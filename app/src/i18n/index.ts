import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

import en from './en';
import frCA from './fr-CA';
import es from './es';

if (!i18n.isInitialized) {
  void i18n.use(initReactI18next).init({
    resources: {
      en,
      'fr-CA': frCA,
      es,
    },
    lng: 'en',
    fallbackLng: 'en',
    interpolation: { escapeValue: false },
    returnNull: false,
  });
}

export default i18n;
