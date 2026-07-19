import React, { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import {
  SUPPORTED_CURRENCIES,
  type SupportedCurrency,
} from '../domain/currency';
import { TOUCH_TARGET, useTokens } from './tokens';

export function CurrencyDropdown({
  label,
  hint,
  value,
  onChange,
}: {
  label: string;
  hint?: string;
  value: SupportedCurrency;
  onChange: (value: SupportedCurrency) => void;
}) {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const [expanded, setExpanded] = useState(false);

  return (
    <View style={{ marginBottom: 12 }}>
      <Text style={{ color: t.softText, fontSize: 12, fontWeight: '600', marginBottom: 4 }}>
        {label}
      </Text>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        accessibilityState={{ expanded }}
        onPress={() => setExpanded((current) => !current)}
        style={({ pressed }) => ({
          minHeight: TOUCH_TARGET,
          borderWidth: 1,
          borderColor: t.line,
          backgroundColor: t.bg,
          paddingHorizontal: 12,
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between',
          opacity: pressed ? 0.8 : 1,
        })}
      >
        <Text style={{ color: t.ink, fontSize: 15 }}>
          {tr(`currency.options.${value}`)}
        </Text>
        <Text style={{ color: t.cobalt, fontSize: 16 }}>{expanded ? '▴' : '▾'}</Text>
      </Pressable>
      {expanded ? (
        <View style={{ borderWidth: 1, borderTopWidth: 0, borderColor: t.line }}>
          {SUPPORTED_CURRENCIES.map((currency, index) => {
            const selected = currency === value;
            return (
              <Pressable
                key={currency}
                accessibilityRole="button"
                accessibilityState={{ selected }}
                onPress={() => {
                  onChange(currency);
                  setExpanded(false);
                }}
                style={({ pressed }) => ({
                  minHeight: TOUCH_TARGET,
                  borderTopWidth: index === 0 ? 0 : 1,
                  borderTopColor: t.line,
                  backgroundColor: selected ? t.cobaltSoft : t.bg,
                  paddingHorizontal: 12,
                  justifyContent: 'center',
                  opacity: pressed ? 0.8 : 1,
                })}
              >
                <Text style={{ color: selected ? t.cobalt : t.ink, fontSize: 15, fontWeight: selected ? '700' : '400' }}>
                  {tr(`currency.options.${currency}`)}
                </Text>
              </Pressable>
            );
          })}
        </View>
      ) : null}
      {hint ? <Text style={{ color: t.softText, fontSize: 11, marginTop: 3 }}>{hint}</Text> : null}
    </View>
  );
}
