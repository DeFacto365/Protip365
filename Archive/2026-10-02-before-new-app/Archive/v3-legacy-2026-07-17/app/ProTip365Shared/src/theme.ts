export const colors = {
  background: "#F6F7F9",
  surface: "#FFFFFF",
  surfaceMuted: "#EEF2F7",
  text: "#101828",
  textMuted: "#5B6472",
  border: "#D8DEE8",
  primary: "#2563EB",
  primaryMuted: "#DBEAFE",
  success: "#11835B",
  warning: "#B45309",
  danger: "#B42318",
  tabBar: "#FFFFFF",
  tabInactive: "#7B8494",
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 48,
} as const;

export const typography = {
  title: { fontSize: 34, lineHeight: 40, fontWeight: "800" },
  screenTitle: { fontSize: 28, lineHeight: 34, fontWeight: "800" },
  sectionTitle: { fontSize: 18, lineHeight: 24, fontWeight: "700" },
  body: { fontSize: 16, lineHeight: 24, fontWeight: "400" },
  label: { fontSize: 13, lineHeight: 18, fontWeight: "700" },
} as const;

export const radius = {
  sm: 6,
  md: 8,
  lg: 14,
} as const;

export const cards = {
  backgroundColor: colors.surface,
  borderColor: colors.border,
  borderRadius: radius.md,
  borderWidth: 1,
  padding: spacing.lg,
} as const;

export const forms = {
  borderColor: colors.border,
  borderRadius: radius.md,
  inputHeight: 48,
  labelColor: colors.textMuted,
} as const;

export const navigation = {
  activeTint: colors.primary,
  headerBackground: colors.background,
  inactiveTint: colors.tabInactive,
  tabBarHeight: 64,
  tabIconSize: 22,
} as const;

export const theme = {
  cards,
  colors,
  forms,
  navigation,
  radius,
  spacing,
  typography,
} as const;

export type AppTheme = typeof theme;
