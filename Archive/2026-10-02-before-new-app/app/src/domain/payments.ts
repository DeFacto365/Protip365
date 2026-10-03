/** Integer-cent receipt ledger. Earnings are deliberately absent from this module. */
export interface ExpectedItem {
  id: string;
  employerId: string;
  shiftId: string | null;
  kind: 'tips' | 'wages' | 'other';
  amount: number | null;
  currency: string;
  dueDate: string | null;
  disputed: boolean;
}
export interface Receipt {
  id: string;
  employerId: string;
  amount: number;
  currency: string;
  receivedDate: string;
  reference: string;
  reversedAt: string | null;
}
export interface Allocation {
  id: string;
  receiptId: string;
  expectedId: string;
  amount: number;
}
export interface Ledger {
  expected: ExpectedItem[];
  receipts: Receipt[];
  allocations: Allocation[];
}
export const emptyLedger = (): Ledger => ({ expected: [], receipts: [], allocations: [] });
export function validDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(value + 'T12:00:00Z');
  return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value;
}
function cents(value: number, positive = false) {
  if (!Number.isSafeInteger(value) || value < (positive ? 1 : 0)) throw new Error('payment_amount');
}
function sum(values: number[]): number {
  const total = values.reduce((a, b) => a + b, 0);
  cents(total);
  return total;
}
export function receivedFor(itemId: string, ledger: Ledger): number {
  return sum(
    ledger.allocations
      .filter(
        (a) =>
          a.expectedId === itemId &&
          ledger.receipts.some((r) => r.id === a.receiptId && !r.reversedAt)
      )
      .map((a) => a.amount)
  );
}
export function itemBalance(item: ExpectedItem, ledger: Ledger) {
  const received = receivedFor(item.id, ledger);
  const remaining = item.amount === null ? null : item.amount - received;
  const status = item.disputed
    ? 'disputed'
    : remaining === null
      ? 'unknown'
      : remaining === 0
        ? 'settled'
        : received > 0
          ? 'partial'
          : 'awaiting';
  return { received, remaining, status };
}
export function unallocated(receipt: Receipt, ledger: Ledger): number {
  return receipt.reversedAt
    ? 0
    : receipt.amount -
        sum(ledger.allocations.filter((a) => a.receiptId === receipt.id).map((a) => a.amount));
}
export function validateLedger(ledger: Ledger): void {
  for (const rows of [ledger.expected, ledger.receipts, ledger.allocations]) {
    if (new Set(rows.map((r) => r.id)).size !== rows.length || rows.some((r) => !r.id))
      throw new Error('payment_duplicate');
  }
  for (const item of ledger.expected) {
    if (item.amount !== null) cents(item.amount);
    if (
      !item.employerId ||
      !/^[A-Z]{3}$/.test(item.currency) ||
      !['tips', 'wages', 'other'].includes(item.kind) ||
      typeof item.disputed !== 'boolean' ||
      (item.dueDate !== null && !validDate(item.dueDate))
    )
      throw new Error('payment_invalid');
  }
  for (const receipt of ledger.receipts) {
    cents(receipt.amount, true);
    if (
      !receipt.employerId ||
      !/^[A-Z]{3}$/.test(receipt.currency) ||
      !validDate(receipt.receivedDate) ||
      (receipt.reversedAt !== null && !Number.isFinite(Date.parse(receipt.reversedAt)))
    )
      throw new Error('payment_invalid');
  }
  for (const a of ledger.allocations) {
    cents(a.amount, true);
    const item = ledger.expected.find((i) => i.id === a.expectedId);
    const receipt = ledger.receipts.find((r) => r.id === a.receiptId);
    if (!item || !receipt) throw new Error('payment_unmatched');
    if (item.employerId !== receipt.employerId || item.currency !== receipt.currency)
      throw new Error('payment_mismatch');
  }
  for (const item of ledger.expected)
    if (item.amount !== null && receivedFor(item.id, ledger) > item.amount)
      throw new Error('payment_overallocated');
  for (const receipt of ledger.receipts)
    if (
      sum(ledger.allocations.filter((a) => a.receiptId === receipt.id).map((a) => a.amount)) >
      receipt.amount
    )
      throw new Error('payment_overallocated');
}
