import {
  ENTITLEMENT_ENFORCEMENT_ENABLED,
  canWriteBeforeEntitlementHydration,
  evaluateEntitlement,
  LIFETIME_PRODUCT_ID,
  MONTHLY_PRODUCT_ID,
  TRIAL_DAYS,
} from '../entitlements';

const startedAt = '2026-07-01T00:00:00.000Z';

describe('local entitlement evaluation', () => {
  it('starts with the complete 7-day trial', () => {
    const result = evaluateEntitlement(
      { trialStartedAt: startedAt, lifetimeUnlocked: false, subscriptionExpiresAt: null },
      new Date(startedAt)
    );

    expect(TRIAL_DAYS).toBe(7);
    expect(result).toMatchObject({ status: 'trial', canWrite: true, trialDaysRemaining: 7 });
  });

  it('allows recording through the final instant of the seventh day', () => {
    const result = evaluateEntitlement(
      { trialStartedAt: startedAt, lifetimeUnlocked: false, subscriptionExpiresAt: null },
      new Date('2026-07-07T23:59:59.999Z')
    );

    expect(result).toMatchObject({ status: 'trial', canWrite: true, trialDaysRemaining: 1 });
  });

  it('enforces read-only access at the exact trial boundary', () => {
    const result = evaluateEntitlement(
      { trialStartedAt: startedAt, lifetimeUnlocked: false, subscriptionExpiresAt: null },
      new Date('2026-07-08T00:00:00.000Z')
    );

    expect(ENTITLEMENT_ENFORCEMENT_ENABLED).toBe(true);
    expect(result).toMatchObject({ status: 'expired', canWrite: false, trialDaysRemaining: 0 });
  });

  it('can evaluate a disabled-enforcement fixture without changing production policy', () => {
    const result = evaluateEntitlement(
      { trialStartedAt: startedAt, lifetimeUnlocked: false, subscriptionExpiresAt: null },
      new Date('2026-07-31T00:00:00.000Z'),
      false
    );

    expect(result).toMatchObject({ status: 'expired', canWrite: true, trialDaysRemaining: 0 });
  });

  it('keeps lifetime purchases writable after trial expiry', () => {
    const result = evaluateEntitlement(
      { trialStartedAt: startedAt, lifetimeUnlocked: true, subscriptionExpiresAt: null },
      new Date('2027-01-01T00:00:00.000Z')
    );

    expect(result).toMatchObject({ status: 'lifetime', canWrite: true });
  });

  it('allows an active monthly subscription and expires a lapsed one', () => {
    const active = evaluateEntitlement(
      {
        trialStartedAt: startedAt,
        lifetimeUnlocked: false,
        subscriptionExpiresAt: '2026-09-01T00:00:00.000Z',
      },
      new Date('2026-08-01T00:00:00.000Z')
    );
    const lapsed = evaluateEntitlement(
      {
        trialStartedAt: startedAt,
        lifetimeUnlocked: false,
        subscriptionExpiresAt: '2026-08-01T00:00:00.000Z',
      },
      new Date('2026-08-01T00:00:00.000Z'),
      true
    );

    expect(active).toMatchObject({ status: 'subscription', canWrite: true });
    expect(lapsed).toMatchObject({ status: 'expired', canWrite: false });
  });

  it('uses the Play submission product IDs', () => {
    expect(LIFETIME_PRODUCT_ID).toBe('lifetime_unlock');
    expect(MONTHLY_PRODUCT_ID).toBe('monthly');
  });

  it('does not extend a trial when the device clock rolls backward', () => {
    const result = evaluateEntitlement(
      {
        trialStartedAt: startedAt,
        lastSeenAt: '2026-07-06T00:00:00.000Z',
        lifetimeUnlocked: false,
        subscriptionExpiresAt: null,
      },
      new Date('2026-07-03T00:00:00.000Z')
    );

    expect(result).toMatchObject({ status: 'trial', trialDaysRemaining: 2 });
  });

  it('fails closed before hydration in production', () => {
    expect(canWriteBeforeEntitlementHydration()).toBe(false);
    expect(canWriteBeforeEntitlementHydration(false)).toBe(true);
    expect(canWriteBeforeEntitlementHydration(true)).toBe(false);
  });
});
