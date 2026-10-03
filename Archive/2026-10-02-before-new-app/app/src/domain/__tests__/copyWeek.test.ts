import {
  applyTemplateOnDate,
  copyWeekForward,
  previewCopyWeek,
  previewRecurrence,
} from '../copyWeek';
import {
  addDaysIso,
  addMonthsIso,
  isValidIsoDate,
  minutesToHHMM,
  monthDatesIso,
  parseHHMM,
  startOfWeekIso,
  weekDatesIso,
} from '../dates';
import type { RecurrenceRule, ScheduleTemplate, Shift } from '../types';

const shift = (overrides: Partial<Shift>): Shift => ({
  id: 'id',
  employerId: 'e1',
  date: '2026-07-13', // Monday
  startMin: 17 * 60,
  endMin: 23 * 60,
  breaks: [],
  hourlyRateSnapshot: 2000,
  status: 'planned',
  ...overrides,
});

describe('date helpers', () => {
  it('validates ISO dates', () => {
    expect(isValidIsoDate('2026-07-17')).toBe(true);
    expect(isValidIsoDate('2026-02-30')).toBe(false);
    expect(isValidIsoDate('2026-7-17')).toBe(false);
  });

  it('adds days across month boundaries', () => {
    expect(addDaysIso('2026-07-28', 7)).toBe('2026-08-04');
    expect(addDaysIso('2026-01-01', -1)).toBe('2025-12-31');
  });

  it('computes Monday-based week start', () => {
    expect(startOfWeekIso('2026-07-17')).toBe('2026-07-13'); // Friday → Monday
    expect(startOfWeekIso('2026-07-13')).toBe('2026-07-13'); // Monday → itself
    expect(startOfWeekIso('2026-07-19')).toBe('2026-07-13'); // Sunday → previous Monday
  });

  it('produces seven consecutive dates', () => {
    const week = weekDatesIso('2026-07-13');
    expect(week).toHaveLength(7);
    expect(week[0]).toBe('2026-07-13');
    expect(week[6]).toBe('2026-07-19');
  });

  it('navigates calendar months and clamps end-of-month dates', () => {
    expect(addMonthsIso('2026-01-31', 1)).toBe('2026-02-28');
    expect(addMonthsIso('2026-03-31', -1)).toBe('2026-02-28');
    expect(monthDatesIso('2026-02-14')).toHaveLength(28);
    expect(monthDatesIso('2028-02-14')).toHaveLength(29);
  });

  it('formats and parses HH:MM, wrapping overnight minutes', () => {
    expect(minutesToHHMM(17 * 60 + 5)).toBe('17:05');
    expect(minutesToHHMM(1460)).toBe('00:20');
    expect(parseHHMM('17:30')).toBe(1050);
    expect(parseHHMM('24:00')).toBeNull();
    expect(parseHHMM('9:60')).toBeNull();
    expect(parseHHMM('nonsense')).toBeNull();
  });
});

describe('copyWeekForward', () => {
  it('copies scheduled shifts to the same weekday next week', () => {
    const shifts = [
      shift({ id: 'a', date: '2026-07-13' }),
      shift({ id: 'b', date: '2026-07-17', startMin: 18 * 60, endMin: 20 }), // overnight Fri
    ];
    const copies = copyWeekForward(shifts, '2026-07-13');
    expect(copies).toHaveLength(2);
    expect(copies[0].date).toBe('2026-07-20');
    expect(copies[1].date).toBe('2026-07-24');
    expect(copies[1].startMin).toBe(18 * 60);
    expect(copies[1].endMin).toBe(20);
  });

  it('copies only shifts with status scheduled', () => {
    const shifts = [
      shift({ id: 'a', status: 'planned' }),
      shift({ id: 'b', status: 'worked', date: '2026-07-14' }),
      shift({ id: 'c', status: 'missed', date: '2026-07-15' }),
      shift({ id: 'd', status: 'cancelled', date: '2026-07-16' }),
    ];
    const copies = copyWeekForward(shifts, '2026-07-13');
    expect(copies).toHaveLength(1);
    expect(copies[0].date).toBe('2026-07-20');
  });

  it('ignores shifts outside the viewed week', () => {
    const shifts = [
      shift({ id: 'a', date: '2026-07-12' }), // Sunday of previous week
      shift({ id: 'b', date: '2026-07-20' }), // Monday of next week
    ];
    expect(copyWeekForward(shifts, '2026-07-13')).toHaveLength(0);
  });

  it('copies plan fields (breaks, role, rate) but never actual/completion data', () => {
    const source = shift({
      id: 'a',
      roleId: 'r1',
      breaks: [{ label: 'Lunch', startMin: 20 * 60, durationMin: 30, paid: false }],
      hourlyRateSnapshot: 2250,
      plannedExpectedTips: 4500,
      plannedOtherIncome: 500,
      notes: 'bring apron',
      // stale actual data on a scheduled shift must not propagate
      actualStartMin: 17 * 60,
      directTips: 9900,
    });
    const [copy] = copyWeekForward([source], '2026-07-13');
    expect(copy.roleId).toBe('r1');
    expect(copy.hourlyRateSnapshot).toBe(2250);
    expect(copy.plannedExpectedTips).toBe(4500);
    expect(copy.plannedOtherIncome).toBe(500);
    expect(copy.breaks).toEqual([
      { label: 'Lunch', startMin: 20 * 60, durationMin: 30, paid: false },
    ]);
    expect(copy.notes).toBe('bring apron');
    expect('actualStartMin' in copy).toBe(false);
    expect('directTips' in copy).toBe(false);
    expect('status' in copy).toBe(false);
  });

  it('deep-copies breaks so mutating the copy never touches the source', () => {
    const source = shift({
      breaks: [{ label: 'Lunch', startMin: 20 * 60, durationMin: 30, paid: false }],
    });
    const [copy] = copyWeekForward([source], '2026-07-13');
    copy.breaks[0].durationMin = 99;
    expect(source.breaks[0].durationMin).toBe(30);
  });

  it('previews destination duplicates with stable idempotency keys', () => {
    const source = shift({ id: 'source', date: '2026-07-13' });
    const firstPreview = previewCopyWeek([source], '2026-07-13');
    expect(firstPreview[0]).toMatchObject({
      date: '2026-07-20',
      recurrenceKey: 'copy-week:source:2026-07-20',
      conflict: 'none',
    });

    const persisted = shift({
      id: 'copy',
      date: '2026-07-20',
      recurrenceKey: firstPreview[0].recurrenceKey,
    });
    expect(previewCopyWeek([source, persisted], '2026-07-13')[0]).toMatchObject({
      conflict: 'duplicate',
      conflictingShiftIds: ['copy'],
    });
  });

  it('previews cross-employer overlaps separately from duplicates', () => {
    const source = shift({ id: 'source', date: '2026-07-13' });
    const destinationOverlap = shift({
      id: 'overlap',
      employerId: 'e2',
      date: '2026-07-20',
      startMin: 18 * 60,
      endMin: 22 * 60,
    });
    expect(previewCopyWeek([source, destinationOverlap], '2026-07-13')[0]).toMatchObject({
      conflict: 'overlap',
      conflictingShiftIds: ['overlap'],
    });
  });
});

describe('schedule templates and recurrence preview', () => {
  const template: ScheduleTemplate = {
    id: 'template-1',
    name: 'Dinner',
    employerId: 'e1',
    roleId: 'r1',
    startMin: 17 * 60,
    endMin: 23 * 60,
    breaks: [{ label: 'Break', startMin: 20 * 60, durationMin: 20, paid: false }],
    plannedExpectedTips: 3500,
    plannedOtherIncome: 250,
    notes: 'Black shirt',
    archived: false,
  };

  const rule = (overrides: Partial<RecurrenceRule> = {}): RecurrenceRule => ({
    id: 'rule-1',
    templateId: template.id,
    cadenceWeeks: 1,
    weekdays: [0, 2],
    startDate: '2026-07-13',
    occurrenceCount: 4,
    active: true,
    ...overrides,
  });

  it('applies planned values only and deep-copies break presets', () => {
    const plan = applyTemplateOnDate(template, '2026-07-20', 2450);
    expect(plan).toMatchObject({
      employerId: 'e1',
      roleId: 'r1',
      date: '2026-07-20',
      hourlyRateSnapshot: 2450,
      plannedExpectedTips: 3500,
      plannedOtherIncome: 250,
      sourceTemplateId: 'template-1',
    });
    plan.breaks[0].durationMin = 99;
    expect(template.breaks[0].durationMin).toBe(20);
    expect('status' in plan).toBe(false);
    expect('actualStartMin' in plan).toBe(false);
  });

  it('generates selected weekdays with stable idempotency keys', () => {
    const plans = previewRecurrence(template, rule(), 2450, []);
    expect(plans.map((plan) => plan.date)).toEqual([
      '2026-07-13',
      '2026-07-15',
      '2026-07-20',
      '2026-07-22',
    ]);
    expect(plans[0].recurrenceKey).toBe('rule-1:template-1:2026-07-13');
    expect(plans.every((plan) => plan.sourceRecurrenceRuleId === 'rule-1')).toBe(true);
  });

  it('honors a biweekly cadence', () => {
    const plans = previewRecurrence(
      template,
      rule({ cadenceWeeks: 2, weekdays: [0], occurrenceCount: 3 }),
      2000,
      []
    );
    expect(plans.map((plan) => plan.date)).toEqual([
      '2026-07-13',
      '2026-07-27',
      '2026-08-10',
    ]);
  });

  it('generates an end-date-only series through its date boundary without a 52-shift cap', () => {
    const plans = previewRecurrence(
      template,
      rule({
        weekdays: [0, 1, 2, 3, 4, 5, 6],
        occurrenceCount: null,
        endDate: '2026-09-30',
      }),
      2000,
      []
    );
    expect(plans.length).toBeGreaterThan(52);
    expect(plans[0].date).toBe('2026-07-13');
    expect(plans.at(-1)?.date).toBe('2026-09-30');
  });

  it('previews duplicates before overlaps and leaves decisions to the caller', () => {
    const existing = [
      shift({ id: 'duplicate', date: '2026-07-13' }),
      shift({ id: 'overlap', employerId: 'e2', date: '2026-07-15', startMin: 18 * 60 }),
    ];
    const plans = previewRecurrence(template, rule({ occurrenceCount: 2 }), 2000, existing);
    expect(plans[0]).toMatchObject({ conflict: 'duplicate', conflictingShiftIds: ['duplicate'] });
    expect(plans[1]).toMatchObject({ conflict: 'overlap', conflictingShiftIds: ['overlap'] });
  });

  it('does not generate from an inactive rule', () => {
    expect(previewRecurrence(template, rule({ active: false }), 2000, [])).toEqual([]);
  });
});
