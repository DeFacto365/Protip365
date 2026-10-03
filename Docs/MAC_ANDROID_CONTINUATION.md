# Continue Android verification on the MacBook

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
