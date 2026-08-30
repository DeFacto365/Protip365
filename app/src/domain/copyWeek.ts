/**
 * Pure "copy week forward" planning. No React Native or database imports.
 */

import { addDaysIso, startOfWeekIso, weekDatesIso } from './dates';
import { findOverlaps } from './overlap';
import type { RecurrenceRule, ScheduleTemplate, Shift, ShiftBreak } from './types';

/** A planned (not yet persisted) scheduled shift produced by the copy. */
export interface CopiedShiftPlan {
  employerId: string;
  roleId?: string | null;
  date: string;
  startMin: number;
  endMin: number;
  breaks: ShiftBreak[];
  hourlyRateSnapshot: number;
  plannedExpectedTips?: number | null;
  plannedOtherIncome?: number | null;
  notes?: string | null;
  sourceTemplateId?: string | null;
  sourceRecurrenceRuleId?: string | null;
  recurrenceKey?: string | null;
}

export type PlanConflict = 'none' | 'duplicate' | 'overlap';

export interface RecurringShiftPlan extends CopiedShiftPlan {
  conflict: PlanConflict;
  conflictingShiftIds: string[];
}

function dayNumber(iso: string): number {
  const [year, month, day] = iso.split('-').map(Number);
  return Date.UTC(year, month - 1, day) / 86_400_000;
}

function mondayWeekday(iso: string): number {
  const [year, month, day] = iso.split('-').map(Number);
  const sundayBased = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  return sundayBased === 0 ? 6 : sundayBased - 1;
}

/** Build one planned shift from a reusable template. */
export function applyTemplateOnDate(
  template: ScheduleTemplate,
  date: string,
  hourlyRateSnapshot: number
): CopiedShiftPlan {
  return {
    employerId: template.employerId,
    roleId: template.roleId ?? null,
    date,
    startMin: template.startMin,
    endMin: template.endMin,
    breaks: template.breaks.map((item) => ({ ...item })),
    hourlyRateSnapshot,
    plannedExpectedTips: template.plannedExpectedTips ?? null,
    plannedOtherIncome: template.plannedOtherIncome ?? null,
    notes: template.notes ?? null,
    sourceTemplateId: template.id,
  };
}

/**
 * Preview a finite weekly/biweekly rule. Generated keys are stable, conflicts
 * are reported before persistence, and actual/completion data is never copied.
 */
export function previewRecurrence(
  template: ScheduleTemplate,
  rule: RecurrenceRule,
  hourlyRateSnapshot: number,
  existingShifts: readonly Shift[]
): RecurringShiftPlan[] {
  const selectedDays = new Set(rule.weekdays.filter((day) => day >= 0 && day <= 6));
  if (selectedDays.size === 0 || !rule.active) return [];

  const plans: RecurringShiftPlan[] = [];
  const anchorWeek = startOfWeekIso(rule.startDate);
  const maxOccurrences =
    rule.occurrenceCount == null ? Number.POSITIVE_INFINITY : Math.max(0, rule.occurrenceCount);
  const endDateSpan = rule.endDate
    ? dayNumber(rule.endDate) - dayNumber(rule.startDate)
    : null;
  if (endDateSpan != null && endDateSpan < 0) return [];
  const maxDays = endDateSpan != null
    ? endDateSpan
    : rule.occurrenceCount == null
      ? -1
      : Math.max(0, rule.occurrenceCount * rule.cadenceWeeks * 7 + 6);

  if (maxDays < 0) return [];

  for (let offset = 0; offset <= maxDays && plans.length < maxOccurrences; offset++) {
    const date = addDaysIso(rule.startDate, offset);
    const weekIndex = Math.floor((dayNumber(startOfWeekIso(date)) - dayNumber(anchorWeek)) / 7);
    if (weekIndex % rule.cadenceWeeks !== 0 || !selectedDays.has(mondayWeekday(date))) continue;

    const recurrenceKey = `${rule.id}:${template.id}:${date}`;
    const base = applyTemplateOnDate(template, date, hourlyRateSnapshot);
    const exact = existingShifts.filter(
      (shift) =>
        shift.recurrenceKey === recurrenceKey ||
        (shift.status === 'planned' &&
          shift.employerId === base.employerId &&
          shift.date === base.date &&
          shift.startMin === base.startMin &&
          shift.endMin === base.endMin)
    );
    const overlaps = findOverlaps(base, existingShifts);
    const conflict: PlanConflict = exact.length > 0 ? 'duplicate' : overlaps.length > 0 ? 'overlap' : 'none';
    const conflicts = exact.length > 0 ? exact : overlaps;
    plans.push({
      ...base,
      sourceRecurrenceRuleId: rule.id,
      recurrenceKey,
      conflict,
      conflictingShiftIds: conflicts.map((shift) => shift.id),
    });
  }

  return plans;
}

/**
 * Duplicate every SCHEDULED shift of the week starting at `weekStartIso`
 * into the following week (same weekday, times, employer, role, breaks,
 * rate snapshot). Worked/missed/cancelled shifts are never copied, and no
 * actual/completion data is ever carried over.
 */
export function copyWeekForward(shifts: readonly Shift[], weekStartIso: string): CopiedShiftPlan[] {
  const weekDates = new Set(weekDatesIso(weekStartIso));
  return shifts
    .filter((s) => s.status === 'planned' && weekDates.has(s.date))
    .map((s) => ({
      employerId: s.employerId,
      roleId: s.roleId ?? null,
      date: addDaysIso(s.date, 7),
      startMin: s.startMin,
      endMin: s.endMin,
      breaks: s.breaks.map((b) => ({ ...b })),
      hourlyRateSnapshot: s.hourlyRateSnapshot,
      plannedExpectedTips: s.plannedExpectedTips ?? null,
      plannedOtherIncome: s.plannedOtherIncome ?? null,
      notes: s.notes ?? null,
      recurrenceKey: `copy-week:${s.id}:${addDaysIso(s.date, 7)}`,
    }));
}

/**
 * Preview copy-week destinations against the current ledger. Stable keys make
 * retries idempotent; exact existing shifts are marked as duplicates so the UI
 * can skip them while still warning about intentional cross-employer overlaps.
 */
export function previewCopyWeek(
  shifts: readonly Shift[],
  weekStartIso: string
): RecurringShiftPlan[] {
  return copyWeekForward(shifts, weekStartIso).map((plan) => {
    const exact = shifts.filter(
      (shift) =>
        shift.recurrenceKey === plan.recurrenceKey ||
        (shift.status === 'planned' &&
          shift.employerId === plan.employerId &&
          shift.date === plan.date &&
          shift.startMin === plan.startMin &&
          shift.endMin === plan.endMin)
    );
    const overlaps = findOverlaps(plan, shifts);
    const conflict: PlanConflict = exact.length > 0
      ? 'duplicate'
      : overlaps.length > 0
        ? 'overlap'
        : 'none';
    const conflicts = exact.length > 0 ? exact : overlaps;
    return {
      ...plan,
      conflict,
      conflictingShiftIds: conflicts.map((shift) => shift.id),
    };
  });
}
