import { describe, expect, it, vi } from "vitest";

vi.mock("react-native", () => ({
  AppState: { addEventListener: () => ({ remove: () => undefined }) },
  Modal: "Modal",
  Platform: { OS: "web" },
  Text: "Text",
  View: "View",
}));

vi.mock("expo-local-authentication", () => ({
  AuthenticationType: {
    FACIAL_RECOGNITION: 2,
    FINGERPRINT: 1,
  },
  authenticateAsync: vi.fn(),
  hasHardwareAsync: vi.fn(),
  isEnrolledAsync: vi.fn(),
  supportedAuthenticationTypesAsync: vi.fn(),
}));

vi.mock("../../screens/shared/screenShared", () => ({
  FormInput: "FormInput",
  PrimaryButton: "PrimaryButton",
  styles: {},
}));

vi.mock("../secureStorage", () => ({
  supabaseSecureStorage: {
    getItem: vi.fn(),
    removeItem: vi.fn(),
    setItem: vi.fn(),
  },
}));

describe("app lock helpers", async () => {
  const { saveAppLockSettings, shouldLockOnResume, subscribeAppLockSettings } = await import("../appLock");
  const { supabaseSecureStorage } = await import("../secureStorage");

  it("does not lock when disabled", () => {
    expect(shouldLockOnResume({ biometricEnabled: false, enabled: false, lockDelay: "resume" }, null)).toBe(false);
  });

  it("does not lock on resume when launch-only is selected", () => {
    expect(shouldLockOnResume({ biometricEnabled: false, enabled: true, lockDelay: "launch" }, Date.now())).toBe(false);
  });

  it("locks immediately on resume setting", () => {
    expect(shouldLockOnResume({ biometricEnabled: false, enabled: true, lockDelay: "resume" }, Date.now())).toBe(true);
  });

  it("waits five minutes when that delay is selected", () => {
    const now = new Date("2026-06-17T12:05:00Z").getTime();

    expect(shouldLockOnResume({ biometricEnabled: false, enabled: true, lockDelay: "five_minutes" }, now - 60 * 1000, now)).toBe(false);
    expect(shouldLockOnResume({ biometricEnabled: false, enabled: true, lockDelay: "five_minutes" }, now - 5 * 60 * 1000, now)).toBe(true);
  });

  it("notifies mounted gates when settings change", async () => {
    vi.mocked(supabaseSecureStorage.getItem).mockResolvedValue("1234");
    const listener = vi.fn();
    const unsubscribe = subscribeAppLockSettings(listener);

    await saveAppLockSettings({ biometricEnabled: false, enabled: true, lockDelay: "resume" });

    expect(listener).toHaveBeenCalledWith({ biometricEnabled: false, enabled: true, lockDelay: "resume" });
    unsubscribe();
  });
});
