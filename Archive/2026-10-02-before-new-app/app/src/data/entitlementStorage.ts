import * as SecureStore from 'expo-secure-store';

export const ENTITLEMENT_RECORD_KEY = 'protip365.entitlement.v1';

export interface StoredEntitlementRecord {
  version: 2;
  /** Immutable device-local first-launch anchor. */
  trialStartedAt: string;
  /** Highest wall-clock value observed, preventing trial extension by clock rollback. */
  lastSeenAt: string;
  lifetimeUnlocked: boolean;
  subscriptionExpiresAt: string | null;
}

interface LegacyStoredEntitlementRecord {
  version: 1;
  trialStartedAt: string;
  lastSeenAt: string;
  lifetimeUnlocked: boolean;
  subscriptionExpiresAt: string | null;
}

function validTimestamp(value: unknown): value is string {
  return typeof value === 'string' && Number.isFinite(Date.parse(value));
}

function validPurchaseFields(
  record: Partial<StoredEntitlementRecord | LegacyStoredEntitlementRecord>
): boolean {
  return (
    typeof record.lifetimeUnlocked === 'boolean' &&
    (record.subscriptionExpiresAt === null || validTimestamp(record.subscriptionExpiresAt))
  );
}

function parseRecord(
  value: string | null
): StoredEntitlementRecord | LegacyStoredEntitlementRecord | null {
  if (!value) return null;
  try {
    const record = JSON.parse(value) as Partial<
      StoredEntitlementRecord | LegacyStoredEntitlementRecord
    >;
    if (
      (record.version !== 1 && record.version !== 2) ||
      !validTimestamp(record.trialStartedAt) ||
      !validTimestamp(record.lastSeenAt) ||
      !validPurchaseFields(record)
    ) {
      return null;
    }
    return record as StoredEntitlementRecord | LegacyStoredEntitlementRecord;
  } catch {
    return null;
  }
}

/**
 * Version 1 shipped while enforcement was disabled. On its one-time migration,
 * start a fair 30-day trial at the greatest wall-clock value already observed,
 * while preserving purchases for immediate store reconciliation.
 */
export function migrateEntitlementRecord(
  record: LegacyStoredEntitlementRecord,
  now = new Date()
): StoredEntitlementRecord {
  const observedAt = Math.max(Date.parse(record.lastSeenAt), now.getTime());
  const trialStartedAt = new Date(observedAt).toISOString();
  return {
    version: 2,
    trialStartedAt,
    lastSeenAt: trialStartedAt,
    lifetimeUnlocked: record.lifetimeUnlocked,
    subscriptionExpiresAt: record.subscriptionExpiresAt,
  };
}

export function readEntitlementRecord(now = new Date()): StoredEntitlementRecord | null {
  const record = parseRecord(SecureStore.getItem(ENTITLEMENT_RECORD_KEY));
  if (!record) return null;
  if (record.version === 2) return record;

  const migrated = migrateEntitlementRecord(record, now);
  writeEntitlementRecord(migrated);
  return migrated;
}

export function writeEntitlementRecord(record: StoredEntitlementRecord): void {
  SecureStore.setItem(ENTITLEMENT_RECORD_KEY, JSON.stringify(record));
}
