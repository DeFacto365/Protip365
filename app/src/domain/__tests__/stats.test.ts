import {
  aggregateStats,
  aggregateWorked,
  bestGroup,
  goalProgress,
  netTipIncome,
  percentChange,
} from '../stats';
import type { Shift, WeeklyGoal } from '../types';

const worked = (overrides: Partial<Shift> = {}): Shift => ({
  id: 'shift',
  employerId: 'employer-1',
  date: '2026-07-13',
  startMin: 9 * 60,
  endMin: 17 * 60,
  breaks: [],
  hourlyRateSnapshot: 2000,
  plannedExpectedTips: 8000,
  plannedOtherIncome: 500,
  status: 'worked',
  actualStartMin: 9 * 60,
  actualEndMin: 17 * 60,
  actualBreaks: [],
  directTips: 10000,
  tipShareReceived: 2000,
  tipOutPaid: 1000,
  poolContribution: 500,
  otherIncome: 1500,
  deductionRateSnapshotBp: 2000,
  expectedPayout: 25000,
  actualReceived: 10000,
  ...overrides,
});

describe('stats, goals, and trends', () => {
  it('aggregates base wages, net tips, gross, net, hours, and effective hourly', () => {
    const totals = aggregateWorked([worked()]);
    expect(netTipIncome(worked())).toBe(10500);
    expect(totals).toMatchObject({
      sampleSize: 1,
      hours: 8,
      baseWages: 16000,
      netTips: 10500,
      actualGross: 28000,
      estimatedNet: 22400,
      effectiveHourly: 3500,
    });
  });

  it('builds one integer-cents ledger for earnings, payouts, and comparable variance', () => {
    const ledger = aggregateStats([worked()]);
    expect(ledger).toMatchObject({
      scheduledShiftCount: 1,
      workedShiftCount: 1,
      scheduledMinutes: 480,
      workedMinutes: 480,
      hoursVarianceMinutes: 0,
      expectedBaseWages: 16000,
      actualBaseWages: 16000,
      expectedGrossEarnings: 24500,
      grossTips: 12000,
      tipOutPaid: 1000,
      poolContributions: 500,
      netTips: 10500,
      otherIncome: 1500,
      grossEarnings: 28000,
      estimatedDeductions: 5600,
      estimatedNet: 22400,
      expectedPayout: 25000,
      payoutsReceived: 10000,
      payoutsPending: 15000,
      comparableActualGrossEarnings: 28000,
      earningsVariance: 3500,
      comparableShiftCount: 1,
      effectiveHourly: 3500,
    });
    expect(ledger.byEmployer).toHaveLength(1);
    expect(ledger.byEmployer[0]).toMatchObject({
      employerId: 'employer-1',
      totals: { grossEarnings: 28000 },
    });
  });

  it('uses only comparable worked shifts for variance and preserves unknown expected totals', () => {
    const unknown = worked({
      id: 'unknown',
      plannedExpectedTips: null,
      directTips: 100000,
    });
    const ledger = aggregateStats([worked(), unknown]);
    expect(ledger.expectedGrossEarnings).toBeNull();
    expect(ledger.comparableShiftCount).toBe(1);
    expect(ledger.comparableActualGrossEarnings).toBe(28000);
    expect(ledger.earningsVariance).toBe(3500);
  });

  it('keeps missed and cancelled shifts out of actuals and groups their scheduled loss by reason', () => {
    const missed = worked({ id: 'missed', status: 'missed', notWorkedReason: 'sick' });
    const cancelled = worked({
      id: 'cancelled',
      status: 'cancelled',
      notWorkedReason: 'employer_cancelled',
    });
    const ledger = aggregateStats([missed, cancelled]);
    expect(ledger).toMatchObject({
      scheduledMinutes: 960,
      workedMinutes: 0,
      expectedBaseWages: 32000,
      actualBaseWages: 0,
      grossEarnings: 0,
      missedCount: 1,
      cancelledCount: 1,
    });
    expect(ledger.notWorkedByReason).toEqual([
      {
        reason: 'employer_cancelled',
        shiftCount: 1,
        scheduledMinutes: 480,
        expectedBaseWages: 16000,
      },
      {
        reason: 'sick',
        shiftCount: 1,
        scheduledMinutes: 480,
        expectedBaseWages: 16000,
      },
    ]);
  });

  it('keeps scheduled and actual goal progress separate', () => {
    const scheduled = worked({ id: 'planned', status: 'planned' });
    const hoursGoal: WeeklyGoal = {
      id: 'goal',
      weekStart: '2026-07-13',
      metric: 'worked_hours',
      target: 1200,
      repeat: false,
    };
    expect(goalProgress(hoursGoal, [worked(), scheduled])).toEqual({ expected: 960, actual: 480 });

    const tipsGoal = { ...hoursGoal, metric: 'net_tips' as const, target: 20000 };
    expect(goalProgress(tipsGoal, [worked(), scheduled])).toEqual({ expected: null, actual: 10500 });
  });

  it('returns no effective hourly value when worked shifts have no paid time', () => {
    expect(
      aggregateWorked([
        worked({
          actualBreaks: [{ label: 'Unpaid', startMin: 9 * 60, durationMin: 8 * 60, paid: false }],
        }),
      ]).effectiveHourly
    ).toBeNull();
  });

  it('reports percentage change only when a prior baseline exists', () => {
    expect(percentChange(120, 100)).toBe(20);
    expect(percentChange(100, 0)).toBeNull();
  });

  it('requires at least three completed shifts inside each ranked group', () => {
    expect(bestGroup([worked(), worked({ id: 'two' })], 'actual_gross', (shift) => shift.employerId)).toBeNull();
    expect(
      bestGroup(
        [
          worked(),
          worked({ id: 'two', employerId: 'employer-2', directTips: 2000 }),
          worked({ id: 'three', employerId: 'employer-2', directTips: 3000 }),
        ],
        'actual_gross',
        (shift) => shift.employerId
      )
    ).toBeNull();
    expect(
      bestGroup(
        [
          worked(),
          worked({ id: 'two', employerId: 'employer-2', directTips: 2000 }),
          worked({ id: 'three', employerId: 'employer-2', directTips: 3000 }),
          worked({ id: 'four', employerId: 'employer-2', directTips: 4000 }),
        ],
        'actual_gross',
        (shift) => shift.employerId
      )
    ).toMatchObject({ key: 'employer-2', sampleSize: 3, value: 63000 });
  });
});
