import React, { useMemo, useState } from 'react';
import { Platform, Pressable, Text, View } from 'react-native';
import DateTimePicker, {
  type DateTimePickerEvent,
} from '@react-native-community/datetimepicker';
import { getCalendars } from 'expo-localization';

import i18n from '../i18n';
import { isValidIsoDate, toIso } from '../domain/dates';
import { radius, TOUCH_TARGET, useTokens } from './tokens';

interface PickerFieldProps {
  label: string;
  value: Date;
  mode: 'date' | 'time';
  onChange: (value: Date) => void;
  hint?: string;
  error?: string | null;
}

function PickerField({ label, value, mode, onChange, hint, error }: PickerFieldProps) {
  const { t, isDark } = useTokens();
  const [show, setShow] = useState(false);
  const locale = i18n.resolvedLanguage || i18n.language || 'en';
  const uses24HourClock = useMemo(() => {
    try {
      return getCalendars()[0]?.uses24hourClock ?? undefined;
    } catch {
      return undefined;
    }
  }, []);
  const displayValue = useMemo(() => {
    try {
      return new Intl.DateTimeFormat(locale,
        mode === 'date'
          ? { year: 'numeric', month: 'short', day: 'numeric' }
          : { hour: '2-digit', minute: '2-digit' }
      ).format(value);
    } catch {
      return mode === 'date' ? toIso(value) : value.toTimeString().slice(0, 5);
    }
  }, [locale, mode, value]);

  const onPickerChange = (event: DateTimePickerEvent, selected?: Date) => {
    if (event.type === 'set' && selected) onChange(selected);
    setShow(false);
  };

  return (
    <View style={{ marginBottom: 12 }}>
      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 4 }}>
        {label}
      </Text>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        accessibilityValue={{ text: displayValue }}
        onPress={() => setShow(true)}
        style={({ pressed }) => ({
          minHeight: TOUCH_TARGET,
          borderWidth: 1,
          borderRadius: radius.field,
          borderColor: error ? t.dangerBg : t.line,
          backgroundColor: t.bg,
          paddingHorizontal: 12,
          justifyContent: 'center',
          opacity: pressed ? 0.75 : 1,
        })}
      >
        <Text style={{ color: t.ink, fontSize: 15 }}>{displayValue}</Text>
      </Pressable>
      {hint && !error ? (
        <Text style={{ color: t.softText, fontSize: 11, marginTop: 3 }}>{hint}</Text>
      ) : null}
      {error ? (
        <Text style={{ color: '#FFFFFF', backgroundColor: t.dangerBg, padding: 4, fontSize: 11, marginTop: 3 }}>
          {error}
        </Text>
      ) : null}

      {show && Platform.OS === 'android' ? (
        <DateTimePicker
          value={value}
          mode={mode}
          display="default"
          design="material"
          is24Hour={mode === 'time' ? uses24HourClock : undefined}
          onChange={onPickerChange}
        />
      ) : null}
      {show && Platform.OS === 'ios' ? (
        <DateTimePicker
          value={value}
          mode={mode}
          display="spinner"
          themeVariant={isDark ? 'dark' : 'light'}
          is24Hour={mode === 'time' ? uses24HourClock : undefined}
          onChange={onPickerChange}
        />
      ) : null}
    </View>
  );
}

function dateFromIso(iso: string): Date {
  if (!isValidIsoDate(iso)) return new Date();
  const [year, month, day] = iso.split('-').map(Number);
  return new Date(year, month - 1, day, 12);
}

function dateFromMinutes(minutes: number): Date {
  const normalized = ((minutes % 1440) + 1440) % 1440;
  return new Date(2000, 0, 1, Math.floor(normalized / 60), normalized % 60);
}

export function DatePickerField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (iso: string) => void;
}) {
  return (
    <PickerField
      label={label}
      value={dateFromIso(value)}
      mode="date"
      onChange={(selected) => onChange(toIso(selected))}
    />
  );
}

export function TimePickerField({
  label,
  value,
  onChange,
  hint,
}: {
  label: string;
  value: number;
  onChange: (minutes: number) => void;
  hint?: string;
}) {
  return (
    <PickerField
      label={label}
      value={dateFromMinutes(value)}
      mode="time"
      hint={hint}
      onChange={(selected) => onChange(selected.getHours() * 60 + selected.getMinutes())}
    />
  );
}
