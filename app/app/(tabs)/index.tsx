import React, { useMemo } from 'react';
import { ScrollView, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { expectedEarnings } from '../../src/domain/calc';
import { minutesToHHMM, startOfWeekIso, todayIso, weekDatesIso } from '../../src/domain/dates';
import { isActualsPending } from '../../src/domain/reminders';
import { aggregateStats, goalProgress } from '../../src/domain/stats';
import type { GoalMetric, Shift } from '../../src/domain/types';
import { useEmployersStore } from '../../src/state/employersStore';
import { useGoalsStore } from '../../src/state/goalsStore';
import { useSettingsStore } from '../../src/state/settingsStore';
import { useShiftsStore } from '../../src/state/shiftsStore';
import {
  Card,
  LineItem,
  money,
  PrimaryButton,
  ReceiptCard,
  ReceiptRule,
  Stamp,
} from '../../src/ui/components';
import { Text } from '../../src/ui/typography';
import { useTokens } from '../../src/ui/tokens';

import { PendingPayments } from '../../src/ui/PendingPayments';

function shiftSort(a: Shift, b: Shift): number {
  return a.date.localeCompare(b.date) || a.startMin - b.startMin;
}

function formatDate(iso: string, locale: string): string {
  const [year, month, day] = iso.split('-').map(Number);
  return new Intl.DateTimeFormat(locale, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    timeZone: 'UTC',
  }).format(new Date(Date.UTC(year, month - 1, day)));
}

function formatWeekRange(dates: readonly string[], locale: string): string {
  const first = dates[0];
  const last = dates.at(-1);
  if (!first || !last) return '';
  const format = (iso: string) => {
    const [year, month, day] = iso.split('-').map(Number);
    return new Intl.DateTimeFormat(locale, {
      month: 'short',
      day: 'numeric',
      timeZone: 'UTC',
    }).format(new Date(Date.UTC(year, month - 1, day)));
  };
  return `${format(first)}–${format(last)}`;
}

function goalAmount(metric: GoalMetric, value: number, hoursLabel: string): string {
  return metric === 'worked_hours' ? `${(value / 60).toFixed(1)} ${hoursLabel}` : money(value);
}

export default function HomeScreen() {
  const router = useRouter();
  const { t } = useTokens();
  const { t: tr, i18n } = useTranslation();
  const shifts = useShiftsStore((state) => state.shifts);
  const employers = useEmployersStore((state) => state.employers);
  const goals = useGoalsStore((state) => state.goals);
  const reminderDelayMinutes = useSettingsStore((state) => state.postShiftReminderDelayMinutes);
  const today = todayIso();
  const weekStart = startOfWeekIso(today);
  const weekDates = useMemo(() => weekDatesIso(weekStart), [weekStart]);
  const weekShifts = useMemo(
    () => shifts.filter((shift) => weekDates.includes(shift.date)),
    [shifts, weekDates]
  );
  const tally = useMemo(() => aggregateStats(weekShifts), [weekShifts]);
  const goal = goals.find(
    (item) => item.weekStart === weekStart && item.metric === 'actual_gross' && !item.employerId
  ) ?? goals.find((item) => item.weekStart === weekStart);
  const progress = goal ? goalProgress(goal, weekShifts) : null;
  const progressPercent = goal && progress && goal.target > 0
    ? Math.max(0, Math.round((progress.actual / goal.target) * 100))
    : 0;
  const meterFilled = Math.min(10, Math.floor(progressPercent / 10));
  const closeOuts = shifts
    .filter((shift) => isActualsPending(shift, new Date(), reminderDelayMinutes))
    .sort(shiftSort);
  const nextShift = shifts
    .filter(
      (shift) =>
        shift.status === 'planned' &&
        shift.date >= today &&
        !closeOuts.some((pending) => pending.id === shift.id)
    )
    .sort(shiftSort)[0];

  const employerName = (shift: Shift) =>
    employers.find((employer) => employer.id === shift.employerId)?.name ?? tr('home.unknownEmployer');
  const shiftSummary = (shift: Shift) =>
    tr('home.shiftSummary', {
      employer: employerName(shift),
      date: formatDate(shift.date, i18n.language),
      time: `${minutesToHHMM(shift.startMin)}–${minutesToHHMM(shift.endMin)}`,
    });

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: t.bg }} edges={['top']}>
      <ScrollView
        style={{ flex: 1, backgroundColor: t.bg }}
        contentContainerStyle={{ paddingHorizontal: 18, paddingTop: 12, paddingBottom: 36 }}
      >
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <Text fontRole="display" style={{ color: t.ink, fontSize: 18, fontWeight: '700', letterSpacing: 0.4 }}>
          {tr('home.brand').toUpperCase()}
        </Text>
        <Text fontRole="ui" style={{ color: t.dim, fontSize: 10 }}>
          {formatDate(today, i18n.language).toUpperCase()}
        </Text>
      </View>

      {closeOuts.length > 0 ? (
        <Card style={{ padding: 14, marginTop: 14, borderColor: t.amber }}>
          <Text fontRole="penNote" style={{ color: t.ink, fontWeight: '600', fontSize: 20 }}>
            {tr('home.closeOutCount', { count: closeOuts.length }).toUpperCase()}
          </Text>
          <Text fontRole="ui" style={{ color: t.ink, fontWeight: '700', fontSize: 13, marginTop: 4, marginBottom: 12 }}>
            {shiftSummary(closeOuts[0]!)}
          </Text>
          <PrimaryButton
            label={tr('home.closeOutAction')}
            onPress={() => router.push({ pathname: '/complete/[id]', params: { id: closeOuts[0]!.id } })}
          />
          {closeOuts.slice(1).map(item => <PrimaryButton key={item.id} label={shiftSummary(item)} onPress={() => router.push({ pathname: '/complete/[id]', params: { id: item.id } })} style={{ marginTop: 8 }} />)}
        </Card>
      ) : null}
      {shifts.length > 0 ? <Card style={{ padding: 20, marginTop: 18 }}>
        <Text style={{ color: t.dim, fontSize: 15 }}>{tr('home.weekOf', { range: formatWeekRange(weekDates, i18n.language) })}</Text>
        <Text style={{ color: t.ink, fontSize: 16, marginTop: 12 }}>{tr('home.totalEarned')}</Text>
        <Text fontRole="total" style={{ color: t.ink, fontSize: 36 }}>{money(tally.grossEarnings)}</Text>
        <Text style={{ color: t.dim, marginTop: 8 }}>{tr('home.realHourly', { rate: tally.effectiveHourly == null ? tr('home.notAvailable') : money(tally.effectiveHourly) })}</Text>
        <PendingPayments />
        <PrimaryButton label={tr('redesign.money')} onPress={() => router.push('/(tabs)/money')} style={{ marginTop: 16 }} />
      </Card> : null}

      {weekShifts.length === 0 && !nextShift ? (
        <Card style={{ padding: 14, marginTop: 16 }}>
          <Text fontRole="display" style={{ color: t.ink, fontWeight: '700', fontSize: 15 }}>
            {tr('home.emptyTitle').toUpperCase()}
          </Text>
          <Text fontRole="ui" style={{ color: t.dim, fontSize: 12, marginTop: 5, marginBottom: 12 }}>
            {tr('home.emptyHint')}
          </Text>
          <PrimaryButton
            label={tr('home.viewSchedule')}
            tone="ink"
            onPress={() => router.push('/(tabs)/schedule')}
          />
        </Card>
      ) : null}

      {nextShift ? (
        <Card style={{ padding: 14, marginTop: 16 }}>
          <Text fontRole="ui" style={{ color: t.dim, fontWeight: '700', fontSize: 10, letterSpacing: 1 }}>
            {tr('home.nextShift').toUpperCase()}
          </Text>
          <Text fontRole="ui" style={{ color: t.ink, fontWeight: '700', fontSize: 13, marginTop: 4 }}>
            {shiftSummary(nextShift)}
          </Text>
          <Text fontRole="ui" style={{ color: t.ink, fontSize: 11, marginTop: 3, marginBottom: 12 }}>
            {tr('home.expected', { amount: money(expectedEarnings(nextShift)) })}
          </Text>
          <PrimaryButton
            label={tr('redesign.shiftDetails')}
            tone="ink"
            onPress={() => router.push({ pathname: '/shift-form', params: { id: nextShift.id } })}
          />
        </Card>
      ) : null}

      </ScrollView>
    </SafeAreaView>
  );
}
