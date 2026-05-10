import { useCallback, useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import { ClipboardList, History, ReceiptText } from "lucide-react-native";
import { ActionList } from "../../components/ActionList";
import { AppScaffold, Card } from "../../components/AppScaffold";
import { ReportPeriodKind, ShiftRecord } from "../../domain";
import { ReportsStackParamList } from "../../navigation/types";
import { loadShiftRecords } from "../../storage/shiftRepository";
import { theme } from "../../theme";
import { buildReportViewModelForPeriod, ReportMetric, ReportViewModel } from "./reportViewModel";

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function useShiftRecords() {
  const [records, setRecords] = useState<ShiftRecord[]>([]);

  useFocusEffect(
    useCallback(() => {
      let active = true;
      loadShiftRecords().then((loadedRecords) => {
        if (active) {
          setRecords(loadedRecords);
        }
      });

      return () => {
        active = false;
      };
    }, []),
  );

  return records;
}

function MetricGrid({ metrics }: { metrics: ReportMetric[] }) {
  return (
    <View style={styles.metricGrid}>
      {metrics.map((metric) => (
        <View key={metric.label} style={styles.metricTile}>
          <Text style={styles.metricLabel}>{metric.label}</Text>
          <Text adjustsFontSizeToFit numberOfLines={1} style={styles.metricValue}>
            {metric.value}
          </Text>
        </View>
      ))}
    </View>
  );
}

function ReportBody({ model }: { model: ReportViewModel }) {
  return (
    <>
      <View style={styles.headerCard}>
        <Text style={styles.period}>{model.subtitle}</Text>
        <MetricGrid metrics={model.primaryMetrics} />
      </View>

      {model.empty ? <Card body="Log or plan a shift to see this report." title="No entries in this period" /> : null}

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Details</Text>
        <MetricGrid metrics={model.secondaryMetrics} />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Targets</Text>
        <MetricGrid metrics={model.progressMetrics} />
      </View>
    </>
  );
}

function PeriodReportScreen({ kind }: { kind: ReportPeriodKind }) {
  const records = useShiftRecords();
  const model = buildReportViewModelForPeriod({
    anchorDate: todayISO(),
    kind,
    records,
  });

  return (
    <AppScaffold title={model.title}>
      <ReportBody model={model} />
    </AppScaffold>
  );
}

export function ReportsScreen({ navigation }: NativeStackScreenProps<ReportsStackParamList, "ReportsHome">) {
  const records = useShiftRecords();
  const today = buildReportViewModelForPeriod({
    anchorDate: todayISO(),
    kind: "today",
    records,
  });
  const week = buildReportViewModelForPeriod({
    anchorDate: todayISO(),
    kind: "week",
    records,
  });

  return (
    <AppScaffold eyebrow="Current period" title="Reports">
      <ReportBody model={today} />

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>This week</Text>
        <MetricGrid metrics={week.primaryMetrics} />
      </View>

      <ActionList
        items={[
          {
            icon: <ClipboardList color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: "Weekly report",
            onPress: () => navigation.navigate("WeeklyReport"),
          },
          {
            icon: <ReceiptText color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: "Monthly report",
            onPress: () => navigation.navigate("MonthlyReport"),
          },
          {
            icon: <ReceiptText color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: "Yearly report",
            onPress: () => navigation.navigate("YearlyReport"),
          },
          {
            icon: <History color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: "History",
            onPress: () => navigation.navigate("History"),
          },
        ]}
      />
    </AppScaffold>
  );
}

export function WeeklyReportScreen() {
  return <PeriodReportScreen kind="week" />;
}

export function MonthlyReportScreen() {
  return <PeriodReportScreen kind="month" />;
}

export function YearlyReportScreen() {
  return <PeriodReportScreen kind="year" />;
}

export function HistoryScreen() {
  const records = useShiftRecords();
  const sortedRecords = [...records].sort((first, second) => `${second.plannedShift.shiftDate} ${second.plannedShift.startTime}`.localeCompare(`${first.plannedShift.shiftDate} ${first.plannedShift.startTime}`));

  return (
    <AppScaffold title="History">
      {sortedRecords.length === 0 ? (
        <Card body="Saved shifts will appear here after you log or plan them." title="No history yet" />
      ) : (
        <View style={styles.list}>
          {sortedRecords.map((record) => (
            <View key={record.plannedShift.id} style={styles.historyRow}>
              <Text style={styles.historyTitle}>{record.plannedShift.shiftDate}</Text>
              <Text style={styles.historyBody}>
                {record.plannedShift.startTime} - {record.plannedShift.endTime} | {record.plannedShift.status}
              </Text>
            </View>
          ))}
        </View>
      )}
    </AppScaffold>
  );
}

const styles = StyleSheet.create({
  headerCard: {
    ...theme.cards,
    gap: theme.spacing.lg,
  },
  historyBody: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  historyRow: {
    ...theme.cards,
    gap: theme.spacing.xs,
  },
  historyTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  list: {
    gap: theme.spacing.md,
  },
  metricGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: theme.spacing.md,
  },
  metricLabel: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
  },
  metricTile: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    flexBasis: "46%",
    flexGrow: 1,
    gap: theme.spacing.xs,
    minHeight: 78,
    padding: theme.spacing.md,
  },
  metricValue: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  period: {
    ...theme.typography.label,
    color: theme.colors.primary,
  },
  section: {
    gap: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
});
