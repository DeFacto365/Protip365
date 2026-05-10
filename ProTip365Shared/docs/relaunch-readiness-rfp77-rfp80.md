# RFP-77/RFP-80 Relaunch Readiness

## App Store Checklist

| Item | Status | Evidence |
| --- | --- | --- |
| App status | Blocked | App is local/shared Expo implementation, not ready for store submission until RFP-139 and native purchase setup are complete. |
| Bundle ID | Ready | `app.json` uses existing native identifier `com.protip365.monthly`. |
| Subscription products | Blocked | Sandbox model exists; real App Store products must be created. |
| Privacy labels | Blocked | Final data collection policy must match Supabase/account/subscription implementation. |
| Screenshots | Partial | UX screenshot strategy documented in RFP-75; final screenshots must be captured after release build. |
| Description | Drafted | RFP-75 contains short and long description draft. |
| Support URL | Blocked | Current domain resolves to suspended page for public URLs; support email exists in app. |
| Privacy URL | Blocked | RFP-139. |
| Account deletion | Blocked | App request flow exists; public deletion URL fails under RFP-139. |
| Age rating | Pending | No restricted content identified; final App Store Connect questionnaire still required. |
| Review notes | Pending | Include free logging, premium planned products, account deletion flow, and test credentials when backend auth is final. |

## Google Play Checklist

| Item | Status | Evidence |
| --- | --- | --- |
| Package name | Ready | `app.json` uses existing native identifier `com.protip365.monthly`. |
| Signing | Missing | No EAS/Play signing evidence in repo. |
| Subscription products | Blocked | Real Google Play subscriptions must be created. |
| Data safety | Blocked | Must match final Supabase/account/subscription data flow. |
| Screenshots | Partial | RFP-75 screenshot story exists; final Android screenshots require emulator/device. |
| Description | Drafted | RFP-75 contains store copy draft. |
| Support URL | Blocked | Public domain issue under RFP-139. |
| Privacy URL | Blocked | RFP-139. |
| Account deletion | Blocked | Public deletion URL fails under RFP-139. |
| Testing tracks | Pending | Requires Play Console project and signed Android build. |
| Review notes | Pending | Include premium behavior, account deletion, privacy URL, and test account once backend is final. |

## Internal Release Candidate Evidence

- Tests passed: `npm test`.
- TypeScript passed: `npm run typecheck`.
- Expo doctor passed: `npx expo-doctor`.
- Audit passed after security fix: `npm audit --json` reported zero vulnerabilities.
- Export/build smoke passed:
  - `/tmp/protip365-rfp118-120-export`
  - `/tmp/protip365-rfp121-123-export`
  - `/tmp/protip365-security-fixes-export-final`
  - `/tmp/protip365-rfp77-80-export-final`
- iOS launch screenshot:
  - `/tmp/protip365-qa/rfp114-ios-launch.png`
- Android runtime:
  - Blocked because no ADB device/emulator was attached.

## Store Blockers

- RFP-139: Public privacy, terms, and account deletion URLs resolve to suspended hosting page and fail TLS validation without `-k`.
- Real iOS and Android subscription products are not configured.
- Signed release builds are not produced yet.

## Release Notes Draft

ProTip365 shared mobile rebuild now includes:

- First-run onboarding.
- Daily shift/tip entry with grouped fields, validation, and save confirmation.
- Planned shift and missed/did-not-work behavior.
- Today, weekly, monthly, yearly reports with period controls and insights.
- Calendar/history correction flows.
- Production-style paywall shell and subscription status UI.
- Settings grouped into account, subscription, work defaults, preferences, support, and legal.
- Security fixes for account deletion, support email HTML escaping, local secure storage, password reset token storage, email enumeration, and PostCSS advisory.

## Decision

Do not submit to either store yet. The shared app is functionally implemented and build-exportable, but store submission is blocked by public compliance URLs, native product setup, native package identifiers, and signed release builds.
