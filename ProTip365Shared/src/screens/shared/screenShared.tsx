import React, { useCallback, useState } from "react";
import { Alert, Modal, Pressable, RefreshControl, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import DateTimePicker, { DateTimePickerChangeEvent } from "@react-native-community/datetimepicker";
import { useFocusEffect } from "@react-navigation/native";
import { AppScaffold, Card } from "../../components/AppScaffold";
import {
  Employer,
  formatCurrency,
  getProfile,
  listEmployers,
  listShiftIncome,
  ShiftIncome,
  toDateValue,
  UserProfile,
} from "../../lib/protipData";
import { getStrings } from "../../localization";
import { theme } from "../../theme";

export const strings = getStrings();

export function todayValue() {
  return toDateValue(new Date());
}

export function startOfWeek(date: Date, weekStart = 0) {
  const next = new Date(date);
  const diff = (next.getDay() - weekStart + 7) % 7;
  next.setDate(next.getDate() - diff);
  next.setHours(0, 0, 0, 0);

  return next;
}

export function addDays(date: Date, days: number) {
  const next = new Date(date);
  next.setDate(date.getDate() + days);

  return next;
}

export function timeFromString(value: string) {
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

export function shiftId(shift: ShiftIncome) {
  return shift.shift_id ?? shift.id ?? "";
}

function timeLabel(value: string) {
  return value.slice(0, 5);
}

export function visibleShiftLabel(shift: ShiftIncome) {
  const employer = shift.employer_name ? ` - ${shift.employer_name}` : "";
  const time = shift.start_time && shift.end_time ? `, ${timeLabel(shift.start_time)}-${timeLabel(shift.end_time)}` : "";

  return `${shift.shift_date}${time}${employer}`;
}

export function useAppData() {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [employers, setEmployers] = useState<Employer[]>([]);
  const [shifts, setShifts] = useState<ShiftIncome[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const reload = useCallback(async () => {
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
  }, []);

  useFocusEffect(
    useCallback(() => {
      void reload();
    }, [reload]),
  );

  return { employers, isLoading, profile, reload, setProfile, shifts };
}

export function DataScaffold({ children, isLoading, onRefresh, title }: { children: React.ReactNode; isLoading: boolean; onRefresh: () => Promise<void>; title: string }) {
  return (
    <ScrollView
      contentContainerStyle={styles.screen}
      keyboardShouldPersistTaps="handled"
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

export function buildStats(shifts: ShiftIncome[]) {
  const hours = sum(shifts.map((shift) => shift.hours ?? 0));
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

export function StatsGrid({ stats }: { stats: ReturnType<typeof buildStats> }) {
  function showDetails(label: string, value: string) {
    Alert.alert(label, value);
  }

  return (
    <View style={styles.statsGrid}>
      <StatCard label="Total income" onPress={() => showDetails("Total income", `${formatCurrency(stats.salary)} base pay + ${formatCurrency(stats.tips)} tips - ${formatCurrency(stats.tipOut)} tip-out = ${formatCurrency(stats.total)}`)} value={formatCurrency(stats.total)} />
      <StatCard label="Tips" onPress={() => showDetails("Tips", `${formatCurrency(stats.tips)} tips, ${formatCurrency(stats.tipOut)} tip-out`)} value={formatCurrency(stats.tips)} />
      <StatCard label="Sales" onPress={() => showDetails("Sales", `${formatCurrency(stats.sales)} recorded sales`)} value={formatCurrency(stats.sales)} />
      <StatCard label="Hours" onPress={() => showDetails("Hours", `${stats.hours.toFixed(2)} recorded hours`)} value={stats.hours.toFixed(2)} />
      <StatCard label="Base pay" onPress={() => showDetails("Base pay", `${formatCurrency(stats.salary)} before tips`)} value={formatCurrency(stats.salary)} />
      <StatCard label="Tip %" onPress={() => showDetails("Tip %", `${stats.tipPercentage.toFixed(1)}% tips on sales`)} value={`${stats.tipPercentage.toFixed(1)}%`} />
    </View>
  );
}

function StatCard({ label, onPress, value }: { label: string; onPress: () => void; value: string }) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={({ pressed }) => [styles.statCard, pressed && styles.pressed]}>
      <Text style={styles.statLabel}>{label}</Text>
      <Text style={styles.statValue}>{value}</Text>
    </Pressable>
  );
}

export function ShiftList({ emptyText, shifts, title = "Shifts" }: { emptyText: string; shifts: ShiftIncome[]; title?: string }) {
  if (shifts.length === 0) {
    return <Card body={emptyText} title={title} />;
  }

  return (
    <View style={styles.formCard}>
      <Text style={styles.formTitle}>{title}</Text>
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

export function FormInput({ keyboardType = "default", label, multiline = false, onChangeText, placeholder, value }: { keyboardType?: "default" | "decimal-pad"; label: string; multiline?: boolean; onChangeText: (value: string) => void; placeholder: string; value: string }) {
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

export function PickerRow({ label, onPress, value }: { label: string; onPress: () => void; value: string }) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.pickerRow}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.pickerValue}>{value}</Text>
    </Pressable>
  );
}

export function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.infoRow}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.pickerValue}>{value}</Text>
    </View>
  );
}

export function PrimaryButton({ isLoading = false, label, onPress }: { isLoading?: boolean; label: string; onPress: () => void }) {
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

export function DatePickerModal({ endTime, picker, setEndTime, setPicker, setShiftDate, setStartTime, shiftDate, startTime }: { endTime: Date; picker: "date" | "start" | "end" | null; setEndTime: (date: Date) => void; setPicker: (picker: "date" | "start" | "end" | null) => void; setShiftDate: (date: Date) => void; setStartTime: (date: Date) => void; shiftDate: Date; startTime: Date }) {
  if (!picker) {
    return null;
  }

  const value = picker === "date" ? shiftDate : picker === "start" ? startTime : endTime;
  const mode = picker === "date" ? "date" : "time";

  function onValueChange(_event: DateTimePickerChangeEvent, selectedDate: Date) {
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

  return (
    <DateTimePicker
      mode={mode}
      onDismiss={() => setPicker(null)}
      onNeutralButtonPress={() => setPicker(null)}
      onValueChange={onValueChange}
      value={value}
    />
  );
}

export function EmployerModal({ employers, onClose, onSelect, selectedId, visible }: { employers: Employer[]; onClose: () => void; onSelect: (id: string | null) => void; selectedId: string | null; visible: boolean }) {
  const visibleEmployers = employers.filter((employer) => employer.active !== false || employer.id === selectedId);

  return (
    <Modal animationType="slide" transparent visible={visible}>
      <View style={styles.modalBackdrop}>
        <View style={styles.modalCard}>
          <Text style={styles.formTitle}>Select employer</Text>
          <ModalOption label="No employer" onPress={() => { onSelect(null); onClose(); }} selected={!selectedId} />
          {visibleEmployers.map((employer) => (
            <ModalOption key={employer.id} label={`${employer.name} - ${formatCurrency(employer.hourly_rate)}/hr`} onPress={() => { onSelect(employer.id); onClose(); }} selected={selectedId === employer.id} />
          ))}
          <PrimaryButton label="Close" onPress={onClose} />
        </View>
      </View>
    </Modal>
  );
}

export function ShiftPickerModal({ onClose, onSelect, selectedId, shifts, visible }: { onClose: () => void; onSelect: (id: string) => void; selectedId: string | null; shifts: ShiftIncome[]; visible: boolean }) {
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

export function filterRange(shifts: ShiftIncome[], range: "week" | "month" | "year") {
  const now = new Date();
  const start =
    range === "week"
      ? startOfWeek(now)
      : range === "month"
        ? new Date(now.getFullYear(), now.getMonth(), 1)
        : new Date(now.getFullYear(), 0, 1);
  const end =
    range === "week"
      ? addDays(start, 7)
      : range === "month"
        ? new Date(now.getFullYear(), now.getMonth() + 1, 1)
        : new Date(now.getFullYear() + 1, 0, 1);

  return shifts.filter((shift) => {
    const shiftDate = new Date(`${shift.shift_date}T00:00:00`);

    return shiftDate >= start && shiftDate < end;
  });
}

export const styles = StyleSheet.create({
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
  dayCell: {
    alignItems: "center",
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    flex: 1,
    gap: theme.spacing.xs,
    minHeight: 70,
    paddingVertical: theme.spacing.sm,
  },
  dayCellToday: {
    backgroundColor: theme.colors.primaryMuted,
    borderColor: theme.colors.primary,
  },
  dayHasShift: {
    color: theme.colors.primary,
    fontWeight: "900",
  },
  dayName: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
  },
  dayNumber: {
    ...theme.typography.body,
    color: theme.colors.text,
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
  rowWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
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
  weekCalendar: {
    flexDirection: "row",
    gap: theme.spacing.xs,
  },
});
