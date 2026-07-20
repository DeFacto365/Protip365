import { useColorScheme } from 'react-native';

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
  pen: '#2B4BD7',
  cobalt: '#2B4BD7',
  cobaltLink: '#2B4BD7',
  cobaltSoft: '#F6F2E9',
  greenSoft: '#F6F2E9',
  amber: '#D8472B',
  amberSoft: '#F6F2E9',
  dangerBg: '#D8472B',
  danger: '#D8472B',
  fabText: '#F6F2E9',
};

export const dark: Tokens = {
  bg: '#12151C',
  paper: '#1E222C',
  surface: '#1E222C',
  card: '#1E222C',
  ink: '#F0EEE6',
  dim: '#8B92A5',
  softText: '#8B92A5',
  rule: '#3A4152',
  line: '#3A4152',
  red: '#FF7A5C',
  green: '#5CD69B',
  pen: '#8FA8FF',
  cobalt: '#8FA8FF',
  cobaltLink: '#8FA8FF',
  cobaltSoft: '#1E222C',
  greenSoft: '#1E222C',
  amber: '#FF7A5C',
  amberSoft: '#1E222C',
  dangerBg: '#FF7A5C',
  danger: '#FF7A5C',
  fabText: '#12151C',
};

/** Employer palette (assigned round-robin when employers are created). */
export const EMPLOYER_PALETTE = [
  '#E8A23D',
  '#D8697D',
  '#2E8B7C',
  '#2B4BD7',
  '#7A4E8C',
] as const;

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
