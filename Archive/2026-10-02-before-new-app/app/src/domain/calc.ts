/**
 * Pure calculation functions for ProTip365 V4 MVP.
 * No React Native or database imports allowed here.
 */

import type { PayoutStatus, Shift, ShiftBreak } from './types';

/** Round a calculated cent value at an explicitly defined boundary. */
export function roundCents(amountInCents: number): number {
  return Math.round(amountInCents);
}

/** Integer-cent wage boundary for a rate in cents/hour and integer minutes. */
export function wagesForMinutes(minutes: number, hourlyRateCents: number): number {
  return roundCents((minutes * hourlyRateCents) / 60);
}

/**
 * Normalize an end time relative to a start time so overnight shifts
 * (end past midnight) produce a positive span. If `endMin <= startMin`
 * the end is assumed to be on the next day.
 */
export function normalizeEnd(startMin: number, endMin: number): number {
  return endMin <= startMin ? endMin + 1440 : endMin;
}

/** Span in minutes between start and end, overnight-aware. Never negative. */
export function spanMinutes(startMin: number, endMin: number): number {
  return Math.max(normalizeEnd(startMin, endMin) - startMin, 0);
}

/** Total unpaid break minutes. Paid breaks never reduce paid time. */
export function unpaidBreakMinutes(breaks: readonly ShiftBreak[] | null | undefined): number {
  if (!breaks) return 0;
  return breaks
    .filter((b) => !b.paid)
    .reduce((sum, b) => sum + Math.max(b.durationMin, 0), 0);
}

/** Scheduled duration minus unpaid scheduled break minutes. Never negative. */
export function scheduledPaidMinutes(
  shift: Pick<Shift, 'startMin' | 'endMin' | 'breaks'>
): number {
  const span = spanMinutes(shift.startMin, shift.endMin);
  return Math.max(span - unpaidBreakMinutes(shift.breaks), 0);
}

/** Actual duration minus unpaid actual break minutes. 0 when actuals are absent. */
export function actualPaidMinutes(
  shift: Pick<Shift, 'actualStartMin' | 'actualEndMin' | 'actualBreaks'>
): number {
  if (shift.actualStartMin == null || shift.actualEndMin == null) return 0;
  const span = spanMinutes(shift.actualStartMin, shift.actualEndMin);
  return Math.max(span - unpaidBreakMinutes(shift.actualBreaks), 0);
}

/** Expected base earnings: scheduled paid hours × snapshotted hourly rate. */
export function expectedEarnings(
  shift: Pick<
    Shift,
    | 'startMin'
    | 'endMin'
    | 'breaks'
    | 'hourlyRateSnapshot'
    | 'plannedExpectedTips'
    | 'plannedOtherIncome'
  >
): number {
  return (
    wagesForMinutes(scheduledPaidMinutes(shift), shift.hourlyRateSnapshot) +
    (shift.plannedExpectedTips ?? 0) +
    (shift.plannedOtherIncome ?? 0)
  );
}

/**
 * Actual gross earnings:
 * base wage on actual paid minutes
 * + direct tips + tip-share received + other income
 * − tip-out paid − pool contribution.
 */
export function actualEarnings(
  shift: Pick<
    Shift,
    | 'actualStartMin'
    | 'actualEndMin'
    | 'actualBreaks'
    | 'hourlyRateSnapshot'
    | 'actualHourlyRateSnapshot'
    | 'directTips'
    | 'tipShareReceived'
    | 'tipOutPaid'
    | 'poolContribution'
    | 'otherIncome'
  >
): number {
  const rate = shift.actualHourlyRateSnapshot ?? shift.hourlyRateSnapshot;
  const base = wagesForMinutes(actualPaidMinutes(shift), rate);
  const tips =
    (shift.directTips ?? 0) +
    (shift.tipShareReceived ?? 0) -
    (shift.tipOutPaid ?? 0) -
    (shift.poolContribution ?? 0);
  return base + tips + (shift.otherIncome ?? 0);
}

/** Variance: actual gross earnings − expected base earnings. */
export function variance(shift: Shift): number | null {
  if (shift.plannedExpectedTips == null) return null;
  return actualEarnings(shift) - expectedEarnings(shift);
}

/** Effective hourly rate: actual earnings ÷ actual paid hours. Null when no paid time. */
export function effectiveHourly(shift: Shift): number | null {
  const minutes = actualPaidMinutes(shift);
  if (minutes <= 0) return null;
  return roundCents((actualEarnings(shift) * 60) / minutes);
}

/**
 * Estimated net from integer cents and a basis-point deduction snapshot.
 */
export function estimatedNet(shift: Shift): number {
  const rateBp = shift.deductionRateSnapshotBp ?? 0;
  return roundCents((actualEarnings(shift) * (10000 - rateBp)) / 10000);
}

/**
 * Derive payout status from expected vs. received amounts.
 * `disputed` is never derived — it can only be set manually.
 */
export function derivePayoutStatus(
  expectedPayout: number,
  actualReceived: number
): Exclude<PayoutStatus, 'disputed'> {
  if (expectedPayout <= 0) return 'not_expected';
  if (actualReceived <= 0) return 'pending';
  if (actualReceived < expectedPayout) return 'partially_received';
  return 'received';
}

/** Pending payout amount; never negative. */
export function pendingPayout(expectedPayout: number, actualReceived: number): number {
  return Math.max(expectedPayout - actualReceived, 0);
}
