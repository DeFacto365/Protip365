export type SupabaseConfig = {
  url: string;
  publishableKey: string;
};

export type SupabaseConfigResult =
  | { ok: true; config: SupabaseConfig }
  | { ok: false; missingKeys: string[] };

const requiredEnv = {
  EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  EXPO_PUBLIC_SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL,
};

export function getSupabaseConfig(): SupabaseConfigResult {
  const missingKeys = Object.entries(requiredEnv)
    .filter(([, value]) => !value)
    .map(([key]) => key);

  if (missingKeys.length > 0) {
    return { missingKeys, ok: false };
  }

  return {
    config: {
      publishableKey: requiredEnv.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY as string,
      url: requiredEnv.EXPO_PUBLIC_SUPABASE_URL as string,
    },
    ok: true,
  };
}
