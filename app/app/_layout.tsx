import React, { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useTranslation } from 'react-i18next';

import '../src/i18n';
import { useTokens } from '../src/ui/tokens';
import { useEmployersStore } from '../src/state/employersStore';
import { useShiftsStore } from '../src/state/shiftsStore';
import { useSettingsStore } from '../src/state/settingsStore';

export default function RootLayout() {
  const { t, isDark } = useTokens();
  const { t: tr } = useTranslation();
  const hydrateSettings = useSettingsStore((s) => s.hydrate);
  const loadEmployers = useEmployersStore((s) => s.load);
  const loadShifts = useShiftsStore((s) => s.load);

  useEffect(() => {
    hydrateSettings();
    loadEmployers();
    loadShifts();
  }, [hydrateSettings, loadEmployers, loadShifts]);

  return (
    <>
      <StatusBar style={isDark ? 'light' : 'dark'} />
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: t.bg },
          headerTintColor: t.ink,
          headerTitleStyle: { color: t.ink },
          contentStyle: { backgroundColor: t.bg },
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="shift-form"
          options={{ presentation: 'modal', title: tr('shiftForm.addTitle') }}
        />
        <Stack.Screen
          name="complete/[id]"
          options={{ presentation: 'modal', title: tr('complete.title') }}
        />
      </Stack>
    </>
  );
}
