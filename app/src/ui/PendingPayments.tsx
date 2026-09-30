import React, { useCallback, useState } from 'react';
import { useFocusEffect } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { paymentsRepo } from '../data/paymentsRepo';
import { emptyLedger, itemBalance } from '../domain/payments';
import { useEmployersStore } from '../state/employersStore';
import { Text } from './typography';
import { useTokens } from './tokens';
export function PendingPayments() {
  const { t: tr, i18n } = useTranslation();
  const { t } = useTokens();
  const employers = useEmployersStore((s) => s.employers);
  const [ledger, setLedger] = useState(emptyLedger);
  const [failed, setFailed] = useState(false);
  useFocusEffect(
    useCallback(() => {
      try {
        setLedger(paymentsRepo.list());
        setFailed(false);
      } catch {
        setFailed(true);
      }
    }, [])
  );
  if (failed)
    return (
      <Text accessibilityRole="alert" style={{ color: t.red }}>
        {tr('redesign.saveError')}
      </Text>
    );
  const groups = new Map<
    string,
    { employerId: string; currency: string; amount: number; unknown: boolean }
  >();
  for (const item of ledger.expected) {
    const balance = itemBalance(item, ledger);
    if (balance.remaining === 0) continue;
    const key = `${item.employerId}:${item.currency}`;
    const g = groups.get(key) ?? {
      employerId: item.employerId,
      currency: item.currency,
      amount: 0,
      unknown: false,
    };
    g.amount += balance.remaining ?? 0;
    g.unknown ||= balance.remaining === null;
    groups.set(key, g);
  }
  return (
    <>
      {[...groups.entries()].map(([key, g]) => (
        <Text key={key} style={{ color: t.amber, marginTop: 12, fontSize: 15 }}>
          {employers.find((e) => e.id === g.employerId)?.name} · {tr('redesign.awaiting')}:{' '}
          {new Intl.NumberFormat(i18n.language, { style: 'currency', currency: g.currency }).format(
            g.amount / 100
          )}
          {g.unknown ? ` + ${tr('redesign.unknown')}` : ''}
        </Text>
      ))}
    </>
  );
}
