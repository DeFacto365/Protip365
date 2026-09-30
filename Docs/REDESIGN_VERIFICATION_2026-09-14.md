# Pre-launch redesign implementation and verification

Owner request: implement `PROTIP_REDESIGN_GAME_PLAN_2026-09-14.md` in one shared app; no store publishing. Decision reference: [ADR-002](ADR-002-prelaunch-redesign.md).

## Implemented

- Home prioritizes unfinished shifts, lists further close-outs, opens scheduled details for future shifts, shows concise earnings and employer/currency-specific pending payments.
- Shared light/dark surfaces, teal controls, rounded cards, sans-serif body text, tabular amounts, larger field labels and safe-area-aware tab bar. Receipt styling remains on the result screen.
- Schedule preserves the selected agenda period (the existing week view is a dated agenda). Day, month, templates, recurrence, overlap override, copy week and save-and-add-another remain available.
- Quick-add hides forecasts/notes behind a disclosure. Employer settings provide usual tip arrangement. Completion uses method-sensitive fields, preserves entered values when switching method, groups optional rate/sales/deductions, and records receipt timing separately.
- Completion drafts persist locally against the source revision. Work, initial receipt, expected amount, allocations and draft deletion share one SQLite transaction. Retry/error handling retains inputs; successful completion opens the shift result.
- Money replaces the Stats tab. Insights remain reachable from Money. Expected items retain employer, optional shift, kind, currency, amount or unknown, optional due date, and review status.
- Dated receipts support multiple allocations, partial settlement, unknown expectations, excess/unallocated amounts, later matching, duplicate-save protection and reversal history. Corrected-to-planned work flags linked expectations for review. Linked financial history prevents destructive shift deletion and cross-employer reassignment.
- New databases no longer have cumulative shift payment columns. No customer opening balances are fabricated; existing developer databases are not erased. Backup format 4 includes the ledger and validates allocations before restore.
- New UI copy has EN, fr-CA and Spanish keys. No remote analytics, cloud sync, price changes or publishing added.

## Automated evidence

Baseline: TypeScript passed; 29 Jest suites / 214 tests passed.

Final automated run after Windows tooling setup: all 34 suites / 238 tests passed together. TypeScript passed with the installed Node runtime. Both explicit platform exports passed during the earlier implementation checks.

The initial verification commands used the bundled Node runtime. Node and npm were subsequently installed system-wide during Windows tooling setup:

```powershell
cd C:\Github\Protip365\app
node node_modules/typescript/bin/tsc --noEmit
node node_modules/jest/bin/jest.js --runInBand
node node_modules/expo/bin/cli export --platform ios --platform android --output-dir dist-redesign
```

The platform export compiles Hermes bundles, not signed installable applications. An initial all-platform export also attempted unsupported web and failed on absent `react-native-web`; explicit iOS/Android exports succeeded. No web dependency was added.

New deterministic tests exercise the $200/$40/$60/$100 + $80 + $150 worked example; pooled and mixed income; currency/employer mismatch; partials; unknowns; excess; invalid cents/dates; reversal; late allocation; duplicate retries; interrupted transactions; stale drafts; and an encrypted full-backup round trip with real in-memory SQLite. React payment and completion screen harnesses verify entered allocations, decimal comma, duplicate taps, retained inputs after save failure and denied writes, atomic close-out arguments, restored receipt-timing drafts and rejection of malformed tips. Host controls are mocked: this does not establish native accessibility or keyboard behaviour. The installed React renderer emits its upstream deprecation notice.

## Prototype review

[Clickable prototype](design/redesign/prototype.html) covers the nine requested flows and provides platform, light/dark, large-text, populated, empty, incomplete, error, loading and long-content switches. Values follow the tips-only acceptance example. Browser review covered Home and the payment flow, including settlement and Android dark/large text. It is a design simulation, not a screenshot of the running native app. Remaining usability claims require observation with workers.

## Native release gates still open

- `expo run:ios --no-install` explicitly reports that local iOS builds require macOS. This host is Windows.
- Windows tooling setup installed Node 24.19.0 (ARM64), npm 11.17.0, Microsoft OpenJDK 17.0.20.1 (x64), EAS CLI 24.4.0, Android command-line tools 22.0, platform-tools 37.0.1, Android SDK platform 36, build-tools 35.0.0/36.0.0, NDK 27.0.12077973/27.1.12297006 and CMake 3.22.1. User PATH, JAVA_HOME and ANDROID_HOME are configured; open a fresh terminal to inherit them.
- This laptop has a Snapdragon X ARM64 CPU. Google explicitly excludes Windows ARM from supported Android Studio configurations, so Android Studio and the emulator were not installed. Command-line Java and adb execute under Windows compatibility support; `adb devices -l` found no connected device. [Google requirements](https://developer.android.com/studio/install).
- Browser-based Expo sign-in succeeded. EAS identity and access to the existing `@defacto365/protip365` project were verified. The existing preview profile is blocked by its missing local upload keystore. A separate `android-debug` profile builds a test-key APK without changing release credentials.
- A local ARM64-target debug build progressed through Java/Kotlin and native SQLCipher compilation. It was intentionally stopped before APK completion after the cloud build was accepted because of laptop memory pressure. This is not a successful local build claim.
- Root `.easignore` now excludes historical apps, generated outputs and credentials. Local archive inspection confirmed `app/package.json` present and `app/credentials.json` absent. A malformed initial archive job was canceled. The corrected archive was submitted as [Android debug build 5449b39f](https://expo.dev/accounts/defacto365/projects/protip365/builds/5449b39f-c1c1-43ef-a875-a8001049e271), which FINISHED successfully. The 96,542,729-byte APK was downloaded to `artifacts/protip365-redesign-debug.apk`. This is a test-key ARM64 development APK that needs Metro; it is not a release-signed or on-device-tested build. No store submission occurred.
- Expo compatibility checking reports newer SDK 57 patch versions available; those upgrades were not mixed into the tooling installation. Prebuild also warns that automatic Android UI style requires `expo-system-ui`; native dark-mode behavior remains an open validation item.
- Downloaded APK checks: Android `apksigner verify --verbose` passed (v2 signature); `aapt dump badging` confirmed `com.defacto365.protip365`, version 2.0.0/code 12, minimum API 24, target API 36, ARM64. SHA-256: `34FCA3CC0C8003F6B17B0BFDF446DCC3C92F9D14CDAF43F2AE4139A99235072F`. No Android device was connected at the final check, so installation and runtime behavior remain unverified.
- Native before/after captures, small-screen keyboard checks, Dynamic Type/TalkBack/VoiceOver, predictive Back, interruption while locked, offline device use and signed StoreKit/Play purchase scenarios are unverified.
- No participants were recruited or contacted. Timing targets, wording comprehension and optional four-week beta retention have no measured evidence.
- Store screenshots must come from verified native builds. No store assets were fabricated from this prototype, and no store submission occurred.

This is an implemented pre-launch candidate, not a verified launch-ready release. Complete native/device/billing gates before approving release. The prototype and automated checks do not close these gates.

SDK references read before implementation: [Expo 57](https://docs.expo.dev/versions/v57.0.0/), [SQLite](https://docs.expo.dev/versions/v57.0.0/sdk/sqlite/), [app configuration](https://docs.expo.dev/versions/v57.0.0/config/app/).
