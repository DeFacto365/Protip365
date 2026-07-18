export interface CurrencyLocale {
  currencyCode?: string | null;
}

export const DEFAULT_CURRENCY = 'CAD';

let activeCurrency = DEFAULT_CURRENCY;

export function normalizeCurrencyCode(value: string | null | undefined): string | null {
  const code = value?.trim().toUpperCase() ?? '';
  if (!/^[A-Z]{3}$/.test(code)) return null;
  try {
    new Intl.NumberFormat('en', { style: 'currency', currency: code }).format(0);
    return code;
  } catch {
    return null;
  }
}

export function currencyForLocales(locales: readonly CurrencyLocale[]): string {
  for (const locale of locales) {
    const code = normalizeCurrencyCode(locale.currencyCode);
    if (code) return code;
  }
  return DEFAULT_CURRENCY;
}

export function setActiveCurrency(code: string): void {
  const normalized = normalizeCurrencyCode(code);
  if (!normalized) throw new Error('invalid_currency_code');
  activeCurrency = normalized;
}

export function getActiveCurrency(): string {
  return activeCurrency;
}
