# Android emulator validation — October 3, 2026

## Windows follow-up - October 3, 2026, 16:01 EDT

Fetched and fast-forwarded the clean Windows checkout at C:\Github\Protip365 to the Mac handoff ebc062a on codex/v4-reset-and-landing-ux. No local changes were discarded.

Live inspection of Google Play Console Publishing overview confirms production 14 (3.0.0), Start full rollout, and the release/listing changes are still in review. Managed publishing remains off. No actionable review issue is displayed on this page; it says Google may find additional issues during review. Last published remains July 30, 2026.

The refreshed public listing at https://play.google.com/store/apps/details?id=com.defacto365.protip365 still shows the earlier short description (Plan shifts across every job. See real hours, tips, and expected pay.), July 21, 2026 update date, and earlier receipt/date-picker release notes. Public build 14 and the updated branding/listing are not yet confirmed. No release or listing setting was changed during this check.

Next: check again after Google review, address any reported issue, then verify production build 14 and the public logo, screenshots and localized descriptions. Native results below are the Mac agent's committed evidence; they were not rerun on Windows. Physical-device and comprehensive spoken accessibility checks remain unavailable.

## Production submission — October 3, 2026, 15:52 EDT

Build 14 (3.0.0) and the updated store listing are submitted for **production, full rollout to all targeted countries**. Google Play's initial automated checks finished and Publishing overview now says "Your changes are now in review." Managed publishing is **off**, so approval publishes automatically. Build 11 remains the public version until Google approves the update. Do not report build 14 as live yet.

Final AAB: ~/ProTip365-emulator-test-20261003/build14-upload-final.aab, SHA-256 27db59ea297c7916564688cd2322d14e1fd3a5927dac8fcae830618338a4abb5. Internal release 7 contains build 14; production release 2 contains build 14 only, with seven-locale release notes. All 22 release/listing changes were sent for review, including the landing-page logo, feature graphics, screenshots and localized copy. Source fixes are pushed at 22c51d9. Original upload keystore was recovered and its certificate matches Play; credentials remain outside Git.

### Completed final Play-signed upgrade and billing tests

- Downloaded Google's signed universal build-14 APK and installed it over the preserved production-11-to-12 fixture **without uninstalling**. Its signing certificate matches the production APK.
- Wrong inherited passcode is rejected; correct passcode and recovery key unlock. Background return, share return and cold restart relock before exposing records. Repeated restarts do not duplicate imports.
- Original employer, planned shift, worked shift and amounts survive: six hours at USD 13.30/hour; USD 79.80 wages + USD 95.50 net tips + USD 15.25 other income = USD 190.55. Home shows one worked shift and the planned shift separately.
- Actual build-14 CSV has the two original rows and preserved identifiers/timestamps. Actual JSON backup has one employer, two shifts and the legacy database archive. Older templates, recurrence, goals and payouts remain archived; they are not all active redesign features.
- Existing lifetime access survives the upgrade and Restore Purchases. Ordinary refund with entitlement removal returned access to the seven-day trial. Google's delayed-approval test payment kept trial access while pending, then granted full access after approval. All payments used Google's test instruments, with no real charges. Google's pending notice is visible; the app's additional pending message can reset when the inherited lock remounts its main screen.
- Earlier monthly tests passed: checkout cancel, declined payment, approval, Restore, accelerated renewal, store cancellation and expiry. Earlier lifetime delayed decline, chargeback/revocation, delayed approval and Restore passed.

### Completed native checks and disclosures

Offline record creation, cold persistence, backup restore, malformed-backup rejection and actual CSV/JSON/PDF export inspection pass. Real reminder delivery, cold-start routing, snooze, completed/removed-shift protection and alarm cancellation pass. Today's planned shifts stay planned; ended planned shifts become worked when saved. Erase confirmation, Undo and preservation of trial/purchases pass using disposable test data.

Targeted TalkBack double-tap navigation and labeled form checks pass. French/English, keyboard-visible entry, landscape entry and 320dp/font 1.3 save checks pass after the compact form fix. Display, rotation, accessibility and connectivity settings were restored. TypeScript and 39 tests in seven suites pass; final signed all-architecture AAB build and certificate checks pass.

English/French/Spanish Android 3 privacy disclosures are live on www.protip365.com/privacy, website branch website/protip365-landing-2026-10 at 48ec754. Live native Chrome inspection confirms readable JSON backup, inherited lock behavior and erase/purchase/trial scope.

Google's pre-launch report has no device report for this internal release. A physical Android device, comprehensive spoken accessibility audit and human-observed entry speed were not available; do not claim those checks passed. No source change followed the final AAB build.

### Handoff and remaining external step

Only Google review and subsequent public availability remain. Inspect Publishing overview for approval or actionable issues, then confirm production build 14 and the updated public logo/listing. Production track: 4698220799313296574; app: 4973804276694301111; developer: 6320222294638558312; package: com.defacto365.protip365.

Continue in ~/.codex/worktrees/android-release/Protip365, branch codex/v4-reset-and-landing-ux. Preserve the original checkout's other bots' uncommitted work and incoming remote commits. GitHub connector is authenticated as DeFacto365; commit author email is jacques.bolduc@defacto365.com. Local HTTPS push uses another cached account and returns 403; use the correct connector without force pushing. This handoff is committed in all three Android status documents; the exact originating laptop chat is unidentified, so no guessed chat was messaged.

Local evidence in ~/ProTip365-emulator-test-20261003 includes play-production14-in-review.png, play-internal-v14.png, upgrade14-records-preserved.png, upgrade14-export.csv, upgrade14-backup.json, play-refund-v14-test.png, build14-pending-test-payment.png, build14-approved-test-payment.png and live-privacy-android3.png. Test-account screenshots, synthetic recovery credentials and signing secrets are excluded from Git.

## Earlier validation checkpoints (superseded where noted)

## Additional native build-14 verification

Separate QA package com.defacto365.protip365.qa preserves the real Play-signed upgrade fixture. Offline restore, actual CSV/JSON export, new record creation and cold persistence passed with no default network. Two reminders delivered at 14:17; snooze scheduled tomorrow 09:00, completing the snoozed shift removed the alarm, an old completed-shift notification refused another snooze, and disabling reminders cancelled the remaining future alarm. Native TalkBack activated Add with a double tap and exposed form labels; comprehensive spoken-output coverage remains unverified.

The fixed totals footer initially hid landscape entry fields. The corrected short-layout form scrolls the footer with its fields: a landscape $3.50 save passed, and 320dp/font 1.3 entry with keyboard open accepted $2.25 and scrolled to its correct total and successful Save. French/English and cold persistence passed. Normal display, rotation, accessibility and network settings were restored. Final QA totals were $138.50 across six test shifts. These QA-package tests do not establish Google Play billing or legacy production migration.

Local evidence is in ~/ProTip365-emulator-test-20261003: qa-talkback-form-final.png, qa14-landscape-fields-fixed.png, qa14-landscape-save-fixed.png, qa14-en-320-font13-field-fixed.png, qa14-en-320-font13-save-fixed.png and offline-final-exports/. Personal license-tester screenshots are excluded from Git.

## Historical laptop emulator session

Native runtime tested over SSH on the user's Apple Silicon MacBook, using Android SDK adb and UI Automator hierarchy inspection with actual input, screenshots, and logcat. This was a standalone APK; Metro was not used.

## Environment and artifact

- AVD: `ProTip365_QA_API36`, serial `emulator-5554`, Pixel 5, API 36, Google Play ARM64 image.
- Emulator: 37.1.11. macOS 27.2, arm64. Device timezone: America/Toronto.
- Normal viewport: 1080 × 2340, density 440 (~393dp). Small-screen check: 880 × 1907 at density 440 (320dp), font scale 1.3. Size and font settings restored afterward.
- Package: `com.defacto365.protip365`, version 3.0.0, local versionCode 1, Android Debug signing certificate.
- Initial APK SHA256: `70E54E5268757076586D3B3E345A5D028DC1941DA878C03E439B061D88701A57`.
- Corrected APK: `artifacts/ProTip365-3.0.0-internal-test.apk`, 55,297,810 bytes, SHA256 `5F5F3CF29C6245835C0768C52F06F819F8E1191719A98821DBF7143A57111794`.

## Results

| Check | Result and evidence |
| --- | --- |
| Install and startup | Passed. APK installed; empty onboarding, no account/paywall or sample shifts. English system locale used initially. No app fatal exception found in captured AndroidRuntime/ReactNativeJS logs. |
| Onboarding | Passed. Bar Le Zinc, Bartender, $13.30/h, 17:00–23:30, 30-minute break, Monday week. |
| Yesterday / overnight | Passed. Native time picker changed end to 01:30; date selected Yesterday (October 2). Card-only `100,50`, other fields blank: 8h, $100.50 net, $206.90 wage-plus-tip total, $25.86/h. Home, saved screen and Stats agreed. |
| Edit and Undo | Passed. Changed card to $120.50 and saved; Undo returned Home to $100.50. |
| Validation and zero | Passed. Negative card amount produced a visible validation error without saving. Zero saved successfully; Undo restored the previous record. |
| Delete and Undo | Passed. Android confirmation appeared; DELETE removed record and calendar total became $0.00. Undo restored Home to $100.50. Undo is below calendar content and requires scrolling; discoverability still needs user testing. |
| Planned shift | Passed. Native date picker selected October 4; planned 17:00–01:30 shift appeared on Home. Recorded total stayed $100.50 and count stayed one. |
| Week boundaries | Passed. Saturday start excluded yesterday: weekly $0.00, monthly $100.50. Restored Monday and weekly $100.50 returned. |
| App restart and corrected-APK reinstall | Passed. Saved record persisted after `install -r` and force-stop/relaunch, with the corrected APK. This does not test an upgrade from the legacy production app. |
| Emulator reboot | Passed. Native record, job, language and planned shift persisted after Android reboot. |
| Offline cold start | Passed. Disabled Wi-Fi and mobile data after reboot; verified both settings were 0 and active default network was none. Cold launch displayed saved $100.50 and $25.86/h. Connectivity restored afterward. Offline creation/export/restore were not separately exercised. |
| English / French | Passed for inspected screens. Switched to French; Home, entry forms, job role and currency formatting updated. |
| Native numeric keyboard | Found and fixed: keyboard obscured total/Save. Android KeyboardAvoidingView now uses height behavior. Corrected APK shows total and Save above keyboard; field remains editable. |
| 320dp / font 1.3 | French entry fields scroll and Save/net remain visible above keyboard. The fixed footer leaves a small area for the focused field on short screens; field label may scroll offscreen. This is a targeted layout check, not a full accessibility audit. |
| CSV / JSON / PDF export | Each opens Android share sheet with the expected CSV, backup JSON, or generated PDF filename. No external sharing was performed. Exported native file contents were not independently inspected. |
| Notifications | Permission is granted and Android AlarmManager contains the planned overnight end+15-minute alarm (October 5, 01:45). Alarm has a one-hour scheduling window. Actual delivery, tap routing, snooze and cancellation are not yet validated. |
| Timing | adb cold activity launch reported 493ms after reinstall, 830ms after emulator reboot, 693ms offline. These are activity-launch measurements, not full interactive readiness or human entry-speed measurements. |

## Fix and verification

`app/src/App.tsx` now sets Android `KeyboardAvoidingView` behavior to `height`, retaining iOS `padding` and web behavior. TypeScript passed; Gradle `assembleRelease` passed in 1m35s. Reinstalled the corrected APK and verified the affected screen with the keyboard visible, including the narrow French layout.

## Evidence

- `screenshots/android-home.png`: initial native onboarding.
- `screenshots/android-keyboard.png`: original keyboard obstruction.
- `screenshots/android-keyboard-fixed.png`: corrected native layout.
- `screenshots/android-keyboard-fr-320-large.png`: corrected French layout, 320dp/font 1.3.
- `screenshots/android-offline.png`: French Home after offline cold launch.
- `screenshots/android-runtime.log`: captured native runtime log before reboot.

## Still required before production

Native backup restore and malformed-file rejection; inspection of actual PDF/CSV/JSON contents; notification delivery/actions/cancellation; TalkBack and broader accessibility/orientation checks; multiple shifts per day in the native UI; user-observed entry speed; a physical Android-device test; legacy database migration and a correctly signed Play internal-track upgrade. No Play publication, cloud sync, or legacy migration was performed.

The test emulator was stopped after verification. APK and test files remain in `~/ProTip365-emulator-test-20261003` on the Mac. The dedicated temporary SSH authorization and local key pair were removed after collecting evidence; other SSH configuration was preserved.
