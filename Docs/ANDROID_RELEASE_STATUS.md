# Android release status — October 3, 2026

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

## Verified Google Play configuration

- Developer: DeFacto365, ID `6320222294638558312`.
- Update this app: **ProTip365 - Tip Tracker**, package `com.defacto365.protip365`, app ID `4973804276694301111`.
- The other draft app (`com.protip365.monthly`) is not the Android target.
- Current production: version **1.0.0**, version code **11**, released July 30, 2026, rollout 100%. Internal track also serves build 11.
- Console reports one installed/active device. Preserve existing local records during upgrade; do not assume this is a fresh install.
- `lifetime_unlock`: active purchase option `lifetime`, backwards compatible, 174 regions. Canada price **CAD 19.99**; United States **USD 19.99**.
- `monthly`: active auto-renewing base plan `local-monthly`, backwards compatible, 175 regions. Canada **CAD 4.19/month**; United States **USD 2.99/month**. Seven-day grace period and automatic account hold are configured.
- No pricing or product configuration was changed during inspection.
- Upload certificate SHA-256: `2E:A5:53:BD:B0:15:31:C4:D3:D6:AE:EA:08:68:B6:C3:0C:5A:F3:DF:EA:B4:AA:40:80:96:EB:4F:47:98:6F:16`.
- Upload certificate SHA-1: `97:4E:89:CD:42:3D:2E:89:39:B4:F5:EF:44:F6:1B:CB:AC:7A:DB:91`.

## Billing implementation and checks

The new interface now mounts the Expo IAP adapter and preserves the existing `protip365.entitlement.v1` SecureStore record. The trial is now 7 days, as approved on October 3, 2026; monthly/lifetime products are retained. Existing trial start dates are preserved rather than reset, and paid entitlements are unchanged. Google Play supplies localized prices. Pending or suspended payments do not unlock access; completed purchases are acknowledged. Restore and foreground reconciliation update cached access. Corrupt access records fail closed rather than starting another trial. Exports, backup restore and record deletion remain accessible after expiry.

TypeScript and **24 tests across four suites** passed. Tests cover financial calculations, trial expiry/clock rollback, purchase restoration/revocation, pending/cancelled purchases, offline access, subscription expiry and old entitlement-record compatibility.

An ARM64 release-mode **debug-signed test APK** compiled successfully. These checks do not establish real Play Billing purchase success. It cannot update the production app.

Current test artifact: `artifacts/ProTip365-3.0.0-billing-test.apk`, SHA-256 `B9C75DD77D6FB61F505A8F9EE8440C1AD54807C26940CFCC9C0FAFC2A01C0890`. It includes the later planning, notification, Undo and record-reset changes. This particular APK has not yet been exercised on the emulator.

## Release blockers / remaining validation

1. **Resolved on the Mac, October 3:** recovered `~/Library/CloudStorage/OneDrive-Synergia365ConseilInc/Documents/protip365-keys/protip365-upload.keystore`. The adjacent credential note unlocks alias `protip365-upload`; keytool confirms both SHA-256 and SHA-1 exactly match the recorded Play upload certificate. Passwords and private keys remain outside the repository. A second copy exists in the DeFacto365 finance folder. Correctly signed production artifacts remain to be built and tested.
2. **Resolved on the Mac, October 3:** direct local SDK/adb access is available; `ProTip365_QA_API36` starts as `emulator-5554`. No SSH authorization was reintroduced.
3. Run actual Google Play license-tester purchase tests for monthly and lifetime, cancellation/pending, restore, refund/revocation and subscription renewal/expiry. Use Google's test payment methods and verify the test banner; no real charges.
4. Implement and test preservation/import of the legacy encrypted database, respecting its existing passcode lock. The redesign currently uses its own database and leaves the old database untouched. Preserving the file alone is not a completed upgrade migration.
5. Complete native backup restore/file inspection, notification delivery/actions/cancellation and accessibility checks listed in `ANDROID_EMULATOR_VALIDATION.md`. Planning today's shift, cold notification routing, stale snooze prevention and visible Undo were improved after the earlier emulator session and need native verification.
6. Align public privacy/support pages and Play disclosures with the shipping features. The existing policy mentions optional app passcode/biometrics and password-encrypted backups; the redesign does not currently offer those features. The new erase control explicitly covers this version's records and preserves purchases/trial and old-version data.
7. Produce a correctly signed production AAB with a version code above 11, validate through Play's internal track and pre-launch checks, then submit the production update. Publication is not complete until the new production release is available.

User has authorized Android publication; no release has been uploaded or submitted yet.

## Mac continuation at ca9f9da

- Fetched the requested remote branch and used an isolated managed checkout because the original Mac checkout contains substantial uncommitted work. Those changes were preserved.
- Reinstalled dependencies from the lockfile; TypeScript and all 24 tests across four suites pass.
- Play Console is accessible under the user's DeFacto365 Chrome profile. Live inspection confirms production and internal tracks still serve version code 11.
- With explicit user approval, added `defacto365@gmail.com` to the selected Maya license-tester email list. Play confirms three members; existing members remain. The emulator is signed in with this account. Actual test purchases remain unverified.
- Downloaded Play's signed universal build 11 APK for upgrade validation. Its bundled code contains the legacy encrypted database and passcode keys, confirming that migration and lock preservation are relevant to the released app.
- Native build setup uses the existing JDK 21 at `~/.local/share/protip-tools/jdk21/Contents/Home`. Android Studio's bundled newer Java failed native configuration; the default 512 MiB Gradle metaspace limit also failed. `assembleRelease -PreactNativeArchitectures=arm64-v8a` passed in 1m32s with local heap/metaspace limits of 4096/1536 MiB. The debug-signed APK installed successfully with `adb install -r`; SHA-256 `6568A4B34A10979BF45FA7DC30FDFAFA5999BD4D0EB9A761188C101AD716E07A`. This is version 3.0.0, version code 1, and cannot update the Play production app. Runtime and billing checks on this rebuilt artifact remain unverified.
- Emulator UI automation via the previous adb/UI Automator scripts is awaiting the user's requested method confirmation. The computer-control tool cannot bind the standalone emulator process. Android Studio was opened as an alternative, but its initial project sync used the incompatible bundled Java; local project SDK/JDK settings now point to the existing SDK and JDK 21.
- The user requires the landing-page logo before Google Play publication. The remote branch subsequently advanced to `e02ca96` with app and launcher branding aligned to the latest landing-page logo. This incoming change is preserved; the APK tested above predates it and the new branding still needs a rebuild and native verification.
## Store listing prepared 2026-10-03

All seven existing store languages now have saved draft descriptions that reflect the redesigned app. The default icon uses the landing-page sage `p.` mark. Six ordered feature screenshots and a feature graphic use the landing-page typography and colors, with localized French graphics for fr-CA/fr-FR and English graphics for the other locales. Assets and copy are in `Docs/google-play/`. Release notes are prepared in `release-notes.txt` but await attachment to the new Android release. The listing has not been submitted for review or published; submit it alongside the validated redesigned build. The poster screens were captured from the web interface with isolated demo data, so check them against the final native app before publication.
