export interface CurrencyLocale {
  currencyCode?: string | null;
}

export const SUPPORTED_CURRENCIES = ['USD', 'CAD', 'EUR', 'MXN'] as const;
export type SupportedCurrency = (typeof SUPPORTED_CURRENCIES)[number];

export const DEFAULT_CURRENCY: SupportedCurrency = 'CAD';

let activeCurrency: SupportedCurrency = DEFAULT_CURRENCY;

export function normalizeCurrencyCode(
  value: string | null | undefined
): SupportedCurrency | null {
  const code = value?.trim().toUpperCase() ?? '';
  return SUPPORTED_CURRENCIES.includes(code as SupportedCurrency)
    ? (code as SupportedCurrency)
    : null;
}

export function currencyForLocales(locales: readonly CurrencyLocale[]): SupportedCurrency {
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

export function getActiveCurrency(): SupportedCurrency {
  return activeCurrency;
}
