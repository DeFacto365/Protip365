import { useCallback, useEffect, useMemo, useState } from "react";
import { Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import { CalendarPlus, Pencil } from "lucide-react-native";
import { AppScaffold, Card } from "../../components/AppScaffold";
import { calculatePlannedHours, ShiftRecord } from "../../domain";
import { CalendarStackParamList } from "../../navigation/types";
import { loadShiftRecords, saveShiftRecord } from "../../storage/shiftRepository";
import { theme } from "../../theme";
import {
  buildRecordFromPlannedShift,
  createDefaultPlannedShiftForm,
  formFromPlannedShiftRecord,
  hasPlannedShiftValidationErrors,
  PlannedShiftForm,
  previewPlannedHours,
  validatePlannedShift,
} from "./plannedShift";

type PlannedShiftScreenProps = {
  navigation: {
    goBack: () => void;
  };
  route?: {
    params?: {
      shiftId?: string;
    };
  };
};

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

export function CalendarScreen({ navigation }: NativeStackScreenProps<CalendarStackParamList, "CalendarHome">) {
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

  const plannedRecords = records
    .filter((record) => record.plannedShift.status === "planned")
    .sort((first, second) => `${first.plannedShift.shiftDate} ${first.plannedShift.startTime}`.localeCompare(`${second.plannedShift.shiftDate} ${second.plannedShift.startTime}`));

  return (
    <AppScaffold title="Calendar">
      <Pressable accessibilityRole="button" onPress={() => navigation.navigate("AddPlannedShift")} style={styles.primaryButton}>
        <CalendarPlus color="#FFFFFF" size={20} />
        <Text style={styles.primaryButtonText}>Add planned shift</Text>
      </Pressable>

      {plannedRecords.length === 0 ? (
        <Card body="No planned shifts saved yet." title="Planned shifts" />
      ) : (
        <View style={styles.list}>
          {plannedRecords.map((record) => (
            <Pressable
              accessibilityRole="button"
              key={record.plannedShift.id}
              onPress={() => navigation.navigate("AddPlannedShift", { shiftId: record.plannedShift.id })}
              style={styles.shiftRow}
            >
              <View style={styles.shiftRowHeader}>
                <View>
                  <Text style={styles.shiftTitle}>{record.plannedShift.shiftDate}</Text>
                  <Text style={styles.shiftSubtitle}>
                    {record.plannedShift.startTime} - {record.plannedShift.endTime} | {calculatePlannedHours(record.plannedShift).toFixed(2)} h
                  </Text>
                </View>
                <Pencil color={theme.colors.primary} size={18} />
              </View>
              {record.employer?.name ? <Text style={styles.shiftSubtitle}>{record.employer.name}</Text> : null}
            </Pressable>
          ))}
        </View>
      )}
    </AppScaffold>
  );
}

export function PlannedShiftScreen({ navigation, route }: PlannedShiftScreenProps) {
  const [form, setForm] = useState<PlannedShiftForm>(() => createDefaultPlannedShiftForm());
  const [submitted, setSubmitted] = useState(false);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    let active = true;
    const shiftId = route?.params?.shiftId;

    if (!shiftId) {
      setForm(createDefaultPlannedShiftForm());
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
        setForm(formFromPlannedShiftRecord(existingRecord));
        setNotFound(false);
      } else {
        setNotFound(true);
      }
    });

    return () => {
      active = false;
    };
  }, [route?.params?.shiftId]);

  const errors = useMemo(() => (submitted ? validatePlannedShift(form) : {}), [form, submitted]);
  const plannedHours = previewPlannedHours(form);

  function updateField<K extends keyof PlannedShiftForm>(field: K, value: PlannedShiftForm[K]) {
    setForm((current) => ({ ...current, [field]: value }));
  }

  async function handleSave() {
    setSubmitted(true);
    const nextErrors = validatePlannedShift(form);
    if (hasPlannedShiftValidationErrors(nextErrors)) {
      return;
    }

    await saveShiftRecord(buildRecordFromPlannedShift(form));
    navigation.goBack();
  }

  return (
    <AppScaffold eyebrow={route?.params?.shiftId ? "Edit plan" : "Plan shift"} title={route?.params?.shiftId ? "Edit planned shift" : "Add planned shift"}>
      {notFound ? <Card body="This planned shift could not be found on this device." title="Shift unavailable" /> : null}

      <View style={styles.formCard}>
        <Field error={errors.date} keyboardType="numbers-and-punctuation" label="Date" onChangeText={(value) => updateField("date", value)} placeholder="YYYY-MM-DD" value={form.date} />
        <View style={styles.twoColumn}>
          <Field error={errors.startTime} label="Start" onChangeText={(value) => updateField("startTime", value)} placeholder="17:00" value={form.startTime} />
          <Field error={errors.endTime} label="End" onChangeText={(value) => updateField("endTime", value)} placeholder="23:30" value={form.endTime} />
        </View>
        <View style={styles.twoColumn}>
          <Field error={errors.expectedHours} keyboardType="decimal-pad" label="Expected hours" onChangeText={(value) => updateField("expectedHours", value)} placeholder="Optional" value={form.expectedHours} />
          <Field error={errors.hourlyRate} keyboardType="decimal-pad" label="Hourly rate" onChangeText={(value) => updateField("hourlyRate", value)} placeholder="16.00" value={form.hourlyRate} />
        </View>
        <Field label="Employer" onChangeText={(value) => updateField("employerName", value)} placeholder="Restaurant or bar" value={form.employerName} />
        <Field label="Notes" onChangeText={(value) => updateField("notes", value)} placeholder="Section, reminder, uniform note" value={form.notes} />
      </View>

      {plannedHours !== null ? (
        <View style={styles.previewCard}>
          <Text style={styles.previewTitle}>Planned duration</Text>
          <Text style={styles.previewItem}>{plannedHours.toFixed(2)} hours</Text>
        </View>
      ) : null}

      <Pressable accessibilityRole="button" onPress={handleSave} style={styles.primaryButton}>
        <Text style={styles.primaryButtonText}>{route?.params?.shiftId ? "Save changes" : "Save planned shift"}</Text>
      </Pressable>
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
    gap: theme.spacing.xs,
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
  shiftRow: {
    ...theme.cards,
    gap: theme.spacing.sm,
  },
  shiftRowHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  shiftSubtitle: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  shiftTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  twoColumn: {
    flexDirection: "row",
    gap: theme.spacing.md,
  },
});
