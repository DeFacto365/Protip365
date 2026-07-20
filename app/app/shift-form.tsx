import React, { useMemo, useRef, useState } from 'react';
import { Alert, ScrollView, View } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { useEmployersStore } from '../src/state/employersStore';
import { useShiftsStore } from '../src/state/shiftsStore';
import { useSettingsStore } from '../src/state/settingsStore';
import { EMPLOYER_PALETTE, useTokens } from '../src/ui/tokens';
import {
  Card,
  Chip,
  Field,
  GhostButton,
  LineItem,
  money,
  PrimaryButton,
  ReceiptCard,
  ReceiptRule,
} from '../src/ui/components';
import { DatePickerField, TimePickerField } from '../src/ui/DateTimeField';
import { expectedEarnings } from '../src/domain/calc';
import { selectableEmployers } from '../src/domain/employers';
import { isValidIsoDate, minutesToHHMM, parseHHMM, todayIso } from '../src/domain/dates';
import { findOverlaps } from '../src/domain/overlap';
import {
  validateHourlyRateCents,
  validateShiftWindow,
  type ValidationError,
} from '../src/domain/validate';
import type { ShiftBreak } from '../src/domain/types';
import { centsToInput, localizedMoneyPlaceholder, parseMoneyToCents } from '../src/domain/money';
import { useWriteAccess, WriteAccessBanner } from '../src/ui/WriteAccess';
import { Text } from '../src/ui/typography';

const SCHEDULE_ROUTE = '/(tabs)/schedule' as const;

export default function ShiftFormScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ id?: string; date?: string; unplanned?: string }>();
  const { t } = useTokens();
  const { t: tr, i18n } = useTranslation();
  const { requireWrite } = useWriteAccess();

  const allEmployers = useEmployersStore((s) => s.employers);
  const addEmployer = useEmployersStore((s) => s.addEmployer);
  const rolesAll = useEmployersStore((s) => s.roles);
  const addRole = useEmployersStore((s) => s.addRole);
  const defaultDeductionRateBp = useSettingsStore((s) => s.defaultDeductionRateBp);

  const shifts = useShiftsStore((s) => s.shifts);
  const getById = useShiftsStore((s) => s.getById);
  const addShift = useShiftsStore((s) => s.addShift);
  const updateScheduled = useShiftsStore((s) => s.updateScheduled);
  const deleteShift = useShiftsStore((s) => s.deleteShift);

  const editing = params.id ? getById(params.id) : undefined;
  const [initialScreenMode] = useState<'edit' | 'unplanned' | 'add'>(() => {
    if (params.id) return 'edit';
    return params.unplanned === '1' ? 'unplanned' : 'add';
  });
  const [screenTitle] = useState(() => {
    if (initialScreenMode === 'edit') return tr('shiftForm.editTitle');
    return tr(
      initialScreenMode === 'unplanned' ? 'shiftForm.unplannedTitle' : 'shiftForm.addTitle'
    );
  });
  const unplanned = params.unplanned === '1' && !editing;

  const employers = useMemo(
    () => selectableEmployers(allEmployers, editing?.employerId),
    [allEmployers, editing?.employerId]
  );
  const [employerId, setEmployerId] = useState<string | null>(
    editing?.employerId ?? employers[0]?.id ?? null
  );
  const [roleId, setRoleId] = useState<string | null>(editing?.roleId ?? null);
  const [date, setDate] = useState(editing?.date ?? params.date ?? todayIso());
  const [startText, setStartText] = useState(editing ? minutesToHHMM(editing.startMin) : '17:00');
  const [endText, setEndText] = useState(editing ? minutesToHHMM(editing.endMin) : '23:00');
  const firstBreak: ShiftBreak | undefined = editing?.breaks[0];
  const [hasBreak, setHasBreak] = useState(!!firstBreak);
  const [breakStartText, setBreakStartText] = useState(
    firstBreak ? minutesToHHMM(firstBreak.startMin) : '20:00'
  );
  const [breakDurText, setBreakDurText] = useState(firstBreak ? String(firstBreak.durationMin) : '30');
  const [rateText, setRateText] = useState(
    editing ? centsToInput(editing.hourlyRateSnapshot) : ''
  );
  const [plannedExpectedTipsText, setPlannedExpectedTipsText] = useState(
    centsToInput(editing?.plannedExpectedTips)
  );
  const [plannedOtherIncomeText, setPlannedOtherIncomeText] = useState(
    centsToInput(editing?.plannedOtherIncome)
  );
  const [notes, setNotes] = useState(editing?.notes ?? '');
  const [errors, setErrors] = useState<string[]>([]);
  // DEF-13: re-entrancy guard against double-tap duplicate saves.
  const [saving, setSaving] = useState(false);
  const savingRef = useRef(false);

  // Inline "add employer" mini-form
  const [showNewEmployer, setShowNewEmployer] = useState(false);
  const [newEmployerName, setNewEmployerName] = useState('');
  const [newEmployerRate, setNewEmployerRate] = useState('');
  const [newEmployerNameError, setNewEmployerNameError] = useState<string | null>(null);
  const [newEmployerRateError, setNewEmployerRateError] = useState<string | null>(null);

  // Inline "add role" mini-form
  const [showNewRole, setShowNewRole] = useState(false);
  const [newRoleName, setNewRoleName] = useState('');
  const [newRoleRate, setNewRoleRate] = useState('');
  const [newRoleNameError, setNewRoleNameError] = useState<string | null>(null);
  const [newRoleRateError, setNewRoleRateError] = useState<string | null>(null);

  const roles = useMemo(
    () => rolesAll.filter((r) => r.employerId === employerId),
    [rolesAll, employerId]
  );
  const employer = employers.find((e) => e.id === employerId);

  const effectiveRate = useMemo(() => {
    const parsed = parseMoneyToCents(rateText);
    if (parsed != null) return parsed;
    const role = roles.find((r) => r.id === roleId);
    return role?.hourlyRate ?? employer?.defaultHourlyRate ?? 0;
  }, [rateText, roles, roleId, employer]);
  const plannedExpectedTips = plannedExpectedTipsText.trim() === ''
    ? null
    : parseMoneyToCents(plannedExpectedTipsText);
  const plannedOtherIncome = plannedOtherIncomeText.trim() === ''
    ? null
    : parseMoneyToCents(plannedOtherIncomeText);

  const parsed = useMemo(() => {
    const startMin = parseHHMM(startText);
    const endMinRaw = parseHHMM(endText);
    if (startMin == null || endMinRaw == null) return null;
    // store overnight as end > 1440
    const endMin = endMinRaw <= startMin ? endMinRaw + 1440 : endMinRaw;
    const breaks: ShiftBreak[] = [];
    if (hasBreak) {
      const bStart = parseHHMM(breakStartText);
      const bDur = Number(breakDurText);
      if (bStart == null || !Number.isFinite(bDur)) return null;
      const normBStart = bStart < startMin ? bStart + 1440 : bStart;
      breaks.push({
        label: tr('shiftForm.breakSection'),
        startMin: normBStart,
        durationMin: bDur,
        paid: false,
      });
    }
    return { startMin, endMin, breaks };
  }, [startText, endText, hasBreak, breakStartText, breakDurText, tr]);

  // DEF-06: explicit overnight cue when the end time wraps past midnight.
  const isOvernight = useMemo(() => {
    const s = parseHHMM(startText);
    const e = parseHHMM(endText);
    return s != null && e != null && e <= s;
  }, [startText, endText]);

  // DEF-01: live, non-blocking cross-employer overlap warning.
  const overlapNames = useMemo(() => {
    if (!parsed || !isValidIsoDate(date)) return [];
    const hits = findOverlaps(
      { id: editing?.id, date, startMin: parsed.startMin, endMin: parsed.endMin },
      shifts
    );
    return hits.map((s) => {
      const e = employers.find((emp) => emp.id === s.employerId);
      return `${e?.name ?? '?'} ${minutesToHHMM(s.startMin)}–${minutesToHHMM(s.endMin)}`;
    });
  }, [parsed, date, editing?.id, shifts, employers]);

  const preview = useMemo(() => {
    if (!parsed) return null;
    return expectedEarnings({
      startMin: parsed.startMin,
      endMin: parsed.endMin,
      breaks: parsed.breaks,
      hourlyRateSnapshot: effectiveRate,
      plannedExpectedTips,
      plannedOtherIncome,
    });
  }, [parsed, effectiveRate, plannedExpectedTips, plannedOtherIncome]);

  const nextColor = () => EMPLOYER_PALETTE[employers.length % EMPLOYER_PALETTE.length];

  const onAddEmployer = () => {
    if (!requireWrite()) return;
    const rate = parseMoneyToCents(newEmployerRate);
    const nameError = newEmployerName.trim()
      ? null
      : tr('shiftForm.errors.employerNameRequired');
    const rateError = validateHourlyRateCents(rate).valid
      ? null
      : tr('shiftForm.errors.rate_not_positive');
    setNewEmployerNameError(nameError);
    setNewEmployerRateError(rateError);
    if (nameError || rateError) return;
    const created = addEmployer({
      name: newEmployerName.trim(),
      color: nextColor(),
      defaultHourlyRate: rate!,
      deductionRateBp: defaultDeductionRateBp,
    });
    setEmployerId(created.id);
    setRoleId(null);
    setRateText(centsToInput(rate));
    setShowNewEmployer(false);
    setNewEmployerName('');
    setNewEmployerRate('');
  };

  const onAddRole = () => {
    if (!requireWrite()) return;
    if (!employerId) return;
    const rate = parseMoneyToCents(newRoleRate);
    // Inline validation (parity with the employer mini-form).
    if (!newRoleName.trim()) {
      setNewRoleNameError(tr('shiftForm.errors.roleNameRequired'));
      return;
    }
    if (!validateHourlyRateCents(rate).valid) {
      setNewRoleRateError(tr('shiftForm.errors.rate_not_positive'));
      return;
    }
    setNewRoleNameError(null);
    setNewRoleRateError(null);
    const created = addRole({ employerId, name: newRoleName.trim(), hourlyRate: rate! });
    setRoleId(created.id);
    setRateText(centsToInput(rate));
    setShowNewRole(false);
    setNewRoleName('');
    setNewRoleRate('');
  };

  const validateAll = (): { startMin: number; endMin: number; breaks: ShiftBreak[] } | null => {
    const errs: string[] = [];
    if (!employerId) errs.push(tr('shiftForm.errors.selectEmployer'));
    if (!isValidIsoDate(date)) errs.push(tr('shiftForm.errors.invalidDate'));
    if (!parsed) {
      errs.push(tr('shiftForm.errors.invalidTime'));
      setErrors(errs);
      return null;
    }
    if (
      !validateHourlyRateCents(effectiveRate).valid ||
      (rateText.trim() !== '' && parseMoneyToCents(rateText) == null)
    ) {
      errs.push(tr('shiftForm.errors.rate_not_positive'));
    }
    if (
      (plannedExpectedTipsText.trim() !== '' &&
        (plannedExpectedTips == null || plannedExpectedTips < 0)) ||
      (plannedOtherIncomeText.trim() !== '' &&
        (plannedOtherIncome == null || plannedOtherIncome < 0))
    ) {
      errs.push(tr('shiftForm.errors.invalidNumber'));
    }
    const rawEndMin = parseHHMM(endText) ?? parsed.endMin;
    const result = validateShiftWindow({ ...parsed, endMin: rawEndMin });
    for (const code of result.errors) {
      errs.push(tr(`shiftForm.errors.${code as ValidationError}`));
    }
    setErrors(errs);
    return errs.length === 0 ? parsed : null;
  };

  const buildInput = (p: { startMin: number; endMin: number; breaks: ShiftBreak[] }) => ({
    employerId: employerId!,
    roleId,
    date,
    startMin: p.startMin,
    endMin: p.endMin,
    breaks: p.breaks,
    hourlyRateSnapshot: effectiveRate,
    plannedExpectedTips,
    plannedOtherIncome,
    notes: notes.trim() || null,
  });

  const onSave = async (addAnother: boolean) => {
    if (!requireWrite()) return;
    // DEF-13: ignore re-entrant taps while a save is in flight.
    if (savingRef.current) return;
    savingRef.current = true;
    setSaving(true);
    const release = () => {
      savingRef.current = false;
      setSaving(false);
    };
    const p = validateAll();
    if (!p) {
      release();
      return;
    }
    try {
      if (editing) {
        await updateScheduled(editing.id, buildInput(p));
        router.dismissTo(SCHEDULE_ROUTE);
        return;
      }
      const created = await addShift(buildInput(p));
      if (unplanned) {
        router.replace({ pathname: '/complete/[id]', params: { id: created.id } });
        return;
      }
      if (addAnother) {
        setErrors([]);
        // keep employer/role/rate/times; user usually changes the date next
      } else {
        router.dismissTo(SCHEDULE_ROUTE);
      }
    } finally {
      release();
    }
  };

  const onDelete = () => {
    if (!requireWrite()) return;
    if (!editing) return;
    Alert.alert(tr('shiftForm.deleteShift'), undefined, [
      { text: tr('common.cancel'), style: 'cancel' },
      {
        text: tr('common.delete'),
        style: 'destructive',
        onPress: () => {
          void (async () => {
            await deleteShift(editing.id);
            router.dismissTo(SCHEDULE_ROUTE);
          })();
        },
      },
    ]);
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 16, paddingBottom: 48 }}
      keyboardShouldPersistTaps="handled"
    >
      <Stack.Screen
        options={{
          title: screenTitle,
        }}
      />

      <WriteAccessBanner />

      <ReceiptCard style={{ marginBottom: 16 }}>
      {/* Employer */}
      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 6 }}>
        {tr('shiftForm.employer')}
      </Text>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
        {employers.map((e) => (
          <Chip
            key={e.id}
            label={e.name}
            color={e.color}
            selected={e.id === employerId}
            onPress={() => {
              setEmployerId(e.id);
              setRoleId(null);
              setRateText(centsToInput(e.defaultHourlyRate));
            }}
          />
        ))}
        <Chip
          label={`＋ ${tr('shiftForm.addEmployer')}`}
          onPress={() => setShowNewEmployer((v) => !v)}
        />
      </View>

      {showNewEmployer ? (
        <Card style={{ padding: 12, marginBottom: 12 }}>
          <Field
            label={tr('shiftForm.employerName')}
            value={newEmployerName}
            onChangeText={(text) => {
              setNewEmployerName(text);
              if (newEmployerNameError) setNewEmployerNameError(null);
            }}
            error={newEmployerNameError}
          />
          <Field
            label={tr('shiftForm.hourlyRate')}
            value={newEmployerRate}
            onChangeText={(text) => {
              setNewEmployerRate(text);
              if (newEmployerRateError) setNewEmployerRateError(null);
            }}
            keyboardType="decimal-pad"
            error={newEmployerRateError}
          />
          <PrimaryButton label={tr('common.save')} onPress={onAddEmployer} />
        </Card>
      ) : null}

      {/* Role */}
      {employer ? (
        <>
          <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 6 }}>
            {tr('shiftForm.role')}
          </Text>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
            <Chip
              label={tr('shiftForm.noRole')}
              selected={roleId === null}
              onPress={() => {
                setRoleId(null);
                setRateText(centsToInput(employer.defaultHourlyRate));
              }}
            />
            {roles.map((r) => (
              <Chip
                key={r.id}
                label={`${r.name} · ${money(r.hourlyRate)}/h`}
                selected={r.id === roleId}
                onPress={() => {
                  setRoleId(r.id);
                  setRateText(centsToInput(r.hourlyRate));
                }}
              />
            ))}
            <Chip label={`＋ ${tr('shiftForm.addRole')}`} onPress={() => setShowNewRole((v) => !v)} />
          </View>
          {showNewRole ? (
            <Card style={{ padding: 12, marginBottom: 12 }}>
              <Field
                label={tr('shiftForm.roleName')}
                value={newRoleName}
                onChangeText={(text) => {
                  setNewRoleName(text);
                  if (newRoleNameError) setNewRoleNameError(null);
                }}
                error={newRoleNameError}
              />
              <Field
                label={tr('shiftForm.hourlyRate')}
                value={newRoleRate}
                onChangeText={(text) => {
                  setNewRoleRate(text);
                  if (newRoleRateError) setNewRoleRateError(null);
                }}
                keyboardType="decimal-pad"
                error={newRoleRateError}
              />
              <PrimaryButton label={tr('common.save')} onPress={onAddRole} />
            </Card>
          ) : null}
        </>
      ) : null}

      <Field
        label={tr('shiftForm.hourlyRate')}
        value={rateText}
        onChangeText={setRateText}
        keyboardType="decimal-pad"
        placeholder={localizedMoneyPlaceholder(i18n.language)}
      />
      <Field
        label={`${tr('shiftForm.plannedExpectedTips')} (${tr('common.optional')})`}
        value={plannedExpectedTipsText}
        onChangeText={setPlannedExpectedTipsText}
        keyboardType="decimal-pad"
      />
      <Field
        label={`${tr('shiftForm.plannedOtherIncome')} (${tr('common.optional')})`}
        value={plannedOtherIncomeText}
        onChangeText={setPlannedOtherIncomeText}
        keyboardType="decimal-pad"
      />
      <Field
        label={`${tr('templates.notes')} (${tr('common.optional')})`}
        value={notes}
        onChangeText={setNotes}
        multiline
      />
      <DatePickerField
        label={tr('shiftForm.date')}
        value={date}
        onChange={setDate}
      />
      <View style={{ flexDirection: 'row', gap: 12 }}>
        <View style={{ flex: 1 }}>
          <TimePickerField
            label={tr('shiftForm.start')}
            value={parseHHMM(startText) ?? 0}
            onChange={(minutes) => setStartText(minutesToHHMM(minutes))}
            hint={tr('shiftForm.timeFormatHint')}
          />
        </View>
        <View style={{ flex: 1 }}>
          <TimePickerField
            label={tr('shiftForm.end')}
            value={parseHHMM(endText) ?? 0}
            onChange={(minutes) => setEndText(minutesToHHMM(minutes))}
          />
          {/* DEF-06: explicit overnight cue */}
          {isOvernight ? (
            <Text
              style={{
                color: t.cobaltLink,
                backgroundColor: t.cobaltSoft,
                paddingHorizontal: 4,
                fontSize: 12,
                fontWeight: '700',
                marginTop: -8,
                marginBottom: 8,
              }}
            >
              {tr('shiftForm.overnight')}
            </Text>
          ) : null}
        </View>
      </View>

      {/* Optional unpaid break */}
      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 6 }}>
        {tr('shiftForm.breakSection')}
      </Text>
      <View style={{ flexDirection: 'row', gap: 8, marginBottom: 12 }}>
        <Chip label={tr('shiftForm.breakNone')} selected={!hasBreak} onPress={() => setHasBreak(false)} />
        <Chip label={tr('shiftForm.breakSection')} selected={hasBreak} onPress={() => setHasBreak(true)} />
      </View>
      {hasBreak ? (
        <View style={{ flexDirection: 'row', gap: 12 }}>
          <View style={{ flex: 1 }}>
            <TimePickerField
              label={tr('shiftForm.breakStart')}
              value={parseHHMM(breakStartText) ?? 0}
              onChange={(minutes) => setBreakStartText(minutesToHHMM(minutes))}
            />
          </View>
          <View style={{ flex: 1 }}>
            <Field
              label={tr('shiftForm.breakDuration')}
              value={breakDurText}
              onChangeText={setBreakDurText}
              keyboardType="number-pad"
            />
          </View>
        </View>
      ) : null}

      <ReceiptRule />
      <LineItem
        label={tr('shiftForm.expectedPreview')}
        value={preview != null ? money(preview) : '—'}
        strong
      />
      </ReceiptCard>

      {/* DEF-01: non-blocking cross-employer overlap warning */}
      {overlapNames.length > 0 ? (
        <View
          accessibilityRole="alert"
          style={{
            backgroundColor: t.amberSoft,
            borderRadius: 0,
            padding: 12,
            marginBottom: 12,
          }}
        >
          <Text style={{ color: t.amber, fontWeight: '600', fontSize: 13 }}>
            ⚠ {tr('shiftForm.overlapWarning', { shifts: overlapNames.join(', ') })}
          </Text>
        </View>
      ) : null}

      {errors.length > 0 ? (
        <View style={{ marginBottom: 12 }}>
          {errors.map((e) => (
            <Text key={e} style={{ color: t.paper, backgroundColor: t.red, padding: 6, fontSize: 13, marginBottom: 2 }}>
              {e}
            </Text>
          ))}
        </View>
      ) : null}

      <PrimaryButton
        label={tr('common.save')}
        onPress={() => onSave(false)}
        disabled={saving}
        style={{ marginBottom: 8 }}
      />
      {!editing && !unplanned ? (
        <GhostButton
          label={tr('shiftForm.saveAndAddAnother')}
          onPress={() => onSave(true)}
          style={{ marginBottom: 8 }}
        />
      ) : (
        <GhostButton label={tr('shiftForm.deleteShift')} onPress={onDelete} danger style={{ marginBottom: 8 }} />
      )}
    </ScrollView>
  );
}
