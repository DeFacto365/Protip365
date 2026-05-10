import { useCallback, useEffect, useMemo, useState } from "react";
import { Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import { Clock, Pencil, Plus } from "lucide-react-native";
import { AppScaffold, Card } from "../../components/AppScaffold";
import { calculateReportTotals, calculateShift, ShiftRecord } from "../../domain";
import { TodayStackParamList } from "../../navigation/types";
import { loadShiftRecords, saveShiftRecord } from "../../storage/shiftRepository";
import { theme } from "../../theme";
import {
  buildShiftRecordFromDailyEntry,
  createDefaultDailyEntryForm,
  DailyEntryForm,
  formFromShiftRecord,
  hasValidationErrors,
  previewDailyEntry,
  validateDailyEntry,
} from "./dailyEntry";

type DailyEntryScreenProps = {
  navigation: {
    goBack: () => void;
  };
  route?: {
    params?: {
      shiftId?: string;
    };
  };
};

function formatMoney(value: number) {
  return `$${value.toFixed(2)}`;
}

function Field({
  error,
  keyboardType = "default",
  label,
  onChangeText,
  placeholder,
  value,
}: {
  error?: string;
  keyboardType?: "default" | "decimal-pad" | "numbers-and-punctuation";
  label: string;
  onChangeText: (value: string) => void;
  placeholder?: string;
  value: string;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        accessibilityLabel={label}
        autoCapitalize="none"
        keyboardType={keyboardType}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={theme.colors.tabInactive}
        style={[styles.input, error ? styles.inputError : null]}
        value={value}
      />
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

function SegmentedChoice<T extends string>({
  label,
  onChange,
  options,
  value,
}: {
  label: string;
  onChange: (value: T) => void;
  options: Array<{ label: string; value: T }>;
  value: T;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <View style={styles.segmented}>
        {options.map((option) => (
          <Pressable
            accessibilityRole="button"
            key={option.value}
            onPress={() => onChange(option.value)}
            style={[styles.segmentButton, option.value === value ? styles.segmentButtonActive : null]}
          >
            <Text style={[styles.segmentLabel, option.value === value ? styles.segmentLabelActive : null]}>
              {option.label}
            </Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

export function TodayScreen({ navigation }: NativeStackScreenProps<TodayStackParamList, "TodayHome">) {
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

  const today = new Date().toISOString().slice(0, 10);
  const todayRecords = records.filter((record) => record.plannedShift.shiftDate === today);
  const totals = calculateReportTotals(todayRecords);

  return (
    <AppScaffold eyebrow="Daily tips" title="Today">
      <View style={styles.summaryGrid}>
        <View style={styles.summaryTile}>
          <Text style={styles.summaryLabel}>Take-home</Text>
          <Text style={styles.summaryValue}>{formatMoney(totals.totalIncome)}</Text>
        </View>
        <View style={styles.summaryTile}>
          <Text style={styles.summaryLabel}>Real hourly</Text>
          <Text style={styles.summaryValue}>{formatMoney(totals.realHourlyRate)}</Text>
        </View>
      </View>

      <Pressable accessibilityRole="button" onPress={() => navigation.navigate("AddShift")} style={styles.primaryButton}>
        <Plus color="#FFFFFF" size={20} />
        <Text style={styles.primaryButtonText}>Add shift</Text>
      </Pressable>

      {todayRecords.length === 0 ? (
        <Card body="No shift logged for today yet." title="Shift entries" />
      ) : (
        <View style={styles.list}>
          {todayRecords.map((record) => {
            const calculation = calculateShift(record);
            return (
              <Pressable
                accessibilityRole="button"
                key={record.plannedShift.id}
                onPress={() => navigation.navigate("AddShift", { shiftId: record.plannedShift.id })}
                style={styles.shiftRow}
              >
                <View style={styles.shiftRowHeader}>
                  <View style={styles.shiftTime}>
                    <Clock color={theme.colors.textMuted} size={18} />
                    <Text style={styles.shiftTitle}>
                      {record.plannedShift.startTime} - {record.plannedShift.endTime}
                    </Text>
                  </View>
                  <Pencil color={theme.colors.primary} size={18} />
                </View>
                <View style={styles.shiftStats}>
                  <Text style={styles.shiftStat}>{formatMoney(calculation.netTips)} net tips</Text>
                  <Text style={styles.shiftStat}>{formatMoney(calculation.totalIncome)} total</Text>
                  <Text style={styles.shiftStat}>{calculation.hours.toFixed(2)} h</Text>
                </View>
              </Pressable>
            );
          })}
        </View>
      )}
    </AppScaffold>
  );
}

export function AddShiftScreen({ navigation, route }: DailyEntryScreenProps) {
  const [form, setForm] = useState<DailyEntryForm>(() => createDefaultDailyEntryForm());
  const [saved, setSaved] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    let active = true;
    const shiftId = route?.params?.shiftId;

    if (!shiftId) {
      setForm(createDefaultDailyEntryForm());
      setNotFound(false);
      return () => {
        active = false;
      };
    }

    loadShiftRecords().then((records) => {
      if (!active) {
        return;
      }

      const existingRecord = records.find((record) => record.plannedShift.id === shiftId);
      if (existingRecord) {
        setForm(formFromShiftRecord(existingRecord));
        setNotFound(false);
      } else {
        setNotFound(true);
      }
    });

    return () => {
      active = false;
    };
  }, [route?.params?.shiftId]);

  const errors = useMemo(() => (submitted ? validateDailyEntry(form) : {}), [form, submitted]);
  const preview = previewDailyEntry(form);

  function updateField<K extends keyof DailyEntryForm>(field: K, value: DailyEntryForm[K]) {
    setSaved(false);
    setForm((current) => ({ ...current, [field]: value }));
  }

  async function handleSave() {
    setSubmitted(true);
    const nextErrors = validateDailyEntry(form);
    if (hasValidationErrors(nextErrors)) {
      return;
    }

    await saveShiftRecord(buildShiftRecordFromDailyEntry(form));
    setSaved(true);
    navigation.goBack();
  }

  return (
    <AppScaffold eyebrow={route?.params?.shiftId ? "Edit shift" : "Daily entry"} title={route?.params?.shiftId ? "Edit shift" : "Add shift"}>
      {notFound ? <Card body="This shift could not be found on this device." title="Shift unavailable" /> : null}

      <View style={styles.formCard}>
        <Field error={errors.date} keyboardType="numbers-and-punctuation" label="Date" onChangeText={(value) => updateField("date", value)} placeholder="YYYY-MM-DD" value={form.date} />
        <View style={styles.twoColumn}>
          <Field label="Start" onChangeText={(value) => updateField("startTime", value)} placeholder="17:00" value={form.startTime} />
          <Field label="End" onChangeText={(value) => updateField("endTime", value)} placeholder="23:30" value={form.endTime} />
        </View>
        <View style={styles.twoColumn}>
          <Field error={errors.hours} keyboardType="decimal-pad" label="Hours" onChangeText={(value) => updateField("hours", value)} placeholder="6.5" value={form.hours} />
          <Field error={errors.hourlyRate} keyboardType="decimal-pad" label="Hourly rate" onChangeText={(value) => updateField("hourlyRate", value)} placeholder="16.00" value={form.hourlyRate} />
        </View>
        <Field error={errors.sales} keyboardType="decimal-pad" label="Sales" onChangeText={(value) => updateField("sales", value)} placeholder="950.00" value={form.sales} />
        <View style={styles.twoColumn}>
          <Field error={errors.cashTips} keyboardType="decimal-pad" label="Cash tips" onChangeText={(value) => updateField("cashTips", value)} placeholder="40.00" value={form.cashTips} />
          <Field error={errors.cardTips} keyboardType="decimal-pad" label="Card tips" onChangeText={(value) => updateField("cardTips", value)} placeholder="150.00" value={form.cardTips} />
        </View>
        <Field label="Tip-out name" onChangeText={(value) => updateField("tipOutName", value)} placeholder="Bar, host, kitchen" value={form.tipOutName} />
        <View style={styles.twoColumn}>
          <Field error={errors.tipOutValue} keyboardType="decimal-pad" label="Tip-out" onChangeText={(value) => updateField("tipOutValue", value)} placeholder="3 or 25" value={form.tipOutValue} />
          <Field error={errors.otherIncome} keyboardType="decimal-pad" label="Other income" onChangeText={(value) => updateField("otherIncome", value)} placeholder="0.00" value={form.otherIncome} />
        </View>
        <SegmentedChoice
          label="Tip-out method"
          onChange={(value) => updateField("tipOutMethod", value)}
          options={[
            { label: "%", value: "percentage" },
            { label: "$", value: "fixed" },
          ]}
          value={form.tipOutMethod}
        />
        <SegmentedChoice
          label="Tip-out basis"
          onChange={(value) => updateField("tipOutBasis", value)}
          options={[
            { label: "Sales", value: "sales" },
            { label: "Tips", value: "tips" },
          ]}
          value={form.tipOutBasis}
        />
        <Field label="Notes" onChangeText={(value) => updateField("notes", value)} placeholder="Section, event, payout note" value={form.notes} />
      </View>

      {preview ? (
        <View style={styles.previewCard}>
          <Text style={styles.previewTitle}>Shift preview</Text>
          <View style={styles.previewGrid}>
            <Text style={styles.previewItem}>Gross tips {formatMoney(preview.grossTips)}</Text>
            <Text style={styles.previewItem}>Tip-out {formatMoney(preview.tipOut)}</Text>
            <Text style={styles.previewItem}>Net tips {formatMoney(preview.netTips)}</Text>
            <Text style={styles.previewItem}>Total {formatMoney(preview.totalIncome)}</Text>
          </View>
        </View>
      ) : null}

      <Pressable accessibilityRole="button" onPress={handleSave} style={styles.primaryButton}>
        <Text style={styles.primaryButtonText}>{route?.params?.shiftId ? "Save changes" : "Save shift"}</Text>
      </Pressable>
      {saved ? <Text style={styles.saved}>Saved</Text> : null}
    </AppScaffold>
  );
}

const styles = StyleSheet.create({
  error: {
    color: theme.colors.danger,
    fontSize: 12,
    lineHeight: 16,
  },
  field: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  formCard: {
    ...theme.cards,
    gap: theme.spacing.md,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.forms.borderColor,
    borderRadius: theme.forms.borderRadius,
    borderWidth: 1,
    color: theme.colors.text,
    fontSize: 16,
    minHeight: theme.forms.inputHeight,
    paddingHorizontal: theme.spacing.md,
  },
  inputError: {
    borderColor: theme.colors.danger,
  },
  label: {
    ...theme.typography.label,
    color: theme.forms.labelColor,
  },
  list: {
    gap: theme.spacing.md,
  },
  previewCard: {
    ...theme.cards,
    gap: theme.spacing.md,
  },
  previewGrid: {
    gap: theme.spacing.sm,
  },
  previewItem: {
    ...theme.typography.body,
    color: theme.colors.text,
  },
  previewTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  primaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.md,
    flexDirection: "row",
    gap: theme.spacing.sm,
    justifyContent: "center",
    minHeight: 52,
    paddingHorizontal: theme.spacing.lg,
  },
  primaryButtonText: {
    ...theme.typography.label,
    color: "#FFFFFF",
    fontSize: 16,
  },
  saved: {
    ...theme.typography.body,
    color: theme.colors.success,
    textAlign: "center",
  },
  segmented: {
    backgroundColor: theme.colors.surfaceMuted,
    borderRadius: theme.radius.md,
    flexDirection: "row",
    padding: theme.spacing.xs,
  },
  segmentButton: {
    alignItems: "center",
    borderRadius: theme.radius.sm,
    flex: 1,
    paddingVertical: theme.spacing.sm,
  },
  segmentButtonActive: {
    backgroundColor: theme.colors.surface,
  },
  segmentLabel: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
  },
  segmentLabelActive: {
    color: theme.colors.primary,
  },
  shiftRow: {
    ...theme.cards,
    gap: theme.spacing.md,
  },
  shiftRowHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  shiftStat: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
  },
  shiftStats: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: theme.spacing.md,
  },
  shiftTime: {
    alignItems: "center",
    flexDirection: "row",
    gap: theme.spacing.sm,
  },
  shiftTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  summaryGrid: {
    flexDirection: "row",
    gap: theme.spacing.md,
  },
  summaryLabel: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
  },
  summaryTile: {
    ...theme.cards,
    flex: 1,
    gap: theme.spacing.xs,
  },
  summaryValue: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  twoColumn: {
    flexDirection: "row",
    gap: theme.spacing.md,
  },
});
