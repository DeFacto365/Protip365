import { Platform } from "react-native";

export type ShiftReminderInput = {
  alertMinutes: number | null;
  endTime: string;
  shiftDate: string;
  shiftId: string;
  startTime: string;
};

export const MISSING_ENTRY_GRACE_MINUTES = 60;

let notificationsModule: any | null = null;
let notificationHandlerConfigured = false;

async function getNotifications(): Promise<any | null> {
  if (Platform.OS === "web" || (Platform.OS === "android" && __DEV__)) {
    return null;
  }

  try {
    notificationsModule ??= await import("expo-notifications");
  } catch {
    return null;
  }

  if (!notificationHandlerConfigured) {
    notificationsModule.setNotificationHandler({
      handleNotification: async () => ({
        shouldPlaySound: false,
        shouldSetBadge: false,
        shouldShowBanner: true,
        shouldShowList: true,
      }),
    });
    notificationHandlerConfigured = true;
  }

  return notificationsModule;
}

export function parseLocalShiftDateTime(shiftDate: string, time: string) {
  const parsed = new Date(`${shiftDate}T${time}:00`);

  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export function reminderDateForShift(shiftDate: string, startTime: string, alertMinutes: number | null) {
  if (alertMinutes === null || alertMinutes < 0) {
    return null;
  }

  const start = parseLocalShiftDateTime(shiftDate, startTime);

  if (!start) {
    return null;
  }

  return new Date(start.getTime() - alertMinutes * 60 * 1000);
}

export function missingEntryReminderDate(shiftDate: string, startTime: string, endTime: string) {
  const start = parseLocalShiftDateTime(shiftDate, startTime);
  const end = parseLocalShiftDateTime(shiftDate, endTime);

  if (!start || !end) {
    return null;
  }

  if (end <= start) {
    end.setDate(end.getDate() + 1);
  }

  return new Date(end.getTime() + MISSING_ENTRY_GRACE_MINUTES * 60 * 1000);
}

export async function scheduleShiftReminders(input: ShiftReminderInput) {
  const notifications = await getNotifications();

  if (!notifications) {
    return { scheduled: false, reason: "Local reminders are not available in this runtime." };
  }

  await cancelShiftReminders(input.shiftId);

  if (Platform.OS === "android") {
    await notifications.setNotificationChannelAsync("shift-reminders", {
      importance: notifications.AndroidImportance.DEFAULT,
      name: "Shift reminders",
    });
  }

  const { status } = await notifications.requestPermissionsAsync();

  if (status !== "granted") {
    return { scheduled: false, reason: "Notification permission was not granted." };
  }

  const now = Date.now();
  const reminderCandidates = [
    {
      body: "Your planned shift is coming up.",
      date: reminderDateForShift(input.shiftDate, input.startTime, input.alertMinutes),
      title: "Shift reminder",
    },
    {
      body: "Add your sales and tips so your totals stay accurate.",
      date: missingEntryReminderDate(input.shiftDate, input.startTime, input.endTime),
      title: "Enter shift income",
    },
  ];
  const reminders: { body: string; date: Date; title: string }[] = [];

  for (const reminder of reminderCandidates) {
    if (reminder.date && reminder.date.getTime() > now) {
      reminders.push({ body: reminder.body, date: reminder.date, title: reminder.title });
    }
  }

  if (reminders.length === 0) {
    return { scheduled: false, reason: "No future reminder time was available for this shift." };
  }

  await Promise.all(
    reminders.map((reminder) =>
      notifications.scheduleNotificationAsync({
        content: {
          body: reminder.body,
          data: { shiftId: input.shiftId },
          title: reminder.title,
        },
        trigger: {
          channelId: "shift-reminders",
          date: reminder.date,
          type: notifications.SchedulableTriggerInputTypes.DATE,
        },
      }),
    ),
  );

  return { scheduled: true, reason: null };
}

export async function cancelShiftReminders(shiftId: string) {
  const notifications = await getNotifications();

  if (!notifications) {
    return;
  }

  const scheduled: { content: { data?: { shiftId?: string } }; identifier: string }[] =
    await notifications.getAllScheduledNotificationsAsync();

  await Promise.all(
    scheduled
      .filter((notification) => notification.content.data?.shiftId === shiftId)
      .map((notification) => notifications.cancelScheduledNotificationAsync(notification.identifier)),
  );
}
