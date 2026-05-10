export type ShiftEntryRouteParams = { shiftId?: string } | undefined;
export type PlannedShiftRouteParams = { shiftId?: string } | undefined;

export type RootStackParamList = {
  MainTabs: undefined;
  Onboarding: undefined;
  Paywall: undefined;
};

export type TodayStackParamList = {
  TodayHome: undefined;
  AddShift: ShiftEntryRouteParams;
  AddIncome: undefined;
};

export type CalendarStackParamList = {
  CalendarHome: undefined;
  AddShift: ShiftEntryRouteParams;
  AddPlannedShift: PlannedShiftRouteParams;
};

export type AddStackParamList = {
  AddHome: undefined;
  AddShift: ShiftEntryRouteParams;
  AddPlannedShift: PlannedShiftRouteParams;
  AddIncome: undefined;
};

export type ReportsStackParamList = {
  ReportsHome: undefined;
  WeeklyReport: undefined;
  MonthlyReport: undefined;
  YearlyReport: undefined;
  History: undefined;
};

export type SettingsStackParamList = {
  SettingsHome: undefined;
};

export type MainTabParamList = {
  TodayTab: undefined;
  CalendarTab: undefined;
  AddTab: undefined;
  ReportsTab: undefined;
  SettingsTab: undefined;
};
