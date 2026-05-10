# Autonomous QA Checklist

This checklist is for an agent to execute without user testing.

## Evidence Format

For every failed or blocked item, record:

- Platform: iOS or Android.
- Build/source: branch, commit SHA, command used.
- Screen/workflow.
- Expected result.
- Actual result.
- Severity: Critical, High, Medium, Low.
- Reproduction steps.
- Screenshot or log path.
- Retest status: Not retested, Passed, Failed, Blocked.

## Environment

- Run from `ProTip365Shared`.
- Install dependencies with `npm install` if needed.
- Run `npm test`.
- Run `npm run typecheck`.
- Run `npx expo-doctor`.
- Run `npx expo export --platform all --output-dir /tmp/protip365shared-qa-export`.
- Launch iOS simulator or document exact blocker.
- Launch Android emulator or document exact blocker.

## Screens

- Onboarding: opens, text fits, no blocked first useful action.
- Auth shell: missing config produces clear setup error; configured env does not expose secrets.
- Today: empty state, add shift, saved shift summary, edit saved shift.
- Add shift: validation, save, edit, tip-out method/basis, notes, decimal inputs.
- Add planned shift: validation, save, edit, future/today/past dates, expected hours.
- Missed/did-not-work: status actions, restore planned, no income corruption.
- Calendar: planned/completed/missed/did-not-work indicators, past/future order, edit navigation.
- Reports: Today, weekly, monthly, yearly summaries, empty states, metric readability.
- History: saved records, ordering, edit navigation.
- Settings: plan status, support link, privacy link, terms link.
- Account deletion: request flow, local data clearing, failure message.
- Paywall: free/premium copy, sandbox products, trial state.

## Core Workflows

1. Log a completed shift with hours, hourly rate, sales, cash tips, card tips, tip-out, other income, and notes.
2. Edit that shift and verify reports update.
3. Add a future planned shift.
4. Mark planned shift missed.
5. Restore it to planned.
6. Mark it did-not-work.
7. Verify calendar/history status indicators and edit routes.
8. Verify reports show totals and empty states correctly.
9. Verify subscription sandbox success, cancel, and error states where UI exposes them.
10. Verify support/privacy/terms/deletion actions handle success and failure safely.

## Store/Compliance

- Export is not implemented yet; mark Not Applicable until an export issue lands.
- Real StoreKit / Google Play purchase is blocked until native IAP module, store products, tester accounts, and development build are configured.
- Privacy/terms URLs must be replaced with live public pages before submission.

## Bug Filing Rules

- Create Linear Bug issues for concrete failures only.
- Include exact branch/commit and reproduction steps.
- Do not file duplicate bugs; link retest evidence to the original issue.
