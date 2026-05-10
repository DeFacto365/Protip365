import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  buildRecordFromPlannedShift,
  createDefaultPlannedShiftForm,
  formFromPlannedShiftRecord,
  markPlannedShiftStatus,
  previewPlannedHours,
  shiftStatusLabel,
  validatePlannedShift,
} from "./plannedShift";

describe("plannedShift", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-05-09T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("creates a default planned shift form for today", () => {
    expect(createDefaultPlannedShiftForm().date).toBe("2026-05-09");
  });

  it("validates date, time, expected hours, and hourly rate", () => {
    const errors = validatePlannedShift({
      ...createDefaultPlannedShiftForm(),
      date: "05/09/2026",
      endTime: "5pm",
      expectedHours: "-1",
      hourlyRate: "",
      startTime: "9",
    });

    expect(errors.date).toBe("Use YYYY-MM-DD");
    expect(errors.startTime).toBe("Use HH:MM");
    expect(errors.endTime).toBe("Use HH:MM");
    expect(errors.expectedHours).toBe("Enter a valid positive number");
    expect(errors.hourlyRate).toBe("Required");
  });

  it("previews planned duration from times including overnight shifts", () => {
    const form = {
      ...createDefaultPlannedShiftForm(),
      endTime: "02:00",
      hourlyRate: "16",
      startTime: "18:00",
    };

    expect(previewPlannedHours(form)).toBe(8);
  });

  it("lets explicit expected hours override time duration", () => {
    const form = {
      ...createDefaultPlannedShiftForm(),
      endTime: "23:00",
      expectedHours: "4.5",
      hourlyRate: "16",
      startTime: "18:00",
    };

    expect(previewPlannedHours(form)).toBe(4.5);
  });

  it("builds and round-trips planned shift records", () => {
    const record = buildRecordFromPlannedShift({
      ...createDefaultPlannedShiftForm(),
      employerName: "Bistro",
      endTime: "22:00",
      expectedHours: "5",
      hourlyRate: "17.5",
      notes: "Patio",
      startTime: "17:00",
    });

    expect(record.entry).toBeUndefined();
    expect(record.plannedShift.status).toBe("planned");
    expect(record.employer?.name).toBe("Bistro");
    expect(formFromPlannedShiftRecord(record)).toMatchObject({
      employerName: "Bistro",
      expectedHours: "5",
      hourlyRate: "17.5",
      notes: "Patio",
    });
  });

  it("marks a planned shift missed without carrying income", () => {
    const record = buildRecordFromPlannedShift({
      ...createDefaultPlannedShiftForm(),
      endTime: "22:00",
      hourlyRate: "17.5",
      startTime: "17:00",
    });

    const missedRecord = markPlannedShiftStatus(
      {
        ...record,
        entry: {
          actualHours: 5,
          id: "entry-1",
          sales: 500,
          shiftId: record.plannedShift.id,
          tips: { card: 100, cash: 20 },
          userId: "local-user",
        },
      },
      "missed",
    );

    expect(missedRecord.plannedShift.status).toBe("missed");
    expect(missedRecord.entry).toBeUndefined();
  });

  it("labels did-not-work status for calendar and reports", () => {
    expect(shiftStatusLabel("did_not_work")).toBe("Did not work");
    expect(shiftStatusLabel("missed")).toBe("Missed");
  });
});
