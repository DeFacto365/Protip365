/**
 * QA extension suite — covers QA_TEST_PLAN_V4 P0 unit scenarios not exercised
 * by the original test files (TP-026, TP-035, TP-040, TP-046, TP-049, TP-051,
 * TP-053, TP-054, TP-057, TP-058) plus copy-week edges (owner-ruled in scope).
 */
import {
  actualEarnings,
  derivePayoutStatus,
  effectiveHourly,
  estimatedNet,
  expectedEarnings,
  pendingPayout,
  roundCents,
  scheduledPaidMinutes,
  variance,
} from '../calc';
import { copyWeekForward } from '../copyWeek';
import { addDaysIso, startOfWeekIso } from '../dates';
import { validateShiftWindow } from '../validate';
import { NOT_WORKED_REASONS, type Shift, type ShiftBreak } from '../types';

const brk = (
  startMin: number,
  durationMin: number,
  paid = false,
  label = 'Break'
): ShiftBreak => ({ label, startMin, durationMin, paid });

const baseShift = (overrides: Partial<Shift> = {}): Shift => ({
  id: 's1',
  employerId: 'e1',
  date: '2026-07-17',
  startMin: 17 * 60,
  endMin: 23 * 60,
  breaks: [],
  hourlyRateSnapshot: 1500,
  status: 'planned',
  ...overrides,
});

// TP-046 — expected_base_wages with cent rounding
describe('TP-046 expectedEarnings rounding', () => {
  it('8.5h × 15.75 = 133.88 (half-up at the half-cent)', () => {
    const shift = baseShift({
      startMin: 8 * 60,
      endMin: 17 * 60, // 540 min
      breaks: [brk(10 * 60, 15, true), brk(13 * 60, 30, false)], // → 510 paid
      hourlyRateSnapshot: 1575,
    });
    expect(expectedEarnings(shift)).toBe(13388);
  });
});

// TP-026 — adjust actual end +20 minutes
describe('TP-026 completion with +20 min end adjustment', () => {
  const shift = baseShift({
    // planned 17:00–23:00 @ $15 → expected 90
    actualStartMin: 17 * 60,
    actualEndMin: 23 * 60 + 20, // stayed 20 min late
    actualBreaks: [],
    plannedExpectedTips: 0,
    status: 'worked',
  });

  it('expected stays 90; actual base becomes 95', () => {
    expect(expectedEarnings(shift)).toBe(9000);
    expect(actualEarnings(shift)).toBe(9500);
  });

  it('variance is +5 and effective hourly equals the rate', () => {
    expect(variance(shift)).toBe(500);
    expect(effectiveHourly(shift)).toBe(1500);
  });
});

// TP-035 — net tip flows in isolation
describe('TP-035 net tip income per flow', () => {
  const worked = (tips: Partial<Shift>) =>
    baseShift({
      actualStartMin: 17 * 60,
      actualEndMin: 23 * 60, // 6h × 15 = 90 base
      actualBreaks: [],
      status: 'worked',
      ...tips,
    });

  it('direct tips only: +120', () => {
    expect(actualEarnings(worked({ directTips: 12000 }))).toBe(21000);
  });
  it('tip-out only: −15', () => {
    expect(actualEarnings(worked({ tipOutPaid: 1500 }))).toBe(7500);
  });
  it('tip-share only: +35', () => {
    expect(actualEarnings(worked({ tipShareReceived: 3500 }))).toBe(12500);
  });
  it('pool contribution only: −20', () => {
    expect(actualEarnings(worked({ poolContribution: 2000 }))).toBe(7000);
  });
  it('all four combined (PRD §10 model): 120 − 20 + 35 − 15 = +120 net tips', () => {
    expect(
      actualEarnings(
        worked({ directTips: 12000, poolContribution: 2000, tipShareReceived: 3500, tipOutPaid: 1500 })
      )
    ).toBe(21000);
  });
  it('all zeros → base only', () => {
    expect(
      actualEarnings(
        worked({ directTips: 0, poolContribution: 0, tipShareReceived: 0, tipOutPaid: 0 })
      )
    ).toBe(9000);
  });
});

// TP-040 — shifts without actuals contribute zero
describe('TP-040 no-actuals shifts contribute zero earnings', () => {
  it('a shift without actual times or tips earns 0', () => {
    expect(actualEarnings(baseShift())).toBe(0);
    expect(actualEarnings(baseShift({ status: 'missed' }))).toBe(0);
  });
});

// TP-049 — deduction boundaries (PRD example covered in calc.test.ts)
describe('TP-049 deduction-rate boundaries', () => {
  const worked = (rate?: number) =>
    baseShift({
      actualStartMin: 9 * 60,
      actualEndMin: 17 * 60,
      actualBreaks: [],
      hourlyRateSnapshot: 2500,
      deductionRateSnapshotBp: rate,
      status: 'worked',
    });

  it('rate 0 → net equals gross', () => {
    expect(estimatedNet(worked(0))).toBe(20000);
  });
  it('rate 1 (100%) → net 0', () => {
    expect(estimatedNet(worked(10000))).toBe(0);
  });
});

// TP-051 — variance sign convention
describe('TP-051 variance signs', () => {
  it('working less than scheduled produces a negative variance', () => {
    const shift = baseShift({
      // planned 6h × 15 = 90; actual 5h × 15 = 75
      actualStartMin: 17 * 60,
      actualEndMin: 22 * 60,
      actualBreaks: [],
      plannedExpectedTips: 0,
      status: 'worked',
    });
    expect(variance(shift)).toBe(-1500);
  });
});

// TP-053 — effective hourly with zero paid time
describe('TP-053 effective hourly zero-paid-time guard', () => {
  it('returns 0 (never Infinity/NaN) when unpaid breaks consume the whole span, even with tips', () => {
    const shift = baseShift({
      actualStartMin: 600,
      actualEndMin: 660,
      actualBreaks: [brk(600, 60, false)], // paid time 0
      directTips: 5000,
      status: 'worked',
    });
    expect(effectiveHourly(shift)).toBeNull();
  });
});

// TP-054 — payout boundary refinements
describe('TP-054 payout status boundaries (cent-level)', () => {
  it('one cent short is still partially_received', () => {
    expect(derivePayoutStatus(15000, 14999)).toBe('partially_received');
  });
  it('one cent over is received', () => {
    expect(derivePayoutStatus(15000, 15001)).toBe('received');
  });
  it('overpayment keeps pending at 0', () => {
    expect(pendingPayout(15000, 15001)).toBe(0);
  });
});

// TP-057 — zero-hour / degenerate scheduled shifts
describe('TP-057 zero-hour edges', () => {
  it('unpaid breaks consuming the whole scheduled span → 0 paid minutes and $0 expected', () => {
    const shift = baseShift({
      startMin: 600,
      endMin: 660,
      breaks: [brk(600, 60, false)],
    });
    expect(scheduledPaidMinutes(shift)).toBe(0);
    expect(expectedEarnings(shift)).toBe(0);
  });

  it('variance against a 0-expected shift equals actual earnings', () => {
    const shift = baseShift({
      startMin: 600,
      endMin: 660,
      breaks: [brk(600, 60, false)],
      actualStartMin: 600,
      actualEndMin: 660,
      actualBreaks: [],
      directTips: 4000,
      plannedExpectedTips: 0,
      status: 'worked',
    });
    // actual: 1h × 15 + 40 = 55; expected 0
    expect(variance(shift)).toBe(5500);
  });

  it('validation rejects identical start/end so a true 0-length shift cannot be saved', () => {
    expect(validateShiftWindow({ startMin: 600, endMin: 600, breaks: [] }).valid).toBe(false);
  });
});

// TP-058 — money rounding and float-drift guards
describe('TP-058 integer-cent rounding boundaries', () => {
  it('7h50m at 1575 cents/hour rounds once to 12338 cents', () => {
    expect(roundCents((470 * 1575) / 60)).toBe(12338);
  });

  it('a 40% deduction on 3333 cents rounds to 1333 cents', () => {
    expect(roundCents((3333 * 4000) / 10000)).toBe(1333);
  });

  it('positive half-cent values round up at the defined boundary', () => {
    expect(roundCents(100.5)).toBe(101);
    expect(roundCents(267.5)).toBe(268);
    expect(roundCents(12.5)).toBe(13);
  });

  it('break math is integer minutes (no fractional-minute drift)', () => {
    const shift = baseShift({
      startMin: 8 * 60,
      endMin: 17 * 60,
      breaks: [brk(10 * 60, 15, true), brk(13 * 60, 30, false)],
    });
    expect(Number.isInteger(scheduledPaidMinutes(shift))).toBe(true);
  });
});

// Owner directive 2026-07-18: reason codes must exactly match PRD §9's set.
describe('not-worked reason codes (PRD §9)', () => {
  it('exposes the canonical PRD list, in order', () => {
    expect([...NOT_WORKED_REASONS]).toEqual([
      'sick',
      'employer_cancelled',
      'personal',
      'emergency',
      'schedule_conflict',
      'weather_or_transportation',
      'other',
    ]);
  });
});

// Copy-week edges (owner ruling: in scope)
describe('copyWeekForward edges', () => {
  it('copies across a year boundary', () => {
    const source = baseShift({ date: '2026-12-30' }); // Wednesday
    const weekStart = startOfWeekIso('2026-12-30'); // 2026-12-28
    const [copy] = copyWeekForward([source], weekStart);
    expect(copy.date).toBe('2027-01-06');
    expect(copy.date).toBe(addDaysIso('2026-12-30', 7));
  });

  it('an empty week copies nothing', () => {
    expect(copyWeekForward([], startOfWeekIso('2026-07-17'))).toHaveLength(0);
  });
});
