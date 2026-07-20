import React from 'react';
import {
  StyleSheet,
  Text as NativeText,
  type TextProps,
  type TextStyle,
} from 'react-native';

export const fonts = {
  regular: 'IBMPlexMono_400Regular',
  medium: 'IBMPlexMono_500Medium',
  semiBold: 'IBMPlexMono_600SemiBold',
  bold: 'IBMPlexMono_700Bold',
} as const;

function familyFor(style: TextProps['style']): string {
  const weight = StyleSheet.flatten(style as TextStyle)?.fontWeight;
  if (weight === 'bold' || weight === '700' || weight === '800' || weight === '900') {
    return fonts.bold;
  }
  if (weight === '600') return fonts.semiBold;
  if (weight === '500') return fonts.medium;
  return fonts.regular;
}

/** App-wide text primitive that maps React Native weights to loaded Plex faces. */
export function Text({ style, ...props }: TextProps) {
  return <NativeText {...props} style={[{ fontFamily: familyFor(style) }, style]} />;
}
