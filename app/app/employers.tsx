import React, { useState } from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';

import type { Employer, Role } from '../src/domain/types';
import { useEmployersStore } from '../src/state/employersStore';
import { Card, Chip, Field, GhostButton, money, PrimaryButton } from '../src/ui/components';
import { EMPLOYER_PALETTE, useTokens } from '../src/ui/tokens';
import { useWriteAccess, WriteAccessBanner } from '../src/ui/WriteAccess';
import { centsToInput, parseMoneyToCents } from '../src/domain/money';
import { validateDeductionBasisPoints, validateHourlyRateCents } from '../src/domain/validate';

const COLOR_KEYS = ['amber', 'rose', 'teal', 'cobalt', 'violet'] as const;

function parseDecimal(text: string): number | null {
  const value = Number(text.replace(',', '.'));
  return text.trim() !== '' && Number.isFinite(value) ? value : null;
}

function RoleEditor({ role }: { role: Role }) {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const updateRole = useEmployersStore((state) => state.updateRole);
  const { requireWrite } = useWriteAccess();
  const [name, setName] = useState(role.name);
  const [rateText, setRateText] = useState(centsToInput(role.hourlyRate));
  const [nameError, setNameError] = useState<string | null>(null);
  const [rateError, setRateError] = useState<string | null>(null);

  const onSave = () => {
    if (!requireWrite()) return;
    const rate = parseMoneyToCents(rateText);
    const nextNameError = name.trim() ? null : tr('shiftForm.errors.roleNameRequired');
    const nextRateError = validateHourlyRateCents(rate).valid
      ? null
      : tr('shiftForm.errors.rate_not_positive');
    setNameError(nextNameError);
    setRateError(nextRateError);
    if (nextNameError || nextRateError || rate == null) return;
    updateRole({ ...role, name: name.trim(), hourlyRate: rate });
  };

  return (
    <View style={{ borderTopWidth: 1, borderTopColor: t.line, paddingTop: 12, marginTop: 12 }}>
      <Field
        label={tr('shiftForm.roleName')}
        value={name}
        onChangeText={(text) => {
          setName(text);
          setNameError(null);
        }}
        error={nameError}
      />
      <Field
        label={tr('shiftForm.hourlyRate')}
        value={rateText}
        onChangeText={(text) => {
          setRateText(text);
          setRateError(null);
        }}
        keyboardType="decimal-pad"
        error={rateError}
      />
      <GhostButton label={tr('employers.saveRole')} onPress={onSave} />
    </View>
  );
}

function AddRoleForm({ employerId }: { employerId: string }) {
  const { t: tr } = useTranslation();
  const addRole = useEmployersStore((state) => state.addRole);
  const { requireWrite } = useWriteAccess();
  const [show, setShow] = useState(false);
  const [name, setName] = useState('');
  const [rateText, setRateText] = useState('');
  const [nameError, setNameError] = useState<string | null>(null);
  const [rateError, setRateError] = useState<string | null>(null);

  const onAdd = () => {
    if (!requireWrite()) return;
    const rate = parseMoneyToCents(rateText);
    const nextNameError = name.trim() ? null : tr('shiftForm.errors.roleNameRequired');
    const nextRateError = validateHourlyRateCents(rate).valid
      ? null
      : tr('shiftForm.errors.rate_not_positive');
    setNameError(nextNameError);
    setRateError(nextRateError);
    if (nextNameError || nextRateError || rate == null) return;
    addRole({ employerId, name: name.trim(), hourlyRate: rate });
    setName('');
    setRateText('');
    setShow(false);
  };

  if (!show) {
    return (
      <GhostButton
        label={`＋ ${tr('shiftForm.addRole')}`}
        onPress={() => setShow(true)}
        style={{ marginTop: 12 }}
      />
    );
  }

  return (
    <View style={{ marginTop: 12 }}>
      <Field
        label={tr('shiftForm.roleName')}
        value={name}
        onChangeText={(text) => {
          setName(text);
          setNameError(null);
        }}
        error={nameError}
      />
      <Field
        label={tr('shiftForm.hourlyRate')}
        value={rateText}
        onChangeText={(text) => {
          setRateText(text);
          setRateError(null);
        }}
        keyboardType="decimal-pad"
        error={rateError}
      />
      <PrimaryButton label={tr('employers.addRoleAction')} onPress={onAdd} />
    </View>
  );
}

function EmployerEditor({ employer, roles }: { employer: Employer; roles: Role[] }) {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const updateEmployer = useEmployersStore((state) => state.updateEmployer);
  const archiveEmployer = useEmployersStore((state) => state.archiveEmployer);
  const { requireWrite } = useWriteAccess();
  const [name, setName] = useState(employer.name);
  const [color, setColor] = useState(employer.color);
  const [defaultRateText, setDefaultRateText] = useState(centsToInput(employer.defaultHourlyRate));
  const [deductionText, setDeductionText] = useState(
    String(employer.deductionRateBp / 100)
  );
  const [nameError, setNameError] = useState<string | null>(null);
  const [defaultRateError, setDefaultRateError] = useState<string | null>(null);
  const [deductionError, setDeductionError] = useState<string | null>(null);

  const onSave = () => {
    if (!requireWrite()) return;
    const defaultRate = parseMoneyToCents(defaultRateText);
    const deduction = parseDecimal(deductionText);
    const nextNameError = name.trim() ? null : tr('shiftForm.errors.employerNameRequired');
    const nextDefaultRateError = validateHourlyRateCents(defaultRate).valid
      ? null
      : tr('shiftForm.errors.rate_not_positive');
    const deductionBp = deduction == null ? Number.NaN : Math.round(deduction * 100);
    const nextDeductionError =
      deduction != null &&
      deduction >= 0 &&
      deduction <= 100 &&
      validateDeductionBasisPoints(deductionBp).valid
      ? null
      : tr('shiftForm.errors.deduction_out_of_range');
    setNameError(nextNameError);
    setDefaultRateError(nextDefaultRateError);
    setDeductionError(nextDeductionError);
    if (
      nextNameError ||
      nextDefaultRateError ||
      nextDeductionError ||
      defaultRate == null ||
      deduction == null
    ) return;
    updateEmployer({
      ...employer,
      name: name.trim(),
      color,
      defaultHourlyRate: defaultRate,
      deductionRateBp: deductionBp,
    });
  };

  const onArchive = () => {
    if (!requireWrite()) return;
    if (employer.archived) {
      archiveEmployer(employer.id, false);
      return;
    }
    Alert.alert(tr('employers.archiveConfirmTitle'), tr('employers.archiveConfirmMessage'), [
      { text: tr('common.cancel'), style: 'cancel' },
      {
        text: tr('employers.archive'),
        style: 'destructive',
        onPress: () => archiveEmployer(employer.id, true),
      },
    ]);
  };

  return (
    <Card style={{ padding: 14, marginBottom: 14 }}>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', gap: 8 }}>
        <Text style={{ color: t.ink, fontWeight: '700', fontSize: 18, flex: 1 }}>
          {employer.name}
        </Text>
        {employer.archived ? (
          <Text style={{ color: t.ink, fontSize: 12, fontWeight: '700' }}>
            {tr('employers.archived')}
          </Text>
        ) : null}
      </View>

      <Field
        label={tr('shiftForm.employerName')}
        value={name}
        onChangeText={(text) => {
          setName(text);
          setNameError(null);
        }}
        error={nameError}
      />
      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 4 }}>
        {tr('employers.color')}
      </Text>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
        {EMPLOYER_PALETTE.map((value, index) => (
          <Chip
            key={value}
            label={tr(`employers.colors.${COLOR_KEYS[index]}`)}
            color={value}
            selected={color === value}
            onPress={() => setColor(value)}
          />
        ))}
      </View>
      <Field
        label={tr('employers.defaultHourlyRate')}
        value={defaultRateText}
        onChangeText={(text) => {
          setDefaultRateText(text);
          setDefaultRateError(null);
        }}
        keyboardType="decimal-pad"
        error={defaultRateError}
      />
      <Field
        label={tr('employers.deductionRate')}
        value={deductionText}
        onChangeText={(text) => {
          setDeductionText(text);
          setDeductionError(null);
        }}
        keyboardType="decimal-pad"
        error={deductionError}
      />
      <PrimaryButton label={tr('employers.saveEmployer')} onPress={onSave} />

      <Text style={{ color: t.ink, fontWeight: '700', fontSize: 15, marginTop: 18 }}>
        {tr('employers.roles')}
      </Text>
      {roles.length === 0 ? (
        <Text style={{ color: t.softText, marginTop: 8 }}>{tr('employers.noRoles')}</Text>
      ) : (
        roles.map((role) => <RoleEditor key={role.id} role={role} />)
      )}
      <AddRoleForm employerId={employer.id} />

      <Text style={{ color: t.softText, fontSize: 12, marginTop: 16 }}>
        {roles.map((role) => `${role.name}: ${money(role.hourlyRate)}/h`).join(' · ')}
      </Text>
      <GhostButton
        label={employer.archived ? tr('employers.unarchive') : tr('employers.archive')}
        onPress={onArchive}
        danger={!employer.archived}
        style={{ marginTop: 12 }}
      />
    </Card>
  );
}

export default function EmployersScreen() {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const employers = useEmployersStore((state) => state.employers);
  const roles = useEmployersStore((state) => state.roles);

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 16, paddingBottom: 48 }}
      keyboardShouldPersistTaps="handled"
    >
      <Stack.Screen options={{ title: tr('employers.title') }} />
      <WriteAccessBanner />
      {employers.length === 0 ? (
        <Text style={{ color: t.softText }}>{tr('employers.empty')}</Text>
      ) : (
        employers.map((employer) => (
          <EmployerEditor
            key={employer.id}
            employer={employer}
            roles={roles.filter((role) => role.employerId === employer.id)}
          />
        ))
      )}
    </ScrollView>
  );
}
