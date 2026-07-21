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

      <ReceiptCard style={{ marginTop: 18 }}>
        <Text style={{ color: t.dim, textAlign: 'center', fontSize: 10, fontWeight: '600', letterSpacing: 1.5 }}>
          {tr('home.weekOf', { range: formatWeekRange(weekDates, i18n.language) }).toUpperCase()}
        </Text>
        <Text fontRole="display" style={{ color: t.ink, textAlign: 'center', fontSize: 17, fontWeight: '700', letterSpacing: 0.4, marginTop: 4 }}>
          {tr('home.title').toUpperCase()}
        </Text>
        {goal && progress ? (
          <Stamp
            label={tr(progressPercent >= 100 ? 'home.goalMet' : 'home.onTrack')}
            tone={goal.metric === 'worked_hours' ? 'ink' : 'confirmed'}
            style={{ position: 'absolute', right: 10, top: 36 }}
          />
        ) : null}
        <ReceiptRule />
        <LineItem label={tr('home.hoursWorked')} value={(tally.workedMinutes / 60).toFixed(1)} />
        <LineItem label={tr('home.wages')} value={money(tally.actualBaseWages)} />
        <LineItem label={tr('home.grossTips')} value={money(tally.grossTips)} />
        <LineItem
          label={tr('home.tipOutPaid')}
          value={tally.tipOutPaid > 0 ? money(-tally.tipOutPaid) : money(0)}
          tone={tally.tipOutPaid > 0 ? 'negative' : 'computed'}
        />
        <ReceiptRule />
        <LineItem label={tr('home.totalEarned')} value={money(tally.grossEarnings)} strong />
        <Text fontRole="mono" style={{ color: tally.workedShiftCount > 0 ? t.green : t.dim, textAlign: 'center', fontSize: 11, fontWeight: '600', marginTop: 4 }}>
          {tr('home.realHourly', {
            rate: tally.effectiveHourly == null ? tr('home.notAvailable') : money(tally.effectiveHourly),
          }).toUpperCase()}
        </Text>
        <ReceiptRule />
        {goal && progress ? (
          <>
            <LineItem
              label={`${tr('home.goal')} · ${tr(`stats.goalMetrics.${goal.metric}`)}`}
              value={`${goalAmount(goal.metric, progress.actual, tr('common.hours'))} / ${goalAmount(goal.metric, goal.target, tr('common.hours'))}`}
            />
            <Text style={{ color: goal.metric === 'worked_hours' ? t.ink : t.green, fontSize: 12, fontWeight: '700', letterSpacing: 0.7, marginTop: 5 }}>
              {`${'■'.repeat(meterFilled)}${'□'.repeat(10 - meterFilled)} ${progressPercent}%`}
            </Text>
          </>
        ) : (
          <LineItem label={tr('home.goal')} value={tr('home.noGoal')} tone="dim" />
        )}
      </ReceiptCard>

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
            label={tr('home.logShift')}
            tone="ink"
            onPress={() => router.push({ pathname: '/complete/[id]', params: { id: nextShift.id } })}
          />
        </Card>
      ) : null}

      {closeOuts.length > 0 ? (
        <Card style={{ padding: 14, marginTop: 14, borderColor: t.red, shadowColor: t.red }}>
          <Text fontRole="penNote" style={{ color: t.red, fontWeight: '600', fontSize: 17, transform: [{ rotate: '-1deg' }] }}>
            {tr('home.closeOutCount', { count: closeOuts.length }).toUpperCase()}
          </Text>
          <Text fontRole="ui" style={{ color: t.ink, fontWeight: '700', fontSize: 13, marginTop: 4, marginBottom: 12 }}>
            {shiftSummary(closeOuts[0]!)}
          </Text>
          <PrimaryButton
            label={tr('home.closeOutAction')}
            danger
            onPress={() => router.push({ pathname: '/complete/[id]', params: { id: closeOuts[0]!.id } })}
          />
        </Card>
      ) : null}
      </ScrollView>
    </SafeAreaView>
  );
}
