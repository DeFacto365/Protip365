export const LEGACY_BLUE_EMPLOYER_COLOR = '#2B4BD7';
export const RUST_EMPLOYER_COLOR = '#996044';

export const EMPLOYER_PALETTE = [
  '#E8A23D',
  '#D8697D',
  '#2E8B7C',
  RUST_EMPLOYER_COLOR,
  '#7A4E8C',
] as const;

export function normalizeEmployerColor(color: string): string {
  return color.toUpperCase() === LEGACY_BLUE_EMPLOYER_COLOR ? RUST_EMPLOYER_COLOR : color;
}
