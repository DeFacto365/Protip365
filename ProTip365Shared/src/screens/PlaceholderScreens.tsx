import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { CalendarDays, CircleDollarSign, Plus } from "lucide-react-native";
import { ActionList } from "../components/ActionList";
import { AppScaffold, Card } from "../components/AppScaffold";
import { getStrings } from "../localization";
import { AddStackParamList } from "../navigation/types";
import { theme } from "../theme";
import { SubscriptionStatusCard } from "../features/entitlements/EntitlementScreens";

const strings = getStrings();

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
            icon: <CalendarDays color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: "Add planned shift",
            onPress: () => navigation.navigate("AddPlannedShift"),
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

export function SettingsScreen() {
  return (
    <AppScaffold title={strings.screens.settings}>
      <SubscriptionStatusCard />
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
