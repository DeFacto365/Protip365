export const STORE_SUBSCRIPTION_LEASE_MS = 72 * 60 * 60 * 1000;

export interface StoreEntitlementSnapshot {
  ownsLifetime: boolean;
  hasActiveSubscription: boolean;
  subscriptionExpirationDateMs?: number | null;
}

export interface StoreEntitlement {
  lifetimeUnlocked: boolean;
  subscriptionExpiresAt: string | null;
}

/**
 * Android's on-device billing query confirms whether a subscription is active,
 * but does not expose its server expiration timestamp. Keep a short renewable
 * lease and refresh it whenever the app returns to the foreground.
 */
export function entitlementFromStoreSnapshot(
  snapshot: StoreEntitlementSnapshot,
  now = new Date()
): StoreEntitlement {
  if (!snapshot.hasActiveSubscription) {
    return {
      lifetimeUnlocked: snapshot.ownsLifetime,
      subscriptionExpiresAt: null,
    };
  }

  const nowMs = now.getTime();
  const reportedExpiration = snapshot.subscriptionExpirationDateMs;
  const expirationMs =
    typeof reportedExpiration === 'number' &&
    Number.isFinite(reportedExpiration) &&
    reportedExpiration > nowMs
      ? reportedExpiration
      : nowMs + STORE_SUBSCRIPTION_LEASE_MS;

  return {
    lifetimeUnlocked: snapshot.ownsLifetime,
    subscriptionExpiresAt: new Date(expirationMs).toISOString(),
  };
}
