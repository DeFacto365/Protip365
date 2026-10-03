# ProTip365 Android redesign

Active source: `app/`. Previous app, documents, prototypes and builds are preserved in `Archive/2026-10-02-before-new-app/`. Git history is retained.

The redesigned app uses the existing Android application ID (`com.defacto365.protip365`) and EAS project. Landing-page colors, Fraunces / Work Sans typography and the p. mark are shared across the interface.

From `app/`, run `npm ci`, then `npm run web` for the browser preview or `npm run android` with a connected Android device. Run `npm run typecheck` and `npm test -- --runInBand` for checks.

Read `Docs/ANDROID_IMPLEMENTATION.md` for implementation details, validation and the remaining release gates. Do not publish the local test APK as a store update.
