/**
 * Pure cross-employer overlap detection (DEF-01, PRD §9: warn about
 * overlapping shifts without blocking an intentional overlap).
 * No React Native or database imports.
 */

import { normalizeEnd } from './calc';
import type { Shift } from './types';

export interface OverlapCandidate {
  id?: string;
  date: string;
  startMin: number;
  endMin: number;
}

/** Days since the Unix epoch for an ISO date (UTC-based, calendar-only). */
function dayNumber(iso: string): number {
  const [y, m, d] = iso.split('-').map(Number);
  return Date.UTC(y, m - 1, d) / 86_400_000;
}

/** Absolute [start, end) interval in minutes on a continuous timeline. */
function absInterval(s: OverlapCandidate): [number, number] {
  const base = dayNumber(s.date) * 1440;
  return [base + s.startMin, base + normalizeEnd(s.startMin, s.endMin)];
}

/** True when the two shifts' time windows strictly intersect (overnight-aware). */
export function shiftsOverlap(a: OverlapCandidate, b: OverlapCandidate): boolean {
  const [aStart, aEnd] = absInterval(a);
  const [bStart, bEnd] = absInterval(b);
  return aStart < bEnd && bStart < aEnd;
}

/** Statuses that occupy time on the schedule; missed/cancelled shifts do not. */
function occupiesTime(s: Shift): boolean {
  return s.status === 'planned' || s.status === 'worked';
}

/**
 * Shifts from `others` that overlap `candidate` (excluding `candidate.id`
 * itself and any missed/cancelled shifts). Used for the save-time warning.
 */
export function findOverlaps(candidate: OverlapCandidate, others: readonly Shift[]): Shift[] {
  return others.filter(
    (s) => s.id !== candidate.id && occupiesTime(s) && shiftsOverlap(candidate, s)
  );
}

/**
 * Ids of every scheduled/worked shift involved in at least one overlap.
 * Used for the agenda/week badge. O(n²) over the passed list — callers pass
 * a week (or few weeks) of shifts, not full history.
 */
export function overlappingShiftIds(shifts: readonly Shift[]): Set<string> {
  const active = shifts.filter(occupiesTime);
  const ids = new Set<string>();
  for (let i = 0; i < active.length; i++) {
    for (let j = i + 1; j < active.length; j++) {
      if (shiftsOverlap(active[i], active[j])) {
        ids.add(active[i].id);
        ids.add(active[j].id);
      }
    }
  }
  return ids;
}
