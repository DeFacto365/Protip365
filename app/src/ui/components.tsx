import React from 'react';
import {
  Pressable,
  StyleSheet,
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
import { fonts, Text } from './typography';

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
    .map((word) => word[0]!.toUpperCase())
    .join('');
}

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
        styles.card,
        {
          backgroundColor: t.card,
          borderColor: t.ink,
          shadowColor: t.ink,
        },
        style,
      ]}
    >
      {children}
    </View>
  );
}

export function ReceiptCard({
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
        styles.receipt,
        {
          backgroundColor: t.paper,
          borderColor: t.rule,
          shadowColor: t.ink,
        },
        style,
      ]}
    >
      {children}
    </View>
  );
}

export function ReceiptRule() {
  const { t } = useTokens();
  return <View style={[styles.receiptRule, { borderColor: t.rule }]} />;
}

export function LineItem({
  label,
  value,
  tone = 'computed',
  strong,
}: {
  label: string;
  value: string;
  tone?: 'computed' | 'dim' | 'pen' | 'confirmed' | 'negative';
  strong?: boolean;
}) {
  const { t } = useTokens();
  const color =
    tone === 'pen'
      ? t.pen
      : tone === 'confirmed'
        ? t.green
        : tone === 'negative'
          ? t.red
          : tone === 'dim'
            ? t.dim
            : t.ink;
  return (
    <View style={styles.lineItem}>
      <Text fontRole="mono" style={[styles.lineLabel, { color: t.dim }, strong && styles.lineStrong]}>
        {label}
      </Text>
      <Text fontRole={strong ? 'total' : 'mono'} style={[styles.lineValue, { color }, strong && styles.lineTotal]}>{value}</Text>
    </View>
  );
}

export function Stamp({
  label,
  tone = 'confirmed',
  rotation = 7,
  style,
}: {
  label: string;
  tone?: 'confirmed' | 'negative' | 'pen' | 'ink';
  rotation?: number;
  style?: StyleProp<ViewStyle>;
}) {
  const { t } = useTokens();
  const color =
    tone === 'negative' ? t.red : tone === 'pen' ? t.pen : tone === 'ink' ? t.ink : t.green;
  return (
    <View
      style={[
        styles.stamp,
        { borderColor: color, transform: [{ rotate: `${rotation}deg` }] },
        style,
      ]}
    >
      <Text style={[styles.stampText, { color }]}>{label.toUpperCase()}</Text>
    </View>
  );
}

export function PrimaryButton({
  label,
  onPress,
  disabled,
  danger,
  tone = 'ink',
  style,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  danger?: boolean;
  tone?: 'ink' | 'pen';
  style?: StyleProp<ViewStyle>;
}) {
  const { t } = useTokens();
  const backgroundColor = danger ? t.red : tone === 'ink' ? t.ink : t.pen;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.button,
        styles.hardShadow,
        {
          backgroundColor,
          shadowColor: backgroundColor,
          opacity: disabled ? 0.45 : pressed ? 0.82 : 1,
        },
        style,
      ]}
    >
      <Text fontRole="ui" style={[styles.buttonText, { color: danger ? t.paper : t.bg }]}>
        {label.toUpperCase()}
      </Text>
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
  const { t } = useTokens();
  const color = danger ? t.red : t.ink;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        { backgroundColor: 'transparent', borderWidth: 1.5, borderColor: color, opacity: pressed ? 0.7 : 1 },
        style,
      ]}
    >
      <Text fontRole="ui" style={[styles.buttonText, { color }]}>{label.toUpperCase()}</Text>
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
  const accent = color ?? t.ink;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ selected: !!selected }}
      onPress={onPress}
      style={({ pressed }) => [
        styles.chip,
        {
          backgroundColor: selected ? accent : t.paper,
          borderColor: selected ? accent : t.ink,
          opacity: pressed ? 0.8 : 1,
        },
      ]}
    >
      <Text
        fontRole="ui"
        style={{
          color: selected ? t.paper : t.ink,
          fontWeight: '700',
          fontSize: 11,
          letterSpacing: 0.7,
        }}
      >
        {label.toUpperCase()}
      </Text>
    </Pressable>
  );
}

export function statusChipColors(status: ShiftStatus, t: Tokens): { bg: string; fg: string } {
  switch (status) {
    case 'worked':
      return { bg: t.ink, fg: t.paper };
    case 'planned':
      return { bg: t.paper, fg: t.pen };
    case 'missed':
    case 'cancelled':
      return { bg: t.paper, fg: t.red };
  }
}

export function StatusChip({ status }: { status: ShiftStatus }) {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const { bg, fg } = statusChipColors(status, t);
  const label = tr(`status.${status}`);
  return (
    <View
      style={[styles.statusChip, { backgroundColor: bg, borderColor: fg }]}
      accessibilityLabel={label}
    >
      <Text fontRole="ui" style={{ color: fg, fontSize: 10, fontWeight: '700', letterSpacing: 0.6 }}>
        {label}
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
      <Text fontRole="ui" style={{ color: t.dim, fontSize: 10, fontWeight: '700', letterSpacing: 1, marginBottom: 4 }}>
        {label.toUpperCase()}
      </Text>
      <TextInput
        accessibilityLabel={label}
        placeholderTextColor={t.dim}
        {...inputProps}
        style={[
          styles.input,
          {
            backgroundColor: 'transparent',
            borderColor: error ? t.red : t.ink,
            color: t.pen,
          },
        ]}
      />
      {hint && !error ? (
        <Text fontRole="ui" style={{ color: t.dim, fontSize: 11, marginTop: 3 }}>{hint}</Text>
      ) : null}
      {error ? (
        <Text fontRole="ui" style={{ color: t.paper, backgroundColor: t.red, padding: 4, fontSize: 11, marginTop: 3 }}>
          {error}
        </Text>
      ) : null}
    </View>
  );
}

export function Avatar({ name, color }: { name: string; color: string }) {
  const { t } = useTokens();
  return (
    <View style={[styles.avatar, { backgroundColor: t.paper, borderColor: t.ink }]}>
      <Text style={{ color, fontWeight: '700', fontSize: 12 }}>{initials(name)}</Text>
    </View>
  );
}

export function SegmentedTabs<T extends string>({
  items,
  selected,
  onSelect,
}: {
  items: readonly { key: T; label: string }[];
  selected: T;
  onSelect: (value: T) => void;
}) {
  const { t } = useTokens();
  return (
    <View style={[styles.segmented, { borderColor: t.ink }]}>
      {items.map((item, index) => {
        const active = item.key === selected;
        return (
          <Pressable
            key={item.key}
            accessibilityRole="tab"
            accessibilityLabel={item.label}
            accessibilityState={{ selected: active }}
            onPress={() => onSelect(item.key)}
            style={({ pressed }) => [
              styles.segment,
              index > 0 && { borderLeftColor: t.ink, borderLeftWidth: 1.5 },
              { backgroundColor: active ? t.ink : t.paper, opacity: pressed ? 0.78 : 1 },
            ]}
          >
            <Text
              fontRole="ui"
              style={{
                color: active ? t.paper : t.dim,
                fontSize: 10,
                fontWeight: '700',
                letterSpacing: 1,
              }}
            >
              {item.label.toUpperCase()}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1.5,
    borderRadius: radius.card,
    shadowOffset: { width: 3, height: 3 },
    shadowOpacity: 0.22,
    shadowRadius: 0,
    elevation: 2,
  },
  hardShadow: {
    shadowOffset: { width: 3, height: 3 },
    shadowOpacity: 0.32,
    shadowRadius: 0,
    elevation: 3,
  },
  button: {
    minHeight: TOUCH_TARGET,
    borderRadius: radius.button,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  buttonText: {
    fontWeight: '700',
    fontSize: 13,
    letterSpacing: 0.8,
  },
  chip: {
    minHeight: TOUCH_TARGET,
    borderRadius: radius.chip,
    borderWidth: 1.5,
    paddingHorizontal: 12,
    paddingVertical: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statusChip: {
    borderRadius: radius.chip,
    borderWidth: 1.5,
    paddingHorizontal: 8,
    paddingVertical: 3,
    alignSelf: 'flex-start',
  },
  input: {
    minHeight: TOUCH_TARGET,
    borderWidth: 0,
    borderBottomWidth: 1.5,
    borderRadius: radius.field,
    paddingHorizontal: 0,
    fontSize: 15,
    fontFamily: fonts.regular,
  },
  avatar: {
    width: 34,
    height: 34,
    borderRadius: 0,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  receipt: {
    borderTopWidth: 1.5,
    borderBottomWidth: 1.5,
    borderLeftWidth: 0,
    borderRightWidth: 0,
    borderStyle: 'dashed',
    padding: 16,
    shadowOffset: { width: 4, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 0,
    elevation: 3,
  },
  receiptRule: {
    borderTopWidth: 1.5,
    borderStyle: 'dashed',
    marginVertical: 10,
  },
  lineItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'baseline',
    gap: 12,
    paddingVertical: 3,
  },
  lineLabel: {
    flex: 1,
    fontSize: 11,
  },
  lineValue: {
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'right',
  },
  lineStrong: {
    fontWeight: '700',
    letterSpacing: 0.7,
  },
  lineTotal: {
    fontSize: 22,
    fontWeight: '700',
  },
  stamp: {
    alignSelf: 'flex-start',
    borderWidth: 2.5,
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  stampText: {
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 1.4,
  },
  segmented: {
    flexDirection: 'row',
    borderWidth: 1.5,
  },
  segment: {
    flex: 1,
    minHeight: TOUCH_TARGET,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 8,
  },
});
