import { supabaseSecureStorage } from "../../lib/secureStorage";

const ONBOARDING_COMPLETE_KEY = "protip365.onboardingComplete.v1";

export async function isOnboardingComplete() {
  return (await supabaseSecureStorage.getItem(ONBOARDING_COMPLETE_KEY)) === "true";
}

export async function setOnboardingComplete() {
  await supabaseSecureStorage.setItem(ONBOARDING_COMPLETE_KEY, "true");
}
