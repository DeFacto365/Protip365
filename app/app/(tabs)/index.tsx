import React, { useMemo, useState } from 'react';
import {
  Pressable,
  SectionList,
  StyleSheet,
  Text,
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
  money,
  signedMoney,
  StatusChip,
} from '../../src/ui/components';
import {
  actualEarnings,
  expectedEarnings,
  scheduledPaidMinutes,
  variance,
} from '../../src/domain/calc';
import { copyWeekForward } from '../../src/domain/copyWeek';
import { overlappingShiftIds } from '../../src/domain/overlap';
import {
  addDaysIso,
  minutesToHHMM,
  startOfWeekIso,
  todayIso,
  weekDatesIso,
} from '../../src/domain/dates';
import type { Shift } from '../../src/domain/types';

export default function ScheduleScreen() {
  const router = useRouter();
  const { t } = useTokens();
  const { t: tr, i18n } = useTranslation();
  const shifts = useShiftsStore((s) => s.shifts);
  const addShift = useShiftsStore((s) => s.addShift);
  const employers = useEmployersStore((s) => s.employers);
  const roles = useEmployersStore((s) => s.roles);

  const today = todayIso();
  const [weekStart, setWeekStart] = useState(() => startOfWeekIso(today));
  const weekDates = useMemo(() => weekDatesIso(weekStart), [weekStart]);

  const weekShifts = useMemo(
    () => shifts.filter((s) => weekDates.includes(s.date)),
    [shifts, weekDates]
  );

  // DEF-01: flag overlapping shifts. Include the adjacent days so an overnight
  // shift spilling into this week (or out of it) is still detected.
  const overlapIds = useMemo(() => {
    const from = addDaysIso(weekStart, -1);
    const to = addDaysIso(weekStart, 7);
    return overlappingShiftIds(shifts.filter((s) => s.date >= from && s.date <= to));
  }, [shifts, weekStart]);

  const scheduledHours = useMemo(
    () => weekShifts.reduce((sum, s) => sum + scheduledPaidMinutes(s), 0) / 60,
    [weekShifts]
  );

  const sections = useMemo(
    () =>
      weekDates
        .map((date) => ({
          date,
          data: weekShifts
            .filter((s) => s.date === date)
            .sort((a, b) => a.startMin - b.startMin),
        }))
        .filter((sec) => sec.data.length > 0),
    [weekDates, weekShifts]
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

  const openShift = (shift: Shift) => {
    if (shift.status === 'scheduled' && shift.date <= today) {
      router.push({ pathname: '/complete/[id]', params: { id: shift.id } });
    } else if (shift.status === 'worked') {
      router.push({ pathname: '/complete/[id]', params: { id: shift.id } });
    } else {
      router.push({ pathname: '/shift-form', params: { id: shift.id } });
    }
  };

  const onCopyWeek = () => {
    const plans = copyWeekForward(shifts, weekStart);
    for (const plan of plans) {
      addShift(plan);
    }
    if (plans.length > 0) setWeekStart(addDaysIso(weekStart, 7));
  };

  return (
    <View style={{ flex: 1, backgroundColor: t.bg }}>
      {/* Week header */}
      <View style={styles.weekHeader}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={tr('schedule.prevWeek')}
          onPress={() => setWeekStart(addDaysIso(weekStart, -7))}
          style={[styles.navBtn, { backgroundColor: t.card, borderColor: t.line }]}
        >
          <Text style={{ color: t.ink, fontSize: 16 }}>‹</Text>
        </Pressable>
        <View style={{ alignItems: 'center' }}>
          <Text style={{ color: t.ink, fontWeight: '700', fontSize: 16 }}>
            {scheduledHours.toFixed(1)} {tr('common.hours')}
          </Text>
          <Text style={{ color: t.softText, fontSize: 10, letterSpacing: 1, fontWeight: '600' }}>
            {tr('schedule.scheduledHours')}
          </Text>
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={tr('schedule.nextWeek')}
          onPress={() => setWeekStart(addDaysIso(weekStart, 7))}
          style={[styles.navBtn, { backgroundColor: t.card, borderColor: t.line }]}
        >
          <Text style={{ color: t.ink, fontSize: 16 }}>›</Text>
        </Pressable>
      </View>

      {/* Week strip */}
      <View style={styles.weekStrip}>
        {weekDates.map((date) => {
          const isToday = date === today;
          const hasShift = weekShifts.some((s) => s.date === date);
          return (
            <View
              key={date}
              style={[
                styles.dayCell,
                {
                  backgroundColor: isToday ? t.cobalt : t.card,
                  borderColor: isToday ? t.cobalt : t.line,
                },
              ]}
            >
              <Text
                style={{
                  color: isToday ? '#FFFFFF' : t.softText,
                  fontSize: 10,
                  fontWeight: '600',
                }}
              >
                {shortDay(date)}
              </Text>
              <Text style={{ color: isToday ? '#FFFFFF' : t.ink, fontWeight: '700', fontSize: 13 }}>
                {Number(date.slice(8))}
              </Text>
              <View
                style={{
                  width: 4,
                  height: 4,
                  backgroundColor: hasShift ? (isToday ? '#FFFFFF' : t.cobaltLink) : 'transparent',
                }}
              />
            </View>
          );
        })}
      </View>

      {/* Copy week */}
      <View style={{ flexDirection: 'row', justifyContent: 'flex-end', paddingHorizontal: 16 }}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={tr('schedule.copyWeek')}
          onPress={onCopyWeek}
          style={({ pressed }) => ({ opacity: pressed ? 0.6 : 1, minHeight: 32, justifyContent: 'center' })}
        >
          <Text style={{ color: t.cobaltLink, fontWeight: '600', fontSize: 13 }}>
            ⧉ {tr('schedule.copyWeek')}
          </Text>
        </Pressable>
      </View>

      {/* Agenda */}
      {sections.length === 0 ? (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 }}>
          <Text style={{ color: t.ink, fontWeight: '600', fontSize: 15, marginBottom: 6 }}>
            {tr('schedule.emptyWeek')}
          </Text>
          <Text style={{ color: t.softText, fontSize: 13, textAlign: 'center' }}>
            {tr('schedule.emptyHint')}
          </Text>
        </View>
      ) : (
        <SectionList
          sections={sections}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ padding: 16, paddingBottom: 120 }}
          renderSectionHeader={({ section }) => (
            <Text
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
            return (
              <Pressable
                accessibilityRole="button"
                onPress={() => openShift(item)}
                style={({ pressed }) => ({ opacity: pressed ? 0.85 : 1, marginBottom: 8 })}
              >
                <Card style={{ flexDirection: 'row', overflow: 'hidden' }}>
                  <View style={{ width: 4, backgroundColor: employer?.color ?? t.line }} />
                  <View style={{ flex: 1, flexDirection: 'row', alignItems: 'center', padding: 12, gap: 10 }}>
                    <Avatar name={employer?.name ?? '?'} color={employer?.color ?? t.softText} />
                    <View style={{ flex: 1 }}>
                      <Text style={{ color: t.ink, fontWeight: '700', fontSize: 14 }}>
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
                        <StatusChip status={item.status} />
                      </View>
                      {isWorked ? (
                        <>
                          <Text style={{ color: t.ink, fontWeight: '700', fontSize: 14 }}>
                            {money(actualEarnings(item))}
                          </Text>
                          <Text style={{ color: variance(item) >= 0 ? t.green : t.amber, fontSize: 11, fontWeight: '600' }}>
                            {tr('schedule.vsExpected', { amount: signedMoney(variance(item)) })}
                          </Text>
                        </>
                      ) : item.status === 'scheduled' ? (
                        <Text style={{ color: t.ink, fontWeight: '700', fontSize: 14 }}>
                          {money(expected)}
                        </Text>
                      ) : null}
                    </View>
                  </View>
                </Card>
              </Pressable>
            );
          }}
        />
      )}

      {/* Extended FAB — Schedule tab only */}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={tr('schedule.addShift')}
        onPress={() => router.push('/shift-form')}
        style={({ pressed }) => [
          styles.fab,
          { backgroundColor: t.cobalt, opacity: pressed ? 0.9 : 1 },
        ]}
      >
        <Text style={{ color: t.fabText, fontWeight: '700', fontSize: 14 }}>
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
    shadowColor: '#2B4BD7',
    shadowOpacity: 0.4,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
  },
});
