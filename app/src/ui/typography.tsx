import React from 'react';
import {
  StyleSheet,
  Text as NativeText,
  type TextProps,
  type TextStyle,
} from 'react-native';

export const fonts = {
  body: 'IBMPlexMono_400Regular',
  bodyMedium: 'IBMPlexMono_500Medium',
  bodySemiBold: 'IBMPlexMono_600SemiBold',
  bodyBold: 'IBMPlexMono_700Bold',
  mono: 'IBMPlexMono_400Regular',
  monoMedium: 'IBMPlexMono_500Medium',
  monoSemiBold: 'IBMPlexMono_600SemiBold',
  monoBold: 'IBMPlexMono_700Bold',
  ui: 'Outfit_400Regular',
  uiMedium: 'Outfit_500Medium',
  uiSemiBold: 'Outfit_600SemiBold',
  uiBold: 'Outfit_700Bold',
  display: 'Fraunces_600SemiBold',
  displayBold: 'Fraunces_700Bold',
  total: 'Fraunces_700Bold',
  penNote: 'Caveat_600SemiBold',
  // Backwards-compatible aliases for existing callers.
  regular: 'IBMPlexMono_400Regular',
  medium: 'IBMPlexMono_500Medium',
  semiBold: 'IBMPlexMono_600SemiBold',
  bold: 'IBMPlexMono_700Bold',
} as const;

export type FontRole = 'body' | 'mono' | 'ui' | 'display' | 'total' | 'penNote';

const FontAvailabilityContext = React.createContext(true);

export function TypographyProvider({
  available,
  children,
}: {
  available: boolean;
  children: React.ReactNode;
}) {
  return (
    <FontAvailabilityContext.Provider value={available}>
      {children}
    </FontAvailabilityContext.Provider>
  );
}

export function useFontAvailability(): boolean {
  return React.useContext(FontAvailabilityContext);
}

function weightFor(style: TextProps['style']): TextStyle['fontWeight'] {
  return StyleSheet.flatten(style as TextStyle)?.fontWeight;
}

function isBold(weight: TextStyle['fontWeight']): boolean {
  return weight === 'bold' || weight === '700' || weight === '800' || weight === '900';
}

export function familyFor(role: FontRole, style: TextProps['style']): string {
  const weight = weightFor(style);

  if (role === 'display') return isBold(weight) ? fonts.displayBold : fonts.display;
  if (role === 'total') return fonts.total;
  if (role === 'penNote') return fonts.penNote;
  if (role === 'ui') {
    if (isBold(weight)) return fonts.uiBold;
    if (weight === '600') return fonts.uiSemiBold;
    if (weight === '500') return fonts.uiMedium;
    return fonts.ui;
  }

  if (isBold(weight)) {
    return fonts.bold;
  }
  if (weight === '600') return fonts.semiBold;
  if (weight === '500') return fonts.medium;
  return fonts.regular;
}

/** Text primitive with named receipt, display, handwritten, and UI roles. */
export function Text({
  fontRole = 'body',
  style,
  ...props
}: TextProps & { fontRole?: FontRole }) {
  const fontsAvailable = useFontAvailability();
  return (
    <NativeText
      {...props}
      style={[fontsAvailable ? { fontFamily: familyFor(fontRole, style) } : null, style]}
    />
  );
}
