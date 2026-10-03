# Continue Android verification on the MacBook

## Mac release continuation — current checkpoint, October 3, 2026

Production is still version code 11. Internal builds 12 and 13 were uploaded with the recovered original upload key; build 13 is available to internal testers. Publication is authorized, but production must wait for the legacy upgrade defect described below.

Verified in the API 36 Google Play emulator with the approved license-tester account:
- Monthly: real Google test checkout cancellation, declined card, approved payment, Restore Purchases, accelerated renewal, store cancellation, and expiry back to the existing trial.
- Lifetime: delayed decline stays locked; approved chargeback payment grants access, then revokes after Play cache refresh; delayed approval grants access and Restore Purchases succeeds. No real charges.
- Native CSV/JSON/PDF files saved through Android's share interface and inspected. Valid JSON backup restores; malformed backup fails without changing records.
- Today's planned shift remains planned; an ended planned shift opens earnings entry and becomes worked when saved.
- A delivered notification opened the correct shift after a cold start with data loaded. Actual stale-snooze/cancellation and remaining offline/accessibility checks still need completion.
- Native erase confirmation preserves purchases/trial; visible Undo restores records.

Recovered signing certificate matches Play: SHA-256 2E:A5:53:BD:B0:15:31:C4:D3:D6:AE:EA:08:68:B6:C3:0C:5A:F3:DF:EA:B4:AA:40:80:96:EB:4F:47:98:6F:16. Private keys/passwords stay outside Git.
Build 13 AAB SHA-256: 05b388523ebcd98d9c2f54292b47519bc4ab3676325f6a7e1aa120157ed3263e. Includes landing-page logo, seven-day trial, French employer wording, pending-payment feedback and inherited-lock/import implementation. TypeScript and 39 tests across seven suites pass.

Upgrade blocker: installed production 11 through Play; created employer Legacy Upgrade QA, one planned shift, and one worked shift ($190.55 USD = $79.80 wages + $95.50 net tips + $15.25 other income). Enabled a disposable six-digit app lock. Upgraded without uninstall to Play-generated build 12. Existing lock blocks records and rejects a wrong code; correct code unlocks but record loading fails closed. Original records are not erased. Diagnose and verify a corrected build before production. Templates, recurrence, goals and payout rows are retained in the original database and JSON legacy archive; they are not all active redesign features.

Website disclosure corrections in English/French/Spanish are pushed to website/protip365-landing-2026-10 at 48ec754 and live on www.protip365.com. They distinguish readable JSON backups from earlier encrypted .pt365 files, explain inherited locks and erase scope, and confirm restore/export remain accessible after expiry.

Continue in the isolated Mac worktree ~/.codex/worktrees/android-release/Protip365. The original checkout contains other bots' uncommitted work. Preserve it and incoming remote commits. Use the authenticated DeFacto365 GitHub connector for fast-forward pushes; local HTTPS push uses another cached account and fails 403. Git author email: jacques.bolduc@defacto365.com.

Remaining: corrected production upgrade/import and lock/recovery/relock checks; native stale-snooze, cancellation, offline and accessibility checks; latest signed internal build and pre-launch report; final store listing/disclosure verification; production submission and availability. The laptop loop closes through these committed status documents; do not claim complete while this list remains.

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
