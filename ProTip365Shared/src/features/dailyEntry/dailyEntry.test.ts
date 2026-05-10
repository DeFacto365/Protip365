import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  buildShiftRecordFromDailyEntry,
  createDefaultDailyEntryForm,
  formFromShiftRecord,
  previewDailyEntry,
  validateDailyEntry,
} from "./dailyEntry";

describe("dailyEntry", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-05-09T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("creates a fast default form for today", () => {
    expect(createDefaultDailyEntryForm().date).toBe("2026-05-09");
  });

  it("validates required and numeric fields", () => {
    const errors = validateDailyEntry({
      ...createDefaultDailyEntryForm(),
      date: "05/09/2026",
      hourlyRate: "",
      hours: "",
      sales: "abc",
    });

    expect(errors.date).toBe("Use YYYY-MM-DD");
    expect(errors.hourlyRate).toBe("Required");
    expect(errors.hours).toBe("Required");
    expect(errors.sales).toBe("Enter a valid positive number");
  });

  it("builds a shift record and preview from form values", () => {
    const form = {
      ...createDefaultDailyEntryForm(),
      cardTips: "140",
      cashTips: "30",
      date: "2026-05-09",
      hourlyRate: "16",
      hours: "6",
      otherIncome: "12",
      sales: "900",
      tipOutBasis: "sales" as const,
      tipOutMethod: "percentage" as const,
      tipOutName: "Bar",
      tipOutValue: "3",
    };

    const record = buildShiftRecordFromDailyEntry(form);
    const preview = previewDailyEntry(form);

    expect(record.plannedShift.status).toBe("completed");
    expect(record.entry?.tipOuts?.[0]?.name).toBe("Bar");
    expect(preview?.grossTips).toBe(170);
    expect(preview?.tipOut).toBe(27);
    expect(preview?.totalIncome).toBe(251);
    expect(preview?.realHourlyRate).toBe(41.83);
  });

  it("round-trips an existing shift record into edit form values", () => {
    const original = buildShiftRecordFromDailyEntry({
      ...createDefaultDailyEntryForm(),
      cardTips: "80",
      cashTips: "20",
      hourlyRate: "15",
      hours: "5",
      sales: "500",
    });

    expect(formFromShiftRecord(original)).toMatchObject({
      cardTips: "80",
      cashTips: "20",
      hourlyRate: "15",
      hours: "5",
      sales: "500",
    });
  });
});
