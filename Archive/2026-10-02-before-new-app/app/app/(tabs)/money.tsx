import React, { useCallback, useState } from 'react';
import { View, Alert } from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { emptyLedger, itemBalance, unallocated } from '../../src/domain/payments';
import { paymentsRepo } from '../../src/data/paymentsRepo';
import { useEmployersStore } from '../../src/state/employersStore';
import { Card, GhostButton, PrimaryButton } from '../../src/ui/components';
import { Text } from '../../src/ui/typography';
import { FormScreen } from '../../src/ui/FormScreen';
import { useTokens } from '../../src/ui/tokens';
import { useWriteAccess } from '../../src/ui/WriteAccess';

export default function MoneyScreen() {
  const { t: tr, i18n } = useTranslation();
  const { t } = useTokens();
  const router = useRouter();
  const { requireWrite } = useWriteAccess();
  const employers = useEmployersStore((s) => s.employers);
  const [ledger, setLedger] = useState(emptyLedger);
  const [error, setError] = useState(false);
  const refresh = useCallback(() => {
    try {
      setLedger(paymentsRepo.list());
      setError(false);
    } catch {
      setError(true);
    }
  }, []);
  useFocusEffect(refresh);
  const amount = (n: number, currency: string) =>
    new Intl.NumberFormat(i18n.language, { style: 'currency', currency }).format(n / 100);
  const employer = (id: string) =>
    employers.find((e) => e.id === id)?.name ?? tr('home.unknownEmployer');
  return (
    <FormScreen>
      <View style={{ gap: 10 }}>
        <Text style={{ color: t.dim, fontSize: 16 }}>{tr('redesign.moneyHint')}</Text>
        {error ? (
          <Text accessibilityRole="alert" style={{ color: t.red }}>
            {tr('redesign.saveError')}
          </Text>
        ) : null}
        <PrimaryButton
          label={tr('redesign.recordPayment')}
          onPress={() => router.push('/record-payment')}
        />
        <GhostButton
          label={tr('redesign.addExpected')}
          onPress={() => router.push('/expected-payment')}
        />
        <GhostButton label={tr('redesign.insights')} onPress={() => router.push('/(tabs)/stats')} />
        {!ledger.expected.length ? (
          <Card style={{ padding: 18 }}>
            <Text style={{ color: t.ink }}>{tr('redesign.noExpected')}</Text>
          </Card>
        ) : null}
        {employers
          .filter((e) => ledger.expected.some((i) => i.employerId === e.id))
          .map((e) => (
            <View key={e.id} style={{ gap: 10 }}>
              <Text style={{ color: t.ink, fontSize: 22, fontWeight: '600', marginTop: 16 }}>
                {e.name}
              </Text>
              {ledger.expected
                .filter((i) => i.employerId === e.id)
                .map((item) => {
                  const balance = itemBalance(item, ledger);
                  return (
                    <Card key={item.id} style={{ padding: 16 }}>
                      <Text style={{ color: t.dim }}>
                        {tr(`redesign.${item.kind}`)} · {item.dueDate ?? tr('redesign.noDate')}
                      </Text>
                      <Text style={{ color: t.ink, fontSize: 24 }}>
                        {balance.remaining === null
                          ? tr('redesign.unknown')
                          : amount(balance.remaining, item.currency)}
                      </Text>
                      <Text
                        accessibilityLabel={tr(`redesign.${balance.status}`)}
                        style={{ color: balance.status === 'settled' ? t.green : t.amber }}
                      >
                        {tr(`redesign.${balance.status}`)}
                      </Text>
                      <Text style={{ color: t.dim }}>
                        {tr('redesign.received')}: {amount(balance.received, item.currency)}
                      </Text>
                      {item.shiftId ? (
                        <GhostButton
                          label={tr('redesign.shiftDetails')}
                          onPress={() =>
                            router.push({
                              pathname: '/shift-result/[id]',
                              params: { id: item.shiftId! },
                            })
                          }
                        />
                      ) : null}
                      <GhostButton
                        label={tr('redesign.editExpected')}
                        onPress={() =>
                          router.push({ pathname: '/expected-payment', params: { id: item.id } })
                        }
                      />
                    </Card>
                  );
                })}
            </View>
          ))}
        <Text style={{ color: t.ink, fontSize: 22, marginTop: 20 }}>{tr('redesign.history')}</Text>
        {!ledger.receipts.length ? (
          <Text style={{ color: t.dim }}>{tr('redesign.noReceipts')}</Text>
        ) : null}
        {ledger.receipts.map((receipt) => (
          <Card key={receipt.id} style={{ padding: 16 }}>
            <Text style={{ color: t.ink, fontSize: 18 }}>
              {employer(receipt.employerId)} · {amount(receipt.amount, receipt.currency)}
            </Text>
            <Text style={{ color: t.dim }}>
              {receipt.receivedDate} · {receipt.reference}
            </Text>
            <Text style={{ color: receipt.reversedAt ? t.amber : t.green }}>
              {tr(receipt.reversedAt ? 'redesign.reversed' : 'redesign.received')}
            </Text>
            {!receipt.reversedAt ? (
              <>
                <Text style={{ color: t.dim }}>
                  {tr('redesign.unallocated')}:{' '}
                  {amount(unallocated(receipt, ledger), receipt.currency)}
                </Text>
                {unallocated(receipt, ledger) > 0 ? (
                  <GhostButton
                    label={tr('redesign.allocate')}
                    onPress={() =>
                      router.push({
                        pathname: '/record-payment',
                        params: { receiptId: receipt.id },
                      })
                    }
                  />
                ) : null}
                <GhostButton
                  label={tr('redesign.reverse')}
                  onPress={() => {
                    if (!requireWrite()) return;
                    Alert.alert(tr('redesign.reverse'), tr('redesign.reverseHint'), [
                      { text: tr('common.cancel'), style: 'cancel' },
                      {
                        text: tr('common.confirm'),
                        style: 'destructive',
                        onPress: () => {
                          try {
                            paymentsRepo.reverse(receipt.id);
                            refresh();
                          } catch {
                            setError(true);
                          }
                        },
                      },
                    ]);
                  }}
                />
              </>
            ) : null}
          </Card>
        ))}
      </View>
    </FormScreen>
  );
}
