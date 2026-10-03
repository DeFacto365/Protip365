const values = new Map<string, string>();
jest.mock('expo-secure-store', () => ({
  getItem: (key: string) => values.get(key) ?? null,
  setItem: (key: string, value: string) => values.set(key, value),
}));
import {useEntitlementStore as access} from '../entitlementStore';
import {ENTITLEMENT_RECORD_KEY, readEntitlementRecord} from '../entitlementStorage';
import {setInAppPurchaseClient, resetInAppPurchaseClient, PurchaseFlowError} from '../iap';

beforeEach(() => {
  values.clear(); resetInAppPurchaseClient();
  jest.useFakeTimers().setSystemTime(new Date('2026-10-03T12:00:00Z'));
  access.setState({hydrated: false, canWrite: false});
});
afterEach(() => jest.useRealTimers());
test('trial anchor survives refresh; expiry and clock rollback cannot restart it', () => {
  access.getState().hydrate();
  const anchor=readEntitlementRecord()!.trialStartedAt;
  jest.setSystemTime(new Date('2026-11-03T12:00:00Z'));
  access.getState().refresh(); expect(access.getState().canWrite).toBe(false);
  jest.setSystemTime(new Date('2026-10-05T12:00:00Z'));
  access.getState().refresh(); expect(access.getState().canWrite).toBe(false);
  expect(readEntitlementRecord()!.trialStartedAt).toBe(anchor);
});
test('lifetime purchase persists; a confirmed store revocation removes access', async () => {
  access.getState().hydrate();
  jest.setSystemTime(new Date('2026-11-03T12:00:00Z'));
  setInAppPurchaseClient({purchase: async () => ({lifetimeUnlocked:true, subscriptionExpiresAt:null}),
    restore: async () => ({lifetimeUnlocked:false, subscriptionExpiresAt:null})});
  await access.getState().purchase('lifetime_unlock');
  expect(access.getState().status).toBe('lifetime');
  access.getState().hydrate(); expect(access.getState().canWrite).toBe(true);
  await access.getState().restorePurchases(); expect(access.getState().canWrite).toBe(false);
});
test('pending and cancelled payment do not grant access; offline restore preserves verified access', async () => {
  access.getState().hydrate();
  jest.setSystemTime(new Date('2026-11-03T12:00:00Z'));
  access.getState().refresh();
  for (const code of ['iap_pending','iap_cancelled'] as const) {
    setInAppPurchaseClient({purchase: async () => {throw new PurchaseFlowError(code);}, restore:async () => {throw new Error('offline');}});
    await expect(access.getState().purchase('monthly')).rejects.toThrow(code);
    expect(access.getState().canWrite).toBe(false);
  }
  access.getState().applyStoreEntitlement({lifetimeUnlocked:true,subscriptionExpiresAt:null});
  await expect(access.getState().restorePurchases()).rejects.toThrow('offline');
  expect(access.getState().status).toBe('lifetime');
});
test('monthly expiration is enforced and restore can renew access', async () => {
  access.getState().hydrate();
  jest.setSystemTime(new Date('2026-11-03T12:00:00Z'));
  access.getState().applyStoreEntitlement({lifetimeUnlocked:false,subscriptionExpiresAt:'2026-11-04T12:00:00Z'});
  expect(access.getState().status).toBe('subscription');
  jest.setSystemTime(new Date('2026-11-04T12:00:00Z'));
  access.getState().refresh(); expect(access.getState().canWrite).toBe(false);
  setInAppPurchaseClient({purchase:async () => {throw new Error('unused');},
    restore:async () => ({lifetimeUnlocked:false,subscriptionExpiresAt:'2026-11-07T12:00:00Z'})});
  await access.getState().restorePurchases(); expect(access.getState().status).toBe('subscription');
});
test('legacy purchase record retains ownership, invalid saved access never restarts a free trial', () => {
  values.set(ENTITLEMENT_RECORD_KEY,JSON.stringify({version:1,trialStartedAt:'2026-07-01T12:00:00Z',lastSeenAt:'2026-07-01T12:00:00Z',lifetimeUnlocked:true,subscriptionExpiresAt:null}));
  access.getState().hydrate(); expect(access.getState().status).toBe('lifetime');
  expect(readEntitlementRecord()!.version).toBe(2);
  values.set(ENTITLEMENT_RECORD_KEY,'broken'); access.getState().refresh();
  expect(access.getState().canWrite).toBe(false); expect(values.get(ENTITLEMENT_RECORD_KEY)).toBe('broken');
});
