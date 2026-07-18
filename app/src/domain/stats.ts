import {
  actualEarnings,
  actualPaidMinutes,
  estimatedNet,
  expectedEarnings,
  pendingPayout,
  roundCents,
  scheduledPaidMinutes,
  wagesForMinutes,
} from './calc';
import type { GoalMetric, NotWorkedReason, Shift, WeeklyGoal } from './types';

export type TrendMetric =
  | 'hours'
  | 'base_wages'
  | 'net_tips'
  | 'actual_gross'
  | 'estimated_net'
  | 'effective_hourly';

export interface StatsTotals {
  sampleSize: number;
  hours: number;
  baseWages: number;
  netTips: number;
  actualGross: number;
  estimatedNet: number;
  effectiveHourly: number | null;
}

export interface NotWorkedStats {
  reason: NotWorkedReason | 'unknown';
  shiftCount: number;
  scheduledMinutes: number;
  expectedBaseWages: number;
}

export interface StatsAggregate {
  scheduledShiftCount: number;
  workedShiftCount: number;
  scheduledMinutes: number;
  workedMinutes: number;
  hoursVarianceMinutes: number;
  expectedBaseWages: number;
  actualBaseWages: number;
  /** Null unless every scheduled shift has an explicit expected-tip value. */
  expectedGrossEarnings: number | null;
  grossTips: number;
  tipOutPaid: number;
  poolContributions: number;
  netTips: number;
  otherIncome: number;
  grossEarnings: number;
  estimatedDeductions: number;
  estimatedNet: number;
  expectedPayout: number;
  payoutsReceived: number;
  payoutsPending: number;
  /** Actual gross for worked shifts that have comparable expected totals. */
  comparableActualGrossEarnings: number | null;
  earningsVariance: number | null;
  comparableShiftCount: number;
  effectiveHourly: number | null;
  missedCount: number;
  cancelledCount: number;
  notWorkedByReason: NotWorkedStats[];
}

export interface EmployerStats {
  employerId: string;
  totals: StatsAggregate;
}

export interface StatsLedger extends StatsAggregate {
  byEmployer: EmployerStats[];
}

export function netTipIncome(shift: Shift): number {
  return roundCents(
    (shift.directTips ?? 0) +
      (shift.tipShareReceived ?? 0) -
      (shift.tipOutPaid ?? 0) -
      (shift.poolContribution ?? 0)
  );
}

function aggregateGroup(shifts: readonly Shift[]): StatsAggregate {
  const worked = shifts.filter((shift) => shift.status === 'worked');
  const scheduledMinutes = shifts.reduce(
    (sum, shift) => sum + scheduledPaidMinutes(shift),
    0
  );
  const workedMinutes = worked.reduce(
    (sum, shift) => sum + actualPaidMinutes(shift),
    0
  );
  const expectedBaseWages = shifts.reduce(
    (sum, shift) =>
      sum + wagesForMinutes(scheduledPaidMinutes(shift), shift.hourlyRateSnapshot),
    0
  );
  const actualBaseWages = worked.reduce(
    (sum, shift) =>
      sum +
      wagesForMinutes(
        actualPaidMinutes(shift),
        shift.actualHourlyRateSnapshot ?? shift.hourlyRateSnapshot
      ),
    0
  );
  const grossTips = worked.reduce(
    (sum, shift) => sum + (shift.directTips ?? 0) + (shift.tipShareReceived ?? 0),
    0
  );
  const tipOutPaid = worked.reduce((sum, shift) => sum + (shift.tipOutPaid ?? 0), 0);
  const poolContributions = worked.reduce(
    (sum, shift) => sum + (shift.poolContribution ?? 0),
    0
  );
  const netTips = roundCents(grossTips - tipOutPaid - poolContributions);
  const otherIncome = worked.reduce((sum, shift) => sum + (shift.otherIncome ?? 0), 0);
  const grossEarnings = worked.reduce((sum, shift) => sum + actualEarnings(shift), 0);
  const estimatedNetTotal = worked.reduce((sum, shift) => sum + estimatedNet(shift), 0);
  const comparable = worked.filter((shift) => shift.plannedExpectedTips != null);
  const comparableExpected = comparable.reduce(
    (sum, shift) => sum + expectedEarnings(shift),
    0
  );
  const comparableActual = comparable.reduce(
    (sum, shift) => sum + actualEarnings(shift),
    0
  );
  const reasonRows = new Map<NotWorkedReason | 'unknown', NotWorkedStats>();

  for (const shift of shifts) {
    if (shift.status !== 'missed' && shift.status !== 'cancelled') continue;
    const reason = shift.notWorkedReason ?? 'unknown';
    const current = reasonRows.get(reason) ?? {
      reason,
      shiftCount: 0,
      scheduledMinutes: 0,
      expectedBaseWages: 0,
    };
    current.shiftCount += 1;
    current.scheduledMinutes += scheduledPaidMinutes(shift);
    current.expectedBaseWages += wagesForMinutes(
      scheduledPaidMinutes(shift),
      shift.hourlyRateSnapshot
    );
    reasonRows.set(reason, current);
  }

  return {
    scheduledShiftCount: shifts.length,
    workedShiftCount: worked.length,
    scheduledMinutes,
    workedMinutes,
    hoursVarianceMinutes: workedMinutes - scheduledMinutes,
    expectedBaseWages,
    actualBaseWages,
    expectedGrossEarnings:
      shifts.length > 0 && shifts.every((shift) => shift.plannedExpectedTips != null)
        ? shifts.reduce((sum, shift) => sum + expectedEarnings(shift), 0)
        : null,
    grossTips,
    tipOutPaid,
    poolContributions,
    netTips,
    otherIncome,
    grossEarnings,
    estimatedDeductions: grossEarnings - estimatedNetTotal,
    estimatedNet: estimatedNetTotal,
    expectedPayout: worked.reduce((sum, shift) => sum + (shift.expectedPayout ?? 0), 0),
    payoutsReceived: worked.reduce((sum, shift) => sum + (shift.actualReceived ?? 0), 0),
    payoutsPending: worked.reduce(
      (sum, shift) =>
        sum + pendingPayout(shift.expectedPayout ?? 0, shift.actualReceived ?? 0),
      0
    ),
    comparableActualGrossEarnings: comparable.length > 0 ? comparableActual : null,
    earningsVariance:
      comparable.length > 0 ? comparableActual - comparableExpected : null,
    comparableShiftCount: comparable.length,
    effectiveHourly:
      workedMinutes > 0 ? roundCents((grossEarnings * 60) / workedMinutes) : null,
    missedCount: shifts.filter((shift) => shift.status === 'missed').length,
    cancelledCount: shifts.filter((shift) => shift.status === 'cancelled').length,
    notWorkedByReason: [...reasonRows.values()].sort((a, b) =>
      a.reason.localeCompare(b.reason)
    ),
  };
}

/** The single cents-based source for all summary and per-employer statistics. */
export function aggregateStats(shifts: readonly Shift[]): StatsLedger {
  const employerIds = [...new Set(shifts.map((shift) => shift.employerId))];
  return {
    ...aggregateGroup(shifts),
    byEmployer: employerIds
      .map((employerId) => ({
        employerId,
        totals: aggregateGroup(shifts.filter((shift) => shift.employerId === employerId)),
      }))
      .sort((a, b) => b.totals.grossEarnings - a.totals.grossEarnings),
  };
}

export function aggregateWorked(shifts: readonly Shift[]): StatsTotals {
  const totals = aggregateStats(shifts);
  return {
    sampleSize: totals.workedShiftCount,
    hours: Math.round((totals.workedMinutes / 60) * 100) / 100,
    baseWages: totals.actualBaseWages,
    netTips: totals.netTips,
    actualGross: totals.grossEarnings,
    estimatedNet: totals.estimatedNet,
    effectiveHourly: totals.effectiveHourly,
  };
}

export function trendValue(totals: StatsTotals, metric: TrendMetric): number | null {
  switch (metric) {
    case 'hours':
      return totals.hours;
    case 'base_wages':
      return totals.baseWages;
    case 'net_tips':
      return totals.netTips;
    case 'actual_gross':
      return totals.actualGross;
    case 'estimated_net':
      return totals.estimatedNet;
    case 'effective_hourly':
      return totals.effectiveHourly;
  }
}

/** Null means there is no reliable prior baseline. */
export function percentChange(current: number, previous: number): number | null {
  if (previous === 0) return null;
  return Math.round(((current - previous) / Math.abs(previous)) * 1000) / 10;
}

export function goalProgress(
  goal: WeeklyGoal,
  shifts: readonly Shift[]
): { expected: number | null; actual: number } {
  const scoped = shifts.filter(
    (shift) => !goal.employerId || shift.employerId === goal.employerId
  );
  const planned = scoped.filter(
    (shift) => shift.status === 'planned' || shift.status === 'worked'
  );
  const worked = scoped.filter((shift) => shift.status === 'worked');
  switch (goal.metric satisfies GoalMetric) {
    case 'worked_hours':
      return {
        expected: planned.reduce((sum, shift) => sum + scheduledPaidMinutes(shift), 0),
        actual: worked.reduce((sum, shift) => sum + actualPaidMinutes(shift), 0),
      };
    case 'actual_gross':
      return {
        expected:
          planned.length > 0 && planned.every((shift) => shift.plannedExpectedTips != null)
            ? planned.reduce((sum, shift) => sum + expectedEarnings(shift), 0)
            : null,
        actual: aggregateWorked(worked).actualGross,
      };
    case 'net_tips':
      return { expected: null, actual: aggregateWorked(worked).netTips };
    case 'estimated_net':
      return { expected: null, actual: aggregateWorked(worked).estimatedNet };
  }
}

export interface BestGroup {
  key: string;
  value: number;
  sampleSize: number;
}

export function bestGroup(
  shifts: readonly Shift[],
  metric: TrendMetric,
  keyFor: (shift: Shift) => string
): BestGroup | null {
  const worked = shifts.filter((shift) => shift.status === 'worked');
  if (worked.length < 3) return null;
  const grouped = new Map<string, Shift[]>();
  for (const shift of worked) {
    const key = keyFor(shift);
    grouped.set(key, [...(grouped.get(key) ?? []), shift]);
  }
  const rows = [...grouped.entries()].flatMap(([key, values]) => {
    if (values.length < 3) return [];
    const value = trendValue(aggregateWorked(values), metric);
    return value == null ? [] : [{ key, value, sampleSize: values.length }];
  });
  return rows.sort((a, b) => b.value - a.value)[0] ?? null;
}
