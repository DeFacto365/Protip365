export interface CurrencyLocale {
  regionCode?: string | null;
}

export const SUPPORTED_CURRENCIES = ['USD', 'CAD', 'EUR', 'MXN'] as const;
export type SupportedCurrency = (typeof SUPPORTED_CURRENCIES)[number];

export const DEFAULT_CURRENCY: SupportedCurrency = 'CAD';

const CURRENCY_BY_REGION: Readonly<Record<string, SupportedCurrency>> = {
  CA: 'CAD',
  US: 'USD',
  MX: 'MXN',
  AT: 'EUR',
  BE: 'EUR',
  CY: 'EUR',
  DE: 'EUR',
  EE: 'EUR',
  ES: 'EUR',
  FI: 'EUR',
  FR: 'EUR',
  GR: 'EUR',
  HR: 'EUR',
  IE: 'EUR',
  IT: 'EUR',
  LT: 'EUR',
  LU: 'EUR',
  LV: 'EUR',
  MT: 'EUR',
  NL: 'EUR',
  PT: 'EUR',
  SI: 'EUR',
  SK: 'EUR',
};

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
  const regionCode = locales[0]?.regionCode?.trim().toUpperCase();
  return (regionCode && CURRENCY_BY_REGION[regionCode]) || DEFAULT_CURRENCY;
}

export function setActiveCurrency(code: string): void {
  const normalized = normalizeCurrencyCode(code);
  if (!normalized) throw new Error('invalid_currency_code');
  activeCurrency = normalized;
}

export function getActiveCurrency(): SupportedCurrency {
  return activeCurrency;
}
