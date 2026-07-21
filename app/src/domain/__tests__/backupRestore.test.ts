jest.mock('../../domain/backup', () => ({
  decryptBackupPayload: jest.fn(),
  encryptBackupPayload: jest.fn(),
}));

jest.mock('../../data/db', () => ({
  getDb: jest.fn(),
}));

import { decryptBackupPayload } from '../../domain/backup';
import { getDb } from '../../data/db';
import {
  MAX_BACKUP_FILE_BYTES,
  restoreEncryptedFullBackup,
} from '../../data/backup';

const decryptMock = decryptBackupPayload as jest.MockedFunction<typeof decryptBackupPayload>;
const getDbMock = getDb as jest.MockedFunction<typeof getDb>;
const withTransactionSync = jest.fn((callback: () => void) => callback());
const execSync = jest.fn();
const runSync = jest.fn();

const emptyPayload = () => ({
  format: 'protip365-data',
  schemaVersion: 3,
  createdAt: '2026-07-18T12:00:00.000Z',
  tables: {
    employers: [] as Array<Record<string, unknown>>,
    roles: [],
    schedule_templates: [],
    recurrence_rules: [],
    weekly_goals: [] as Array<Record<string, unknown>>,
    shifts: [],
    settings: [],
  },
});

const employerRow = () => ({
  id: 'employer-1',
  name: 'Cafe',
  color: '#2B4BD7',
  default_hourly_rate: 2000,
  deduction_rate_bp: 1500,
  archived: 0,
  created_at: '2026-07-18T12:00:00.000Z',
  updated_at: '2026-07-18T12:00:00.000Z',
});

beforeEach(() => {
  jest.clearAllMocks();
  getDbMock.mockReturnValue({
    withTransactionSync,
    execSync,
    runSync,
  } as unknown as ReturnType<typeof getDb>);
});

describe('restore validation before destructive work', () => {
  it('accepts a complete, correctly typed payload', () => {
    const payload = emptyPayload();
    payload.tables.employers.push(employerRow());
    decryptMock.mockReturnValue(payload);

    restoreEncryptedFullBackup('encrypted', 'password');

    expect(withTransactionSync).toHaveBeenCalledTimes(1);
    expect(runSync).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO employers'),
      expect.arrayContaining(['employer-1', 2000])
    );
  });

  it('rejects missing required columns before opening the destructive transaction', () => {
    const payload = emptyPayload();
    const { id: _id, ...missingId } = employerRow();
    payload.tables.employers.push(missingId);
    decryptMock.mockReturnValue(payload);

    expect(() => restoreEncryptedFullBackup('encrypted', 'password')).toThrow(
      'backup_invalid_payload'
    );
    expect(withTransactionSync).not.toHaveBeenCalled();
  });

  it('rejects incorrect column types before opening the destructive transaction', () => {
    const payload = emptyPayload();
    payload.tables.employers.push({
      ...employerRow(),
      default_hourly_rate: '2000' as unknown as number,
    });
    decryptMock.mockReturnValue(payload);

    expect(() => restoreEncryptedFullBackup('encrypted', 'password')).toThrow(
      'backup_invalid_payload'
    );
    expect(withTransactionSync).not.toHaveBeenCalled();
  });

  it('rejects files over 10 MB before decrypting or opening a transaction', () => {
    expect(() =>
      restoreEncryptedFullBackup('x'.repeat(MAX_BACKUP_FILE_BYTES + 1), 'password')
    ).toThrow('backup_file_too_large');
    expect(decryptMock).not.toHaveBeenCalled();
    expect(withTransactionSync).not.toHaveBeenCalled();
  });

  it('coalesces duplicate legacy weekly goals during restore', () => {
    const payload = emptyPayload();
    payload.tables.weekly_goals.push(
      {
        id: 'goal-old',
        week_start: '2026-07-20',
        metric: 'actual_gross',
        target: 50000,
        employer_id: null,
        repeat: 0,
        created_at: '2026-07-20T12:00:00.000Z',
        updated_at: '2026-07-20T12:00:00.000Z',
      },
      {
        id: 'goal-new',
        week_start: '2026-07-20',
        metric: 'actual_gross',
        target: 60000,
        employer_id: null,
        repeat: 1,
        created_at: '2026-07-21T12:00:00.000Z',
        updated_at: '2026-07-21T12:00:00.000Z',
      }
    );
    decryptMock.mockReturnValue(payload);

    restoreEncryptedFullBackup('encrypted', 'password');

    expect(
      runSync.mock.calls.filter(([sql]) => String(sql).includes('weekly_goals'))
    ).toHaveLength(1);
    expect(runSync).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO weekly_goals'),
      expect.arrayContaining(['goal-new', 60000])
    );
  });
});
