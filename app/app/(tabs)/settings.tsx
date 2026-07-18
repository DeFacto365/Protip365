import React, { useState } from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import * as Sharing from 'expo-sharing';
import { File, Paths } from 'expo-file-system';
import { useTranslation } from 'react-i18next';
import { useRouter } from 'expo-router';

import { useSettingsStore, type Language } from '../../src/state/settingsStore';
import { useShiftsStore } from '../../src/state/shiftsStore';
import { useEmployersStore } from '../../src/state/employersStore';
import { useTemplatesStore } from '../../src/state/templatesStore';
import { useGoalsStore } from '../../src/state/goalsStore';
import { useAppLockStore } from '../../src/state/appLockStore';
import { useEntitlementStore } from '../../src/state/entitlementStore';
import { useTokens } from '../../src/ui/tokens';
import { Chip, Field, GhostButton, PrimaryButton } from '../../src/ui/components';
import {
  actualEarnings,
  actualPaidMinutes,
  effectiveHourly,
  estimatedNet,
  expectedEarnings,
  scheduledPaidMinutes,
  variance,
} from '../../src/domain/calc';
import { minutesToHHMM } from '../../src/domain/dates';
import type { ShiftBreak } from '../../src/domain/types';
import { centsToFixed } from '../../src/domain/money';
import { validateDeductionBasisPoints } from '../../src/domain/validate';
import {
  notificationsSupported,
  requestReminderPermission,
  syncAllShiftReminders,
} from '../../src/notifications/shiftReminders';

const LANGUAGES: Language[] = ['en', 'fr-CA', 'es'];

function csvEscape(value: string | number | null | undefined): string {
  const text = value == null ? '' : String(value);
  if (/[",\n]/.test(text)) return `"${text.replace(/"/g, '""')}"`;
  return text;
}

/** DEF-03: serialize break rows for CSV, e.g. "Lunch 13:00 30min unpaid; …". */
function breaksToCsv(breaks: ShiftBreak[] | null | undefined): string {
  if (!breaks || breaks.length === 0) return '';
  return breaks
    .map(
      (b) =>
        `${b.label} ${minutesToHHMM(b.startMin)} ${b.durationMin}min ${b.paid ? 'paid' : 'unpaid'}`
    )
    .join('; ');
}

export default function SettingsScreen() {
  const router = useRouter();
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const language = useSettingsStore((s) => s.language);
  const setLanguage = useSettingsStore((s) => s.setLanguage);
  const defaultDeductionRateBp = useSettingsStore((s) => s.defaultDeductionRateBp);
  const setDefaultDeductionRateBp = useSettingsStore((s) => s.setDefaultDeductionRateBp);
  const reminderEnabled = useSettingsStore((s) => s.postShiftReminderEnabled);
  const reminderDelayMinutes = useSettingsStore((s) => s.postShiftReminderDelayMinutes);
  const setReminderEnabled = useSettingsStore((s) => s.setPostShiftReminderEnabled);
  const setReminderDelay = useSettingsStore((s) => s.setPostShiftReminderDelayMinutes);
  const eraseAll = useSettingsStore((s) => s.eraseAll);
  const loadShifts = useShiftsStore((s) => s.load);
  const loadEmployers = useEmployersStore((s) => s.load);
  const loadTemplates = useTemplatesStore((s) => s.load);
  const loadGoals = useGoalsStore((s) => s.load);
  const resetLock = useAppLockStore((s) => s.reset);
  const rehydrateEntitlement = useEntitlementStore((s) => s.rehydrateAfterDataChange);
  const shifts = useShiftsStore((s) => s.shifts);
  const employers = useEmployersStore((s) => s.employers);
  const roles = useEmployersStore((s) => s.roles);

  const [rateText, setRateText] = useState(String(defaultDeductionRateBp / 100));
  const [rateError, setRateError] = useState<string | null>(null);
  const [reminderDelayText, setReminderDelayText] = useState(String(reminderDelayMinutes / 60));

  const onRateChange = (text: string) => {
    setRateText(text);
    const pct = Number(text.replace(',', '.'));
    const basisPoints = Math.round(pct * 100);
    if (
      !Number.isFinite(pct) ||
      pct < 0 ||
      pct > 100 ||
      !validateDeductionBasisPoints(basisPoints).valid
    ) {
      setRateError(tr('shiftForm.errors.deduction_out_of_range'));
      return;
    }
    setRateError(null);
    setDefaultDeductionRateBp(basisPoints);
  };

  const onExportCsv = async () => {
    try {
      const header = [
        'date',
        'employer',
        'role',
        'status',
        'scheduled_start',
        'scheduled_end',
        'scheduled_paid_hours',
        'scheduled_breaks',
        'actual_start',
        'actual_end',
        'actual_paid_hours',
        'actual_breaks',
        'hourly_rate',
        'planned_expected_tips',
        'planned_other_income',
        'actual_hourly_rate',
        'tip_method',
        'direct_tips',
        'pool_contribution',
        'tip_share_received',
        'tip_out_paid',
        'sales',
        'other_income',
        'deduction_rate',
        'expected_earnings',
        'actual_earnings',
        'variance',
        'effective_hourly',
        'estimated_net',
        'expected_payout',
        'actual_received',
        'payout_status',
        'not_worked_reason',
        'not_worked_note',
        'notes',
      ].join(',');

      const lines = shifts.map((s) => {
        const employer = employers.find((e) => e.id === s.employerId);
        const role = roles.find((r) => r.id === s.roleId);
        const worked = s.status === 'worked';
        return [
          s.date,
          csvEscape(employer?.name),
          csvEscape(role?.name),
          s.status,
          minutesToHHMM(s.startMin),
          minutesToHHMM(s.endMin),
          (scheduledPaidMinutes(s) / 60).toFixed(2),
          csvEscape(breaksToCsv(s.breaks)),
          s.actualStartMin != null ? minutesToHHMM(s.actualStartMin) : '',
          s.actualEndMin != null ? minutesToHHMM(s.actualEndMin) : '',
          worked ? (actualPaidMinutes(s) / 60).toFixed(2) : '',
          csvEscape(breaksToCsv(s.actualBreaks)),
          centsToFixed(s.hourlyRateSnapshot),
          s.plannedExpectedTips != null ? centsToFixed(s.plannedExpectedTips) : '',
          s.plannedOtherIncome != null ? centsToFixed(s.plannedOtherIncome) : '',
          s.actualHourlyRateSnapshot != null ? centsToFixed(s.actualHourlyRateSnapshot) : '',
          s.tipMethod ?? '',
          s.directTips != null ? centsToFixed(s.directTips) : '',
          s.poolContribution != null ? centsToFixed(s.poolContribution) : '',
          s.tipShareReceived != null ? centsToFixed(s.tipShareReceived) : '',
          s.tipOutPaid != null ? centsToFixed(s.tipOutPaid) : '',
          s.sales != null ? centsToFixed(s.sales) : '',
          s.otherIncome != null ? centsToFixed(s.otherIncome) : '',
          // DEF-03/DEF-14: exported as a percentage of gross (snapshot fraction × 100).
          s.deductionRateSnapshotBp != null ? (s.deductionRateSnapshotBp / 100).toFixed(2) : '',
          centsToFixed(expectedEarnings(s)),
          worked ? centsToFixed(actualEarnings(s)) : '',
          worked && variance(s) != null ? centsToFixed(variance(s)!) : '',
          worked && effectiveHourly(s) != null ? centsToFixed(effectiveHourly(s)!) : '',
          worked ? centsToFixed(estimatedNet(s)) : '',
          s.expectedPayout != null ? centsToFixed(s.expectedPayout) : '',
          s.actualReceived != null ? centsToFixed(s.actualReceived) : '',
          s.payoutStatus ?? '',
          csvEscape(s.notWorkedReason),
          csvEscape(s.notWorkedNote),
          csvEscape(s.notes),
        ].join(',');
      });

      const csv = [header, ...lines].join('\n');
      const file = new File(Paths.cache, 'protip365-shifts.csv');
      if (file.exists) file.delete();
      file.write(csv);
      await Sharing.shareAsync(file.uri, { mimeType: 'text/csv' });
    } catch {
      Alert.alert(tr('settings.exportError'));
    }
  };

  const toggleReminders = async () => {
    const next = !reminderEnabled;
    if (next && notificationsSupported() && !(await requestReminderPermission())) {
      Alert.alert(tr('reminders.permissionDenied'));
      return;
    }
    setReminderEnabled(next);
    await syncAllShiftReminders(shifts, next, reminderDelayMinutes);
    if (next && !notificationsSupported()) Alert.alert(tr('reminders.expoGoFallback'));
  };

  const onReminderDelayChange = async (text: string) => {
    setReminderDelayText(text);
    const hours = Number(text.replace(',', '.'));
    if (!Number.isFinite(hours) || hours < 0 || hours > 24) return;
    const minutes = Math.round(hours * 60);
    setReminderDelay(minutes);
    await syncAllShiftReminders(shifts, reminderEnabled, minutes);
  };

  const onErase = () => {
    Alert.alert(tr('settings.eraseConfirmTitle'), tr('settings.eraseConfirmMessage'), [
      { text: tr('common.cancel'), style: 'cancel' },
      {
        text: tr('settings.eraseConfirmAction'),
        style: 'destructive',
        onPress: () => {
          void (async () => {
            try {
              await eraseAll();
              await loadShifts();
              loadEmployers();
              loadTemplates();
              loadGoals();
              resetLock();
              rehydrateEntitlement();
              setRateText('0');
            } catch {
              Alert.alert(tr('reminders.cancelFailed'));
            }
          })();
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
      {/* Language */}
      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 8 }}>
        {tr('settings.language')}
      </Text>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 20 }}>
        {LANGUAGES.map((lang) => (
          <Chip
            key={lang}
            label={tr(`settings.languages.${lang}`)}
            selected={language === lang}
            onPress={() => setLanguage(lang)}
          />
        ))}
      </View>

      {/* Default deduction rate */}
      <Field
        label={tr('settings.defaultDeductionRate')}
        value={rateText}
        onChangeText={onRateChange}
        keyboardType="decimal-pad"
        hint={tr('settings.deductionHint')}
        error={rateError}
      />

      <View style={{ height: 12 }} />

      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 8 }}>
        {tr('reminders.title')}
      </Text>
      <Chip
        label={tr('reminders.enable')}
        selected={reminderEnabled}
        onPress={() => void toggleReminders()}
      />
      <Field
        label={tr('reminders.delayHours')}
        value={reminderDelayText}
        onChangeText={(text) => void onReminderDelayChange(text)}
        keyboardType="decimal-pad"
        hint={tr('reminders.privacyHint')}
      />

      <GhostButton
        label={tr('settings.manageEmployers')}
        onPress={() => router.push('/employers')}
        style={{ marginBottom: 12 }}
      />
      <GhostButton
        label={tr('settings.manageTemplates')}
        onPress={() => router.push('/templates')}
        style={{ marginBottom: 12 }}
      />
      <GhostButton
        label={tr('settings.security')}
        onPress={() => router.push('/security')}
        style={{ marginBottom: 12 }}
      />
      <GhostButton
        label={tr('settings.backup')}
        onPress={() => router.push('/backup')}
        style={{ marginBottom: 12 }}
      />
      <GhostButton
        label={tr('paywall.manage')}
        onPress={() => router.push('/paywall')}
        style={{ marginBottom: 12 }}
      />
      <PrimaryButton label={tr('settings.exportCsv')} onPress={() => void onExportCsv()} style={{ marginBottom: 12 }} />
      <GhostButton label={tr('settings.eraseData')} onPress={onErase} danger />
    </ScrollView>
  );
}
