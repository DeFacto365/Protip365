import { StoredSubscription } from "../features/subscriptions/subscriptionStatus";
import { supabaseSecureStorage } from "../lib/secureStorage";

const STORAGE_KEY = "protip365.subscription.v1";

export async function loadSubscription(): Promise<StoredSubscription> {
  const raw = await supabaseSecureStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return { state: "unknown" };
  }

  return JSON.parse(raw) as StoredSubscription;
}

export async function saveSubscription(subscription: StoredSubscription) {
  await supabaseSecureStorage.setItem(STORAGE_KEY, JSON.stringify(subscription));
  return subscription;
}

export async function clearSubscription() {
  await supabaseSecureStorage.removeItem(STORAGE_KEY);
}
