import { Platform } from "react-native";
import * as Notifications from "expo-notifications";

export type ShiftReminderInput = {
  alertMinutes: number | null;
  endTime: string;
  shiftDate: string;
  shiftId: string;
  startTime: string;
};

export const MISSING_ENTRY_GRACE_MINUTES = 60;

if (Platform.OS !== "web") {
  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldPlaySound: false,
      shouldSetBadge: false,
      shouldShowBanner: true,
      shouldShowList: true,
    }),
  });
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
  if (Platform.OS === "web") {
    return { scheduled: false, reason: "Local reminders are not supported on web." };
  }

  await cancelShiftReminders(input.shiftId);

  if (Platform.OS === "android") {
    await Notifications.setNotificationChannelAsync("shift-reminders", {
      importance: Notifications.AndroidImportance.DEFAULT,
      name: "Shift reminders",
    });
  }

  const { status } = await Notifications.requestPermissionsAsync();

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
      Notifications.scheduleNotificationAsync({
        content: {
          body: reminder.body,
          data: { shiftId: input.shiftId },
          title: reminder.title,
        },
        trigger: {
          channelId: "shift-reminders",
          date: reminder.date,
          type: Notifications.SchedulableTriggerInputTypes.DATE,
        },
      }),
    ),
  );

  return { scheduled: true, reason: null };
}

export async function cancelShiftReminders(shiftId: string) {
  if (Platform.OS === "web") {
    return;
  }

  const scheduled = await Notifications.getAllScheduledNotificationsAsync();

  await Promise.all(
    scheduled
      .filter((notification) => notification.content.data?.shiftId === shiftId)
      .map((notification) => Notifications.cancelScheduledNotificationAsync(notification.identifier)),
  );
}
