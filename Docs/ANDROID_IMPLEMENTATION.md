# Android implementation — October 2, 2026

## Scope and source

New source lives in `app/src/`; the previous application remains in `Archive/2026-10-02-before-new-app/`. `ANDROID_BUILD_SPEC.md` preserves the supplied Perplexity document. `reference-prototype.js` is the landing-page prototype reference. The document's Expo 56 / ProTip365Shared assumptions were superseded by the actual Expo 57 project found in the repository.

Implemented: bilingual onboarding, unlimited jobs, configurable pay-week starts and goal, dashboard, two-step shift logging, overnight hours and unpaid breaks, cash/card/shared-in/shared-out tips, optional sales/other tips/notes, saved summary with undo/edit, calendar with multiple shifts per date, future shift scheduling, week/month/year statistics, job editing/archive, per-job tip statement and yearly PDF, CSV export, JSON backup and restore, notification reminders and settings. Every amount field can be empty or zero. Financial storage uses integer cents; unknown inputs remain null. Net tips exclude wages; hourly earnings include wages and are labeled accordingly. Tip-outs subtract once.

The landing-page palette and typography are implemented with bundled fonts. The tip-entry net total and Save control remain outside the scroll area. Inputs show a visible focus border, amount inputs request decimal keyboards, and radio selections expose checked state.

## Existing Android identity

Application ID: `com.defacto365.protip365`.
EAS project ID: `c1a2f4a8-14ee-4093-a4ee-a96bbe9317e2`.
Owner: `defacto365`.
Existing local signing credential configuration and production remote version auto-increment are retained. Credentials and keystores remain ignored. Version is 3.0.0. OTA runtime now follows appVersion to isolate this redesign from old SDK-57 updates. No store submission or OTA publication was performed.

The local Gradle release-mode test artifact uses Expo's debug certificate and local versionCode 1. It is an internal fresh-install test artifact, not an update for the Play installation. A store-compatible update must be built through the retained EAS production configuration, with a higher versionCode and the correct upload certificate, then tested on the Play internal track.

## Data and privacy

Native data is encrypted with SQLCipher in `protip365-redesign.db`, using its own SecureStore key. Browser preview data is separate localStorage under `protip365.new-app.v1`. Fresh installations have no demonstration data or account gate. Writes are serialized. Invalid saved data fails visibly without resetting it. Restore validates schema, job references, dates/times, IDs, timestamps and money, and offers a current-data backup before replacing data.

The old `protip365.db` and old encryption key are untouched. Existing records are NOT imported into the new model yet. Before releasing an update to existing users, establish which legacy database/store version is installed, implement and test an explicit migration or import, and verify a real upgrade preserves records. Do not advise users to uninstall the old app to install the local test APK: uninstalling can remove local data.

No tip analytics, POS integration, authentication, subscriptions or backend are used by the new interface. Optional backup is an actual file export/restore rather than an unimplemented cloud toggle. Cloud sync remains outside this implementation.

## Reminder behavior

Reminders are scheduled for actual planned shifts, at their end plus the selected offset, including overnight shifts. Tapping one opens that planned shift. Permission is requested only when enabling reminders. A 'Tomorrow morning' action postpones it to 09:00. Android swipe dismissal does not auto-reschedule: Expo does not expose a reliable background dismissal callback. Logged/deleted shift snoozes are cancelled when schedules are reconciled.

## Validation

Passed: TypeScript checking; seven calculation/schema tests; Android Metro export; Android native debug compilation. Integrated browser verification recorded a card-only shift with decimal-comma $100.50, 17:00–01:30 and a 30-minute break: 8 hours, $100.50 net tips, $25.86 hourly earnings with $13.30/hour wage. The saved record remained visible in a fresh preview tab.

The test suite covers nullable/card-only inputs, zero tips, net sharing arithmetic, overnight shifts, invalid amounts, configurable week boundaries, multiple daily shifts, planned-shift exclusion, sales-check pairing and invalid backups. Dates use the actual current day, not prototype hard-coded 2026 fixtures.

Still requiring native-device validation: fresh startup/offline operation, encrypted persistence and restore, keyboard layout and TalkBack, 320dp and font scale 1.3, PDF/share sheet and file chooser, notification delivery/actions/deep links, Android back gestures, cold-start timing, six-tap logging target and install-over-old-version migration. Android emulator runtime validation was completed on the MacBook on October 3; see ANDROID_EMULATOR_VALIDATION.md for passed checks, the keyboard fix, and remaining validation. The list above reflects the earlier pre-emulator status.

The inherited Expo package set still contains unused legacy dependencies; review/prune them and the dependency audit before production release. This implementation does not activate legacy billing/auth features.

## Run and build

Use Node >=22.13. From `app/`: `npm ci`, `npm run web`, `npm run typecheck`, `npm test -- --runInBand`. For a local native build, set ANDROID_HOME to the installed SDK, run `npx expo prebuild --platform android --no-install`, then run `./gradlew.bat :app:assembleRelease -PreactNativeArchitectures=arm64-v8a --max-workers=2` from `app/android/`. Generated native folders and build artifacts are ignored.

For the existing signed production path: use the retained `eas.json` production profile only after the release gates above. The build spec is reference material; it is not authorization to publish to Play.

## Final artifact and browser evidence

Standalone ARM64 test APK: `artifacts/ProTip365-3.0.0-internal-test.apk` (55,297,810 bytes), version 3.0.0 / local versionCode 1. Final Gradle `assembleRelease` succeeded with embedded Hermes code and five font assets. SHA256: `5F5F3CF29C6245835C0768C52F06F819F8E1191719A98821DBF7143A57111794`.

Additional browser checks passed: edit $100.50 to $120.50 and Undo back to $100.50; add a planned October 3 shift without changing recorded earnings; weekly statistics; French/English switching; 320px English and 390px French home layouts; selection controls expose aria-checked; actual CSV download checked on disk (one recorded row, one planned row, blanks remain blank). Screenshot: `screenshots/app-home-web.png` (browser rendering of shared app source, not a native-device screenshot).

Delete/restore confirmation is now an in-app web dialog; native uses Android alerts. The delete re-check was interrupted by the earlier built-in browser dialog blocking automated input across tabs, so it remains unverified in the final UI. File restore, native sharing and notification behavior remain device-validation items. The existing data in the browser preview is test data entered during these checks; it is not bundled in fresh installations.

A compiled browser preview is served at http://127.0.0.1:8083/ via `node scripts/serve-web.cjs` from `app/`. Generate that preview with `npx expo export --platform web --output-dir dist-web` before serving. Public prototype hosting remains unchanged.
