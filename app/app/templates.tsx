import React, { useMemo, useState } from 'react';
import { Alert, Pressable, ScrollView, Text, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { uuid } from '../src/data/ids';
import { previewRecurrence, applyTemplateOnDate, type RecurringShiftPlan } from '../src/domain/copyWeek';
import { isValidIsoDate, minutesToHHMM, todayIso } from '../src/domain/dates';
import type { RecurrenceRule, ScheduleTemplate, ShiftBreak } from '../src/domain/types';
import { validateShiftWindow } from '../src/domain/validate';
import { useEmployersStore } from '../src/state/employersStore';
import { useShiftsStore } from '../src/state/shiftsStore';
import { useTemplatesStore } from '../src/state/templatesStore';
import { Card, Chip, Field, GhostButton, PrimaryButton } from '../src/ui/components';
import { DatePickerField, TimePickerField } from '../src/ui/DateTimeField';
import { useTokens } from '../src/ui/tokens';
import { useWriteAccess, WriteAccessBanner } from '../src/ui/WriteAccess';
import { centsToInput, parseMoneyToCents } from '../src/domain/money';

const WEEKDAYS = [0, 1, 2, 3, 4, 5, 6];

function weekdayForDate(iso: string): number {
  const [year, month, day] = iso.split('-').map(Number);
  const sundayBased = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  return sundayBased === 0 ? 6 : sundayBased - 1;
}

export default function TemplatesScreen() {
  const { t } = useTokens();
  const { t: tr, i18n } = useTranslation();
  const employers = useEmployersStore((state) => state.employers).filter((item) => !item.archived);
  const roles = useEmployersStore((state) => state.roles);
  const shifts = useShiftsStore((state) => state.shifts);
  const addShift = useShiftsStore((state) => state.addShift);
  const loadShifts = useShiftsStore((state) => state.load);
  const templates = useTemplatesStore((state) => state.templates);
  const addTemplate = useTemplatesStore((state) => state.addTemplate);
  const updateTemplate = useTemplatesStore((state) => state.updateTemplate);
  const archiveTemplate = useTemplatesStore((state) => state.archiveTemplate);
  const rules = useTemplatesStore((state) => state.rules);
  const saveRecurringSeries = useTemplatesStore((state) => state.saveSeries);
  const endRule = useTemplatesStore((state) => state.endRule);
  const { requireWrite } = useWriteAccess();

  const [editingId, setEditingId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [employerId, setEmployerId] = useState<string | null>(employers[0]?.id ?? null);
  const [roleId, setRoleId] = useState<string | null>(null);
  const [startMin, setStartMin] = useState(9 * 60);
  const [endMin, setEndMin] = useState(17 * 60);
  const [hasBreak, setHasBreak] = useState(false);
  const [breakStartMin, setBreakStartMin] = useState(13 * 60);
  const [breakDuration, setBreakDuration] = useState('30');
  const [notes, setNotes] = useState('');
  const [plannedExpectedTipsText, setPlannedExpectedTipsText] = useState('');
  const [plannedOtherIncomeText, setPlannedOtherIncomeText] = useState('');
  const [formError, setFormError] = useState<string | null>(null);
  const [applyDate, setApplyDate] = useState(todayIso());

  const [recurringTemplateId, setRecurringTemplateId] = useState<string | null>(null);
  const [editingRuleId, setEditingRuleId] = useState<string | null>(null);
  const [ruleId, setRuleId] = useState(() => uuid());
  const [cadenceWeeks, setCadenceWeeks] = useState<1 | 2>(1);
  const [weekdays, setWeekdays] = useState<number[]>([weekdayForDate(todayIso())]);
  const [occurrenceCount, setOccurrenceCount] = useState('8');
  const [recurrenceEndDate, setRecurrenceEndDate] = useState('');
  const [preview, setPreview] = useState<RecurringShiftPlan[]>([]);
  const [excludedKeys, setExcludedKeys] = useState<string[]>([]);
  const [replaceDuplicates, setReplaceDuplicates] = useState(false);

  const employer = employers.find((item) => item.id === employerId);
  const employerRoles = roles.filter((item) => item.employerId === employerId);

  const rateForTemplate = (template: ScheduleTemplate): number => {
    const role = template.roleId ? roles.find((item) => item.id === template.roleId) : undefined;
    const owner = employers.find((item) => item.id === template.employerId);
    return role?.hourlyRate ?? owner?.defaultHourlyRate ?? 0;
  };

  const resetForm = () => {
    setEditingId(null);
    setName('');
    setEmployerId(employers[0]?.id ?? null);
    setRoleId(null);
    setStartMin(9 * 60);
    setEndMin(17 * 60);
    setHasBreak(false);
    setBreakStartMin(13 * 60);
    setBreakDuration('30');
    setNotes('');
    setPlannedExpectedTipsText('');
    setPlannedOtherIncomeText('');
    setFormError(null);
  };

  const saveTemplate = () => {
    if (!requireWrite()) return;
    const duration = Number(breakDuration);
    const normalizedEnd = endMin <= startMin ? endMin + 1440 : endMin;
    const normalizedBreak = breakStartMin < startMin ? breakStartMin + 1440 : breakStartMin;
    const breaks: ShiftBreak[] = hasBreak
      ? [{ label: tr('shiftForm.breakSection'), startMin: normalizedBreak, durationMin: duration, paid: false }]
      : [];
    if (!name.trim() || !employerId || (hasBreak && !Number.isFinite(duration))) {
      setFormError(tr('templates.invalid'));
      return;
    }
    if (!validateShiftWindow({ startMin, endMin: normalizedEnd, breaks }).valid) {
      setFormError(tr('templates.invalid'));
      return;
    }
    const draft = {
      name: name.trim(),
      employerId,
      roleId,
      startMin,
      endMin: normalizedEnd,
      breaks,
      plannedExpectedTips:
        plannedExpectedTipsText.trim() === '' ? null : parseMoneyToCents(plannedExpectedTipsText),
      plannedOtherIncome:
        plannedOtherIncomeText.trim() === '' ? null : parseMoneyToCents(plannedOtherIncomeText),
      notes: notes.trim() || null,
    };
    if (
      (plannedExpectedTipsText.trim() !== '' &&
        (draft.plannedExpectedTips == null || draft.plannedExpectedTips < 0)) ||
      (plannedOtherIncomeText.trim() !== '' &&
        (draft.plannedOtherIncome == null || draft.plannedOtherIncome < 0))
    ) {
      setFormError(tr('templates.invalid'));
      return;
    }
    const existing = templates.find((item) => item.id === editingId);
    if (existing) updateTemplate({ ...existing, ...draft });
    else addTemplate(draft);
    resetForm();
  };

  const editTemplate = (template: ScheduleTemplate) => {
    setEditingId(template.id);
    setName(template.name);
    setEmployerId(template.employerId);
    setRoleId(template.roleId ?? null);
    setStartMin(template.startMin);
    setEndMin(template.endMin % 1440);
    const firstBreak = template.breaks[0];
    setHasBreak(!!firstBreak);
    setBreakStartMin(firstBreak?.startMin % 1440 || 13 * 60);
    setBreakDuration(String(firstBreak?.durationMin ?? 30));
    setNotes(template.notes ?? '');
    setPlannedExpectedTipsText(centsToInput(template.plannedExpectedTips));
    setPlannedOtherIncomeText(centsToInput(template.plannedOtherIncome));
    setFormError(null);
  };

  const useOnce = async (template: ScheduleTemplate) => {
    if (!requireWrite()) return;
    const plan = applyTemplateOnDate(template, applyDate, rateForTemplate(template));
    const duplicate = shifts.some(
      (shift) =>
        shift.status === 'planned' &&
        shift.employerId === plan.employerId &&
        shift.date === plan.date &&
        shift.startMin === plan.startMin &&
        shift.endMin === plan.endMin
    );
    if (duplicate) {
      Alert.alert(tr('templates.duplicate'));
      return;
    }
    await addShift(plan);
    Alert.alert(tr('templates.saved'));
  };

  const buildRule = (template: ScheduleTemplate): RecurrenceRule | null => {
    const count = occurrenceCount.trim() === '' ? null : Number(occurrenceCount);
    const endDate = recurrenceEndDate.trim() || null;
    if (
      weekdays.length === 0 ||
      (count == null && endDate == null) ||
      (count != null && (!Number.isInteger(count) || count < 1)) ||
      (endDate != null && (!isValidIsoDate(endDate) || endDate < applyDate))
    ) return null;
    return {
      id: ruleId,
      templateId: template.id,
      cadenceWeeks,
      weekdays,
      startDate: applyDate,
      endDate,
      occurrenceCount: count,
      active: true,
    };
  };

  const previewRule = (template: ScheduleTemplate) => {
    const rule = buildRule(template);
    if (!rule) {
      setFormError(tr('templates.invalid'));
      return;
    }
    const plans = previewRecurrence(template, rule, rateForTemplate(template), shifts);
    setPreview(plans);
    setExcludedKeys(plans.filter((item) => item.conflict === 'duplicate').map((item) => item.recurrenceKey!));
  };

  const saveSeries = async (template: ScheduleTemplate) => {
    if (!requireWrite()) return;
    const rule = buildRule(template);
    if (!rule || preview.length === 0) return;
    try {
      saveRecurringSeries({ rule, preview, excludedKeys, replaceDuplicates });
      await loadShifts();
    } catch (error) {
      if (error instanceof Error && error.message === 'recurrence_preview_stale') {
        previewRule(template);
        Alert.alert(tr('templates.previewChanged'));
        return;
      }
      if (error instanceof Error && error.message === 'recurrence_conflict_unresolved') {
        Alert.alert(tr('templates.conflictUnresolved'));
        return;
      }
      setFormError(tr('templates.invalid'));
      return;
    }
    setPreview([]);
    setExcludedKeys([]);
    setRuleId(uuid());
    setEditingRuleId(null);
    setRecurringTemplateId(null);
    Alert.alert(tr('templates.saved'));
  };

  const editRule = (rule: RecurrenceRule) => {
    setEditingRuleId(rule.id);
    setRuleId(rule.id);
    setRecurringTemplateId(rule.templateId);
    setCadenceWeeks(rule.cadenceWeeks);
    setWeekdays([...rule.weekdays]);
    setApplyDate(rule.startDate);
    setOccurrenceCount(rule.occurrenceCount == null ? '' : String(rule.occurrenceCount));
    setRecurrenceEndDate(rule.endDate ?? '');
    setPreview([]);
    setExcludedKeys([]);
  };

  const weekdayLabels = useMemo(() => {
    const monday = new Date(Date.UTC(2026, 6, 13));
    return WEEKDAYS.map((offset) =>
      new Intl.DateTimeFormat(i18n.language, { weekday: 'narrow', timeZone: 'UTC' }).format(
        new Date(monday.getTime() + offset * 86_400_000)
      )
    );
  }, [i18n.language]);

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 16, paddingBottom: 48 }}
      keyboardShouldPersistTaps="handled"
    >
      <Stack.Screen options={{ title: tr('templates.title') }} />

      <WriteAccessBanner />

      <Card style={{ padding: 14, marginBottom: 16 }}>
        <Text style={{ color: t.ink, fontSize: 18, fontWeight: '700', marginBottom: 12 }}>
          {tr(editingId ? 'templates.editTitle' : 'templates.newTitle')}
        </Text>
        <Field label={tr('templates.name')} value={name} onChangeText={setName} />
        <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 6 }}>
          {tr('shiftForm.employer')}
        </Text>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
          {employers.map((item) => (
            <Chip
              key={item.id}
              label={item.name}
              selected={item.id === employerId}
              color={item.color}
              onPress={() => {
                setEmployerId(item.id);
                setRoleId(null);
              }}
            />
          ))}
        </View>
        {employer ? (
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
            <Chip label={tr('shiftForm.noRole')} selected={roleId === null} onPress={() => setRoleId(null)} />
            {employerRoles.map((role) => (
              <Chip key={role.id} label={role.name} selected={role.id === roleId} onPress={() => setRoleId(role.id)} />
            ))}
          </View>
        ) : null}
        <View style={{ flexDirection: 'row', gap: 12 }}>
          <View style={{ flex: 1 }}>
            <TimePickerField label={tr('shiftForm.start')} value={startMin} onChange={setStartMin} />
          </View>
          <View style={{ flex: 1 }}>
            <TimePickerField label={tr('shiftForm.end')} value={endMin} onChange={setEndMin} />
          </View>
        </View>
        <View style={{ flexDirection: 'row', gap: 8, marginBottom: 12 }}>
          <Chip label={tr('shiftForm.breakNone')} selected={!hasBreak} onPress={() => setHasBreak(false)} />
          <Chip label={tr('shiftForm.breakSection')} selected={hasBreak} onPress={() => setHasBreak(true)} />
        </View>
        {hasBreak ? (
          <View style={{ flexDirection: 'row', gap: 12 }}>
            <View style={{ flex: 1 }}>
              <TimePickerField label={tr('shiftForm.breakStart')} value={breakStartMin} onChange={setBreakStartMin} />
            </View>
            <View style={{ flex: 1 }}>
              <Field
                label={tr('shiftForm.breakDuration')}
                value={breakDuration}
                onChangeText={setBreakDuration}
                keyboardType="number-pad"
              />
            </View>
          </View>
        ) : null}
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
        <Field label={tr('templates.notes')} value={notes} onChangeText={setNotes} multiline />
        {formError ? (
          <Text style={{ color: '#FFFFFF', backgroundColor: t.dangerBg, padding: 6, marginBottom: 8 }}>
            {formError}
          </Text>
        ) : null}
        <PrimaryButton label={tr(editingId ? 'templates.update' : 'templates.create')} onPress={saveTemplate} />
        {editingId ? <GhostButton label={tr('common.cancel')} onPress={resetForm} style={{ marginTop: 8 }} /> : null}
      </Card>

      <DatePickerField label={tr('templates.useDate')} value={applyDate} onChange={setApplyDate} />

      {templates.length === 0 ? (
        <Text style={{ color: t.softText }}>{tr('templates.empty')}</Text>
      ) : (
        templates.map((template) => {
          const owner = employers.find((item) => item.id === template.employerId);
          const isRecurring = recurringTemplateId === template.id;
          return (
            <Card key={template.id} style={{ padding: 14, marginBottom: 14 }}>
              <Text style={{ color: t.ink, fontSize: 17, fontWeight: '700' }}>{template.name}</Text>
              <Text style={{ color: t.softText, marginTop: 4 }}>
                {owner?.name ?? '—'} · {minutesToHHMM(template.startMin)}–{minutesToHHMM(template.endMin)}
              </Text>
              <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 }}>
                {!template.archived ? (
                  <>
                            <GhostButton label={tr('templates.useOnce')} onPress={() => void useOnce(template)} />
                    <GhostButton
                      label={tr('templates.recurring')}
                      onPress={() => {
                        setRecurringTemplateId(isRecurring ? null : template.id);
                        setPreview([]);
                      }}
                    />
                  </>
                ) : null}
                <GhostButton label={tr('templates.edit')} onPress={() => editTemplate(template)} />
                <GhostButton
                  label={tr(template.archived ? 'templates.unarchive' : 'templates.archive')}
                  onPress={() => {
                    if (requireWrite()) archiveTemplate(template.id, !template.archived);
                  }}
                  danger={!template.archived}
                />
              </View>

              {isRecurring ? (
                <View style={{ borderTopWidth: 1, borderTopColor: t.line, marginTop: 14, paddingTop: 14 }}>
                  <View style={{ flexDirection: 'row', gap: 8, marginBottom: 12 }}>
                    <Chip label={tr('templates.weekly')} selected={cadenceWeeks === 1} onPress={() => setCadenceWeeks(1)} />
                    <Chip label={tr('templates.biweekly')} selected={cadenceWeeks === 2} onPress={() => setCadenceWeeks(2)} />
                  </View>
                  <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 6 }}>
                    {tr('templates.weekdays')}
                  </Text>
                  <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
                    {WEEKDAYS.map((day) => (
                      <Chip
                        key={day}
                        label={weekdayLabels[day]}
                        selected={weekdays.includes(day)}
                        onPress={() =>
                          setWeekdays((items) =>
                            items.includes(day) ? items.filter((item) => item !== day) : [...items, day]
                          )
                        }
                      />
                    ))}
                  </View>
                  <Field
                    label={tr('templates.occurrenceCount')}
                    value={occurrenceCount}
                    onChangeText={setOccurrenceCount}
                    keyboardType="number-pad"
                  />
                  <Field
                    label={tr('templates.endDate')}
                    value={recurrenceEndDate}
                    onChangeText={setRecurrenceEndDate}
                    placeholder={tr('shiftForm.dateFormatHint')}
                  />
                  <GhostButton label={tr('templates.preview')} onPress={() => previewRule(template)} />

                  {preview.length > 0 ? (
                    <View style={{ marginTop: 12 }}>
                      {preview.map((plan) => {
                        const excluded = excludedKeys.includes(plan.recurrenceKey!);
                        return (
                          <Pressable
                            key={plan.recurrenceKey}
                            onPress={() =>
                              setExcludedKeys((items) =>
                                excluded
                                  ? items.filter((key) => key !== plan.recurrenceKey)
                                  : [...items, plan.recurrenceKey!]
                              )
                            }
                            style={{ borderTopWidth: 1, borderTopColor: t.line, paddingVertical: 10 }}
                          >
                            <Text style={{ color: t.ink, fontWeight: '600' }}>
                              {plan.date} · {minutesToHHMM(plan.startMin)}–{minutesToHHMM(plan.endMin)}
                            </Text>
                            <Text style={{
                              color: plan.conflict === 'none' ? t.softText : t.amber,
                              backgroundColor: plan.conflict === 'none' ? 'transparent' : t.amberSoft,
                              paddingHorizontal: plan.conflict === 'none' ? 0 : 4,
                              fontSize: 12,
                            }}>
                              {tr(`templates.${plan.conflict}`)} · {tr(excluded ? 'templates.skipped' : 'templates.included')}
                            </Text>
                          </Pressable>
                        );
                      })}
                      <Chip
                        label={tr('templates.replaceDuplicates')}
                        selected={replaceDuplicates}
                        onPress={() => setReplaceDuplicates((value) => !value)}
                      />
                      <PrimaryButton
                        label={tr('templates.saveSeries')}
                        onPress={() => void saveSeries(template)}
                        style={{ marginTop: 10 }}
                      />
                    </View>
                  ) : null}
                </View>
              ) : null}
            </Card>
          );
        })
      )}

      {rules.length > 0 ? (
        <View style={{ marginTop: 8 }}>
          <Text style={{ color: t.ink, fontSize: 18, fontWeight: '700', marginBottom: 10 }}>
            {tr('templates.rulesTitle')}
          </Text>
          {rules.map((rule) => {
            const source = templates.find((template) => template.id === rule.templateId);
            return (
              <Card key={rule.id} style={{ padding: 14, marginBottom: 10 }}>
                <Text style={{ color: t.ink, fontWeight: '700' }}>{source?.name ?? '—'}</Text>
                <Text style={{ color: t.softText, marginTop: 4 }}>
                  {tr(rule.cadenceWeeks === 1 ? 'templates.weekly' : 'templates.biweekly')} · {rule.startDate}
                </Text>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 10 }}>
                  {rule.active ? (
                    <>
                      <GhostButton label={tr('templates.editRule')} onPress={() => editRule(rule)} />
                      <GhostButton
                        label={tr('templates.endRule')}
                        onPress={() => {
                          if (requireWrite()) endRule(rule.id);
                        }}
                        danger
                      />
                    </>
                  ) : (
                    <Text style={{ color: t.softText }}>{tr('templates.inactive')}</Text>
                  )}
                </View>
              </Card>
            );
          })}
        </View>
      ) : null}
    </ScrollView>
  );
}
