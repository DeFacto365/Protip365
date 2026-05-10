import { DefaultTheme, NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { CalendarDays, CirclePlus, ClipboardList, Home, Settings } from "lucide-react-native";
import { getStrings } from "../localization";
import {
  AddStackParamList,
  CalendarStackParamList,
  MainTabParamList,
  ReportsStackParamList,
  RootStackParamList,
  SettingsStackParamList,
  TodayStackParamList,
} from "./types";
import {
  AddHomeScreen,
  AddIncomeScreen,
  OnboardingScreen,
  PaywallScreen,
  SettingsScreen,
} from "../screens/PlaceholderScreens";
import { AddShiftScreen, TodayScreen } from "../features/dailyEntry/DailyEntryScreen";
import { CalendarScreen, PlannedShiftScreen } from "../features/plannedShift/PlannedShiftScreen";
import {
  HistoryScreen,
  MonthlyReportScreen,
  ReportsScreen,
  WeeklyReportScreen,
  YearlyReportScreen,
} from "../features/reports/ReportScreens";
import { theme } from "../theme";

const RootStack = createNativeStackNavigator<RootStackParamList>();
const Tabs = createBottomTabNavigator<MainTabParamList>();
const TodayStack = createNativeStackNavigator<TodayStackParamList>();
const CalendarStack = createNativeStackNavigator<CalendarStackParamList>();
const AddStack = createNativeStackNavigator<AddStackParamList>();
const ReportsStack = createNativeStackNavigator<ReportsStackParamList>();
const SettingsStack = createNativeStackNavigator<SettingsStackParamList>();
const strings = getStrings();

const navigationTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: theme.colors.background,
    border: theme.colors.border,
    card: theme.colors.surface,
    primary: theme.colors.primary,
    text: theme.colors.text,
  },
};

const stackScreenOptions = {
  contentStyle: {
    backgroundColor: theme.colors.background,
  },
  headerShown: false,
};

function TodayStackNavigator() {
  return (
    <TodayStack.Navigator screenOptions={stackScreenOptions}>
      <TodayStack.Screen component={TodayScreen} name="TodayHome" />
      <TodayStack.Screen component={AddShiftScreen} name="AddShift" />
      <TodayStack.Screen component={AddIncomeScreen} name="AddIncome" />
    </TodayStack.Navigator>
  );
}

function CalendarStackNavigator() {
  return (
    <CalendarStack.Navigator screenOptions={stackScreenOptions}>
      <CalendarStack.Screen component={CalendarScreen} name="CalendarHome" />
      <CalendarStack.Screen component={AddShiftScreen} name="AddShift" />
      <CalendarStack.Screen component={PlannedShiftScreen} name="AddPlannedShift" />
    </CalendarStack.Navigator>
  );
}

function AddStackNavigator() {
  return (
    <AddStack.Navigator screenOptions={stackScreenOptions}>
      <AddStack.Screen component={AddHomeScreen} name="AddHome" />
      <AddStack.Screen component={AddShiftScreen} name="AddShift" />
      <AddStack.Screen component={PlannedShiftScreen} name="AddPlannedShift" />
      <AddStack.Screen component={AddIncomeScreen} name="AddIncome" />
    </AddStack.Navigator>
  );
}

function ReportsStackNavigator() {
  return (
    <ReportsStack.Navigator screenOptions={stackScreenOptions}>
      <ReportsStack.Screen component={ReportsScreen} name="ReportsHome" />
      <ReportsStack.Screen component={WeeklyReportScreen} name="WeeklyReport" />
      <ReportsStack.Screen component={MonthlyReportScreen} name="MonthlyReport" />
      <ReportsStack.Screen component={YearlyReportScreen} name="YearlyReport" />
      <ReportsStack.Screen component={HistoryScreen} name="History" />
      <ReportsStack.Screen component={AddShiftScreen} name="AddShift" />
      <ReportsStack.Screen component={PlannedShiftScreen} name="AddPlannedShift" />
    </ReportsStack.Navigator>
  );
}

function SettingsStackNavigator() {
  return (
    <SettingsStack.Navigator screenOptions={stackScreenOptions}>
      <SettingsStack.Screen component={SettingsScreen} name="SettingsHome" />
    </SettingsStack.Navigator>
  );
}

function MainTabs() {
  return (
    <Tabs.Navigator
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: theme.navigation.activeTint,
        tabBarInactiveTintColor: theme.navigation.inactiveTint,
        tabBarLabelStyle: {
          fontSize: theme.typography.label.fontSize,
          fontWeight: theme.typography.label.fontWeight,
        },
        tabBarStyle: {
          backgroundColor: theme.colors.tabBar,
          borderTopColor: theme.colors.border,
          height: theme.navigation.tabBarHeight,
          paddingBottom: theme.spacing.sm,
          paddingTop: theme.spacing.sm,
        },
      }}
    >
      <Tabs.Screen
        component={TodayStackNavigator}
        name="TodayTab"
        options={{
          tabBarAccessibilityLabel: strings.tabs.today,
          tabBarIcon: ({ color, size }) => <Home color={color} size={size} />,
          tabBarLabel: strings.tabs.today,
        }}
      />
      <Tabs.Screen
        component={CalendarStackNavigator}
        name="CalendarTab"
        options={{
          tabBarAccessibilityLabel: strings.tabs.calendar,
          tabBarIcon: ({ color, size }) => <CalendarDays color={color} size={size} />,
          tabBarLabel: strings.tabs.calendar,
        }}
      />
      <Tabs.Screen
        component={AddStackNavigator}
        name="AddTab"
        options={{
          tabBarAccessibilityLabel: strings.tabs.add,
          tabBarIcon: ({ color, size }) => <CirclePlus color={color} size={size} />,
          tabBarLabel: strings.tabs.add,
        }}
      />
      <Tabs.Screen
        component={ReportsStackNavigator}
        name="ReportsTab"
        options={{
          tabBarAccessibilityLabel: strings.tabs.reports,
          tabBarIcon: ({ color, size }) => <ClipboardList color={color} size={size} />,
          tabBarLabel: strings.tabs.reports,
        }}
      />
      <Tabs.Screen
        component={SettingsStackNavigator}
        name="SettingsTab"
        options={{
          tabBarAccessibilityLabel: strings.tabs.settings,
          tabBarIcon: ({ color, size }) => <Settings color={color} size={size} />,
          tabBarLabel: strings.tabs.settings,
        }}
      />
    </Tabs.Navigator>
  );
}

export function AppNavigator() {
  return (
    <NavigationContainer theme={navigationTheme}>
      <RootStack.Navigator screenOptions={stackScreenOptions}>
        <RootStack.Screen component={MainTabs} name="MainTabs" />
        <RootStack.Screen component={OnboardingScreen} name="Onboarding" />
        <RootStack.Screen component={PaywallScreen} name="Paywall" />
      </RootStack.Navigator>
    </NavigationContainer>
  );
}
