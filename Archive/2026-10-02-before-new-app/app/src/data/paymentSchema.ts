export const PAYMENT_SCHEMA = `
CREATE TABLE IF NOT EXISTS expected_items (
 id TEXT PRIMARY KEY NOT NULL, employer_id TEXT NOT NULL REFERENCES employers(id),
 shift_id TEXT REFERENCES shifts(id), kind TEXT NOT NULL, amount INTEGER CHECK(amount >= 0),
 currency TEXT NOT NULL, due_date TEXT, disputed INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS receipts (
 id TEXT PRIMARY KEY NOT NULL, employer_id TEXT NOT NULL REFERENCES employers(id),
 amount INTEGER NOT NULL CHECK(amount > 0), currency TEXT NOT NULL, received_date TEXT NOT NULL,
 reference TEXT NOT NULL, reversed_at TEXT
);
CREATE TABLE IF NOT EXISTS allocations (
 id TEXT PRIMARY KEY NOT NULL, receipt_id TEXT NOT NULL REFERENCES receipts(id),
 expected_id TEXT NOT NULL REFERENCES expected_items(id), amount INTEGER NOT NULL CHECK(amount > 0)
);
CREATE INDEX IF NOT EXISTS idx_expected_shift ON expected_items(shift_id);
CREATE INDEX IF NOT EXISTS idx_allocation_item ON allocations(expected_id);
`;
