import { calculateReportSummary, ReportPeriodKind, ReportSummary, ShiftRecord } from "../../domain";

export type ReportMetric = {
  label: string;
  value: string;
};

export type ReportViewModel = {
  title: string;
  subtitle: string;
  empty: boolean;
  primaryMetrics: ReportMetric[];
  secondaryMetrics: ReportMetric[];
  progressMetrics: ReportMetric[];
};

export function formatMoney(value: number) {
  return `$${value.toFixed(2)}`;
}

export function formatPercent(value: number) {
  return `${value.toFixed(value % 1 === 0 ? 0 : 1)}%`;
}

function reportTitle(kind: ReportPeriodKind) {
  switch (kind) {
    case "today":
      return "Today";
    case "week":
      return "Weekly report";
    case "month":
      return "Monthly report";
    case "year":
      return "Yearly report";
  }
}

export function buildReportViewModel(summary: ReportSummary): ReportViewModel {
  return {
    empty: summary.records.length === 0,
    primaryMetrics: [
      { label: "Take-home", value: formatMoney(summary.totals.totalIncome) },
      { label: "Net tips", value: formatMoney(summary.totals.netTips) },
      { label: "Real hourly", value: formatMoney(summary.totals.realHourlyRate) },
      { label: "Hours", value: summary.totals.hours.toFixed(2) },
    ],
    progressMetrics: [
      { label: "Income target", value: formatPercent(summary.targetProgress.income) },
      { label: "Tips target", value: formatPercent(summary.targetProgress.tips) },
      { label: "Sales target", value: formatPercent(summary.targetProgress.sales) },
      { label: "Hours target", value: formatPercent(summary.targetProgress.hours) },
    ],
    secondaryMetrics: [
      { label: "Sales", value: formatMoney(summary.totals.sales) },
      { label: "Gross tips", value: formatMoney(summary.totals.grossTips) },
      { label: "Tip-out", value: formatMoney(summary.totals.tipOut) },
      { label: "Tip %", value: formatPercent(summary.totals.tipPercentage) },
      { label: "Worked shifts", value: String(summary.totals.workedShiftCount) },
      { label: "Missed / not worked", value: String(summary.totals.missedShiftCount) },
    ],
    subtitle: summary.period.label,
    title: reportTitle(summary.period.kind),
  };
}

export function buildReportViewModelForPeriod({
  anchorDate,
  kind,
  records,
}: {
  anchorDate: string;
  kind: ReportPeriodKind;
  records: ShiftRecord[];
}) {
  return buildReportViewModel(
    calculateReportSummary({
      anchorDate,
      kind,
      records,
      target: {
        hours: 30,
        income: 1000,
        sales: 5000,
        tips: 500,
      },
    }),
  );
}
