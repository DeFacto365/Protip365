import AsyncStorage from "@react-native-async-storage/async-storage";
import { StoredSubscription } from "../features/subscriptions/subscriptionStatus";

const STORAGE_KEY = "protip365.subscription.v1";

export async function loadSubscription(): Promise<StoredSubscription> {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return { state: "unknown" };
  }

  return JSON.parse(raw) as StoredSubscription;
}

export async function saveSubscription(subscription: StoredSubscription) {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(subscription));
  return subscription;
}

export async function clearSubscription() {
  await AsyncStorage.removeItem(STORAGE_KEY);
}
