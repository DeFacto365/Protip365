import { describe, expect, it } from "vitest";
import type { ShiftIncome } from "../protipData";
import {
  buildCsvExport,
  buildReportInsights,
  buildReportSummary,
  buildTrendPoints,
  filterShiftsByPeriod,
  startOfReportPeriod,
} from "../reporting";

const shifts: ShiftIncome[] = [
  shift({
    cash_out: 10,
    employer_name: "Cafe, North",
    hours: 6,
    hourly_rate: 16,
    sales: 500,
    shift_date: "2026-06-15",
    tips: 100,
    total_income: 186,
  }),
  shift({
    cash_out: 5,
    employer_name: "Patio",
    hours: 4,
    hourly_rate: 18,
    sales: 300,
    shift_date: "2026-06-17",
    tips: 60,
    total_income: 127,
  }),
  shift({
    cash_out: 0,
    employer_name: "Old Job",
    hours: 5,
    hourly_rate: 15,
    sales: 200,
    shift_date: "2026-05-31",
    tips: 40,
    total_income: 115,
  }),
];

describe("reporting helpers", () => {
  it("starts weekly reports on the configured week start", () => {
    expect(dateValue(startOfReportPeriod(new Date(2026, 5, 17), "week", 1))).toBe("2026-06-15");
    expect(dateValue(startOfReportPeriod(new Date(2026, 5, 17), "week", 0))).toBe("2026-06-14");
  });

  it("filters reports by period using local date boundaries", () => {
    const weekly = filterShiftsByPeriod(shifts, "week", new Date(2026, 5, 17), 1);

    expect(weekly.map((item) => item.shift_date)).toEqual(["2026-06-15", "2026-06-17"]);
  });

  it("builds money summaries without Supabase", () => {
    const summary = buildReportSummary(filterShiftsByPeriod(shifts, "week", new Date(2026, 5, 17), 1));

    expect(summary.shiftCount).toBe(2);
    expect(summary.completedShifts).toBe(2);
    expect(summary.hours).toBe(10);
    expect(summary.sales).toBe(800);
    expect(summary.tips).toBe(160);
    expect(summary.cashOut).toBe(15);
    expect(summary.netTips).toBe(145);
    expect(summary.totalIncome).toBe(313);
    expect(summary.averageTipPercentage).toBe(20);
    expect(summary.bestShift?.shift_date).toBe("2026-06-15");
  });

  it("exports detailed CSV with escaped values", () => {
    const csv = buildCsvExport([shifts[0]], "detailed");

    expect(csv.split("\n")[0]).toContain("Date,Employer,Status");
    expect(csv).toContain("\"Cafe, North\"");
    expect(csv).toContain("2026-06-15");
    expect(csv).toContain("90.00");
  });

  it("exports summary CSV rows", () => {
    const csv = buildCsvExport(filterShiftsByPeriod(shifts, "week", new Date(2026, 5, 17), 1), "summary");

    expect(csv).toContain("Metric,Value");
    expect(csv).toContain("Total income,313.00");
    expect(csv).toContain("Average tip percentage,20.00");
  });

  it("creates trend points and plain-language insights", () => {
    const filtered = filterShiftsByPeriod(shifts, "week", new Date(2026, 5, 17), 1);
    const trends = buildTrendPoints(filtered, "week");
    const insights = buildReportInsights(buildReportSummary(filtered), trends);

    expect(trends).toEqual([
      { hours: 6, label: "2026-06-15", tips: 100, totalIncome: 186 },
      { hours: 4, label: "2026-06-17", tips: 60, totalIncome: 127 },
    ]);
    expect(insights[0]).toContain("Best shift: 2026-06-15");
    expect(insights[1]).toContain("Average income per hour");
  });
});

function dateValue(date: Date) {
  return `${date.getFullYear()}-${`${date.getMonth() + 1}`.padStart(2, "0")}-${`${date.getDate()}`.padStart(2, "0")}`;
}

function shift(overrides: Partial<ShiftIncome>): ShiftIncome {
  const hours = overrides.hours ?? 0;
  const hourlyRate = overrides.hourly_rate ?? 0;
  const tips = overrides.tips ?? 0;
  const cashOut = overrides.cash_out ?? 0;
  const sales = overrides.sales ?? 0;
  const baseIncome = hours * hourlyRate;

  return {
    base_income: baseIncome,
    cash_out: cashOut,
    employer_id: null,
    employer_name: null,
    end_time: "17:00",
    has_earnings: true,
    hourly_rate: hourlyRate,
    hours,
    id: overrides.shift_date ?? "shift",
    income_id: null,
    net_tips: tips - cashOut,
    sales,
    shift_date: "2026-06-01",
    shift_id: overrides.shift_date ?? "shift",
    shift_status: "completed",
    start_time: "11:00",
    tip_percentage: sales > 0 ? (tips / sales) * 100 : 0,
    tips,
    total_income: baseIncome + tips - cashOut,
    user_id: "user-1",
    ...overrides,
  };
}
