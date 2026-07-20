import React, { useCallback } from 'react';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { useEntitlementStore } from '../state/entitlementStore';
import { Card, PrimaryButton } from './components';
import { useTokens } from './tokens';
import { Text } from './typography';

export function useWriteAccess() {
  const router = useRouter();
  const canWrite = useEntitlementStore((state) => state.canWrite);
  const requireWrite = useCallback(() => {
    if (canWrite) return true;
    router.push('/paywall');
    return false;
  }, [canWrite, router]);
  return { canWrite, requireWrite };
}

export function WriteAccessBanner() {
  const router = useRouter();
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const canWrite = useEntitlementStore((state) => state.canWrite);
  if (canWrite) return null;
  return (
    <Card style={{ padding: 12, marginBottom: 14 }}>
      <Text style={{ color: t.ink, lineHeight: 20, marginBottom: 10 }}>
        {tr('paywall.expiredExplanation')}
      </Text>
      <PrimaryButton label={tr('paywall.unlockToEdit')} onPress={() => router.push('/paywall')} />
    </Card>
  );
}
