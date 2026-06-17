import { useMemo } from "react";
import { Alert, Share, StyleSheet, Text, View } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { ClipboardList, Download, History, ReceiptText } from "lucide-react-native";
import { ActionList } from "../components/ActionList";
import {
  buildCsvExport,
  buildReportInsights,
  buildReportSummary,
  buildTrendPoints,
  CsvExportFormat,
  filterShiftsByPeriod,
  ReportPeriod,
} from "../lib/reporting";
import { ReportsStackParamList } from "../navigation/types";
import { theme } from "../theme";
import { buildStats, DataScaffold, InfoRow, PrimaryButton, ShiftList, StatsGrid, strings, styles, useAppData } from "./shared/screenShared";

export function ReportsScreen({ navigation }: NativeStackScreenProps<ReportsStackParamList, "ReportsHome">) {
  const { isLoading, reload, shifts } = useAppData();
  const stats = useMemo(() => buildStats(shifts), [shifts]);
  const summary = useMemo(() => buildReportSummary(shifts), [shifts]);
  const insights = useMemo(() => buildReportInsights(summary, buildTrendPoints(shifts, "all")), [shifts, summary]);

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.reports}>
      <StatsGrid stats={stats} />
      <ReportSummaryCard summary={summary} title="All-time report summary" />
      <InsightsCard insights={insights} />
      <ActionList
        items={[
          {
            icon: <ClipboardList color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.viewWeekly,
            onPress: () => navigation.navigate("WeeklyReport"),
          },
          {
            icon: <ReceiptText color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.viewMonthly,
            onPress: () => navigation.navigate("MonthlyReport"),
          },
          {
            icon: <ReceiptText color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.viewYearly,
            onPress: () => navigation.navigate("YearlyReport"),
          },
          {
            icon: <History color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.viewHistory,
            onPress: () => navigation.navigate("History"),
          },
          {
            icon: <Download color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: "Export all shifts CSV",
            onPress: () => void shareCsv(shifts, "detailed"),
          },
        ]}
      />
    </DataScaffold>
  );
}

export function WeeklyReportScreen() {
  return <ReportRangeScreen range="week" title={strings.screens.weeklyReport} />;
}

export function MonthlyReportScreen() {
  return <ReportRangeScreen range="month" title={strings.screens.monthlyReport} />;
}

export function YearlyReportScreen() {
  return <ReportRangeScreen range="year" title={strings.screens.yearlyReport} />;
}

export function HistoryScreen() {
  const { isLoading, reload, shifts } = useAppData();

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.history}>
      <ShiftList emptyText="No history yet." shifts={shifts} />
    </DataScaffold>
  );
}

function ReportRangeScreen({ range, title }: { range: Exclude<ReportPeriod, "all">; title: string }) {
  const { isLoading, profile, reload, shifts } = useAppData();
  const filtered = useMemo(() => filterShiftsByPeriod(shifts, range, new Date(), profile?.week_start ?? 0), [profile?.week_start, range, shifts]);
  const summary = useMemo(() => buildReportSummary(filtered), [filtered]);
  const trends = useMemo(() => buildTrendPoints(filtered, range), [filtered, range]);
  const insights = useMemo(() => buildReportInsights(summary, trends), [summary, trends]);

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={title}>
      <StatsGrid stats={buildStats(filtered)} />
      <ReportSummaryCard summary={summary} title="Period summary" />
      <TrendCard trends={trends} />
      <InsightsCard insights={insights} />
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>CSV export</Text>
        <PrimaryButton label="Share detailed CSV" onPress={() => void shareCsv(filtered, "detailed")} />
        <PrimaryButton label="Share summary CSV" onPress={() => void shareCsv(filtered, "summary")} />
      </View>
      <ShiftList emptyText="No shifts in this period." shifts={filtered} />
    </DataScaffold>
  );
}

function ReportSummaryCard({ summary, title }: { summary: ReturnType<typeof buildReportSummary>; title: string }) {
  return (
    <View style={styles.formCard}>
      <Text style={styles.formTitle}>{title}</Text>
      <InfoRow label="Dates" value={summary.dateRangeLabel} />
      <InfoRow label="Shifts" value={`${summary.completedShifts}/${summary.shiftCount} completed`} />
      <InfoRow label="Net tips" value={money(summary.netTips)} />
      <InfoRow label="Tip %" value={`${summary.averageTipPercentage.toFixed(1)}%`} />
      <InfoRow label="Income/hr" value={summary.hours > 0 ? money(summary.totalIncome / summary.hours) : money(0)} />
    </View>
  );
}

function TrendCard({ trends }: { trends: ReturnType<typeof buildTrendPoints> }) {
  if (trends.length === 0) {
    return null;
  }

  const maxIncome = Math.max(...trends.map((trend) => trend.totalIncome), 1);

  return (
    <View style={styles.formCard}>
      <Text style={styles.formTitle}>Income trend</Text>
      {trends.map((trend) => (
        <View key={trend.label} style={localStyles.trendRow}>
          <Text style={localStyles.trendLabel}>{trend.label}</Text>
          <View style={localStyles.trendTrack}>
            <View style={[localStyles.trendFill, { flex: trend.totalIncome / maxIncome }]} />
            <View style={{ flex: 1 - trend.totalIncome / maxIncome }} />
          </View>
          <Text style={localStyles.trendValue}>{money(trend.totalIncome)}</Text>
        </View>
      ))}
    </View>
  );
}

function InsightsCard({ insights }: { insights: string[] }) {
  return (
    <View style={styles.formCard}>
      <Text style={styles.formTitle}>Insights</Text>
      {insights.map((insight) => (
        <Text key={insight} style={styles.body}>
          {insight}
        </Text>
      ))}
    </View>
  );
}

async function shareCsv(shifts: Parameters<typeof buildCsvExport>[0], format: CsvExportFormat) {
  const csv = buildCsvExport(shifts, format);

  if (shifts.length === 0 && format === "detailed") {
    Alert.alert("Nothing to export", "There are no shifts in this report period.");
    return;
  }

  try {
    await Share.share({ message: csv, title: `ProTip365 ${format} CSV` });
  } catch (error) {
    Alert.alert("Export failed", error instanceof Error ? error.message : "Could not prepare the CSV export.");
  }
}

function money(value: number) {
  return new Intl.NumberFormat(undefined, {
    currency: "USD",
    maximumFractionDigits: 2,
    minimumFractionDigits: 2,
    style: "currency",
  }).format(Number.isFinite(value) ? value : 0);
}

const localStyles = StyleSheet.create({
  trendFill: {
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.sm,
  },
  trendLabel: {
    ...theme.typography.label,
    color: theme.colors.text,
    width: 92,
  },
  trendRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: theme.spacing.sm,
  },
  trendTrack: {
    backgroundColor: theme.colors.surfaceMuted,
    borderRadius: theme.radius.sm,
    flex: 1,
    flexDirection: "row",
    height: 10,
    overflow: "hidden",
  },
  trendValue: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
    minWidth: 74,
    textAlign: "right",
  },
});
