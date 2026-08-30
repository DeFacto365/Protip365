import { create } from 'zustand';

import type { PurchaseProductId } from '../purchases/iap';

interface PurchaseCatalogState {
  ready: boolean;
  prices: Partial<Record<PurchaseProductId, string>>;
  setCatalog: (
    ready: boolean,
    prices: Partial<Record<PurchaseProductId, string>>
  ) => void;
  reset: () => void;
}

export const usePurchaseStore = create<PurchaseCatalogState>((set) => ({
  ready: false,
  prices: {},
  setCatalog: (ready, prices) => set({ ready, prices }),
  reset: () => set({ ready: false, prices: {} }),
}));
