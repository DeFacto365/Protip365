import { decryptBackupPayload, encryptBackupPayload } from '../domain/backup';
import { getDb } from './db';

type BackupValue = string | number | null;
type BackupRow = Record<string, BackupValue>;

export const MAX_BACKUP_FILE_BYTES = 10 * 1024 * 1024;

const TABLE_COLUMNS = {
  employers: [
    'id', 'name', 'color', 'default_hourly_rate', 'deduction_rate_bp', 'archived', 'created_at', 'updated_at',
  ],
  roles: ['id', 'employer_id', 'name', 'hourly_rate', 'created_at', 'updated_at'],
  schedule_templates: [
    'id', 'name', 'employer_id', 'role_id', 'start_min', 'end_min', 'breaks_json',
    'planned_expected_tips', 'planned_other_income', 'notes',
    'archived', 'created_at', 'updated_at',
  ],
  recurrence_rules: [
    'id', 'template_id', 'cadence_weeks', 'weekdays_json', 'start_date', 'end_date',
    'occurrence_count', 'active', 'created_at', 'updated_at',
  ],
  weekly_goals: [
    'id', 'week_start', 'metric', 'target', 'employer_id', 'repeat', 'created_at', 'updated_at',
  ],
  shifts: [
    'id', 'employer_id', 'role_id', 'date', 'start_min', 'end_min', 'breaks_json',
    'hourly_rate_snapshot', 'planned_expected_tips', 'planned_other_income', 'status', 'transition_at',
    'not_worked_reason', 'not_worked_note', 'actual_start_min', 'actual_end_min',
    'actual_breaks_json', 'actual_hourly_rate_snapshot', 'tip_method', 'direct_tips',
    'pool_contribution', 'tip_share_received', 'tip_out_paid', 'sales', 'other_income',
    'deduction_rate_snapshot_bp', 'expected_payout', 'actual_received', 'payout_status', 'notes',
    'source_template_id', 'source_recurrence_rule_id', 'recurrence_key', 'created_at', 'updated_at',
  ],
  settings: ['key', 'value'],
} as const;

type TableName = keyof typeof TABLE_COLUMNS;
const INSERT_ORDER: TableName[] = [
  'employers',
  'roles',
  'schedule_templates',
  'recurrence_rules',
  'weekly_goals',
  'shifts',
  'settings',
];
const DELETE_ORDER = [...INSERT_ORDER].reverse();

const INTEGER_COLUMNS: Record<TableName, ReadonlySet<string>> = {
  employers: new Set(['default_hourly_rate', 'deduction_rate_bp', 'archived']),
  roles: new Set(['hourly_rate']),
  schedule_templates: new Set([
    'start_min', 'end_min', 'planned_expected_tips', 'planned_other_income', 'archived',
  ]),
  recurrence_rules: new Set(['cadence_weeks', 'occurrence_count', 'active']),
  weekly_goals: new Set(['target', 'repeat']),
  shifts: new Set([
    'start_min', 'end_min', 'hourly_rate_snapshot', 'planned_expected_tips',
    'planned_other_income', 'actual_start_min', 'actual_end_min',
    'actual_hourly_rate_snapshot', 'direct_tips', 'pool_contribution',
    'tip_share_received', 'tip_out_paid', 'sales', 'other_income',
    'deduction_rate_snapshot_bp', 'expected_payout', 'actual_received',
  ]),
  settings: new Set(),
};

const NULLABLE_COLUMNS: Record<TableName, ReadonlySet<string>> = {
  employers: new Set(),
  roles: new Set(),
  schedule_templates: new Set([
    'role_id', 'planned_expected_tips', 'planned_other_income', 'notes',
  ]),
  recurrence_rules: new Set(['end_date', 'occurrence_count']),
  weekly_goals: new Set(['employer_id']),
  shifts: new Set([
    'role_id', 'planned_expected_tips', 'planned_other_income', 'not_worked_reason',
    'not_worked_note', 'actual_start_min', 'actual_end_min', 'actual_breaks_json',
    'actual_hourly_rate_snapshot', 'tip_method', 'direct_tips', 'pool_contribution',
    'tip_share_received', 'tip_out_paid', 'sales', 'other_income',
    'deduction_rate_snapshot_bp', 'expected_payout', 'actual_received', 'payout_status',
    'notes', 'source_template_id', 'source_recurrence_rule_id', 'recurrence_key',
  ]),
  settings: new Set(),
};

const JSON_ARRAY_COLUMNS = new Set(['breaks_json', 'actual_breaks_json', 'weekdays_json']);

interface BackupData {
  format: 'protip365-data';
  schemaVersion: 3;
  createdAt: string;
  tables: Record<TableName, BackupRow[]>;
}

export function createEncryptedFullBackup(password: string): string {
  const database = getDb();
  const tables = {} as Record<TableName, BackupRow[]>;
  for (const table of INSERT_ORDER) {
    const columns = TABLE_COLUMNS[table];
    const rows = database.getAllSync<BackupRow>(
      `SELECT ${columns.join(', ')} FROM ${table};`
    );
    tables[table] =
      table === 'settings'
        ? rows.filter(
            (row) =>
              !String(row.key).startsWith('shiftReminder:') &&
              !String(row.key).startsWith('entitlement')
          )
        : rows;
  }
  const payload: BackupData = {
    format: 'protip365-data',
    schemaVersion: 3,
    createdAt: new Date().toISOString(),
    tables,
  };
  return encryptBackupPayload(payload, password);
}

export function backupTextByteLength(text: string): number {
  let bytes = 0;
  for (let index = 0; index < text.length; index += 1) {
    const code = text.charCodeAt(index);
    if (code < 0x80) bytes += 1;
    else if (code < 0x800) bytes += 2;
    else if (code >= 0xd800 && code <= 0xdbff && index + 1 < text.length) {
      const next = text.charCodeAt(index + 1);
      if (next >= 0xdc00 && next <= 0xdfff) {
        bytes += 4;
        index += 1;
      } else bytes += 3;
    } else bytes += 3;
  }
  return bytes;
}

export function assertBackupFileSize(bytes: number): void {
  if (!Number.isFinite(bytes) || bytes < 0 || bytes > MAX_BACKUP_FILE_BYTES) {
    throw new Error('backup_file_too_large');
  }
}

export function validatePayload(value: unknown): asserts value is BackupData {
  if (!value || typeof value !== 'object') throw new Error('backup_invalid_payload');
  const payload = value as Partial<BackupData>;
  if (
    payload.format !== 'protip365-data' ||
    payload.schemaVersion !== 3 ||
    typeof payload.createdAt !== 'string' ||
    !payload.tables ||
    typeof payload.tables !== 'object' ||
    Array.isArray(payload.tables)
  ) {
    throw new Error('backup_unsupported');
  }
  for (const table of INSERT_ORDER) {
    const rows = payload.tables[table];
    if (!Array.isArray(rows)) throw new Error('backup_invalid_payload');
    const columns: readonly string[] = TABLE_COLUMNS[table];
    const allowed = new Set(columns);
    for (const row of rows) {
      if (
        !row ||
        typeof row !== 'object' ||
        Array.isArray(row) ||
        Object.keys(row).some((key) => !allowed.has(key)) ||
        columns.some((column) => !Object.prototype.hasOwnProperty.call(row, column))
      ) {
        throw new Error('backup_invalid_payload');
      }
      for (const column of columns) {
        const cell = row[column];
        if (cell === null) {
          if (!NULLABLE_COLUMNS[table].has(column)) throw new Error('backup_invalid_payload');
          continue;
        }
        if (INTEGER_COLUMNS[table].has(column)) {
          if (typeof cell !== 'number' || !Number.isSafeInteger(cell)) {
            throw new Error('backup_invalid_payload');
          }
        } else if (typeof cell !== 'string') {
          throw new Error('backup_invalid_payload');
        }
        if (typeof cell === 'string' && JSON_ARRAY_COLUMNS.has(column)) {
          try {
            if (!Array.isArray(JSON.parse(cell))) throw new Error('not_array');
          } catch {
            throw new Error('backup_invalid_payload');
          }
        }
      }
    }
  }
}

function rowsForRestore(table: TableName, rows: BackupRow[]): BackupRow[] {
  if (table !== 'weekly_goals') return rows;
  const latestByIdentity = new Map<string, BackupRow>();
  for (const row of rows) {
    const identity = JSON.stringify([row.week_start, row.metric, row.employer_id]);
    const current = latestByIdentity.get(identity);
    if (
      !current ||
      String(row.updated_at).localeCompare(String(current.updated_at)) > 0 ||
      (row.updated_at === current.updated_at && String(row.id) > String(current.id))
    ) {
      latestByIdentity.set(identity, row);
    }
  }
  return [...latestByIdentity.values()];
}

export function restoreEncryptedFullBackup(text: string, password: string): void {
  assertBackupFileSize(backupTextByteLength(text));
  const payload = decryptBackupPayload<unknown>(text, password);
  validatePayload(payload);
  const database = getDb();
  database.withTransactionSync(() => {
    for (const table of DELETE_ORDER) database.execSync(`DELETE FROM ${table};`);
    for (const table of INSERT_ORDER) {
      const columns = TABLE_COLUMNS[table];
      for (const row of rowsForRestore(table, payload.tables[table])) {
        if (
          table === 'settings' &&
          (String(row.key).startsWith('shiftReminder:') ||
            String(row.key).startsWith('entitlement'))
        ) {
          continue;
        }
        database.runSync(
          `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${columns.map(() => '?').join(', ')});`,
          columns.map((column) => row[column] ?? null)
        );
      }
    }
  });
}
