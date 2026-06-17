import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { CalendarDays } from "lucide-react-native";
import { Text, View } from "react-native";
import { ActionList } from "../components/ActionList";
import { toDateValue } from "../lib/protipData";
import { CalendarStackParamList } from "../navigation/types";
import { theme } from "../theme";
import { addDays, DataScaffold, ShiftList, startOfWeek, strings, styles, todayValue, useAppData } from "./shared/screenShared";

export function CalendarScreen({ navigation }: NativeStackScreenProps<CalendarStackParamList, "CalendarHome">) {
  const { isLoading, profile, reload, shifts } = useAppData();
  const weekStart = profile?.week_start ?? 0;
  const weekDays = Array.from({ length: 7 }, (_, index) => addDays(startOfWeek(new Date(), weekStart), index));
  const shiftDates = new Set(shifts.map((shift) => shift.shift_date));
  const selectedDate = todayValue();
  const selectedShifts = shifts.filter((shift) => shift.shift_date === selectedDate);

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.calendar}>
      <View style={styles.weekCalendar}>
        {weekDays.map((date) => {
          const value = toDateValue(date);
          const hasShift = shiftDates.has(value);
          const isToday = value === selectedDate;

          return (
            <View key={value} style={[styles.dayCell, isToday && styles.dayCellToday]}>
              <Text style={[styles.dayName, hasShift && styles.dayHasShift]}>{date.toLocaleDateString(undefined, { weekday: "short" })}</Text>
              <Text style={[styles.dayNumber, hasShift && styles.dayHasShift]}>{date.getDate()}</Text>
            </View>
          );
        })}
      </View>
      <ActionList
        items={[
          {
            icon: <CalendarDays color={theme.colors.primary} size={theme.navigation.tabIconSize} />,
            label: strings.actions.addShift,
            onPress: () => navigation.navigate("AddShift"),
          },
        ]}
      />
      <ShiftList emptyText="No shifts for today." shifts={selectedShifts} />
      <ShiftList emptyText="No upcoming shifts." shifts={shifts} title="All shifts" />
    </DataScaffold>
  );
}
