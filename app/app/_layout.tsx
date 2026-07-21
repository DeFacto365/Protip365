import React, { useEffect } from 'react';
import { AppState, Platform, View } from 'react-native';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as Font from 'expo-font';
import * as SplashScreen from 'expo-splash-screen';
import { IBMPlexMono_400Regular } from '@expo-google-fonts/ibm-plex-mono/400Regular';
import { IBMPlexMono_500Medium } from '@expo-google-fonts/ibm-plex-mono/500Medium';
import { IBMPlexMono_600SemiBold } from '@expo-google-fonts/ibm-plex-mono/600SemiBold';
import { IBMPlexMono_700Bold } from '@expo-google-fonts/ibm-plex-mono/700Bold';
import { Fraunces_600SemiBold } from '@expo-google-fonts/fraunces/600SemiBold';
import { Fraunces_700Bold } from '@expo-google-fonts/fraunces/700Bold';
import { Caveat_600SemiBold } from '@expo-google-fonts/caveat/600SemiBold';
import { Outfit_400Regular } from '@expo-google-fonts/outfit/400Regular';
import { Outfit_500Medium } from '@expo-google-fonts/outfit/500Medium';
import { Outfit_600SemiBold } from '@expo-google-fonts/outfit/600SemiBold';
import { Outfit_700Bold } from '@expo-google-fonts/outfit/700Bold';
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
import { IapBootstrap } from '../src/purchases/IapBootstrap';
import { fonts, requiredNativeFontFamilies, TypographyProvider } from '../src/ui/typography';

void SplashScreen.preventAutoHideAsync().catch(() => undefined);

export const unstable_settings = {
  initialRouteName: '(tabs)',
};

export default function RootLayout() {
  const [webFontsLoaded, webFontError] = Font.useFonts(
    Platform.OS === 'web'
      ? {
          IBMPlexMono_400Regular,
          IBMPlexMono_500Medium,
          IBMPlexMono_600SemiBold,
          IBMPlexMono_700Bold,
          Fraunces_600SemiBold,
          Fraunces_700Bold,
          Caveat_600SemiBold,
          Outfit_400Regular,
          Outfit_500Medium,
          Outfit_600SemiBold,
          Outfit_700Bold,
        }
      : {},
  );
  const [nativeFontsLoaded, nativeFontError] = React.useMemo<[boolean, Error | null]>(() => {
    if (Platform.OS === 'web') return [true, null];

    try {
      const loadedFonts = new Set(Font.getLoadedFonts());
      const missingFonts = requiredNativeFontFamilies.filter((family) => !loadedFonts.has(family));
      return missingFonts.length === 0
        ? [true, null]
        : [false, new Error(`Missing embedded fonts: ${missingFonts.join(', ')}`)];
    } catch (error) {
      return [false, error instanceof Error ? error : new Error('Unable to read embedded fonts')];
    }
  }, []);
  const fontsLoaded = Platform.OS === 'web' ? webFontsLoaded : nativeFontsLoaded;
  const fontError = Platform.OS === 'web' ? webFontError : nativeFontError;
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
    if (fontsLoaded || fontError) void SplashScreen.hideAsync().catch(() => undefined);
  }, [fontError, fontsLoaded]);

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

  if (!fontsLoaded && !fontError) return null;

  let content: React.ReactNode;
  if (!lockHydrated) {
    content = <View style={{ flex: 1, backgroundColor: t.bg }} />;
  } else if (locked) {
    content = <LockScreen />;
  } else if (!settingsHydrated || !employersLoaded) {
    content = <View style={{ flex: 1, backgroundColor: t.bg }} />;
  } else {
    content = (
      <>
        <IapBootstrap />
        <StatusBar style={isDark ? 'light' : 'dark'} />
        <Stack
          screenOptions={{
            headerStyle: { backgroundColor: t.bg },
            headerTintColor: t.ink,
            headerTitleStyle: {
              color: t.ink,
              fontFamily: fontsLoaded ? fonts.uiSemiBold : undefined,
              fontWeight: fontsLoaded && Platform.OS === 'android' ? '600' : undefined,
            },
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

  return (
    <TypographyProvider available={fontsLoaded}>
      {content}
    </TypographyProvider>
  );
}
