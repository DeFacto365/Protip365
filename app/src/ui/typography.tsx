import React from 'react';
import {
  Platform,
  StyleSheet,
  Text as NativeText,
  type TextProps,
  type TextStyle,
} from 'react-native';

const platformFontFamilies = Platform.select({
  android: {
    body: 'IBM Plex Mono',
    bodyMedium: 'IBM Plex Mono',
    bodySemiBold: 'IBM Plex Mono',
    bodyBold: 'IBM Plex Mono',
    ui: 'Outfit',
    uiMedium: 'Outfit',
    uiSemiBold: 'Outfit',
    uiBold: 'Outfit',
    display: 'Fraunces',
    displayBold: 'Fraunces',
    total: 'Fraunces',
    penNote: 'Caveat',
  },
  ios: {
    body: 'IBMPlexMono-Regular',
    bodyMedium: 'IBMPlexMono-Medium',
    bodySemiBold: 'IBMPlexMono-SemiBold',
    bodyBold: 'IBMPlexMono-Bold',
    ui: 'Outfit-Regular',
    uiMedium: 'Outfit-Medium',
    uiSemiBold: 'Outfit-SemiBold',
    uiBold: 'Outfit-Bold',
    display: 'Fraunces-SemiBold',
    displayBold: 'Fraunces-Bold',
    total: 'Fraunces-Bold',
    penNote: 'Caveat-SemiBold',
  },
  default: {
    body: 'IBMPlexMono_400Regular',
    bodyMedium: 'IBMPlexMono_500Medium',
    bodySemiBold: 'IBMPlexMono_600SemiBold',
    bodyBold: 'IBMPlexMono_700Bold',
    ui: 'Outfit_400Regular',
    uiMedium: 'Outfit_500Medium',
    uiSemiBold: 'Outfit_600SemiBold',
    uiBold: 'Outfit_700Bold',
    display: 'Fraunces_600SemiBold',
    displayBold: 'Fraunces_700Bold',
    total: 'Fraunces_700Bold',
    penNote: 'Caveat_600SemiBold',
  },
});

export const fonts = {
  ...platformFontFamilies,
  mono: platformFontFamilies.body,
  monoMedium: platformFontFamilies.bodyMedium,
  monoSemiBold: platformFontFamilies.bodySemiBold,
  monoBold: platformFontFamilies.bodyBold,
  // Backwards-compatible aliases for existing callers.
  regular: platformFontFamilies.body,
  medium: platformFontFamilies.bodyMedium,
  semiBold: platformFontFamilies.bodySemiBold,
  bold: platformFontFamilies.bodyBold,
} as const;

export const requiredNativeFontFamilies = [...new Set(Object.values(fonts))];

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

function defaultWeightFor(role: FontRole): TextStyle['fontWeight'] {
  if (role === 'display' || role === 'penNote') return '600';
  if (role === 'total') return '700';
  return '400';
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
  const fontWeight = weightFor(style) ?? defaultWeightFor(fontRole);
  return (
    <NativeText
      {...props}
      style={[
        fontsAvailable
          ? {
              fontFamily: familyFor(fontRole, style),
              fontWeight: Platform.OS === 'android' ? fontWeight : undefined,
            }
          : null,
        style,
      ]}
    />
  );
}
