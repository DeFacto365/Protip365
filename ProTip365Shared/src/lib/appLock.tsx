import React, { ReactNode, useEffect, useState } from "react";
import { AppState, Modal, Platform, Text, View } from "react-native";
import * as LocalAuthentication from "expo-local-authentication";
import { FormInput, PrimaryButton, styles } from "../screens/shared/screenShared";
import { supabaseSecureStorage } from "./secureStorage";

const APP_LOCK_SETTINGS_KEY = "protip365.appLock.settings";
const appLockListeners = new Set<(settings: AppLockSettings) => void>();

export type AppLockDelay = "launch" | "resume" | "five_minutes";

export type AppLockSettings = {
  biometricEnabled: boolean;
  enabled: boolean;
  lockDelay: AppLockDelay;
};

export type BiometricSupport = {
  available: boolean;
  label: string;
  reason: string | null;
};

const defaultAppLockSettings: AppLockSettings = {
  biometricEnabled: false,
  enabled: false,
  lockDelay: "resume",
};

export async function getAppLockSettings(): Promise<AppLockSettings> {
  const value = await supabaseSecureStorage.getItem(APP_LOCK_SETTINGS_KEY);

  if (!value) {
    return defaultAppLockSettings;
  }

  try {
    return { ...defaultAppLockSettings, ...JSON.parse(value) };
  } catch {
    return defaultAppLockSettings;
  }
}

export async function saveAppLockSettings(settings: AppLockSettings, pin?: string) {
  if (settings.enabled && !pin && !(await getStoredPin())) {
    throw new Error("Enter a PIN before enabling app lock.");
  }

  if (pin) {
    const normalizedPin = pin.trim();

    if (normalizedPin.length < 4) {
      throw new Error("Use at least 4 digits for your PIN.");
    }

    await supabaseSecureStorage.setItem("protip365.appLock.pin", normalizedPin);
  }

  await supabaseSecureStorage.setItem(APP_LOCK_SETTINGS_KEY, JSON.stringify(settings));
  emitAppLockSettings(settings);
}

export async function clearAppLock() {
  await Promise.all([
    supabaseSecureStorage.removeItem(APP_LOCK_SETTINGS_KEY),
    supabaseSecureStorage.removeItem("protip365.appLock.pin"),
  ]);
  emitAppLockSettings(defaultAppLockSettings);
}

export function subscribeAppLockSettings(listener: (settings: AppLockSettings) => void) {
  appLockListeners.add(listener);

  return () => {
    appLockListeners.delete(listener);
  };
}

function emitAppLockSettings(settings: AppLockSettings) {
  for (const listener of appLockListeners) {
    listener(settings);
  }
}

export async function getBiometricSupport(): Promise<BiometricSupport> {
  if (Platform.OS === "web") {
    return { available: false, label: "Biometrics unavailable", reason: "Biometric unlock is not available on web." };
  }

  try {
    const [hasHardware, isEnrolled, types] = await Promise.all([
      LocalAuthentication.hasHardwareAsync(),
      LocalAuthentication.isEnrolledAsync(),
      LocalAuthentication.supportedAuthenticationTypesAsync(),
    ]);

    if (!hasHardware) {
      return { available: false, label: "Biometrics unavailable", reason: "This device does not report biometric hardware." };
    }

    if (!isEnrolled) {
      return { available: false, label: "Biometrics not set up", reason: "Set up Face ID, Touch ID, or fingerprint unlock in device settings first." };
    }

    const label = types.includes(LocalAuthentication.AuthenticationType.FACIAL_RECOGNITION)
      ? "Face ID"
      : types.includes(LocalAuthentication.AuthenticationType.FINGERPRINT)
        ? "Fingerprint"
        : "Biometric unlock";

    return { available: true, label, reason: null };
  } catch {
    return { available: false, label: "Biometrics unavailable", reason: "Biometric unlock could not be checked on this device." };
  }
}

export function shouldLockOnResume(settings: AppLockSettings, lastUnlockedAt: number | null, now = Date.now()) {
  if (!settings.enabled) {
    return false;
  }

  if (settings.lockDelay === "launch") {
    return false;
  }

  if (settings.lockDelay === "resume") {
    return true;
  }

  return !lastUnlockedAt || now - lastUnlockedAt >= 5 * 60 * 1000;
}

async function getStoredPin() {
  return supabaseSecureStorage.getItem("protip365.appLock.pin");
}

async function authenticateWithBiometrics() {
  const result = await LocalAuthentication.authenticateAsync({
    cancelLabel: "Use PIN",
    fallbackLabel: "Use PIN",
    promptMessage: "Unlock ProTip365",
  });

  return result.success;
}

export function AppLockGate({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<AppLockSettings>(defaultAppLockSettings);
  const [isLocked, setIsLocked] = useState(false);
  const [pin, setPin] = useState("");
  const [message, setMessage] = useState("");
  const [lastUnlockedAt, setLastUnlockedAt] = useState<number | null>(null);

  useEffect(() => {
    let mounted = true;

    getAppLockSettings().then((nextSettings) => {
      if (!mounted) {
        return;
      }

      setSettings(nextSettings);
      setIsLocked(nextSettings.enabled);
    });

    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => subscribeAppLockSettings((nextSettings) => {
    setSettings(nextSettings);
    setIsLocked(nextSettings.enabled);
    setLastUnlockedAt(null);
    setPin("");
    setMessage("");
  }), []);

  useEffect(() => {
    const subscription = AppState.addEventListener("change", (state) => {
      if (state === "active" && shouldLockOnResume(settings, lastUnlockedAt)) {
        setIsLocked(true);
      }
    });

    return () => subscription.remove();
  }, [lastUnlockedAt, settings]);

  async function unlockWithPin() {
    const savedPin = await getStoredPin();

    if (!savedPin || pin.trim() !== savedPin) {
      setMessage("PIN does not match.");
      return;
    }

    setPin("");
    setMessage("");
    setLastUnlockedAt(Date.now());
    setIsLocked(false);
  }

  async function unlockWithBiometrics() {
    if (!settings.biometricEnabled) {
      return;
    }

    const success = await authenticateWithBiometrics();

    if (success) {
      setLastUnlockedAt(Date.now());
      setIsLocked(false);
    } else {
      setMessage("Biometric unlock failed. Use your PIN.");
    }
  }

  return (
    <>
      {children}
      <Modal animationType="fade" transparent visible={isLocked}>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.formTitle}>Unlock ProTip365</Text>
            {message ? <Text style={styles.body}>{message}</Text> : null}
            <FormInput keyboardType="decimal-pad" label="PIN" onChangeText={setPin} placeholder="Enter PIN" value={pin} />
            {settings.biometricEnabled ? <PrimaryButton label="Use biometrics" onPress={unlockWithBiometrics} /> : null}
            <PrimaryButton label="Unlock" onPress={unlockWithPin} />
          </View>
        </View>
      </Modal>
    </>
  );
}
