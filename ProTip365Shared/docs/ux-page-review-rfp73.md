# RFP-73 Page-by-Page Mobile UX Review

## Review Basis

- Source reviewed: current `ProTip365Shared` Expo React Native implementation.
- Runtime screenshot evidence available:
  - iOS launch evidence: `/tmp/protip365-qa/ios-rfp69-launch.png`
  - Android emulator blocker log: `/tmp/protip365-qa/android-emulator.log`
- Limitation: full interactive simulator walkthrough was blocked by Expo Go developer sheet on iOS and Android emulator availability. This review is source-based with available launch evidence.

## Ranked Findings

### P0: Paywall Is Not Production-Usable

- Screens/files: `src/features/entitlements/EntitlementScreens.tsx`
- Issue: Paywall renders sandbox products, simulated purchase status, and entitlement debug text directly in the user UI. It also lacks a purchase CTA, restore action, price hierarchy, legal footer, and production loading/error states.
- Impact: Release blocker. Users would see internal testing language and cannot actually understand or start a premium plan.
- Recommendation: Replace debug card with production paywall: Free vs Premium comparison, primary CTA for trial/monthly/annual, secondary Restore purchases, legal footer, and value props tied to reports/export/sync. Keep sandbox diagnostics behind a dev-only flag.
- V1: Blocker.

### P0: Daily Entry Is Too Raw For Fast Mobile Use

- Screens/files: `src/features/dailyEntry/DailyEntryScreen.tsx`
- Issue: The form exposes all fields in one long scroll with plain text date/time inputs, equal field weight, and no sticky save/preview. Save immediately pops the screen, so the saved confirmation is effectively invisible.
- Impact: Waiters entering tips after a shift need speed. Raw text fields and long forms increase errors and abandonment.
- Recommendation: Use native date/time pickers or masked inputs, split into Shift/Tips/Tip-out/Notes sections, visually de-emphasize optional fields, add sticky bottom save/preview, and show confirmation on the destination screen.
- V1: Blocker.

### P0: Settings Is Compliance Plumbing, Not A Settings Experience

- Screens/files: `src/screens/PlaceholderScreens.tsx`, `src/features/account/SettingsComplianceScreen.tsx`
- Issue: Settings only shows Plan plus Account compliance actions. It does not expose account identity, subscription controls, work defaults, app preferences, language/currency, employer settings, or tip-out defaults.
- Impact: Users cannot configure the app around their job, and destructive account deletion is too easy to trigger.
- Recommendation: Add grouped settings: Account, Subscription, Work defaults, App preferences, Support, Legal. Move compliance links under Legal, remove developer phrasing, and gate account deletion behind a confirmation sheet.
- V1: Blocker.

### P1: History Does Not Show Strong Correction Context

- Screens/files: `src/features/reports/ReportScreens.tsx`, `src/features/history/historyViewModel.ts`
- Issue: History rows can navigate to edit, but visual distinction between completed/planned/missed is light.
- Impact: Corrections are a core workflow; wrong edit target is costly.
- Recommendation: Add status color, income/time summary, and clear edit affordance per row.
- V1: Yes.

### P1: Calendar Is A List, Not A Calendar-Like Review Surface

- Screens/files: `src/features/plannedShift/PlannedShiftScreen.tsx`
- Issue: Calendar is currently a chronological list. It has status labels but no date grouping or quick scan pattern.
- Impact: Users cannot quickly see worked/missed/future days.
- Recommendation: Group by date and add compact status chips before a true calendar grid is built.
- V1: Yes.

### P2: Reports Need Period Controls

- Screens/files: `src/features/reports/ReportScreens.tsx`
- Issue: Weekly/monthly/yearly screens are anchored to today only. There is no previous/next period control.
- Impact: Historical review is limited.
- Recommendation: Add previous/next period controls and display period range consistently.
- V1: Yes.

### P2: Settings Compliance Links Use Placeholder URLs

- Screens/files: `src/features/account/accountLifecycle.ts`, `docs/account-compliance.md`
- Issue: Privacy and terms URLs are placeholders.
- Impact: Store review blocker.
- Recommendation: Replace with live public URLs and validate links.
- V1 before submission.

### P2: Empty States Are Functional But Not Action-Oriented Enough

- Screens/files: Today, Calendar, Reports, History
- Issue: Empty states explain absence but do not always include a direct action.
- Impact: First-run users need a clear first useful action.
- Recommendation: Add primary CTA in empty states: Add shift or Add planned shift.
- V1: Yes.

### P2: Planned Shift Status Actions Are Visually Unsafe

- Screens/files: `src/features/plannedShift/PlannedShiftScreen.tsx`
- Issue: Did not work and Missed actions are always visible on add/edit, styled like neutral secondary actions, and can save a new planned shift directly into a negative status.
- Impact: User can accidentally create negative-status shifts and lose expected income context.
- Recommendation: Show status actions only for existing planned shifts, separate them from Save, use status-specific styling/copy, and confirm destructive/negative state changes.
- V1: Yes.

### P2: Secondary Stack Screens Lack Visible Back/Cancel

- Screens/files: `src/navigation/AppNavigator.tsx`
- Issue: Stack headers are hidden globally. Form/report screens rely on gestures or save-only completion.
- Impact: Users may not see how to cancel or back out of add/edit flows.
- Recommendation: Add screen-level top row or app header for secondary screens with Back/Cancel and contextual title. Keep tab roots headerless if desired.
- V1: Yes.

### P2: Reports Are Metric-Heavy But Insight-Light

- Screens/files: `src/features/reports/ReportScreens.tsx`
- Issue: Reports show repeated metric grids without insight summary, best/worst shift, trend, or drill-down context.
- Impact: Users get numbers but limited guidance.
- Recommendation: Add one insight card per period, target progress explanation, and shift list preview linking to history. Defer charts until enough data exists.
- V1: Basic insight yes; charts deferred.

### P2: Scaffold Needs Better Bottom-Safe-Area And Keyboard Ergonomics

- Screens/files: `src/components/AppScaffold.tsx`
- Issue: SafeAreaView uses top edge only and fixed bottom padding while tab height is fixed. Long forms and future sticky CTAs may collide on device variants.
- Impact: Form ergonomics and bottom navigation reliability risk.
- Recommendation: Include bottom safe area for scroll content, add keyboard-aware form behavior, and support sticky bottom actions.
- V1: Yes.

### P3: Onboarding Is Still A Placeholder

- Screens/files: `src/screens/PlaceholderScreens.tsx`, navigation root onboarding route
- Issue: Onboarding route exists but is not a real first-run setup.
- Impact: Lower conversion and less guidance.
- Recommendation: Add minimal onboarding: language/default hourly rate/first action.
- V1 if time; otherwise launch can start on Today.

### P3: Form Field Labels Are English-Only

- Screens/files: daily entry, planned shift, reports, settings
- Issue: New UX strings are hardcoded English despite localization foundation.
- Impact: Breaks bilingual goal.
- Recommendation: Move user-facing strings into localization once UI stabilizes.
- V1 if bilingual launch is still required.

## Summary

Top UX fixes before final release:

1. Make daily entry faster and sectioned.
2. Replace sandbox paywall with production paywall.
3. Turn Settings into real user settings, not just compliance links.
4. Improve calendar/history correction clarity.
5. Add report period navigation.
6. Replace compliance placeholder URLs.
