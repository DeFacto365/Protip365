import React from 'react';
import {
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
  type StyleProp,
  type TextInputProps,
  type ViewStyle,
} from 'react-native';
import { radius, TOUCH_TARGET, useTokens, type Tokens } from './tokens';
import type { ShiftStatus } from '../domain/types';
import { useTranslation } from 'react-i18next';

import i18n from '../i18n';
import { getActiveCurrency } from '../domain/currency';

const formatterCache = new Map<string, Intl.NumberFormat>();

function currencyFormatter(): Intl.NumberFormat {
  const locale = i18n.language || 'en';
  const currency = getActiveCurrency();
  const cacheKey = `${locale}|${currency}`;
  let cached = formatterCache.get(cacheKey);
  if (!cached) {
    try {
      cached = new Intl.NumberFormat(locale, {
        style: 'currency',
        currency,
        currencyDisplay: 'narrowSymbol',
      });
    } catch {
      // Older Intl implementations may reject narrowSymbol.
      cached = new Intl.NumberFormat(locale, { style: 'currency', currency });
    }
    formatterCache.set(cacheKey, cached);
  }
  return cached;
}

export function money(cents: number): string {
  return currencyFormatter().format(cents / 100);
}

export function signedMoney(amount: number): string {
  return amount >= 0 ? `+${money(amount)}` : money(amount);
}

export function initials(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0]!.toUpperCase())
    .join('');
}

// ---------------------------------------------------------------------------

export function Card({
  children,
  style,
}: {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
}) {
  const { t } = useTokens();
  return (
    <View
      style={[
        { backgroundColor: t.card, borderColor: t.line, borderWidth: 1, borderRadius: radius.card },
        style,
      ]}
    >
      {children}
    </View>
  );
}

export function PrimaryButton({
  label,
  onPress,
  disabled,
  danger,
  style,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  danger?: boolean;
  style?: StyleProp<ViewStyle>;
}) {
  const { t } = useTokens();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.button,
        {
          backgroundColor: danger ? t.dangerBg : t.cobalt,
          opacity: disabled ? 0.45 : pressed ? 0.85 : 1,
        },
        style,
      ]}
    >
      <Text style={[styles.buttonText, { color: '#FFFFFF' }]}>{label}</Text>
    </Pressable>
  );
}

export function GhostButton({
  label,
  onPress,
  danger,
  style,
}: {
  label: string;
  onPress: () => void;
  danger?: boolean;
  style?: StyleProp<ViewStyle>;
}) {
  const { t, isDark } = useTokens();
  const color = danger ? t.danger : t.cobaltLink;
  const borderColor = danger ? t.dangerBg : isDark ? t.cobalt : t.cobaltLink;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        { backgroundColor: 'transparent', borderWidth: 1.5, borderColor, opacity: pressed ? 0.7 : 1 },
        style,
      ]}
    >
      <Text style={[styles.buttonText, { color }]}>{label}</Text>
    </Pressable>
  );
}

export function Chip({
  label,
  selected,
  onPress,
  color,
}: {
  label: string;
  selected?: boolean;
  onPress?: () => void;
  color?: string;
}) {
  const { t } = useTokens();
  const accent = color ?? t.cobalt;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ selected: !!selected }}
      onPress={onPress}
      style={({ pressed }) => [
        styles.chip,
        {
          backgroundColor: selected ? accent : t.card,
          borderColor: selected ? accent : t.line,
          opacity: pressed ? 0.8 : 1,
        },
      ]}
    >
      <Text style={{ color: selected ? '#FFFFFF' : t.ink, fontWeight: '600', fontSize: 13 }}>
        {label}
      </Text>
    </Pressable>
  );
}

export function statusChipColors(status: ShiftStatus, t: Tokens): { bg: string; fg: string } {
  switch (status) {
    case 'worked':
      return { bg: t.greenSoft, fg: t.green };
    case 'planned':
      return { bg: t.cobaltSoft, fg: t.cobaltLink };
    case 'missed':
    case 'cancelled':
      return { bg: t.amberSoft, fg: t.amber };
  }
}

export function StatusChip({ status }: { status: ShiftStatus }) {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const { bg, fg } = statusChipColors(status, t);
  const label = tr(`status.${status}`);
  return (
    <View style={[styles.statusChip, { backgroundColor: bg }]} accessibilityLabel={label}>
      <Text style={{ color: fg, fontSize: 10, fontWeight: '700', letterSpacing: 0.6 }}>
        {status === 'worked' ? `✓ ${label}` : label}
      </Text>
    </View>
  );
}

export function Field({
  label,
  hint,
  error,
  ...inputProps
}: TextInputProps & { label: string; hint?: string; error?: string | null }) {
  const { t } = useTokens();
  return (
    <View style={{ marginBottom: 12 }}>
      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 4 }}>
        {label}
      </Text>
      <TextInput
        accessibilityLabel={label}
        placeholderTextColor={t.softText}
        {...inputProps}
        style={[
          styles.input,
          {
            backgroundColor: t.bg,
            borderColor: error ? t.dangerBg : t.line,
            color: t.ink,
          },
        ]}
      />
      {hint && !error ? (
        <Text style={{ color: t.softText, fontSize: 11, marginTop: 3 }}>{hint}</Text>
      ) : null}
      {error ? (
        <Text style={{ color: '#FFFFFF', backgroundColor: t.dangerBg, padding: 4, fontSize: 11, marginTop: 3 }}>
          {error}
        </Text>
      ) : null}
    </View>
  );
}

export function Avatar({ name, color }: { name: string; color: string }) {
  const { isDark } = useTokens();
  return (
    <View style={[styles.avatar, { backgroundColor: isDark ? color : `${color}33` }]}>
      <Text style={{ color: isDark ? '#FFFFFF' : color, fontWeight: '700', fontSize: 12 }}>
        {initials(name)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: TOUCH_TARGET,
    borderRadius: radius.button,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  buttonText: {
    fontWeight: '600',
    fontSize: 15,
  },
  chip: {
    // DEF-15: 48dp minimum Android touch target.
    minHeight: TOUCH_TARGET,
    borderRadius: radius.chip,
    borderWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statusChip: {
    borderRadius: radius.chip,
    paddingHorizontal: 8,
    paddingVertical: 3,
    alignSelf: 'flex-start',
  },
  input: {
    minHeight: TOUCH_TARGET,
    borderWidth: 1,
    borderRadius: radius.field,
    paddingHorizontal: 12,
    fontSize: 15,
  },
  avatar: {
    width: 32,
    height: 32,
    borderRadius: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
