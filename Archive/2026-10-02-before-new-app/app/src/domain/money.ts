/** Parse a user-entered major-unit amount into exact integer cents. */
export function parseMoneyToCents(text: string): number | null {
  const normalized = text.trim();
  const match = /^([+-]?)(\d*)(?:[.,](\d{0,2}))?$/.exec(normalized);
  if (!match || (match[2] === '' && match[3] == null)) return null;
  const whole = Number(match[2] || '0');
  const fraction = Number((match[3] ?? '').padEnd(2, '0') || '0');
  const cents = whole * 100 + fraction;
  if (!Number.isSafeInteger(cents)) return null;
  return match[1] === '-' ? -cents : cents;
}

/** Editable major-unit text without unnecessary trailing zeroes. */
export function centsToInput(cents: number | null | undefined): string {
  if (cents == null) return '';
  const sign = cents < 0 ? '-' : '';
  const absolute = Math.abs(cents);
  const whole = Math.floor(absolute / 100);
  const fraction = absolute % 100;
  if (fraction === 0) return `${sign}${whole}`;
  if (fraction % 10 === 0) return `${sign}${whole}.${fraction / 10}`;
  return `${sign}${whole}.${String(fraction).padStart(2, '0')}`;
}

/** Fixed two-decimal major-unit text for CSV/export boundaries. */
export function centsToFixed(cents: number): string {
  const sign = cents < 0 ? '-' : '';
  const absolute = Math.abs(cents);
  return `${sign}${Math.floor(absolute / 100)}.${String(absolute % 100).padStart(2, '0')}`;
}

export function localizedMoneyPlaceholder(locale: string, majorUnits = 15): string {
  return new Intl.NumberFormat(locale, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
    useGrouping: false,
  }).format(majorUnits);
}
