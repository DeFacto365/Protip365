jest.mock('../../state/entitlementStore', () => ({
  assertWriteAccess: jest.fn(),
}));

jest.mock('../../data/repositories', () => ({
  employersRepo: {
    list: jest.fn(() => []),
    create: jest.fn(),
    update: jest.fn(),
    archive: jest.fn(),
    remove: jest.fn(),
  },
  rolesRepo: {
    list: jest.fn(() => []),
    create: jest.fn(),
    update: jest.fn(),
    remove: jest.fn(),
  },
  shiftsRepo: {
    list: jest.fn(() => []),
    create: jest.fn(),
    updateScheduled: jest.fn(),
    completeShift: jest.fn(),
    correctWorkedToPlanned: jest.fn(),
    markNotWorked: jest.fn(),
    remove: jest.fn(),
    getById: jest.fn(),
  },
  scheduleTemplatesRepo: {
    list: jest.fn(() => []),
    create: jest.fn(),
    update: jest.fn(),
  },
  recurrenceRulesRepo: {
    list: jest.fn(() => []),
    create: jest.fn(),
    update: jest.fn(),
    saveSeries: jest.fn(),
    end: jest.fn(),
  },
  weeklyGoalsRepo: {
    list: jest.fn(() => []),
    upsert: jest.fn(),
    remove: jest.fn(),
  },
}));

jest.mock('../../state/settingsStore', () => ({
  useSettingsStore: { getState: jest.fn(() => ({})) },
}));

jest.mock('../../notifications/shiftReminders', () => ({
  cancelShiftReminder: jest.fn(() => Promise.resolve()),
  syncAllShiftReminders: jest.fn(() => Promise.resolve()),
  syncShiftReminder: jest.fn(() => Promise.resolve()),
}));

jest.mock('../../data/backup', () => ({
  restoreEncryptedFullBackup: jest.fn(),
}));

import { restoreEncryptedFullBackup } from '../../data/backup';
import { assertWriteAccess } from '../../state/entitlementStore';
import { restoreEncryptedBackupWithWriteAccess } from '../../state/backupRestoreStore';
import { useEmployersStore } from '../../state/employersStore';
import { useGoalsStore } from '../../state/goalsStore';
import { useShiftsStore } from '../../state/shiftsStore';
import { useTemplatesStore } from '../../state/templatesStore';

const writeGuard = assertWriteAccess as jest.MockedFunction<typeof assertWriteAccess>;
const restoreBackup = restoreEncryptedFullBackup as jest.MockedFunction<
  typeof restoreEncryptedFullBackup
>;

beforeEach(() => {
  jest.clearAllMocks();
  writeGuard.mockImplementation(() => {
    throw new Error('read_only_trial_expired');
  });
});

describe('expired entitlement mutation guards', () => {
  it('blocks every employer, role, template, recurrence, and goal mutation', () => {
    const employers = useEmployersStore.getState();
    const templates = useTemplatesStore.getState();
    const goals = useGoalsStore.getState();
    const actions = [
      () => employers.addEmployer(undefined as never),
      () => employers.updateEmployer(undefined as never),
      () => employers.archiveEmployer('employer', true),
      () => employers.removeEmployer('employer'),
      () => employers.addRole(undefined as never),
      () => employers.updateRole(undefined as never),
      () => employers.removeRole('role'),
      () => templates.addTemplate(undefined as never),
      () => templates.updateTemplate(undefined as never),
      () => templates.archiveTemplate('template', true),
      () => templates.addRule(undefined as never),
      () => templates.updateRule(undefined as never),
      () => templates.saveSeries(undefined as never),
      () => templates.endRule('rule'),
      () => goals.addGoal(undefined as never),
      () => goals.removeGoal('goal'),
    ];

    for (const action of actions) {
      expect(action).toThrow('read_only_trial_expired');
    }
    expect(writeGuard).toHaveBeenCalledTimes(actions.length);
  });

  it('blocks every scheduled and completed shift mutation', async () => {
    const shifts = useShiftsStore.getState();
    const actions = [
      () => shifts.addShift(undefined as never),
      () => shifts.updateScheduled('shift', undefined as never),
      () => shifts.completeShift('shift', undefined as never),
      () => shifts.correctWorkedToPlanned('shift', true),
      () => shifts.markNotWorked('shift', 'cancelled', undefined as never, null),
      () => shifts.deleteShift('shift'),
    ];

    for (const action of actions) {
      await expect(action()).rejects.toThrow('read_only_trial_expired');
    }
    expect(writeGuard).toHaveBeenCalledTimes(actions.length);
  });

  it('blocks encrypted restore before any backup data is changed', () => {
    expect(() =>
      restoreEncryptedBackupWithWriteAccess('encrypted', 'password')
    ).toThrow('read_only_trial_expired');
    expect(restoreBackup).not.toHaveBeenCalled();
  });
});
