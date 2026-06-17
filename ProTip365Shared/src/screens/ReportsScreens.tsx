import { useMemo } from "react";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { ClipboardList, History, ReceiptText } from "lucide-react-native";
import { ActionList } from "../components/ActionList";
import { ReportsStackParamList } from "../navigation/types";
import { theme } from "../theme";
import { buildStats, DataScaffold, filterRange, ShiftList, StatsGrid, strings, useAppData } from "./shared/screenShared";

export function ReportsScreen({ navigation }: NativeStackScreenProps<ReportsStackParamList, "ReportsHome">) {
  const { isLoading, reload, shifts } = useAppData();
  const stats = useMemo(() => buildStats(shifts), [shifts]);

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.reports}>
      <StatsGrid stats={stats} />
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

function ReportRangeScreen({ range, title }: { range: "week" | "month" | "year"; title: string }) {
  const { isLoading, reload, shifts } = useAppData();
  const filtered = useMemo(() => filterRange(shifts, range), [range, shifts]);

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={title}>
      <StatsGrid stats={buildStats(filtered)} />
      <ShiftList emptyText="No shifts in this period." shifts={filtered} />
    </DataScaffold>
  );
}
