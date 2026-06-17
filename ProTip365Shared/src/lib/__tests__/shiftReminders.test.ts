import { describe, expect, it, vi } from "vitest";

vi.mock("react-native", () => ({
  Platform: { OS: "web" },
}));

vi.mock("expo-notifications", () => ({
  cancelScheduledNotificationAsync: vi.fn(),
  getAllScheduledNotificationsAsync: vi.fn(() => []),
  requestPermissionsAsync: vi.fn(),
  scheduleNotificationAsync: vi.fn(),
}));

describe("shift reminder helpers", async () => {
  const { missingEntryReminderDate, reminderDateForShift } = await import("../shiftReminders");

  it("schedules shift reminders before the planned start", () => {
    expect(reminderDateForShift("2026-06-17", "17:00", 30)?.toISOString()).toBe("2026-06-17T20:30:00.000Z");
    expect(reminderDateForShift("2026-06-17", "17:00", null)).toBeNull();
  });

  it("defines missing-entry alerts one hour after planned end", () => {
    expect(missingEntryReminderDate("2026-06-17", "17:00", "23:30")?.toISOString()).toBe("2026-06-18T04:30:00.000Z");
  });

  it("moves overnight missing-entry alerts to the next day", () => {
    expect(missingEntryReminderDate("2026-06-17", "22:30", "02:00")?.toISOString()).toBe("2026-06-18T07:00:00.000Z");
  });
});
