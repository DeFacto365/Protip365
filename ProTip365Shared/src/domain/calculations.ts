import {
  PlannedShift,
  ReportTotals,
  ShiftCalculation,
  ShiftEntry,
  ShiftRecord,
  TipOut,
} from "./models";

const MINUTES_PER_DAY = 24 * 60;

function roundMoney(value: number) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function roundMetric(value: number) {
  return Math.round((value + Number.EPSILON) * 10000) / 10000;
}

function safeNumber(value: number | undefined): number {
  return value !== undefined && Number.isFinite(value) ? value : 0;
}

function parseTimeToMinutes(time: string) {
  const [hours = "0", minutes = "0"] = time.split(":");
  const parsedHours = Number.parseInt(hours, 10);
  const parsedMinutes = Number.parseInt(minutes, 10);

  if (!Number.isFinite(parsedHours) || !Number.isFinite(parsedMinutes)) {
    return 0;
  }

  return parsedHours * 60 + parsedMinutes;
}

export function calculateHoursFromTimes(startTime: string, endTime: string, breakMinutes = 0) {
  const start = parseTimeToMinutes(startTime);
  let end = parseTimeToMinutes(endTime);

  if (end < start) {
    end += MINUTES_PER_DAY;
  }

  return roundMetric(Math.max(0, end - start - Math.max(0, breakMinutes)) / 60);
}

export function calculatePlannedHours(shift: PlannedShift) {
  if (Number.isFinite(shift.expectedHours)) {
    return roundMetric(Math.max(0, shift.expectedHours as number));
  }

  return calculateHoursFromTimes(shift.startTime, shift.endTime, shift.lunchBreakMinutes);
}

export function calculateActualHours(shift: PlannedShift, entry?: ShiftEntry) {
  if (!entry) {
    return 0;
  }

  if (Number.isFinite(entry.actualHours)) {
    return roundMetric(Math.max(0, entry.actualHours as number));
  }

  return calculateHoursFromTimes(
    entry.actualStartTime ?? shift.startTime,
    entry.actualEndTime ?? shift.endTime,
    shift.lunchBreakMinutes,
  );
}

export function calculateTipOutAmount(tipOut: TipOut, sales: number, grossTips: number) {
  if (tipOut.method === "fixed") {
    return roundMoney(Math.max(0, tipOut.value));
  }

  const basis = tipOut.basis === "sales" ? sales : grossTips;
  return roundMoney(Math.max(0, basis) * (Math.max(0, tipOut.value) / 100));
}

export function calculateTipOutTotal(tipOuts: TipOut[] | undefined, sales: number, grossTips: number) {
  return roundMoney((tipOuts ?? []).reduce((sum, tipOut) => sum + calculateTipOutAmount(tipOut, sales, grossTips), 0));
}

export function calculateShift(record: ShiftRecord): ShiftCalculation {
  const { plannedShift, entry } = record;
  const isMissed = plannedShift.status === "missed" || plannedShift.status === "did_not_work";
  const worked = Boolean(entry) && !isMissed;

  if (!worked) {
    return {
      cardTips: 0,
      cashTips: 0,
      grossTips: 0,
      grossWages: 0,
      hours: 0,
      netTips: 0,
      netWages: 0,
      otherIncome: 0,
      realHourlyRate: 0,
      sales: 0,
      status: plannedShift.status,
      tipOut: 0,
      tipPercentage: 0,
      totalIncome: 0,
      worked: false,
    };
  }

  const hours = calculateActualHours(plannedShift, entry);
  const sales: number = safeNumber(entry?.sales);
  const cashTips: number = safeNumber(entry?.tips?.cash);
  const cardTips: number = safeNumber(entry?.tips?.card);
  const grossTips = roundMoney(cashTips + cardTips);
  const tipOut = calculateTipOutTotal(entry?.tipOuts, sales, grossTips);
  const netTips = roundMoney(grossTips - tipOut);
  const otherIncome: number = safeNumber(entry?.otherIncome);
  const hourlyRate: number = safeNumber(entry?.hourlyRateSnapshot ?? plannedShift.hourlyRate);
  const grossWages = roundMoney(entry?.grossIncomeSnapshot ?? hours * hourlyRate);
  const deductionPercentage: number = safeNumber(entry?.deductionPercentageSnapshot);
  const netWages = roundMoney(entry?.netIncomeSnapshot ?? grossWages * (1 - Math.max(0, deductionPercentage) / 100));
  const totalIncome = roundMoney(entry?.totalIncomeSnapshot ?? netWages + netTips + otherIncome);
  const tipPercentage = sales > 0 ? roundMetric((grossTips / sales) * 100) : 0;
  const realHourlyRate = hours > 0 ? roundMoney(totalIncome / hours) : 0;

  return {
    cardTips,
    cashTips,
    grossTips,
    grossWages,
    hours,
    netTips,
    netWages,
    otherIncome,
    realHourlyRate,
    sales,
    status: plannedShift.status,
    tipOut,
    tipPercentage,
    totalIncome,
    worked,
  };
}

export function calculateReportTotals(records: ShiftRecord[]): ReportTotals {
  const totals = records.reduce(
    (accumulator, record) => {
      const shift = calculateShift(record);

      accumulator.cardTips += shift.cardTips;
      accumulator.cashTips += shift.cashTips;
      accumulator.grossTips += shift.grossTips;
      accumulator.grossWages += shift.grossWages;
      accumulator.hours += shift.hours;
      accumulator.netTips += shift.netTips;
      accumulator.netWages += shift.netWages;
      accumulator.otherIncome += shift.otherIncome;
      accumulator.sales += shift.sales;
      accumulator.tipOut += shift.tipOut;
      accumulator.totalIncome += shift.totalIncome;
      accumulator.shiftCount += 1;
      accumulator.workedShiftCount += shift.worked ? 1 : 0;
      accumulator.missedShiftCount += shift.worked ? 0 : 1;

      return accumulator;
    },
    {
      cardTips: 0,
      cashTips: 0,
      grossTips: 0,
      grossWages: 0,
      hours: 0,
      missedShiftCount: 0,
      netTips: 0,
      netWages: 0,
      otherIncome: 0,
      realHourlyRate: 0,
      sales: 0,
      shiftCount: 0,
      tipOut: 0,
      tipPercentage: 0,
      totalIncome: 0,
      workedShiftCount: 0,
    },
  );

  const roundedTotals = {
    ...totals,
    cardTips: roundMoney(totals.cardTips),
    cashTips: roundMoney(totals.cashTips),
    grossTips: roundMoney(totals.grossTips),
    grossWages: roundMoney(totals.grossWages),
    hours: roundMetric(totals.hours),
    netTips: roundMoney(totals.netTips),
    netWages: roundMoney(totals.netWages),
    otherIncome: roundMoney(totals.otherIncome),
    sales: roundMoney(totals.sales),
    tipOut: roundMoney(totals.tipOut),
    totalIncome: roundMoney(totals.totalIncome),
  };

  return {
    ...roundedTotals,
    realHourlyRate: roundedTotals.hours > 0 ? roundMoney(roundedTotals.totalIncome / roundedTotals.hours) : 0,
    tipPercentage: roundedTotals.sales > 0 ? roundMetric((roundedTotals.grossTips / roundedTotals.sales) * 100) : 0,
  };
}
