import { describe, expect, it } from "vitest";
import {
  calculateActualHours,
  calculateHoursFromTimes,
  calculatePlannedHours,
  calculateReportTotals,
  calculateShift,
  calculateTipOutTotal,
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
