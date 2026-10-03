import { useEffect, useMemo, useState } from "react";
import { Alert, Modal, Pressable, RefreshControl, ScrollView, StyleSheet, Switch, Text, TextInput, View } from "react-native";
import DateTimePicker, { DateTimePickerEvent } from "@react-native-community/datetimepicker";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { CalendarDays, CircleDollarSign, ClipboardList, History, Plus, ReceiptText } from "lucide-react-native";
import { useAuth } from "../auth/AuthProvider";
import { ActionList } from "../components/ActionList";
import { AppScaffold, Card } from "../components/AppScaffold";
import {
  addEmployer,
  createShift,
  deleteEmployer,
  Employer,
  formatCurrency,
  getProfile,
  hoursBetween,
  listEmployers,
  listShiftIncome,
  parseMoney,
  saveIncome,
  saveProfile,
  ShiftIncome,
  toDateValue,
  toTimeValue,
  UserProfile,
} from "../lib/protipData";
import { getSupabaseClient } from "../lib/supabase";
import { getStrings } from "../localization";
import { AddStackParamList, CalendarStackParamList, ReportsStackParamList, TodayStackParamList } from "../navigation/types";
import { theme } from "../theme";

const strings = getStrings();

function todayValue() {
  return toDateValue(new Date());
}

function timeFromString(value: string) {
  const date = new Date();
  const [hours, minutes] = value.split(":").map(Number);

  if (Number.isFinite(hours)) {
    date.setHours(hours, Number.isFinite(minutes) ? minutes : 0, 0, 0);
  }

  return date;
}

function sum(values: number[]) {
  return values.reduce((total, value) => total + (Number.isFinite(value) ? value : 0), 0);
}

function shiftId(shift: ShiftIncome) {
  return shift.shift_id ?? shift.id ?? "";
}

function visibleShiftLabel(shift: ShiftIncome) {
  const employer = shift.employer_name ? ` - ${shift.employer_name}` : "";
  const time = shift.start_time && shift.end_time ? `, ${shift.start_time}-${shift.end_time}` : "";

  return `${shift.shift_date}${time}${employer}`;
}

function useAppData() {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [employers, setEmployers] = useState<Employer[]>([]);
  const [shifts, setShifts] = useState<ShiftIncome[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  async function reload() {
    setIsLoading(true);

    try {
      const [nextProfile, nextEmployers, nextShifts] = await Promise.all([getProfile(), listEmployers(), listShiftIncome()]);
      setProfile(nextProfile);
      setEmployers(nextEmployers);
      setShifts(nextShifts);
    } catch (error) {
      Alert.alert("Load failed", error instanceof Error ? error.message : "Could not load ProTip365 data.");
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    void reload();
  }, []);

  return { employers, isLoading, profile, reload, setProfile, shifts };
}

export function TodayScreen({ navigation }: NativeStackScreenProps<TodayStackParamList, "TodayHome">) {
  const { isLoading, reload, shifts } = useAppData();
  const todayShifts = shifts.filter((shift) => shift.shift_date === todayValue());
  const stats = useMemo(() => buildStats(todayShifts), [todayShifts]);

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.today}>
      <StatsGrid stats={stats} />
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
      <ShiftList emptyText="No shifts for today." shifts={todayShifts} />
    </DataScaffold>
  );
}

export function CalendarScreen({ navigation }: NativeStackScreenProps<CalendarStackParamList, "CalendarHome">) {
  const { isLoading, reload, shifts } = useAppData();

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.calendar}>
      <ActionList
        items={[
          {
            icon: <CalendarDays color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.addShift,
            onPress: () => navigation.navigate("AddShift"),
          },
        ]}
      />
      <ShiftList emptyText="No shifts yet." shifts={shifts} />
    </DataScaffold>
  );
}

export function AddHomeScreen({ navigation }: NativeStackScreenProps<AddStackParamList, "AddHome">) {
  return (
    <AppScaffold title={strings.screens.add}>
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

export function AddShiftScreen({ navigation }: NativeStackScreenProps<AddStackParamList, "AddShift">) {
  const { employers, isLoading, profile, reload } = useAppData();
  const [shiftDate, setShiftDate] = useState(new Date());
  const [startTime, setStartTime] = useState(timeFromString("17:00"));
  const [endTime, setEndTime] = useState(timeFromString("23:30"));
  const [selectedEmployerId, setSelectedEmployerId] = useState<string | null>(null);
  const [notes, setNotes] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [picker, setPicker] = useState<"date" | "start" | "end" | null>(null);
  const [showEmployerPicker, setShowEmployerPicker] = useState(false);
  const startValue = toTimeValue(startTime);
  const endValue = toTimeValue(endTime);
  const selectedEmployer = employers.find((employer) => employer.id === selectedEmployerId);
  const hourlyRate = selectedEmployer?.hourly_rate ?? profile?.default_hourly_rate ?? 15;
  const expectedHours = hoursBetween(startValue, endValue);

  async function handleSave() {
    setIsSaving(true);

    try {
      await createShift({
        employerId: selectedEmployerId,
        endTime: endValue,
        expectedHours,
        hourlyRate,
        notes,
        shiftDate: toDateValue(shiftDate),
        startTime: startValue,
      });
      Alert.alert("Shift saved", "The shift is ready for income entry.");
      setNotes("");
      await reload();
      navigation.goBack();
    } catch (error) {
      Alert.alert("Save failed", error instanceof Error ? error.message : "Could not save shift.");
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.addShift}>
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>Shift details</Text>
        <PickerRow label="Date" onPress={() => setPicker("date")} value={toDateValue(shiftDate)} />
        <View style={styles.row}>
          <PickerRow label="Start" onPress={() => setPicker("start")} value={startValue} />
          <PickerRow label="End" onPress={() => setPicker("end")} value={endValue} />
        </View>
        <PickerRow
          label="Employer"
          onPress={() => setShowEmployerPicker(true)}
          value={selectedEmployer?.name ?? "No employer"}
        />
        <InfoRow label="Expected hours" value={expectedHours.toFixed(2)} />
        <InfoRow label="Hourly rate" value={formatCurrency(hourlyRate)} />
        <FormInput label="Notes" multiline onChangeText={setNotes} placeholder="Optional notes" value={notes} />
        <PrimaryButton isLoading={isSaving} label="Save shift" onPress={handleSave} />
      </View>
      <DatePickerModal endTime={endTime} picker={picker} setEndTime={setEndTime} setPicker={setPicker} setShiftDate={setShiftDate} setStartTime={setStartTime} shiftDate={shiftDate} startTime={startTime} />
      <EmployerModal employers={employers} onClose={() => setShowEmployerPicker(false)} onSelect={setSelectedEmployerId} selectedId={selectedEmployerId} visible={showEmployerPicker} />
    </DataScaffold>
  );
}

export function AddIncomeScreen({ navigation }: NativeStackScreenProps<AddStackParamList, "AddIncome">) {
  const { isLoading, reload, shifts } = useAppData();
  const [selectedShiftId, setSelectedShiftId] = useState<string | null>(null);
  const [showShiftPicker, setShowShiftPicker] = useState(false);
  const [sales, setSales] = useState("");
  const [tips, setTips] = useState("");
  const [cashOut, setCashOut] = useState("");
  const [notes, setNotes] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const selectedShift = shifts.find((shift) => shiftId(shift) === selectedShiftId);
  const availableShifts = shifts.filter((shift) => shiftId(shift));

  async function handleSave() {
    if (!selectedShift) {
      Alert.alert("Select a shift", "Income must be attached to a shift.");
      return;
    }

    setIsSaving(true);

    try {
      await saveIncome({
        actualEndTime: selectedShift.end_time ?? "",
        actualHours: selectedShift.expected_hours ?? selectedShift.hours ?? 0,
        actualStartTime: selectedShift.start_time ?? "",
        cashOut: parseMoney(cashOut),
        incomeId: selectedShift.income_id,
        notes,
        sales: parseMoney(sales),
        shiftId: shiftId(selectedShift),
        tips: parseMoney(tips),
      });
      Alert.alert("Income saved", "Income was attached to the selected shift.");
      setSales("");
      setTips("");
      setCashOut("");
      setNotes("");
      await reload();
    } catch (error) {
      Alert.alert("Save failed", error instanceof Error ? error.message : "Could not save income.");
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.addIncome}>
      {availableShifts.length === 0 ? (
        <View style={styles.formCard}>
          <Text style={styles.formTitle}>Create a shift first</Text>
          <Text style={styles.body}>Income must belong to a shift. Create the shift, then add income against it.</Text>
          <PrimaryButton label="Create shift" onPress={() => navigation.navigate("AddShift")} />
        </View>
      ) : (
        <View style={styles.formCard}>
          <Text style={styles.formTitle}>Income details</Text>
          <PickerRow label="Shift" onPress={() => setShowShiftPicker(true)} value={selectedShift ? visibleShiftLabel(selectedShift) : "Select shift"} />
          <View style={styles.row}>
            <FormInput keyboardType="decimal-pad" label="Sales" onChangeText={setSales} placeholder="0.00" value={sales} />
            <FormInput keyboardType="decimal-pad" label="Tips" onChangeText={setTips} placeholder="0.00" value={tips} />
          </View>
          <FormInput keyboardType="decimal-pad" label="Tip-out" onChangeText={setCashOut} placeholder="0.00" value={cashOut} />
          <FormInput label="Notes" multiline onChangeText={setNotes} placeholder="Optional income notes" value={notes} />
          <PrimaryButton isLoading={isSaving} label="Save income" onPress={handleSave} />
        </View>
      )}
      <ShiftPickerModal onClose={() => setShowShiftPicker(false)} onSelect={setSelectedShiftId} selectedId={selectedShiftId} shifts={availableShifts} visible={showShiftPicker} />
    </DataScaffold>
  );
}

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

export function SettingsScreen() {
  const { session } = useAuth();
  const { employers, isLoading, profile, reload, setProfile } = useAppData();
  const [newEmployerName, setNewEmployerName] = useState("");
  const [newEmployerRate, setNewEmployerRate] = useState("");
  const [isSaving, setIsSaving] = useState(false);

  async function handleProfileSave() {
    if (!profile) {
      return;
    }

    setIsSaving(true);

    try {
      await saveProfile(profile);
      Alert.alert("Settings saved", "Your settings were updated.");
      await reload();
    } catch (error) {
      Alert.alert("Save failed", error instanceof Error ? error.message : "Could not save settings.");
    } finally {
      setIsSaving(false);
    }
  }

  async function handleAddEmployer() {
    if (!newEmployerName.trim()) {
      Alert.alert("Employer name required", "Enter an employer name.");
      return;
    }

    try {
      await addEmployer(newEmployerName.trim(), parseMoney(newEmployerRate) || profile?.default_hourly_rate || 15);
      setNewEmployerName("");
      setNewEmployerRate("");
      await reload();
    } catch (error) {
      Alert.alert("Employer failed", error instanceof Error ? error.message : "Could not add employer.");
    }
  }

  async function signOut() {
    await getSupabaseClient()?.auth.signOut();
  }

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.settings}>
      {profile ? (
        <View style={styles.formCard}>
          <Text style={styles.formTitle}>Profile</Text>
          <Text style={styles.body}>{session?.user.email}</Text>
          <FormInput label="Name" onChangeText={(value) => setProfile({ ...profile, name: value })} placeholder="Your name" value={profile.name ?? ""} />
          <FormInput keyboardType="decimal-pad" label="Default hourly rate" onChangeText={(value) => setProfile({ ...profile, default_hourly_rate: parseMoney(value) })} placeholder="15.00" value={`${profile.default_hourly_rate}`} />
          <View style={styles.switchRow}>
            <Text style={styles.label}>Use multiple employers</Text>
            <Switch onValueChange={(value) => setProfile({ ...profile, use_multiple_employers: value })} value={profile.use_multiple_employers} />
          </View>
          <PrimaryButton isLoading={isSaving} label="Save settings" onPress={handleProfileSave} />
        </View>
      ) : null}
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>Employers</Text>
        <FormInput label="Employer name" onChangeText={setNewEmployerName} placeholder="Restaurant or venue" value={newEmployerName} />
        <FormInput keyboardType="decimal-pad" label="Hourly rate" onChangeText={setNewEmployerRate} placeholder="15.00" value={newEmployerRate} />
        <PrimaryButton label="Add employer" onPress={handleAddEmployer} />
        {employers.map((employer) => (
          <View key={employer.id} style={styles.listRow}>
            <View>
              <Text style={styles.listTitle}>{employer.name}</Text>
              <Text style={styles.body}>{formatCurrency(employer.hourly_rate)}/hr</Text>
            </View>
            <Pressable accessibilityRole="button" onPress={() => void deleteEmployer(employer.id).then(reload)}>
              <Text style={styles.dangerText}>Delete</Text>
            </Pressable>
          </View>
        ))}
      </View>
      <Pressable accessibilityRole="button" onPress={signOut} style={styles.signOutButton}>
        <Text style={styles.dangerText}>Sign out</Text>
      </Pressable>
    </DataScaffold>
  );
}

export function OnboardingScreen() {
  return (
    <AppScaffold title={strings.screens.onboarding}>
      <Card body="Create employers, add shifts, then record income against those shifts." title="Welcome" />
    </AppScaffold>
  );
}

export function PaywallScreen() {
  return (
    <AppScaffold title={strings.screens.paywall}>
      <Card body="Subscription controls will be restored after the core waiter workflow is complete." title={strings.screens.paywall} />
    </AppScaffold>
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

function DataScaffold({ children, isLoading, onRefresh, title }: { children: React.ReactNode; isLoading: boolean; onRefresh: () => Promise<void>; title: string }) {
  return (
    <ScrollView
      contentContainerStyle={styles.screen}
      refreshControl={<RefreshControl onRefresh={onRefresh} refreshing={isLoading} />}
      showsVerticalScrollIndicator={false}
      style={styles.scroll}
    >
      <Text accessibilityRole="header" style={styles.screenTitle}>
        {title}
      </Text>
      {children}
    </ScrollView>
  );
}

function buildStats(shifts: ShiftIncome[]) {
  const hours = sum(shifts.map((shift) => shift.hours || shift.expected_hours || 0));
  const sales = sum(shifts.map((shift) => shift.sales));
  const tips = sum(shifts.map((shift) => shift.tips));
  const tipOut = sum(shifts.map((shift) => shift.cash_out));
  const salary = sum(shifts.map((shift) => shift.base_income));
  const total = sum(shifts.map((shift) => shift.total_income));

  return {
    hours,
    salary,
    sales,
    tipOut,
    tipPercentage: sales > 0 ? (tips / sales) * 100 : 0,
    tips,
    total,
  };
}

function StatsGrid({ stats }: { stats: ReturnType<typeof buildStats> }) {
  return (
    <View style={styles.statsGrid}>
      <StatCard label="Total income" value={formatCurrency(stats.total)} />
      <StatCard label="Tips" value={formatCurrency(stats.tips)} />
      <StatCard label="Sales" value={formatCurrency(stats.sales)} />
      <StatCard label="Hours" value={stats.hours.toFixed(2)} />
      <StatCard label="Base pay" value={formatCurrency(stats.salary)} />
      <StatCard label="Tip %" value={`${stats.tipPercentage.toFixed(1)}%`} />
    </View>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.statCard}>
      <Text style={styles.statLabel}>{label}</Text>
      <Text style={styles.statValue}>{value}</Text>
    </View>
  );
}

function ShiftList({ emptyText, shifts }: { emptyText: string; shifts: ShiftIncome[] }) {
  if (shifts.length === 0) {
    return <Card body={emptyText} title="Shifts" />;
  }

  return (
    <View style={styles.formCard}>
      <Text style={styles.formTitle}>Shifts</Text>
      {shifts.map((shift) => (
        <View key={shiftId(shift)} style={styles.listRow}>
          <View style={styles.flex}>
            <Text style={styles.listTitle}>{visibleShiftLabel(shift)}</Text>
            <Text style={styles.body}>
              {formatCurrency(shift.total_income)} total, {formatCurrency(shift.tips)} tips
            </Text>
          </View>
          <Text style={styles.badge}>{shift.shift_status ?? (shift.has_earnings ? "completed" : "planned")}</Text>
        </View>
      ))}
    </View>
  );
}

function FormInput({ keyboardType = "default", label, multiline = false, onChangeText, placeholder, value }: { keyboardType?: "default" | "decimal-pad"; label: string; multiline?: boolean; onChangeText: (value: string) => void; placeholder: string; value: string }) {
  return (
    <View style={styles.inputGroup}>
      <Text style={styles.label}>{label}</Text>
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

function PickerRow({ label, onPress, value }: { label: string; onPress: () => void; value: string }) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.pickerRow}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.pickerValue}>{value}</Text>
    </Pressable>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.infoRow}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.pickerValue}>{value}</Text>
    </View>
  );
}

function PrimaryButton({ isLoading = false, label, onPress }: { isLoading?: boolean; label: string; onPress: () => void }) {
  return (
    <Pressable
      accessibilityLabel={label}
      accessibilityRole="button"
      disabled={isLoading}
      onPress={onPress}
      style={({ pressed }) => [styles.primaryButton, pressed && styles.pressed, isLoading && styles.disabled]}
    >
      <Text style={styles.primaryButtonText}>{isLoading ? "Saving..." : label}</Text>
    </Pressable>
  );
}

function DatePickerModal({ endTime, picker, setEndTime, setPicker, setShiftDate, setStartTime, shiftDate, startTime }: { endTime: Date; picker: "date" | "start" | "end" | null; setEndTime: (date: Date) => void; setPicker: (picker: "date" | "start" | "end" | null) => void; setShiftDate: (date: Date) => void; setStartTime: (date: Date) => void; shiftDate: Date; startTime: Date }) {
  if (!picker) {
    return null;
  }

  const value = picker === "date" ? shiftDate : picker === "start" ? startTime : endTime;
  const mode = picker === "date" ? "date" : "time";

  function onChange(_event: DateTimePickerEvent, selectedDate?: Date) {
    setPicker(null);

    if (!selectedDate) {
      return;
    }

    if (picker === "date") {
      setShiftDate(selectedDate);
    } else if (picker === "start") {
      setStartTime(selectedDate);
    } else {
      setEndTime(selectedDate);
    }
  }

  return <DateTimePicker mode={mode} onChange={onChange} value={value} />;
}

function EmployerModal({ employers, onClose, onSelect, selectedId, visible }: { employers: Employer[]; onClose: () => void; onSelect: (id: string | null) => void; selectedId: string | null; visible: boolean }) {
  return (
    <Modal animationType="slide" transparent visible={visible}>
      <View style={styles.modalBackdrop}>
        <View style={styles.modalCard}>
          <Text style={styles.formTitle}>Select employer</Text>
          <ModalOption label="No employer" onPress={() => { onSelect(null); onClose(); }} selected={!selectedId} />
          {employers.map((employer) => (
            <ModalOption key={employer.id} label={`${employer.name} - ${formatCurrency(employer.hourly_rate)}/hr`} onPress={() => { onSelect(employer.id); onClose(); }} selected={selectedId === employer.id} />
          ))}
          <PrimaryButton label="Close" onPress={onClose} />
        </View>
      </View>
    </Modal>
  );
}

function ShiftPickerModal({ onClose, onSelect, selectedId, shifts, visible }: { onClose: () => void; onSelect: (id: string) => void; selectedId: string | null; shifts: ShiftIncome[]; visible: boolean }) {
  return (
    <Modal animationType="slide" transparent visible={visible}>
      <View style={styles.modalBackdrop}>
        <View style={styles.modalCard}>
          <Text style={styles.formTitle}>Select shift</Text>
          {shifts.map((shift) => (
            <ModalOption key={shiftId(shift)} label={visibleShiftLabel(shift)} onPress={() => { onSelect(shiftId(shift)); onClose(); }} selected={selectedId === shiftId(shift)} />
          ))}
          <PrimaryButton label="Close" onPress={onClose} />
        </View>
      </View>
    </Modal>
  );
}

function ModalOption({ label, onPress, selected }: { label: string; onPress: () => void; selected: boolean }) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={[styles.modalOption, selected && styles.modalOptionSelected]}>
      <Text style={styles.modalOptionText}>{label}</Text>
    </Pressable>
  );
}

function filterRange(shifts: ShiftIncome[], range: "week" | "month" | "year") {
  const now = new Date();
  const days = range === "week" ? 7 : range === "month" ? 30 : 365;
  const start = new Date(now);
  start.setDate(now.getDate() - days);

  return shifts.filter((shift) => new Date(`${shift.shift_date}T00:00:00`) >= start);
}

const styles = StyleSheet.create({
  badge: {
    ...theme.typography.label,
    color: theme.colors.primary,
    textTransform: "capitalize",
  },
  body: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  dangerText: {
    color: theme.colors.danger,
    fontWeight: "800",
  },
  disabled: {
    opacity: 0.65,
  },
  flex: {
    flex: 1,
  },
  formCard: {
    ...theme.cards,
    gap: theme.spacing.md,
  },
  formTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  infoRow: {
    alignItems: "center",
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    flexDirection: "row",
    justifyContent: "space-between",
    minHeight: 48,
    paddingHorizontal: theme.spacing.md,
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
  label: {
    ...theme.typography.label,
    color: theme.forms.labelColor,
  },
  listRow: {
    alignItems: "center",
    borderTopColor: theme.colors.border,
    borderTopWidth: 1,
    flexDirection: "row",
    gap: theme.spacing.md,
    justifyContent: "space-between",
    paddingVertical: theme.spacing.md,
  },
  listTitle: {
    ...theme.typography.body,
    color: theme.colors.text,
    fontWeight: "800",
  },
  modalBackdrop: {
    backgroundColor: "rgba(16, 24, 40, 0.55)",
    flex: 1,
    justifyContent: "flex-end",
  },
  modalCard: {
    backgroundColor: theme.colors.surface,
    borderTopLeftRadius: theme.radius.lg,
    borderTopRightRadius: theme.radius.lg,
    gap: theme.spacing.md,
    padding: theme.spacing.xl,
  },
  modalOption: {
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    padding: theme.spacing.md,
  },
  modalOptionSelected: {
    backgroundColor: theme.colors.primaryMuted,
    borderColor: theme.colors.primary,
  },
  modalOptionText: {
    ...theme.typography.body,
    color: theme.colors.text,
    fontWeight: "700",
  },
  multilineInput: {
    minHeight: 92,
    textAlignVertical: "top",
  },
  pickerRow: {
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    gap: theme.spacing.xs,
    minHeight: 56,
    padding: theme.spacing.md,
  },
  pickerValue: {
    ...theme.typography.body,
    color: theme.colors.text,
    fontWeight: "700",
  },
  pressed: {
    opacity: 0.85,
  },
  primaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.md,
    minHeight: 52,
    justifyContent: "center",
    paddingHorizontal: theme.spacing.lg,
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
  screen: {
    gap: theme.spacing.lg,
    padding: theme.spacing.xl,
    paddingBottom: theme.spacing.xxxl,
  },
  screenTitle: {
    ...theme.typography.screenTitle,
    color: theme.colors.text,
  },
  scroll: {
    backgroundColor: theme.colors.background,
    flex: 1,
  },
  signOutButton: {
    ...theme.cards,
  },
  statCard: {
    ...theme.cards,
    flexBasis: "47%",
    gap: theme.spacing.xs,
  },
  statLabel: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
  },
  statValue: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  statsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: theme.spacing.md,
  },
  switchRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
});
