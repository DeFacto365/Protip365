import { getDb } from './db';
import {
  validateLedger,
  type Ledger,
  type ExpectedItem,
  type Receipt,
  type Allocation,
} from '../domain/payments';

export const paymentsRepo = {
  list(): Ledger {
    const db = getDb();
    return {
      expected: db
        .getAllSync<any>('SELECT * FROM expected_items ORDER BY due_date, id;')
        .map((r) => ({
          id: r.id,
          employerId: r.employer_id,
          shiftId: r.shift_id,
          kind: r.kind,
          amount: r.amount,
          currency: r.currency,
          dueDate: r.due_date,
          disputed: r.disputed === 1,
        })),
      receipts: db
        .getAllSync<any>('SELECT * FROM receipts ORDER BY received_date DESC, id;')
        .map((r) => ({
          id: r.id,
          employerId: r.employer_id,
          amount: r.amount,
          currency: r.currency,
          receivedDate: r.received_date,
          reference: r.reference,
          reversedAt: r.reversed_at,
        })),
      allocations: db
        .getAllSync<any>('SELECT * FROM allocations;')
        .map((r) => ({
          id: r.id,
          receiptId: r.receipt_id,
          expectedId: r.expected_id,
          amount: r.amount,
        })),
    };
  },
  saveExpected(item: ExpectedItem): void {
    const db = getDb();
    db.withTransactionSync(() => {
      const ledger = this.list();
      const old = ledger.expected.find((i) => i.id === item.id);
      if (
        old &&
        (old.employerId !== item.employerId ||
          old.currency !== item.currency ||
          old.shiftId !== item.shiftId)
      )
        throw new Error('payment_mismatch');
      validateLedger({
        ...ledger,
        expected: [...ledger.expected.filter((i) => i.id !== item.id), item],
      });
      if (
        item.shiftId &&
        !db.getFirstSync(
          "SELECT id FROM shifts WHERE id = ? AND employer_id = ? AND status = 'worked';",
          [item.shiftId, item.employerId]
        )
      )
        throw new Error('payment_unmatched');
      db.runSync(
        'INSERT INTO expected_items VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET amount=excluded.amount, due_date=excluded.due_date, disputed=excluded.disputed;',
        [
          item.id,
          item.employerId,
          item.shiftId,
          item.kind,
          item.amount,
          item.currency,
          item.dueDate,
          item.disputed ? 1 : 0,
        ]
      );
    });
  },
  record(receipt: Receipt, allocations: Allocation[]): void {
    const db = getDb();
    db.withTransactionSync(() => {
      const ledger = this.list();
      const existing = ledger.receipts.find((r) => r.id === receipt.id);
      if (existing) {
        if (
          Object.keys(existing).every(
            (key) => existing[key as keyof Receipt] === receipt[key as keyof Receipt]
          ) &&
          ledger.allocations.filter((a) => a.receiptId === receipt.id).length ===
            allocations.length &&
          allocations.every((a) =>
            ledger.allocations.some(
              (old) =>
                old.id === a.id &&
                old.receiptId === a.receiptId &&
                old.expectedId === a.expectedId &&
                old.amount === a.amount
            )
          )
        )
          return;
        throw new Error('payment_duplicate');
      }
      if (receipt.reversedAt || allocations.some((a) => a.receiptId !== receipt.id))
        throw new Error('payment_invalid');
      validateLedger({
        ...ledger,
        receipts: [...ledger.receipts, receipt],
        allocations: [...ledger.allocations, ...allocations],
      });
      db.runSync('INSERT INTO receipts VALUES (?, ?, ?, ?, ?, ?, ?);', [
        receipt.id,
        receipt.employerId,
        receipt.amount,
        receipt.currency,
        receipt.receivedDate,
        receipt.reference,
        null,
      ]);
      for (const a of allocations)
        db.runSync('INSERT INTO allocations VALUES (?, ?, ?, ?);', [
          a.id,
          a.receiptId,
          a.expectedId,
          a.amount,
        ]);
    });
  },
  allocate(receiptId: string, allocations: Allocation[]): void {
    const db = getDb();
    db.withTransactionSync(() => {
      const ledger = this.list();
      const receipt = ledger.receipts.find((r) => r.id === receiptId);
      if (!receipt || receipt.reversedAt || allocations.some((a) => a.receiptId !== receiptId))
        throw new Error('payment_invalid');
      const additions = allocations.filter(
        (a) =>
          !ledger.allocations.some(
            (old) =>
              old.id === a.id &&
              old.receiptId === a.receiptId &&
              old.expectedId === a.expectedId &&
              old.amount === a.amount
          )
      );
      validateLedger({ ...ledger, allocations: [...ledger.allocations, ...additions] });
      for (const a of additions)
        db.runSync('INSERT INTO allocations VALUES (?, ?, ?, ?);', [
          a.id,
          a.receiptId,
          a.expectedId,
          a.amount,
        ]);
    });
  },
  reverse(id: string): void {
    getDb().runSync('UPDATE receipts SET reversed_at = ? WHERE id = ? AND reversed_at IS NULL;', [
      new Date().toISOString(),
      id,
    ]);
  },
};
