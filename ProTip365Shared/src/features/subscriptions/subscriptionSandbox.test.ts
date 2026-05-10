import { describe, expect, it } from "vitest";
import { getSandboxProducts, nativeStoreReadiness, simulateSandboxPurchase } from "./subscriptionSandbox";

describe("subscriptionSandbox", () => {
  it("exposes iOS and Android sandbox products", () => {
    expect(getSandboxProducts("ios")).toHaveLength(2);
    expect(getSandboxProducts("android")).toHaveLength(2);
  });

  it("starts trial entitlement on successful sandbox purchase", () => {
    expect(
      simulateSandboxPurchase({
        outcome: "success",
        productId: "protip365_premium_monthly",
      }),
    ).toEqual({
      productId: "protip365_premium_monthly",
      status: "trial",
    });
  });

  it("handles canceled and failed purchases gracefully", () => {
    expect(
      simulateSandboxPurchase({
        outcome: "canceled",
        productId: "protip365_premium_monthly",
      }),
    ).toMatchObject({
      status: "free",
    });
    expect(
      simulateSandboxPurchase({
        outcome: "error",
        productId: "protip365_premium_yearly",
      }),
    ).toMatchObject({
      status: "unknown",
    });
  });

  it("documents native store blockers as explicit readiness checks", () => {
    expect(
      nativeStoreReadiness({
        hasDevelopmentBuild: false,
        hasProductsConfigured: false,
        hasSandboxTester: false,
      }),
    ).toMatchObject({
      ready: false,
    });
    expect(
      nativeStoreReadiness({
        hasDevelopmentBuild: true,
        hasProductsConfigured: true,
        hasSandboxTester: true,
      }),
    ).toEqual({
      blockers: [],
      ready: true,
    });
  });
});
