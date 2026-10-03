import React, { useState } from 'react';
import { View } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { paymentsRepo } from '../src/data/paymentsRepo';
import { uuid } from '../src/data/ids';
import { type ExpectedItem } from '../src/domain/payments';
import { parseMoneyToCents, centsToInput } from '../src/domain/money';
import { useEmployersStore } from '../src/state/employersStore';
import { useSettingsStore } from '../src/state/settingsStore';
import { useShiftsStore } from '../src/state/shiftsStore';
import { Chip, Field, PrimaryButton } from '../src/ui/components';
import { FormScreen } from '../src/ui/FormScreen';
import { Text } from '../src/ui/typography';
import { useTokens } from '../src/ui/tokens';
import { useWriteAccess } from '../src/ui/WriteAccess';

export default function ExpectedPaymentScreen() {
  const { id, shiftId } = useLocalSearchParams<{ id?: string; shiftId?: string }>();
  const { t: tr } = useTranslation();
  const { t } = useTokens();
  const router = useRouter();
  const { requireWrite } = useWriteAccess();
  const employers = useEmployersStore((s) => s.employers);
  const shifts = useShiftsStore((s) => s.shifts);
  const currency = useSettingsStore((s) => s.currencyCode);
  const [original] = useState(() => paymentsRepo.list().expected.find((i) => i.id === id));
  const [key] = useState(() => id ?? uuid());
  const linked = shifts.find((s) => s.id === (original?.shiftId ?? shiftId));
  const [employerId, setEmployer] = useState(
    original?.employerId ?? linked?.employerId ?? employers.find((e) => !e.archived)?.id ?? ''
  );
  const [kind, setKind] = useState<ExpectedItem['kind']>(original?.kind ?? 'tips');
  const [value, setValue] = useState(centsToInput(original?.amount));
  const [due, setDue] = useState(original?.dueDate ?? '');
  const [disputed, setDisputed] = useState(original?.disputed ?? false);
  const [error, setError] = useState(false);
  return (
    <FormScreen>
      <Stack.Screen options={{ title: tr('redesign.addExpected') }} />
      <Text style={{ color: t.dim, marginBottom: 16 }}>{tr('redesign.expectedHint')}</Text>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 16 }}>
        {employers
          .filter((e) => !e.archived || e.id === employerId)
          .map((e) => (
            <Chip
              key={e.id}
              label={e.name}
              selected={e.id === employerId}
              onPress={() => {
                if (!original && !linked) setEmployer(e.id);
              }}
            />
          ))}
      </View>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 16 }}>
        {(['tips', 'wages', 'other'] as const).map((k) => (
          <Chip
            key={k}
            label={tr(`redesign.${k}`)}
            selected={kind === k}
            onPress={() => {
              if (!original) setKind(k);
            }}
          />
        ))}
      </View>
      <Text style={{ color: t.ink }}>
        {original?.currency ?? currency} {linked ? `· ${linked.date}` : ''}
      </Text>
      <Field
        label={tr('redesign.expectedAmount')}
        value={value}
        onChangeText={setValue}
        keyboardType="decimal-pad"
        hint={tr('redesign.blankUnknown')}
      />
      <Field
        label={tr('redesign.dueDate')}
        value={due}
        onChangeText={setDue}
        placeholder="YYYY-MM-DD"
      />
      <Chip
        label={tr('redesign.disputed')}
        selected={disputed}
        onPress={() => setDisputed(!disputed)}
      />
      {error ? (
        <Text accessibilityRole="alert" style={{ color: t.red }}>
          {tr('redesign.saveError')}
        </Text>
      ) : null}
      <PrimaryButton
        label={tr('common.save')}
        style={{ marginTop: 20 }}
        onPress={() => {
          if (!requireWrite()) return;
          try {
            const amount = value.trim() ? parseMoneyToCents(value) : null;
            if (value.trim() && amount === null) throw Error();
            paymentsRepo.saveExpected({
              id: key,
              employerId,
              shiftId: original?.shiftId ?? linked?.id ?? null,
              kind,
              amount,
              currency: original?.currency ?? currency,
              dueDate: due.trim() || null,
              disputed,
            });
            router.back();
          } catch {
            setError(true);
          }
        }}
      />
    </FormScreen>
  );
}
