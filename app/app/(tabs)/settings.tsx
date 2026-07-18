import React, { useState } from 'react';
import { Alert, ScrollView, Text, View } from 'react-native';
import * as Sharing from 'expo-sharing';
import { File, Paths } from 'expo-file-system';
import { useTranslation } from 'react-i18next';

import { useSettingsStore, type Language } from '../../src/state/settingsStore';
import { useShiftsStore } from '../../src/state/shiftsStore';
import { useEmployersStore } from '../../src/state/employersStore';
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
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const language = useSettingsStore((s) => s.language);
  const setLanguage = useSettingsStore((s) => s.setLanguage);
  const defaultDeductionRate = useSettingsStore((s) => s.defaultDeductionRate);
  const setDefaultDeductionRate = useSettingsStore((s) => s.setDefaultDeductionRate);
  const eraseAll = useSettingsStore((s) => s.eraseAll);
  const loadShifts = useShiftsStore((s) => s.load);
  const loadEmployers = useEmployersStore((s) => s.load);
  const shifts = useShiftsStore((s) => s.shifts);
  const employers = useEmployersStore((s) => s.employers);
  const roles = useEmployersStore((s) => s.roles);

  const [rateText, setRateText] = useState(String(Math.round(defaultDeductionRate * 100)));

  const onRateChange = (text: string) => {
    setRateText(text);
    const pct = Number(text.replace(',', '.'));
    if (Number.isFinite(pct) && pct >= 0 && pct <= 100) {
      setDefaultDeductionRate(pct / 100);
    }
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
          s.hourlyRateSnapshot.toFixed(2),
          s.tipMethod ?? '',
          s.directTips?.toFixed(2) ?? '',
          s.poolContribution?.toFixed(2) ?? '',
          s.tipShareReceived?.toFixed(2) ?? '',
          s.tipOutPaid?.toFixed(2) ?? '',
          s.sales?.toFixed(2) ?? '',
          s.otherIncome?.toFixed(2) ?? '',
          // DEF-03/DEF-14: exported as a percentage of gross (snapshot fraction × 100).
          s.deductionRateSnapshot != null ? (s.deductionRateSnapshot * 100).toFixed(2) : '',
          expectedEarnings(s).toFixed(2),
          worked ? actualEarnings(s).toFixed(2) : '',
          worked ? variance(s).toFixed(2) : '',
          worked ? effectiveHourly(s).toFixed(2) : '',
          worked ? estimatedNet(s).toFixed(2) : '',
          s.expectedPayout?.toFixed(2) ?? '',
          s.actualReceived?.toFixed(2) ?? '',
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

  const onErase = () => {
    Alert.alert(tr('settings.eraseConfirmTitle'), tr('settings.eraseConfirmMessage'), [
      { text: tr('common.cancel'), style: 'cancel' },
      {
        text: tr('settings.eraseConfirmAction'),
        style: 'destructive',
        onPress: () => {
          eraseAll();
          loadShifts();
          loadEmployers();
          setRateText('0');
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
      />

      <View style={{ height: 12 }} />

      <PrimaryButton label={tr('settings.exportCsv')} onPress={() => void onExportCsv()} style={{ marginBottom: 12 }} />
      <GhostButton label={tr('settings.eraseData')} onPress={onErase} danger />
    </ScrollView>
  );
}
