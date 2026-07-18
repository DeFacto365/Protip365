import React from 'react';
import { Tabs } from 'expo-router';
import { Text, type ColorValue } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useTokens } from '../../src/ui/tokens';

function TabIcon({ glyph, color }: { glyph: string; color: ColorValue }) {
  return <Text style={{ fontSize: 20, color }}>{glyph}</Text>;
}

export default function TabsLayout() {
  const { t } = useTokens();
  const { t: tr } = useTranslation();

  return (
    <Tabs
      screenOptions={{
        headerStyle: { backgroundColor: t.bg },
        headerTintColor: t.ink,
        headerShadowVisible: false,
        tabBarStyle: {
          backgroundColor: t.surface,
          borderTopColor: t.line,
          height: 64,
          paddingBottom: 8,
          paddingTop: 6,
        },
        tabBarActiveTintColor: t.cobaltLink,
        tabBarInactiveTintColor: t.softText,
        tabBarLabelStyle: { fontSize: 11, fontWeight: '600' },
        sceneStyle: { backgroundColor: t.bg },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: tr('tabs.schedule'),
          tabBarIcon: ({ color }) => <TabIcon glyph="▦" color={color} />,
        }}
      />
      <Tabs.Screen
        name="stats"
        options={{
          title: tr('tabs.stats'),
          tabBarIcon: ({ color }) => <TabIcon glyph="◫" color={color} />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: tr('tabs.settings'),
          tabBarIcon: ({ color }) => <TabIcon glyph="⚙" color={color} />,
        }}
      />
    </Tabs>
  );
}
