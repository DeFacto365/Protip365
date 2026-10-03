import React, {useEffect} from 'react';
import {AppState, Linking, Modal, ScrollView, View} from 'react-native';
import {IapBootstrap} from './IapBootstrap';
import {useEntitlementStore} from './entitlementStore';
import {usePurchaseStore} from './purchaseStore';
import {LIFETIME_PRODUCT_ID, MONTHLY_PRODUCT_ID} from './entitlements';
import {Button, Card, Txt, C} from '../ui';
import type {CopyKey} from '../copy';
export const useAccess = useEntitlementStore;
export function BillingHost() {
  useEffect(() => {
    useEntitlementStore.getState().hydrate();
    const sub = AppState.addEventListener('change', state => {
      if (state === 'active') useEntitlementStore.getState().refresh();
    });
    const timer = setInterval(() => useEntitlementStore.getState().refresh(), 60000);
    return () => {sub.remove(); clearInterval(timer);};
  }, []);
  return <IapBootstrap />;
}
export function AccessSheet({visible, onClose, t, onMessage}: {
  visible: boolean; onClose: () => void; t: (k: CopyKey) => string; onMessage: (message: string) => void;
}) {
  const access = useAccess(), catalog = usePurchaseStore();
  const [busy, setBusy] = React.useState(false);
  const action = async (fn: () => Promise<void>) => {
    setBusy(true);
    try {await fn(); onMessage(t(['lifetime', 'subscription'].includes(useAccess.getState().status) ? 'purchaseSuccess' : 'noPurchases')); onClose();}
    catch (error) {
      const code = (error as {code?: string}).code;
      if (code !== 'iap_cancelled') onMessage(t(code === 'iap_pending' ? 'purchasePending' : 'storeUnavailable'));
    } finally {setBusy(false);}
  };
  return <Modal visible={visible} animationType="slide" onRequestClose={onClose}>
    <ScrollView contentContainerStyle={{padding: 28, paddingTop: 64, gap: 20, flexGrow: 1, backgroundColor: C.bg}}>
      <Txt kind="title">{t('accessTitle')}</Txt>
      <Txt>{t(access.status === 'expired' ? 'accessExpired' : access.status === 'trial' ? 'accessTrial' : 'accessPaid')}
        {access.status === 'trial' ? ` ${access.trialDaysRemaining}` : ''}</Txt>
      <Txt kind="small">{t('accessDataSafe')}</Txt>
      {access.status !== 'lifetime' && <Card>
        <Txt kind="section">{t('lifetime')}</Txt>
        <Txt>{catalog.prices[LIFETIME_PRODUCT_ID] ?? t('storeLoading')}</Txt>
        <Button label={t('buyLifetime')} disabled={busy || !catalog.ready}
          onPress={() => void action(() => access.purchase(LIFETIME_PRODUCT_ID))}/>
      </Card>}
      {!['lifetime', 'subscription'].includes(access.status) && <Card>
        <Txt kind="section">{t('monthly')}</Txt>
        <Txt>{catalog.prices[MONTHLY_PRODUCT_ID] ?? t('storeLoading')} · {t('perMonth')}</Txt>
        <Txt kind="small">{t('renewalTerms')}</Txt>
        <Button label={t('subscribe')} disabled={busy || !catalog.ready}
          onPress={() => void action(() => access.purchase(MONTHLY_PRODUCT_ID))}/>
      </Card>}
      <Button secondary label={t('restorePurchase')} disabled={busy}
        onPress={() => void action(access.restorePurchases)}/>
      <Button secondary label={t('manageSubscription')} onPress={() => void Linking.openURL('https://play.google.com/store/account/subscriptions?package=com.defacto365.protip365&sku=monthly')}/>
      <View style={{gap: 12}}>
        <Button secondary label={t('privacyLink')} onPress={() => void Linking.openURL('https://www.protip365.com/privacy')}/>
        <Button secondary label={t('terms')} onPress={() => void Linking.openURL('https://www.protip365.com/terms')}/>
      </View>
      <Button label={t('done')} onPress={onClose}/>
    </ScrollView>
  </Modal>;
}
