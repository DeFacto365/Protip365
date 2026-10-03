import type { SQLiteDatabase } from 'expo-sqlite';
import { validateLedger, type Ledger } from '../domain/payments';
export interface CloseoutSettlement {
  received: number | null;
  later: number | null;
  currency: string;
  date: string;
}
/** Called only inside the shift completion transaction. */
export function writeCloseoutSettlement(
  db: SQLiteDatabase,
  shiftId: string,
  employerId: string,
  input: CloseoutSettlement
): void {
  for (const n of [input.received, input.later])
    if (n !== null && (!Number.isSafeInteger(n) || n < 0)) throw new Error('payment_amount');
  const expectedId = `${shiftId}:tips`;
  const receiptId = `${shiftId}:receipt`;
  const known = input.received !== null && input.later !== null;
  const ledger: Ledger = {
    expected: [
      {
        id: expectedId,
        employerId,
        shiftId,
        kind: 'tips',
        amount: known
          ? input.received! + input.later!
          : input.later !== null && input.later > 0
            ? input.later
            : null,
        currency: input.currency,
        dueDate: null,
        disputed: false,
      },
    ],
    receipts: input.received
      ? [
          {
            id: receiptId,
            employerId,
            amount: input.received,
            currency: input.currency,
            receivedDate: input.date,
            reference: '',
            reversedAt: null,
          },
        ]
      : [],
    allocations: input.received
      ? [{ id: `${shiftId}:allocation`, receiptId, expectedId, amount: input.received }]
      : [],
  };
  validateLedger(ledger);
  const item = ledger.expected[0];
  db.runSync('INSERT INTO expected_items VALUES (?, ?, ?, ?, ?, ?, ?, ?);', [
    item.id,
    employerId,
    shiftId,
    'tips',
    item.amount,
    input.currency,
    null,
    0,
  ]);
  for (const r of ledger.receipts)
    db.runSync('INSERT INTO receipts VALUES (?, ?, ?, ?, ?, ?, ?);', [
      r.id,
      employerId,
      r.amount,
      input.currency,
      input.date,
      '',
      null,
    ]);
  for (const a of ledger.allocations)
    db.runSync('INSERT INTO allocations VALUES (?, ?, ?, ?);', [
      a.id,
      a.receiptId,
      a.expectedId,
      a.amount,
    ]);
}
