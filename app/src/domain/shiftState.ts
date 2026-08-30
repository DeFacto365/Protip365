import type { ShiftStatus } from './types';

export const ALLOWED_SHIFT_TRANSITIONS: Readonly<Record<ShiftStatus, readonly ShiftStatus[]>> = {
  planned: ['worked', 'missed', 'cancelled'],
  worked: ['planned'],
  missed: [],
  cancelled: [],
};

export interface ShiftTransitionOptions {
  confirmedCorrection?: boolean;
}

export function canTransitionShift(
  from: ShiftStatus,
  to: ShiftStatus,
  options: ShiftTransitionOptions = {}
): boolean {
  if (!ALLOWED_SHIFT_TRANSITIONS[from].includes(to)) return false;
  if (from === 'worked' && to === 'planned') return options.confirmedCorrection === true;
  return true;
}

export function assertShiftTransition(
  from: ShiftStatus,
  to: ShiftStatus,
  options: ShiftTransitionOptions = {}
): void {
  if (!canTransitionShift(from, to, options)) throw new Error('invalid_shift_transition');
}
