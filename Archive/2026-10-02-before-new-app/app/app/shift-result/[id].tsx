import React, { useCallback, useState } from 'react';
import { Share } from 'react-native';
import { useFocusEffect, Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useShiftsStore } from '../../src/state/shiftsStore';
import { useEmployersStore } from '../../src/state/employersStore';
import { actualEarnings, actualPaidMinutes, wagesForMinutes } from '../../src/domain/calc';
import { paymentsRepo } from '../../src/data/paymentsRepo';
import { itemBalance } from '../../src/domain/payments';
import { FormScreen } from '../../src/ui/FormScreen';
import { ReceiptCard, LineItem, money, PrimaryButton, GhostButton } from '../../src/ui/components';
import { Text } from '../../src/ui/typography';
import { useTokens } from '../../src/ui/tokens';
export default function ShiftResultScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t: tr, i18n } = useTranslation();
  const { t } = useTokens();
  const shift = useShiftsStore((s) => s.shifts.find((x) => x.id === id));
  const employers = useEmployersStore((s) => s.employers);
  const [ledger, setLedger] = useState(() => paymentsRepo.list());
  useFocusEffect(
    useCallback(() => {
      setLedger(paymentsRepo.list());
    }, [])
  );
  if (!shift)
    return (
      <FormScreen>
        <Text style={{ color: t.ink }}>{tr('redesign.saveError')}</Text>
      </FormScreen>
    );
  const employer = employers.find((e) => e.id === shift.employerId)?.name ?? '';
  const items = ledger.expected.filter((i) => i.shiftId === id);
  const base = wagesForMinutes(
    actualPaidMinutes(shift),
    shift.actualHourlyRateSnapshot ?? shift.hourlyRateSnapshot
  );
  return (
    <FormScreen>
      <Stack.Screen options={{ title: tr('redesign.result') }} />
      <ReceiptCard>
        <Text fontRole="mono" style={{ color: t.ink, fontSize: 18 }}>
          {employer} · {shift.date}
        </Text>
        <LineItem
          label={tr('redesign.recordedEarnings')}
          value={money(actualEarnings(shift))}
          strong
        />
        <LineItem label={tr('home.wages')} value={money(base)} />
        <LineItem
          label={tr('redesign.tips')}
          value={money(actualEarnings(shift) - base - (shift.otherIncome ?? 0))}
        />
        {items.length === 0 ? (
          <Text style={{ color: t.dim }}>
            {tr('redesign.unknown')} · {tr('redesign.paymentTiming')}
          </Text>
        ) : null}
        {items.map((item) => {
          const b = itemBalance(item, ledger);
          const fmt = (n: number) =>
            new Intl.NumberFormat(i18n.language, {
              style: 'currency',
              currency: item.currency,
            }).format(n / 100);
          return (
            <React.Fragment key={item.id}>
              <LineItem
                label={`${tr(`redesign.${item.kind}`)} · ${tr('redesign.received')}`}
                value={fmt(b.received)}
                tone="confirmed"
              />
              <LineItem
                label={tr(`redesign.${b.status}`)}
                value={b.remaining === null ? tr('redesign.unknown') : fmt(b.remaining)}
              />
              {ledger.allocations
                .filter((a) => a.expectedId === item.id)
                .map((a) => {
                  const r = ledger.receipts.find((r) => r.id === a.receiptId)!;
                  return (
                    <LineItem
                      key={a.id}
                      label={`${r.receivedDate} · ${tr(r.reversedAt ? 'redesign.reversed' : 'redesign.received')}`}
                      value={fmt(a.amount)}
                    />
                  );
                })}
            </React.Fragment>
          );
        })}
      </ReceiptCard>
      <PrimaryButton
        label={tr('redesign.done')}
        onPress={() => router.dismissTo('/(tabs)')}
        style={{ marginTop: 20 }}
      />
      <GhostButton
        label={tr('redesign.addExpected')}
        onPress={() => router.push({ pathname: '/expected-payment', params: { shiftId: id } })}
      />
      <GhostButton
        label={tr('redesign.edit')}
        onPress={() => router.replace({ pathname: '/complete/[id]', params: { id } })}
      />
      <GhostButton
        label={tr('redesign.share')}
        onPress={() => {
          void Share.share({
            message: `ProTip365 · ${employer} · ${shift.date}\n${tr('redesign.recordedEarnings')}: ${money(actualEarnings(shift))}`,
          });
        }}
      />
    </FormScreen>
  );
}
