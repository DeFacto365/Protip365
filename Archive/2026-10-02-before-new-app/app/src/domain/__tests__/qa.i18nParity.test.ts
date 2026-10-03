/**
 * QA static check — TP-071 / TP-072: locale key parity across en, fr-CA, es.
 * Imports the pure locale objects (not the i18next runtime), so this runs in
 * the domain Jest environment. Lives under src/domain/__tests__ because the
 * Jest `roots` config only scans src/domain.
 */
import en from '../../i18n/en';
import frCA from '../../i18n/fr-CA';
import es from '../../i18n/es';

type Tree = { [key: string]: string | Tree };

function flattenKeys(obj: Tree, prefix = ''): string[] {
  return Object.entries(obj).flatMap(([key, value]) => {
    const path = prefix ? `${prefix}.${key}` : key;
    return typeof value === 'string' ? [path] : flattenKeys(value as Tree, path);
  });
}

function flattenEntries(obj: Tree, prefix = ''): Array<[string, string]> {
  return Object.entries(obj).flatMap(([key, value]) => {
    const path = prefix ? `${prefix}.${key}` : key;
    return typeof value === 'string'
      ? ([[path, value]] as Array<[string, string]>)
      : flattenEntries(value as Tree, path);
  });
}

const enKeys = flattenKeys(en as unknown as Tree).sort();
const frKeys = flattenKeys(frCA as unknown as Tree).sort();
const esKeys = flattenKeys(es as unknown as Tree).sort();

describe('TP-071 fr-CA key parity', () => {
  it('has exactly the same key set as en', () => {
    expect(frKeys).toEqual(enKeys);
  });

  it('has no empty values', () => {
    for (const [path, value] of flattenEntries(frCA as unknown as Tree)) {
      expect({ path, empty: value.trim() === '' }).toEqual({ path, empty: false });
    }
  });
});

describe('TP-072 es key parity', () => {
  it('has exactly the same key set as en', () => {
    expect(esKeys).toEqual(enKeys);
  });

  it('has no empty values', () => {
    for (const [path, value] of flattenEntries(es as unknown as Tree)) {
      expect({ path, empty: value.trim() === '' }).toEqual({ path, empty: false });
    }
  });
});

describe('locale sanity', () => {
  it('en has a meaningful number of keys', () => {
    expect(enKeys.length).toBeGreaterThan(50);
  });

  it('language display names stay native (never translated)', () => {
    const get = (tree: Tree, path: string): string =>
      path.split('.').reduce<Tree | string>((node, part) => (node as Tree)[part], tree) as string;
    for (const locale of [en, frCA, es] as unknown as Tree[]) {
      expect(get(locale, 'translation.settings.languages.en')).toBe('English');
      expect(get(locale, 'translation.settings.languages.fr-CA')).toBe('Français (Canada)');
      expect(get(locale, 'translation.settings.languages.es')).toBe('Español');
    }
  });
});
