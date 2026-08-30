import { create } from 'zustand';
import type { NotWorkedReason, Shift, ShiftActualsInput } from '../domain/types';
import { shiftsRepo, type NewShiftInput } from '../data/repositories';
import { cancelShiftReminder, syncAllShiftReminders, syncShiftReminder } from '../notifications/shiftReminders';
import { useSettingsStore } from './settingsStore';
import { assertWriteAccess } from './entitlementStore';

interface ShiftsState {
  shifts: Shift[];
  loaded: boolean;
  load: () => Promise<void>;
  addShift: (input: NewShiftInput) => Promise<Shift>;
  updateScheduled: (id: string, input: NewShiftInput) => Promise<void>;
  completeShift: (id: string, actuals: ShiftActualsInput) => Promise<Shift>;
  correctWorkedToPlanned: (id: string, confirmedCorrection: boolean) => Promise<void>;
  markNotWorked: (
    id: string,
    status: 'missed' | 'cancelled',
    reason: NotWorkedReason,
    note: string | null
  ) => Promise<void>;
  deleteShift: (id: string) => Promise<void>;
  getById: (id: string) => Shift | undefined;
}

function reload(): Shift[] {
  return shiftsRepo.list();
}

function reminderSettings() {
  const state = useSettingsStore.getState();
  return {
    enabled: state.postShiftReminderEnabled,
    delayMinutes: state.postShiftReminderDelayMinutes,
  };
}

export const useShiftsStore = create<ShiftsState>((set, get) => ({
  shifts: [],
  loaded: false,

  load: async () => {
    const shifts = reload();
    set({ shifts, loaded: true });
    const reminder = reminderSettings();
    await syncAllShiftReminders(shifts, reminder.enabled, reminder.delayMinutes).catch(() => undefined);
  },

  addShift: async (input) => {
    assertWriteAccess();
    const shift = shiftsRepo.create(input);
    set({ shifts: reload() });
    const reminder = reminderSettings();
    await syncShiftReminder(shift, reminder.enabled, reminder.delayMinutes).catch(() => undefined);
    return shift;
  },

  updateScheduled: async (id, input) => {
    assertWriteAccess();
    const expectedStatus = get().shifts.find((shift) => shift.id === id)?.status;
    if (!expectedStatus) throw new Error('shift_not_found');
    shiftsRepo.updateScheduled(id, input, expectedStatus);
    const shifts = reload();
    set({ shifts });
    const updated = shifts.find((shift) => shift.id === id);
    const reminder = reminderSettings();
    if (updated) {
      await syncShiftReminder(updated, reminder.enabled, reminder.delayMinutes).catch(() => undefined);
    }
  },

  completeShift: async (id, actuals) => {
    assertWriteAccess();
    const expectedStatus = get().shifts.find((shift) => shift.id === id)?.status;
    if (expectedStatus !== 'planned' && expectedStatus !== 'worked') {
      throw new Error('invalid_shift_transition');
    }
    const updated = shiftsRepo.completeShift(id, actuals, expectedStatus);
    set({ shifts: reload() });
    // Native notification cleanup is best-effort and must never hold the
    // completed transaction or its post-save navigation open.
    void cancelShiftReminder(id).catch(() => undefined);
    return updated;
  },

  correctWorkedToPlanned: async (id, confirmedCorrection) => {
    assertWriteAccess();
    shiftsRepo.correctWorkedToPlanned(id, confirmedCorrection);
    set({ shifts: reload() });
    const corrected = shiftsRepo.getById(id);
    const reminder = reminderSettings();
    if (corrected) {
      await syncShiftReminder(corrected, reminder.enabled, reminder.delayMinutes).catch(() => undefined);
    }
  },

  markNotWorked: async (id, status, reason, note) => {
    assertWriteAccess();
    shiftsRepo.markNotWorked(id, status, reason, note);
    set({ shifts: reload() });
    await cancelShiftReminder(id).catch(() => undefined);
  },

  deleteShift: async (id) => {
    assertWriteAccess();
    const expectedStatus = get().shifts.find((shift) => shift.id === id)?.status;
    if (!expectedStatus) throw new Error('shift_not_found');
    shiftsRepo.remove(id, expectedStatus);
    set({ shifts: reload() });
    await cancelShiftReminder(id).catch(() => undefined);
  },

  getById: (id) => get().shifts.find((s) => s.id === id),
}));
