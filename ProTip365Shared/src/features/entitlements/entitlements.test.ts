import { describe, expect, it } from "vitest";
import { getFeatureEntitlement, shouldShowTrialPrompt } from "./entitlements";

describe("entitlements", () => {
  it("keeps core logging, calendar, and basic reports free", () => {
    const state = { completedWeekCount: 0, loggedShiftCount: 0, status: "free" as const, trialAvailable: true };

    expect(getFeatureEntitlement("coreLogging", state).allowed).toBe(true);
    expect(getFeatureEntitlement("calendarHistory", state).allowed).toBe(true);
    expect(getFeatureEntitlement("basicReports", state).allowed).toBe(true);
  });

  it("locks premium surfaces for free users with a value explanation", () => {
    const entitlement = getFeatureEntitlement("advancedReports", {
      completedWeekCount: 0,
      loggedShiftCount: 2,
      status: "free",
      trialAvailable: true,
    });

    expect(entitlement.allowed).toBe(false);
    expect(entitlement.tier).toBe("premium");
    expect(entitlement.reason).toContain("Premium unlocks");
  });

  it("allows premium features during trial and active premium", () => {
    expect(
      getFeatureEntitlement("fullExport", {
        completedWeekCount: 0,
        loggedShiftCount: 3,
        status: "trial",
        trialAvailable: false,
      }).allowed,
    ).toBe(true);
    expect(
      getFeatureEntitlement("cloudSync", {
        completedWeekCount: 0,
        loggedShiftCount: 0,
        status: "premium",
        trialAvailable: false,
      }).allowed,
    ).toBe(true);
  });

  it("shows trial prompt only after demonstrated value", () => {
    expect(
      shouldShowTrialPrompt({
        completedWeekCount: 0,
        loggedShiftCount: 2,
        status: "free",
        trialAvailable: true,
      }),
    ).toBe(false);
    expect(
      shouldShowTrialPrompt({
        completedWeekCount: 0,
        loggedShiftCount: 3,
        status: "free",
        trialAvailable: true,
      }),
    ).toBe(true);
    expect(
      shouldShowTrialPrompt({
        completedWeekCount: 1,
        loggedShiftCount: 1,
        status: "free",
        trialAvailable: true,
      }),
    ).toBe(true);
  });
});
