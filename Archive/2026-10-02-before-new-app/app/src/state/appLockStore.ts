import { create } from 'zustand';
import { AppState, type AppStateStatus } from 'react-native';

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
import {
  nextSystemPromptDepth,
  shouldLockAfterSystemPrompt,
  systemPromptFinishAction,
} from '../security/appLifecycle';

const SYSTEM_PROMPT_RETURN_GRACE_MS = 750;
let systemPromptReturnTimer: ReturnType<typeof setTimeout> | null = null;

function clearSystemPromptReturnTimer() {
  if (systemPromptReturnTimer == null) return;
  clearTimeout(systemPromptReturnTimer);
  systemPromptReturnTimer = null;
}

interface AppLockState {
  hydrated: boolean;
  enabled: boolean;
  biometricEnabled: boolean;
  locked: boolean;
  systemPromptOpen: boolean;
  systemPromptDepth: number;
  hydrate: () => void;
  lock: () => void;
  unlockWithPasscode: (passcode: string) => Promise<UnlockResult>;
  unlockWithRecovery: (key: string) => Promise<UnlockResult>;
  unlockWithBiometrics: (prompt: string) => Promise<boolean>;
  enable: (passcode: string) => Promise<string>;
  disable: (passcode: string) => Promise<boolean>;
  setBiometrics: (enabled: boolean, prompt: string) => Promise<boolean>;
  reset: () => Promise<void>;
  beginSystemPrompt: () => void;
  finishSystemPrompt: () => void;
  resolveFinishedSystemPrompt: (currentState: AppStateStatus) => void;
}

export const useAppLockStore = create<AppLockState>((set, get) => ({
  hydrated: false,
  enabled: false,
  biometricEnabled: false,
  locked: true,
  systemPromptOpen: false,
  systemPromptDepth: 0,

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
    await clearAppLock();
    clearSystemPromptReturnTimer();
    revokeDatabaseUnlockCapability();
    set({ enabled: false, biometricEnabled: false, locked: false });
    return true;
  },

  setBiometrics: async (enabled, prompt) => {
    const ok = await setBiometricEnabled(enabled, prompt);
    if (ok) set({ biometricEnabled: enabled });
    return ok;
  },

  reset: async () => {
    await clearAppLock();
    clearSystemPromptReturnTimer();
    revokeDatabaseUnlockCapability();
    closeDatabaseForLock();
    set({ hydrated: true, enabled: false, biometricEnabled: false, locked: false, systemPromptOpen: false, systemPromptDepth: 0 });
  },

  beginSystemPrompt: () => {
    clearSystemPromptReturnTimer();
    const systemPromptDepth = nextSystemPromptDepth(get().systemPromptDepth, true);
    set({ systemPromptDepth, systemPromptOpen: true });
  },
  finishSystemPrompt: () => {
    const state = get();
    if (state.systemPromptDepth === 0) return;
    const systemPromptDepth = nextSystemPromptDepth(state.systemPromptDepth, false);
    if (systemPromptDepth > 0) {
      set({ systemPromptDepth });
      return;
    }
    set({ systemPromptDepth: 0 });
    get().resolveFinishedSystemPrompt(AppState.currentState);
    const resolvedState = get();
    if (!resolvedState.systemPromptOpen || resolvedState.systemPromptDepth > 0) return;
    systemPromptReturnTimer = setTimeout(() => {
      systemPromptReturnTimer = null;
      const promptState = get();
      if (!promptState.systemPromptOpen || promptState.systemPromptDepth > 0) return;
      set({ systemPromptOpen: false });
      if (shouldLockAfterSystemPrompt(AppState.currentState, promptState.enabled)) {
        promptState.lock();
      }
    }, SYSTEM_PROMPT_RETURN_GRACE_MS);
  },
  resolveFinishedSystemPrompt: (currentState) => {
    const state = get();
    if (state.systemPromptDepth > 0) return;
    const action = systemPromptFinishAction(currentState, state.enabled);
    if (action === 'wait') return;
    clearSystemPromptReturnTimer();
    set({ systemPromptOpen: false });
    if (action === 'lock') get().lock();
  },
}));

export async function withAppLockSystemPrompt<T>(operation: () => Promise<T>): Promise<T> {
  useAppLockStore.getState().beginSystemPrompt();
  try {
    return await operation();
  } finally {
    useAppLockStore.getState().finishSystemPrompt();
  }
}
