import { INITIAL_SCHEMA } from './initialSchema';
// NOTE: `execSync` in this file is expo-sqlite's SQLiteDatabase.execSync (SQL
// statements on the local database), not Node's child_process. No shell is involved.
import { deleteDatabaseSync, openDatabaseSync, type SQLiteDatabase } from 'expo-sqlite';
import { getRandomBytes } from 'expo-crypto';
import * as SecureStore from 'expo-secure-store';
import { clearAppLock, getLockConfig } from '../security/appLock';
import {
  requireDatabaseUnlockCapability,
  revokeDatabaseUnlockCapability,
  type DatabaseUnlockCapability,
} from '../security/databaseCapability';
import { NO_BLUE_EMPLOYER_COLOR_MIGRATION, WEEKLY_GOALS_IDENTITY_MIGRATION } from './migrations';

import { PAYMENT_SCHEMA } from './paymentSchema';

export const DB_NAME = 'protip365.db';

let db: SQLiteDatabase | null = null;
const DATABASE_KEY = 'protip365.database-key.v1';

function randomHex(byteCount: number): string {
  return Array.from(getRandomBytes(byteCount), (byte) => byte.toString(16).padStart(2, '0')).join('');
}

function getOrCreateDatabaseKey(_capability: DatabaseUnlockCapability | null): string {
  const stored = SecureStore.getItem(DATABASE_KEY);
  if (stored) return stored;
  const created = randomHex(32);
  SecureStore.setItem(DATABASE_KEY, created);
  return created;
}

/**
 * Idempotent migrations: every statement is CREATE IF NOT EXISTS, guarded by user_version.
 *
 * NOTE (DEF-14, 2026-07-18): deduction rates are stored as INTEGER basis points
 * (0–10000) per PRD §10, in `deduction_rate_bp` / `deduction_rate_snapshot_bp`.
 * RFP-225 also adds `default_hourly_rate` and the INTEGER `archived` employer
 * flag. The database is unreleased, so these schema changes were made in place
 * with no customer migration path (owner ruling). Preserve unidentified
 * developer databases; use disposable fixtures for testing. All money columns are INTEGER cents;
 * deduction rates remain INTEGER basis points.
 */
const MIGRATIONS: string[] = [
  // v1 — initial schema
  INITIAL_SCHEMA,
  // v2 — one goal per week/metric/employer; retain the most recently updated duplicate.
  WEEKLY_GOALS_IDENTITY_MIGRATION,
  // v3 — replace the retired cobalt employer swatch in existing local data.
  NO_BLUE_EMPLOYER_COLOR_MIGRATION,
  PAYMENT_SCHEMA,
];

export function migrate(database: SQLiteDatabase): void {
  database.execSync('PRAGMA journal_mode = WAL;');
  database.execSync('PRAGMA foreign_keys = ON;');
  const row = database.getFirstSync<{ user_version: number }>('PRAGMA user_version;');
  const current = row?.user_version ?? 0;
  for (let v = current; v < MIGRATIONS.length; v++) {
    database.withTransactionSync(() => {
      database.execSync(MIGRATIONS[v]);
      database.execSync(`PRAGMA user_version = ${v + 1};`);
    });
  }
}

export function getDb(): SQLiteDatabase {
  const lockEnabled = getLockConfig().enabled;
  const capability = lockEnabled ? requireDatabaseUnlockCapability() : null;
  if (!db) {
    // Keychain access is deliberately behind the app-unlock capability gate.
    const key = getOrCreateDatabaseKey(capability);
    const opened = openDatabaseSync(DB_NAME);
    opened.execSync(`PRAGMA key = "x'${key}'";`);
    migrate(opened);
    db = opened;
  }
  return db;
}

/** Close the decrypted database handle when the app returns to a locked state. */
export function closeDatabaseForLock(): void {
  db?.closeSync();
  db = null;
}

function checkpointDatabaseForEraseBestEffort(): void {
  try {
    db?.execSync('PRAGMA wal_checkpoint(TRUNCATE);');
  } catch (error) {
    console.warn('Database WAL checkpoint failed during local data erase.', error);
  }
}

function closeDatabaseForEraseBestEffort(): void {
  try {
    db?.closeSync();
  } catch (error) {
    console.warn('Database close failed during local data erase.', error);
  } finally {
    db = null;
  }
}

function deleteDatabaseSidecarsBestEffort(): void {
  for (const suffix of ['-wal', '-shm']) {
    try {
      deleteDatabaseSync(`${DB_NAME}${suffix}`);
    } catch {
      // Sidecars are expected to be absent after a clean checkpoint.
    }
  }
}

async function deleteDatabaseKeyBestEffort(): Promise<void> {
  try {
    await SecureStore.deleteItemAsync(DATABASE_KEY);
  } catch (error) {
    try {
      SecureStore.setItem(DATABASE_KEY, '');
    } catch {
      console.warn('Database key cleanup failed during local data erase.', error);
    }
  }
}

/** Drops all app data (used by Settings → Erase local data). */
export async function eraseAllData(): Promise<void> {
  checkpointDatabaseForEraseBestEffort();
  closeDatabaseForEraseBestEffort();
  deleteDatabaseSync(DB_NAME);
  deleteDatabaseSidecarsBestEffort();
  await deleteDatabaseKeyBestEffort();
  await clearAppLock();
  revokeDatabaseUnlockCapability();
}

export function nowIso(): string {
  return new Date().toISOString();
}
