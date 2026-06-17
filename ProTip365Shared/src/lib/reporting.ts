import type { ShiftIncome } from "./protipData";

export type ReportPeriod = "week" | "month" | "year" | "all";
export type CsvExportFormat = "detailed" | "summary";

export type ReportSummary = {
  averageTipPercentage: number;
  bestShift: ShiftIncome | null;
  cashOut: number;
  completedShifts: number;
  dateRangeLabel: string;
  hours: number;
  netTips: number;
  sales: number;
  shiftCount: number;
  tips: number;
  totalIncome: number;
};

export type TrendPoint = {
  label: string;
  totalIncome: number;
  tips: number;
  hours: number;
};

function safeNumber(value: number | null | undefined) {
  return Number.isFinite(value) ? Number(value) : 0;
}

function parseShiftDate(value: string) {
  const date = new Date(`${value}T00:00:00`);

  return Number.isNaN(date.getTime()) ? null : date;
}

export function startOfReportPeriod(date: Date, period: Exclude<ReportPeriod, "all">, weekStart = 0) {
  const start = new Date(date);

  if (period === "week") {
    const diff = (start.getDay() - weekStart + 7) % 7;
    start.setDate(start.getDate() - diff);
  } else if (period === "month") {
    start.setDate(1);
  } else {
    start.setMonth(0, 1);
  }

  start.setHours(0, 0, 0, 0);

  return start;
}

export function endOfReportPeriod(start: Date, period: Exclude<ReportPeriod, "all">) {
  const end = new Date(start);

  if (period === "week") {
    end.setDate(end.getDate() + 7);
  } else if (period === "month") {
    end.setMonth(end.getMonth() + 1);
  } else {
    end.setFullYear(end.getFullYear() + 1);
  }

  return end;
}

export function filterShiftsByPeriod(shifts: ShiftIncome[], period: ReportPeriod, today = new Date(), weekStart = 0) {
  if (period === "all") {
    return [...shifts].sort(compareShiftDates);
  }

  const start = startOfReportPeriod(today, period, weekStart);
  const end = endOfReportPeriod(start, period);

  return shifts.filter((shift) => {
    const date = parseShiftDate(shift.shift_date);

    return date ? date >= start && date < end : false;
  }).sort(compareShiftDates);
}

export function buildReportSummary(shifts: ShiftIncome[]): ReportSummary {
  const shiftCount = shifts.length;
  const completedShifts = shifts.filter((shift) => shift.has_earnings || shift.shift_status === "completed").length;
  const hours = shifts.reduce((total, shift) => total + safeNumber(shift.hours), 0);
  const sales = shifts.reduce((total, shift) => total + safeNumber(shift.sales), 0);
  const tips = shifts.reduce((total, shift) => total + safeNumber(shift.tips), 0);
  const cashOut = shifts.reduce((total, shift) => total + safeNumber(shift.cash_out), 0);
  const totalIncome = shifts.reduce((total, shift) => total + safeNumber(shift.total_income), 0);
  const bestShift = shifts.reduce<ShiftIncome | null>((best, shift) => {
    if (!best) {
      return shift;
    }

    return safeNumber(shift.total_income) > safeNumber(best.total_income) ? shift : best;
  }, null);

  return {
    averageTipPercentage: sales > 0 ? (tips / sales) * 100 : 0,
    bestShift,
    cashOut,
    completedShifts,
    dateRangeLabel: buildDateRangeLabel(shifts),
    hours,
    netTips: tips - cashOut,
    sales,
    shiftCount,
    tips,
    totalIncome,
  };
}

export function buildTrendPoints(shifts: ShiftIncome[], period: ReportPeriod): TrendPoint[] {
  const groups = new Map<string, TrendPoint>();

  for (const shift of shifts) {
    const label = trendLabel(shift.shift_date, period);
    const current = groups.get(label) ?? { hours: 0, label, tips: 0, totalIncome: 0 };
    current.hours += safeNumber(shift.hours);
    current.tips += safeNumber(shift.tips);
    current.totalIncome += safeNumber(shift.total_income);
    groups.set(label, current);
  }

  return [...groups.values()].sort((left, right) => left.label.localeCompare(right.label));
}

export function buildReportInsights(summary: ReportSummary, trends: TrendPoint[]) {
  const insights: string[] = [];

  if (summary.shiftCount === 0) {
    return ["No shifts in this period yet."];
  }

  if (summary.bestShift) {
    insights.push(`Best shift: ${summary.bestShift.shift_date} at ${currency(summary.bestShift.total_income)} total income.`);
  }

  if (summary.hours > 0) {
    insights.push(`Average income per hour: ${currency(summary.totalIncome / summary.hours)}.`);
  }

  const bestTrend = trends.reduce<TrendPoint | null>((best, point) => {
    if (!best) {
      return point;
    }

    return point.totalIncome > best.totalIncome ? point : best;
  }, null);

  if (bestTrend && trends.length > 1) {
    insights.push(`Strongest ${trends.length > 6 ? "period" : "day"}: ${bestTrend.label} with ${currency(bestTrend.totalIncome)}.`);
  }

  return insights;
}

export function buildCsvExport(shifts: ShiftIncome[], format: CsvExportFormat) {
  if (format === "summary") {
    const summary = buildReportSummary(shifts);

    return toCsv([
      ["Metric", "Value"],
      ["Date range", summary.dateRangeLabel],
      ["Shifts", summary.shiftCount],
      ["Completed shifts", summary.completedShifts],
      ["Hours", fixed(summary.hours)],
      ["Sales", fixed(summary.sales)],
      ["Tips", fixed(summary.tips)],
      ["Cash out", fixed(summary.cashOut)],
      ["Net tips", fixed(summary.netTips)],
      ["Total income", fixed(summary.totalIncome)],
      ["Average tip percentage", fixed(summary.averageTipPercentage)],
    ]);
  }

  return toCsv([
    ["Date", "Employer", "Status", "Start", "End", "Hours", "Hourly rate", "Sales", "Tips", "Cash out", "Net tips", "Base income", "Total income", "Tip percentage"],
    ...shifts.map((shift) => [
      shift.shift_date,
      shift.employer_name ?? "",
      shift.shift_status ?? "",
      shift.start_time ?? "",
      shift.end_time ?? "",
      fixed(shift.hours),
      fixed(shift.hourly_rate ?? 0),
      fixed(shift.sales),
      fixed(shift.tips),
      fixed(shift.cash_out),
      fixed(shift.net_tips),
      fixed(shift.base_income),
      fixed(shift.total_income),
      fixed(shift.tip_percentage),
    ]),
  ]);
}

function compareShiftDates(left: ShiftIncome, right: ShiftIncome) {
  return left.shift_date.localeCompare(right.shift_date);
}

function buildDateRangeLabel(shifts: ShiftIncome[]) {
  const dates = shifts.map((shift) => shift.shift_date).filter(Boolean).sort();

  if (dates.length === 0) {
    return "No dates";
  }

  const first = dates[0];
  const last = dates[dates.length - 1];

  return first === last ? first : `${first} to ${last}`;
}

function trendLabel(shiftDate: string, period: ReportPeriod) {
  const date = parseShiftDate(shiftDate);

  if (!date) {
    return shiftDate;
  }

  if (period === "year" || period === "all") {
    return `${date.getFullYear()}-${`${date.getMonth() + 1}`.padStart(2, "0")}`;
  }

  return shiftDate;
}

function toCsv(rows: Array<Array<string | number>>) {
  return rows.map((row) => row.map(csvCell).join(",")).join("\n");
}

function csvCell(value: string | number) {
  const text = String(value);

  if (/[",\n]/.test(text)) {
    return `"${text.replace(/"/g, "\"\"")}"`;
  }

  return text;
}

function fixed(value: number | null | undefined) {
  return safeNumber(value).toFixed(2);
}

function currency(value: number) {
  return new Intl.NumberFormat(undefined, {
    currency: "USD",
    maximumFractionDigits: 2,
    minimumFractionDigits: 2,
    style: "currency",
  }).format(safeNumber(value));
}
