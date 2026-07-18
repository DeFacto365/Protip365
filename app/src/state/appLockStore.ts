import { create } from 'zustand';

import {
  authenticateBiometric,
  clearAppLock,
  enablePasscode,
  getLockConfig,
  setBiometricEnabled,
  verifyPasscode,
  verifyRecoveryKey,
  type UnlockResult,
} from '../security/appLock';
import {
  issueDatabaseUnlockCapability,
  revokeDatabaseUnlockCapability,
} from '../security/databaseCapability';
import { closeDatabaseForLock } from '../data/db';

interface AppLockState {
  hydrated: boolean;
  enabled: boolean;
  biometricEnabled: boolean;
  locked: boolean;
  hydrate: () => void;
  lock: () => void;
  unlockWithPasscode: (passcode: string) => Promise<UnlockResult>;
  unlockWithRecovery: (key: string) => Promise<UnlockResult>;
  unlockWithBiometrics: (prompt: string) => Promise<boolean>;
  enable: (passcode: string) => Promise<string>;
  disable: (passcode: string) => Promise<boolean>;
  setBiometrics: (enabled: boolean, prompt: string) => Promise<boolean>;
  reset: () => void;
}

export const useAppLockStore = create<AppLockState>((set, get) => ({
  hydrated: false,
  enabled: false,
  biometricEnabled: false,
  locked: true,

  hydrate: () => {
    const config = getLockConfig();
    if (config.enabled) {
      revokeDatabaseUnlockCapability();
      closeDatabaseForLock();
    }
    set({ ...config, hydrated: true, locked: config.enabled });
  },

  lock: () => {
    if (get().enabled) {
      revokeDatabaseUnlockCapability();
      closeDatabaseForLock();
      set({ locked: true });
    }
  },

  unlockWithPasscode: async (passcode) => {
    const result = await verifyPasscode(passcode);
    if (result.ok) {
      issueDatabaseUnlockCapability();
      set({ locked: false });
    }
    return result;
  },

  unlockWithRecovery: async (key) => {
    const result = await verifyRecoveryKey(key);
    if (result.ok) {
      issueDatabaseUnlockCapability();
      set({ locked: false });
    }
    return result;
  },

  unlockWithBiometrics: async (prompt) => {
    if (!get().biometricEnabled) return false;
    const ok = await authenticateBiometric(prompt);
    if (ok) {
      issueDatabaseUnlockCapability();
      set({ locked: false });
    }
    return ok;
  },

  enable: async (passcode) => {
    const recoveryKey = await enablePasscode(passcode);
    issueDatabaseUnlockCapability();
    set({ enabled: true, biometricEnabled: false, locked: false });
    return recoveryKey;
  },

  disable: async (passcode) => {
    const result = await verifyPasscode(passcode);
    if (!result.ok) return false;
    clearAppLock();
    revokeDatabaseUnlockCapability();
    set({ enabled: false, biometricEnabled: false, locked: false });
    return true;
  },

  setBiometrics: async (enabled, prompt) => {
    const ok = await setBiometricEnabled(enabled, prompt);
    if (ok) set({ biometricEnabled: enabled });
    return ok;
  },

  reset: () => {
    clearAppLock();
    revokeDatabaseUnlockCapability();
    closeDatabaseForLock();
    set({ hydrated: true, enabled: false, biometricEnabled: false, locked: false });
  },
}));
