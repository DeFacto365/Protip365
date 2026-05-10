import { describe, expect, it } from "vitest";
import {
  calculateActualHours,
  calculateHoursFromTimes,
  calculatePlannedHours,
  calculateReportSummary,
  calculateReportTotals,
  calculateShift,
  calculateTipOutTotal,
  filterRecordsForPeriod,
  getReportPeriod,
} from "./calculations";
import { PlannedShift, ShiftRecord } from "./models";

const plannedShift: PlannedShift = {
  endTime: "23:00:00",
  hourlyRate: 15,
  id: "shift-1",
  lunchBreakMinutes: 30,
  shiftDate: "2026-05-09",
  startTime: "17:00:00",
  status: "completed",
  userId: "user-1",
};

function workedShift(overrides: Partial<ShiftRecord> = {}): ShiftRecord {
  return {
    plannedShift,
    entry: {
      actualEndTime: "23:00:00",
      actualStartTime: "17:00:00",
      id: "entry-1",
      otherIncome: 10,
      sales: 1000,
      shiftId: "shift-1",
      tipOuts: [
        { basis: "sales", id: "bar", method: "percentage", name: "Bar", value: 3.5 },
        { basis: "tips", id: "runner", method: "percentage", name: "Runner", value: 2 },
        { basis: "tips", id: "host", method: "fixed", name: "Host", value: 5 },
      ],
      tips: { card: 150, cash: 50 },
      userId: "user-1",
    },
    ...overrides,
  };
}

function shiftOn(date: string, id: string, overrides: Partial<ShiftRecord> = {}): ShiftRecord {
  return workedShift({
    plannedShift: {
      ...plannedShift,
      id,
      shiftDate: date,
    },
    entry: {
      ...workedShift().entry!,
      id: `entry-${id}`,
      sales: 100,
      tipOuts: [],
      tips: { card: 20, cash: 5 },
    },
    ...overrides,
  });
}

describe("time and hour calculations", () => {
  it("calculates same-day hours with unpaid break minutes", () => {
    expect(calculateHoursFromTimes("17:00:00", "23:00:00", 30)).toBe(5.5);
  });

  it("calculates overnight hours", () => {
    expect(calculateHoursFromTimes("22:30:00", "02:00:00", 30)).toBe(3);
  });

  it("prefers explicit expected hours when present", () => {
    expect(calculatePlannedHours({ ...plannedShift, expectedHours: 7.25 })).toBe(7.25);
  });

  it("prefers explicit actual hours when present", () => {
    expect(calculateActualHours(plannedShift, { ...workedShift().entry!, actualHours: 4.75 })).toBe(4.75);
  });
});

describe("tip-out and income calculations", () => {
  it("calculates mixed fixed, sales percentage, and tips percentage tip-outs", () => {
    expect(calculateTipOutTotal(workedShift().entry?.tipOuts, 1000, 200)).toBe(44);
  });

  it("calculates shift income using net wages, net tips, other income, and real hourly", () => {
    const result = calculateShift(workedShift());

    expect(result.hours).toBe(5.5);
    expect(result.sales).toBe(1000);
    expect(result.cashTips).toBe(50);
    expect(result.cardTips).toBe(150);
    expect(result.grossTips).toBe(200);
    expect(result.tipOut).toBe(44);
    expect(result.netTips).toBe(156);
    expect(result.grossWages).toBe(82.5);
    expect(result.netWages).toBe(82.5);
    expect(result.otherIncome).toBe(10);
    expect(result.totalIncome).toBe(248.5);
    expect(result.realHourlyRate).toBe(45.18);
    expect(result.tipPercentage).toBe(20);
  });

  it("uses stored historical snapshots when present", () => {
    const result = calculateShift(
      workedShift({
        entry: {
          ...workedShift().entry!,
          grossIncomeSnapshot: 90,
          netIncomeSnapshot: 70,
          totalIncomeSnapshot: 260,
        },
      }),
    );

    expect(result.grossWages).toBe(90);
    expect(result.netWages).toBe(70);
    expect(result.totalIncome).toBe(260);
  });

  it("calculates deduction snapshot when no net snapshot exists", () => {
    const result = calculateShift(
      workedShift({
        entry: {
          ...workedShift().entry!,
          deductionPercentageSnapshot: 20,
        },
      }),
    );

    expect(result.grossWages).toBe(82.5);
    expect(result.netWages).toBe(66);
    expect(result.totalIncome).toBe(232);
  });

  it("does not corrupt totals for missed or did-not-work shifts", () => {
    const missed = calculateShift({
      plannedShift: { ...plannedShift, status: "missed" },
      entry: workedShift().entry,
    });
    const didNotWork = calculateShift({
      plannedShift: { ...plannedShift, status: "did_not_work" },
    });

    expect(missed.worked).toBe(false);
    expect(missed.totalIncome).toBe(0);
    expect(didNotWork.worked).toBe(false);
    expect(didNotWork.totalIncome).toBe(0);
  });

  it("handles zero sales and zero hours without invalid percentages or hourly rates", () => {
    const result = calculateShift(
      workedShift({
        entry: {
          ...workedShift().entry!,
          actualHours: 0,
          sales: 0,
        },
      }),
    );

    expect(result.tipPercentage).toBe(0);
    expect(result.realHourlyRate).toBe(0);
  });
});

describe("report totals", () => {
  it("aggregates worked and missed shifts", () => {
    const totals = calculateReportTotals([
      workedShift(),
      workedShift({
        entry: {
          ...workedShift().entry!,
          id: "entry-2",
          otherIncome: 0,
          sales: 500,
          tips: { card: 80, cash: 20 },
        },
        plannedShift: {
          ...plannedShift,
          id: "shift-2",
        },
      }),
      {
        plannedShift: {
          ...plannedShift,
          id: "shift-3",
          status: "missed",
        },
      },
    ]);

    expect(totals.shiftCount).toBe(3);
    expect(totals.workedShiftCount).toBe(2);
    expect(totals.missedShiftCount).toBe(1);
    expect(totals.hours).toBe(11);
    expect(totals.sales).toBe(1500);
    expect(totals.grossTips).toBe(300);
    expect(totals.tipOut).toBe(68.5);
    expect(totals.netTips).toBe(231.5);
    expect(totals.totalIncome).toBe(406.5);
    expect(totals.tipPercentage).toBe(20);
    expect(totals.realHourlyRate).toBe(36.95);
  });
});

describe("report periods", () => {
  it("builds today, week, month, and year periods", () => {
    expect(getReportPeriod("today", "2026-05-09")).toMatchObject({
      endDate: "2026-05-09",
      startDate: "2026-05-09",
    });
    expect(getReportPeriod("week", "2026-05-09", 1)).toMatchObject({
      endDate: "2026-05-10",
      startDate: "2026-05-04",
    });
    expect(getReportPeriod("month", "2026-02-14")).toMatchObject({
      endDate: "2026-02-28",
      startDate: "2026-02-01",
    });
    expect(getReportPeriod("year", "2026-05-09")).toMatchObject({
      endDate: "2026-12-31",
      startDate: "2026-01-01",
    });
  });

  it("supports custom week-start rules", () => {
    expect(getReportPeriod("week", "2026-05-09", 0)).toMatchObject({
      endDate: "2026-05-09",
      startDate: "2026-05-03",
    });
  });

  it("filters date boundaries inclusively", () => {
    const period = getReportPeriod("week", "2026-05-09", 1);
    const records = [
      shiftOn("2026-05-03", "before"),
      shiftOn("2026-05-04", "start"),
      shiftOn("2026-05-10", "end"),
      shiftOn("2026-05-11", "after"),
    ];

    expect(filterRecordsForPeriod(records, period).map((record) => record.plannedShift.id)).toEqual(["start", "end"]);
  });

  it("returns empty totals for empty periods", () => {
    const summary = calculateReportSummary({
      anchorDate: "2026-05-09",
      kind: "today",
      records: [],
      target: { income: 100, sales: 1000 },
    });

    expect(summary.records).toHaveLength(0);
    expect(summary.totals.totalIncome).toBe(0);
    expect(summary.targetProgress.income).toBe(0);
  });

  it("aggregates mixed employers and edited records within the requested period", () => {
    const summary = calculateReportSummary({
      anchorDate: "2026-05-09",
      kind: "month",
      records: [
        shiftOn("2026-05-01", "bar", {
          employer: { active: true, hourlyRate: 15, id: "emp-1", name: "Bar", userId: "user-1" },
        }),
        shiftOn("2026-05-09", "bistro", {
          employer: { active: true, hourlyRate: 18, id: "emp-2", name: "Bistro", userId: "user-1" },
          entry: {
            ...workedShift().entry!,
            id: "entry-bistro-edited",
            sales: 250,
            shiftId: "bistro",
            tipOuts: [],
            tips: { card: 50, cash: 10 },
          },
          plannedShift: {
            ...plannedShift,
            id: "bistro",
            shiftDate: "2026-05-09",
          },
        }),
        shiftOn("2026-06-01", "next-month"),
      ],
      target: { hours: 20, income: 500, sales: 1000, tips: 200 },
    });

    expect(summary.records.map((record) => record.plannedShift.id)).toEqual(["bar", "bistro"]);
    expect(summary.totals.sales).toBe(350);
    expect(summary.totals.grossTips).toBe(85);
    expect(summary.totals.netTips).toBe(85);
    expect(summary.totals.hours).toBe(11);
    expect(summary.targetProgress.sales).toBe(35);
    expect(summary.targetProgress.tips).toBe(42.5);
    expect(summary.targetProgress.hours).toBe(55);
  });

  it("includes missed shifts in period counts without adding income", () => {
    const summary = calculateReportSummary({
      anchorDate: "2026-05-09",
      kind: "week",
      records: [
        shiftOn("2026-05-09", "worked"),
        {
          plannedShift: {
            ...plannedShift,
            id: "missed",
            shiftDate: "2026-05-10",
            status: "missed",
          },
        },
      ],
    });

    expect(summary.totals.shiftCount).toBe(2);
    expect(summary.totals.workedShiftCount).toBe(1);
    expect(summary.totals.missedShiftCount).toBe(1);
    expect(summary.totals.totalIncome).toBe(117.5);
  });
});
