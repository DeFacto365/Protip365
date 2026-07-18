import { LIFETIME_PRODUCT_ID, MONTHLY_PRODUCT_ID } from '../domain/entitlements';

export type PurchaseProductId = typeof LIFETIME_PRODUCT_ID | typeof MONTHLY_PRODUCT_ID;

export interface PurchaseEntitlement {
  lifetimeUnlocked: boolean;
  subscriptionExpiresAt: string | null;
}

export interface InAppPurchaseClient {
  purchase(productId: PurchaseProductId): Promise<PurchaseEntitlement>;
  restore(): Promise<PurchaseEntitlement>;
}

/**
 * Phase I seam for Google Play / App Store billing. The production adapter will
 * replace this stub after store products and receipt validation are configured.
 */
class StubInAppPurchaseClient implements InAppPurchaseClient {
  async purchase(_productId: PurchaseProductId): Promise<PurchaseEntitlement> {
    throw new Error('iap_unavailable');
  }

  async restore(): Promise<PurchaseEntitlement> {
    throw new Error('iap_unavailable');
  }
}

export let inAppPurchaseClient: InAppPurchaseClient = new StubInAppPurchaseClient();
let purchaseAdapterAvailable = false;

export function purchasesAreAvailable(): boolean {
  return purchaseAdapterAvailable;
}

export function setInAppPurchaseClient(client: InAppPurchaseClient): void {
  inAppPurchaseClient = client;
  purchaseAdapterAvailable = true;
}
