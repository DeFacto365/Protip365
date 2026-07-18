// NOTE: `execSync` in this file is expo-sqlite's SQLiteDatabase.execSync (SQL
// statements on the local database), not Node's child_process. No shell is involved.
import { openDatabaseSync, type SQLiteDatabase } from 'expo-sqlite';

export const DB_NAME = 'protip365.db';

let db: SQLiteDatabase | null = null;

/**
 * Idempotent migrations: every statement is CREATE IF NOT EXISTS, guarded by user_version.
 *
 * NOTE (DEF-14, 2026-07-18): deduction rates are stored as INTEGER basis points
 * (0–10000) per PRD §10, in `deduction_rate_bp` / `deduction_rate_snapshot_bp`.
 * The database is unreleased, so this schema change was made in place with no
 * migration-compat path (owner ruling); wipe any pre-existing dev database.
 */
const MIGRATIONS: string[] = [
  // v1 — initial schema
  `
  CREATE TABLE IF NOT EXISTS employers (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    deduction_rate_bp INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS roles (
    id TEXT PRIMARY KEY NOT NULL,
    employer_id TEXT NOT NULL REFERENCES employers(id),
    name TEXT NOT NULL,
    hourly_rate REAL NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS shifts (
    id TEXT PRIMARY KEY NOT NULL,
    employer_id TEXT NOT NULL REFERENCES employers(id),
    role_id TEXT REFERENCES roles(id),
    date TEXT NOT NULL,
    start_min INTEGER NOT NULL,
    end_min INTEGER NOT NULL,
    breaks_json TEXT NOT NULL DEFAULT '[]',
    hourly_rate_snapshot REAL NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled',
    not_worked_reason TEXT,
    not_worked_note TEXT,
    actual_start_min INTEGER,
    actual_end_min INTEGER,
    actual_breaks_json TEXT,
    tip_method TEXT,
    direct_tips REAL,
    pool_contribution REAL,
    tip_share_received REAL,
    tip_out_paid REAL,
    sales REAL,
    other_income REAL,
    deduction_rate_snapshot_bp INTEGER,
    expected_payout REAL,
    actual_received REAL,
    payout_status TEXT,
    notes TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_shifts_date ON shifts(date);
  CREATE INDEX IF NOT EXISTS idx_shifts_employer ON shifts(employer_id);
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
  );
  `,
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
  if (!db) {
    db = openDatabaseSync(DB_NAME);
    migrate(db);
  }
  return db;
}

/** Drops all app data (used by Settings → Erase local data). */
export function eraseAllData(): void {
  const d = getDb();
  d.withTransactionSync(() => {
    d.execSync('DELETE FROM shifts;');
    d.execSync('DELETE FROM roles;');
    d.execSync('DELETE FROM employers;');
    d.execSync('DELETE FROM settings;');
  });
}

export function nowIso(): string {
  return new Date().toISOString();
}
