import React, { useEffect, useMemo, useState } from 'react';
import {
  AccessibilityInfo,
  Alert,
  LayoutAnimation,
  Pressable,
  SectionList,
  StyleSheet,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { useShiftsStore } from '../../src/state/shiftsStore';
import { useEmployersStore } from '../../src/state/employersStore';
import { useTokens, TOUCH_TARGET, radius } from '../../src/ui/tokens';
import {
  Avatar,
  Card,
  GhostButton,
  LineItem,
  money,
  PrimaryButton,
  ReceiptCard,
  ReceiptRule,
  SegmentedTabs,
  signedMoney,
  StatusChip,
} from '../../src/ui/components';
import {
  actualPaidMinutes,
  actualEarnings,
  effectiveHourly,
  expectedEarnings,
  scheduledPaidMinutes,
  unpaidBreakMinutes,
  variance,
  wagesForMinutes,
} from '../../src/domain/calc';
import { previewCopyWeek } from '../../src/domain/copyWeek';
import { overlappingShiftIds } from '../../src/domain/overlap';
import {
  addDaysIso,
  addMonthsIso,
  minutesToHHMM,
  monthDatesIso,
  startOfWeekIso,
  todayIso,
  weekDatesIso,
} from '../../src/domain/dates';
import type { Shift, ShiftBreak } from '../../src/domain/types';
import { isActualsPending } from '../../src/domain/reminders';
import { useSettingsStore } from '../../src/state/settingsStore';
import { useWriteAccess } from '../../src/ui/WriteAccess';
import { Text } from '../../src/ui/typography';

type ScheduleView = 'day' | 'week' | 'month';

function formatHours(minutes: number, locale: string): string {
  return new Intl.NumberFormat(locale, { maximumFractionDigits: 2 }).format(minutes / 60);
}

function breakMinutes(breaks: readonly ShiftBreak[] | null | undefined): number {
  return (breaks ?? []).reduce((sum, item) => sum + Math.max(item.durationMin, 0), 0);
}

function ShiftReceiptDetails({
  shift,
  actualsPending,
  onEdit,
  onLog,
}: {
  shift: Shift;
  actualsPending: boolean;
  onEdit: () => void;
  onLog: () => void;
}) {
  const { t } = useTokens();
  const { t: tr, i18n } = useTranslation();
  const isWorked = shift.status === 'worked';
  const plannedMinutes = scheduledPaidMinutes(shift);
  const workedMinutes = actualPaidMinutes(shift);
  const actualRate = shift.actualHourlyRateSnapshot ?? shift.hourlyRateSnapshot;
  const actualWages = wagesForMinutes(workedMinutes, actualRate);
  const actualTotal = actualEarnings(shift);
  const realHourly = effectiveHourly(shift);
  const expectedTotal = expectedEarnings(shift);

  const timeRange = (start: number | null | undefined, end: number | null | undefined) =>
    start == null || end == null
      ? tr('home.notAvailable')
      : `${minutesToHHMM(start)}–${minutesToHHMM(end)}`;

  const breakLabel = (breaks: readonly ShiftBreak[] | null | undefined) => {
    const unpaid = unpaidBreakMinutes(breaks);
    const paid = breakMinutes(breaks) - unpaid;
    const parts = [
      unpaid > 0 ? tr('schedule.unpaidBreak', { minutes: unpaid }) : null,
      paid > 0 ? tr('schedule.paidBreak', { minutes: paid }) : null,
    ].filter((part): part is string => part != null);
    return parts.length > 0 ? parts.join(' · ') : tr('schedule.noBreak');
  };

  const payoutTone: 'confirmed' | 'negative' | 'dim' | 'pen' =
    shift.payoutStatus === 'received'
      ? 'confirmed'
      : shift.payoutStatus === 'disputed'
        ? 'negative'
        : shift.payoutStatus == null || shift.payoutStatus === 'not_expected'
          ? 'dim'
          : 'pen';

  return (
    <ReceiptCard style={styles.shiftReceipt}>
      <Text fontRole="display" style={[styles.receiptTitle, { color: actualsPending ? t.red : t.ink }]}>
        {tr(
          isWorked
            ? 'schedule.actualReceiptTitle'
            : actualsPending
              ? 'schedule.closeOutReceiptTitle'
              : 'schedule.plannedReceiptTitle'
        ).toUpperCase()}
      </Text>
      <ReceiptRule />

      {isWorked ? (
        <>
          <LineItem
            label={tr('schedule.actualTime')}
            value={timeRange(shift.actualStartMin, shift.actualEndMin)}
            tone="pen"
          />
          <LineItem
            label={tr('schedule.break')}
            value={breakLabel(shift.actualBreaks)}
            tone="pen"
          />
          <LineItem
            label={tr('schedule.hoursWorked')}
            value={`${formatHours(workedMinutes, i18n.language)} ${tr('common.hours')}`}
          />
          <LineItem
            label={tr('schedule.wagesAtRate', { rate: money(actualRate) })}
            value={money(actualWages)}
          />
          <LineItem
            label={tr('schedule.directTips')}
            value={money(shift.directTips ?? 0)}
            tone="pen"
          />
          <LineItem
            label={tr('schedule.tipShareReceived')}
            value={money(shift.tipShareReceived ?? 0)}
            tone="pen"
          />
          <LineItem
            label={tr('schedule.tipOutPaid')}
            value={shift.tipOutPaid ? money(-shift.tipOutPaid) : money(0)}
            tone={shift.tipOutPaid ? 'negative' : 'pen'}
          />
          {shift.poolContribution ? (
            <LineItem
              label={tr('schedule.poolContribution')}
              value={money(-shift.poolContribution)}
              tone="negative"
            />
          ) : null}
          {shift.otherIncome ? (
            <LineItem
              label={tr('schedule.otherIncome')}
              value={money(shift.otherIncome)}
              tone="pen"
            />
          ) : null}
          {shift.sales != null ? (
            <LineItem label={tr('schedule.sales')} value={money(shift.sales)} tone="pen" />
          ) : null}
          <ReceiptRule />
          <LineItem
            label={tr('schedule.totalEarned')}
            value={money(actualTotal)}
            tone="confirmed"
            strong
          />
          <Text fontRole="mono" style={[styles.realHourly, { color: realHourly == null ? t.dim : t.green }]}>
            {tr('schedule.realHourly', {
              rate: realHourly == null ? tr('home.notAvailable') : money(realHourly),
            }).toUpperCase()}
          </Text>
          <ReceiptRule />
          <LineItem
            label={tr('schedule.payoutStatus')}
            value={
              shift.payoutStatus == null
                ? tr('home.notAvailable')
                : tr(`payout.${shift.payoutStatus}`)
            }
            tone={payoutTone}
          />
          {shift.notes?.trim() ? (
            <View style={[styles.note, { borderColor: t.rule }]}>
              <Text style={[styles.noteLabel, { color: t.dim }]}>
                {tr('schedule.note').toUpperCase()}
              </Text>
              <Text fontRole="penNote" style={{ color: t.pen, fontSize: 18, transform: [{ rotate: '-1deg' }] }}>{shift.notes.trim()}</Text>
            </View>
          ) : null}
          <GhostButton
            label={tr('schedule.editActuals')}
            onPress={onLog}
            style={styles.singleAction}
          />
        </>
      ) : (
        <>
          <LineItem
            label={tr('schedule.plannedTime')}
            value={timeRange(shift.startMin, shift.endMin)}
            tone="pen"
          />
          <LineItem label={tr('schedule.break')} value={breakLabel(shift.breaks)} tone="pen" />
          <LineItem
            label={tr('schedule.plannedHours')}
            value={`${formatHours(plannedMinutes, i18n.language)} ${tr('common.hours')}`}
          />
          <LineItem
            label={tr('schedule.hourlyRate')}
            value={tr('schedule.perHour', { amount: money(shift.hourlyRateSnapshot) })}
            tone="pen"
          />
          <LineItem
            label={tr('schedule.expectedTips')}
            value={
              shift.plannedExpectedTips == null
                ? tr('home.notAvailable')
                : money(shift.plannedExpectedTips)
            }
            tone={shift.plannedExpectedTips == null ? 'dim' : 'pen'}
          />
          {shift.plannedOtherIncome ? (
            <LineItem
              label={tr('schedule.expectedOtherIncome')}
              value={money(shift.plannedOtherIncome)}
              tone="pen"
            />
          ) : null}
          <ReceiptRule />
          <LineItem label={tr('schedule.expectedTotal')} value={money(expectedTotal)} strong />

          {actualsPending ? (
            <View style={styles.actionRow}>
              <GhostButton
                label={tr('schedule.editShift')}
                onPress={onEdit}
                style={styles.action}
              />
              <PrimaryButton
                label={tr('schedule.closeOut')}
                danger
                onPress={onLog}
                style={styles.action}
              />
            </View>
          ) : shift.status === 'planned' ? (
            <View style={styles.actionRow}>
              <GhostButton
                label={tr('schedule.editShift')}
                onPress={onEdit}
                style={styles.action}
              />
              <PrimaryButton
                label={tr('schedule.logShift')}
                tone="ink"
                onPress={onLog}
                style={styles.action}
              />
            </View>
          ) : (
            <GhostButton
              label={tr('schedule.editShift')}
              onPress={onEdit}
              style={styles.singleAction}
            />
          )}
        </>
      )}
    </ReceiptCard>
  );
}

export default function ScheduleScreen() {
  const router = useRouter();
  const { t } = useTokens();
  const { t: tr, i18n } = useTranslation();
  const shifts = useShiftsStore((s) => s.shifts);
  const addShift = useShiftsStore((s) => s.addShift);
  const employers = useEmployersStore((s) => s.employers);
  const roles = useEmployersStore((s) => s.roles);
  const reminderDelayMinutes = useSettingsStore((state) => state.postShiftReminderDelayMinutes);
  const { requireWrite } = useWriteAccess();

  const today = todayIso();
  const [view, setView] = useState<ScheduleView>('week');
  const [selectedDate, setSelectedDate] = useState(today);
  const [weekStart, setWeekStart] = useState(() => startOfWeekIso(today));
  const [expandedShiftId, setExpandedShiftId] = useState<string | null>(null);
  const [reduceMotion, setReduceMotion] = useState<boolean | null>(null);
  const weekDates = useMemo(() => weekDatesIso(weekStart), [weekStart]);
  const monthDates = useMemo(() => monthDatesIso(selectedDate), [selectedDate]);

  useEffect(() => {
    let active = true;
    void AccessibilityInfo.isReduceMotionEnabled()
      .then((enabled) => {
        if (active) setReduceMotion(enabled);
      })
      .catch(() => {
        if (active) setReduceMotion(true);
      });
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduceMotion);
    return () => {
      active = false;
      subscription.remove();
    };
  }, []);

  const weekShifts = useMemo(
    () => shifts.filter((s) => weekDates.includes(s.date)),
    [shifts, weekDates]
  );

  const visibleDates = useMemo(
    () => (view === 'day' ? [selectedDate] : view === 'month' ? monthDates : weekDates),
    [monthDates, selectedDate, view, weekDates]
  );

  const periodShifts = useMemo(
    () => shifts.filter((shift) => visibleDates.includes(shift.date)),
    [shifts, visibleDates]
  );

  // DEF-01: flag overlapping shifts. Include the adjacent days so an overnight
  // shift spilling into this week (or out of it) is still detected.
  const overlapIds = useMemo(() => {
    const from = addDaysIso(weekStart, -1);
    const to = addDaysIso(weekStart, 7);
    return overlappingShiftIds(shifts.filter((s) => s.date >= from && s.date <= to));
  }, [shifts, weekStart]);

  const scheduledHours = useMemo(
    () => periodShifts.reduce((sum, s) => sum + scheduledPaidMinutes(s), 0) / 60,
    [periodShifts]
  );

  const sections = useMemo(
    () =>
      visibleDates
        .map((date) => ({
          date,
          data: periodShifts
            .filter((s) => s.date === date)
            .sort((a, b) => a.startMin - b.startMin),
        }))
        .filter((sec) => sec.data.length > 0),
    [periodShifts, visibleDates]
  );

  const dayLabel = (iso: string) => {
    const [y, m, d] = iso.split('-').map(Number);
    const date = new Date(y, m - 1, d);
    return new Intl.DateTimeFormat(i18n.language, {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
    }).format(date);
  };

  const shortDay = (iso: string) => {
    const [y, m, d] = iso.split('-').map(Number);
    const date = new Date(y, m - 1, d);
    return new Intl.DateTimeFormat(i18n.language, { weekday: 'narrow' }).format(date);
  };

  const employerFor = (id: string) => employers.find((e) => e.id === id);
  const roleFor = (id?: string | null) => (id ? roles.find((r) => r.id === id) : undefined);

  const toggleShift = (shiftId: string) => {
    if (reduceMotion === false) LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setExpandedShiftId((current) => (current === shiftId ? null : shiftId));
  };

  const onCopyWeek = () => {
    if (!requireWrite()) return;
    const plans = previewCopyWeek(shifts, weekStart);
    const duplicates = plans.filter((plan) => plan.conflict === 'duplicate').length;
    const overlaps = plans.filter((plan) => plan.conflict === 'overlap').length;
    const lines = plans.map(
      (plan) =>
        `${plan.date} · ${minutesToHHMM(plan.startMin)}–${minutesToHHMM(plan.endMin)} · ${tr(`templates.${plan.conflict}`)}`
    );
    Alert.alert(
      tr('schedule.copyWeekPreviewTitle'),
      `${tr('schedule.copyWeekPreviewMessage', { count: plans.length, duplicates, overlaps })}${lines.length ? `\n\n${lines.join('\n')}` : ''}`,
      [
        { text: tr('common.cancel'), style: 'cancel' },
        {
          text: tr('common.confirm'),
          onPress: () => {
            void (async () => {
            const included = plans.filter((plan) => plan.conflict !== 'duplicate');
            for (const plan of included) {
              const { conflict: _conflict, conflictingShiftIds: _ids, ...input } = plan;
              await addShift(input);
            }
            if (included.length > 0) {
              setWeekStart(addDaysIso(weekStart, 7));
              setSelectedDate(addDaysIso(selectedDate, 7));
            }
            })();
          },
        },
      ]
    );
  };

  const navigatePeriod = (direction: -1 | 1) => {
    if (view === 'day') {
      const next = addDaysIso(selectedDate, direction);
      setSelectedDate(next);
      setWeekStart(startOfWeekIso(next));
      return;
    }
    if (view === 'month') {
      const next = addMonthsIso(selectedDate, direction);
      setSelectedDate(next);
      setWeekStart(startOfWeekIso(next));
      return;
    }
    const next = addDaysIso(weekStart, direction * 7);
    setWeekStart(next);
    setSelectedDate(addDaysIso(selectedDate, direction * 7));
  };

  const monthLead = useMemo(() => {
    const first = monthDates[0];
    if (!first) return 0;
    const [year, month, day] = first.split('-').map(Number);
    const sundayBased = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
    return sundayBased === 0 ? 6 : sundayBased - 1;
  }, [monthDates]);

  return (
    <View style={{ flex: 1, backgroundColor: t.bg }}>
      {/* Week header */}
      <View style={styles.weekHeader}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={tr('schedule.previousPeriod')}
          onPress={() => navigatePeriod(-1)}
          style={[styles.navBtn, { backgroundColor: t.card, borderColor: t.line }]}
        >
          <Text fontRole="ui" style={{ color: t.ink, fontSize: 16 }}>‹</Text>
        </Pressable>
        <View style={{ alignItems: 'center' }}>
          <Text fontRole="total" style={{ color: t.ink, fontWeight: '700', fontSize: 18 }}>
            {scheduledHours.toFixed(1)} {tr('common.hours')}
          </Text>
          <Text fontRole="ui" style={{ color: t.softText, fontSize: 10, letterSpacing: 1, fontWeight: '600' }}>
            {tr('schedule.scheduledHours')}
          </Text>
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={tr('schedule.nextPeriod')}
          onPress={() => navigatePeriod(1)}
          style={[styles.navBtn, { backgroundColor: t.card, borderColor: t.line }]}
        >
          <Text fontRole="ui" style={{ color: t.ink, fontSize: 16 }}>›</Text>
        </Pressable>
      </View>

      <View style={{ marginHorizontal: 16, marginBottom: 8 }}>
        <SegmentedTabs
          items={(['day', 'week', 'month'] as const).map((key) => ({
            key,
            label: tr(`schedule.views.${key}`),
          }))}
          selected={view}
          onSelect={(item) => {
            setView(item);
            setWeekStart(startOfWeekIso(selectedDate));
          }}
        />
      </View>

      {/* Week strip */}
      {view !== 'month' ? (
        <View style={styles.weekStrip}>
          {weekDates.map((date) => {
            const selected = date === selectedDate;
            const hasShift = weekShifts.some((shift) => shift.date === date);
            return (
              <Pressable
                key={date}
                accessibilityRole="button"
                onPress={() => setSelectedDate(date)}
                style={[
                  styles.dayCell,
                  {
                    backgroundColor: selected ? t.cobalt : t.card,
                    borderColor: selected ? t.cobalt : t.line,
                  },
                ]}
              >
                <Text fontRole="ui" style={{ color: selected ? t.paper : t.softText, fontSize: 10, fontWeight: '600' }}>
                  {shortDay(date)}
                </Text>
                <Text fontRole="ui" style={{ color: selected ? t.paper : t.ink, fontWeight: '700', fontSize: 13 }}>
                  {Number(date.slice(8))}
                </Text>
                <View
                  style={{
                    width: 4,
                    height: 4,
                    backgroundColor: hasShift ? (selected ? t.paper : t.pen) : 'transparent',
                  }}
                />
              </Pressable>
            );
          })}
        </View>
      ) : (
        <View style={styles.monthGrid}>
          {weekDatesIso('2026-07-13').map((date) => (
            <Text fontRole="ui" key={date} style={[styles.monthWeekday, { color: t.softText }]}>
              {shortDay(date)}
            </Text>
          ))}
          {Array.from({ length: monthLead }, (_, index) => (
            <View key={`lead-${index}`} style={styles.monthCell} />
          ))}
          {monthDates.map((date) => {
            const selected = date === selectedDate;
            const hasShift = shifts.some((shift) => shift.date === date);
            return (
              <Pressable
                key={date}
                accessibilityRole="button"
                onPress={() => setSelectedDate(date)}
                style={[
                  styles.monthCell,
                  {
                    backgroundColor: selected ? t.cobalt : t.card,
                    borderColor: selected ? t.cobalt : t.line,
                  },
                ]}
              >
                <Text fontRole="ui" style={{ color: selected ? t.paper : t.ink, fontWeight: '700' }}>
                  {Number(date.slice(8))}
                </Text>
                <View
                  style={{
                    width: 4,
                    height: 4,
                    backgroundColor: hasShift ? (selected ? t.paper : t.pen) : 'transparent',
                  }}
                />
              </Pressable>
            );
          })}
        </View>
      )}

      {/* Copy week */}
      <View style={{ flexDirection: 'row', justifyContent: 'flex-end', paddingHorizontal: 16 }}>
        {view === 'week' ? <Pressable
          accessibilityRole="button"
          accessibilityLabel={tr('schedule.unplannedShift')}
          onPress={() => {
            if (requireWrite()) router.push({ pathname: '/shift-form', params: { unplanned: '1' } });
          }}
          style={({ pressed }) => ({
            opacity: pressed ? 0.6 : 1,
            minHeight: TOUCH_TARGET,
            justifyContent: 'center',
            marginRight: 18,
            borderBottomWidth: 2,
            borderBottomColor: t.cobalt,
          })}
        >
          <Text fontRole="ui" style={{ color: t.cobaltLink, fontWeight: '600', fontSize: 13 }}>
            {tr('schedule.unplannedShift')}
          </Text>
        </Pressable> : null}
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={tr('schedule.copyWeek')}
          onPress={onCopyWeek}
          style={({ pressed }) => ({
            opacity: pressed ? 0.6 : 1,
            minHeight: TOUCH_TARGET,
            justifyContent: 'center',
            borderBottomWidth: 2,
            borderBottomColor: t.cobalt,
          })}
        >
          <Text fontRole="ui" style={{ color: t.cobaltLink, fontWeight: '600', fontSize: 13 }}>
            ⧉ {tr('schedule.copyWeek')}
          </Text>
        </Pressable>
      </View>

      {/* Agenda */}
      {sections.length === 0 ? (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 }}>
          <Text fontRole="display" style={{ color: t.ink, fontWeight: '600', fontSize: 17, marginBottom: 6 }}>
            {tr('schedule.emptyWeek')}
          </Text>
          <Text fontRole="ui" style={{ color: t.softText, fontSize: 13, textAlign: 'center' }}>
            {tr('schedule.emptyHint')}
          </Text>
        </View>
      ) : (
        <SectionList
          sections={sections}
          keyExtractor={(item) => item.id}
          extraData={expandedShiftId}
          contentContainerStyle={{ padding: 16, paddingBottom: 120 }}
          renderSectionHeader={({ section }) => (
            <Text
              fontRole="display"
              style={{
                color: t.softText,
                fontWeight: '700',
                fontSize: 12,
                marginTop: 12,
                marginBottom: 6,
                textTransform: 'capitalize',
              }}
            >
              {dayLabel(section.date)}
            </Text>
          )}
          renderItem={({ item }) => {
            const employer = employerFor(item.employerId);
            const role = roleFor(item.roleId);
            const expected = expectedEarnings(item);
            const isWorked = item.status === 'worked';
            const varianceValue = isWorked ? variance(item) : null;
            const actualsPending = isActualsPending(item, new Date(), reminderDelayMinutes);
            const expanded = expandedShiftId === item.id;
            const onEdit = () =>
              router.push({ pathname: '/shift-form', params: { id: item.id } });
            const onLog = () =>
              router.push({ pathname: '/complete/[id]', params: { id: item.id } });
            return (
              <View style={{ marginBottom: 8 }}>
                <Card style={{ overflow: 'hidden' }}>
                  <View style={{ flexDirection: 'row' }}>
                    <View style={{ width: 4, backgroundColor: employer?.color ?? t.line }} />
                    <View style={{ flex: 1 }}>
                      <View style={styles.shiftStub}>
                        <Pressable
                          accessibilityRole="button"
                          onPress={actualsPending || isWorked ? onLog : onEdit}
                          style={({ pressed }) => [
                            styles.shiftStubMain,
                            { opacity: pressed ? 0.85 : 1 },
                          ]}
                        >
                          <Avatar
                            name={employer?.name ?? '?'}
                            color={employer?.color ?? t.softText}
                          />
                          <View style={{ flex: 1 }}>
                            <Text fontRole="ui" style={{ color: t.ink, fontWeight: '700', fontSize: 14 }}>
                              {employer?.name ?? '—'}
                              {role ? ` · ${role.name}` : ''}
                            </Text>
                            <Text style={{ color: t.softText, fontSize: 12, marginTop: 2 }}>
                              {minutesToHHMM(item.startMin)}–{minutesToHHMM(item.endMin)}
                            </Text>
                          </View>
                          <View style={{ alignItems: 'flex-end', gap: 4 }}>
                            <View style={{ flexDirection: 'row', gap: 4 }}>
                              {overlapIds.has(item.id) ? (
                                <View
                                  accessibilityLabel={tr('schedule.overlap')}
                                  style={{
                                    backgroundColor: t.amberSoft,
                                    borderRadius: 0,
                                    paddingHorizontal: 8,
                                    paddingVertical: 3,
                                  }}
                                >
                                  <Text
                                    style={{
                                      color: t.amber,
                                      fontSize: 10,
                                      fontWeight: '700',
                                      letterSpacing: 0.6,
                                    }}
                                  >
                                    ⚠ {tr('schedule.overlap')}
                                  </Text>
                                </View>
                              ) : null}
                              {actualsPending ? (
                                <View
                                  style={{
                                    backgroundColor: t.amberSoft,
                                    paddingHorizontal: 8,
                                    paddingVertical: 3,
                                  }}
                                >
                                  <Text
                                    style={{
                                      color: t.amber,
                                      fontSize: 10,
                                      fontWeight: '700',
                                      letterSpacing: 0.6,
                                    }}
                                  >
                                    {tr('schedule.actualsPending')}
                                  </Text>
                                </View>
                              ) : (
                                <StatusChip status={item.status} />
                              )}
                            </View>
                            {isWorked ? (
                              <>
                                <Text style={{ color: t.green, fontWeight: '700', fontSize: 14 }}>
                                  {money(actualEarnings(item))}
                                </Text>
                                <Text
                                  fontRole="mono"
                                  style={{
                                    color:
                                      varianceValue == null
                                        ? t.softText
                                        : varianceValue >= 0
                                          ? t.green
                                          : t.amber,
                                    backgroundColor:
                                      varianceValue == null
                                        ? 'transparent'
                                        : varianceValue >= 0
                                          ? t.greenSoft
                                          : t.amberSoft,
                                    paddingHorizontal: varianceValue == null ? 0 : 4,
                                    fontSize: 11,
                                    fontWeight: '600',
                                  }}
                                >
                                  {tr('schedule.vsExpected', {
                                    amount:
                                      varianceValue == null ? '—' : signedMoney(varianceValue),
                                  })}
                                </Text>
                              </>
                            ) : item.status === 'planned' ? (
                              <Text style={{ color: t.ink, fontWeight: '700', fontSize: 14 }}>
                                {money(expected)}
                              </Text>
                            ) : null}
                          </View>
                        </Pressable>
                        <Pressable
                          accessibilityRole="button"
                          accessibilityLabel={tr(
                            expanded ? 'schedule.collapseShiftHint' : 'schedule.expandShiftHint'
                          )}
                          accessibilityState={{ expanded }}
                          onPress={() => toggleShift(item.id)}
                          style={({ pressed }) => [
                            styles.detailsToggle,
                            { opacity: pressed ? 0.6 : 1 },
                          ]}
                        >
                          <Text fontRole="ui" style={{ color: t.cobaltLink, fontSize: 18 }}>
                            {expanded ? '▴' : '▾'}
                          </Text>
                        </Pressable>
                      </View>
                      {expanded ? (
                        <ShiftReceiptDetails
                          shift={item}
                          actualsPending={actualsPending}
                          onEdit={onEdit}
                          onLog={onLog}
                        />
                      ) : null}
                    </View>
                  </View>
                </Card>
              </View>
            );
          }}
        />
      )}

      {/* Extended FAB — Schedule tab only */}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={tr('schedule.addShift')}
        onPress={() => {
          if (requireWrite()) router.push('/shift-form');
        }}
        style={({ pressed }) => [
          styles.fab,
          { backgroundColor: t.ink, shadowColor: t.ink, opacity: pressed ? 0.9 : 1 },
        ]}
      >
        <Text fontRole="ui" style={{ color: t.fabText, fontWeight: '700', fontSize: 14 }}>
          ＋ {tr('schedule.addShift')}
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  weekHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 10,
    paddingBottom: 6,
  },
  navBtn: {
    width: TOUCH_TARGET,
    height: TOUCH_TARGET,
    borderRadius: 0,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  weekStrip: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    gap: 4,
    marginBottom: 6,
  },
  dayCell: {
    flex: 1,
    borderRadius: 0,
    borderWidth: 1,
    alignItems: 'center',
    paddingVertical: 8,
    gap: 2,
    minHeight: TOUCH_TARGET,
  },
  monthGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 16,
    marginBottom: 6,
  },
  monthWeekday: {
    width: '14.285714%',
    textAlign: 'center',
    fontSize: 10,
    fontWeight: '700',
    paddingVertical: 5,
  },
  monthCell: {
    width: '14.285714%',
    minHeight: TOUCH_TARGET,
    borderWidth: 1,
    borderRadius: 0,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 3,
  },
  shiftStub: {
    minHeight: TOUCH_TARGET,
    flexDirection: 'row',
    alignItems: 'center',
  },
  shiftStubMain: {
    flex: 1,
    minHeight: TOUCH_TARGET,
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingLeft: 12,
    gap: 10,
  },
  detailsToggle: {
    width: TOUCH_TARGET,
    minHeight: TOUCH_TARGET,
    alignItems: 'center',
    justifyContent: 'center',
  },
  shiftReceipt: {
    marginHorizontal: 12,
    marginBottom: 12,
  },
  receiptTitle: {
    textAlign: 'center',
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.2,
  },
  realHourly: {
    textAlign: 'center',
    fontSize: 11,
    fontWeight: '600',
    marginTop: 4,
  },
  note: {
    borderTopWidth: 1,
    marginTop: 8,
    paddingTop: 8,
    gap: 3,
  },
  noteLabel: {
    fontSize: 9,
    fontWeight: '700',
    letterSpacing: 1,
  },
  actionRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 14,
  },
  action: {
    flex: 1,
  },
  singleAction: {
    marginTop: 14,
  },
  fab: {
    position: 'absolute',
    right: 16,
    bottom: 20,
    minHeight: 48,
    borderRadius: radius.button,
    paddingHorizontal: 20,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 6,
    shadowOpacity: 0.4,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
  },
});
