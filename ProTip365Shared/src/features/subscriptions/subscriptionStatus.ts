import { EntitlementStatus } from "../entitlements/entitlements";
import { SubscriptionProductId } from "./subscriptionSandbox";

export type StoreSubscriptionState = "active" | "trial" | "expired" | "canceled" | "unknown";

export type StoredSubscription = {
  productId?: SubscriptionProductId;
  state: StoreSubscriptionState;
  expiresAt?: string;
  autoRenewing?: boolean;
  lastSyncedAt?: string;
};

export function mapStoreStateToEntitlement(subscription: StoredSubscription): EntitlementStatus {
  switch (subscription.state) {
    case "active":
      return "premium";
    case "trial":
      return "trial";
    case "expired":
    case "canceled":
      return "expired";
    case "unknown":
    default:
      return "unknown";
  }
}

export function refreshSubscriptionState(subscription: StoredSubscription, nowISO: string): StoredSubscription {
  if (!subscription.expiresAt) {
    return {
      ...subscription,
      lastSyncedAt: nowISO,
    };
  }

  if (subscription.expiresAt < nowISO && (subscription.state === "active" || subscription.state === "trial")) {
    return {
      ...subscription,
      lastSyncedAt: nowISO,
      state: "expired",
    };
  }

  return {
    ...subscription,
    lastSyncedAt: nowISO,
  };
}

export function restoreSandboxPurchase({
  productId,
  restored,
}: {
  productId?: SubscriptionProductId;
  restored: boolean;
}): StoredSubscription {
  if (!restored || !productId) {
    return {
      state: "unknown",
    };
  }

  return {
    autoRenewing: true,
    productId,
    state: "active",
  };
}
