/**
 * Pure calculation functions for ProTip365 V4 MVP.
 * No React Native or database imports allowed here.
 */

import type { PayoutStatus, Shift, ShiftBreak } from './types';

/**
 * Round a currency amount to cents, half-up, avoiding binary float artifacts
 * (DEF-10: `1.005 * 100` is `100.4999…` in IEEE 754, which naive Math.round
 * turns into 1.00; re-quantizing through toFixed removes the artifact first).
 */
export function roundCents(amount: number): number {
  return Math.round(Number((amount * 100).toFixed(6))) / 100;
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
  shift: Pick<Shift, 'startMin' | 'endMin' | 'breaks' | 'hourlyRateSnapshot'>
): number {
  return roundCents((scheduledPaidMinutes(shift) / 60) * shift.hourlyRateSnapshot);
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
    | 'directTips'
    | 'tipShareReceived'
    | 'tipOutPaid'
    | 'poolContribution'
    | 'otherIncome'
  >
): number {
  const base = (actualPaidMinutes(shift) / 60) * shift.hourlyRateSnapshot;
  const tips =
    (shift.directTips ?? 0) +
    (shift.tipShareReceived ?? 0) -
    (shift.tipOutPaid ?? 0) -
    (shift.poolContribution ?? 0);
  return roundCents(base + tips + (shift.otherIncome ?? 0));
}

/** Variance: actual gross earnings − expected base earnings. */
export function variance(shift: Shift): number {
  return roundCents(actualEarnings(shift) - expectedEarnings(shift));
}

/** Effective hourly rate: actual earnings ÷ actual paid hours. 0 when no paid time. */
export function effectiveHourly(shift: Shift): number {
  const minutes = actualPaidMinutes(shift);
  if (minutes <= 0) return 0;
  return roundCents(actualEarnings(shift) / (minutes / 60));
}

/**
 * Estimated net: actual earnings × (1 − deduction rate).
 * The rate is a fraction (0–1) snapshotted at completion.
 */
export function estimatedNet(shift: Shift): number {
  const rate = shift.deductionRateSnapshot ?? 0;
  return roundCents(actualEarnings(shift) * (1 - rate));
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
  return roundCents(Math.max(expectedPayout - actualReceived, 0));
}
