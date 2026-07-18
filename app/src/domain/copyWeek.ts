/**
 * Pure "copy week forward" planning. No React Native or database imports.
 */

import { addDaysIso, weekDatesIso } from './dates';
import type { Shift, ShiftBreak } from './types';

/** A planned (not yet persisted) scheduled shift produced by the copy. */
export interface CopiedShiftPlan {
  employerId: string;
  roleId?: string | null;
  date: string;
  startMin: number;
  endMin: number;
  breaks: ShiftBreak[];
  hourlyRateSnapshot: number;
  notes?: string | null;
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
    .filter((s) => s.status === 'scheduled' && weekDates.has(s.date))
    .map((s) => ({
      employerId: s.employerId,
      roleId: s.roleId ?? null,
      date: addDaysIso(s.date, 7),
      startMin: s.startMin,
      endMin: s.endMin,
      breaks: s.breaks.map((b) => ({ ...b })),
      hourlyRateSnapshot: s.hourlyRateSnapshot,
      notes: s.notes ?? null,
    }));
}
