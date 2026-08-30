jest.mock('../../data/db', () => ({
  getDb: jest.fn(),
  nowIso: () => '2026-07-18T12:00:00.000Z',
}));
jest.mock('../../data/ids', () => ({ uuid: () => 'new-shift' }));

import { getDb } from '../../data/db';
import {
  recurrenceRulesRepo,
  shiftsRepo,
  type NewShiftInput,
} from '../../data/repositories';
import { previewRecurrence } from '../copyWeek';
import type { RecurrenceRule, ScheduleTemplate, Shift, ShiftActualsInput } from '../types';

const getDbMock = getDb as jest.MockedFunction<typeof getDb>;
const runSync = jest.fn((..._args: unknown[]) => ({ changes: 1 }));
const getAllSync = jest.fn((): Record<string, unknown>[] => []);
const defaultShiftRow: Record<string, unknown> = {
  id: 'shift-1',
  employer_id: 'employer-1',
  role_id: null,
  date: '2026-07-18',
  start_min: 540,
  end_min: 1020,
  breaks_json: '[]',
  hourly_rate_snapshot: 2000,
  planned_expected_tips: 0,
  planned_other_income: null,
  status: 'worked',
  transition_at: '2026-07-18T12:00:00.000Z',
  not_worked_reason: null,
  not_worked_note: null,
  actual_start_min: 540,
  actual_end_min: 1020,
  actual_breaks_json: '[]',
  actual_hourly_rate_snapshot: 2000,
  tip_method: 'direct',
  direct_tips: 0,
  pool_contribution: 0,
  tip_share_received: 0,
  tip_out_paid: 0,
  sales: null,
  other_income: 500,
  deduction_rate_snapshot_bp: 2000,
  expected_payout: 0,
  actual_received: 0,
  payout_status: 'not_expected',
  notes: null,
  source_template_id: null,
  source_recurrence_rule_id: null,
  recurrence_key: null,
  created_at: '2026-07-18T10:00:00.000Z',
  updated_at: '2026-07-18T12:00:00.000Z',
};
const getFirstSync = jest.fn(
  (..._args: unknown[]): Record<string, unknown> | null => defaultShiftRow
);
const withTransactionSync = jest.fn((callback: () => void) => callback());

const actuals: ShiftActualsInput = {
  actualStartMin: 540,
  actualEndMin: 1020,
  actualBreaks: [],
  actualHourlyRateSnapshot: 2000,
  tipMethod: 'direct',
  directTips: 0,
  poolContribution: 0,
  tipShareReceived: 0,
  tipOutPaid: 0,
  otherIncome: 500,
  deductionRateSnapshotBp: 2000,
  expectedPayout: 0,
  actualReceived: 0,
  payoutStatus: 'not_expected',
};

const scheduledInput: NewShiftInput = {
  employerId: 'employer-1',
  roleId: null,
  date: '2026-07-18',
  startMin: 540,
  endMin: 1020,
  breaks: [],
  hourlyRateSnapshot: 2000,
};

beforeEach(() => {
  runSync.mockClear();
  runSync.mockReturnValue({ changes: 1 });
  getFirstSync.mockReset();
  getFirstSync.mockReturnValue(defaultShiftRow);
  getAllSync.mockReset();
  getAllSync.mockReturnValue([]);
  withTransactionSync.mockClear();
  getDbMock.mockReset();
  getDbMock.mockReturnValue({
    runSync,
    getFirstSync,
    getAllSync,
    withTransactionSync,
  } as unknown as ReturnType<typeof getDb>);
});

describe('recurrence series transaction integrity', () => {
  const template: ScheduleTemplate = {
    id: 'template-1',
    name: 'Dinner',
    employerId: 'employer-1',
    roleId: null,
    startMin: 1020,
    endMin: 1380,
    breaks: [],
    archived: false,
  };
  const templateRow = {
    id: template.id,
    name: template.name,
    employer_id: template.employerId,
    role_id: null,
    start_min: template.startMin,
    end_min: template.endMin,
    breaks_json: '[]',
    planned_expected_tips: null,
    planned_other_income: null,
    notes: null,
    archived: 0,
  };
  const rule: RecurrenceRule = {
    id: 'rule-1',
    templateId: template.id,
    cadenceWeeks: 1,
    weekdays: [0],
    startDate: '2026-07-20',
    occurrenceCount: 2,
    active: true,
  };

  const existingShift = (overrides: Partial<Shift> = {}): Shift => ({
    id: 'existing',
    employerId: 'employer-1',
    roleId: null,
    date: '2026-07-20',
    startMin: 1020,
    endMin: 1380,
    breaks: [],
    hourlyRateSnapshot: 2000,
    status: 'planned',
    ...overrides,
  });

  const toRow = (shift: Shift) => ({
    id: shift.id,
    employer_id: shift.employerId,
    role_id: shift.roleId ?? null,
    date: shift.date,
    start_min: shift.startMin,
    end_min: shift.endMin,
    breaks_json: JSON.stringify(shift.breaks),
    hourly_rate_snapshot: shift.hourlyRateSnapshot,
    planned_expected_tips: null,
    planned_other_income: null,
    status: shift.status,
    transition_at: '2026-07-18T12:00:00.000Z',
    not_worked_reason: null,
    not_worked_note: null,
    actual_start_min: null,
    actual_end_min: null,
    actual_breaks_json: null,
    actual_hourly_rate_snapshot: null,
    tip_method: null,
    direct_tips: null,
    pool_contribution: null,
    tip_share_received: null,
    tip_out_paid: null,
    sales: null,
    other_income: null,
    deduction_rate_snapshot_bp: null,
    expected_payout: null,
    actual_received: null,
    payout_status: null,
    notes: null,
    source_template_id: null,
    source_recurrence_rule_id: null,
    recurrence_key: shift.recurrenceKey ?? null,
    created_at: '2026-07-18T12:00:00.000Z',
    updated_at: '2026-07-18T12:00:00.000Z',
  });

  function mockSeriesReads(existing: Shift[]) {
    getFirstSync.mockImplementation((sqlValue: unknown) => {
      const sql = String(sqlValue);
      if (sql.includes('schedule_templates')) return templateRow;
      if (sql.includes('default_hourly_rate')) return { hourly_rate: 2000 };
      return null;
    });
    getAllSync.mockReturnValue(existing.map(toRow));
  }

  it('upserts the rule and inserts every occurrence in one transaction', () => {
    mockSeriesReads([]);
    const preview = previewRecurrence(template, rule, 2000, []);
    const saved = recurrenceRulesRepo.saveSeries({
      rule,
      preview,
      excludedKeys: [],
      replaceDuplicates: false,
    });

    expect(withTransactionSync).toHaveBeenCalledTimes(1);
    expect(saved.createdShifts).toHaveLength(2);
    expect(runSync.mock.calls.filter(([sql]) => String(sql).includes('INSERT INTO recurrence_rules'))).toHaveLength(1);
    expect(runSync.mock.calls.filter(([sql]) => String(sql).includes('INSERT INTO shifts'))).toHaveLength(2);
  });

  it('replaces a planned duplicate atomically and treats an existing recurrence key as idempotent', () => {
    const duplicate = existingShift();
    mockSeriesReads([duplicate]);
    const oneOccurrence = { ...rule, occurrenceCount: 1 };
    const preview = previewRecurrence(template, oneOccurrence, 2000, [duplicate]);
    recurrenceRulesRepo.saveSeries({
      rule: oneOccurrence,
      preview,
      excludedKeys: [],
      replaceDuplicates: true,
    });
    expect(runSync.mock.calls.some(([sql]) => String(sql).includes('DELETE FROM shifts'))).toBe(true);
    expect(runSync.mock.calls.filter(([sql]) => String(sql).includes('INSERT INTO shifts'))).toHaveLength(1);

    runSync.mockClear();
    const generated = existingShift({ recurrenceKey: preview[0].recurrenceKey });
    mockSeriesReads([generated]);
    const retryPreview = previewRecurrence(template, oneOccurrence, 2000, [generated]);
    recurrenceRulesRepo.saveSeries({
      rule: oneOccurrence,
      preview: retryPreview,
      excludedKeys: [],
      replaceDuplicates: true,
    });
    expect(runSync.mock.calls.some(([sql]) => String(sql).includes('DELETE FROM shifts'))).toBe(false);
    expect(runSync.mock.calls.filter(([sql]) => String(sql).includes('INSERT INTO shifts'))).toHaveLength(0);
  });

  it('rejects a stale preview before any rule, replacement, or occurrence write', () => {
    const preview = previewRecurrence(template, { ...rule, occurrenceCount: 1 }, 2000, []);
    mockSeriesReads([existingShift()]);
    expect(() =>
      recurrenceRulesRepo.saveSeries({
        rule: { ...rule, occurrenceCount: 1 },
        preview,
        excludedKeys: [],
        replaceDuplicates: false,
      })
    ).toThrow('recurrence_preview_stale');
    expect(runSync).not.toHaveBeenCalled();
  });
});

describe('shift repository compare-and-set transitions', () => {
  it('completes planned shifts and edits worked actuals using the expected status', () => {
    shiftsRepo.completeShift('shift-1', actuals, 'planned');
    expect(runSync).toHaveBeenLastCalledWith(
      expect.stringContaining('WHERE id = ? AND status = ?'),
      expect.arrayContaining(['planned'])
    );

    runSync.mockClear();
    shiftsRepo.completeShift('shift-1', actuals, 'worked');
    expect(runSync.mock.calls[0][1]).toEqual(expect.arrayContaining(['worked']));
  });

  it('records transition time and expected planned status for not-worked changes', () => {
    shiftsRepo.markNotWorked('shift-1', 'missed', 'sick', null);
    expect(runSync).toHaveBeenCalledWith(
      expect.stringContaining("WHERE id = ? AND status = 'planned'"),
      expect.arrayContaining(['2026-07-18T12:00:00.000Z', 'shift-1'])
    );
  });

  it('fails when a conditional transition changes no row', () => {
    runSync.mockReturnValueOnce({ changes: 0 });
    expect(() => shiftsRepo.markNotWorked('shift-1', 'missed', 'sick', null)).toThrow(
      'shift_write_conflict'
    );
  });

  it('requires confirmation and clears actual fields in worked correction', () => {
    expect(() => shiftsRepo.correctWorkedToPlanned('shift-1', false)).toThrow(
      'invalid_shift_transition'
    );
    shiftsRepo.correctWorkedToPlanned('shift-1', true);
    expect(runSync).toHaveBeenCalledWith(
      expect.stringMatching(/actual_start_min = NULL[\s\S]*WHERE id = \? AND status = 'worked'/),
      ['2026-07-18T12:00:00.000Z', '2026-07-18T12:00:00.000Z', 'shift-1']
    );
  });

  it('preserves notes when omitted and clears them only when explicitly changed', () => {
    shiftsRepo.updateScheduled('shift-1', scheduledInput, 'planned');
    expect((runSync.mock.calls[0][1] as unknown[]).slice(9, 11)).toEqual([0, null]);

    runSync.mockClear();
    shiftsRepo.updateScheduled('shift-1', { ...scheduledInput, notes: null }, 'planned');
    expect((runSync.mock.calls[0][1] as unknown[]).slice(9, 11)).toEqual([1, null]);
    expect(runSync.mock.calls[0][0]).toContain('CASE WHEN ? = 1 THEN ? ELSE notes END');
  });

  it('rejects a role owned by another employer before writing', () => {
    getFirstSync.mockReturnValueOnce(null);
    expect(() =>
      shiftsRepo.updateScheduled(
        'shift-1',
        { ...scheduledInput, roleId: 'other-role' },
        'planned'
      )
    ).toThrow('role_employer_mismatch');
    expect(runSync).not.toHaveBeenCalled();
  });

  it('rejects invalid rate and deduction values at the repository boundary', () => {
    expect(() =>
      shiftsRepo.updateScheduled(
        'shift-1',
        { ...scheduledInput, hourlyRateSnapshot: 0 },
        'planned'
      )
    ).toThrow('rate_not_positive');
    expect(() =>
      shiftsRepo.completeShift(
        'shift-1',
        { ...actuals, deductionRateSnapshotBp: 10001 },
        'planned'
      )
    ).toThrow('deduction_out_of_range');
    expect(runSync).not.toHaveBeenCalled();
  });
});
