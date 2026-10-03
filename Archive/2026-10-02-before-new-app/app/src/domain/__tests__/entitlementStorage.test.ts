jest.mock('expo-secure-store', () => ({
  getItem: jest.fn(),
  setItem: jest.fn(),
}));

import * as SecureStore from 'expo-secure-store';
import {
  ENTITLEMENT_RECORD_KEY,
  migrateEntitlementRecord,
  readEntitlementRecord,
} from '../../data/entitlementStorage';

const secureStore = SecureStore as jest.Mocked<typeof SecureStore>;
const migrationTime = new Date('2026-08-03T12:00:00.000Z');

beforeEach(() => {
  jest.clearAllMocks();
});

describe('entitlement record version 2', () => {
  it('gives a version-1 install a fresh trial and preserves purchases', () => {
    const migrated = migrateEntitlementRecord(
      {
        version: 1,
        trialStartedAt: '2026-07-01T00:00:00.000Z',
        lastSeenAt: '2026-07-20T00:00:00.000Z',
        lifetimeUnlocked: true,
        subscriptionExpiresAt: '2026-08-20T00:00:00.000Z',
      },
      migrationTime
    );

    expect(migrated).toEqual({
      version: 2,
      trialStartedAt: migrationTime.toISOString(),
      lastSeenAt: migrationTime.toISOString(),
      lifetimeUnlocked: true,
      subscriptionExpiresAt: '2026-08-20T00:00:00.000Z',
    });
  });

  it('uses the greatest observed time so clock rollback cannot extend migration', () => {
    const future = '2026-08-10T00:00:00.000Z';
    const migrated = migrateEntitlementRecord(
      {
        version: 1,
        trialStartedAt: '2026-07-01T00:00:00.000Z',
        lastSeenAt: future,
        lifetimeUnlocked: false,
        subscriptionExpiresAt: null,
      },
      migrationTime
    );

    expect(migrated.trialStartedAt).toBe(future);
    expect(migrated.lastSeenAt).toBe(future);
  });

  it('persists a one-time migration and returns version 2 thereafter', () => {
    secureStore.getItem.mockReturnValue(
      JSON.stringify({
        version: 1,
        trialStartedAt: '2026-07-01T00:00:00.000Z',
        lastSeenAt: '2026-07-20T00:00:00.000Z',
        lifetimeUnlocked: false,
        subscriptionExpiresAt: null,
      })
    );

    const result = readEntitlementRecord(migrationTime);

    expect(result?.version).toBe(2);
    expect(secureStore.setItem).toHaveBeenCalledWith(
      ENTITLEMENT_RECORD_KEY,
      JSON.stringify(result)
    );
  });

  it('does not rewrite a valid version-2 record', () => {
    const record = {
      version: 2 as const,
      trialStartedAt: migrationTime.toISOString(),
      lastSeenAt: migrationTime.toISOString(),
      lifetimeUnlocked: false,
      subscriptionExpiresAt: null,
    };
    secureStore.getItem.mockReturnValue(JSON.stringify(record));

    expect(readEntitlementRecord(migrationTime)).toEqual(record);
    expect(secureStore.setItem).not.toHaveBeenCalled();
  });
});
