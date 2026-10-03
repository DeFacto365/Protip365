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

  it('uses the device region instead of locale currency metadata', () => {
    const canadianRegionWithUsdLocale = [{ regionCode: 'ca', currencyCode: 'USD' }];
    const usRegionWithCanadianLocale = [{ regionCode: 'US', currencyCode: 'CAD' }];

    expect(currencyForLocales(canadianRegionWithUsdLocale)).toBe('CAD');
    expect(currencyForLocales(usRegionWithCanadianLocale)).toBe('USD');
  });

  it('maps supported regions deterministically and otherwise defaults to CAD', () => {
    const mexicanRegion = [{ regionCode: 'MX', currencyCode: null }];
    const euroRegion = [{ regionCode: 'FR', currencyCode: null }];
    const unknownRegionWithSupportedLocaleCurrency = [
      { regionCode: 'GB', currencyCode: 'USD' },
    ];

    expect(currencyForLocales(mexicanRegion)).toBe('MXN');
    expect(currencyForLocales(euroRegion)).toBe('EUR');
    expect(currencyForLocales(unknownRegionWithSupportedLocaleCurrency)).toBe('CAD');
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
