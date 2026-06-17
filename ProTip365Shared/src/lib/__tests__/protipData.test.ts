import { describe, expect, it, vi } from "vitest";

vi.mock("react-native", () => ({
  AppState: { addEventListener: () => ({ remove: () => undefined }) },
  NativeModules: { BlobModule: null },
  Platform: { OS: "web" },
}));

vi.mock("expo-secure-store", () => ({
  deleteItemAsync: vi.fn(),
  getItemAsync: vi.fn(),
  setItemAsync: vi.fn(),
}));

describe("money and time helpers", async () => {
  const { hoursBetween, parseMoney, toDateValue, toTimeValue } = await import("../protipData");

  it("parses common money input safely", () => {
    expect(parseMoney("$1,234.56")).toBe(1234.56);
    expect(parseMoney("-$12.50")).toBe(-12.5);
    expect(parseMoney("not a number")).toBe(0);
  });

  it("formats local date and time values", () => {
    const date = new Date(2026, 5, 7, 9, 5);

    expect(toDateValue(date)).toBe("2026-06-07");
    expect(toTimeValue(date)).toBe("09:05");
  });

  it("calculates overnight shift hours", () => {
    expect(hoursBetween("22:30", "02:00")).toBe(3.5);
    expect(hoursBetween("09:00", "17:15")).toBe(8.25);
  });
});
