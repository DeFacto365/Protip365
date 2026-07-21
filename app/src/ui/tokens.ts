import { useColorScheme } from 'react-native';

export { EMPLOYER_PALETTE } from '../domain/employerColors';

/**
 * "Shift Receipt" tokens — owner-approved 2026-07-20.
 * Source: Docs/design/explorations/home-redesign/claude/receipt-screens.html.
 */
export interface Tokens {
  bg: string;
  paper: string;
  surface: string;
  card: string;
  ink: string;
  dim: string;
  softText: string;
  rule: string;
  line: string;
  red: string;
  green: string;
  pen: string;
  /** Legacy aliases retained for existing screens. */
  cobalt: string;
  cobaltLink: string;
  cobaltSoft: string;
  greenSoft: string;
  amber: string;
  amberSoft: string;
  dangerBg: string;
  danger: string;
  fabText: string;
}

export const light: Tokens = {
  bg: '#E9E4D7',
  paper: '#F6F2E9',
  surface: '#F6F2E9',
  card: '#F6F2E9',
  ink: '#20211E',
  dim: '#7C7A70',
  softText: '#7C7A70',
  rule: '#C9C3B2',
  line: '#C9C3B2',
  red: '#D8472B',
  green: '#2E7D4F',
  pen: '#20211E',
  cobalt: '#20211E',
  cobaltLink: '#20211E',
  cobaltSoft: '#F6F2E9',
  greenSoft: '#F6F2E9',
  amber: '#D8472B',
  amberSoft: '#F6F2E9',
  dangerBg: '#D8472B',
  danger: '#D8472B',
  fabText: '#F6F2E9',
};

export const dark: Tokens = {
  bg: '#171714',
  paper: '#24231F',
  surface: '#24231F',
  card: '#24231F',
  ink: '#F0EEE6',
  dim: '#AAA59A',
  softText: '#AAA59A',
  rule: '#716C61',
  line: '#716C61',
  red: '#FF7A5C',
  green: '#5CD69B',
  pen: '#F0EEE6',
  cobalt: '#F0EEE6',
  cobaltLink: '#F0EEE6',
  cobaltSoft: '#24231F',
  greenSoft: '#24231F',
  amber: '#FF7A5C',
  amberSoft: '#24231F',
  dangerBg: '#FF7A5C',
  danger: '#FF7A5C',
  fabText: '#171714',
};

/** Minimum touch target (dp). */
export const TOUCH_TARGET = 48;

/** Square geometry is part of the approved receipt direction. */
export const radius = {
  card: 0,
  button: 0,
  chip: 0,
  field: 0,
} as const;

export function useTokens(): { t: Tokens; isDark: boolean } {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';
  return { t: isDark ? dark : light, isDark };
}
