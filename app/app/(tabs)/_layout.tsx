import React from 'react';
import { Tabs } from 'expo-router';
import { Platform, View, type ColorValue } from 'react-native';
import { useTranslation } from 'react-i18next';

import { useTokens } from '../../src/ui/tokens';
import { fonts, Text, useFontAvailability } from '../../src/ui/typography';

export const unstable_settings = {
  initialRouteName: 'index',
};

function TabIcon({ glyph, color, focused }: { glyph: string; color: ColorValue; focused: boolean }) {
  const { t } = useTokens();
  return (
    <View
      style={{
        width: 54,
        height: 28,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: focused ? t.ink : 'transparent',
      }}
    >
      <Text style={{ fontSize: 17, color: focused ? t.paper : color }}>{glyph}</Text>
    </View>
  );
}

export default function TabsLayout() {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const fontsAvailable = useFontAvailability();

  return (
    <Tabs
      screenOptions={{
        headerStyle: { backgroundColor: t.bg },
        headerTintColor: t.ink,
        headerShadowVisible: false,
        headerTitleStyle: {
          fontFamily: fontsAvailable ? fonts.uiSemiBold : undefined,
          fontWeight: fontsAvailable && Platform.OS === 'android' ? '600' : undefined,
          color: t.ink,
        },
        tabBarStyle: {
          backgroundColor: t.paper,
          borderTopColor: t.ink,
          borderTopWidth: 1.5,
          height: 66,
          paddingBottom: 8,
          paddingTop: 6,
        },
        tabBarActiveTintColor: t.ink,
        tabBarInactiveTintColor: t.dim,
        tabBarLabelStyle: {
          fontSize: 10,
          fontFamily: fontsAvailable ? fonts.uiSemiBold : undefined,
          fontWeight: fontsAvailable && Platform.OS === 'android' ? '600' : undefined,
          letterSpacing: 0.4,
        },
        sceneStyle: { backgroundColor: t.bg },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: tr('tabs.home'),
          headerShown: false,
          tabBarIcon: ({ color, focused }) => <TabIcon glyph="⌂" color={color} focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="schedule"
        options={{
          title: tr('tabs.schedule'),
          tabBarIcon: ({ color, focused }) => <TabIcon glyph="▦" color={color} focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="stats"
        options={{
          title: tr('tabs.stats'),
          tabBarIcon: ({ color, focused }) => <TabIcon glyph="▥" color={color} focused={focused} />,
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
