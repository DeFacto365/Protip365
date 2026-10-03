export type Language = 'en' | 'fr-CA' | 'es';

/** Select the first supported device language, falling back to English. */
export function languageForDeviceCodes(
  languageCodes: readonly (string | null | undefined)[]
): Language {
  for (const languageCode of languageCodes) {
    const code = languageCode?.toLowerCase();
    if (code === 'fr') return 'fr-CA';
    if (code === 'es') return 'es';
    if (code === 'en') return 'en';
  }
  return 'en';
}
