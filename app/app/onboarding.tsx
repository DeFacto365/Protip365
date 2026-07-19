import React, { useState } from 'react';
import { Image, ScrollView, Text, View } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { parseMoneyToCents, localizedMoneyPlaceholder } from '../src/domain/money';
import type { SupportedCurrency } from '../src/domain/currency';
import { validateHourlyRateCents } from '../src/domain/validate';
import { useEmployersStore } from '../src/state/employersStore';
import { useSettingsStore, type Language } from '../src/state/settingsStore';
import { Card, Chip, Field, PrimaryButton } from '../src/ui/components';
import { CurrencyDropdown } from '../src/ui/CurrencyDropdown';
import { EMPLOYER_PALETTE, useTokens } from '../src/ui/tokens';

const LANGUAGES: Language[] = ['en', 'fr-CA', 'es'];
const WELCOME_VALUES = [
  { icon: '▦', key: 'schedule' },
  { icon: '$', key: 'tips' },
  { icon: '▣', key: 'privacy' },
] as const;

export default function OnboardingScreen() {
  const router = useRouter();
  const { t } = useTokens();
  const { t: tr, i18n } = useTranslation();
  const language = useSettingsStore((state) => state.language);
  const currencyCode = useSettingsStore((state) => state.currencyCode);
  const defaultDeductionRateBp = useSettingsStore((state) => state.defaultDeductionRateBp);
  const setLanguage = useSettingsStore((state) => state.setLanguage);
  const setCurrencyCode = useSettingsStore((state) => state.setCurrencyCode);
  const addEmployer = useEmployersStore((state) => state.addEmployer);
  const [step, setStep] = useState<0 | 1 | 2>(0);
  const [employerName, setEmployerName] = useState('');
  const [rateText, setRateText] = useState('');
  const [currencySelection, setCurrencySelection] = useState<SupportedCurrency>(currencyCode);
  const [nameError, setNameError] = useState<string | null>(null);
  const [rateError, setRateError] = useState<string | null>(null);

  const saveEmployer = () => {
    const name = employerName.trim();
    const rate = parseMoneyToCents(rateText);
    const nextNameError = name ? null : tr('onboarding.employerNameRequired');
    const nextRateError = validateHourlyRateCents(rate).valid
      ? null
      : tr('onboarding.rateRequired');
    setNameError(nextNameError);
    setRateError(nextRateError);
    if (nextNameError || nextRateError || rate == null) return;
    addEmployer({
      name,
      defaultHourlyRate: rate,
      deductionRateBp: defaultDeductionRateBp,
      color: EMPLOYER_PALETTE[0],
    });
    setStep(2);
  };

  const confirmCurrency = () => {
    setCurrencyCode(currencySelection);
    router.replace('/shift-form');
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 20, paddingTop: 48, paddingBottom: 48 }}
      keyboardShouldPersistTaps="handled"
    >
      <Stack.Screen options={{ headerShown: false, gestureEnabled: false }} />
      {step === 0 ? (
        <View style={{ alignItems: 'center', marginBottom: 20 }}>
          <Image
            source={require('../assets/splash-logo.png')}
            accessibilityLabel={tr('onboarding.logoLabel')}
            resizeMode="contain"
            style={{ width: 120, height: 120, marginBottom: 14 }}
          />
          <Text
            style={{
              color: t.ink,
              fontSize: 26,
              fontWeight: '700',
              textAlign: 'center',
            }}
          >
            {tr('onboarding.title')}
          </Text>
          <Text
            style={{
              color: t.cobalt,
              fontSize: 18,
              fontWeight: '700',
              lineHeight: 24,
              marginTop: 8,
              textAlign: 'center',
            }}
          >
            {tr('onboarding.tagline')}
          </Text>
          <View style={{ alignSelf: 'stretch', marginTop: 22, gap: 12 }}>
            {WELCOME_VALUES.map((value) => (
              <View
                key={value.key}
                style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}
              >
                <View
                  style={{
                    width: 40,
                    height: 40,
                    alignItems: 'center',
                    justifyContent: 'center',
                    backgroundColor: t.cobaltSoft,
                  }}
                >
                  <Text style={{ color: t.cobalt, fontSize: 20, fontWeight: '800' }}>
                    {value.icon}
                  </Text>
                </View>
                <Text style={{ color: t.ink, flex: 1, fontSize: 15, lineHeight: 21 }}>
                  {tr(`onboarding.values.${value.key}`)}
                </Text>
              </View>
            ))}
          </View>
        </View>
      ) : (
        <Text style={{ color: t.ink, fontSize: 26, fontWeight: '700' }}>
          {tr('onboarding.title')}
        </Text>
      )}
      <Text style={{ color: t.softText, marginTop: 6, marginBottom: 20 }}>
        {tr('onboarding.step', { current: step + 1, total: 3 })}
      </Text>

      {step === 0 ? (
        <Card style={{ padding: 16 }}>
          <Text style={{ color: t.ink, fontSize: 18, fontWeight: '700', marginBottom: 6 }}>
            {tr('onboarding.languageTitle')}
          </Text>
          <Text style={{ color: t.softText, fontSize: 13, marginBottom: 14 }}>
            {tr('onboarding.languageHint')}
          </Text>
          <View style={{ gap: 8 }}>
            {LANGUAGES.map((value) => (
              <Chip
                key={value}
                label={tr(`settings.languages.${value}`)}
                selected={language === value}
                onPress={() => setLanguage(value)}
              />
            ))}
          </View>
          <PrimaryButton
            label={tr('common.next')}
            onPress={() => setStep(1)}
            style={{ marginTop: 18 }}
          />
        </Card>
      ) : null}

      {step === 1 ? (
        <Card style={{ padding: 16 }}>
          <Text style={{ color: t.ink, fontSize: 18, fontWeight: '700', marginBottom: 6 }}>
            {tr('onboarding.employerTitle')}
          </Text>
          <Text style={{ color: t.softText, fontSize: 13, marginBottom: 14 }}>
            {tr('onboarding.employerHint')}
          </Text>
          <Field
            label={tr('shiftForm.employerName')}
            value={employerName}
            onChangeText={(value) => {
              setEmployerName(value);
              setNameError(null);
            }}
            error={nameError}
          />
          <Field
            label={tr('shiftForm.hourlyRate')}
            value={rateText}
            onChangeText={(value) => {
              setRateText(value);
              setRateError(null);
            }}
            keyboardType="decimal-pad"
            placeholder={localizedMoneyPlaceholder(i18n.language)}
            error={rateError}
          />
          <PrimaryButton label={tr('common.next')} onPress={saveEmployer} />
        </Card>
      ) : null}

      {step === 2 ? (
        <Card style={{ padding: 16 }}>
          <Text style={{ color: t.ink, fontSize: 18, fontWeight: '700', marginBottom: 6 }}>
            {tr('onboarding.currencyTitle')}
          </Text>
          <Text style={{ color: t.softText, fontSize: 13, marginBottom: 14 }}>
            {tr('onboarding.currencyHint')}
          </Text>
          <CurrencyDropdown
            label={tr('onboarding.currencyCode')}
            value={currencySelection}
            onChange={setCurrencySelection}
          />
          <PrimaryButton label={tr('onboarding.confirmCurrency')} onPress={confirmCurrency} />
        </Card>
      ) : null}
    </ScrollView>
  );
}
