import { useState } from "react";
import { Alert, Text, View } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { CircleDollarSign, Plus } from "lucide-react-native";
import { ActionList } from "../components/ActionList";
import { AppScaffold } from "../components/AppScaffold";
import { createShift, formatCurrency, hoursBetween, parseMoney, saveIncome, toDateValue, toTimeValue } from "../lib/protipData";
import { AddStackParamList } from "../navigation/types";
import { theme } from "../theme";
import {
  DataScaffold,
  DatePickerModal,
  EmployerModal,
  FormInput,
  InfoRow,
  PickerRow,
  PrimaryButton,
  ShiftPickerModal,
  shiftId,
  strings,
  styles,
  timeFromString,
  useAppData,
  visibleShiftLabel,
} from "./shared/screenShared";

export function AddHomeScreen({ navigation }: NativeStackScreenProps<AddStackParamList, "AddHome">) {
  const [billAmount, setBillAmount] = useState("");
  const [tipPercent, setTipPercent] = useState("18");
  const [splitCount, setSplitCount] = useState("1");
  const bill = parseMoney(billAmount);
  const percent = parseMoney(tipPercent);
  const people = Math.max(1, Math.round(parseMoney(splitCount) || 1));
  const tip = bill * (percent / 100);
  const total = bill + tip;

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
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>Tip calculator</Text>
        <View style={styles.row}>
          <FormInput keyboardType="decimal-pad" label="Bill" onChangeText={setBillAmount} placeholder="0.00" value={billAmount} />
          <FormInput keyboardType="decimal-pad" label="Tip %" onChangeText={setTipPercent} placeholder="18" value={tipPercent} />
        </View>
        <FormInput keyboardType="decimal-pad" label="Split" onChangeText={setSplitCount} placeholder="1" value={splitCount} />
        <InfoRow label="Tip amount" value={formatCurrency(tip)} />
        <InfoRow label="Total" value={formatCurrency(total)} />
        <InfoRow label="Per person" value={formatCurrency(total / people)} />
      </View>
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
