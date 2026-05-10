import { describe, expect, it } from "vitest";
import { buildReportViewModel, buildReportViewModelForPeriod, formatMoney, formatPercent } from "./reportViewModel";
import { calculateReportSummary, ShiftRecord } from "../../domain";

const record: ShiftRecord = {
  entry: {
    actualHours: 5,
    id: "entry-1",
    sales: 500,
    shiftId: "shift-1",
    tips: { card: 100, cash: 25 },
    userId: "user-1",
  },
  plannedShift: {
    endTime: "22:00",
    hourlyRate: 15,
    id: "shift-1",
    shiftDate: "2026-05-09",
    startTime: "17:00",
    status: "completed",
    userId: "user-1",
  },
};

describe("reportViewModel", () => {
  it("formats money and percentages for mobile report cards", () => {
    expect(formatMoney(123.4)).toBe("$123.40");
    expect(formatPercent(35)).toBe("35%");
    expect(formatPercent(42.5)).toBe("42.5%");
  });

  it("builds a populated report model", () => {
    const model = buildReportViewModelForPeriod({
      anchorDate: "2026-05-09",
      kind: "week",
      records: [record],
    });

    expect(model.empty).toBe(false);
    expect(model.title).toBe("Weekly report");
    expect(model.primaryMetrics).toContainEqual({ label: "Take-home", value: "$200.00" });
    expect(model.secondaryMetrics).toContainEqual({ label: "Sales", value: "$500.00" });
  });

  it("marks empty report states", () => {
    const model = buildReportViewModel(
      calculateReportSummary({
        anchorDate: "2026-05-09",
        kind: "month",
        records: [],
      }),
    );

    expect(model.empty).toBe(true);
    expect(model.title).toBe("Monthly report");
  });
});
