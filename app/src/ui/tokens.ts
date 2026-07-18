import { useColorScheme } from 'react-native';

/**
 * Design tokens — owner-approved mockups rev 3
 * (Docs/design/explorations/app-mockups/claude/index.html).
 */

export interface Tokens {
  bg: string;
  surface: string;
  card: string;
  line: string;
  ink: string;
  softText: string;
  /** Primary action color (buttons). */
  cobalt: string;
  /** Link/accent color (same as cobalt in light mode). */
  cobaltLink: string;
  cobaltSoft: string;
  /** Confirmed money ONLY. */
  green: string;
  greenSoft: string;
  /** Pending amounts. */
  amber: string;
  amberSoft: string;
  /** Destructive background/border; `danger` remains a text foreground. */
  dangerBg: string;
  danger: string;
  fabText: string;
}

export const light: Tokens = {
  bg: '#FFFFFF',
  surface: '#E8E7F7',
  card: '#E8E7F7',
  line: '#D9D8EC',
  ink: '#23242E',
  softText: '#63667A',
  cobalt: '#2B4BD7',
  cobaltLink: '#2B4BD7',
  cobaltSoft: '#D9E1FC',
  green: '#1E7A5A',
  greenSoft: '#DFF0E8',
  amber: '#C97A10',
  amberSoft: '#F7E8D2',
  dangerBg: '#B3362B',
  danger: '#B3362B',
  fabText: '#FFFFFF',
};

export const dark: Tokens = {
  bg: '#0E1118',
  surface: '#161A26',
  card: '#1D2231',
  line: '#2B3144',
  // Owner direction: ALL text white in dark mode.
  ink: '#FFFFFF',
  softText: '#FFFFFF',
  cobalt: '#4C67E8', // buttons
  cobaltLink: '#FFFFFF',
  cobaltSoft: '#2B4BD7',
  green: '#FFFFFF',
  greenSoft: '#1E7A5A',
  amber: '#FFFFFF',
  amberSoft: '#875008',
  dangerBg: '#B3362B',
  danger: '#FFFFFF',
  fabText: '#FFFFFF',
};

/** Employer palette (assigned round-robin when employers are created). */
export const EMPLOYER_PALETTE = [
  '#E8A23D', // amber
  '#D8697D', // rose
  '#2E8B7C', // teal
  '#2B4BD7', // cobalt
  '#7A4E8C', // violet
] as const;

/** Minimum touch target (dp). */
export const TOUCH_TARGET = 48;

/** Owner directive 2026-07-18 (PRD §15 updated): no rounded corners anywhere. */
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
