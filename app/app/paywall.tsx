import React, { useState } from 'react';
import { Alert, ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import {
  LIFETIME_PRODUCT_ID,
  MONTHLY_PRODUCT_ID,
} from '../src/domain/entitlements';
import { PurchaseFlowError } from '../src/purchases/iap';
import { useEntitlementStore } from '../src/state/entitlementStore';
import { usePurchaseStore } from '../src/state/purchaseStore';
import { withAppLockSystemPrompt } from '../src/state/appLockStore';
import { Card, GhostButton, PrimaryButton } from '../src/ui/components';
import { useTokens } from '../src/ui/tokens';
import { Text } from '../src/ui/typography';

export default function PaywallScreen() {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const status = useEntitlementStore((state) => state.status);
  const days = useEntitlementStore((state) => state.trialDaysRemaining);
  const purchase = useEntitlementStore((state) => state.purchase);
  const restorePurchases = useEntitlementStore((state) => state.restorePurchases);
  const purchasesAvailable = usePurchaseStore((state) => state.ready);
  const prices = usePurchaseStore((state) => state.prices);
  const [busy, setBusy] = useState(false);

  const runPurchase = async (productId: typeof LIFETIME_PRODUCT_ID | typeof MONTHLY_PRODUCT_ID) => {
    setBusy(true);
    try {
      await withAppLockSystemPrompt(() => purchase(productId));
      Alert.alert(tr('paywall.purchaseComplete'));
    } catch (error) {
      if (error instanceof PurchaseFlowError && error.code === 'iap_cancelled') return;
      if (error instanceof PurchaseFlowError && error.code === 'iap_pending') {
        Alert.alert(tr('paywall.purchasePending'));
        return;
      }
      Alert.alert(tr('paywall.storeUnavailable'));
    } finally {
      setBusy(false);
    }
  };

  const restore = async () => {
    setBusy(true);
    try {
      await withAppLockSystemPrompt(restorePurchases);
      Alert.alert(tr('paywall.restoreComplete'));
    } catch {
      Alert.alert(tr('paywall.storeUnavailable'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 16, paddingBottom: 48 }}
    >
      <Text style={{ color: t.ink, fontSize: 26, lineHeight: 32, fontWeight: '800' }}>
        {tr('paywall.heading')}
      </Text>
      <Text style={{ color: t.softText, fontSize: 15, lineHeight: 22, marginTop: 8, marginBottom: 18 }}>
        {status === 'expired'
          ? tr('paywall.expiredExplanation')
          : status === 'trial'
            ? tr('paywall.trialRemaining', { count: days })
            : tr(`paywall.status.${status}`)}
      </Text>

      {!purchasesAvailable ? (
        <Card style={{ padding: 16, marginBottom: 12 }}>
          <Text style={{ color: t.ink, fontSize: 16, fontWeight: '800', marginBottom: 6 }}>
            {tr('paywall.comingAtLaunchTitle')}
          </Text>
          <Text style={{ color: t.softText, lineHeight: 20 }}>
            {tr('paywall.comingAtLaunchDescription')}
          </Text>
        </Card>
      ) : null}

      <Card style={{ padding: 16, marginBottom: 12 }}>
        <Text style={{ color: t.ink, fontSize: 20, fontWeight: '800' }}>
          {prices[LIFETIME_PRODUCT_ID] ?? tr('paywall.lifetimePrice')}
        </Text>
        <Text style={{ color: t.softText, lineHeight: 20, marginVertical: 8 }}>{tr('paywall.lifetimeDescription')}</Text>
        <PrimaryButton
          label={purchasesAvailable ? tr('paywall.lifetimeAction') : tr('paywall.comingAtLaunchAction')}
          onPress={() => void runPurchase(LIFETIME_PRODUCT_ID)}
          disabled={busy || !purchasesAvailable}
        />
      </Card>

      <Card style={{ padding: 16, marginBottom: 16 }}>
        <Text style={{ color: t.ink, fontSize: 20, fontWeight: '800' }}>
          {prices[MONTHLY_PRODUCT_ID] ?? tr('paywall.monthlyPrice')}
        </Text>
        <Text style={{ color: t.softText, lineHeight: 20, marginVertical: 8 }}>{tr('paywall.monthlyDescription')}</Text>
        <PrimaryButton
          label={purchasesAvailable ? tr('paywall.monthlyAction') : tr('paywall.comingAtLaunchAction')}
          onPress={() => void runPurchase(MONTHLY_PRODUCT_ID)}
          disabled={busy || !purchasesAvailable}
        />
      </Card>

      {purchasesAvailable ? (
        <GhostButton label={tr('paywall.restoreAction')} onPress={() => void restore()} style={{ marginBottom: 12 }} />
      ) : null}
      <View style={{ borderTopWidth: 1, borderTopColor: t.line, paddingTop: 12 }}>
        <Text style={{ color: t.softText, fontSize: 12, lineHeight: 18 }}>
          {tr('paywall.readOnlyPromise')}
        </Text>
        <Text style={{ color: t.softText, fontSize: 12, lineHeight: 18, marginTop: 6 }}>
          {tr('paywall.restoreClarification')}
        </Text>
      </View>
    </ScrollView>
  );
}
