import { normalizeEnd } from './calc';
import type { Shift } from './types';

/** Resolve a scheduled local work date + overnight-aware end time to a Date. */
export function scheduledEndDate(
  shift: Pick<Shift, 'date' | 'startMin' | 'endMin'>
): Date {
  const [year, month, day] = shift.date.split('-').map(Number);
  const endMinutes = normalizeEnd(shift.startMin, shift.endMin);
  return new Date(year, month - 1, day, 0, endMinutes, 0, 0);
}

export function reminderDate(
  shift: Pick<Shift, 'date' | 'startMin' | 'endMin'>,
  delayMinutes = 120
): Date {
  return new Date(scheduledEndDate(shift).getTime() + delayMinutes * 60_000);
}

export function isActualsPending(
  shift: Pick<Shift, 'status' | 'date' | 'startMin' | 'endMin'>,
  now = new Date(),
  delayMinutes = 120
): boolean {
  return shift.status === 'planned' && now.getTime() >= reminderDate(shift, delayMinutes).getTime();
}
