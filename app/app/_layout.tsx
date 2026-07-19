import React, { useEffect } from 'react';
import { AppState, View } from 'react-native';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useTranslation } from 'react-i18next';

import '../src/i18n';
import { useTokens } from '../src/ui/tokens';
import { useEmployersStore } from '../src/state/employersStore';
import { useShiftsStore } from '../src/state/shiftsStore';
import { useSettingsStore } from '../src/state/settingsStore';
import { useTemplatesStore } from '../src/state/templatesStore';
import { useGoalsStore } from '../src/state/goalsStore';
import { useAppLockStore } from '../src/state/appLockStore';
import { LockScreen } from '../src/ui/LockScreen';
import { useEntitlementStore } from '../src/state/entitlementStore';

export const unstable_settings = {
  initialRouteName: '(tabs)',
};

export default function RootLayout() {
  const { t, isDark } = useTokens();
  const { t: tr } = useTranslation();
  const hydrateSettings = useSettingsStore((s) => s.hydrate);
  const loadEmployers = useEmployersStore((s) => s.load);
  const employersLoaded = useEmployersStore((s) => s.loaded);
  const employerCount = useEmployersStore((s) => s.employers.length);
  const settingsHydrated = useSettingsStore((s) => s.hydrated);
  const loadShifts = useShiftsStore((s) => s.load);
  const loadTemplates = useTemplatesStore((s) => s.load);
  const loadGoals = useGoalsStore((s) => s.load);
  const lockHydrated = useAppLockStore((state) => state.hydrated);
  const lockEnabled = useAppLockStore((state) => state.enabled);
  const locked = useAppLockStore((state) => state.locked);
  const hydrateLock = useAppLockStore((state) => state.hydrate);
  const lock = useAppLockStore((state) => state.lock);
  const hydrateEntitlement = useEntitlementStore((state) => state.hydrate);
  const refreshEntitlement = useEntitlementStore((state) => state.refresh);
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    hydrateLock();
  }, [hydrateLock]);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', (state) => {
      if (lockEnabled && state !== 'active') lock();
      if (state === 'active') refreshEntitlement();
    });
    return () => subscription.remove();
  }, [lock, lockEnabled, refreshEntitlement]);

  useEffect(() => {
    if (!lockHydrated || locked) return;
    hydrateSettings();
    loadEmployers();
    void loadShifts();
    loadTemplates();
    loadGoals();
    hydrateEntitlement();
  }, [hydrateSettings, loadEmployers, loadShifts, loadTemplates, loadGoals, hydrateEntitlement, lockHydrated, locked]);

  useEffect(() => {
    if (!settingsHydrated || !employersLoaded || employerCount > 0) return;
    if (segments[0] !== 'onboarding') router.replace('/onboarding');
  }, [employerCount, employersLoaded, router, segments, settingsHydrated]);

  if (!lockHydrated) return <View style={{ flex: 1, backgroundColor: t.bg }} />;
  if (locked) return <LockScreen />;
  if (!settingsHydrated || !employersLoaded) {
    return <View style={{ flex: 1, backgroundColor: t.bg }} />;
  }

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
        <Stack.Screen name="onboarding" options={{ headerShown: false, gestureEnabled: false }} />
        <Stack.Screen
          name="shift-form"
          options={{ presentation: 'modal', title: tr('shiftForm.addTitle') }}
        />
        <Stack.Screen
          name="complete/[id]"
          options={{ presentation: 'modal', title: tr('complete.title') }}
        />
        <Stack.Screen name="employers" options={{ title: tr('employers.title') }} />
        <Stack.Screen name="templates" options={{ title: tr('templates.title') }} />
        <Stack.Screen name="security" options={{ title: tr('security.title') }} />
        <Stack.Screen name="backup" options={{ title: tr('backup.title') }} />
        <Stack.Screen name="paywall" options={{ title: tr('paywall.title') }} />
      </Stack>
    </>
  );
}
