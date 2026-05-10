# RFP-114 Functional QA Pass

## Scope

- Branch: `codex/rfp-77-80-qa-readiness`
- Base implementation includes UX fixes through RFP-123 and security fixes through RFP-116.
- iOS runtime evidence: `/tmp/protip365-qa/rfp114-ios-launch.png`
- Android runtime evidence: `adb devices` returned no connected device.

## Environment

- iOS Simulator: iPhone 16, iOS 18.6, booted.
- Expo command used:
  - `EXPO_PUBLIC_SUPABASE_URL=https://example.supabase.co EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=dummy npx expo start --ios --localhost`
- Android: blocked because no ADB device/emulator was attached.
- Simulator accessibility automation: blocked because Computer Use could not attach to Simulator (`cgWindowNotFound`). iOS launch and screenshot evidence were still captured with `xcrun simctl io booted screenshot`.

## Functional Coverage

### Onboarding

- First-run route displays onboarding before tabs.
- Screenshot evidence captured.
- CTA coverage reviewed in source:
  - `Log first shift`
  - `Plan a shift instead`
- Returning-user skip behavior implemented through SecureStore-backed `isOnboardingComplete`.

Status: Pass with source verification and launch screenshot.

### Today / Daily Entry

- Today summary renders take-home and real hourly.
- Add shift opens daily entry.
- Fields reviewed:
  - Date masked as `YYYY-MM-DD`.
  - Start/end masked as `HH:mm`.
  - Hours, hourly rate, sales, cash tips, card tips, tip-out, other income use numeric keyboard.
  - Tip-out method and basis use segmented controls.
  - Notes accepts free text.
- Validation source coverage exists for date, required hours/hourly rate, numeric amounts, and non-negative amounts.
- Save confirmation persists and displays on Today after navigation.

Status: Pass by source, tests, and export.

### Add / Planned Shift

- Add tab exposes Add shift, Add planned shift, and Add income.
- Planned shift fields reviewed:
  - Date, start, end, expected hours, hourly rate, employer, notes.
- Negative status actions are available only when editing an existing planned shift.
- Planned status rows route back to planned-shift edit.

Status: Pass by source, tests, and export.

### Calendar / History

- Calendar rows are grouped by date.
- Rows include date/time context, status chip, subtitle, and edit affordance.
- Completed records route to daily entry edit.
- Planned, missed, and did-not-work records route to planned-shift edit.

Status: Pass by source, tests, and export.

### Reports

- Reports home displays current period and report navigation.
- Weekly, monthly, and yearly reports have Previous/Next controls.
- Empty period state suppresses noisy zero metric grid.
- Insight card appears per period.

Status: Pass by source, tests, and export.

### Settings / Account Lifecycle

- Settings groups:
  - Account
  - Subscription
  - Work defaults
  - App preferences
  - Support
  - Legal
- Account deletion requires a confirmation click before local clear/request flow.
- Support/privacy/terms links are present.

Status: Product UI pass; public URL verification failed under RFP-139.

### Paywall

- Sandbox/debug products are removed from production UI.
- Free vs Premium comparison is present.
- Primary trial CTA, restore action, status states, and legal footer are present.
- Core logging is not blocked by paywall.

Status: Pass by source and export. Native purchase checkout remains store-product work.

## Verification Commands

- `npm test`
- `npm run typecheck`
- `npx expo-doctor`
- `npm audit --json`
- `npx expo export --platform all --output-dir /tmp/protip365-rfp121-123-export`
- iOS runtime launch via Expo Go.

## Bugs Opened

- RFP-139: Store blocker: ProTip365 privacy, terms, and deletion URLs resolve to suspended page.

## Result

No app-code Critical/High/Medium functional bugs were found in the implemented shared app flows. Store submission remains blocked by RFP-139 and by the absence of real native store-product checkout/build evidence.
