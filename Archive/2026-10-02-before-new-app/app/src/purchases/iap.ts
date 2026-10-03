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

export type PurchaseFlowErrorCode =
  | 'iap_busy'
  | 'iap_cancelled'
  | 'iap_pending'
  | 'iap_product_unavailable'
  | 'iap_store_unavailable';

export class PurchaseFlowError extends Error {
  constructor(public readonly code: PurchaseFlowErrorCode) {
    super(code);
    this.name = 'PurchaseFlowError';
  }
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

export function resetInAppPurchaseClient(): void {
  inAppPurchaseClient = new StubInAppPurchaseClient();
  purchaseAdapterAvailable = false;
}
