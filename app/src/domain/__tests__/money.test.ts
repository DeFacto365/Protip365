import {
  centsToFixed,
  centsToInput,
  localizedMoneyPlaceholder,
  parseMoneyToCents,
} from '../money';

describe('integer minor-unit boundaries', () => {
  it('parses dot and comma decimal input without floating-point conversion', () => {
    expect(parseMoneyToCents('19.99')).toBe(1999);
    expect(parseMoneyToCents('19,99')).toBe(1999);
    expect(parseMoneyToCents('.5')).toBe(50);
  });

  it('rejects missing values and more than two decimal places', () => {
    expect(parseMoneyToCents('')).toBeNull();
    expect(parseMoneyToCents('1.005')).toBeNull();
    expect(parseMoneyToCents('nope')).toBeNull();
  });

  it('formats cents for editable fields and fixed export columns', () => {
    expect(centsToInput(1900)).toBe('19');
    expect(centsToInput(1990)).toBe('19.9');
    expect(centsToInput(1999)).toBe('19.99');
    expect(centsToFixed(-5)).toBe('-0.05');
  });

  it('uses the locale decimal separator in numeric placeholders', () => {
    expect(localizedMoneyPlaceholder('en-CA')).toBe('15.00');
    expect(localizedMoneyPlaceholder('fr-CA')).toBe('15,00');
    expect(localizedMoneyPlaceholder('es')).toBe('15,00');
  });
});
