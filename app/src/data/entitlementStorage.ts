import * as SecureStore from 'expo-secure-store';

export const ENTITLEMENT_RECORD_KEY = 'protip365.entitlement.v1';

export interface StoredEntitlementRecord {
  version: 1;
  /** Immutable device-local first-launch anchor. */
  trialStartedAt: string;
  /** Highest wall-clock value observed, preventing trial extension by clock rollback. */
  lastSeenAt: string;
  lifetimeUnlocked: boolean;
  subscriptionExpiresAt: string | null;
}

function validTimestamp(value: unknown): value is string {
  return typeof value === 'string' && Number.isFinite(Date.parse(value));
}

function parseRecord(value: string | null): StoredEntitlementRecord | null {
  if (!value) return null;
  try {
    const record = JSON.parse(value) as Partial<StoredEntitlementRecord>;
    if (
      record.version !== 1 ||
      !validTimestamp(record.trialStartedAt) ||
      !validTimestamp(record.lastSeenAt) ||
      typeof record.lifetimeUnlocked !== 'boolean' ||
      (record.subscriptionExpiresAt !== null && !validTimestamp(record.subscriptionExpiresAt))
    ) {
      return null;
    }
    return record as StoredEntitlementRecord;
  } catch {
    return null;
  }
}

export function readEntitlementRecord(): StoredEntitlementRecord | null {
  return parseRecord(SecureStore.getItem(ENTITLEMENT_RECORD_KEY));
}

export function writeEntitlementRecord(record: StoredEntitlementRecord): void {
  SecureStore.setItem(ENTITLEMENT_RECORD_KEY, JSON.stringify(record));
}
