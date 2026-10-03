import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Alert, ScrollView, View } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { useShiftsStore } from '../../src/state/shiftsStore';
import { useEmployersStore } from '../../src/state/employersStore';
import { useSettingsStore } from '../../src/state/settingsStore';
import { useTokens } from '../../src/ui/tokens';
import { useWriteAccess, WriteAccessBanner } from '../../src/ui/WriteAccess';
import {
  Card,
  Chip,
  Field,
  GhostButton,
  money,
  PrimaryButton,
  signedMoney,
} from '../../src/ui/components';
import { TimePickerField } from '../../src/ui/DateTimeField';
import { Text } from '../../src/ui/typography';
import {
  actualEarnings,
  effectiveHourly,
  estimatedNet,
  expectedEarnings,
  variance as calcVariance,
} from '../../src/domain/calc';
import { todayIso, minutesToHHMM, parseHHMM } from '../../src/domain/dates';
import {
  validateDeductionBasisPoints,
  validateHourlyRateCents,
  validateMoney,
  validateShiftWindow,
  type ValidationError,
} from '../../src/domain/validate';
import {
  NOT_WORKED_REASONS,
  type NotWorkedReason,
  type Shift,
  type ShiftBreak,
  type TipMethod,
} from '../../src/domain/types';
import { centsToInput, parseMoneyToCents } from '../../src/domain/money';

import { readCompletionDraft, saveCompletionDraft } from '../../src/data/completionDrafts';
import { settingsRepo } from '../../src/data/repositories';
import { paymentsRepo } from '../../src/data/paymentsRepo';
import { FormScreen } from '../../src/ui/FormScreen';

const SCHEDULE_ROUTE = '/(tabs)/schedule' as const;

/** DEF-05: breaks are fully editable at completion (start, duration, taken). */
interface BreakDraft {
  label: string;
  startText: string;
  durText: string;
  paid: boolean;
  taken: boolean;
}

export default function CompleteShiftScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const { requireWrite } = useWriteAccess();

  const getById = useShiftsStore((s) => s.getById);
  const completeShift = useShiftsStore((s) => s.completeShift);
  const correctWorkedToPlanned = useShiftsStore((s) => s.correctWorkedToPlanned);
  const markNotWorked = useShiftsStore((s) => s.markNotWorked);
  const employers = useEmployersStore((s) => s.employers);
  const roles = useEmployersStore((s) => s.roles);
  const currencyCode = useSettingsStore(s=>s.currencyCode);
  const defaultDeductionRateBp = useSettingsStore((s) => s.defaultDeductionRateBp);

  const shift = getById(id);
  const [hasPaymentHistory] = useState(()=>paymentsRepo.list().expected.some(item=>item.shiftId===id));
  const [restored] = useState(() => readCompletionDraft<Record<string, any>>(id, shift?.updatedAt));
  const [receivedNow,setReceivedNow] = useState<string>(restored?.receivedNow ?? '');
  const [expectedLater,setExpectedLater] = useState<string>(restored?.expectedLater ?? '');
  const [draftError, setDraftError] = useState(false);
  const [details, setDetails] = useState(false);
  const isEditingActuals = shift?.status === 'worked';
  const [initialIsEditingActuals] = useState(() => shift?.status === 'worked');
  const [screenTitle] = useState(() =>
    tr(initialIsEditingActuals ? 'complete.editTitle' : 'complete.title')
  );

  const [step, setStep] = useState<1 | 2>(restored?.step ?? 1);
  const [startText, setStartText] = useState(() =>
    restored?.startText ?? (shift ? minutesToHHMM(shift.actualStartMin ?? shift.startMin) : '')
  );
  const [endText, setEndText] = useState(() =>
    restored?.endText ?? (shift ? minutesToHHMM(shift.actualEndMin ?? shift.endMin) : '')
  );
  const [breakDrafts, setBreakDrafts] = useState<BreakDraft[]>(() => {
    if (restored?.breakDrafts) return restored.breakDrafts;
    if (!shift) return [];
    const source = shift.actualBreaks ?? shift.breaks;
    return source.map((b) => ({
      label: b.label,
      startText: minutesToHHMM(b.startMin),
      durText: String(b.durationMin),
      paid: b.paid,
      taken: true,
    }));
  });
  const [tipMethod, setTipMethod] = useState<TipMethod>(restored?.tipMethod ?? shift?.tipMethod ?? (settingsRepo.get(`tipDefault:${shift?.employerId}`) as TipMethod | null) ?? 'direct');
  const [directTipsText, setDirectTipsText] = useState(restored?.directTipsText ?? centsToInput(shift?.directTips));
  const [tipOutText, setTipOutText] = useState(restored?.tipOutText ?? centsToInput(shift?.tipOutPaid));
  const [tipShareText, setTipShareText] = useState(restored?.tipShareText ?? centsToInput(shift?.tipShareReceived));
  const [poolText, setPoolText] = useState(restored?.poolText ?? centsToInput(shift?.poolContribution));
  const [salesText, setSalesText] = useState(restored?.salesText ?? centsToInput(shift?.sales));
  const [otherIncomeText, setOtherIncomeText] = useState(restored?.otherIncomeText ?? centsToInput(shift?.otherIncome));
  const [actualRateText, setActualRateText] = useState(() => {
    if (restored?.actualRateText) return restored.actualRateText;
    if (!shift) return '';
    return centsToInput(
      shift.actualHourlyRateSnapshot ?? shift.hourlyRateSnapshot
    );
  });
  // DEF-07: deduction rate editable per shift, prefilled from snapshot → employer → global.
  const [dedRateText, setDedRateText] = useState(() => {
    if (restored?.dedRateText) return restored.dedRateText;
    if (!shift) return '0';
    const basisPoints =
      shift.deductionRateSnapshotBp ??
      employers.find((e) => e.id === shift.employerId)?.deductionRateBp ??
      defaultDeductionRateBp;
    return String(basisPoints / 100);
  });
  // DEF-12: manual disputed flag (never derived).
  const [showNotWorked, setShowNotWorked] = useState(false);
  const [reasonCode, setReasonCode] = useState<NotWorkedReason | null>(
    shift?.notWorkedReason ?? null
  );
  const [reasonNote, setReasonNote] = useState(shift?.notWorkedNote ?? '');
  const [errors, setErrors] = useState<string[]>([]);
  // DEF-13: re-entrancy guard against double-tap duplicate saves.
  const [saving, setSaving] = useState(false);
  const savingRef = useRef(false);

  const num = (text: string): number => parseMoneyToCents(text) ?? 0;

  const parsedTimes = useMemo(() => {
    const startMin = parseHHMM(startText);
    const endRaw = parseHHMM(endText);
    if (startMin == null || endRaw == null) return null;
    const endMin = endRaw <= startMin ? endRaw + 1440 : endRaw;
    return { startMin, endMin };
  }, [startText, endText]);

  // DEF-06: explicit overnight cue on actual times.
  const isOvernight = useMemo(() => {
    const s = parseHHMM(startText);
    const e = parseHHMM(endText);
    return s != null && e != null && e <= s;
  }, [startText, endText]);

  /** Parse taken break drafts; `invalid` flags unparseable time/duration text. */
  const parsedBreaks = useMemo((): { breaks: ShiftBreak[]; invalid: boolean } => {
    const breaks: ShiftBreak[] = [];
    let invalid = false;
    for (const d of breakDrafts) {
      if (!d.taken) continue;
      const bStart = parseHHMM(d.startText);
      const dur = Number(d.durText);
      if (bStart == null || !Number.isFinite(dur)) {
        invalid = true;
        continue;
      }
      const normStart =
        parsedTimes && bStart < parsedTimes.startMin ? bStart + 1440 : bStart;
      breaks.push({ label: d.label, startMin: normStart, durationMin: dur, paid: d.paid });
    }
    return { breaks, invalid };
  }, [breakDrafts, parsedTimes]);

  useEffect(() => {
    if (!shift || savingRef.current) return;
    try {
      saveCompletionDraft(id, shift.updatedAt, {step,startText,endText,breakDrafts,tipMethod,directTipsText,tipOutText,tipShareText,poolText,salesText,otherIncomeText,actualRateText,dedRateText,receivedNow,expectedLater});
      setDraftError(false);
    } catch { setDraftError(true); }
  }, [id,step,startText,endText,breakDrafts,tipMethod,directTipsText,tipOutText,tipShareText,poolText,salesText,otherIncomeText,actualRateText,dedRateText,receivedNow,expectedLater]);

  if (!shift) {
    return (
      <View style={{ flex: 1, backgroundColor: t.bg, alignItems: 'center', justifyContent: 'center' }}>
        <Text style={{ color: t.softText }}>—</Text>
      </View>
    );
  }

  const employer = employers.find((e) => e.id === shift.employerId);
  const actualHourlyRateSnapshot = num(actualRateText);
  const deductionPercent = Number(dedRateText.replace(',', '.'));
  const deductionRateBp = Number.isFinite(deductionPercent)
    ? Math.round(deductionPercent * 100)
    : Number.NaN;

  const draftShift: Shift = {
    ...shift,
    actualStartMin: parsedTimes?.startMin ?? shift.startMin,
    actualEndMin: parsedTimes?.endMin ?? shift.endMin,
    actualBreaks: parsedBreaks.breaks,
    actualHourlyRateSnapshot,
    tipMethod,
    directTips: num(directTipsText),
    tipOutPaid: num(tipOutText),
    tipShareReceived: num(tipShareText),
    poolContribution: num(poolText),
    sales: salesText.trim() === '' ? null : num(salesText),
    otherIncome: num(otherIncomeText),
    deductionRateSnapshotBp: validateDeductionBasisPoints(deductionRateBp).valid
      ? deductionRateBp
      : 0,
  };

  const expected = expectedEarnings(shift);
  const actual = actualEarnings(draftShift);
  const varianceValue = calcVariance(draftShift);
  const hourly = effectiveHourly(draftShift);
  const net = estimatedNet(draftShift);
  const goToStep2 = () => {
    const errs: string[] = [];
    if (!parsedTimes || parsedBreaks.invalid) {
      errs.push(tr('shiftForm.errors.invalidTime'));
    } else {
      const rawEndMin = parseHHMM(endText) ?? parsedTimes.endMin;
      const result = validateShiftWindow({
        ...parsedTimes,
        endMin: rawEndMin,
        breaks: parsedBreaks.breaks,
      });
      for (const code of result.errors) errs.push(tr(`shiftForm.errors.${code as ValidationError}`));
    }
    setErrors(errs);
    if (errs.length === 0) setStep(2);
  };

  const onAddBreak = () => {
    const startMin = parsedTimes?.startMin ?? shift.startMin;
    const endMin = parsedTimes?.endMin ?? shift.endMin;
    const mid = startMin + Math.floor((endMin - startMin) / 2);
    setBreakDrafts((drafts) => [
      ...drafts,
      {
        label: tr('shiftForm.breakSection'),
        startText: minutesToHHMM(mid),
        durText: '30',
        paid: false,
        taken: true,
      },
    ]);
  };

  const onSave = async () => {
    if (!requireWrite()) return;
    if (!parsedTimes || savingRef.current) return;
    savingRef.current = true;
    setSaving(true);
    const errs: string[] = [];
    if ([directTipsText,tipOutText,tipShareText,poolText,salesText,otherIncomeText].some(value => value.trim() && parseMoneyToCents(value) === null)) errs.push(tr('redesign.saveError'));
    const moneyCheck = validateMoney({
      directTips: num(directTipsText),
      tipOutPaid: num(tipOutText),
      tipShareReceived: num(tipShareText),
      poolContribution: num(poolText),
      sales: salesText.trim() === '' ? null : num(salesText),
      otherIncome: num(otherIncomeText),
    });
    if (!validateHourlyRateCents(parseMoneyToCents(actualRateText)).valid) {
      errs.push(tr('shiftForm.errors.rate_not_positive'));
    }
    if (
      !Number.isFinite(deductionPercent) ||
      deductionPercent < 0 ||
      deductionPercent > 100 ||
      !validateDeductionBasisPoints(deductionRateBp).valid
    ) {
      errs.push(tr('shiftForm.errors.deduction_out_of_range'));
    }
    for (const code of moneyCheck.errors) errs.push(tr(`shiftForm.errors.${code as ValidationError}`));
    setErrors(errs);
    if (errs.length > 0) {
      savingRef.current = false;
      setSaving(false);
      return;
    }

    try {
    const received = receivedNow.trim() ? parseMoneyToCents(receivedNow) : null;
    const later = expectedLater.trim() ? parseMoneyToCents(expectedLater) : null;
    if ((receivedNow.trim() && received === null) || (expectedLater.trim() && later === null)) throw new Error('payment_amount');
    await completeShift(shift.id, {
      settlement: initialIsEditingActuals || hasPaymentHistory ? undefined : { received, later, currency: currencyCode, date: todayIso() },
      actualStartMin: parsedTimes.startMin,
      actualEndMin: parsedTimes.endMin,
      actualBreaks: parsedBreaks.breaks,
      actualHourlyRateSnapshot,
      tipMethod,
      directTips: num(directTipsText),
      poolContribution: num(poolText),
      tipShareReceived: num(tipShareText),
      tipOutPaid: num(tipOutText),
      sales: salesText.trim() === '' ? null : num(salesText),
      otherIncome: num(otherIncomeText),
      deductionRateSnapshotBp: deductionRateBp,
    });
    router.replace({ pathname: '/shift-result/[id]', params: { id: shift.id } });
    } catch { setErrors([tr('redesign.saveError')]); savingRef.current = false; setSaving(false); }
  };

  // DEF-02: canonical reason codes; employer_cancelled → 'cancelled', else 'missed'.
  const noteRequired = reasonCode === 'other';
  const canConfirmNotWorked = reasonCode != null && (!noteRequired || reasonNote.trim() !== '');
  const onMarkNotWorked = async () => {
    if (!requireWrite()) return;
    if (!canConfirmNotWorked || !reasonCode) return;
    const status = reasonCode === 'employer_cancelled' ? 'cancelled' : 'missed';
    await markNotWorked(shift.id, status, reasonCode, reasonNote.trim() || null);
    router.dismissTo(SCHEDULE_ROUTE);
  };

  const onCorrectToPlanned = () => {
    if (!requireWrite()) return;
    Alert.alert(
      tr('complete.correctToPlannedTitle'),
      tr('complete.correctToPlannedMessage'),
      [
        { text: tr('common.cancel'), style: 'cancel' },
        {
          text: tr('complete.correctToPlannedConfirm'),
          style: 'destructive',
          onPress: () => {
            void (async () => {
              await correctWorkedToPlanned(shift.id, true);
              router.dismissTo(SCHEDULE_ROUTE);
            })();
          },
        },
      ]
    );
  };

  return (
    <FormScreen>
      <Stack.Screen options={{ title: screenTitle }} />

      <WriteAccessBanner />
      {restored ? <Text style={{color:t.dim,marginBottom:8}}>{tr('redesign.draftRestored')}</Text> : null}
      {draftError ? <Text accessibilityRole="alert" style={{color:t.red}}>{tr('redesign.draftError')}</Text> : null}

      <Text style={{ color: t.softText, fontSize: 13, marginBottom: 12 }}>
        {employer?.name ?? ''} · {shift.date} · {minutesToHHMM(shift.startMin)}–
        {minutesToHHMM(shift.endMin)}
      </Text>

      {step === 1 ? (
        <>
          <Text fontRole="display" style={{ color: t.ink, fontWeight: '700', fontSize: 20, marginBottom: 12 }}>
            {tr('complete.step1Title')}
          </Text>
          <View style={{ flexDirection: 'row', gap: 12 }}>
            <View style={{ flex: 1 }}>
              <TimePickerField
                label={tr('complete.actualStart')}
                value={parseHHMM(startText) ?? 0}
                onChange={(minutes) => setStartText(minutesToHHMM(minutes))}
                hint={tr('shiftForm.timeFormatHint')}
              />
            </View>
            <View style={{ flex: 1 }}>
              <TimePickerField
                label={tr('complete.actualEnd')}
                value={parseHHMM(endText) ?? 0}
                onChange={(minutes) => setEndText(minutesToHHMM(minutes))}
              />
              {/* DEF-06: explicit overnight cue */}
              {isOvernight ? (
                <Text
                  fontRole="penNote"
                  style={{
                    color: t.pen,
                    backgroundColor: t.cobaltSoft,
                    paddingHorizontal: 4,
                    fontSize: 17,
                    fontWeight: '700',
                    marginTop: -8,
                    marginBottom: 8,
                    transform: [{ rotate: '-1deg' }],
                  }}
                >
                  {tr('shiftForm.overnight')}
                </Text>
              ) : null}
            </View>
          </View>

          <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 6 }}>
            {tr('complete.breaksTaken')}
          </Text>
          {breakDrafts.map((b, i) => (
            <Card key={i} style={{ padding: 12, marginBottom: 8 }}>
              <View
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  marginBottom: 8,
                }}
              >
                <Text style={{ color: t.ink, fontWeight: '600', fontSize: 13 }}>{b.label}</Text>
                <Chip
                  label={b.taken ? tr('complete.breakTaken') : tr('complete.breakSkipped')}
                  selected={b.taken}
                  onPress={() =>
                    setBreakDrafts((drafts) =>
                      drafts.map((d, j) => (j === i ? { ...d, taken: !d.taken } : d))
                    )
                  }
                />
              </View>
              {/* DEF-05: adjust break start/duration at completion */}
              {b.taken ? (
                <View style={{ flexDirection: 'row', gap: 12 }}>
                  <View style={{ flex: 1 }}>
                    <TimePickerField
                      label={tr('shiftForm.breakStart')}
                      value={parseHHMM(b.startText) ?? 0}
                      onChange={(minutes) =>
                        setBreakDrafts((drafts) =>
                          drafts.map((d, j) =>
                            j === i ? { ...d, startText: minutesToHHMM(minutes) } : d
                          )
                        )
                      }
                    />
                  </View>
                  <View style={{ flex: 1 }}>
                    <Field
                      label={tr('shiftForm.breakDuration')}
                      value={b.durText}
                      onChangeText={(text) =>
                        setBreakDrafts((drafts) =>
                          drafts.map((d, j) => (j === i ? { ...d, durText: text } : d))
                        )
                      }
                      keyboardType="number-pad"
                    />
                  </View>
                </View>
              ) : null}
            </Card>
          ))}
          {/* DEF-05: add a break that was not scheduled */}
          <GhostButton
            label={`＋ ${tr('complete.addBreak')}`}
            onPress={onAddBreak}
            style={{ marginBottom: 8 }}
          />

          {errors.map((e) => (
            <Text key={e} accessibilityRole="alert" style={{ color: t.paper, backgroundColor: t.red, padding: 6, fontSize: 13, marginBottom: 4 }}>
              {e}
            </Text>
          ))}

          <PrimaryButton label={tr('common.next')} onPress={goToStep2} style={{ marginTop: 8 }} />
          {!isEditingActuals ? (
            <>
              <GhostButton
                label={tr('complete.markNotWorked')}
                onPress={() => setShowNotWorked((v) => !v)}
                danger
                style={{ marginTop: 8 }}
              />
              {showNotWorked ? (
                <Card style={{ padding: 12, marginTop: 8 }}>
              <Text style={{ color: t.ink, fontWeight: '600', fontSize: 14, marginBottom: 8 }}>
                {tr('complete.notWorkedReason')}
              </Text>
              {/* DEF-02: canonical reason-code picker */}
              <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 10 }}>
                {NOT_WORKED_REASONS.map((code) => (
                  <Chip
                    key={code}
                    label={tr(`complete.reasons.${code}`)}
                    selected={reasonCode === code}
                    onPress={() => setReasonCode(code)}
                  />
                ))}
              </View>
              {noteRequired ? (
                <Field
                  label={tr('complete.reasonNote')}
                  value={reasonNote}
                  onChangeText={setReasonNote}
                />
              ) : null}
              <PrimaryButton
                label={tr('common.confirm')}
                onPress={onMarkNotWorked}
                danger
                disabled={!canConfirmNotWorked}
              />
                </Card>
              ) : null}
            </>
          ) : (
            <GhostButton
              label={tr('complete.correctToPlanned')}
              onPress={onCorrectToPlanned}
              danger
              style={{ marginTop: 8 }}
            />
          )}
        </>
      ) : (
        <>
          <Text fontRole="display" style={{ color: t.ink, fontWeight: '700', fontSize: 20, marginBottom: 12 }}>
            {tr('complete.step2Title')}
          </Text>

          <Text style={{color:t.dim,marginBottom:12}}>{tr('redesign.tipExplanation')}</Text>
          {/* Tip method segmented control */}
          <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 6 }}>
            {tr('complete.tipMethod')}
          </Text>
          <View style={{ flexDirection: 'row', gap: 8, marginBottom: 14 }}>
            {(['direct', 'pooled', 'mixed'] as const).map((m) => (
              <Chip
                key={m}
                label={tr(`complete.tipMethods.${m}`)}
                selected={tipMethod === m}
                onPress={() => setTipMethod(m)}
              />
            ))}
          </View>

          <Field
            label={tr('redesign.directTips')}
            value={directTipsText}
            onChangeText={setDirectTipsText}
            keyboardType="decimal-pad"
          />
          <Field
            label={tr('redesign.tipOut')}
            value={tipOutText}
            onChangeText={setTipOutText}
            keyboardType="decimal-pad"
          />
          {tipMethod !== 'direct' || num(tipShareText) > 0 ? <>          <Field
            label={tr('redesign.poolShare')}
            value={tipShareText}
            onChangeText={setTipShareText}
            keyboardType="decimal-pad"
          />
</> : null}
          {tipMethod !== 'direct' || num(poolText) > 0 ? (
            <Field
              label={tr('complete.poolContribution')}
              value={poolText}
              onChangeText={setPoolText}
              keyboardType="decimal-pad"
            />
          ) : null}
          <GhostButton label={tr('redesign.optionalDetails')} onPress={()=>setDetails(!details)} />
          {details ? <>
          <Field
            label={tr('complete.actualHourlyRate')}
            value={actualRateText}
            onChangeText={setActualRateText}
            keyboardType="decimal-pad"
          />

          <Field
            label={`${tr('complete.sales')} (${tr('common.optional')})`}
            value={salesText}
            onChangeText={setSalesText}
            keyboardType="decimal-pad"
          />
          <Field
            label={`${tr('complete.otherIncome')} (${tr('common.optional')})`}
            value={otherIncomeText}
            onChangeText={setOtherIncomeText}
            keyboardType="decimal-pad"
          />
          {/* DEF-07: per-shift editable deduction rate */}
          <Field
            label={tr('complete.deductionRate')}
            value={dedRateText}
            onChangeText={setDedRateText}
            keyboardType="decimal-pad"
            hint={tr('settings.deductionHint')}
          />
          </> : null}
          {!initialIsEditingActuals && !hasPaymentHistory ? <>
            <Field label={tr('redesign.received')} hint={tr('redesign.blankUnknown')} value={receivedNow} onChangeText={setReceivedNow} keyboardType="decimal-pad" />
            <Field label={tr('redesign.awaiting')} hint={tr('redesign.blankUnknown')} value={expectedLater} onChangeText={setExpectedLater} keyboardType="decimal-pad" />
          </> : <Text style={{color:t.dim,marginBottom:16}}>{tr('redesign.paymentTiming')}</Text>}
          {/* Big total */}
          <Card style={{ padding: 16, alignItems: 'center', marginBottom: 14 }}>
            <Text style={{ color: t.softText, fontSize: 11, fontWeight: '600', letterSpacing: 0.8 }}>
              {tr('complete.total').toUpperCase()}
            </Text>
            <Text fontRole="total" style={{ color: t.ink, fontWeight: '700', fontSize: 34, marginVertical: 4 }}>
              {money(actual)}
            </Text>
            <Text
              fontRole="penNote"
              style={{
                color: varianceValue == null ? t.softText : varianceValue >= 0 ? t.ink : t.red,
                backgroundColor: 'transparent',
                paddingHorizontal: varianceValue == null ? 0 : 6,
                paddingVertical: varianceValue == null ? 0 : 3,
                fontWeight: '600',
                fontSize: 17,
                transform: [{ rotate: '-1deg' }],
              }}
            >
              {varianceValue == null ? '—' : signedMoney(varianceValue)} {tr('complete.variance')} ({money(expected)})
            </Text>
            <View style={{ flexDirection: 'row', gap: 24, marginTop: 10 }}>
              <View style={{ alignItems: 'center' }}>
                <Text style={{ color: t.ink, fontWeight: '700', fontSize: 15 }}>
                  {hourly == null ? '\u2014' : `${money(hourly)}/h`}
                </Text>
                <Text style={{ color: t.softText, fontSize: 10, fontWeight: '600' }}>
                  {tr('complete.effectiveHourly').toUpperCase()}
                </Text>
              </View>
              <View style={{ alignItems: 'center' }}>
                <Text style={{ color: t.ink, fontWeight: '700', fontSize: 15 }}>{money(net)}</Text>
                <Text style={{ color: t.softText, fontSize: 10, fontWeight: '600' }}>
                  {tr('complete.estimatedNet').toUpperCase()}
                </Text>
              </View>
            </View>
          </Card>

          {errors.map((e) => (
            <Text key={e} accessibilityRole="alert" style={{ color: t.paper, backgroundColor: t.red, padding: 6, fontSize: 13, marginBottom: 4 }}>
              {e}
            </Text>
          ))}

          <PrimaryButton
            label={tr(isEditingActuals ? 'complete.updateActuals' : 'complete.saveWorked')}
            onPress={onSave}
            disabled={saving}
            style={{ marginBottom: 8 }}
          />
          <GhostButton label={tr('common.back')} onPress={() => setStep(1)} />
        </>
      )}
    </FormScreen>
  );
}
