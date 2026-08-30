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
 * with no migration-compatibility path (owner ruling); wipe any pre-existing
 * dev database. All currency and hourly-rate columns are INTEGER cents;
 * deduction rates remain INTEGER basis points.
 */
const MIGRATIONS: string[] = [
  // v1 — initial schema
  `
  CREATE TABLE IF NOT EXISTS employers (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    default_hourly_rate INTEGER NOT NULL CHECK (default_hourly_rate > 0),
    deduction_rate_bp INTEGER NOT NULL DEFAULT 0 CHECK (deduction_rate_bp BETWEEN 0 AND 10000),
    archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS roles (
    id TEXT PRIMARY KEY NOT NULL,
    employer_id TEXT NOT NULL REFERENCES employers(id),
    name TEXT NOT NULL,
    hourly_rate INTEGER NOT NULL CHECK (hourly_rate > 0),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE (id, employer_id)
  );
  CREATE TABLE IF NOT EXISTS shifts (
    id TEXT PRIMARY KEY NOT NULL,
    employer_id TEXT NOT NULL REFERENCES employers(id),
    role_id TEXT,
    date TEXT NOT NULL,
    start_min INTEGER NOT NULL,
    end_min INTEGER NOT NULL,
    breaks_json TEXT NOT NULL DEFAULT '[]',
    hourly_rate_snapshot INTEGER NOT NULL CHECK (hourly_rate_snapshot > 0),
    planned_expected_tips INTEGER,
    planned_other_income INTEGER,
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'worked', 'missed', 'cancelled')),
    transition_at TEXT NOT NULL,
    not_worked_reason TEXT,
    not_worked_note TEXT,
    actual_start_min INTEGER,
    actual_end_min INTEGER,
    actual_breaks_json TEXT,
    actual_hourly_rate_snapshot INTEGER CHECK (actual_hourly_rate_snapshot IS NULL OR actual_hourly_rate_snapshot > 0),
    tip_method TEXT,
    direct_tips INTEGER,
    pool_contribution INTEGER,
    tip_share_received INTEGER,
    tip_out_paid INTEGER,
    sales INTEGER,
    other_income INTEGER,
    deduction_rate_snapshot_bp INTEGER CHECK (deduction_rate_snapshot_bp IS NULL OR deduction_rate_snapshot_bp BETWEEN 0 AND 10000),
    expected_payout INTEGER,
    actual_received INTEGER,
    payout_status TEXT,
    notes TEXT,
    source_template_id TEXT,
    source_recurrence_rule_id TEXT,
    recurrence_key TEXT UNIQUE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (role_id, employer_id) REFERENCES roles(id, employer_id)
  );
  CREATE INDEX IF NOT EXISTS idx_shifts_date ON shifts(date);
  CREATE INDEX IF NOT EXISTS idx_shifts_employer ON shifts(employer_id);
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS schedule_templates (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    employer_id TEXT NOT NULL REFERENCES employers(id),
    role_id TEXT,
    start_min INTEGER NOT NULL,
    end_min INTEGER NOT NULL,
    breaks_json TEXT NOT NULL DEFAULT '[]',
    planned_expected_tips INTEGER,
    planned_other_income INTEGER,
    notes TEXT,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (role_id, employer_id) REFERENCES roles(id, employer_id)
  );
  CREATE TABLE IF NOT EXISTS recurrence_rules (
    id TEXT PRIMARY KEY NOT NULL,
    template_id TEXT NOT NULL REFERENCES schedule_templates(id),
    cadence_weeks INTEGER NOT NULL,
    weekdays_json TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    occurrence_count INTEGER,
    active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_templates_employer ON schedule_templates(employer_id);
  CREATE INDEX IF NOT EXISTS idx_recurrence_template ON recurrence_rules(template_id);
  CREATE TABLE IF NOT EXISTS weekly_goals (
    id TEXT PRIMARY KEY NOT NULL,
    week_start TEXT NOT NULL,
    metric TEXT NOT NULL,
    target INTEGER NOT NULL CHECK (target > 0),
    employer_id TEXT REFERENCES employers(id),
    repeat INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_goals_week ON weekly_goals(week_start);
  `,
  // v2 — one goal per week/metric/employer; retain the most recently updated duplicate.
  WEEKLY_GOALS_IDENTITY_MIGRATION,
  // v3 — replace the retired cobalt employer swatch in existing local data.
  NO_BLUE_EMPLOYER_COLOR_MIGRATION,
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
