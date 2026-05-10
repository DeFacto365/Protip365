import { EntitlementStatus } from "../entitlements/entitlements";

export type StorePlatform = "ios" | "android";
export type SubscriptionProductId = "protip365_premium_monthly" | "protip365_premium_yearly";
export type PurchaseOutcome = "success" | "canceled" | "error";

export type SubscriptionProduct = {
  id: SubscriptionProductId;
  platform: StorePlatform;
  title: string;
  trialDays: number;
  priceLabel: string;
};

export type PurchaseResult = {
  status: EntitlementStatus;
  productId?: SubscriptionProductId;
  errorMessage?: string;
};

export const sandboxProducts: SubscriptionProduct[] = [
  {
    id: "protip365_premium_monthly",
    platform: "ios",
    priceLabel: "$4.99/mo",
    title: "ProTip365 Premium Monthly",
    trialDays: 7,
  },
  {
    id: "protip365_premium_yearly",
    platform: "ios",
    priceLabel: "$39.99/yr",
    title: "ProTip365 Premium Yearly",
    trialDays: 7,
  },
  {
    id: "protip365_premium_monthly",
    platform: "android",
    priceLabel: "$4.99/mo",
    title: "ProTip365 Premium Monthly",
    trialDays: 7,
  },
  {
    id: "protip365_premium_yearly",
    platform: "android",
    priceLabel: "$39.99/yr",
    title: "ProTip365 Premium Yearly",
    trialDays: 7,
  },
];

export function getSandboxProducts(platform: StorePlatform) {
  return sandboxProducts.filter((product) => product.platform === platform);
}

export function simulateSandboxPurchase({
  outcome,
  productId,
}: {
  outcome: PurchaseOutcome;
  productId: SubscriptionProductId;
}): PurchaseResult {
  if (outcome === "success") {
    return {
      productId,
      status: "trial",
    };
  }

  if (outcome === "canceled") {
    return {
      errorMessage: "Purchase canceled. Core logging remains available.",
      status: "free",
    };
  }

  return {
    errorMessage: "Purchase could not be completed. Try again from Settings.",
    status: "unknown",
  };
}

export function nativeStoreReadiness({
  hasDevelopmentBuild,
  hasProductsConfigured,
  hasSandboxTester,
}: {
  hasDevelopmentBuild: boolean;
  hasProductsConfigured: boolean;
  hasSandboxTester: boolean;
}) {
  const blockers = [];
  if (!hasDevelopmentBuild) {
    blockers.push("Create an Expo development build with the IAP native module.");
  }
  if (!hasProductsConfigured) {
    blockers.push("Create matching subscription products in App Store Connect and Google Play Console.");
  }
  if (!hasSandboxTester) {
    blockers.push("Configure Apple sandbox tester and Google license tester accounts.");
  }

  return {
    blockers,
    ready: blockers.length === 0,
  };
}
