export const TRIAL_DAYS = 30;
/**
 * Paid access is enforced in production. The purchase UI additionally requires
 * a connected native store adapter and a complete product catalog before it can
 * start a transaction.
 */
export const ENTITLEMENT_ENFORCEMENT_ENABLED = true;
export const LIFETIME_PRODUCT_ID = 'lifetime_unlock';
export const MONTHLY_PRODUCT_ID = 'monthly';

export type EntitlementStatus = 'trial' | 'lifetime' | 'subscription' | 'expired';

export interface EntitlementInput {
  trialStartedAt: string;
  lastSeenAt?: string | null;
  lifetimeUnlocked: boolean;
  subscriptionExpiresAt: string | null;
}

export interface EntitlementEvaluation {
  status: EntitlementStatus;
  canWrite: boolean;
  trialEndsAt: string;
  trialDaysRemaining: number;
}

export function evaluateEntitlement(
  input: EntitlementInput,
  now: Date = new Date(),
  enforcementEnabled: boolean = ENTITLEMENT_ENFORCEMENT_ENABLED
): EntitlementEvaluation {
  const parsedStart = Date.parse(input.trialStartedAt);
  const start = Number.isFinite(parsedStart) ? parsedStart : now.getTime();
  const parsedLastSeen = input.lastSeenAt ? Date.parse(input.lastSeenAt) : Number.NaN;
  const effectiveNow = Math.max(
    now.getTime(),
    start,
    Number.isFinite(parsedLastSeen) ? parsedLastSeen : start
  );
  const trialEnd = start + TRIAL_DAYS * 24 * 60 * 60 * 1000;
  const subscriptionEnd = input.subscriptionExpiresAt
    ? Date.parse(input.subscriptionExpiresAt)
    : Number.NaN;
  const trialDaysRemaining = Math.max(
    0,
    Math.ceil((trialEnd - effectiveNow) / (24 * 60 * 60 * 1000))
  );

  if (input.lifetimeUnlocked) {
    return {
      status: 'lifetime',
      canWrite: true,
      trialEndsAt: new Date(trialEnd).toISOString(),
      trialDaysRemaining,
    };
  }
  if (Number.isFinite(subscriptionEnd) && subscriptionEnd > effectiveNow) {
    return {
      status: 'subscription',
      canWrite: true,
      trialEndsAt: new Date(trialEnd).toISOString(),
      trialDaysRemaining,
    };
  }
  return {
    status: trialEnd > effectiveNow ? 'trial' : 'expired',
    canWrite: !enforcementEnabled || trialEnd > effectiveNow,
    trialEndsAt: new Date(trialEnd).toISOString(),
    trialDaysRemaining,
  };
}

export function canWriteBeforeEntitlementHydration(
  enforcementEnabled: boolean = ENTITLEMENT_ENFORCEMENT_ENABLED
): boolean {
  return !enforcementEnabled;
}
