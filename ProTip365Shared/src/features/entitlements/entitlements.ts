export type EntitlementFeature =
  | "coreLogging"
  | "calendarHistory"
  | "basicReports"
  | "advancedReports"
  | "fullExport"
  | "cloudSync"
  | "paycheckReconciliation"
  | "advancedGoals";

export type EntitlementStatus = "free" | "trial" | "premium" | "expired" | "unknown";

export type EntitlementState = {
  status: EntitlementStatus;
  loggedShiftCount: number;
  completedWeekCount: number;
  trialAvailable: boolean;
};

export type FeatureEntitlement = {
  allowed: boolean;
  feature: EntitlementFeature;
  tier: "free" | "premium";
  reason?: string;
};

const freeFeatures: EntitlementFeature[] = ["coreLogging", "calendarHistory", "basicReports"];
const premiumFeatures: EntitlementFeature[] = [
  "advancedReports",
  "fullExport",
  "cloudSync",
  "paycheckReconciliation",
  "advancedGoals",
];

export function isPremiumStatus(status: EntitlementStatus) {
  return status === "premium" || status === "trial";
}

export function getFeatureEntitlement(feature: EntitlementFeature, state: EntitlementState): FeatureEntitlement {
  if (freeFeatures.includes(feature)) {
    return {
      allowed: true,
      feature,
      tier: "free",
    };
  }

  const allowed = isPremiumStatus(state.status);
  return {
    allowed,
    feature,
    reason: allowed ? undefined : premiumReason(feature),
    tier: "premium",
  };
}

export function shouldShowTrialPrompt(state: EntitlementState) {
  if (!state.trialAvailable || isPremiumStatus(state.status)) {
    return false;
  }

  return state.loggedShiftCount >= 3 || state.completedWeekCount >= 1;
}

export function premiumReason(feature: EntitlementFeature) {
  switch (feature) {
    case "advancedReports":
      return "Premium unlocks job comparisons, best days, day-of-week averages, and monthly trend charts.";
    case "fullExport":
      return "Premium unlocks full CSV/PDF export and tax-ready records.";
    case "cloudSync":
      return "Premium unlocks cloud sync and backup across devices.";
    case "paycheckReconciliation":
      return "Premium unlocks paycheck and pending card-tip reconciliation.";
    case "advancedGoals":
      return "Premium unlocks advanced goals and forecasting.";
    default:
      return "Premium unlocks this feature.";
  }
}

export function premiumFeatureLabels() {
  return [
    "Advanced report comparisons",
    "Full CSV/PDF export",
    "Cloud sync and backup",
    "Paycheck reconciliation",
    "Advanced goals and forecasting",
  ];
}

export function freeFeatureLabels() {
  return [
    "Add and edit shifts",
    "Cash/card tips and tip-out",
    "Calendar and history",
    "Today, week, and month summaries",
    "Real hourly and net tips",
  ];
}
