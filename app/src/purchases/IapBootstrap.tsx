import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { AppState, Platform } from 'react-native';
import {
  ErrorCode,
  getActiveSubscriptions,
  getAvailablePurchases,
  type ExpoPurchaseError,
  type ProductSubscription,
  type Purchase,
  useIAP,
} from 'expo-iap';

import {
  LIFETIME_PRODUCT_ID,
  MONTHLY_PRODUCT_ID,
} from '../domain/entitlements';
import { entitlementFromStoreSnapshot } from '../domain/storeEntitlements';
import { useEntitlementStore } from '../state/entitlementStore';
import { usePurchaseStore } from '../state/purchaseStore';
import {
  type InAppPurchaseClient,
  type PurchaseEntitlement,
  type PurchaseProductId,
  PurchaseFlowError,
  resetInAppPurchaseClient,
  setInAppPurchaseClient,
} from './iap';

const PURCHASE_TIMEOUT_MS = 2 * 60 * 1000;

interface PendingPurchase {
  productId: PurchaseProductId;
  resolve: (entitlement: PurchaseEntitlement) => void;
  reject: (error: Error) => void;
  timeout: ReturnType<typeof setTimeout>;
}

function purchaseContainsProduct(purchase: Purchase, productId: PurchaseProductId): boolean {
  return purchase.productId === productId || purchase.ids?.includes(productId) === true;
}

function basePlanOfferToken(subscription: ProductSubscription | undefined): string | null {
  if (!subscription || subscription.platform !== 'android') return null;

  const basePlan =
    subscription.subscriptionOfferDetailsAndroid.find((offer) => !offer.offerId) ??
    subscription.subscriptionOfferDetailsAndroid[0];
  if (basePlan?.offerToken) return basePlan.offerToken;

  return (
    subscription.subscriptionOffers.find((offer) => offer.offerTokenAndroid)
      ?.offerTokenAndroid ?? null
  );
}

function fallbackEntitlement(purchase: Purchase): PurchaseEntitlement {
  return entitlementFromStoreSnapshot({
    ownsLifetime: purchaseContainsProduct(purchase, LIFETIME_PRODUCT_ID),
    hasActiveSubscription: purchaseContainsProduct(purchase, MONTHLY_PRODUCT_ID),
  });
}

export function IapBootstrap() {
  if (Platform.OS !== 'android' && Platform.OS !== 'ios') return null;
  return <NativeIapBootstrap />;
}

function NativeIapBootstrap() {
  const pendingRef = useRef<PendingPurchase | null>(null);
  const purchaseSuccessRef = useRef<(purchase: Purchase) => void>(() => undefined);
  const purchaseErrorRef = useRef<(error: ExpoPurchaseError) => void>(() => undefined);
  const subscriptionRef = useRef<ProductSubscription | undefined>(undefined);

  const {
    connected,
    products,
    subscriptions,
    fetchProducts,
    requestPurchase,
    finishTransaction,
  } = useIAP({
    onPurchaseSuccess: (purchase) => purchaseSuccessRef.current(purchase),
    onPurchaseError: (error) => purchaseErrorRef.current(error),
  });

  subscriptionRef.current = subscriptions.find(
    (subscription) => subscription.id === MONTHLY_PRODUCT_ID
  );

  const settlePending = useCallback(
    (
      productId: PurchaseProductId | null,
      result: { entitlement: PurchaseEntitlement } | { error: Error }
    ) => {
      const pending = pendingRef.current;
      if (!pending || (productId && pending.productId !== productId)) return;

      clearTimeout(pending.timeout);
      pendingRef.current = null;
      if ('entitlement' in result) pending.resolve(result.entitlement);
      else pending.reject(result.error);
    },
    []
  );

  const readStoreEntitlement = useCallback(async (): Promise<PurchaseEntitlement> => {
    const [availablePurchases, activeSubscriptions] = await Promise.all([
      getAvailablePurchases({ includeSuspendedAndroid: false }),
      getActiveSubscriptions([MONTHLY_PRODUCT_ID]),
    ]);
    const activeSubscription = activeSubscriptions.find(
      (subscription) =>
        subscription.productId === MONTHLY_PRODUCT_ID && subscription.isActive
    );

    return entitlementFromStoreSnapshot({
      ownsLifetime: availablePurchases.some(
        (purchase) =>
          purchase.purchaseState === 'purchased' &&
          purchaseContainsProduct(purchase, LIFETIME_PRODUCT_ID)
      ),
      hasActiveSubscription: Boolean(activeSubscription),
      subscriptionExpirationDateMs: activeSubscription?.expirationDateIOS,
    });
  }, []);

  const client = useMemo<InAppPurchaseClient>(
    () => ({
      purchase: (productId) =>
        new Promise<PurchaseEntitlement>((resolve, reject) => {
          if (!connected) {
            reject(new PurchaseFlowError('iap_store_unavailable'));
            return;
          }
          if (pendingRef.current) {
            reject(new PurchaseFlowError('iap_busy'));
            return;
          }

          const timeout = setTimeout(() => {
            settlePending(productId, {
              error: new PurchaseFlowError('iap_store_unavailable'),
            });
          }, PURCHASE_TIMEOUT_MS);
          pendingRef.current = { productId, resolve, reject, timeout };

          const launchPurchase = async () => {
            try {
              if (productId === LIFETIME_PRODUCT_ID) {
                await requestPurchase({
                  request: {
                    apple: { sku: productId },
                    google: { skus: [productId] },
                  },
                  type: 'in-app',
                });
                return;
              }

              const offerToken = basePlanOfferToken(subscriptionRef.current);
              if (Platform.OS === 'android' && !offerToken) {
                throw new PurchaseFlowError('iap_product_unavailable');
              }
              await requestPurchase({
                request: {
                  apple: { sku: productId },
                  google: {
                    skus: [productId],
                    subscriptionOffers: offerToken
                      ? [{ sku: productId, offerToken }]
                      : [],
                  },
                },
                type: 'subs',
              });
            } catch (error) {
              settlePending(productId, {
                error:
                  error instanceof PurchaseFlowError
                    ? error
                    : new PurchaseFlowError('iap_store_unavailable'),
              });
            }
          };

          void launchPurchase();
        }),
      restore: readStoreEntitlement,
    }),
    [connected, readStoreEntitlement, requestPurchase, settlePending]
  );

  purchaseSuccessRef.current = (purchase) => {
    const knownProductId = purchaseContainsProduct(purchase, LIFETIME_PRODUCT_ID)
      ? LIFETIME_PRODUCT_ID
      : purchaseContainsProduct(purchase, MONTHLY_PRODUCT_ID)
        ? MONTHLY_PRODUCT_ID
        : null;
    if (!knownProductId) return;

    if (purchase.purchaseState === 'pending') {
      settlePending(knownProductId, {
        error: new PurchaseFlowError('iap_pending'),
      });
      return;
    }
    if (purchase.purchaseState !== 'purchased') {
      settlePending(knownProductId, {
        error: new PurchaseFlowError('iap_store_unavailable'),
      });
      return;
    }

    void (async () => {
      let entitlement: PurchaseEntitlement;
      try {
        entitlement = await readStoreEntitlement();
      } catch {
        entitlement = fallbackEntitlement(purchase);
      }

      useEntitlementStore.getState().applyStoreEntitlement(entitlement);
      try {
        await finishTransaction({ purchase, isConsumable: false });
        settlePending(knownProductId, { entitlement });
      } catch {
        settlePending(knownProductId, {
          error: new PurchaseFlowError('iap_store_unavailable'),
        });
      }
    })();
  };

  purchaseErrorRef.current = (error) => {
    settlePending(null, {
      error: new PurchaseFlowError(
        error.code === ErrorCode.UserCancelled
          ? 'iap_cancelled'
          : 'iap_store_unavailable'
      ),
    });
  };

  useEffect(() => {
    if (!connected) return;
    void Promise.allSettled([
      fetchProducts({ skus: [LIFETIME_PRODUCT_ID], type: 'in-app' }),
      fetchProducts({ skus: [MONTHLY_PRODUCT_ID], type: 'subs' }),
    ]);
  }, [connected, fetchProducts]);

  useEffect(() => {
    const lifetimeProduct = products.find(
      (product) => product.id === LIFETIME_PRODUCT_ID
    );
    const monthlyProduct = subscriptions.find(
      (subscription) => subscription.id === MONTHLY_PRODUCT_ID
    );
    const offerToken = basePlanOfferToken(monthlyProduct);
    const ready =
      connected &&
      Boolean(lifetimeProduct) &&
      Boolean(monthlyProduct) &&
      (Platform.OS !== 'android' || Boolean(offerToken));

    usePurchaseStore.getState().setCatalog(ready, {
      ...(lifetimeProduct
        ? { [LIFETIME_PRODUCT_ID]: lifetimeProduct.displayPrice }
        : {}),
      ...(monthlyProduct
        ? { [MONTHLY_PRODUCT_ID]: monthlyProduct.displayPrice }
        : {}),
    });
  }, [connected, products, subscriptions]);

  useEffect(() => {
    if (!connected) {
      resetInAppPurchaseClient();
      return;
    }

    setInAppPurchaseClient(client);
    return () => resetInAppPurchaseClient();
  }, [client, connected]);

  useEffect(() => {
    if (!connected) return;

    const syncEntitlement = async () => {
      try {
        const entitlement = await client.restore();
        useEntitlementStore.getState().applyStoreEntitlement(entitlement);
      } catch {
        // Keep the last verified local entitlement when the store is offline.
      }
    };

    void syncEntitlement();
    const subscription = AppState.addEventListener('change', (state) => {
      if (state === 'active') void syncEntitlement();
    });
    return () => subscription.remove();
  }, [client, connected]);

  useEffect(
    () => () => {
      const pending = pendingRef.current;
      if (pending) {
        clearTimeout(pending.timeout);
        pending.reject(new PurchaseFlowError('iap_store_unavailable'));
        pendingRef.current = null;
      }
      usePurchaseStore.getState().reset();
    },
    []
  );

  return null;
}
