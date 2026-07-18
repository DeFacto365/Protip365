import Constants from 'expo-constants';
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';

import i18n from '../i18n';
import { reminderDate } from '../domain/reminders';
import type { Shift } from '../domain/types';
import { settingsRepo } from '../data/repositories';

const CHANNEL_ID = 'post-shift-reminders';
const REMINDER_PREFIX = 'shiftReminder:';
const reminderKey = (shiftId: string) => `shiftReminder:${shiftId}`;
let reminderOperationTail: Promise<void> = Promise.resolve();

/** Serialize native schedule/cancel calls so a late schedule cannot outrun a cancel. */
function enqueueReminderOperation(operation: () => Promise<void>): Promise<void> {
  const result = reminderOperationTail.catch(() => undefined).then(operation);
  reminderOperationTail = result;
  return result;
}

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: false,
    shouldSetBadge: false,
  }),
});

export function notificationsSupported(): boolean {
  return Constants.appOwnership !== 'expo';
}

async function ensureChannel(): Promise<void> {
  if (Platform.OS !== 'android') return;
  await Notifications.setNotificationChannelAsync(CHANNEL_ID, {
    name: i18n.t('reminders.channel'),
    importance: Notifications.AndroidImportance.DEFAULT,
    lockscreenVisibility: Notifications.AndroidNotificationVisibility.PRIVATE,
  });
}

export async function requestReminderPermission(): Promise<boolean> {
  if (!notificationsSupported()) return false;
  const current = await Notifications.getPermissionsAsync();
  if (current.granted) return true;
  const requested = await Notifications.requestPermissionsAsync();
  return requested.granted;
}

async function cancelShiftReminderNow(shiftId: string): Promise<void> {
  const key = reminderKey(shiftId);
  const notificationId = settingsRepo.get(key);
  if (!notificationId) return;
  if (!notificationsSupported()) return;
  // Remove the ID only after native cancellation succeeds. A retained ID makes
  // a failed cancellation safely retryable.
  await Notifications.cancelScheduledNotificationAsync(notificationId);
  settingsRepo.remove(key);
}

export function cancelShiftReminder(shiftId: string): Promise<void> {
  return enqueueReminderOperation(() => cancelShiftReminderNow(shiftId));
}

async function syncShiftReminderNow(
  shift: Shift,
  enabled: boolean,
  delayMinutes: number
): Promise<void> {
  await cancelShiftReminderNow(shift.id);
  if (!enabled || shift.status !== 'planned' || !notificationsSupported()) return;
  const permissions = await Notifications.getPermissionsAsync();
  if (!permissions.granted) return;
  const date = reminderDate(shift, delayMinutes);
  if (date.getTime() <= Date.now()) return;
  await ensureChannel();
  const id = await Notifications.scheduleNotificationAsync({
    content: {
      title: i18n.t('reminders.title'),
      body: i18n.t('reminders.body'),
      data: { shiftId: shift.id },
    },
    trigger: {
      type: Notifications.SchedulableTriggerInputTypes.DATE,
      date,
      ...(Platform.OS === 'android' ? { channelId: CHANNEL_ID } : {}),
    },
  });
  settingsRepo.set(reminderKey(shift.id), id);
}

export function syncShiftReminder(
  shift: Shift,
  enabled: boolean,
  delayMinutes: number
): Promise<void> {
  return enqueueReminderOperation(() => syncShiftReminderNow(shift, enabled, delayMinutes));
}

export async function syncAllShiftReminders(
  shifts: readonly Shift[],
  enabled: boolean,
  delayMinutes: number
): Promise<void> {
  for (const shift of shifts) await syncShiftReminder(shift, enabled, delayMinutes);
}

/** Cancel every notification scheduled by this app before destructive data changes. */
export function cancelAllAppOwnedNotifications(clearStoredIds = true): Promise<void> {
  return enqueueReminderOperation(async () => {
    if (notificationsSupported()) {
      await Notifications.cancelAllScheduledNotificationsAsync();
    }
    if (clearStoredIds) settingsRepo.removeByPrefix(REMINDER_PREFIX);
  });
}
