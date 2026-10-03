import React, { useRef, useState } from 'react';
import { View } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { paymentsRepo } from '../src/data/paymentsRepo';
import { uuid } from '../src/data/ids';
import { itemBalance, type Allocation } from '../src/domain/payments';
import { parseMoneyToCents } from '../src/domain/money';
import { todayIso } from '../src/domain/dates';
import { useShiftsStore } from '../src/state/shiftsStore';
import { useEmployersStore } from '../src/state/employersStore';
import { useSettingsStore } from '../src/state/settingsStore';
import { Chip, Field, PrimaryButton } from '../src/ui/components';
import { FormScreen } from '../src/ui/FormScreen';
import { Text } from '../src/ui/typography';
import { useTokens } from '../src/ui/tokens';
import { useWriteAccess } from '../src/ui/WriteAccess';
import { DatePickerField } from '../src/ui/DateTimeField';

export default function RecordPaymentScreen() {
  const { receiptId } = useLocalSearchParams<{ receiptId?: string }>();
  const { t: tr } = useTranslation();
  const { t } = useTokens();
  const router = useRouter();
  const { requireWrite } = useWriteAccess();
  const shifts = useShiftsStore((s) => s.shifts);
  const employers = useEmployersStore((s) => s.employers);
  const currency = useSettingsStore((s) => s.currencyCode);
  const [ledger] = useState(() => paymentsRepo.list());
  const [id] = useState(uuid);
  const saving = useRef(false);
  const existing = ledger.receipts.find((r) => r.id === receiptId);
  const [employerId, setEmployer] = useState(existing?.employerId ?? employers[0]?.id ?? '');
  const [code, setCode] = useState<string>(existing?.currency ?? currency);
  const [value, setValue] = useState(existing ? String(existing.amount / 100) : '');
  const [date, setDate] = useState(existing?.receivedDate ?? todayIso());
  const [reference, setReference] = useState(existing?.reference ?? '');
  const [values, setValues] = useState<Record<string, string>>({});
  const [error, setError] = useState(false);
  const items = ledger.expected.filter(
    (i) =>
      i.employerId === employerId &&
      i.currency === code &&
      (itemBalance(i, ledger).remaining ?? 0) > 0
  );
  return (
    <FormScreen>
      <Stack.Screen options={{ title: tr('redesign.recordPayment') }} />
      <Text style={{ color: t.dim, marginBottom: 16 }}>{tr('redesign.paymentHint')}</Text>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 16 }}>
        {employers.map((e) => (
          <Chip
            key={e.id}
            label={e.name}
            selected={e.id === employerId}
            onPress={() => {
              if (!existing) {
                setEmployer(e.id);
                setValues({});
              }
            }}
          />
        ))}
      </View>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 16 }}>
        {['CAD', 'USD', 'EUR', 'MXN'].map((c) => (
          <Chip
            key={c}
            label={c}
            selected={c === code}
            onPress={() => {
              if (!existing) {
                setCode(c);
                setValues({});
              }
            }}
          />
        ))}
      </View>
      <Field
        label={tr('redesign.received')}
        value={value}
        onChangeText={(v) => {
          if (!existing) setValue(v);
        }}
        keyboardType="decimal-pad"
      />
      <DatePickerField
        label={tr('redesign.receivedDate')}
        value={date}
        onChange={(v) => {
          if (!existing) setDate(v);
        }}
      />
      <Field
        label={tr('redesign.reference')}
        value={reference}
        onChangeText={(v) => {
          if (!existing) setReference(v);
        }}
      />
      <Text style={{ color: t.ink, fontSize: 20, marginVertical: 16 }}>
        {tr('redesign.allocate')}
      </Text>
      {items.map((item) => (
        <Field
          key={item.id}
          label={`${tr(`redesign.${item.kind}`)} · ${item.dueDate ?? tr('redesign.noDate')} · ${shifts.find((s) => s.id === item.shiftId)?.date ?? ''}`}
          hint={`${tr('redesign.awaiting')}: ${(itemBalance(item, ledger).remaining! / 100).toFixed(2)} ${code}`}
          value={values[item.id] ?? ''}
          onChangeText={(v) => setValues({ ...values, [item.id]: v })}
          keyboardType="decimal-pad"
        />
      ))}
      <Text style={{ color: t.dim, marginBottom: 16 }}>{tr('redesign.unallocatedHint')}</Text>
      {error ? (
        <Text accessibilityRole="alert" style={{ color: t.red }}>
          {tr('redesign.saveError')}
        </Text>
      ) : null}
      <PrimaryButton
        label={tr('common.save')}
        onPress={() => {
          if (!requireWrite() || saving.current) return;
          saving.current = true;
          try {
            const amount = parseMoneyToCents(value);
            if (amount === null) throw Error();
            const allocations: Allocation[] = Object.entries(values)
              .filter(([, v]) => v.trim())
              .map(([expectedId, v]) => {
                const n = parseMoneyToCents(v);
                if (n === null) throw Error();
                return {
                  id: `${id}:${expectedId}`,
                  receiptId: existing?.id ?? id,
                  expectedId,
                  amount: n,
                };
              });
            if (existing) paymentsRepo.allocate(existing.id, allocations);
            else
              paymentsRepo.record(
                {
                  id,
                  employerId,
                  amount,
                  currency: code,
                  receivedDate: date,
                  reference,
                  reversedAt: null,
                },
                allocations
              );
            router.back();
          } catch {
            setError(true);
            saving.current = false;
          }
        }}
      />
    </FormScreen>
  );
}
