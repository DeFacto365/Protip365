import { useColorScheme } from 'react-native';

export { EMPLOYER_PALETTE } from '../domain/employerColors';

/**
 * Calm earnings tokens — ADR-002, 2026-09-14.
 * Source: Docs/ADR-002-prelaunch-redesign.md.
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
  bg: '#F4F7F6',
  paper: '#F6F2E9',
  surface: '#FFFFFF',
  card: '#FFFFFF',
  ink: '#20211E',
  dim: '#586863',
  softText: '#586863',
  rule: '#C9C3B2',
  line: '#C9C3B2',
  red: '#B93826',
  green: '#2E7D4F',
  pen: '#086B59',
  cobalt: '#086B59',
  cobaltLink: '#086B59',
  cobaltSoft: '#F6F2E9',
  greenSoft: '#F6F2E9',
  amber: '#805900',
  amberSoft: '#FFF1CF',
  dangerBg: '#B93826',
  danger: '#B93826',
  fabText: '#F6F2E9',
};

export const dark: Tokens = {
  bg: '#141C1A',
  paper: '#202B27',
  surface: '#202B27',
  card: '#202B27',
  ink: '#F0EEE6',
  dim: '#AAA59A',
  softText: '#AAA59A',
  rule: '#716C61',
  line: '#716C61',
  red: '#FF7A5C',
  green: '#5CD69B',
  pen: '#79D8BD',
  cobalt: '#79D8BD',
  cobaltLink: '#79D8BD',
  cobaltSoft: '#202B27',
  greenSoft: '#202B27',
  amber: '#FF7A5C',
  amberSoft: '#202B27',
  dangerBg: '#FF7A5C',
  danger: '#FF7A5C',
  fabText: '#141C1A',
};

/** Minimum touch target (dp). */
export const TOUCH_TARGET = 48;

/** Shared rounded geometry; receipt detail remains distinct. */
export const radius = {
  card: 16,
  button: 12,
  chip: 12,
  field: 10,
} as const;

export function useTokens(): { t: Tokens; isDark: boolean } {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';
  return { t: isDark ? dark : light, isDark };
}
