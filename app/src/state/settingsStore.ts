import { create } from 'zustand';
import { getLocales } from 'expo-localization';
import i18n from '../i18n';
import { settingsRepo } from '../data/repositories';
import { eraseAllData } from '../data/db';

export type Language = 'en' | 'fr-CA' | 'es';

const LANGUAGE_KEY = 'language';
// DEF-14: value is integer basis points (0–10000); key renamed so any stale
// pre-release fraction value is simply ignored rather than misread.
const DEDUCTION_KEY = 'defaultDeductionRateBp';

/** Item 1: first-launch language from the device locale (PRD §14), fallback en. */
function detectDeviceLanguage(): Language {
  try {
    const first = getLocales()[0];
    const code = first?.languageCode ?? '';
    if (code === 'fr') return 'fr-CA';
    if (code === 'es') return 'es';
  } catch {
    // Localization unavailable (e.g. tests) — fall through to English.
  }
  return 'en';
}

interface SettingsState {
  language: Language;
  /** Default deduction rate as a fraction (0–1). */
  defaultDeductionRate: number;
  hydrated: boolean;
  hydrate: () => void;
  setLanguage: (language: Language) => void;
  setDefaultDeductionRate: (rate: number) => void;
  eraseAll: () => void;
}

export const useSettingsStore = create<SettingsState>((set) => ({
  language: 'en',
  defaultDeductionRate: 0,
  hydrated: false,

  hydrate: () => {
    const storedLang = settingsRepo.get(LANGUAGE_KEY) as Language | null;
    const storedBp = settingsRepo.get(DEDUCTION_KEY);
    const language: Language =
      storedLang === 'fr-CA' || storedLang === 'es' || storedLang === 'en'
        ? storedLang
        : detectDeviceLanguage();
    // DEF-14: persisted as integer basis points (0–10000); exposed as fraction.
    const bp = storedBp != null ? Number(storedBp) : 0;
    void i18n.changeLanguage(language);
    set({
      language,
      defaultDeductionRate: Number.isFinite(bp)
        ? Math.round(Math.min(Math.max(bp, 0), 10000)) / 10000
        : 0,
      hydrated: true,
    });
  },

  setLanguage: (language) => {
    settingsRepo.set(LANGUAGE_KEY, language);
    void i18n.changeLanguage(language);
    set({ language });
  },

  setDefaultDeductionRate: (rate) => {
    // DEF-14: store integer basis points, expose the fraction.
    const bp = Math.round(Math.min(Math.max(rate, 0), 1) * 10000);
    settingsRepo.set(DEDUCTION_KEY, String(bp));
    set({ defaultDeductionRate: bp / 10000 });
  },

  eraseAll: () => {
    eraseAllData();
    set({ language: 'en', defaultDeductionRate: 0 });
    void i18n.changeLanguage('en');
  },
}));
