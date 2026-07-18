/**
 * SQLite repositories. The UI never touches SQL directly — screens go through
 * zustand stores, which call these functions.
 */
import type {
  Employer,
  NotWorkedReason,
  RecurrenceRule,
  Role,
  ScheduleTemplate,
  Shift,
  ShiftActualsInput,
  ShiftBreak,
  WeeklyGoal,
} from '../domain/types';
import { previewRecurrence, type RecurringShiftPlan } from '../domain/copyWeek';
import { assertShiftTransition } from '../domain/shiftState';
import { validateDeductionBasisPoints, validateHourlyRateCents } from '../domain/validate';
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
  planned_expected_tips: number | null;
  planned_other_income: number | null;
  status: Shift['status'];
  transition_at: string;
  not_worked_reason: NotWorkedReason | null;
  not_worked_note: string | null;
  actual_start_min: number | null;
  actual_end_min: number | null;
  actual_breaks_json: string | null;
  actual_hourly_rate_snapshot: number | null;
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
  source_template_id: string | null;
  source_recurrence_rule_id: string | null;
  recurrence_key: string | null;
  created_at: string;
  updated_at: string;
}

interface ScheduleTemplateRow {
  id: string;
  name: string;
  employer_id: string;
  role_id: string | null;
  start_min: number;
  end_min: number;
  breaks_json: string;
  planned_expected_tips: number | null;
  planned_other_income: number | null;
  notes: string | null;
  archived: number;
}

/** DEF-14: rates are persisted as integer basis points (0–10000), domain uses fractions (0–1). */
function parseBreaks(json: string | null): ShiftBreak[] {
  if (!json) return [];
  try {
    const parsed = JSON.parse(json);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function assertSingleRowChanged(result: { changes: number }): void {
  if (result.changes !== 1) throw new Error('shift_write_conflict');
}

function assertValidRate(rate: number): void {
  if (!validateHourlyRateCents(rate).valid) throw new Error('rate_not_positive');
}

function assertValidDeduction(basisPoints: number): void {
  if (!validateDeductionBasisPoints(basisPoints).valid) {
    throw new Error('deduction_out_of_range');
  }
}

function assertRoleBelongsToEmployer(employerId: string, roleId?: string | null): void {
  if (!roleId) return;
  const role = getDb().getFirstSync<{ id: string }>(
    'SELECT id FROM roles WHERE id = ? AND employer_id = ?;',
    [roleId, employerId]
  );
  if (!role) throw new Error('role_employer_mismatch');
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
    plannedExpectedTips: r.planned_expected_tips,
    plannedOtherIncome: r.planned_other_income,
    status: r.status,
    transitionAt: r.transition_at,
    notWorkedReason: r.not_worked_reason,
    notWorkedNote: r.not_worked_note,
    actualStartMin: r.actual_start_min,
    actualEndMin: r.actual_end_min,
    actualBreaks: r.actual_breaks_json ? parseBreaks(r.actual_breaks_json) : null,
    actualHourlyRateSnapshot: r.actual_hourly_rate_snapshot,
    tipMethod: r.tip_method ?? null,
    directTips: r.direct_tips ?? undefined,
    poolContribution: r.pool_contribution ?? undefined,
    tipShareReceived: r.tip_share_received ?? undefined,
    tipOutPaid: r.tip_out_paid ?? undefined,
    sales: r.sales,
    otherIncome: r.other_income ?? undefined,
    deductionRateSnapshotBp: r.deduction_rate_snapshot_bp ?? undefined,
    expectedPayout: r.expected_payout ?? undefined,
    actualReceived: r.actual_received ?? undefined,
    payoutStatus: r.payout_status ?? undefined,
    notes: r.notes,
    sourceTemplateId: r.source_template_id,
    sourceRecurrenceRuleId: r.source_recurrence_rule_id,
    recurrenceKey: r.recurrence_key,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  };
}

function rowToScheduleTemplate(row: ScheduleTemplateRow): ScheduleTemplate {
  return {
    id: row.id,
    name: row.name,
    employerId: row.employer_id,
    roleId: row.role_id,
    startMin: row.start_min,
    endMin: row.end_min,
    breaks: parseBreaks(row.breaks_json),
    plannedExpectedTips: row.planned_expected_tips,
    plannedOtherIncome: row.planned_other_income,
    notes: row.notes,
    archived: row.archived === 1,
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
        default_hourly_rate: number;
        deduction_rate_bp: number;
        archived: number;
      }>('SELECT * FROM employers ORDER BY name COLLATE NOCASE;')
      .map((r) => ({
        id: r.id,
        name: r.name,
        color: r.color,
        defaultHourlyRate: r.default_hourly_rate,
        deductionRateBp: r.deduction_rate_bp,
        archived: r.archived === 1,
      }));
  },

  create(input: Omit<Employer, 'id' | 'archived'>): Employer {
    assertValidRate(input.defaultHourlyRate);
    assertValidDeduction(input.deductionRateBp);
    const id = uuid();
    const ts = nowIso();
    getDb().runSync(
      'INSERT INTO employers (id, name, color, default_hourly_rate, deduction_rate_bp, archived, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, ?, ?);',
      [
        id,
        input.name,
        input.color,
        input.defaultHourlyRate,
        input.deductionRateBp,
        ts,
        ts,
      ]
    );
    return { id, ...input, archived: false };
  },

  update(employer: Employer): void {
    assertValidRate(employer.defaultHourlyRate);
    assertValidDeduction(employer.deductionRateBp);
    getDb().runSync(
      'UPDATE employers SET name = ?, color = ?, default_hourly_rate = ?, deduction_rate_bp = ?, updated_at = ? WHERE id = ?;',
      [
        employer.name,
        employer.color,
        employer.defaultHourlyRate,
        employer.deductionRateBp,
        nowIso(),
        employer.id,
      ]
    );
  },

  archive(id: string, archived: boolean): void {
    getDb().runSync('UPDATE employers SET archived = ?, updated_at = ? WHERE id = ?;', [
      archived ? 1 : 0,
      nowIso(),
      id,
    ]);
  },

  /** RFP-225: hard deletion is unsupported; archive preserves all history. */
  remove(_id: string): never {
    throw new Error('employer_remove_not_supported');
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
    assertValidRate(input.hourlyRate);
    const id = uuid();
    const ts = nowIso();
    getDb().runSync(
      'INSERT INTO roles (id, employer_id, name, hourly_rate, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?);',
      [id, input.employerId, input.name, input.hourlyRate, ts, ts]
    );
    return { id, ...input };
  },

  update(role: Role): void {
    assertValidRate(role.hourlyRate);
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
  plannedExpectedTips?: number | null;
  plannedOtherIncome?: number | null;
  notes?: string | null;
  sourceTemplateId?: string | null;
  sourceRecurrenceRuleId?: string | null;
  recurrenceKey?: string | null;
}

function insertPlannedShift(
  database: ReturnType<typeof getDb>,
  input: NewShiftInput
): Shift {
  const id = uuid();
  const timestamp = nowIso();
  database.runSync(
    `INSERT INTO shifts
      (id, employer_id, role_id, date, start_min, end_min, breaks_json,
       hourly_rate_snapshot, planned_expected_tips, planned_other_income, status, transition_at,
       notes, source_template_id,
       source_recurrence_rule_id, recurrence_key, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'planned', ?, ?, ?, ?, ?, ?, ?);`,
    [
      id,
      input.employerId,
      input.roleId ?? null,
      input.date,
      input.startMin,
      input.endMin,
      JSON.stringify(input.breaks),
      input.hourlyRateSnapshot,
      input.plannedExpectedTips ?? null,
      input.plannedOtherIncome ?? null,
      timestamp,
      input.notes ?? null,
      input.sourceTemplateId ?? null,
      input.sourceRecurrenceRuleId ?? null,
      input.recurrenceKey ?? null,
      timestamp,
      timestamp,
    ]
  );
  return {
    id,
    ...input,
    roleId: input.roleId ?? null,
    status: 'planned',
    transitionAt: timestamp,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
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

  getByRecurrenceKey(key: string): Shift | null {
    const row = getDb().getFirstSync<ShiftRow>('SELECT * FROM shifts WHERE recurrence_key = ?;', [key]);
    return row ? rowToShift(row) : null;
  },

  create(input: NewShiftInput): Shift {
    assertValidRate(input.hourlyRateSnapshot);
    assertRoleBelongsToEmployer(input.employerId, input.roleId);
    if (input.recurrenceKey) {
      const existing = this.getByRecurrenceKey(input.recurrenceKey);
      if (existing) return existing;
    }
    return insertPlannedShift(getDb(), input);
  },

  /** Update scheduled fields only; never touches actuals or status. */
  updateScheduled(id: string, input: NewShiftInput, expectedStatus: Shift['status']): void {
    assertValidRate(input.hourlyRateSnapshot);
    assertRoleBelongsToEmployer(input.employerId, input.roleId);
    const result = getDb().runSync(
      `UPDATE shifts SET employer_id = ?, role_id = ?, date = ?, start_min = ?, end_min = ?,
        breaks_json = ?, hourly_rate_snapshot = ?, planned_expected_tips = ?,
        planned_other_income = ?, notes = CASE WHEN ? = 1 THEN ? ELSE notes END, updated_at = ?
       WHERE id = ? AND status = ?;`,
      [
        input.employerId,
        input.roleId ?? null,
        input.date,
        input.startMin,
        input.endMin,
        JSON.stringify(input.breaks),
        input.hourlyRateSnapshot,
        input.plannedExpectedTips ?? null,
        input.plannedOtherIncome ?? null,
        input.notes === undefined ? 0 : 1,
        input.notes ?? null,
        nowIso(),
        id,
        expectedStatus,
      ]
    );
    assertSingleRowChanged(result);
  },

  /**
   * ONE transaction: writes all actual values and flips status to 'worked'.
   * The scheduled fields are never modified here.
   */
  completeShift(
    id: string,
    actuals: ShiftActualsInput,
    expectedStatus: 'planned' | 'worked'
  ): Shift {
    if (expectedStatus === 'planned') assertShiftTransition('planned', 'worked');
    assertValidRate(actuals.actualHourlyRateSnapshot);
    assertValidDeduction(actuals.deductionRateSnapshotBp);
    const d = getDb();
    d.withTransactionSync(() => {
      const transitionedAt = nowIso();
      const result = d.runSync(
        `UPDATE shifts SET
          actual_start_min = ?, actual_end_min = ?, actual_breaks_json = ?,
          actual_hourly_rate_snapshot = ?,
          tip_method = ?, direct_tips = ?, pool_contribution = ?,
          tip_share_received = ?, tip_out_paid = ?, sales = ?, other_income = ?,
          deduction_rate_snapshot_bp = ?, expected_payout = ?, actual_received = ?,
          payout_status = ?, notes = COALESCE(?, notes),
          status = 'worked',
          transition_at = CASE WHEN ? = 'planned' THEN ? ELSE transition_at END,
          not_worked_reason = NULL, not_worked_note = NULL, updated_at = ?
         WHERE id = ? AND status = ?;`,
        [
          actuals.actualStartMin,
          actuals.actualEndMin,
          JSON.stringify(actuals.actualBreaks),
          actuals.actualHourlyRateSnapshot,
          actuals.tipMethod,
          actuals.directTips,
          actuals.poolContribution,
          actuals.tipShareReceived,
          actuals.tipOutPaid,
          actuals.sales ?? null,
          actuals.otherIncome ?? null,
          actuals.deductionRateSnapshotBp,
          actuals.expectedPayout,
          actuals.actualReceived,
          actuals.payoutStatus,
          actuals.notes ?? null,
          expectedStatus,
          transitionedAt,
          transitionedAt,
          id,
          expectedStatus,
        ]
      );
      assertSingleRowChanged(result);
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
    assertShiftTransition('planned', status);
    const timestamp = nowIso();
    const result = getDb().runSync(
      `UPDATE shifts SET status = ?, transition_at = ?, not_worked_reason = ?,
       not_worked_note = ?, updated_at = ? WHERE id = ? AND status = 'planned';`,
      [status, timestamp, reason, note, timestamp, id]
    );
    assertSingleRowChanged(result);
  },

  correctWorkedToPlanned(id: string, confirmedCorrection: boolean): void {
    assertShiftTransition('worked', 'planned', { confirmedCorrection });
    const timestamp = nowIso();
    const result = getDb().runSync(
      `UPDATE shifts SET status = 'planned', transition_at = ?,
       actual_start_min = NULL, actual_end_min = NULL, actual_breaks_json = NULL,
       actual_hourly_rate_snapshot = NULL, tip_method = NULL, direct_tips = NULL,
       pool_contribution = NULL, tip_share_received = NULL, tip_out_paid = NULL,
       sales = NULL, other_income = NULL, deduction_rate_snapshot_bp = NULL,
       expected_payout = NULL, actual_received = NULL, payout_status = NULL,
       not_worked_reason = NULL, not_worked_note = NULL, updated_at = ?
       WHERE id = ? AND status = 'worked';`,
      [timestamp, timestamp, id]
    );
    assertSingleRowChanged(result);
  },

  remove(id: string, expectedStatus: Shift['status']): void {
    const result = getDb().runSync('DELETE FROM shifts WHERE id = ? AND status = ?;', [
      id,
      expectedStatus,
    ]);
    assertSingleRowChanged(result);
  },
};

// ---------------------------------------------------------------------------
// Schedule templates and recurrence rules
// ---------------------------------------------------------------------------

export const scheduleTemplatesRepo = {
  list(): ScheduleTemplate[] {
    return getDb()
      .getAllSync<ScheduleTemplateRow>('SELECT * FROM schedule_templates ORDER BY name COLLATE NOCASE;')
      .map(rowToScheduleTemplate);
  },

  getById(id: string): ScheduleTemplate | null {
    const row = getDb().getFirstSync<ScheduleTemplateRow>(
      'SELECT * FROM schedule_templates WHERE id = ?;',
      [id]
    );
    return row ? rowToScheduleTemplate(row) : null;
  },

  create(input: Omit<ScheduleTemplate, 'id' | 'archived'>): ScheduleTemplate {
    assertRoleBelongsToEmployer(input.employerId, input.roleId);
    const id = uuid();
    const timestamp = nowIso();
    getDb().runSync(
      `INSERT INTO schedule_templates
       (id, name, employer_id, role_id, start_min, end_min, breaks_json,
        planned_expected_tips, planned_other_income, notes, archived, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?);`,
      [
        id,
        input.name,
        input.employerId,
        input.roleId ?? null,
        input.startMin,
        input.endMin,
        JSON.stringify(input.breaks),
        input.plannedExpectedTips ?? null,
        input.plannedOtherIncome ?? null,
        input.notes ?? null,
        timestamp,
        timestamp,
      ]
    );
    return { id, ...input, archived: false };
  },

  update(template: ScheduleTemplate): void {
    assertRoleBelongsToEmployer(template.employerId, template.roleId);
    getDb().runSync(
      `UPDATE schedule_templates SET name = ?, employer_id = ?, role_id = ?, start_min = ?,
       end_min = ?, breaks_json = ?, planned_expected_tips = ?, planned_other_income = ?,
       notes = ?, archived = ?, updated_at = ? WHERE id = ?;`,
      [
        template.name,
        template.employerId,
        template.roleId ?? null,
        template.startMin,
        template.endMin,
        JSON.stringify(template.breaks),
        template.plannedExpectedTips ?? null,
        template.plannedOtherIncome ?? null,
        template.notes ?? null,
        template.archived ? 1 : 0,
        nowIso(),
        template.id,
      ]
    );
  },
};

export interface SaveRecurrenceSeriesInput {
  rule: RecurrenceRule;
  preview: RecurringShiftPlan[];
  excludedKeys: string[];
  replaceDuplicates: boolean;
}

export interface SaveRecurrenceSeriesResult {
  rule: RecurrenceRule;
  createdShifts: Shift[];
  preview: RecurringShiftPlan[];
}

function recurrencePreviewSignature(plans: readonly RecurringShiftPlan[]): string {
  return JSON.stringify(
    plans.map((plan) => ({
      key: plan.recurrenceKey,
      conflict: plan.conflict,
      conflictingShiftIds: [...plan.conflictingShiftIds].sort(),
    }))
  );
}

export const recurrenceRulesRepo = {
  list(): RecurrenceRule[] {
    return getDb()
      .getAllSync<{
        id: string;
        template_id: string;
        cadence_weeks: number;
        weekdays_json: string;
        start_date: string;
        end_date: string | null;
        occurrence_count: number | null;
        active: number;
      }>('SELECT * FROM recurrence_rules ORDER BY start_date DESC;')
      .map((row) => ({
        id: row.id,
        templateId: row.template_id,
        cadenceWeeks: row.cadence_weeks === 2 ? 2 : 1,
        weekdays: JSON.parse(row.weekdays_json) as number[],
        startDate: row.start_date,
        endDate: row.end_date,
        occurrenceCount: row.occurrence_count,
        active: row.active === 1,
      }));
  },

  create(input: Omit<RecurrenceRule, 'id'> & { id?: string }): RecurrenceRule {
    const id = input.id ?? uuid();
    const timestamp = nowIso();
    getDb().runSync(
      `INSERT INTO recurrence_rules
       (id, template_id, cadence_weeks, weekdays_json, start_date, end_date,
        occurrence_count, active, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);`,
      [
        id,
        input.templateId,
        input.cadenceWeeks,
        JSON.stringify(input.weekdays),
        input.startDate,
        input.endDate ?? null,
        input.occurrenceCount ?? null,
        input.active ? 1 : 0,
        timestamp,
        timestamp,
      ]
    );
    return { ...input, id };
  },

  /**
   * Rebuilds and validates the preview at commit time, then applies the rule,
   * duplicate replacements, and every included occurrence in one transaction.
   */
  saveSeries(input: SaveRecurrenceSeriesInput): SaveRecurrenceSeriesResult {
    const database = getDb();
    let result: SaveRecurrenceSeriesResult | null = null;
    database.withTransactionSync(() => {
      const templateRow = database.getFirstSync<ScheduleTemplateRow>(
        'SELECT * FROM schedule_templates WHERE id = ?;',
        [input.rule.templateId]
      );
      if (!templateRow) throw new Error('template_not_found');
      const template = rowToScheduleTemplate(templateRow);
      if (template.archived) throw new Error('template_archived');

      const rateRow = template.roleId
        ? database.getFirstSync<{ hourly_rate: number }>(
            'SELECT hourly_rate FROM roles WHERE id = ? AND employer_id = ?;',
            [template.roleId, template.employerId]
          )
        : database.getFirstSync<{ hourly_rate: number }>(
            'SELECT default_hourly_rate AS hourly_rate FROM employers WHERE id = ?;',
            [template.employerId]
          );
      if (!rateRow) throw new Error('template_rate_not_found');
      assertValidRate(rateRow.hourly_rate);

      const existingShifts = database
        .getAllSync<ShiftRow>('SELECT * FROM shifts ORDER BY date, start_min;')
        .map(rowToShift);
      const regenerated = previewRecurrence(
        template,
        input.rule,
        rateRow.hourly_rate,
        existingShifts
      );
      if (regenerated.length === 0) throw new Error('recurrence_empty');
      if (recurrencePreviewSignature(regenerated) !== recurrencePreviewSignature(input.preview)) {
        throw new Error('recurrence_preview_stale');
      }

      const previewKeys = new Set(regenerated.map((plan) => plan.recurrenceKey));
      if (input.excludedKeys.some((key) => !previewKeys.has(key))) {
        throw new Error('recurrence_preview_invalid');
      }
      const excluded = new Set(input.excludedKeys);
      const timestamp = nowIso();
      database.runSync(
        `INSERT INTO recurrence_rules
         (id, template_id, cadence_weeks, weekdays_json, start_date, end_date,
          occurrence_count, active, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
          template_id = excluded.template_id,
          cadence_weeks = excluded.cadence_weeks,
          weekdays_json = excluded.weekdays_json,
          start_date = excluded.start_date,
          end_date = excluded.end_date,
          occurrence_count = excluded.occurrence_count,
          active = excluded.active,
          updated_at = excluded.updated_at;`,
        [
          input.rule.id,
          input.rule.templateId,
          input.rule.cadenceWeeks,
          JSON.stringify(input.rule.weekdays),
          input.rule.startDate,
          input.rule.endDate ?? null,
          input.rule.occurrenceCount ?? null,
          input.rule.active ? 1 : 0,
          timestamp,
          timestamp,
        ]
      );

      const createdShifts: Shift[] = [];
      for (const plan of regenerated) {
        const recurrenceKey = plan.recurrenceKey;
        if (!recurrenceKey || excluded.has(recurrenceKey)) continue;

        const alreadyGenerated = existingShifts.some(
          (shift) => shift.recurrenceKey === recurrenceKey
        );
        if (alreadyGenerated) continue;

        if (plan.conflict === 'duplicate') {
          if (!input.replaceDuplicates) throw new Error('recurrence_conflict_unresolved');
          for (const id of plan.conflictingShiftIds) {
            const duplicate = existingShifts.find((shift) => shift.id === id);
            if (duplicate?.status !== 'planned') throw new Error('recurrence_preview_stale');
            assertSingleRowChanged(
              database.runSync("DELETE FROM shifts WHERE id = ? AND status = 'planned';", [id])
            );
          }
        }

        const { conflict: _conflict, conflictingShiftIds: _ids, ...newShift } = plan;
        createdShifts.push(insertPlannedShift(database, newShift));
      }
      result = { rule: input.rule, createdShifts, preview: regenerated };
    });
    if (!result) throw new Error('recurrence_save_failed');
    return result;
  },

  update(rule: RecurrenceRule): void {
    getDb().runSync(
      `UPDATE recurrence_rules SET template_id = ?, cadence_weeks = ?, weekdays_json = ?,
       start_date = ?, end_date = ?, occurrence_count = ?, active = ?, updated_at = ? WHERE id = ?;`,
      [
        rule.templateId,
        rule.cadenceWeeks,
        JSON.stringify(rule.weekdays),
        rule.startDate,
        rule.endDate ?? null,
        rule.occurrenceCount ?? null,
        rule.active ? 1 : 0,
        nowIso(),
        rule.id,
      ]
    );
  },

  end(id: string): void {
    getDb().runSync('UPDATE recurrence_rules SET active = 0, updated_at = ? WHERE id = ?;', [
      nowIso(),
      id,
    ]);
  },
};

export const weeklyGoalsRepo = {
  list(): WeeklyGoal[] {
    return getDb()
      .getAllSync<{
        id: string;
        week_start: string;
        metric: WeeklyGoal['metric'];
        target: number;
        employer_id: string | null;
        repeat: number;
      }>('SELECT * FROM weekly_goals ORDER BY week_start DESC;')
      .map((row) => ({
        id: row.id,
        weekStart: row.week_start,
        metric: row.metric,
        target: row.target,
        employerId: row.employer_id,
        repeat: row.repeat === 1,
      }));
  },

  create(input: Omit<WeeklyGoal, 'id'>): WeeklyGoal {
    const id = uuid();
    const timestamp = nowIso();
    getDb().runSync(
      `INSERT INTO weekly_goals
       (id, week_start, metric, target, employer_id, repeat, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?);`,
      [
        id,
        input.weekStart,
        input.metric,
        input.target,
        input.employerId ?? null,
        input.repeat ? 1 : 0,
        timestamp,
        timestamp,
      ]
    );
    return { id, ...input };
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

  remove(key: string): void {
    getDb().runSync('DELETE FROM settings WHERE key = ?;', [key]);
  },

  removeByPrefix(prefix: string): void {
    getDb().runSync('DELETE FROM settings WHERE key LIKE ?;', [`${prefix}%`]);
  },
};
