jest.mock('../../data/db', () => ({ getDb: jest.fn(), nowIso: () => new Date().toISOString() }));
import { getDb } from '../../data/db';
import { PAYMENT_SCHEMA } from '../../data/paymentSchema';
import { paymentsRepo } from '../../data/paymentsRepo';
import { writeCloseoutSettlement } from '../../data/closeoutSettlement';
import { itemBalance } from '../payments';
import { saveCompletionDraft, readCompletionDraft } from '../../data/completionDrafts';
const { DatabaseSync } = jest.requireActual('node:sqlite');
let raw: any;
let adapter: any;
beforeEach(() => {
  raw = new DatabaseSync(':memory:');
  raw.exec(`PRAGMA foreign_keys=ON; CREATE TABLE employers(id TEXT PRIMARY KEY); INSERT INTO employers VALUES('cafe');
    CREATE TABLE shifts(id TEXT PRIMARY KEY,employer_id TEXT,status TEXT); INSERT INTO shifts VALUES('one','cafe','worked'),('two','cafe','worked');
    CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT); ${PAYMENT_SCHEMA}`);
  adapter = {
    getAllSync: (sql: string, args: unknown[] = []) => raw.prepare(sql).all(...args),
    getFirstSync: (sql: string, args: unknown[] = []) => raw.prepare(sql).get(...args),
    runSync: (sql: string, args: unknown[] = []) => raw.prepare(sql).run(...args),
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
});
afterEach(() => raw.close());
test('real SQLite round trip: immediate receipt, multi-shift settlement, duplicate retry and reversal', () => {
  adapter.withTransactionSync(() =>
    writeCloseoutSettlement(adapter, 'one', 'cafe', {
      received: 6000,
      later: 10000,
      currency: 'CAD',
      date: '2026-09-13',
    })
  );
  paymentsRepo.saveExpected({
    id: 'two-tips',
    employerId: 'cafe',
    shiftId: 'two',
    kind: 'tips',
    amount: 8000,
    currency: 'CAD',
    dueDate: null,
    disputed: false,
  });
  const receipt = {
    id: 'payment',
    employerId: 'cafe',
    amount: 15000,
    currency: 'CAD',
    receivedDate: '2026-09-14',
    reference: 'deposit',
    reversedAt: null,
  };
  const allocations = [
    { id: 'a', receiptId: 'payment', expectedId: 'one:tips', amount: 10000 },
    { id: 'b', receiptId: 'payment', expectedId: 'two-tips', amount: 5000 },
  ];
  paymentsRepo.record(receipt, allocations);
  paymentsRepo.record(receipt, allocations);
  let ledger = paymentsRepo.list();
  expect(ledger.receipts).toHaveLength(2);
  expect(
    itemBalance(
      ledger.expected.find((i) => i.id === 'two-tips')!,
      ledger
    ).remaining
  ).toBe(3000);
  paymentsRepo.reverse('payment');
  ledger = paymentsRepo.list();
  expect(
    itemBalance(
      ledger.expected.find((i) => i.id === 'two-tips')!,
      ledger
    ).remaining
  ).toBe(8000);
  expect(ledger.allocations).toHaveLength(3);
});
test('failed allocation rolls back receipt insertion; foreign keys preserve history', () => {
  expect(() =>
    paymentsRepo.record(
      {
        id: 'r',
        employerId: 'cafe',
        amount: 100,
        currency: 'CAD',
        receivedDate: '2026-09-14',
        reference: '',
        reversedAt: null,
      },
      [{ id: 'a', receiptId: 'r', expectedId: 'missing', amount: 100 }]
    )
  ).toThrow();
  expect(paymentsRepo.list().receipts).toHaveLength(0);
  adapter.withTransactionSync(() =>
    writeCloseoutSettlement(adapter, 'one', 'cafe', {
      received: 0,
      later: null,
      currency: 'CAD',
      date: '2026-09-13',
    })
  );
  expect(() => raw.exec("DELETE FROM shifts WHERE id='one'")).toThrow();
});
test('interrupted transaction does not leave a partial closeout', () => {
  expect(() =>
    adapter.withTransactionSync(() => {
      writeCloseoutSettlement(adapter, 'one', 'cafe', {
        received: 6000,
        later: 10000,
        currency: 'CAD',
        date: '2026-09-13',
      });
      throw Error('interruption');
    })
  ).toThrow();
  expect(paymentsRepo.list()).toEqual({ expected: [], receipts: [], allocations: [] });
});
test('draft survives reopen, ignores stale revisions and is not duplicated', () => {
  saveCompletionDraft('one', 'v1', { tips: '20,50' });
  expect(readCompletionDraft('one', 'v1')).toEqual({ tips: '20,50' });
  expect(readCompletionDraft('one', 'v2')).toBeNull();
  saveCompletionDraft('one', 'v1', { tips: '25' });
  expect(raw.prepare('SELECT * FROM settings').all()).toHaveLength(1);
});
test('known receipt with unknown remaining expectation retains shift history', () => {
  adapter.withTransactionSync(() =>
    writeCloseoutSettlement(adapter, 'one', 'cafe', {
      received: 6000,
      later: null,
      currency: 'CAD',
      date: '2026-09-13',
    })
  );
  const ledger = paymentsRepo.list();
  expect(itemBalance(ledger.expected[0], ledger)).toEqual({
    received: 6000,
    remaining: null,
    status: 'unknown',
  });
});
test('unallocated receipt can be matched later without duplicating money', () => {
  paymentsRepo.record(
    {
      id: 'r',
      employerId: 'cafe',
      amount: 5000,
      currency: 'CAD',
      receivedDate: '2026-09-14',
      reference: '',
      reversedAt: null,
    },
    []
  );
  paymentsRepo.saveExpected({
    id: 'i',
    employerId: 'cafe',
    shiftId: null,
    kind: 'tips',
    amount: 8000,
    currency: 'CAD',
    dueDate: null,
    disputed: false,
  });
  const allocations = [{ id: 'a', receiptId: 'r', expectedId: 'i', amount: 5000 }];
  paymentsRepo.allocate('r', allocations);
  paymentsRepo.allocate('r', allocations);
  const ledger = paymentsRepo.list();
  expect(ledger.receipts).toHaveLength(1);
  expect(ledger.allocations).toHaveLength(1);
  expect(itemBalance(ledger.expected[0], ledger).remaining).toBe(3000);
});
