import {
  entitlementFromStoreSnapshot,
  STORE_SUBSCRIPTION_LEASE_MS,
} from '../storeEntitlements';

const now = new Date('2026-07-19T12:00:00.000Z');

describe('store entitlement mapping', () => {
  it('restores a durable lifetime purchase', () => {
    expect(
      entitlementFromStoreSnapshot(
        { ownsLifetime: true, hasActiveSubscription: false },
        now
      )
    ).toEqual({ lifetimeUnlocked: true, subscriptionExpiresAt: null });
  });

  it('uses the store-reported subscription expiration when available', () => {
    expect(
      entitlementFromStoreSnapshot(
        {
          ownsLifetime: false,
          hasActiveSubscription: true,
          subscriptionExpirationDateMs: Date.parse('2026-08-19T12:00:00.000Z'),
        },
        now
      )
    ).toEqual({
      lifetimeUnlocked: false,
      subscriptionExpiresAt: '2026-08-19T12:00:00.000Z',
    });
  });

  it('uses a renewable lease when Android confirms access without an expiration', () => {
    const entitlement = entitlementFromStoreSnapshot(
      { ownsLifetime: false, hasActiveSubscription: true },
      now
    );

    expect(Date.parse(entitlement.subscriptionExpiresAt!)).toBe(
      now.getTime() + STORE_SUBSCRIPTION_LEASE_MS
    );
  });

  it('revokes a subscription when the store no longer reports it active', () => {
    expect(
      entitlementFromStoreSnapshot(
        {
          ownsLifetime: false,
          hasActiveSubscription: false,
          subscriptionExpirationDateMs: Date.parse('2026-08-19T12:00:00.000Z'),
        },
        now
      )
    ).toEqual({ lifetimeUnlocked: false, subscriptionExpiresAt: null });
  });
});
