import React from 'react';
import { Tabs } from 'expo-router';
import { Text, View, type ColorValue } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useTokens } from '../../src/ui/tokens';

function TabIcon({ glyph, color, focused }: { glyph: string; color: ColorValue; focused: boolean }) {
  const { t } = useTokens();
  return (
    <View
      style={{
        width: 64,
        height: 32,
        borderRadius: 16,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: focused ? t.cobaltSoft : 'transparent',
      }}
    >
      <Text style={{ fontSize: 20, color }}>{glyph}</Text>
    </View>
  );
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
          tabBarIcon: ({ color, focused }) => <TabIcon glyph="▦" color={color} focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="stats"
        options={{
          title: tr('tabs.stats'),
          tabBarIcon: ({ color, focused }) => <TabIcon glyph="◫" color={color} focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: tr('tabs.settings'),
          tabBarIcon: ({ color, focused }) => <TabIcon glyph="⚙" color={color} focused={focused} />,
        }}
      />
    </Tabs>
  );
}
