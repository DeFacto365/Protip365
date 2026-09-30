jest.mock('../../data/db', () => ({ getDb: jest.fn() }));
jest.mock('expo-crypto', () => ({
  getRandomBytes: (n: number) => new Uint8Array(require('crypto').randomBytes(n)),
}));
import { getDb } from '../../data/db';
import { INITIAL_SCHEMA } from '../../data/initialSchema';
import { PAYMENT_SCHEMA } from '../../data/paymentSchema';
import { createEncryptedFullBackup, restoreEncryptedFullBackup } from '../../data/backup';
import { paymentsRepo } from '../../data/paymentsRepo';
import { itemBalance } from '../payments';
const { DatabaseSync } = jest.requireActual('node:sqlite');
test('encrypted new-schema backup restores the complete ledger in a disposable SQLite database', () => {
  const raw = new DatabaseSync(':memory:');
  const adapter = {
    getAllSync: (sql: string, args: unknown[] = []) => raw.prepare(sql).all(...args),
    getFirstSync: (sql: string, args: unknown[] = []) => raw.prepare(sql).get(...args),
    runSync: (sql: string, args: unknown[] = []) => raw.prepare(sql).run(...args),
    execSync: (sql: string) => raw.exec(sql),
    withTransactionSync: (fn: () => void) => {
      raw.exec('BEGIN');
      try {
        fn();
        raw.exec('COMMIT');
      } catch (e) {
        raw.exec('ROLLBACK');
        throw e;
      }
    },
  };
  (getDb as jest.Mock).mockReturnValue(adapter);
  try {
    raw.exec(`PRAGMA foreign_keys=ON; ${INITIAL_SCHEMA} ${PAYMENT_SCHEMA}
      INSERT INTO employers VALUES('e','Cafe','#996044',2000,0,0,'2026-09-14','2026-09-14');`);
    paymentsRepo.saveExpected({
      id: 'i',
      employerId: 'e',
      shiftId: null,
      kind: 'tips',
      amount: 8000,
      currency: 'CAD',
      dueDate: null,
      disputed: false,
    });
    paymentsRepo.record(
      {
        id: 'r',
        employerId: 'e',
        amount: 5000,
        currency: 'CAD',
        receivedDate: '2026-09-14',
        reference: 'deposit',
        reversedAt: null,
      },
      [{ id: 'a', receiptId: 'r', expectedId: 'i', amount: 5000 }]
    );
    const before = paymentsRepo.list();
    const encrypted = createEncryptedFullBackup('test-passphrase');
    expect(encrypted).not.toContain('deposit');
    paymentsRepo.reverse('r');
    restoreEncryptedFullBackup(encrypted, 'test-passphrase');
    const after = paymentsRepo.list();
    expect(after).toEqual(before);
    expect(itemBalance(after.expected[0], after).remaining).toBe(3000);
  } finally {
    raw.close();
  }
}, 90000);
