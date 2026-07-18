import React, { useMemo, useRef, useState } from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { useEmployersStore } from '../src/state/employersStore';
import { useShiftsStore } from '../src/state/shiftsStore';
import { useSettingsStore } from '../src/state/settingsStore';
import { EMPLOYER_PALETTE, useTokens } from '../src/ui/tokens';
import { Card, Chip, Field, GhostButton, money, PrimaryButton } from '../src/ui/components';
import { expectedEarnings } from '../src/domain/calc';
import { isValidIsoDate, minutesToHHMM, parseHHMM, todayIso } from '../src/domain/dates';
import { findOverlaps } from '../src/domain/overlap';
import { validateShiftWindow, type ValidationError } from '../src/domain/validate';
import type { ShiftBreak } from '../src/domain/types';

export default function ShiftFormScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ id?: string; date?: string }>();
  const { t } = useTokens();
  const { t: tr } = useTranslation();

  const employers = useEmployersStore((s) => s.employers);
  const addEmployer = useEmployersStore((s) => s.addEmployer);
  const rolesAll = useEmployersStore((s) => s.roles);
  const addRole = useEmployersStore((s) => s.addRole);
  const defaultDeductionRate = useSettingsStore((s) => s.defaultDeductionRate);

  const shifts = useShiftsStore((s) => s.shifts);
  const getById = useShiftsStore((s) => s.getById);
  const addShift = useShiftsStore((s) => s.addShift);
  const updateScheduled = useShiftsStore((s) => s.updateScheduled);
  const deleteShift = useShiftsStore((s) => s.deleteShift);

  const editing = params.id ? getById(params.id) : undefined;

  const [employerId, setEmployerId] = useState<string | null>(editing?.employerId ?? employers[0]?.id ?? null);
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
    editing ? String(editing.hourlyRateSnapshot) : ''
  );
  const [errors, setErrors] = useState<string[]>([]);
  // DEF-13: re-entrancy guard against double-tap duplicate saves.
  const [saving, setSaving] = useState(false);
  const savingRef = useRef(false);

  // Inline "add employer" mini-form
  const [showNewEmployer, setShowNewEmployer] = useState(false);
  const [newEmployerName, setNewEmployerName] = useState('');
  const [newEmployerRate, setNewEmployerRate] = useState('');
  const [newEmployerError, setNewEmployerError] = useState<string | null>(null);

  // Inline "add role" mini-form
  const [showNewRole, setShowNewRole] = useState(false);
  const [newRoleName, setNewRoleName] = useState('');
  const [newRoleRate, setNewRoleRate] = useState('');
  const [newRoleError, setNewRoleError] = useState<string | null>(null);

  const roles = useMemo(
    () => rolesAll.filter((r) => r.employerId === employerId),
    [rolesAll, employerId]
  );
  const employer = employers.find((e) => e.id === employerId);

  const effectiveRate = useMemo(() => {
    const parsed = Number(rateText.replace(',', '.'));
    if (rateText.trim() !== '' && Number.isFinite(parsed)) return parsed;
    const role = roles.find((r) => r.id === roleId);
    return role?.hourlyRate ?? 0;
  }, [rateText, roles, roleId]);

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
    });
  }, [parsed, effectiveRate]);

  const nextColor = () => EMPLOYER_PALETTE[employers.length % EMPLOYER_PALETTE.length];

  const onAddEmployer = () => {
    const rate = Number(newEmployerRate.replace(',', '.'));
    // DEF-11: surface an inline error instead of failing silently.
    if (!newEmployerName.trim()) {
      setNewEmployerError(tr('shiftForm.errors.employerNameRequired'));
      return;
    }
    if (!Number.isFinite(rate) || rate < 0) {
      setNewEmployerError(tr('shiftForm.errors.invalidNumber'));
      return;
    }
    setNewEmployerError(null);
    const created = addEmployer({
      name: newEmployerName.trim(),
      color: nextColor(),
      deductionRate: defaultDeductionRate,
    });
    setEmployerId(created.id);
    setRoleId(null);
    setRateText(String(rate));
    // Store the employer default rate as a role-less base by creating a default role.
    addRole({ employerId: created.id, name: tr('shiftForm.role'), hourlyRate: rate });
    setShowNewEmployer(false);
    setNewEmployerName('');
    setNewEmployerRate('');
  };

  const onAddRole = () => {
    if (!employerId) return;
    const rate = Number(newRoleRate.replace(',', '.'));
    // Inline validation (parity with the employer mini-form).
    if (!newRoleName.trim()) {
      setNewRoleError(tr('shiftForm.errors.roleNameRequired'));
      return;
    }
    if (!Number.isFinite(rate) || rate < 0) {
      setNewRoleError(tr('shiftForm.errors.invalidNumber'));
      return;
    }
    setNewRoleError(null);
    const created = addRole({ employerId, name: newRoleName.trim(), hourlyRate: rate });
    setRoleId(created.id);
    setRateText(String(rate));
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
    if (effectiveRate < 0 || !Number.isFinite(effectiveRate)) {
      errs.push(tr('shiftForm.errors.invalidNumber'));
    }
    const result = validateShiftWindow(parsed);
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
  });

  const onSave = (addAnother: boolean) => {
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
    if (editing) {
      updateScheduled(editing.id, buildInput(p));
      router.back();
      return;
    }
    addShift(buildInput(p));
    if (addAnother) {
      setErrors([]);
      // keep employer/role/rate/times; user usually changes the date next
      release();
    } else {
      router.back();
    }
  };

  const onDelete = () => {
    if (!editing) return;
    Alert.alert(tr('shiftForm.deleteShift'), undefined, [
      { text: tr('common.cancel'), style: 'cancel' },
      {
        text: tr('common.delete'),
        style: 'destructive',
        onPress: () => {
          deleteShift(editing.id);
          router.back();
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
        options={{ title: editing ? tr('shiftForm.editTitle') : tr('shiftForm.addTitle') }}
      />

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
              if (newEmployerError) setNewEmployerError(null);
            }}
            error={newEmployerError}
          />
          <Field
            label={tr('shiftForm.hourlyRate')}
            value={newEmployerRate}
            onChangeText={setNewEmployerRate}
            keyboardType="decimal-pad"
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
              onPress={() => setRoleId(null)}
            />
            {roles.map((r) => (
              <Chip
                key={r.id}
                label={`${r.name} · ${money(r.hourlyRate)}/h`}
                selected={r.id === roleId}
                onPress={() => {
                  setRoleId(r.id);
                  setRateText(String(r.hourlyRate));
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
                  if (newRoleError) setNewRoleError(null);
                }}
                error={newRoleError}
              />
              <Field
                label={tr('shiftForm.hourlyRate')}
                value={newRoleRate}
                onChangeText={setNewRoleRate}
                keyboardType="decimal-pad"
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
        placeholder="15.00"
      />
      <Field
        label={tr('shiftForm.date')}
        value={date}
        onChangeText={setDate}
        hint={tr('shiftForm.dateFormatHint')}
        autoCapitalize="none"
      />
      <View style={{ flexDirection: 'row', gap: 12 }}>
        <View style={{ flex: 1 }}>
          <Field
            label={tr('shiftForm.start')}
            value={startText}
            onChangeText={setStartText}
            hint={tr('shiftForm.timeFormatHint')}
            autoCapitalize="none"
          />
        </View>
        <View style={{ flex: 1 }}>
          <Field
            label={tr('shiftForm.end')}
            value={endText}
            onChangeText={setEndText}
            autoCapitalize="none"
          />
          {/* DEF-06: explicit overnight cue */}
          {isOvernight ? (
            <Text
              style={{
                color: t.cobaltLink,
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
            <Field
              label={tr('shiftForm.breakStart')}
              value={breakStartText}
              onChangeText={setBreakStartText}
              autoCapitalize="none"
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

      {/* Live expected preview */}
      <Card style={{ padding: 14, marginBottom: 16, alignItems: 'center' }}>
        <Text style={{ color: t.softText, fontSize: 11, fontWeight: '600', letterSpacing: 0.8 }}>
          {tr('shiftForm.expectedPreview').toUpperCase()}
        </Text>
        <Text style={{ color: t.ink, fontWeight: '700', fontSize: 24, marginTop: 4 }}>
          {preview != null ? money(preview) : '—'}
        </Text>
      </Card>

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
            <Text key={e} style={{ color: t.danger, fontSize: 13, marginBottom: 2 }}>
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
      {!editing ? (
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
