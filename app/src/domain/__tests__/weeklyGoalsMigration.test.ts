import { WEEKLY_GOALS_IDENTITY_MIGRATION } from '../../data/migrations';

interface TestDatabase {
  exec(sql: string): void;
  prepare(sql: string): { all(): Array<Record<string, unknown>> };
  close(): void;
}

type DatabaseConstructor = new (path: string) => TestDatabase;

let DatabaseSync: DatabaseConstructor;
try {
  DatabaseSync = (jest.requireActual('node:sqlite') as { DatabaseSync: DatabaseConstructor }).DatabaseSync;
} catch (error) {
  throw new Error(
    'weekly goals migration verification requires Node.js 22.13 or newer with stable node:sqlite',
    { cause: error }
  );
}

describe('weekly goals identity migration', () => {
  it('retains newest duplicates and enforces null/non-null identities', () => {
    const database = new DatabaseSync(':memory:');
    try {
      database.exec(`
        CREATE TABLE weekly_goals (
          id TEXT PRIMARY KEY NOT NULL,
          week_start TEXT NOT NULL,
          metric TEXT NOT NULL,
          target INTEGER NOT NULL,
          employer_id TEXT,
          repeat INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
        INSERT INTO weekly_goals VALUES
          ('all-old', '2026-07-20', 'actual_gross', 100, NULL, 0, '2026-07-20', '2026-07-20'),
          ('all-new', '2026-07-20', 'actual_gross', 200, NULL, 1, '2026-07-21', '2026-07-21'),
          ('e-old', '2026-07-20', 'actual_gross', 300, 'e1', 0, '2026-07-20', '2026-07-20'),
          ('e-new', '2026-07-20', 'actual_gross', 400, 'e1', 1, '2026-07-21', '2026-07-21');
        ${WEEKLY_GOALS_IDENTITY_MIGRATION}
      `);

      expect(database.prepare('SELECT id, target FROM weekly_goals ORDER BY id;').all()).toEqual([
        { id: 'all-new', target: 200 },
        { id: 'e-new', target: 400 },
      ]);
      expect(() =>
        database.exec(
          "INSERT INTO weekly_goals VALUES ('duplicate', '2026-07-20', 'actual_gross', 500, NULL, 0, '2026-07-22', '2026-07-22');"
        )
      ).toThrow();
    } finally {
      database.close();
    }
  });
});
