# ProTip365 V4 — Google Play App Content answer sheet

**Status:** Version 2.0.0 release-candidate review
**Verified against:** Shared Android/iOS `2.0.0` working tree on 2026-08-03
**Scope:** The current V4 build in `app/`. Recheck every answer if the build, SDKs, active Play artifacts, or privacy policy changes.

This is a copy-ready answer sheet for **Google Play Console → Policy and programs → App content**. It is not legal advice. The owner remains responsible for the final declarations.

## Verified behavior behind these answers

- Phase I has no developer account, email/password login, Supabase client, user-data backend, analytics SDK, advertising SDK, or crash-reporting SDK. No direct `fetch`, Axios, `XMLHttpRequest`, or WebSocket call sends user records from `app/`.
- Employer names, shifts, schedules, hours, wages, tips, sales, payouts, notes, settings, and goals are stored in the on-device SQLite database. `app/app.json` enables SQLCipher with `useSQLCipher: true`; `app/src/data/db.ts` creates a random 256-bit database key, keeps it in `expo-secure-store`, and applies it with `PRAGMA key`.
- The optional local app lock uses a salted passcode hash in `expo-secure-store`. `expo-local-authentication` returns only the device authentication result; the app does not receive or store fingerprint/face templates.
- `expo-notifications` schedules post-shift reminders locally. The English lock-screen text is **“Shift follow-up”** and **“A scheduled shift may still need your update.”** It contains no employer, wage, tip, or earnings value. The Android channel uses `PRIVATE` lock-screen visibility.
- CSV export is started only when the user taps **Export CSV**. The app creates a plaintext CSV in its cache and opens the OS share sheet with `expo-sharing`; it does not select or contact a recipient. The app also offers a user-initiated, password-encrypted full backup through the same share sheet.
- `expo-iap` talks to Google Play Billing for `lifetime_unlock` and `monthly`. Google handles payment details directly; ProTip365 has no payment backend and does not send shift or earnings records to Google. Version `2.0.0` enforces the local 30-day trial and paid write access.
- EAS Update is enabled and checks `https://u.expo.dev/...` on app launch. Expo says this service collects the device operating system and a randomized installation token, and its dashboard reports update adoption and failed installs. Google treats SDK/service-provider transmission as collection even when the publisher does not receive raw data.
- The app is not completely network-free: Google Play Billing and EAS Update use the network, and the user can open external privacy/terms/support links. The verified claim is narrower: **user-entered records have no network/API dependency and are not sent to Defacto365, Expo, or Google.**

## 1. Data Safety form answers

### Copy these top-level answers

| Play Console question | Select |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** — only limited EAS Update technical data, not user-entered work or financial records. |
| Data types | **App activity → App interactions; App info and performance → Crash logs and Diagnostics; Device or other IDs.** Select no others. |
| Is all user data collected by your app encrypted in transit? | **Yes** — EAS Update requests use HTTPS. |
| Does the app provide a way for users to request deletion? | **No, based on currently verified behavior.** The in-app erase removes user-entered local records, but no end-user deletion path for Expo's EAS Update token/metrics was verified. Change this to Yes only after the owner establishes and documents a working request process with Expo. |
| Independent security review | **No**, unless the owner has completed a qualifying review not recorded in this repo. |

Google defines “collected” as user data transmitted off the device, including transmission by an SDK to a service provider. Data processed only on the device does not need to be disclosed. Therefore, EAS Update technical telemetry is collected, while information the user enters into ProTip365—especially tips, wages, employer names, schedules, and notes—is **not** collected.

For categories marked **No**, the exact follow-up answers are **Processed ephemerally: Not applicable; Required or optional: Not applicable; Purpose: None; Encrypted in transit: Not applicable.** For the three EAS Update data types marked **Yes**, use the specific answers below.

| Play data category | Collected? | Shared? | Ephemeral? | Required/optional | Purpose | Transit encryption | Deletable? | One-line justification |
|---|---|---|---|---|---|---|---|---|
| Location | **No** | **No** | N/A | N/A | None | N/A | Yes, if locally entered in a note | No location permission or location API is used. Expo receives an IP address as part of HTTPS operation, but no verified evidence shows it is used to infer location; owner must reconfirm Expo's current SDK guidance. |
| Personal info | **No** | **No** | N/A | N/A | None | N/A | **Yes, locally** | There is no account or login; employer names and any personal text entered in notes stay in SQLCipher unless the user deliberately exports them. |
| Financial info | **No** | **No** | N/A | N/A | None | N/A | **Yes, locally** | Tips, wages, sales, deductions, and payout amounts are “Other financial info,” but they stay on-device. Google Play handles payment details directly; the app only checks local store entitlement state and has no billing server. |
| Health and fitness | **No** | **No** | N/A | N/A | None | N/A | N/A | The app does not request, read, or transmit health or fitness data. |
| Messages | **No** | **No** | N/A | N/A | None | N/A | N/A | The app has no email, SMS, chat, or in-app messaging access. |
| Photos and videos | **No** | **No** | N/A | N/A | None | N/A | N/A | The app does not request, read, capture, or transmit photos or videos. |
| Audio files | **No** | **No** | N/A | N/A | None | N/A | N/A | The app does not request, record, read, or transmit audio. |
| Files and docs | **No** | **No** | N/A | N/A | None | N/A | User-controlled | CSV/backup export and backup import are local, user-initiated document actions; the developer never receives the files. |
| Calendar | **No** | **No** | N/A | N/A | None | N/A | N/A | Shift dates are entered inside ProTip365; the app does not access the device calendar. |
| Contacts | **No** | **No** | N/A | N/A | None | N/A | N/A | The app does not request, read, or transmit contacts. |
| App activity | **Yes: App interactions only** | **No** | **No** | **Required / automatic** | **Analytics** | **Yes** | **No verified request path** | EAS Update records that an installation ran/downloaded an update for adoption metrics. No taps, screens, searches, notes, or shift activity are sent. Expo is a service provider, so this is not marked shared. |
| Web browsing | **No** | **No** | N/A | N/A | None | N/A | N/A | The app does not record browsing history; privacy, terms, and support links open only when the user chooses them. |
| App info and performance | **Yes: Crash logs and Diagnostics** | **No** | **No** | **Required / automatic** | **App functionality; Analytics** | **Yes** | **No verified request path** | EAS Update reports failed update installs/early crashes and update-service diagnostics. There is no general app crash-reporting SDK or transmission of user records. Expo is a service provider, so this is not marked shared. |
| Device or other IDs | **Yes** | **No** | **No** | **Required / automatic** | **App functionality; Analytics** | **Yes** | **No verified request path** | EAS Update sends a randomized per-installation token to deliver and measure updates. Expo says it is not a hardware or advertising ID. Expo is a service provider, so this is not marked shared. |

### EAS Update technical-data nuance

The top-level answer must be **Yes** while the submitted build has EAS Update enabled. `app/app.json`, `app/eas.json`, and the generated Android manifest configure an EAS Update URL, a release channel, `ENABLED=true`, and `EXPO_UPDATES_CHECK_ON_LAUNCH=ALWAYS`. Expo documents HTTPS update checks, a randomized installation token, operating-system information, update-adoption metrics, and failed-install counts.

This does **not** mean Defacto365 receives shift, employer, tip, wage, note, CSV, backup, passcode, or biometric data. Those remain local unless the user explicitly exports them. If the owner wants a truthful top-level **No**, EAS Update must be disabled in a future build and the final AAB must be re-audited before changing this declaration.

### CSV and encrypted-backup nuance

Do **not** mark CSV or encrypted-backup export as developer collection or sharing. The user explicitly starts the export, sees the Android share sheet, and chooses the destination. Google Play excludes transfers caused by a specific user-initiated action where the user reasonably expects sharing. A direct upload to the user's own Drive/storage that the developer never accesses is likewise not developer collection.

The exported CSV is plaintext and can contain employer names, shift details, wages, tips, sales, deductions, payouts, and notes. The full backup is password-encrypted. Once the user sends or saves either file outside ProTip365, deletion and transport security are controlled by the selected destination. **Erase All Local Data cannot delete copies already exported outside the app.** It also does not currently clear an already-created cached CSV or the local Play entitlement/trial record.

### Google Play Billing nuance

Select **No** for developer collection of payment information. Google Play collects payment details directly under Google's terms; ProTip365 never accesses card numbers or billing addresses. The app reads product, purchase, and subscription entitlement state through Play Billing and stores the resulting entitlement locally; it does not send purchase history or purchase tokens to a developer server.

## 2. Permissions justification

These are the three permissions explicitly listed in `app/app.json`:

| Declared Android permission | One-line justification |
|---|---|
| `android.permission.USE_BIOMETRIC` | Lets a user optionally unlock their local shift and earnings records with device biometrics. |
| `android.permission.USE_FINGERPRINT` | Provides compatibility for fingerprint-based local unlock on older supported Android devices. |
| `android.permission.POST_NOTIFICATIONS` | Lets a user opt in to locally scheduled post-shift reminders with generic, privacy-safe text. |

## 3. Content rating questionnaire

Use the questionnaire for **All Other App Types** and select the closest store category **Productivity**.

| Questionnaire topic | Recommended answer |
|---|---|
| Violence or graphic content | **No / None** |
| Sexual content or nudity | **No / None** |
| Profanity or crude humor | **No / None** |
| Alcohol, tobacco, or drugs | **No / None** — the app may be used by bartenders, but the app itself does not depict, sell, or encourage these products. |
| Fear, horror, or disturbing content | **No / None** |
| Gambling, simulated gambling, or real-money contests | **No / None** |
| User-to-user communication or public user-generated content | **No** — private notes and records are not published or exchanged inside the app. |
| Location sharing | **No** |
| Sharing personal information with other users | **No** |
| Digital purchases / in-app purchases | **Yes** — `lifetime_unlock` and the auto-renewing `monthly` subscription unlock write access through Google Play Billing. |
| Ads | **No** |

**Likely result:** **Everyone / PEGI 3 or regional equivalent.** The rating is assigned by IARC from the live questionnaire, so verify the generated certificate before publishing. A content rating suitable for everyone does not mean the app is directed at children.

## 4. Target audience and children

- **Target age group:** Select **18 and over** only.
- **Designed to appeal to children:** **No**.
- **Primarily child-directed:** **No**.
- **Families Policy badge/commitment:** **Do not select**; the app is not targeted to children.
- Do not enable a separate hard **Restrict Minor Access** control unless the owner intends to prevent every under-18 user from finding, installing, purchasing, or renewing. The product has no adult-only content that requires that restriction, but the owner must make the final under-18 policy decision.

## 5. Ads and financial features

### Ads declaration

**Select:** **No, my app does not contain ads.**  
**Reason:** There is no advertising SDK or ad placement in the current app.

### Financial features declaration

**Select:** **My app doesn't provide any financial features.**  
**Reason:** ProTip365 is a private productivity record for amounts the user enters about their own shifts. It does not provide banking, loans, earned-wage advances, payments/transfers, wallets, trading, credit monitoring, insurance, or personalized financial advice. Its estimated deductions/net figures are user-controlled estimates, not payroll, tax advice, or a regulated financial product. Google Play Billing purchases unlock app access and do not turn the app into a financial service.

## 6. Verify before submitting

- [ ] Confirm the AAB being declared was built from this audited code/commit, and that no other active Play artifact has different data practices. Play expects one declaration covering all active versions.
- [ ] In **App Bundle Explorer**, review the final merged manifest and SDK list; config plugins can add native permissions beyond the three explicitly listed in `app/app.json`.
- [ ] Confirm current `expo-iap`, EAS Update, and other bundled SDK Data Safety guidance for the exact release. Specifically verify whether Expo still collects app interactions, crash/failed-install signals, diagnostics, and a randomized installation token as declared above.
- [ ] Confirm with Expo whether an end user can request deletion of EAS Update tokens/metrics. Keep the Play deletion answer **No** unless a working process is established and documented.
- [ ] Confirm EAS/build environment variables do not inject analytics, crash reporting, advertising, a backend URL, or another network SDK.
- [ ] Confirm user-entered shift, employer, wage, tip, note, CSV, and backup data is never uploaded to Defacto365 or another developer-controlled service.
- [ ] Confirm the release still uses the generic reminder text and does not place employer names, tips, wages, or earnings on the lock screen.
- [ ] Confirm **Settings → Erase All Local Data** removes user-entered work and financial records on the submitted build. Do not claim it erases Expo metrics, Google purchase records, the entitlement/trial record, an existing cached CSV, or externally saved/shared exports.
- [x] Live privacy policy distinguishes local user records from billing and EAS Update technical traffic (published 2026-08-03).
- [ ] Confirm the privacy policy also covers: no account; SQLCipher local storage; user-initiated CSV/encrypted-backup sharing; local record deletion limits; and Google Play handling of purchases.
- [ ] Confirm `lifetime_unlock` and `monthly` are the products in the submitted build and complete the signed billing matrix before promoting enforced version `2.0.0` beyond testing.
- [ ] Owner decision: approve **18 and over** as the target audience and decide whether under-18 users are merely outside the target audience or must be technically blocked.
- [ ] Save the forms as drafts, review Google's generated Data Safety preview and IARC certificate, then submit only if they match this sheet.

## Sources checked

Repository evidence: `app/app.json`, `app/eas.json`, `app/package.json`, `app/android/app/src/main/AndroidManifest.xml`, `app/src/data/db.ts`, `app/src/data/backup.ts`, `app/src/domain/backup.ts`, `app/src/security/appLock.ts`, `app/src/notifications/shiftReminders.ts`, `app/src/i18n/en.ts`, `app/app/(tabs)/settings.tsx`, `app/app/backup.tsx`, `app/src/purchases/IapBootstrap.tsx`, `app/src/data/entitlementStorage.ts`, `app/src/domain/entitlements.ts`, and `app/src/ui/LockScreen.tsx`.

Google guidance reviewed on 2026-07-20:

- [Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Expo Privacy Policy](https://expo.dev/privacy)
- [Expo privacy explained](https://expo.dev/privacy-explained)
- [EAS Update: downloading updates and adoption metrics](https://docs.expo.dev/eas-update/download-updates/)
- [Content rating requirements for apps and games](https://support.google.com/googleplay/android-developer/answer/9859655)
- [Manage target audience and app content settings](https://support.google.com/googleplay/android-developer/answer/9867159)
- [Provide information for the Financial features declaration](https://support.google.com/googleplay/android-developer/answer/13849271)
