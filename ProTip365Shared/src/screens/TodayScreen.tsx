import { useMemo } from "react";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { CircleDollarSign, Plus } from "lucide-react-native";
import { ActionList } from "../components/ActionList";
import { TodayStackParamList } from "../navigation/types";
import { theme } from "../theme";
import { buildStats, DataScaffold, ShiftList, StatsGrid, strings, todayValue, useAppData } from "./shared/screenShared";

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
