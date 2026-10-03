/**
 * Pure validation functions for ProTip365 V4 MVP.
 * No React Native or database imports allowed here.
 */

import { normalizeEnd, spanMinutes, unpaidBreakMinutes } from './calc';
import type { ShiftBreak } from './types';

export type ValidationError =
  | 'end_not_after_start'
  | 'break_negative_duration'
  | 'break_outside_shift'
  | 'breaks_overlap'
  | 'unpaid_breaks_exceed_shift'
  | 'negative_amount'
  | 'rate_not_positive'
  | 'deduction_out_of_range';

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

interface TimeWindowInput {
  startMin: number;
  endMin: number;
  breaks: readonly ShiftBreak[];
}

/**
 * Normalize a break start to the shift timeline. A break that appears to
 * start "before" the shift start on an overnight shift is assumed to be
 * after midnight (next day).
 */
function normalizedBreakStart(shiftStartMin: number, breakStartMin: number): number {
  return breakStartMin < shiftStartMin ? breakStartMin + 1440 : breakStartMin;
}

/**
 * Validate a shift time window (works for scheduled and actual values):
 * - end must be strictly after start once overnight normalization is applied;
 * - every break must fit entirely inside the shift window;
 * - breaks must not overlap one another;
 * - total unpaid break time must not exceed the shift duration.
 */
export function validateShiftWindow(input: TimeWindowInput): ValidationResult {
  const errors: ValidationError[] = [];
  const { startMin, breaks } = input;

  // end === start normalizes to a 24h span; treat identical times as invalid.
  if (input.endMin === startMin) {
    errors.push('end_not_after_start');
    return { valid: false, errors };
  }
  const endMin = normalizeEnd(startMin, input.endMin);
  if (endMin <= startMin) {
    errors.push('end_not_after_start');
    return { valid: false, errors };
  }

  const span = spanMinutes(startMin, input.endMin);

  const normalized = breaks.map((b) => ({
    ...b,
    normStart: normalizedBreakStart(startMin, b.startMin),
  }));

  for (const b of normalized) {
    if (b.durationMin <= 0) {
      errors.push('break_negative_duration');
      continue;
    }
    if (b.normStart < startMin || b.normStart + b.durationMin > endMin) {
      errors.push('break_outside_shift');
    }
  }

  const sorted = [...normalized]
    .filter((b) => b.durationMin > 0)
    .sort((a, b) => a.normStart - b.normStart);
  for (let i = 1; i < sorted.length; i++) {
    const prev = sorted[i - 1];
    if (sorted[i].normStart < prev.normStart + prev.durationMin) {
      errors.push('breaks_overlap');
      break;
    }
  }

  if (unpaidBreakMinutes(breaks) > span) {
    errors.push('unpaid_breaks_exceed_shift');
  }

  return { valid: errors.length === 0, errors: [...new Set(errors)] };
}

/** Reject negative money amounts. `undefined`/`null` values are ignored. */
export function validateMoney(
  amounts: Record<string, number | null | undefined>
): ValidationResult {
  const errors: ValidationError[] = [];
  for (const value of Object.values(amounts)) {
    if (value != null && (Number.isNaN(value) || value < 0)) {
      errors.push('negative_amount');
      break;
    }
  }
  return { valid: errors.length === 0, errors };
}

export function validateHourlyRateCents(rate: number | null): ValidationResult {
  const valid = rate != null && Number.isSafeInteger(rate) && rate > 0;
  return { valid, errors: valid ? [] : ['rate_not_positive'] };
}

export function validateDeductionBasisPoints(basisPoints: number): ValidationResult {
  const valid =
    Number.isInteger(basisPoints) && basisPoints >= 0 && basisPoints <= 10000;
  return { valid, errors: valid ? [] : ['deduction_out_of_range'] };
}

/** Combine several validation results into one. */
export function combineResults(...results: ValidationResult[]): ValidationResult {
  const errors = [...new Set(results.flatMap((r) => r.errors))];
  return { valid: errors.length === 0, errors };
}
