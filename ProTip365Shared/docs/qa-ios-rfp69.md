# RFP-69 iOS QA Walkthrough

## Environment

- Platform: iOS simulator.
- Device: iPhone 16, iOS 18.6, UDID `0A219D13-E1E6-4723-A222-A5DCCE3C507A`.
- Branch: `codex/rfp-69-ios-qa`.
- Evidence screenshot: `/tmp/protip365-qa/ios-rfp69-launch.png`.

## Commands Run

- `xcrun simctl boot 0A219D13-E1E6-4723-A222-A5DCCE3C507A`
- `npx expo start --ios --non-interactive`
- `xcrun simctl io booted screenshot /tmp/protip365-qa/ios-rfp69-launch.png`
- `npm test`
- `npm run typecheck`
- `npx expo-doctor`
- `npx expo export --platform all --output-dir /tmp/protip365shared-rfp69-export`

## Result Summary

- Passed:
  - iOS simulator booted.
  - Expo Go installed/launched.
  - Metro bundled the app for iOS.
  - Screenshot evidence was captured.
  - Unit/type/export verification passed.
- Blocked:
  - Full page-by-page iOS interaction was blocked because Expo Go opened the developer sheet over the app after launch.
  - `ProTip365Shared/.env.local` was not present in this worktree, so configured Supabase auth flow was not exercised.
- Failed:
  - No concrete product bug found from the available iOS evidence.
- Not applicable:
  - Native StoreKit purchase flow is not available until an IAP development build and store products are configured.
  - Export workflow is not implemented yet.

## Checklist Status

- Onboarding: Blocked by Expo Go developer sheet.
- Auth shell: Blocked for configured auth because `.env.local` was absent; missing-config behavior is covered by build/export.
- Today: Blocked by Expo Go developer sheet.
- Add shift: Blocked by Expo Go developer sheet.
- Add planned shift: Blocked by Expo Go developer sheet.
- Missed/did-not-work: Blocked by Expo Go developer sheet.
- Calendar: Blocked by Expo Go developer sheet.
- Reports: Blocked by Expo Go developer sheet.
- History: Blocked by Expo Go developer sheet.
- Settings/support/privacy/deletion: Blocked by Expo Go developer sheet.
- Paywall/subscription sandbox: Blocked by Expo Go developer sheet; model covered by unit tests.

## Bug Filing

No Bug issue created. The blocker is environmental/runtime access, not a verified app defect.
