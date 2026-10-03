import {
  actualEarnings,
  actualPaidMinutes,
  derivePayoutStatus,
  effectiveHourly,
  estimatedNet,
  expectedEarnings,
  normalizeEnd,
  pendingPayout,
  roundCents,
  scheduledPaidMinutes,
  spanMinutes,
  unpaidBreakMinutes,
  variance,
} from '../calc';
import type { Shift, ShiftBreak } from '../types';

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
  startMin: 17 * 60, // 17:00
  endMin: 23 * 60, // 23:00
  breaks: [],
  hourlyRateSnapshot: 2000,
  status: 'planned',
  ...overrides,
});

describe('spanMinutes / normalizeEnd', () => {
  it('computes a same-day span', () => {
    expect(spanMinutes(9 * 60, 17 * 60)).toBe(480);
  });

  it('handles overnight where end < start (18:00–00:20)', () => {
    expect(spanMinutes(18 * 60, 20)).toBe(380);
  });

  it('handles end stored beyond 1440 (18:00–24:20)', () => {
    expect(spanMinutes(18 * 60, 1460)).toBe(380);
  });

  it('normalizes end at exactly midnight (22:00–00:00)', () => {
    expect(spanMinutes(22 * 60, 0)).toBe(120);
  });

  it('never returns a negative duration', () => {
    expect(spanMinutes(600, 600)).toBeGreaterThanOrEqual(0);
    expect(normalizeEnd(600, 600)).toBe(600 + 1440);
  });
});

describe('unpaidBreakMinutes', () => {
  it('sums only unpaid breaks', () => {
    const breaks = [brk(720, 30, false), brk(900, 15, true), brk(960, 10, false)];
    expect(unpaidBreakMinutes(breaks)).toBe(40);
  });

  it('returns 0 for null/undefined/empty', () => {
    expect(unpaidBreakMinutes(null)).toBe(0);
    expect(unpaidBreakMinutes(undefined)).toBe(0);
    expect(unpaidBreakMinutes([])).toBe(0);
  });
});

describe('scheduledPaidMinutes', () => {
  it('PRD example: 8:00–17:00 with paid 15m and unpaid 30m = 510', () => {
    const shift = baseShift({
      startMin: 8 * 60,
      endMin: 17 * 60,
      breaks: [brk(10 * 60, 15, true, 'Morning break'), brk(13 * 60, 30, false, 'Lunch')],
    });
    expect(scheduledPaidMinutes(shift)).toBe(510);
  });

  it('paid breaks do not reduce paid time', () => {
    const shift = baseShift({ breaks: [brk(18 * 60, 30, true)] });
    expect(scheduledPaidMinutes(shift)).toBe(360);
  });

  it('overnight 18:00–00:20 with a 20-minute unpaid break = 360', () => {
    const shift = baseShift({
      startMin: 18 * 60,
      endMin: 20,
      breaks: [brk(21 * 60, 20, false)],
    });
    expect(scheduledPaidMinutes(shift)).toBe(360);
  });

  it('never returns negative when unpaid breaks exceed the span', () => {
    const shift = baseShift({
      startMin: 600,
      endMin: 660,
      breaks: [brk(600, 999, false)],
    });
    expect(scheduledPaidMinutes(shift)).toBe(0);
  });
});

describe('actualPaidMinutes', () => {
  it('returns 0 when actuals are missing', () => {
    expect(actualPaidMinutes(baseShift())).toBe(0);
  });

  it('PRD example: 8:15–17:00, paid 15m break, unpaid 45m lunch = 480', () => {
    const shift = baseShift({
      actualStartMin: 8 * 60 + 15,
      actualEndMin: 17 * 60,
      actualBreaks: [brk(10 * 60, 15, true), brk(13 * 60, 45, false)],
    });
    expect(actualPaidMinutes(shift)).toBe(480);
  });

  it('handles overnight actuals (18:00–00:20)', () => {
    const shift = baseShift({
      actualStartMin: 18 * 60,
      actualEndMin: 20,
      actualBreaks: [],
    });
    expect(actualPaidMinutes(shift)).toBe(380);
  });
});

describe('expectedEarnings', () => {
  it('scheduled paid hours × rate snapshot', () => {
    const shift = baseShift({
      startMin: 9 * 60,
      endMin: 17 * 60,
      breaks: [brk(12 * 60, 30, false)],
      hourlyRateSnapshot: 1600,
    });
    // 7.5h × 16 = 120
    expect(expectedEarnings(shift)).toBe(12000);
  });

  it('overnight expected earnings (18:00–00:20 @ $15, no breaks)', () => {
    const shift = baseShift({
      startMin: 18 * 60,
      endMin: 20,
      breaks: [],
      hourlyRateSnapshot: 1500,
    });
    expect(expectedEarnings(shift)).toBe(roundCents((380 * 1500) / 60));
    expect(expectedEarnings(shift)).toBe(9500);
  });

  it('adds explicitly planned tips and other income to expected base wages', () => {
    const shift = baseShift({
      plannedExpectedTips: 4000,
      plannedOtherIncome: 500,
    });
    expect(expectedEarnings(shift)).toBe(16500);
  });
});

describe('actualEarnings', () => {
  it('adds tips and other income, subtracts tip-out and pool contribution', () => {
    const shift = baseShift({
      actualStartMin: 17 * 60,
      actualEndMin: 23 * 60,
      actualBreaks: [],
      hourlyRateSnapshot: 2000,
      directTips: 15000,
      tipShareReceived: 2500,
      tipOutPaid: 3000,
      poolContribution: 1000,
      otherIncome: 500,
    });
    // 120 + 150 + 25 − 30 − 10 + 5 = 260
    expect(actualEarnings(shift)).toBe(26000);
  });

  it('treats missing tip fields as zero', () => {
    const shift = baseShift({
      actualStartMin: 17 * 60,
      actualEndMin: 20 * 60,
      actualBreaks: [],
      hourlyRateSnapshot: 1800,
    });
    expect(actualEarnings(shift)).toBe(5400);
  });

  it('unpaid actual breaks reduce base wage; paid ones do not', () => {
    const shift = baseShift({
      actualStartMin: 10 * 60,
      actualEndMin: 18 * 60, // 8h span
      actualBreaks: [brk(12 * 60, 60, false), brk(15 * 60, 15, true)],
      hourlyRateSnapshot: 1200,
      directTips: 0,
    });
    // 7h × 12 = 84
    expect(actualEarnings(shift)).toBe(8400);
  });
  it('uses the editable actual hourly-rate snapshot for worked base wages', () => {
    const shift = baseShift({
      actualStartMin: 17 * 60,
      actualEndMin: 23 * 60,
      actualBreaks: [],
      actualHourlyRateSnapshot: 2500,
    });
    expect(actualEarnings(shift)).toBe(15000);
  });
});

describe('variance and effectiveHourly', () => {
  const shift = baseShift({
    startMin: 17 * 60,
    endMin: 23 * 60, // expected 6h × 20 = 120
    actualStartMin: 17 * 60,
    actualEndMin: 23 * 60 + 30, // 6.5h
    actualBreaks: [brk(20 * 60, 30, false)], // −0.5h → 6h × 20 = 120 base
    directTips: 9000,
    tipOutPaid: 1200,
    plannedExpectedTips: 0,
    status: 'worked',
  });

  it('variance = actual − expected', () => {
    // actual: 120 + 90 − 12 = 198; expected 120 → +78
    expect(variance(shift)).toBe(7800);
  });

  it('effectiveHourly = actual ÷ actual paid hours', () => {
    expect(effectiveHourly(shift)).toBe(3300);
  });

  it('effectiveHourly is null with no actual paid time', () => {
    expect(effectiveHourly(baseShift())).toBeNull();
  });

  it('returns null variance when expected tips were never recorded', () => {
    expect(variance({ ...shift, plannedExpectedTips: null })).toBeNull();
  });
});

describe('estimatedNet', () => {
  it('applies the snapshotted deduction rate', () => {
    const shift = baseShift({
      actualStartMin: 9 * 60,
      actualEndMin: 17 * 60,
      actualBreaks: [],
      hourlyRateSnapshot: 2250,
      directTips: 10000,
      otherIncome: 2000,
      deductionRateSnapshotBp: 4000,
    });
    // PRD example: 300 gross, 40% → 180 net
    expect(actualEarnings(shift)).toBe(30000);
    expect(estimatedNet(shift)).toBe(18000);
  });

  it('defaults to no deductions when rate is absent', () => {
    const shift = baseShift({
      actualStartMin: 9 * 60,
      actualEndMin: 10 * 60,
      actualBreaks: [],
      hourlyRateSnapshot: 3000,
    });
    expect(estimatedNet(shift)).toBe(3000);
  });
});

describe('derivePayoutStatus', () => {
  it('0 expected → not_expected', () => {
    expect(derivePayoutStatus(0, 0)).toBe('not_expected');
    expect(derivePayoutStatus(0, 5000)).toBe('not_expected');
  });

  it('expected > 0, received 0 → pending', () => {
    expect(derivePayoutStatus(10000, 0)).toBe('pending');
  });

  it('0 < received < expected → partially_received', () => {
    expect(derivePayoutStatus(10000, 1)).toBe('partially_received');
    expect(derivePayoutStatus(10000, 9999)).toBe('partially_received');
  });

  it('received ≥ expected → received', () => {
    expect(derivePayoutStatus(10000, 10000)).toBe('received');
    expect(derivePayoutStatus(10000, 12000)).toBe('received');
  });
});

describe('pendingPayout', () => {
  it('is expected − received, floored at 0', () => {
    expect(pendingPayout(10000, 4000)).toBe(6000);
    expect(pendingPayout(10000, 12000)).toBe(0);
  });
});
