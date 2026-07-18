/**
 * SQLite repositories. The UI never touches SQL directly — screens go through
 * zustand stores, which call these functions.
 */
import type {
  Employer,
  NotWorkedReason,
  Role,
  Shift,
  ShiftActualsInput,
  ShiftBreak,
} from '../domain/types';
import { getDb, nowIso } from './db';
import { uuid } from './ids';

// ---------------------------------------------------------------------------
// Row mapping
// ---------------------------------------------------------------------------

interface ShiftRow {
  id: string;
  employer_id: string;
  role_id: string | null;
  date: string;
  start_min: number;
  end_min: number;
  breaks_json: string;
  hourly_rate_snapshot: number;
  status: Shift['status'];
  not_worked_reason: NotWorkedReason | null;
  not_worked_note: string | null;
  actual_start_min: number | null;
  actual_end_min: number | null;
  actual_breaks_json: string | null;
  tip_method: Shift['tipMethod'];
  direct_tips: number | null;
  pool_contribution: number | null;
  tip_share_received: number | null;
  tip_out_paid: number | null;
  sales: number | null;
  other_income: number | null;
  /** Basis points 0–10000 (DEF-14). */
  deduction_rate_snapshot_bp: number | null;
  expected_payout: number | null;
  actual_received: number | null;
  payout_status: Shift['payoutStatus'] | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

/** DEF-14: rates are persisted as integer basis points (0–10000), domain uses fractions (0–1). */
export function fractionToBp(fraction: number): number {
  return Math.round(Math.min(Math.max(fraction, 0), 1) * 10000);
}

export function bpToFraction(bp: number): number {
  return Math.min(Math.max(bp, 0), 10000) / 10000;
}

function parseBreaks(json: string | null): ShiftBreak[] {
  if (!json) return [];
  try {
    const parsed = JSON.parse(json);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function rowToShift(r: ShiftRow): Shift {
  return {
    id: r.id,
    employerId: r.employer_id,
    roleId: r.role_id,
    date: r.date,
    startMin: r.start_min,
    endMin: r.end_min,
    breaks: parseBreaks(r.breaks_json),
    hourlyRateSnapshot: r.hourly_rate_snapshot,
    status: r.status,
    notWorkedReason: r.not_worked_reason,
    notWorkedNote: r.not_worked_note,
    actualStartMin: r.actual_start_min,
    actualEndMin: r.actual_end_min,
    actualBreaks: r.actual_breaks_json ? parseBreaks(r.actual_breaks_json) : null,
    tipMethod: r.tip_method ?? null,
    directTips: r.direct_tips ?? undefined,
    poolContribution: r.pool_contribution ?? undefined,
    tipShareReceived: r.tip_share_received ?? undefined,
    tipOutPaid: r.tip_out_paid ?? undefined,
    sales: r.sales,
    otherIncome: r.other_income ?? undefined,
    deductionRateSnapshot:
      r.deduction_rate_snapshot_bp != null ? bpToFraction(r.deduction_rate_snapshot_bp) : undefined,
    expectedPayout: r.expected_payout ?? undefined,
    actualReceived: r.actual_received ?? undefined,
    payoutStatus: r.payout_status ?? undefined,
    notes: r.notes,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  };
}

// ---------------------------------------------------------------------------
// Employers
// ---------------------------------------------------------------------------

export const employersRepo = {
  list(): Employer[] {
    return getDb()
      .getAllSync<{
        id: string;
        name: string;
        color: string;
        deduction_rate_bp: number;
      }>('SELECT * FROM employers ORDER BY name COLLATE NOCASE;')
      .map((r) => ({
        id: r.id,
        name: r.name,
        color: r.color,
        deductionRate: bpToFraction(r.deduction_rate_bp),
      }));
  },

  create(input: Omit<Employer, 'id'>): Employer {
    const id = uuid();
    const ts = nowIso();
    getDb().runSync(
      'INSERT INTO employers (id, name, color, deduction_rate_bp, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?);',
      [id, input.name, input.color, fractionToBp(input.deductionRate), ts, ts]
    );
    return { id, ...input };
  },

  update(employer: Employer): void {
    getDb().runSync(
      'UPDATE employers SET name = ?, color = ?, deduction_rate_bp = ?, updated_at = ? WHERE id = ?;',
      [employer.name, employer.color, fractionToBp(employer.deductionRate), nowIso(), employer.id]
    );
  },

  /**
   * DEF-08 (safe part): an employer with historical shifts must never be
   * hard-deleted (PRD §9). Throws `employer_has_shifts` in that case; archive
   * semantics and the employer-management screen remain backlog items.
   */
  remove(id: string): void {
    const d = getDb();
    const row = d.getFirstSync<{ n: number }>(
      'SELECT COUNT(*) AS n FROM shifts WHERE employer_id = ?;',
      [id]
    );
    if ((row?.n ?? 0) > 0) {
      throw new Error('employer_has_shifts');
    }
    d.withTransactionSync(() => {
      d.runSync('DELETE FROM roles WHERE employer_id = ?;', [id]);
      d.runSync('DELETE FROM employers WHERE id = ?;', [id]);
    });
  },
};

// ---------------------------------------------------------------------------
// Roles
// ---------------------------------------------------------------------------

export const rolesRepo = {
  list(): Role[] {
    return getDb()
      .getAllSync<{
        id: string;
        employer_id: string;
        name: string;
        hourly_rate: number;
      }>('SELECT * FROM roles ORDER BY name COLLATE NOCASE;')
      .map((r) => ({ id: r.id, employerId: r.employer_id, name: r.name, hourlyRate: r.hourly_rate }));
  },

  create(input: Omit<Role, 'id'>): Role {
    const id = uuid();
    const ts = nowIso();
    getDb().runSync(
      'INSERT INTO roles (id, employer_id, name, hourly_rate, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?);',
      [id, input.employerId, input.name, input.hourlyRate, ts, ts]
    );
    return { id, ...input };
  },

  update(role: Role): void {
    getDb().runSync('UPDATE roles SET name = ?, hourly_rate = ?, updated_at = ? WHERE id = ?;', [
      role.name,
      role.hourlyRate,
      nowIso(),
      role.id,
    ]);
  },

  remove(id: string): void {
    getDb().runSync('DELETE FROM roles WHERE id = ?;', [id]);
  },
};

// ---------------------------------------------------------------------------
// Shifts
// ---------------------------------------------------------------------------

export interface NewShiftInput {
  employerId: string;
  roleId?: string | null;
  date: string;
  startMin: number;
  endMin: number;
  breaks: ShiftBreak[];
  hourlyRateSnapshot: number;
  notes?: string | null;
}

export const shiftsRepo = {
  list(): Shift[] {
    return getDb()
      .getAllSync<ShiftRow>('SELECT * FROM shifts ORDER BY date, start_min;')
      .map(rowToShift);
  },

  getById(id: string): Shift | null {
    const row = getDb().getFirstSync<ShiftRow>('SELECT * FROM shifts WHERE id = ?;', [id]);
    return row ? rowToShift(row) : null;
  },

  create(input: NewShiftInput): Shift {
    const id = uuid();
    const ts = nowIso();
    getDb().runSync(
      `INSERT INTO shifts
        (id, employer_id, role_id, date, start_min, end_min, breaks_json,
         hourly_rate_snapshot, status, notes, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'scheduled', ?, ?, ?);`,
      [
        id,
        input.employerId,
        input.roleId ?? null,
        input.date,
        input.startMin,
        input.endMin,
        JSON.stringify(input.breaks),
        input.hourlyRateSnapshot,
        input.notes ?? null,
        ts,
        ts,
      ]
    );
    const created = this.getById(id);
    if (!created) throw new Error('Failed to create shift');
    return created;
  },

  /** Update scheduled fields only; never touches actuals or status. */
  updateScheduled(id: string, input: NewShiftInput): void {
    getDb().runSync(
      `UPDATE shifts SET employer_id = ?, role_id = ?, date = ?, start_min = ?, end_min = ?,
        breaks_json = ?, hourly_rate_snapshot = ?, notes = ?, updated_at = ?
       WHERE id = ?;`,
      [
        input.employerId,
        input.roleId ?? null,
        input.date,
        input.startMin,
        input.endMin,
        JSON.stringify(input.breaks),
        input.hourlyRateSnapshot,
        input.notes ?? null,
        nowIso(),
        id,
      ]
    );
  },

  /**
   * ONE transaction: writes all actual values and flips status to 'worked'.
   * The scheduled fields are never modified here.
   */
  completeShift(id: string, actuals: ShiftActualsInput): Shift {
    const d = getDb();
    d.withTransactionSync(() => {
      d.runSync(
        `UPDATE shifts SET
          actual_start_min = ?, actual_end_min = ?, actual_breaks_json = ?,
          tip_method = ?, direct_tips = ?, pool_contribution = ?,
          tip_share_received = ?, tip_out_paid = ?, sales = ?, other_income = ?,
          deduction_rate_snapshot_bp = ?, expected_payout = ?, actual_received = ?,
          payout_status = ?, notes = COALESCE(?, notes),
          status = 'worked', not_worked_reason = NULL, not_worked_note = NULL, updated_at = ?
         WHERE id = ?;`,
        [
          actuals.actualStartMin,
          actuals.actualEndMin,
          JSON.stringify(actuals.actualBreaks),
          actuals.tipMethod,
          actuals.directTips,
          actuals.poolContribution,
          actuals.tipShareReceived,
          actuals.tipOutPaid,
          actuals.sales ?? null,
          actuals.otherIncome ?? null,
          fractionToBp(actuals.deductionRateSnapshot),
          actuals.expectedPayout,
          actuals.actualReceived,
          actuals.payoutStatus,
          actuals.notes ?? null,
          nowIso(),
          id,
        ]
      );
    });
    const updated = this.getById(id);
    if (!updated) throw new Error('Shift not found after completion');
    return updated;
  },

  markNotWorked(
    id: string,
    status: 'missed' | 'cancelled',
    reason: NotWorkedReason,
    note: string | null
  ): void {
    getDb().runSync(
      'UPDATE shifts SET status = ?, not_worked_reason = ?, not_worked_note = ?, updated_at = ? WHERE id = ?;',
      [status, reason, note, nowIso(), id]
    );
  },

  remove(id: string): void {
    getDb().runSync('DELETE FROM shifts WHERE id = ?;', [id]);
  },
};

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

export const settingsRepo = {
  get(key: string): string | null {
    const row = getDb().getFirstSync<{ value: string }>(
      'SELECT value FROM settings WHERE key = ?;',
      [key]
    );
    return row?.value ?? null;
  },

  set(key: string, value: string): void {
    getDb().runSync(
      'INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value;',
      [key, value]
    );
  },
};
