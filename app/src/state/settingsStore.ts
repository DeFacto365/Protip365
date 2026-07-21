import { create } from 'zustand';
import { getLocales } from 'expo-localization';
import i18n from '../i18n';
import { settingsRepo } from '../data/repositories';
import { eraseAllData } from '../data/db';
import { languageForDeviceCodes, type Language } from '../domain/language';
import { validateDeductionBasisPoints } from '../domain/validate';
import { cancelAllAppOwnedNotificationsBestEffort } from '../notifications/shiftReminders';
import {
  currencyForLocales,
  DEFAULT_CURRENCY,
  normalizeCurrencyCode,
  setActiveCurrency,
  type SupportedCurrency,
} from '../domain/currency';

export type { Language } from '../domain/language';

const LANGUAGE_KEY = 'language';
const CURRENCY_KEY = 'currencyCode';
// DEF-14: value is integer basis points (0–10000); key renamed so any stale
// pre-release fraction value is simply ignored rather than misread.
const DEDUCTION_KEY = 'defaultDeductionRateBp';
const REMINDER_ENABLED_KEY = 'postShiftReminderEnabled';
const REMINDER_DELAY_KEY = 'postShiftReminderDelayMinutes';

/** Item 1: first-launch language from the device locale (PRD §14), fallback en. */
function detectDeviceLanguage(): Language {
  try {
    return languageForDeviceCodes(getLocales().map((locale) => locale.languageCode));
  } catch {
    // Localization unavailable (e.g. tests) — fall through to English.
  }
  return 'en';
}

function detectDeviceCurrency(): SupportedCurrency {
  try {
    return currencyForLocales(getLocales());
  } catch {
    return DEFAULT_CURRENCY;
  }
}

interface SettingsState {
  language: Language;
  currencyCode: SupportedCurrency;
  /** Default deduction rate as integer basis points (0–10000). */
  defaultDeductionRateBp: number;
  postShiftReminderEnabled: boolean;
  postShiftReminderDelayMinutes: number;
  hydrated: boolean;
  hydrate: () => void;
  setLanguage: (language: Language) => void;
  setCurrencyCode: (currencyCode: SupportedCurrency) => void;
  setDefaultDeductionRateBp: (basisPoints: number) => void;
  setPostShiftReminderEnabled: (enabled: boolean) => void;
  setPostShiftReminderDelayMinutes: (minutes: number) => void;
  eraseAll: () => Promise<void>;
}

export const useSettingsStore = create<SettingsState>((set) => ({
  language: 'en',
  currencyCode: DEFAULT_CURRENCY,
  defaultDeductionRateBp: 0,
  postShiftReminderEnabled: false,
  postShiftReminderDelayMinutes: 120,
  hydrated: false,

  hydrate: () => {
    const storedLang = settingsRepo.get(LANGUAGE_KEY) as Language | null;
    const storedCurrency = normalizeCurrencyCode(settingsRepo.get(CURRENCY_KEY));
    const storedBp = settingsRepo.get(DEDUCTION_KEY);
    const reminderEnabled = settingsRepo.get(REMINDER_ENABLED_KEY) === '1';
    const storedDelay = Number(settingsRepo.get(REMINDER_DELAY_KEY) ?? 120);
    const language: Language =
      storedLang === 'fr-CA' || storedLang === 'es' || storedLang === 'en'
        ? storedLang
        : detectDeviceLanguage();
    const currencyCode = storedCurrency ?? detectDeviceCurrency();
    if (!storedCurrency) settingsRepo.set(CURRENCY_KEY, currencyCode);
    setActiveCurrency(currencyCode);
    // DEF-14: persisted and exposed as integer basis points (0–10000).
    const bp = storedBp != null ? Number(storedBp) : 0;
    void i18n.changeLanguage(language);
    set({
      language,
      currencyCode,
      defaultDeductionRateBp: validateDeductionBasisPoints(bp).valid ? bp : 0,
      postShiftReminderEnabled: reminderEnabled,
      postShiftReminderDelayMinutes: Number.isFinite(storedDelay)
        ? Math.min(Math.max(Math.round(storedDelay), 0), 1440)
        : 120,
      hydrated: true,
    });
  },

  setLanguage: (language) => {
    settingsRepo.set(LANGUAGE_KEY, language);
    void i18n.changeLanguage(language);
    set({ language });
  },

  setCurrencyCode: (currencyCode) => {
    const normalized = normalizeCurrencyCode(currencyCode);
    if (!normalized) throw new Error('invalid_currency_code');
    settingsRepo.set(CURRENCY_KEY, normalized);
    setActiveCurrency(normalized);
    set({ currencyCode: normalized });
  },

  setDefaultDeductionRateBp: (basisPoints) => {
    if (!validateDeductionBasisPoints(basisPoints).valid) {
      throw new Error('deduction_out_of_range');
    }
    settingsRepo.set(DEDUCTION_KEY, String(basisPoints));
    set({ defaultDeductionRateBp: basisPoints });
  },

  setPostShiftReminderEnabled: (enabled) => {
    settingsRepo.set(REMINDER_ENABLED_KEY, enabled ? '1' : '0');
    set({ postShiftReminderEnabled: enabled });
  },

  setPostShiftReminderDelayMinutes: (minutes) => {
    const value = Math.min(Math.max(Math.round(minutes), 0), 1440);
    settingsRepo.set(REMINDER_DELAY_KEY, String(value));
    set({ postShiftReminderDelayMinutes: value });
  },

  eraseAll: async () => {
    cancelAllAppOwnedNotificationsBestEffort();
    await eraseAllData();
    const currencyCode = detectDeviceCurrency();
    settingsRepo.set(CURRENCY_KEY, currencyCode);
    set({
      language: 'en',
      currencyCode,
      defaultDeductionRateBp: 0,
      postShiftReminderEnabled: false,
      postShiftReminderDelayMinutes: 120,
    });
    setActiveCurrency(currencyCode);
    void i18n.changeLanguage('en');
  },
}));
