import "react-native-url-polyfill/auto";
import { AppState, Platform } from "react-native";
import { createClient, processLock, SupabaseClient } from "@supabase/supabase-js";
import { getSupabaseConfig } from "../config/env";
import { supabaseSecureStorage } from "./secureStorage";

let client: SupabaseClient | null = null;
let appStateRegistered = false;

export function getSupabaseClient() {
  const result = getSupabaseConfig();

  if (!result.ok) {
    return null;
  }

  if (!client) {
    client = createClient(result.config.url, result.config.publishableKey, {
      auth: {
        autoRefreshToken: true,
        detectSessionInUrl: false,
        lock: processLock,
        persistSession: true,
        storage: supabaseSecureStorage,
      },
    });
  }

  if (!appStateRegistered && Platform.OS !== "web") {
    appStateRegistered = true;
    AppState.addEventListener("change", (state) => {
      if (!client) {
        return;
      }

      if (state === "active") {
        client.auth.startAutoRefresh();
      } else {
        client.auth.stopAutoRefresh();
      }
    });
  }

  return client;
}
