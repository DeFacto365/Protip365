import { languageForDeviceCodes } from '../language';

describe('first-launch device language', () => {
  it.each([
    [['fr'], 'fr-CA'],
    [['es'], 'es'],
    [['en'], 'en'],
    [['FR'], 'fr-CA'],
  ] as const)('maps %p to %s', (codes, expected) => {
    expect(languageForDeviceCodes(codes)).toBe(expected);
  });

  it('uses the first supported language in device preference order', () => {
    expect(languageForDeviceCodes(['de', 'es', 'fr'])).toBe('es');
  });

  it('falls back to English when no supported language exists', () => {
    expect(languageForDeviceCodes(['de', null, undefined])).toBe('en');
  });
});
