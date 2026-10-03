# Android release status — October 3, 2026

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

The new interface now mounts the Expo IAP adapter and preserves the existing `protip365.entitlement.v1` SecureStore record. It retains the existing 30-day trial and monthly/lifetime products. Google Play supplies localized prices. Pending or suspended payments do not unlock access; completed purchases are acknowledged. Restore and foreground reconciliation update cached access. Corrupt access records fail closed rather than starting another trial. Exports, backup restore and record deletion remain accessible after expiry.

TypeScript and **24 tests across four suites** passed. Tests cover financial calculations, trial expiry/clock rollback, purchase restoration/revocation, pending/cancelled purchases, offline access, subscription expiry and old entitlement-record compatibility.

An ARM64 release-mode **debug-signed test APK** compiled successfully. These checks do not establish real Play Billing purchase success. It cannot update the production app.

Current test artifact: `artifacts/ProTip365-3.0.0-billing-test.apk`, SHA-256 `B9C75DD77D6FB61F505A8F9EE8440C1AD54807C26940CFCC9C0FAFC2A01C0890`. It includes the later planning, notification, Undo and record-reset changes. This particular APK has not yet been exercised on the emulator.

## Release blockers / remaining validation

1. Recover the matching upload key. The configured `C:\Users\jack_\protip365-keys\protip365-upload.keystore` is missing and EAS has no uploaded credentials. Two older archived JKS files exist, but their certificate match has not been established and the current credential password does not unlock them. Never upload a guessed replacement or silently reset the upload key.
2. Reconnect native test access. The prior temporary Mac SSH authorization was removed after testing; the Mac is not currently a connected host in this Windows Codex session.
3. Run actual Google Play license-tester purchase tests for monthly and lifetime, cancellation/pending, restore, refund/revocation and subscription renewal/expiry. Use Google's test payment methods and verify the test banner; no real charges.
4. Implement and test preservation/import of the legacy encrypted database, respecting its existing passcode lock. The redesign currently uses its own database and leaves the old database untouched. Preserving the file alone is not a completed upgrade migration.
5. Complete native backup restore/file inspection, notification delivery/actions/cancellation and accessibility checks listed in `ANDROID_EMULATOR_VALIDATION.md`. Planning today's shift, cold notification routing, stale snooze prevention and visible Undo were improved after the earlier emulator session and need native verification.
6. Align public privacy/support pages and Play disclosures with the shipping features. The existing policy mentions optional app passcode/biometrics and password-encrypted backups; the redesign does not currently offer those features. The new erase control explicitly covers this version's records and preserves purchases/trial and old-version data.
7. Produce a correctly signed production AAB with a version code above 11, validate through Play's internal track and pre-launch checks, then submit the production update. Publication is not complete until the new production release is available.

User has authorized Android publication; no release has been uploaded or submitted yet.
