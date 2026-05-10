import { useCallback, useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import { ChevronLeft, ChevronRight, ClipboardList, History, Pencil, ReceiptText } from "lucide-react-native";
import { ActionList } from "../../components/ActionList";
import { AppScaffold, Card } from "../../components/AppScaffold";
import { ReportPeriodKind, ShiftRecord } from "../../domain";
import { ReportsStackParamList } from "../../navigation/types";
import { loadShiftRecords } from "../../storage/shiftRepository";
import { theme } from "../../theme";
import { buildReportViewModelForPeriod, ReportMetric, ReportViewModel } from "./reportViewModel";
import { buildHistoryItems, ShiftListItem } from "../history/historyViewModel";

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function shiftAnchorDate(anchorDate: string, kind: ReportPeriodKind, direction: -1 | 1) {
  const date = new Date(`${anchorDate}T00:00:00.000Z`);
  if (kind === "week") {
    date.setUTCDate(date.getUTCDate() + direction * 7);
  } else if (kind === "month") {
    date.setUTCMonth(date.getUTCMonth() + direction);
  } else if (kind === "year") {
    date.setUTCFullYear(date.getUTCFullYear() + direction);
  } else {
    date.setUTCDate(date.getUTCDate() + direction);
  }
  return date.toISOString().slice(0, 10);
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
        {model.empty ? (
          <Text style={styles.historyBody}>No entries in this period. Add a shift or change period to review income here.</Text>
        ) : (
          <MetricGrid metrics={model.primaryMetrics} />
        )}
      </View>

      <View style={styles.insightCard}>
        <Text style={styles.sectionTitle}>Insight</Text>
        <Text style={styles.historyBody}>{model.insight}</Text>
      </View>

      {!model.empty ? (
        <>
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Details</Text>
            <MetricGrid metrics={model.secondaryMetrics} />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Targets</Text>
            <MetricGrid metrics={model.progressMetrics} />
          </View>
        </>
      ) : null}
    </>
  );
}

function PeriodReportScreen({ kind }: { kind: ReportPeriodKind }) {
  const records = useShiftRecords();
  const [anchorDate, setAnchorDate] = useState(todayISO());
  const model = buildReportViewModelForPeriod({
    anchorDate,
    kind,
    records,
  });

  return (
    <AppScaffold title={model.title}>
      <View style={styles.periodControls}>
        <Pressable accessibilityRole="button" onPress={() => setAnchorDate((current) => shiftAnchorDate(current, kind, -1))} style={styles.periodButton}>
          <ChevronLeft color={theme.colors.primary} size={20} />
          <Text style={styles.periodButtonText}>Previous</Text>
        </Pressable>
        <Text style={styles.periodControlLabel}>{model.subtitle}</Text>
        <Pressable accessibilityRole="button" onPress={() => setAnchorDate((current) => shiftAnchorDate(current, kind, 1))} style={styles.periodButton}>
          <Text style={styles.periodButtonText}>Next</Text>
          <ChevronRight color={theme.colors.primary} size={20} />
        </Pressable>
      </View>
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

export function HistoryScreen({ navigation }: NativeStackScreenProps<ReportsStackParamList, "History">) {
  const records = useShiftRecords();
  const historyItems = buildHistoryItems(records);

  function openHistoryItem(item: ShiftListItem) {
    if (item.editTarget === "dailyEntry") {
      navigation.navigate("AddShift", { shiftId: item.id });
    } else {
      navigation.navigate("AddPlannedShift", { shiftId: item.id });
    }
  }

  return (
    <AppScaffold title="History">
      {historyItems.length === 0 ? (
        <Card body="Saved shifts will appear here after you log or plan them." title="No history yet" />
      ) : (
        <View style={styles.list}>
          {historyItems.map((item) => (
            <Pressable accessibilityRole="button" key={item.id} onPress={() => openHistoryItem(item)} style={styles.historyRow}>
              <View style={styles.historyHeader}>
                <View style={styles.historyTitleBlock}>
                  <Text style={styles.historyTitle}>{item.date}</Text>
                  <Text style={styles.historyBody}>{item.time}</Text>
                </View>
                <View style={styles.historyActions}>
                  <Text style={[styles.statusChip, styles[`status_${item.status}`]]}>{item.statusLabel}</Text>
                  <Pencil color={theme.colors.primary} size={18} />
                </View>
              </View>
              <Text style={styles.historyBody}>{item.subtitle}</Text>
            </Pressable>
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
  historyActions: {
    alignItems: "center",
    flexDirection: "row",
    gap: theme.spacing.sm,
  },
  historyBody: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  historyHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    gap: theme.spacing.md,
  },
  historyRow: {
    ...theme.cards,
    gap: theme.spacing.xs,
  },
  historyTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  historyTitleBlock: {
    flex: 1,
  },
  insightCard: {
    ...theme.cards,
    backgroundColor: theme.colors.primaryMuted,
    gap: theme.spacing.sm,
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
  periodButton: {
    alignItems: "center",
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    flexDirection: "row",
    gap: theme.spacing.xs,
    minHeight: 44,
    paddingHorizontal: theme.spacing.md,
  },
  periodButtonText: {
    ...theme.typography.label,
    color: theme.colors.primary,
  },
  periodControlLabel: {
    ...theme.typography.label,
    color: theme.colors.text,
    flex: 1,
    textAlign: "center",
  },
  periodControls: {
    alignItems: "center",
    flexDirection: "row",
    gap: theme.spacing.sm,
  },
  section: {
    gap: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  status_completed: {
    backgroundColor: "#E7F8F0",
    color: theme.colors.success,
  },
  status_did_not_work: {
    backgroundColor: theme.colors.surfaceMuted,
    color: theme.colors.textMuted,
  },
  status_missed: {
    backgroundColor: "#FEECEC",
    color: theme.colors.danger,
  },
  status_planned: {
    backgroundColor: theme.colors.primaryMuted,
    color: theme.colors.primary,
  },
  statusChip: {
    ...theme.typography.label,
    borderRadius: theme.radius.sm,
    overflow: "hidden",
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
  },
});
