import { describe, expect, it } from "vitest";
import { mapStoreStateToEntitlement, refreshSubscriptionState, restoreSandboxPurchase } from "./subscriptionStatus";

describe("subscriptionStatus", () => {
  it("maps store states to entitlement states", () => {
    expect(mapStoreStateToEntitlement({ state: "active" })).toBe("premium");
    expect(mapStoreStateToEntitlement({ state: "trial" })).toBe("trial");
    expect(mapStoreStateToEntitlement({ state: "expired" })).toBe("expired");
    expect(mapStoreStateToEntitlement({ state: "canceled" })).toBe("expired");
    expect(mapStoreStateToEntitlement({ state: "unknown" })).toBe("unknown");
  });

  it("expires active and trial subscriptions during sync", () => {
    expect(
      refreshSubscriptionState(
        {
          expiresAt: "2026-05-01T00:00:00.000Z",
          state: "trial",
        },
        "2026-05-10T00:00:00.000Z",
      ),
    ).toMatchObject({
      state: "expired",
    });
  });

  it("keeps non-expired subscriptions active during sync", () => {
    expect(
      refreshSubscriptionState(
        {
          expiresAt: "2026-06-01T00:00:00.000Z",
          state: "active",
        },
        "2026-05-10T00:00:00.000Z",
      ),
    ).toMatchObject({
      lastSyncedAt: "2026-05-10T00:00:00.000Z",
      state: "active",
    });
  });

  it("restores sandbox purchases when a product is found", () => {
    expect(
      restoreSandboxPurchase({
        productId: "protip365_premium_monthly",
        restored: true,
      }),
    ).toMatchObject({
      productId: "protip365_premium_monthly",
      state: "active",
    });
    expect(
      restoreSandboxPurchase({
        restored: false,
      }),
    ).toEqual({
      state: "unknown",
    });
  });
});
