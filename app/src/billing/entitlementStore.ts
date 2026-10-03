import { create } from 'zustand';
import { readEntitlementRecord, writeEntitlementRecord } from './entitlementStorage';
import { evaluateEntitlement, type EntitlementEvaluation } from './entitlements';
import { inAppPurchaseClient, type PurchaseEntitlement, type PurchaseProductId } from './iap';

type Access = EntitlementEvaluation & {
  hydrated: boolean;
  hydrate: () => void;
  refresh: () => void;
  applyStoreEntitlement: (value: PurchaseEntitlement) => void;
  purchase: (id: PurchaseProductId) => Promise<void>;
  restorePurchases: () => Promise<void>;
};
function record() {
  const now = new Date().toISOString();
  const existing = readEntitlementRecord();
  const value = existing ?? {version: 2 as const, trialStartedAt: now, lastSeenAt: now,
    lifetimeUnlocked: false, subscriptionExpiresAt: null};
  value.lastSeenAt = new Date(Math.max(Date.parse(value.lastSeenAt), Date.now())).toISOString();
  writeEntitlementRecord(value);
  return value;
}
export const useEntitlementStore = create<Access>((set, get) => ({
  hydrated: false, status: 'expired', canWrite: false, trialEndsAt: '', trialDaysRemaining: 0,
  hydrate: () => {
    try { set({...evaluateEntitlement(record()), hydrated: true}); }
    catch { set({hydrated: false, canWrite: false}); }
  },
  refresh: () => get().hydrate(),
  applyStoreEntitlement: (value) => {
    writeEntitlementRecord({...record(), ...value});
    get().refresh();
  },
  purchase: async (id) => get().applyStoreEntitlement(await inAppPurchaseClient.purchase(id)),
  restorePurchases: async () => get().applyStoreEntitlement(await inAppPurchaseClient.restore()),
}));
