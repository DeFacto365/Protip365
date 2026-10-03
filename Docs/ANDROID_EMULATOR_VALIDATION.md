# Android emulator validation — October 3, 2026

Current continuation status is recorded in ANDROID_RELEASE_STATUS.md. Its October 3 checkpoint supersedes historical pending/completed labels below. Legacy upgrade currently fails closed after a successful inherited passcode check; production is blocked until corrected.

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
