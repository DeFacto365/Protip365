# Continue Android verification on the MacBook

## Mac release continuation — current checkpoint, October 3, 2026, 14:33 EDT

Production remains version code 11. Internal builds 12 and 13 were uploaded with the recovered original upload key; 13 is available to testers. Publication remains authorized. The Mac is locked, preventing native Chrome/Play Console upload and download steps; the user has been asked to unlock it. Do not report production complete.

Verified in the API 36 Google Play emulator with the approved license-tester account:
- Monthly: real Google test checkout cancellation, declined card, approved payment, Restore Purchases, accelerated renewal, store cancellation, and expiry back to the existing trial.
- Lifetime: delayed decline stays locked; approved chargeback payment grants access, then revokes after Play cache refresh; delayed approval grants access and Restore Purchases succeeds. No real charges.
- Native CSV/JSON/PDF files saved through Android's share interface and inspected. Valid JSON backup restores; malformed backup fails without changing records.
- Today's planned shift remains planned; ended planned shifts become worked when saved. Native erase confirmation preserves purchases/trial; visible Undo restores records.
- A delivered notification opened the correct shift after a cold start with data loaded.

Subsequent build-14 checks use a separate QA package, com.defacto365.protip365.qa, leaving the actual production-upgrade fixture intact. They establish native behavior, not Play Billing or production migration:
- Offline backup restore, actual CSV/JSON export, new record saving and cold persistence pass with Wi-Fi/mobile data disabled and no default network. Repeated saves and multiple shifts are retained.
- Two real reminders delivered at 14:17. Tomorrow morning scheduled an October 4 09:00 alarm; completing that shift cancelled the snoozed alarm. Completing the other shift through the normal UI left its old notification available; tapping its stale snooze did not schedule another alarm. Turning reminders off cancelled the remaining future alarm.
- TalkBack's actual spoken/touch-exploration service was bound; double-tap activated the Add button and opened the labeled form. This is targeted navigation coverage, not a comprehensive audio accessibility audit.
- Landscape testing found a fixed-total-panel obstruction. Short layouts now scroll the total/Save panel with the fields. Native landscape entry saved $3.50; at 320dp/font 1.3 the keyboard-visible field accepted $2.25, and scrolling exposed the matching total and Save, which succeeded. English/French and cold persistence pass. Display, accessibility, rotation and connectivity settings were restored.

Recovered upload certificate matches Play: SHA-256 2E:A5:53:BD:B0:15:31:C4:D3:D6:AE:EA:08:68:B6:C3:0C:5A:F3:DF:EA:B4:AA:40:80:96:EB:4F:47:98:6F:16. Keys/passwords stay outside Git.

FINAL candidate build 14: ~/ProTip365-emulator-test-20261003/build14-upload-final.aab; SHA-256 27db59ea297c7916564688cd2322d14e1fd3a5927dac8fcae830618338a4abb5. Includes landing-page logo, seven-day trial, French employer wording, pending-payment feedback, inherited-lock/import implementation, Android database-path correction and compact form layout. Signed all-architecture AAB build and certificate verification pass; TypeScript and 39 tests in seven suites pass. Earlier build14-upload.aab and build14-upload-corrected.aab are superseded. Build 14 has NOT been uploaded.

Upgrade fixture: installed production 11 through Play; created employer Legacy Upgrade QA, one planned shift and one worked shift ($190.55 USD = $79.80 wages + $95.50 net tips + $15.25 other income). Enabled a disposable six-digit lock. Upgraded without uninstall to Play-generated 12. Wrong passcode is rejected; correct passcode unlocks but loading fails closed. The failure also reproduced on fresh QA installation. Diagnosis: expo-sqlite returns a bare Android directory path, whereas expo-file-system File requires file://. The path normalization and a strict regression mock fix fresh native startup and backup restore. Actual production-record migration still needs verification by installing Play-generated 14 WITHOUT uninstalling the original com.defacto365.protip365 package. Original records remain intact. Templates, recurrence, goals and payout rows remain in the old database/JSON archive; they are not all active redesign features.

Website disclosures in English/French/Spanish are pushed to website/protip365-landing-2026-10 at 48ec754 and live on www.protip365.com. They distinguish readable JSON from earlier encrypted .pt365 backups, explain inherited locks and erase scope, and confirm restore/export after expiry. Vercel production deployment ChJHtAEXQhVDVq5usNxez5wM1iz2 was promoted and live content verified.

Continue in ~/.codex/worktrees/android-release/Protip365. The original checkout contains other bots' uncommitted work; preserve it and incoming remote commits. Use the authenticated DeFacto365 GitHub connector for fast-forward pushes; local HTTPS uses another cached account and fails 403. Git author email: jacques.bolduc@defacto365.com. Source and the earlier checkpoint were pushed at 49cc37d; this checkpoint accompanies the later path/layout fixes.

Remaining after manual Mac unlock: upload FINAL 14 to internal testing; download Play-signed universal APK and update the preserved 12 fixture; verify imported values, idempotent restart and inherited lock/recovery/relock; verify latest seven-day billing/pending feedback and ordinary refund/revoke test; inspect pre-launch report and final store listing/disclosures; submit authorized production update and verify availability. A physical Android device and user-observed entry speed have not been available. The originating laptop chat is unidentified; committed continuation/status documents provide its handoff. Do not message another bot's chat by guessing.

## Earlier handoff / historical checks

This is a continuation of the Android publication task. The user has authorized completing and publishing the update. Read `ANDROID_RELEASE_STATUS.md` and `ANDROID_EMULATOR_VALIDATION.md` before changing release configuration.

Use the repository `https://github.com/DeFacto365/Protip365.git`, branch `codex/v4-reset-and-landing-ux`. Check the latest remote commit and protect any local modifications before updating. The current source is in `app/`; all previous code is in `Archive/2026-10-02-before-new-app/`.

Brand update: the in-app vector mark, app/adaptive/monochrome icons, favicon and configured splash screen now use the latest landing-page logo geometry and colors. Pull the latest branch before building; the earlier billing test APK predates this logo alignment. `app/scripts/create-brand.cjs` regenerates all logo assets from the canonical mark in `app/src/brand.ts`. Android prebuild and browser export were verified after this update; the Mac must build/install the updated native app.

The Mac's existing test directory is `~/ProTip365-emulator-test-20261003`; its AVD is `ProTip365_QA_API36`, Google Play API 36 ARM64. Android SDK is `~/Library/Android/sdk`. The prior test authorization was removed; do not assume SSH remains available.

Build/install the current native app locally, then verify:

- Trial/access screen, Play prices and unavailable-store behavior.
- Actual monthly/lifetime purchase and restore using an authorized license tester and Google's test payment instruments. Stop before any real charge. Use matching package `com.defacto365.protip365`.
- Today's planned shift stays planned; recording an ended planned shift records earnings.
- Cold-start reminder routing waits for loaded records; removed/completed shifts cannot be snoozed.
- Backup/restore and malformed-file rejection; inspect actual CSV/PDF/JSON contents.
- Offline persistence, French/English, keyboard, narrow/large-font layout and TalkBack.
- Erasing this version's test records leaves purchase/trial status intact; Undo immediately recovers the test records.

Search for the original upload keystore on the Mac by filename only, then compare its public certificate with the upload SHA-256 in `ANDROID_RELEASE_STATUS.md`. Do not print passwords or key contents, generate a replacement key or reset Play signing without resolving the credential requirement. The old production version code is 11.

Do not claim billing, upgrade migration or publication is complete from a successful compilation. Save exact test evidence and outstanding blockers back to the repository.

Google Play listing update: `Docs/google-play/` contains the landing-page logo, six French/English feature screenshots, feature graphics, descriptions and `release-notes.txt` with seven locale tags. Listing changes are saved as drafts in the existing production app. Compare the web-derived screenshots with the final native build and submit the listing with the redesigned Android release. Paste the prepared notes into the new release; do not attach them to production build 11.
