import { itemBalance, validateLedger, unallocated, type Ledger } from '../payments';
import { actualEarnings } from '../calc';
const fixture = (): Ledger => ({
  expected: [
    {
      id: 'one',
      employerId: 'cafe',
      shiftId: null,
      kind: 'tips',
      amount: 16000,
      currency: 'CAD',
      dueDate: null,
      disputed: false,
    },
    {
      id: 'two',
      employerId: 'cafe',
      shiftId: null,
      kind: 'tips',
      amount: 8000,
      currency: 'CAD',
      dueDate: null,
      disputed: false,
    },
  ],
  receipts: [
    {
      id: 'cash',
      employerId: 'cafe',
      amount: 6000,
      currency: 'CAD',
      receivedDate: '2026-09-13',
      reference: 'cash',
      reversedAt: null,
    },
    {
      id: 'pay',
      employerId: 'cafe',
      amount: 15000,
      currency: 'CAD',
      receivedDate: '2026-09-14',
      reference: 'tips',
      reversedAt: null,
    },
  ],
  allocations: [
    { id: 'a', receiptId: 'cash', expectedId: 'one', amount: 6000 },
    { id: 'b', receiptId: 'pay', expectedId: 'one', amount: 10000 },
    { id: 'c', receiptId: 'pay', expectedId: 'two', amount: 5000 },
  ],
});
test('worked acceptance: $150 settles first shift and leaves $30 on second without new earnings', () => {
  const ledger = fixture();
  validateLedger(ledger);
  expect(itemBalance(ledger.expected[0], ledger)).toEqual({
    received: 16000,
    remaining: 0,
    status: 'settled',
  });
  expect(itemBalance(ledger.expected[1], ledger)).toEqual({
    received: 5000,
    remaining: 3000,
    status: 'partial',
  });
  expect(actualEarnings({ hourlyRateSnapshot: 2000, directTips: 20000, tipOutPaid: 4000 })).toBe(
    16000
  );
  expect(ledger.allocations.filter((a) => a.expectedId === 'one')).toHaveLength(2);
});
test('reversal preserves events and releases balances; excess is explicit', () => {
  const ledger = fixture();
  ledger.receipts[1].reversedAt = '2026-09-15T12:00:00Z';
  validateLedger(ledger);
  expect(itemBalance(ledger.expected[0], ledger).remaining).toBe(10000);
  expect(itemBalance(ledger.expected[1], ledger).remaining).toBe(8000);
  expect(ledger.allocations).toHaveLength(3);
  ledger.receipts[0].amount = 7000;
  expect(unallocated(ledger.receipts[0], ledger)).toBe(1000);
});
test.each(['currency', 'employerId'] as const)('rejects cross-%s allocations', (field) => {
  const ledger = fixture();
  ledger.receipts[0][field] = field === 'currency' ? 'USD' : 'other';
  expect(() => validateLedger(ledger)).toThrow('payment_mismatch');
});
test('unknown stays null; dispute is explicit', () => {
  const ledger = fixture();
  ledger.allocations = [];
  ledger.expected[0].amount = null;
  validateLedger(ledger);
  expect(itemBalance(ledger.expected[0], ledger).status).toBe('unknown');
  ledger.expected[0].disputed = true;
  expect(itemBalance(ledger.expected[0], ledger).status).toBe('disputed');
});
test.each([NaN, -1, 0.5, Number.MAX_SAFE_INTEGER + 1])('rejects invalid cents %s', (amount) => {
  const l = fixture();
  l.receipts[0].amount = amount;
  expect(() => validateLedger(l)).toThrow();
});
test('rejects impossible dates, duplicate ids, overpayment allocation and unknown targets', () => {
  const l = fixture();
  l.receipts[0].receivedDate = '2026-02-30';
  expect(() => validateLedger(l)).toThrow();
  const d = fixture();
  d.receipts.push(d.receipts[0]);
  expect(() => validateLedger(d)).toThrow('payment_duplicate');
  const a = fixture();
  a.allocations[0].amount = 6001;
  expect(() => validateLedger(a)).toThrow('payment_overallocated');
  const u = fixture();
  u.allocations[0].expectedId = 'missing';
  expect(() => validateLedger(u)).toThrow('payment_unmatched');
});
test('pool and mixed examples do not double count returned shares', () => {
  expect(
    actualEarnings({
      hourlyRateSnapshot: 2000,
      directTips: 20000,
      poolContribution: 20000,
      tipShareReceived: 8000,
    })
  ).toBe(8000);
  expect(
    actualEarnings({
      hourlyRateSnapshot: 2000,
      directTips: 20000,
      poolContribution: 10000,
      tipShareReceived: 5000,
      tipOutPaid: 2000,
    })
  ).toBe(13000);
});
