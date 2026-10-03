# ProTip365 Shared Mobile

Shared Expo React Native + TypeScript app for the ProTip365 rebuild.

## Purpose

This app is the new iOS/Android codebase. The existing SwiftUI and Kotlin apps remain references for behavior, calculations, and migration decisions.

## Commands

```bash
npm install
cp .env.example .env.local
npm run typecheck
npm run ios
npm run android
```

## Environment

Use `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY`.
Do not commit real `.env` files. The mobile client must only use a publishable key.

## Structure

- `App.tsx`: shared app provider entrypoint.
- `src/navigation/`: typed root, tab, and stack navigation.
- `src/screens/`: placeholder v1 screen shells wired into navigation.
- `src/components/`: reusable accessible shell components.
- `src/config/`: environment validation.
- `src/lib/`: Supabase client and secure session storage.
- `src/auth/`: auth session provider.
- `src/theme.ts`: typography, spacing, color, card, form, and navigation tokens.
- `src/localization.ts`: English, French, and Spanish strings.
- `index.ts`: Expo entrypoint.
- `app.json`: Expo app configuration.
- `assets/`: generated Expo starter assets. Replace before store submission.

## Current Scope

The app shell now covers navigation, theming, localization, Supabase client setup, secure session storage, and missing-config handling.
