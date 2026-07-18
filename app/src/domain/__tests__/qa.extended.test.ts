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
  hourlyRateSnapshot: 15,
  status: 'scheduled',
  ...overrides,
});

// TP-046 — expected_base_wages with cent rounding
describe('TP-046 expectedEarnings rounding', () => {
  it('8.5h × 15.75 = 133.88 (half-up at the half-cent)', () => {
    const shift = baseShift({
      startMin: 8 * 60,
      endMin: 17 * 60, // 540 min
      breaks: [brk(10 * 60, 15, true), brk(13 * 60, 30, false)], // → 510 paid
      hourlyRateSnapshot: 15.75,
    });
    expect(expectedEarnings(shift)).toBe(133.88);
  });
});

// TP-026 — adjust actual end +20 minutes
describe('TP-026 completion with +20 min end adjustment', () => {
  const shift = baseShift({
    // planned 17:00–23:00 @ $15 → expected 90
    actualStartMin: 17 * 60,
    actualEndMin: 23 * 60 + 20, // stayed 20 min late
    actualBreaks: [],
    status: 'worked',
  });

  it('expected stays 90; actual base becomes 95', () => {
    expect(expectedEarnings(shift)).toBe(90);
    expect(actualEarnings(shift)).toBe(95);
  });

  it('variance is +5 and effective hourly equals the rate', () => {
    expect(variance(shift)).toBe(5);
    expect(effectiveHourly(shift)).toBe(15);
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
    expect(actualEarnings(worked({ directTips: 120 }))).toBe(210);
  });
  it('tip-out only: −15', () => {
    expect(actualEarnings(worked({ tipOutPaid: 15 }))).toBe(75);
  });
  it('tip-share only: +35', () => {
    expect(actualEarnings(worked({ tipShareReceived: 35 }))).toBe(125);
  });
  it('pool contribution only: −20', () => {
    expect(actualEarnings(worked({ poolContribution: 20 }))).toBe(70);
  });
  it('all four combined (PRD §10 model): 120 − 20 + 35 − 15 = +120 net tips', () => {
    expect(
      actualEarnings(
        worked({ directTips: 120, poolContribution: 20, tipShareReceived: 35, tipOutPaid: 15 })
      )
    ).toBe(210);
  });
  it('all zeros → base only', () => {
    expect(
      actualEarnings(
        worked({ directTips: 0, poolContribution: 0, tipShareReceived: 0, tipOutPaid: 0 })
      )
    ).toBe(90);
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
      hourlyRateSnapshot: 25, // 8h → 200 gross
      deductionRateSnapshot: rate,
      status: 'worked',
    });

  it('rate 0 → net equals gross', () => {
    expect(estimatedNet(worked(0))).toBe(200);
  });
  it('rate 1 (100%) → net 0', () => {
    expect(estimatedNet(worked(1))).toBe(0);
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
      status: 'worked',
    });
    expect(variance(shift)).toBe(-15);
  });
});

// TP-053 — effective hourly with zero paid time
describe('TP-053 effective hourly zero-paid-time guard', () => {
  it('returns 0 (never Infinity/NaN) when unpaid breaks consume the whole span, even with tips', () => {
    const shift = baseShift({
      actualStartMin: 600,
      actualEndMin: 660,
      actualBreaks: [brk(600, 60, false)], // paid time 0
      directTips: 50,
      status: 'worked',
    });
    expect(effectiveHourly(shift)).toBe(0);
    expect(Number.isFinite(effectiveHourly(shift))).toBe(true);
  });
});

// TP-054 — payout boundary refinements
describe('TP-054 payout status boundaries (cent-level)', () => {
  it('one cent short is still partially_received', () => {
    expect(derivePayoutStatus(150, 149.99)).toBe('partially_received');
  });
  it('one cent over is received', () => {
    expect(derivePayoutStatus(150, 150.01)).toBe('received');
  });
  it('overpayment keeps pending at 0', () => {
    expect(pendingPayout(150, 150.01)).toBe(0);
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
      directTips: 40,
      status: 'worked',
    });
    // actual: 1h × 15 + 40 = 55; expected 0
    expect(variance(shift)).toBe(55);
  });

  it('validation rejects identical start/end so a true 0-length shift cannot be saved', () => {
    expect(validateShiftWindow({ startMin: 600, endMin: 600, breaks: [] }).valid).toBe(false);
  });
});

// TP-058 — money rounding and float-drift guards
describe('TP-058 rounding to cents', () => {
  it('repeated 0.1 additions round clean', () => {
    const sum = [...Array(10)].reduce((s: number) => s + 0.1, 0); // 0.9999999999999999
    expect(roundCents(sum)).toBe(1);
  });

  it('7h50m × 15.75 = 123.375 → 123.38', () => {
    expect(roundCents((470 / 60) * 15.75)).toBe(123.38);
  });

  it('deduction on 33.33 at 40% → 13.33', () => {
    expect(roundCents(33.33 * 0.4)).toBe(13.33);
  });

  // DEF-10 fix (2026-07-18): roundCents now re-quantizes before rounding so the
  // IEEE-754 artifact 1.005 → 100.4999… no longer rounds down; half-up applies.
  it('half-cent values round half-up (1.005 → 1.01)', () => {
    expect(roundCents(1.005)).toBe(1.01);
    expect(roundCents(2.675)).toBe(2.68);
    expect(roundCents(0.125)).toBe(0.13);
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
