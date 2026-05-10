import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { CalendarDays, CircleDollarSign, ClipboardList, History, Plus, ReceiptText } from "lucide-react-native";
import { ActionList } from "../components/ActionList";
import { AppScaffold, Card } from "../components/AppScaffold";
import { getStrings } from "../localization";
import { AddStackParamList, CalendarStackParamList, ReportsStackParamList } from "../navigation/types";
import { theme } from "../theme";

const strings = getStrings();

export function CalendarScreen({ navigation }: NativeStackScreenProps<CalendarStackParamList, "CalendarHome">) {
  return (
    <AppScaffold title={strings.screens.calendar}>
      <Card body={strings.placeholders.calendar} title={strings.screens.calendar} />
      <ActionList
        items={[
          {
            icon: <CalendarDays color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.addShift,
            onPress: () => navigation.navigate("AddShift"),
          },
        ]}
      />
    </AppScaffold>
  );
}

export function AddHomeScreen({ navigation }: NativeStackScreenProps<AddStackParamList, "AddHome">) {
  return (
    <AppScaffold title={strings.screens.add}>
      <Card body={strings.placeholders.add} title={strings.screens.add} />
      <ActionList
        items={[
          {
            icon: <Plus color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.addShift,
            onPress: () => navigation.navigate("AddShift"),
          },
          {
            icon: <CircleDollarSign color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.addIncome,
            onPress: () => navigation.navigate("AddIncome"),
          },
        ]}
      />
    </AppScaffold>
  );
}

export function AddIncomeScreen() {
  return (
    <AppScaffold title={strings.screens.addIncome}>
      <Card body={strings.placeholders.addIncome} title={strings.screens.addIncome} />
    </AppScaffold>
  );
}

export function ReportsScreen({ navigation }: NativeStackScreenProps<ReportsStackParamList, "ReportsHome">) {
  return (
    <AppScaffold title={strings.screens.reports}>
      <Card body={strings.placeholders.reports} title={strings.screens.reports} />
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
    </AppScaffold>
  );
}

export function WeeklyReportScreen() {
  return (
    <AppScaffold title={strings.screens.weeklyReport}>
      <Card body={strings.placeholders.reports} title={strings.screens.weeklyReport} />
    </AppScaffold>
  );
}

export function MonthlyReportScreen() {
  return (
    <AppScaffold title={strings.screens.monthlyReport}>
      <Card body={strings.placeholders.reports} title={strings.screens.monthlyReport} />
    </AppScaffold>
  );
}

export function YearlyReportScreen() {
  return (
    <AppScaffold title={strings.screens.yearlyReport}>
      <Card body={strings.placeholders.reports} title={strings.screens.yearlyReport} />
    </AppScaffold>
  );
}

export function HistoryScreen() {
  return (
    <AppScaffold title={strings.screens.history}>
      <Card body={strings.placeholders.history} title={strings.screens.history} />
    </AppScaffold>
  );
}

export function SettingsScreen() {
  return (
    <AppScaffold title={strings.screens.settings}>
      <Card body={strings.placeholders.settings} title={strings.screens.settings} />
    </AppScaffold>
  );
}

export function OnboardingScreen() {
  return (
    <AppScaffold title={strings.screens.onboarding}>
      <Card body={strings.placeholders.onboarding} title={strings.screens.onboarding} />
    </AppScaffold>
  );
}

export function PaywallScreen() {
  return (
    <AppScaffold title={strings.screens.paywall}>
      <Card body={strings.placeholders.paywall} title={strings.screens.paywall} />
    </AppScaffold>
  );
}
