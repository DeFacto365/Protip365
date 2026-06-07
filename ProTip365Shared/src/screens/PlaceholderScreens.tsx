import { useState } from "react";
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { CalendarDays, CircleDollarSign, ClipboardList, History, Plus, ReceiptText } from "lucide-react-native";
import { ActionList } from "../components/ActionList";
import { AppScaffold, Card } from "../components/AppScaffold";
import { supabaseSecureStorage } from "../lib/secureStorage";
import { getStrings } from "../localization";
import { AddStackParamList, CalendarStackParamList, ReportsStackParamList, TodayStackParamList } from "../navigation/types";
import { theme } from "../theme";

const strings = getStrings();
const SHIFT_DRAFTS_KEY = "protip365.shiftDrafts";

type ShiftDraft = {
  id: string;
  date: string;
  startTime: string;
  endTime: string;
  employer: string;
  sales: string;
  tips: string;
  tipOut: string;
  notes: string;
};

function todayInputValue() {
  const today = new Date();
  const month = `${today.getMonth() + 1}`.padStart(2, "0");
  const day = `${today.getDate()}`.padStart(2, "0");

  return `${today.getFullYear()}-${month}-${day}`;
}

async function saveShiftDraft(shift: ShiftDraft) {
  const storedValue = await supabaseSecureStorage.getItem(SHIFT_DRAFTS_KEY);
  const storedDrafts = storedValue ? (JSON.parse(storedValue) as ShiftDraft[]) : [];

  await supabaseSecureStorage.setItem(SHIFT_DRAFTS_KEY, JSON.stringify([shift, ...storedDrafts].slice(0, 25)));
}

export function TodayScreen({ navigation }: NativeStackScreenProps<TodayStackParamList, "TodayHome">) {
  return (
    <AppScaffold eyebrow={strings.foundationSubtitle} title={strings.screens.today}>
      <Card body={strings.placeholders.today} title={strings.appName} />
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

export function AddShiftScreen() {
  const [date, setDate] = useState(todayInputValue);
  const [startTime, setStartTime] = useState("");
  const [endTime, setEndTime] = useState("");
  const [employer, setEmployer] = useState("");
  const [sales, setSales] = useState("");
  const [tips, setTips] = useState("");
  const [tipOut, setTipOut] = useState("");
  const [notes, setNotes] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [saveMessage, setSaveMessage] = useState("");

  async function handleSave() {
    if (!date.trim()) {
      Alert.alert("Missing date", "Enter the shift date before saving.");
      return;
    }

    setIsSaving(true);

    try {
      await saveShiftDraft({
        date: date.trim(),
        employer: employer.trim(),
        endTime: endTime.trim(),
        id: `${Date.now()}`,
        notes: notes.trim(),
        sales: sales.trim(),
        startTime: startTime.trim(),
        tipOut: tipOut.trim(),
        tips: tips.trim(),
      });
      setSaveMessage("Saved on this device.");
      setStartTime("");
      setEndTime("");
      setEmployer("");
      setSales("");
      setTips("");
      setTipOut("");
      setNotes("");
    } catch {
      setSaveMessage("");
      Alert.alert("Save failed", "The shift could not be saved. Try again.");
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <AppScaffold title={strings.screens.addShift}>
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>Shift details</Text>
        <FormInput label="Date" onChangeText={setDate} placeholder="YYYY-MM-DD" value={date} />
        <View style={styles.row}>
          <FormInput label="Start" onChangeText={setStartTime} placeholder="5:00 PM" value={startTime} />
          <FormInput label="End" onChangeText={setEndTime} placeholder="11:30 PM" value={endTime} />
        </View>
        <FormInput label="Employer" onChangeText={setEmployer} placeholder="Restaurant or venue" value={employer} />
        <View style={styles.row}>
          <FormInput
            keyboardType="decimal-pad"
            label="Sales"
            onChangeText={setSales}
            placeholder="0.00"
            value={sales}
          />
          <FormInput
            keyboardType="decimal-pad"
            label="Tips"
            onChangeText={setTips}
            placeholder="0.00"
            value={tips}
          />
        </View>
        <FormInput
          keyboardType="decimal-pad"
          label="Tip-out"
          onChangeText={setTipOut}
          placeholder="0.00"
          value={tipOut}
        />
        <FormInput
          label="Notes"
          multiline
          onChangeText={setNotes}
          placeholder="Optional shift notes"
          value={notes}
        />
        <Pressable
          accessibilityLabel="Save shift"
          accessibilityRole="button"
          disabled={isSaving}
          onPress={handleSave}
          style={({ pressed }) => [styles.primaryButton, pressed && styles.primaryButtonPressed, isSaving && styles.disabledButton]}
        >
          <Text style={styles.primaryButtonText}>{isSaving ? "Saving..." : "Save shift"}</Text>
        </Pressable>
        {saveMessage ? (
          <Text accessibilityRole="alert" style={styles.successText}>
            {saveMessage}
          </Text>
        ) : null}
      </View>
    </AppScaffold>
  );
}

type FormInputProps = {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  placeholder: string;
  keyboardType?: "default" | "decimal-pad";
  multiline?: boolean;
};

function FormInput({ keyboardType = "default", label, multiline = false, onChangeText, placeholder, value }: FormInputProps) {
  return (
    <View style={styles.inputGroup}>
      <Text style={styles.inputLabel}>{label}</Text>
      <TextInput
        accessibilityLabel={label}
        keyboardType={keyboardType}
        multiline={multiline}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={theme.colors.textMuted}
        style={[styles.input, multiline && styles.multilineInput]}
        value={value}
      />
    </View>
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

const styles = StyleSheet.create({
  disabledButton: {
    opacity: 0.65,
  },
  formCard: {
    ...theme.cards,
    gap: theme.spacing.md,
  },
  formTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.forms.borderColor,
    borderRadius: theme.forms.borderRadius,
    borderWidth: 1,
    color: theme.colors.text,
    fontSize: theme.typography.body.fontSize,
    minHeight: theme.forms.inputHeight,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  inputGroup: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  inputLabel: {
    ...theme.typography.label,
    color: theme.forms.labelColor,
  },
  multilineInput: {
    minHeight: 92,
    textAlignVertical: "top",
  },
  primaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.md,
    minHeight: 52,
    justifyContent: "center",
    paddingHorizontal: theme.spacing.lg,
  },
  primaryButtonPressed: {
    opacity: 0.85,
  },
  primaryButtonText: {
    ...theme.typography.body,
    color: theme.colors.surface,
    fontWeight: "800",
  },
  row: {
    flexDirection: "row",
    gap: theme.spacing.md,
  },
  successText: {
    ...theme.typography.label,
    color: theme.colors.success,
    textAlign: "center",
  },
});
