import { describe, expect, it } from "vitest";
import { buildCalendarItems, buildHistoryItems, editTargetForRecord, statusLabel } from "./historyViewModel";
import { ShiftRecord } from "../../domain";

function record(date: string, id: string, status: ShiftRecord["plannedShift"]["status"] = "planned"): ShiftRecord {
  return {
    entry:
      status === "completed"
        ? {
            actualHours: 5,
            id: `entry-${id}`,
            sales: 500,
            shiftId: id,
            tips: { card: 100, cash: 20 },
            userId: "user-1",
          }
        : undefined,
    plannedShift: {
      endTime: "22:00",
      hourlyRate: 15,
      id,
      shiftDate: date,
      startTime: "17:00",
      status,
      userId: "user-1",
    },
  };
}

describe("historyViewModel", () => {
  it("labels shift statuses", () => {
    expect(statusLabel("planned")).toBe("Planned");
    expect(statusLabel("completed")).toBe("Completed");
    expect(statusLabel("missed")).toBe("Missed");
    expect(statusLabel("did_not_work")).toBe("Did not work");
  });

  it("routes completed records to daily entry and non-worked records to planned shift edit", () => {
    expect(editTargetForRecord(record("2026-05-09", "completed", "completed"))).toBe("dailyEntry");
    expect(editTargetForRecord(record("2026-05-10", "planned", "planned"))).toBe("plannedShift");
    expect(editTargetForRecord(record("2026-05-11", "missed", "missed"))).toBe("plannedShift");
  });

  it("sorts calendar ascending and history descending across past and future records", () => {
    const records = [record("2026-05-10", "future"), record("2026-05-01", "past"), record("2026-05-09", "today")];

    expect(buildCalendarItems(records).map((item) => item.id)).toEqual(["past", "today", "future"]);
    expect(buildHistoryItems(records).map((item) => item.id)).toEqual(["future", "today", "past"]);
  });
});
