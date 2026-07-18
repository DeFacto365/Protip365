import React, { useMemo, useState } from 'react';
import {
  Alert,
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
  Chip,
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
import type { Shift } from '../../src/domain/types';
import { isActualsPending } from '../../src/domain/reminders';
import { useSettingsStore } from '../../src/state/settingsStore';
import { useWriteAccess } from '../../src/ui/WriteAccess';

type ScheduleView = 'day' | 'week' | 'month';

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
  const weekDates = useMemo(() => weekDatesIso(weekStart), [weekStart]);
  const monthDates = useMemo(() => monthDatesIso(selectedDate), [selectedDate]);

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

  const openShift = (shift: Shift) => {
    if (shift.status === 'planned' && shift.date <= today) {
      router.push({ pathname: '/complete/[id]', params: { id: shift.id } });
    } else if (shift.status === 'worked') {
      router.push({ pathname: '/complete/[id]', params: { id: shift.id } });
    } else {
      router.push({ pathname: '/shift-form', params: { id: shift.id } });
    }
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
          accessibilityLabel={tr('schedule.nextPeriod')}
          onPress={() => navigatePeriod(1)}
          style={[styles.navBtn, { backgroundColor: t.card, borderColor: t.line }]}
        >
          <Text style={{ color: t.ink, fontSize: 16 }}>›</Text>
        </Pressable>
      </View>

      <View style={{ flexDirection: 'row', justifyContent: 'center', gap: 8, marginBottom: 8 }}>
        {(['day', 'week', 'month'] as const).map((item) => (
          <Chip
            key={item}
            label={tr(`schedule.views.${item}`)}
            selected={view === item}
            onPress={() => {
              setView(item);
              setWeekStart(startOfWeekIso(selectedDate));
            }}
          />
        ))}
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
                <Text style={{ color: selected ? '#FFFFFF' : t.softText, fontSize: 10, fontWeight: '600' }}>
                  {shortDay(date)}
                </Text>
                <Text style={{ color: selected ? '#FFFFFF' : t.ink, fontWeight: '700', fontSize: 13 }}>
                  {Number(date.slice(8))}
                </Text>
                <View
                  style={{
                    width: 4,
                    height: 4,
                    backgroundColor: hasShift ? (selected ? '#FFFFFF' : t.cobaltLink) : 'transparent',
                  }}
                />
              </Pressable>
            );
          })}
        </View>
      ) : (
        <View style={styles.monthGrid}>
          {weekDatesIso('2026-07-13').map((date) => (
            <Text key={date} style={[styles.monthWeekday, { color: t.softText }]}>
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
                <Text style={{ color: selected ? '#FFFFFF' : t.ink, fontWeight: '700' }}>
                  {Number(date.slice(8))}
                </Text>
                <View
                  style={{
                    width: 4,
                    height: 4,
                    backgroundColor: hasShift ? (selected ? '#FFFFFF' : t.cobaltLink) : 'transparent',
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
          <Text style={{ color: t.cobaltLink, fontWeight: '600', fontSize: 13 }}>
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
            const varianceValue = isWorked ? variance(item) : null;
            const actualsPending = isActualsPending(item, new Date(), reminderDelayMinutes);
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
                        {actualsPending ? (
                          <View style={{ backgroundColor: t.amberSoft, paddingHorizontal: 8, paddingVertical: 3 }}>
                            <Text style={{ color: t.amber, fontSize: 10, fontWeight: '700', letterSpacing: 0.6 }}>
                              {tr('schedule.actualsPending')}
                            </Text>
                          </View>
                        ) : (
                          <StatusChip status={item.status} />
                        )}
                      </View>
                      {isWorked ? (
                        <>
                          <Text style={{ color: t.ink, fontWeight: '700', fontSize: 14 }}>
                            {money(actualEarnings(item))}
                          </Text>
                          <Text style={{
                            color: varianceValue == null ? t.softText : varianceValue >= 0 ? t.green : t.amber,
                            backgroundColor: varianceValue == null ? 'transparent' : varianceValue >= 0 ? t.greenSoft : t.amberSoft,
                            paddingHorizontal: varianceValue == null ? 0 : 4,
                            fontSize: 11,
                            fontWeight: '600',
                          }}>
                            {tr('schedule.vsExpected', { amount: varianceValue == null ? '—' : signedMoney(varianceValue) })}
                          </Text>
                        </>
                      ) : item.status === 'planned' ? (
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
        onPress={() => {
          if (requireWrite()) router.push('/shift-form');
        }}
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
