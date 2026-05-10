import { beforeEach, describe, expect, it, vi } from "vitest";
import { clearSubscription, loadSubscription, saveSubscription } from "./subscriptionRepository";

const storage = new Map<string, string>();

vi.mock("@react-native-async-storage/async-storage", () => ({
  default: {
    getItem: vi.fn((key: string) => Promise.resolve(storage.get(key) ?? null)),
    removeItem: vi.fn((key: string) => {
      storage.delete(key);
      return Promise.resolve();
    }),
    setItem: vi.fn((key: string, value: string) => {
      storage.set(key, value);
      return Promise.resolve();
    }),
  },
}));

describe("subscriptionRepository", () => {
  beforeEach(() => {
    storage.clear();
  });

  it("loads unknown state by default", async () => {
    await expect(loadSubscription()).resolves.toEqual({ state: "unknown" });
  });

  it("saves and clears subscription state", async () => {
    await saveSubscription({ productId: "protip365_premium_monthly", state: "active" });
    await expect(loadSubscription()).resolves.toMatchObject({ state: "active" });
    await clearSubscription();
    await expect(loadSubscription()).resolves.toEqual({ state: "unknown" });
  });
});
