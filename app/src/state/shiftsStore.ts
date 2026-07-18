import { create } from 'zustand';
import type { NotWorkedReason, Shift, ShiftActualsInput } from '../domain/types';
import { shiftsRepo, type NewShiftInput } from '../data/repositories';

interface ShiftsState {
  shifts: Shift[];
  loaded: boolean;
  load: () => void;
  addShift: (input: NewShiftInput) => Shift;
  updateScheduled: (id: string, input: NewShiftInput) => void;
  completeShift: (id: string, actuals: ShiftActualsInput) => Shift;
  markNotWorked: (
    id: string,
    status: 'missed' | 'cancelled',
    reason: NotWorkedReason,
    note: string | null
  ) => void;
  deleteShift: (id: string) => void;
  getById: (id: string) => Shift | undefined;
}

function reload(): Shift[] {
  return shiftsRepo.list();
}

export const useShiftsStore = create<ShiftsState>((set, get) => ({
  shifts: [],
  loaded: false,

  load: () => set({ shifts: reload(), loaded: true }),

  addShift: (input) => {
    const shift = shiftsRepo.create(input);
    set({ shifts: reload() });
    return shift;
  },

  updateScheduled: (id, input) => {
    shiftsRepo.updateScheduled(id, input);
    set({ shifts: reload() });
  },

  completeShift: (id, actuals) => {
    const updated = shiftsRepo.completeShift(id, actuals);
    set({ shifts: reload() });
    return updated;
  },

  markNotWorked: (id, status, reason, note) => {
    shiftsRepo.markNotWorked(id, status, reason, note);
    set({ shifts: reload() });
  },

  deleteShift: (id) => {
    shiftsRepo.remove(id);
    set({ shifts: reload() });
  },

  getById: (id) => get().shifts.find((s) => s.id === id),
}));
