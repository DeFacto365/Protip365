import React, { useMemo } from 'react';
import { ScrollView, Text, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { useShiftsStore } from '../../src/state/shiftsStore';
import { useEmployersStore } from '../../src/state/employersStore';
import { useTokens } from '../../src/ui/tokens';
import { Avatar, Card, money } from '../../src/ui/components';
import {
  actualEarnings,
  actualPaidMinutes,
  expectedEarnings,
  roundCents,
} from '../../src/domain/calc';
import { startOfWeekIso, todayIso, weekDatesIso } from '../../src/domain/dates';

export default function StatsScreen() {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const shifts = useShiftsStore((s) => s.shifts);
  const employers = useEmployersStore((s) => s.employers);

  const stats = useMemo(() => {
    const weekDates = new Set(weekDatesIso(startOfWeekIso(todayIso())));
    const weekShifts = shifts.filter((s) => weekDates.has(s.date));
    const workedShifts = weekShifts.filter((s) => s.status === 'worked');

    // Expected counts scheduled + worked shifts (planned view of the week).
    const expectedTotal = roundCents(
      weekShifts
        .filter((s) => s.status === 'scheduled' || s.status === 'worked')
        .reduce((sum, s) => sum + expectedEarnings(s), 0)
    );
    const actualTotal = roundCents(
      workedShifts.reduce((sum, s) => sum + actualEarnings(s), 0)
    );
    const workedMinutes = workedShifts.reduce((sum, s) => sum + actualPaidMinutes(s), 0);
    const effHourly = workedMinutes > 0 ? roundCents(actualTotal / (workedMinutes / 60)) : 0;

    const byEmployer = employers
      .map((e) => {
        const empShifts = workedShifts.filter((s) => s.employerId === e.id);
        const amount = roundCents(empShifts.reduce((sum, s) => sum + actualEarnings(s), 0));
        const minutes = empShifts.reduce((sum, s) => sum + actualPaidMinutes(s), 0);
        return {
          employer: e,
          amount,
          hourly: minutes > 0 ? roundCents(amount / (minutes / 60)) : 0,
          count: empShifts.length,
        };
      })
      .filter((row) => row.count > 0)
      .sort((a, b) => b.amount - a.amount);

    return { expectedTotal, actualTotal, workedMinutes, effHourly, byEmployer };
  }, [shifts, employers]);

  const maxBar = Math.max(stats.expectedTotal, stats.actualTotal, 1);

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 16, paddingBottom: 48 }}
    >
      <Text style={{ color: t.ink, fontWeight: '700', fontSize: 20, marginBottom: 14 }}>
        {tr('stats.title')}
      </Text>

      {/* Expected vs actual bars */}
      <Card style={{ padding: 16, marginBottom: 14 }}>
        <BarRow
          label={tr('stats.expected')}
          amount={stats.expectedTotal}
          fraction={stats.expectedTotal / maxBar}
          color={t.cobaltLink}
        />
        <View style={{ height: 12 }} />
        <BarRow
          label={tr('stats.actual')}
          amount={stats.actualTotal}
          fraction={stats.actualTotal / maxBar}
          color={t.green}
        />
      </Card>

      {/* Effective hourly + worked hours */}
      <View style={{ flexDirection: 'row', gap: 12, marginBottom: 14 }}>
        <Card style={{ flex: 1, padding: 14, alignItems: 'center' }}>
          <Text style={{ color: t.ink, fontWeight: '700', fontSize: 20 }}>
            {money(stats.effHourly)}/h
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

      {/* Per-employer */}
      <Text style={{ color: t.softText, fontWeight: '700', fontSize: 12, marginBottom: 8 }}>
        {tr('stats.byEmployer').toUpperCase()}
      </Text>
      {stats.byEmployer.length === 0 ? (
        <Text style={{ color: t.softText, fontSize: 13 }}>{tr('stats.noData')}</Text>
      ) : (
        stats.byEmployer.map((row) => (
          <Card
            key={row.employer.id}
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              padding: 12,
              marginBottom: 8,
              gap: 10,
            }}
          >
            <Avatar name={row.employer.name} color={row.employer.color} />
            <Text style={{ flex: 1, color: t.ink, fontWeight: '600', fontSize: 14 }}>
              {row.employer.name}
            </Text>
            <View style={{ alignItems: 'flex-end' }}>
              <Text style={{ color: t.green, fontWeight: '700', fontSize: 15 }}>
                {money(row.amount)}
              </Text>
              <Text style={{ color: t.softText, fontSize: 11 }}>{money(row.hourly)}/h</Text>
            </View>
          </Card>
        ))
      )}
    </ScrollView>
  );
}

function BarRow({
  label,
  amount,
  fraction,
  color,
}: {
  label: string;
  amount: number;
  fraction: number;
  color: string;
}) {
  const { t } = useTokens();
  return (
    <View>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 }}>
        <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600' }}>{label}</Text>
        <Text style={{ color: t.ink, fontWeight: '700', fontSize: 13 }}>{money(amount)}</Text>
      </View>
      <View style={{ height: 10, backgroundColor: t.bg, overflow: 'hidden' }}>
        <View
          style={{
            width: `${Math.max(Math.min(fraction, 1) * 100, 2)}%`,
            height: '100%',
            backgroundColor: color,
          }}
        />
      </View>
    </View>
  );
}
