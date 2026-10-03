import { create } from 'zustand';

import {
  readEntitlementRecord,
  writeEntitlementRecord,
  type StoredEntitlementRecord,
} from '../data/entitlementStorage';
import { settingsRepo } from '../data/repositories';
import {
  canWriteBeforeEntitlementHydration,
  ENTITLEMENT_ENFORCEMENT_ENABLED,
  evaluateEntitlement,
  type EntitlementEvaluation,
  type EntitlementStatus,
} from '../domain/entitlements';
import {
  inAppPurchaseClient,
  type PurchaseEntitlement,
  type PurchaseProductId,
} from '../purchases/iap';

const TRIAL_STARTED_KEY = 'entitlementTrialStartedAt';
const LIFETIME_KEY = 'entitlementLifetimeUnlocked';
const SUBSCRIPTION_EXPIRES_KEY = 'entitlementSubscriptionExpiresAt';

interface EntitlementState {
  hydrated: boolean;
  status: EntitlementStatus;
  canWrite: boolean;
  trialStartedAt: string | null;
  trialEndsAt: string | null;
  trialDaysRemaining: number;
  hydrate: () => void;
  refresh: () => void;
  purchase: (productId: PurchaseProductId) => Promise<void>;
  restorePurchases: () => Promise<void>;
  applyStoreEntitlement: (entitlement: PurchaseEntitlement) => void;
  rehydrateAfterDataChange: () => void;
}

function removeLegacySettings(): void {
  settingsRepo.remove(TRIAL_STARTED_KEY);
  settingsRepo.remove(LIFETIME_KEY);
  settingsRepo.remove(SUBSCRIPTION_EXPIRES_KEY);
}

function createRecordFromLegacy(now: Date): StoredEntitlementRecord {
  const legacySubscription = settingsRepo.get(SUBSCRIPTION_EXPIRES_KEY);
  return {
    version: 2,
    // Legacy settings predate enforced billing. Give the same fair transition
    // trial as a version-1 SecureStore record while retaining purchases.
    trialStartedAt: now.toISOString(),
    lastSeenAt: now.toISOString(),
    lifetimeUnlocked: settingsRepo.get(LIFETIME_KEY) === '1',
    subscriptionExpiresAt:
      legacySubscription && Number.isFinite(Date.parse(legacySubscription))
        ? legacySubscription
        : null,
  };
}

function readPersisted(now = new Date()): { input: Parameters<typeof evaluateEntitlement>[0]; evaluation: EntitlementEvaluation } {
  let record = readEntitlementRecord();
  if (!record) {
    record = createRecordFromLegacy(now);
    writeEntitlementRecord(record);
  }
  removeLegacySettings();
  const observedAt = Math.max(Date.parse(record.lastSeenAt), now.getTime());
  if (observedAt !== Date.parse(record.lastSeenAt)) {
    record = { ...record, lastSeenAt: new Date(observedAt).toISOString() };
    writeEntitlementRecord(record);
  }
  const input = {
    trialStartedAt: record.trialStartedAt,
    lastSeenAt: record.lastSeenAt,
    lifetimeUnlocked: record.lifetimeUnlocked,
    subscriptionExpiresAt: record.subscriptionExpiresAt,
  };
  return { input, evaluation: evaluateEntitlement(input, now) };
}

function persistPurchase(entitlement: PurchaseEntitlement): void {
  const now = new Date();
  const record = readEntitlementRecord() ?? createRecordFromLegacy(now);
  writeEntitlementRecord({
    ...record,
    lastSeenAt: new Date(Math.max(Date.parse(record.lastSeenAt), now.getTime())).toISOString(),
    lifetimeUnlocked: entitlement.lifetimeUnlocked,
    subscriptionExpiresAt: entitlement.subscriptionExpiresAt,
  });
  removeLegacySettings();
}

function evaluatedState(now = new Date()) {
  const { input, evaluation } = readPersisted(now);
  return {
    status: evaluation.status,
    canWrite: evaluation.canWrite,
    trialStartedAt: input.trialStartedAt,
    trialEndsAt: evaluation.trialEndsAt,
    trialDaysRemaining: evaluation.trialDaysRemaining,
  };
}

export const useEntitlementStore = create<EntitlementState>((set, get) => ({
  hydrated: false,
  status: 'trial',
  canWrite: canWriteBeforeEntitlementHydration(),
  trialStartedAt: null,
  trialEndsAt: null,
  trialDaysRemaining: 30,

  hydrate: () => {
    try {
      set({ ...evaluatedState(), hydrated: true });
    } catch {
      set({
        hydrated: false,
        canWrite: canWriteBeforeEntitlementHydration(ENTITLEMENT_ENFORCEMENT_ENABLED),
      });
    }
  },
  refresh: () => {
    if (!get().hydrated) return;
    try {
      set(evaluatedState());
    } catch {
      set({
        hydrated: false,
        canWrite: canWriteBeforeEntitlementHydration(ENTITLEMENT_ENFORCEMENT_ENABLED),
      });
    }
  },
  purchase: async (productId) => {
    const entitlement = await inAppPurchaseClient.purchase(productId);
    get().applyStoreEntitlement(entitlement);
  },
  restorePurchases: async () => {
    const entitlement = await inAppPurchaseClient.restore();
    get().applyStoreEntitlement(entitlement);
  },
  applyStoreEntitlement: (entitlement) => {
    persistPurchase(entitlement);
    set(evaluatedState());
  },
  rehydrateAfterDataChange: () => {
    set({ ...evaluatedState(), hydrated: true });
  },
}));

export function assertWriteAccess(): void {
  if (!useEntitlementStore.getState().canWrite) {
    throw new Error('read_only_trial_expired');
  }
}
