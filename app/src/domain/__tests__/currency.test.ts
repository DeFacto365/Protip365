import {
  currencyForLocales,
  DEFAULT_CURRENCY,
  getActiveCurrency,
  normalizeCurrencyCode,
  SUPPORTED_CURRENCIES,
  setActiveCurrency,
} from '../currency';

describe('currency selection', () => {
  afterEach(() => setActiveCurrency(DEFAULT_CURRENCY));

  it('uses the first valid device-locale ISO currency and otherwise defaults to CAD', () => {
    expect(currencyForLocales([{ currencyCode: null }, { currencyCode: 'usd' }])).toBe('USD');
    expect(currencyForLocales([{ currencyCode: 'GBP' }])).toBe('CAD');
    expect(currencyForLocales([])).toBe('CAD');
  });

  it('normalizes persisted codes and updates the in-memory formatter currency', () => {
    expect(normalizeCurrencyCode(' eur ')).toBe('EUR');
    expect(normalizeCurrencyCode('EU')).toBeNull();
    expect(normalizeCurrencyCode('GBP')).toBeNull();
    expect(SUPPORTED_CURRENCIES).toEqual(['USD', 'CAD', 'EUR', 'MXN']);
    setActiveCurrency('USD');
    expect(getActiveCurrency()).toBe('USD');
    expect(() => setActiveCurrency('US')).toThrow('invalid_currency_code');
  });
});
