jest.mock('expo-constants', () => ({
  __esModule: true,
  default: { appOwnership: 'standalone' },
}));

jest.mock('react-native', () => ({ Platform: { OS: 'ios' } }));

jest.mock('expo-notifications', () => ({
  AndroidImportance: { DEFAULT: 3 },
  AndroidNotificationVisibility: { PRIVATE: 0 },
  SchedulableTriggerInputTypes: { DATE: 'date' },
  setNotificationHandler: jest.fn(),
  setNotificationChannelAsync: jest.fn(async () => undefined),
  getPermissionsAsync: jest.fn(async () => ({ granted: true })),
  requestPermissionsAsync: jest.fn(async () => ({ granted: true })),
  scheduleNotificationAsync: jest.fn(async () => 'scheduled-id'),
  cancelScheduledNotificationAsync: jest.fn(async () => undefined),
  cancelAllScheduledNotificationsAsync: jest.fn(async () => undefined),
}));

jest.mock('../../data/repositories', () => ({
  settingsRepo: {
    get: jest.fn(),
    set: jest.fn(),
    remove: jest.fn(),
    removeByPrefix: jest.fn(),
  },
}));

import * as Notifications from 'expo-notifications';
import { settingsRepo } from '../../data/repositories';
import {
  cancelAllAppOwnedNotifications,
  cancelAllAppOwnedNotificationsBestEffort,
  cancelShiftReminder,
  requestReminderPermission,
  syncShiftReminder,
} from '../../notifications/shiftReminders';
import type { Shift } from '../types';

const notifications = Notifications as jest.Mocked<typeof Notifications>;
const reminderSettings = settingsRepo as jest.Mocked<typeof settingsRepo>;

const futureShift: Shift = {
  id: 'shift-1',
  employerId: 'employer-1',
  date: '2099-07-18',
  startMin: 540,
  endMin: 1020,
  breaks: [],
  hourlyRateSnapshot: 2000,
  status: 'planned',
};

beforeEach(() => {
  jest.clearAllMocks();
  notifications.getPermissionsAsync.mockResolvedValue({ granted: true } as never);
  notifications.scheduleNotificationAsync.mockResolvedValue('scheduled-id');
  notifications.cancelScheduledNotificationAsync.mockResolvedValue();
  notifications.cancelAllScheduledNotificationsAsync.mockResolvedValue();
  reminderSettings.get.mockReturnValue(null);
});

describe('native reminder lifecycle serialization', () => {
  it('requests native permission when reminders are enabled without a grant', async () => {
    notifications.getPermissionsAsync.mockResolvedValueOnce({ granted: false } as never);
    notifications.requestPermissionsAsync.mockResolvedValueOnce({ granted: true } as never);

    await expect(requestReminderPermission()).resolves.toBe(true);
    expect(notifications.requestPermissionsAsync).toHaveBeenCalledTimes(1);
  });

  it('retains the notification ID when native cancellation fails', async () => {
    reminderSettings.get.mockReturnValue('native-id');
    notifications.cancelScheduledNotificationAsync.mockRejectedValueOnce(
      new Error('native_cancel_failed')
    );

    await expect(cancelShiftReminder('shift-1')).rejects.toThrow('native_cancel_failed');
    expect(reminderSettings.remove).not.toHaveBeenCalled();
  });

  it('serializes a cancel behind an in-flight schedule and cancels the new ID', async () => {
    let storedId: string | null = null;
    reminderSettings.get.mockImplementation(() => storedId);
    reminderSettings.set.mockImplementation((_key, value) => {
      storedId = value;
    });
    reminderSettings.remove.mockImplementation(() => {
      storedId = null;
    });

    let finishSchedule!: (id: string) => void;
    notifications.scheduleNotificationAsync.mockReturnValueOnce(
      new Promise<string>((resolve) => {
        finishSchedule = resolve;
      })
    );

    const scheduling = syncShiftReminder(futureShift, true, 120);
    await Promise.resolve();
    await Promise.resolve();
    const cancelling = cancelShiftReminder(futureShift.id);
    expect(notifications.cancelScheduledNotificationAsync).not.toHaveBeenCalled();

    finishSchedule('new-native-id');
    await scheduling;
    await cancelling;

    expect(reminderSettings.set).toHaveBeenCalledWith(
      'shiftReminder:shift-1',
      'new-native-id'
    );
    expect(notifications.cancelScheduledNotificationAsync).toHaveBeenCalledWith(
      'new-native-id'
    );
    expect(reminderSettings.remove).toHaveBeenCalledWith('shiftReminder:shift-1');
  });

  it('keeps stored IDs and rejects destructive cleanup if cancel-all fails', async () => {
    notifications.cancelAllScheduledNotificationsAsync.mockRejectedValueOnce(
      new Error('native_cancel_all_failed')
    );

    await expect(cancelAllAppOwnedNotifications()).rejects.toThrow(
      'native_cancel_all_failed'
    );
    expect(reminderSettings.removeByPrefix).not.toHaveBeenCalled();
  });

  it('logs and ignores native cancellation failure during local data erasure', async () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    notifications.cancelAllScheduledNotificationsAsync.mockRejectedValueOnce(
      new Error('native_cancel_all_failed')
    );

    expect(cancelAllAppOwnedNotificationsBestEffort()).toBeUndefined();
    await new Promise<void>((resolve) => setTimeout(resolve, 0));

    expect(warn).toHaveBeenCalledWith(
      'Scheduled reminder cancellation failed; continuing local data erasure.',
      expect.any(Error)
    );
    warn.mockRestore();
  });
});
