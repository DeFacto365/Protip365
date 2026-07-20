import React, { useEffect, useMemo, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { useShiftsStore } from '../../src/state/shiftsStore';
import { useEmployersStore } from '../../src/state/employersStore';
import { useTokens } from '../../src/ui/tokens';
import { Avatar, Card, Chip, Field, money, PrimaryButton } from '../../src/ui/components';
import { Text } from '../../src/ui/typography';
import {
  addDaysIso,
  addMonthsIso,
  monthDatesIso,
  startOfWeekIso,
  todayIso,
  weekDatesIso,
} from '../../src/domain/dates';
import { useGoalsStore } from '../../src/state/goalsStore';
import {
  aggregateStats,
  aggregateWorked,
  bestGroup,
  goalProgress,
  percentChange,
  trendValue,
  type TrendMetric,
} from '../../src/domain/stats';
import type { GoalMetric } from '../../src/domain/types';
import { parseMoneyToCents } from '../../src/domain/money';
import { useWriteAccess, WriteAccessBanner } from '../../src/ui/WriteAccess';

const GOAL_METRICS: GoalMetric[] = [
  'worked_hours',
  'net_tips',
  'actual_gross',
  'estimated_net',
];

const TREND_METRICS: TrendMetric[] = [
  'hours',
  'base_wages',
  'net_tips',
  'actual_gross',
  'estimated_net',
  'effective_hourly',
];

export default function StatsScreen() {
  const { t } = useTokens();
  const { t: tr, i18n } = useTranslation();
  const shifts = useShiftsStore((s) => s.shifts);
  const employers = useEmployersStore((s) => s.employers);
  const goals = useGoalsStore((state) => state.goals);
  const addGoal = useGoalsStore((state) => state.addGoal);
  const ensureRepeatedForWeek = useGoalsStore((state) => state.ensureRepeatedForWeek);
  const weekStart = startOfWeekIso(todayIso());
  const [goalMetric, setGoalMetric] = useState<GoalMetric>('actual_gross');
  const [goalTarget, setGoalTarget] = useState('500');
  const [goalEmployerId, setGoalEmployerId] = useState<string | null>(null);
  const [repeatGoal, setRepeatGoal] = useState(false);
  const [trendMetric, setTrendMetric] = useState<TrendMetric>('actual_gross');
  const { canWrite, requireWrite } = useWriteAccess();

  useEffect(() => {
    if (canWrite) ensureRepeatedForWeek(weekStart);
  }, [canWrite, ensureRepeatedForWeek, weekStart]);

  const stats = useMemo(() => {
    const weekDates = new Set(weekDatesIso(startOfWeekIso(todayIso())));
    const weekShifts = shifts.filter((s) => weekDates.has(s.date));
    return aggregateStats(weekShifts);
  }, [shifts]);

  const currentGoals = useMemo(
    () => goals.filter((goal) => goal.weekStart === weekStart),
    [goals, weekStart]
  );

  const trendStats = useMemo(() => {
    const inDates = (dates: readonly string[]) => shifts.filter((shift) => dates.includes(shift.date));
    const currentWeek = aggregateWorked(inDates(weekDatesIso(weekStart)));
    const previousWeek = aggregateWorked(inDates(weekDatesIso(addDaysIso(weekStart, -7))));
    const currentMonth = aggregateWorked(inDates(monthDatesIso(todayIso())));
    const previousMonth = aggregateWorked(inDates(monthDatesIso(addMonthsIso(todayIso(), -1))));
    const rangeStart = addDaysIso(todayIso(), -89);
    const range = shifts.filter((shift) => shift.date >= rangeStart && shift.date <= todayIso());
    return {
      currentWeek,
      previousWeek,
      currentMonth,
      previousMonth,
      bestEmployer: bestGroup(range, trendMetric, (shift) => shift.employerId),
      bestWeekday: bestGroup(range, trendMetric, (shift) => {
        const [year, month, day] = shift.date.split('-').map(Number);
        return String(new Date(Date.UTC(year, month - 1, day)).getUTCDay());
      }),
    };
  }, [shifts, trendMetric, weekStart]);

  const metricDisplay = (metric: TrendMetric | GoalMetric, value: number | null): string =>
    value == null
      ? '\u2014'
      : metric === 'hours' || metric === 'worked_hours'
      ? `${(metric === 'worked_hours' ? value / 60 : value).toFixed(1)} ${tr('common.hours')}`
      : metric === 'effective_hourly'
        ? `${money(value)}/h`
        : money(value);

  const saveGoal = () => {
    if (!requireWrite()) return;
    const hours = Number(goalTarget.replace(',', '.'));
    const target = goalMetric === 'worked_hours'
      ? Number.isFinite(hours) ? Math.round(hours * 60) : null
      : parseMoneyToCents(goalTarget);
    if (target == null || target <= 0) return;
    addGoal({
      weekStart,
      metric: goalMetric,
      target,
      employerId: goalEmployerId,
      repeat: repeatGoal,
    });
  };

  const weekdayName = (key: string): string => {
    const sunday = new Date(Date.UTC(2026, 6, 12 + Number(key)));
    return new Intl.DateTimeFormat(i18n.language, { weekday: 'long', timeZone: 'UTC' }).format(sunday);
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 16, paddingBottom: 48 }}
    >
      <Text style={{ color: t.ink, fontWeight: '700', fontSize: 20, marginBottom: 14 }}>
        {tr('stats.title')}
      </Text>

      <WriteAccessBanner />

      <Text style={{ color: t.softText, fontWeight: '700', fontSize: 12, marginBottom: 8 }}>
        {tr('stats.overview').toUpperCase()}
      </Text>
      <View style={{ flexDirection: 'row', gap: 12, marginBottom: 14 }}>
        <Card style={{ flex: 1, padding: 14, alignItems: 'center' }}>
          <Text style={{ color: t.ink, fontWeight: '700', fontSize: 20 }}>
            {stats.effectiveHourly == null ? '\u2014' : `${money(stats.effectiveHourly)}/h`}
          </Text>
          <Text style={{ color: t.softText, fontSize: 10, fontWeight: '600', marginTop: 3 }}>
            {tr('stats.effectiveHourly').toUpperCase()}
          </Text>
        </Card>
        <Card style={{ flex: 1, padding: 14, alignItems: 'center' }}>
          <Text style={{ color: t.ink, fontWeight: '700', fontSize: 20 }}>
            {(stats.workedMinutes / 60).toFixed(1)} {tr('common.hours')}
          </Text>
          <Text style={{ color: t.softText, fontSize: 10, fontWeight: '600', marginTop: 3 }}>
            {tr('stats.worked')}
          </Text>
        </Card>
      </View>

      <Card style={{ padding: 14, marginBottom: 14 }}>
        <SectionTitle label={tr('stats.hoursLedger')} />
        <LedgerRow label={tr('stats.scheduledHours')} value={`${(stats.scheduledMinutes / 60).toFixed(1)} ${tr('common.hours')}`} />
        <LedgerRow label={tr('stats.workedHours')} value={`${(stats.workedMinutes / 60).toFixed(1)} ${tr('common.hours')}`} />
        <LedgerRow
          label={tr('stats.hoursVariance')}
          value={`${stats.hoursVarianceMinutes > 0 ? '+' : ''}${(stats.hoursVarianceMinutes / 60).toFixed(1)} ${tr('common.hours')}`}
          tone={stats.hoursVarianceMinutes >= 0 ? 'default' : 'warning'}
        />
      </Card>

      <Card style={{ padding: 14, marginBottom: 14 }}>
        <SectionTitle label={tr('stats.baseAndVariance')} />
        <LedgerRow label={tr('stats.expectedBaseWages')} value={money(stats.expectedBaseWages)} />
        <LedgerRow label={tr('stats.actualBaseWages')} value={money(stats.actualBaseWages)} />
        <LedgerRow label={tr('stats.expectedGross')} value={moneyOrDash(stats.expectedGrossEarnings)} />
        <LedgerRow
          label={tr('stats.comparableActualGross')}
          value={moneyOrDash(stats.comparableActualGrossEarnings)}
        />
        <LedgerRow
          label={tr('stats.comparableVariance')}
          value={signedMoneyOrDash(stats.earningsVariance)}
          tone={stats.earningsVariance == null ? 'muted' : stats.earningsVariance >= 0 ? 'positive' : 'warning'}
        />
        <Text style={{ color: t.softText, fontSize: 11, marginTop: 6 }}>
          {tr('stats.comparableHint', { count: stats.comparableShiftCount })}
        </Text>
      </Card>

      <Card style={{ padding: 14, marginBottom: 14 }}>
        <SectionTitle label={tr('stats.tipsAndEarnings')} />
        <LedgerRow label={tr('stats.grossTips')} value={money(stats.grossTips)} />
        <LedgerRow label={tr('stats.poolContributions')} value={money(stats.poolContributions)} />
        <LedgerRow label={tr('stats.tipOutPaid')} value={money(stats.tipOutPaid)} />
        <LedgerRow label={tr('stats.netTips')} value={money(stats.netTips)} />
        <LedgerRow label={tr('stats.otherIncome')} value={money(stats.otherIncome)} />
        <LedgerRow label={tr('stats.grossEarnings')} value={money(stats.grossEarnings)} tone="positive" />
        <LedgerRow label={tr('stats.estimatedDeductions')} value={money(stats.estimatedDeductions)} />
        <LedgerRow label={tr('stats.estimatedNet')} value={money(stats.estimatedNet)} tone="positive" />
      </Card>

      <Card style={{ padding: 14, marginBottom: 14 }}>
        <SectionTitle label={tr('stats.payouts')} />
        <LedgerRow label={tr('stats.expectedPayout')} value={money(stats.expectedPayout)} />
        <LedgerRow label={tr('stats.payoutsReceived')} value={money(stats.payoutsReceived)} tone="positive" />
        <LedgerRow label={tr('stats.payoutsPending')} value={money(stats.payoutsPending)} />
      </Card>

      <Card style={{ padding: 14, marginBottom: 14 }}>
        <SectionTitle label={tr('stats.attendance')} />
        <LedgerRow label={tr('stats.missedShifts')} value={String(stats.missedCount)} />
        <LedgerRow label={tr('stats.cancelledShifts')} value={String(stats.cancelledCount)} />
        {stats.notWorkedByReason.map((row) => (
          <View key={row.reason} style={{ borderTopWidth: 1, borderTopColor: t.line, paddingTop: 8, marginTop: 8 }}>
            <Text style={{ color: t.ink, fontWeight: '600', fontSize: 12 }}>
              {row.reason === 'unknown'
                ? tr('stats.unknownReason')
                : tr(`shiftForm.notWorkedReasons.${row.reason}`)}
            </Text>
            <Text style={{ color: t.softText, fontSize: 11, marginTop: 3 }}>
              {tr('stats.reasonImpact', {
                count: row.shiftCount,
                hours: `${(row.scheduledMinutes / 60).toFixed(1)} ${tr('common.hours')}`,
                wages: money(row.expectedBaseWages),
              })}
            </Text>
          </View>
        ))}
      </Card>

      {/* Weekly goals: expected and actual progress are intentionally separate. */}
      <Text style={{ color: t.softText, fontWeight: '700', fontSize: 12, marginBottom: 8 }}>
        {tr('stats.goals').toUpperCase()}
      </Text>
      {currentGoals.map((goal) => {
        const dates = new Set(weekDatesIso(goal.weekStart));
        const progress = goalProgress(goal, shifts.filter((shift) => dates.has(shift.date)));
        return (
          <Card key={goal.id} style={{ padding: 14, marginBottom: 8 }}>
            <Text style={{ color: t.ink, fontWeight: '700' }}>
              {tr(`stats.goalMetrics.${goal.metric}`)} · {metricDisplay(goal.metric, goal.target)}
            </Text>
            <Text style={{ color: t.softText, fontSize: 12, marginTop: 5 }}>
              {tr('stats.expectedProgress')}: {progress.expected == null ? '—' : metricDisplay(goal.metric, progress.expected)}
            </Text>
            <Text style={{ color: goal.metric === 'worked_hours' ? t.ink : t.green, backgroundColor: t.paper, padding: 4, fontSize: 12, marginTop: 3, fontWeight: '600' }}>
              {tr('stats.actualProgress')}: {metricDisplay(goal.metric, progress.actual)}
            </Text>
          </Card>
        );
      })}
      <Card style={{ padding: 14, marginBottom: 14 }}>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 10 }}>
          {GOAL_METRICS.map((metric) => (
            <Chip
              key={metric}
              label={tr(`stats.goalMetrics.${metric}`)}
              selected={goalMetric === metric}
              onPress={() => setGoalMetric(metric)}
            />
          ))}
        </View>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 10 }}>
          <Chip label={tr('stats.allEmployers')} selected={goalEmployerId === null} onPress={() => setGoalEmployerId(null)} />
          {employers.filter((employer) => !employer.archived).map((employer) => (
            <Chip
              key={employer.id}
              label={employer.name}
              selected={goalEmployerId === employer.id}
              color={employer.color}
              onPress={() => setGoalEmployerId(employer.id)}
            />
          ))}
        </View>
        <Field
          label={tr('stats.goalTarget')}
          value={goalTarget}
          onChangeText={setGoalTarget}
          keyboardType="decimal-pad"
        />
        <Chip
          label={tr('stats.repeatGoal')}
          selected={repeatGoal}
          onPress={() => setRepeatGoal((value) => !value)}
        />
        <PrimaryButton label={tr('stats.addGoal')} onPress={saveGoal} style={{ marginTop: 10 }} />
      </Card>

      {/* Basic trends and reliable best-day/employer comparisons. */}
      <Text style={{ color: t.softText, fontWeight: '700', fontSize: 12, marginBottom: 8 }}>
        {tr('stats.trends').toUpperCase()}
      </Text>
      <Card style={{ padding: 14, marginBottom: 14 }}>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
          {TREND_METRICS.map((metric) => (
            <Chip
              key={metric}
              label={tr(`stats.trendMetrics.${metric}`)}
              selected={trendMetric === metric}
              onPress={() => setTrendMetric(metric)}
            />
          ))}
        </View>
        <TrendRow
          label={tr('stats.weekOverWeek')}
          current={trendValue(trendStats.currentWeek, trendMetric)}
          previous={trendValue(trendStats.previousWeek, trendMetric)}
          metric={trendMetric}
          format={metricDisplay}
        />
        <View style={{ height: 10 }} />
        <TrendRow
          label={tr('stats.monthOverMonth')}
          current={trendValue(trendStats.currentMonth, trendMetric)}
          previous={trendValue(trendStats.previousMonth, trendMetric)}
          metric={trendMetric}
          format={metricDisplay}
        />
        <View style={{ borderTopWidth: 1, borderTopColor: t.line, marginTop: 12, paddingTop: 12 }}>
          {trendStats.bestEmployer && trendStats.bestWeekday ? (
            <>
              <Text style={{ color: t.ink, fontWeight: '600' }}>
                {tr('stats.bestEmployer')}: {employers.find((employer) => employer.id === trendStats.bestEmployer?.key)?.name ?? '—'}
              </Text>
              <Text style={{ color: t.softText, fontSize: 12, marginTop: 3 }}>
                {metricDisplay(trendMetric, trendStats.bestEmployer.value)} · n={trendStats.bestEmployer.sampleSize}
              </Text>
              <Text style={{ color: t.ink, fontWeight: '600', marginTop: 9 }}>
                {tr('stats.bestDay')}: {weekdayName(trendStats.bestWeekday.key)}
              </Text>
              <Text style={{ color: t.softText, fontSize: 12, marginTop: 3 }}>
                {metricDisplay(trendMetric, trendStats.bestWeekday.value)} · n={trendStats.bestWeekday.sampleSize}
              </Text>
              <Text style={{ color: t.softText, fontSize: 11, marginTop: 8 }}>{tr('stats.last90Days')}</Text>
            </>
          ) : (
            <Text style={{ color: t.softText }}>{tr('stats.insufficientData')}</Text>
          )}
        </View>
      </Card>

      {/* Per-employer */}
      <Text style={{ color: t.softText, fontWeight: '700', fontSize: 12, marginBottom: 8 }}>
        {tr('stats.byEmployer').toUpperCase()}
      </Text>
      {stats.byEmployer.length === 0 ? (
        <Text style={{ color: t.softText, fontSize: 13 }}>{tr('stats.noData')}</Text>
      ) : (
        stats.byEmployer.map((row) => (
          <Card
            key={row.employerId}
            style={{
              padding: 14,
              marginBottom: 8,
            }}
          >
            {(() => {
              const employer = employers.find((value) => value.id === row.employerId);
              return (
                <>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                    <Avatar name={employer?.name ?? ''} color={employer?.color ?? t.cobaltLink} />
                    <Text style={{ flex: 1, color: t.ink, fontWeight: '700', fontSize: 14 }}>
                      {employer?.name ?? '\u2014'}
                    </Text>
                    <Text style={{ color: t.green, backgroundColor: t.greenSoft, padding: 4, fontWeight: '700', fontSize: 15 }}>
                      {money(row.totals.grossEarnings)}
                    </Text>
                  </View>
                  <LedgerRow label={tr('stats.expectedBaseWages')} value={money(row.totals.expectedBaseWages)} />
                  <LedgerRow label={tr('stats.actualBaseWages')} value={money(row.totals.actualBaseWages)} />
                  <LedgerRow label={tr('stats.netTips')} value={money(row.totals.netTips)} />
                  <LedgerRow label={tr('stats.otherIncome')} value={money(row.totals.otherIncome)} />
                  <LedgerRow label={tr('stats.estimatedNet')} value={money(row.totals.estimatedNet)} />
                  <LedgerRow
                    label={tr('stats.workedHours')}
                    value={`${(row.totals.workedMinutes / 60).toFixed(1)} ${tr('common.hours')}`}
                  />
                  <LedgerRow
                    label={tr('stats.effectiveHourly')}
                    value={row.totals.effectiveHourly == null ? '\u2014' : `${money(row.totals.effectiveHourly)}/h`}
                  />
                </>
              );
            })()}
          </Card>
        ))
      )}
    </ScrollView>
  );
}

function SectionTitle({ label }: { label: string }) {
  const { t } = useTokens();
  return (
    <Text style={{ color: t.ink, fontSize: 13, fontWeight: '700', marginBottom: 7 }}>
      {label}
    </Text>
  );
}

function LedgerRow({
  label,
  value,
  tone = 'default',
}: {
  label: string;
  value: string;
  tone?: 'default' | 'muted' | 'positive' | 'warning';
}) {
  const { t } = useTokens();
  const color = tone === 'positive' ? t.green : tone === 'warning' ? t.amber : tone === 'muted' ? t.softText : t.ink;
  const backgroundColor = tone === 'positive' ? t.greenSoft : tone === 'warning' ? t.amberSoft : 'transparent';
  return (
    <View style={{ flexDirection: 'row', justifyContent: 'space-between', gap: 12, paddingVertical: 3 }}>
      <Text style={{ color: t.softText, flex: 1, fontSize: 12 }}>{label}</Text>
      <Text style={{ color, backgroundColor, paddingHorizontal: tone === 'positive' || tone === 'warning' ? 4 : 0, fontWeight: '600', fontSize: 12 }}>{value}</Text>
    </View>
  );
}

function moneyOrDash(value: number | null): string {
  return value == null ? '\u2014' : money(value);
}

function signedMoneyOrDash(value: number | null): string {
  return value == null ? '\u2014' : `${value > 0 ? '+' : ''}${money(value)}`;
}

function TrendRow({
  label,
  current,
  previous,
  metric,
  format,
}: {
  label: string;
  current: number | null;
  previous: number | null;
  metric: TrendMetric;
  format: (metric: TrendMetric, value: number | null) => string;
}) {
  const { t } = useTokens();
  const change = current == null || previous == null ? null : percentChange(current, previous);
  const positiveColor = metric === 'hours' ? t.ink : t.green;
  return (
    <View>
      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600' }}>{label}</Text>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginTop: 4 }}>
        <Text style={{ color: t.ink, fontSize: 16, fontWeight: '700' }}>{format(metric, current)}</Text>
        <Text style={{
          color: change == null ? t.softText : change >= 0 ? positiveColor : t.red,
          backgroundColor: 'transparent',
          paddingHorizontal: change == null ? 0 : 4,
          fontWeight: '700',
        }}>
          {change == null ? '—' : `${change >= 0 ? '+' : ''}${change}%`}
        </Text>
      </View>
    </View>
  );
}
