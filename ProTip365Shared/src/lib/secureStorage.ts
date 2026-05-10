import * as SecureStore from "expo-secure-store";
import { Platform } from "react-native";

const memoryStorage = new Map<string, string>();

export const supabaseSecureStorage = {
  async getItem(key: string) {
    if (Platform.OS === "web") {
      return memoryStorage.get(key) ?? null;
    }

    return SecureStore.getItemAsync(key);
  },
  async removeItem(key: string) {
    if (Platform.OS === "web") {
      memoryStorage.delete(key);
      return;
    }

    await SecureStore.deleteItemAsync(key);
  },
  async setItem(key: string, value: string) {
    if (Platform.OS === "web") {
      memoryStorage.set(key, value);
      return;
    }

    await SecureStore.setItemAsync(key, value);
  },
};
