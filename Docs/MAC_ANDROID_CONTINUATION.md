# Continue Android verification on the MacBook

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

## Superseded Mac checkpoint, October 3, 2026, 14:33 EDT

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
