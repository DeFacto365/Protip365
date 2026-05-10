import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { CalendarDays, CircleDollarSign, Plus } from "lucide-react-native";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { ActionList } from "../components/ActionList";
import { AppScaffold, Card } from "../components/AppScaffold";
import { setOnboardingComplete } from "../features/onboarding/onboardingState";
import { getStrings } from "../localization";
import { AddStackParamList, RootStackParamList } from "../navigation/types";
import { theme } from "../theme";
import { SubscriptionStatusCard } from "../features/entitlements/EntitlementScreens";
import { SettingsComplianceSection } from "../features/account/SettingsComplianceScreen";

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
      <SettingsComplianceSection />
    </AppScaffold>
  );
}

export function OnboardingScreen({ navigation, onComplete }: NativeStackScreenProps<RootStackParamList, "Onboarding"> & { onComplete?: () => void }) {
  async function finishOnboarding(target: "log" | "plan") {
    await setOnboardingComplete();
    onComplete?.();
    navigation.replace("MainTabs");
  }

  return (
    <AppScaffold eyebrow="Setup" title="Make shift logging faster">
      <View style={onboardingStyles.card}>
        <Text style={onboardingStyles.title}>Work defaults</Text>
        <Text style={onboardingStyles.body}>ProTip365 starts with your device currency and language. Add your default hourly rate, employer, and tip-out later from Settings.</Text>
      </View>
      <View style={onboardingStyles.card}>
        <Text style={onboardingStyles.title}>First useful action</Text>
        <Text style={onboardingStyles.body}>Start by logging the shift you just worked. Reports and history build from there.</Text>
      </View>
      <Pressable accessibilityRole="button" onPress={() => finishOnboarding("log")} style={onboardingStyles.primaryButton}>
        <Text style={onboardingStyles.primaryButtonText}>Log first shift</Text>
      </Pressable>
      <Pressable accessibilityRole="button" onPress={() => finishOnboarding("plan")} style={onboardingStyles.secondaryButton}>
        <Text style={onboardingStyles.secondaryButtonText}>Plan a shift instead</Text>
      </Pressable>
    </AppScaffold>
  );
}

const onboardingStyles = StyleSheet.create({
  body: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  card: {
    ...theme.cards,
    gap: theme.spacing.sm,
  },
  primaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.md,
    justifyContent: "center",
    minHeight: 52,
    paddingHorizontal: theme.spacing.lg,
  },
  primaryButtonText: {
    ...theme.typography.label,
    color: "#FFFFFF",
    fontSize: 16,
  },
  secondaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 48,
    paddingHorizontal: theme.spacing.lg,
  },
  secondaryButtonText: {
    ...theme.typography.label,
    color: theme.colors.text,
  },
  title: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
});
