# RFP-75 Paywall, Onboarding, and Store Screenshot Strategy

## Decision

Do not sell ProTip365 as a generic budgeting app. Position it as the fast shift-income tracker for servers, bartenders, and tipped restaurant staff who need daily tips, tip-out, hourly pay, and period reports in one mobile app.

## Onboarding

### Target Flow

1. Welcome:
   - Promise: track shift income in under a minute.
   - Primary CTA: Get started.
2. Work defaults:
   - Currency/locale.
   - Default hourly rate.
   - Optional default tip-out percent or amount when supported.
3. Reporting goal:
   - Optional weekly or monthly take-home target.
   - Skip allowed.
4. First useful action:
   - CTA: Log first shift.
   - Secondary CTA: Plan a shift.

### Rules

- Returning users skip onboarding after completion.
- Users can edit defaults later from Settings.
- Onboarding should not ask for subscription payment.
- Account creation should be allowed after the user sees the value, unless backend sync requires sign-in at launch.

### Implementation Backlog Mapping

- Main implementation issue: RFP-123.
- Settings dependency: RFP-120 for editing defaults after onboarding.

## Paywall

### Timing

Use a soft-paywall model:

- Free users can log shifts and see basic today/current-week totals.
- Premium is prompted when users try advanced value:
  - historical weekly/monthly/yearly reports beyond a limited window,
  - export,
  - cloud sync or account backup,
  - advanced targets/insights,
  - widgets if implemented later.

Avoid showing the paywall before the first shift is logged.

### Screen Structure

- Header: `ProTip365 Premium`.
- Subhead: keep every shift, report, and export in one place.
- Plan comparison:
  - Free: daily shift logging, current period summary, local history limit.
  - Premium: full history, weekly/monthly/yearly reports, export, backup/sync, targets/insights.
- Primary CTA: Start free trial or Continue with Premium.
- Secondary CTA: Restore purchases.
- Legal footer: terms, privacy, auto-renewal text.
- Error/loading states: purchase loading, purchase failed, restore failed, entitlement restored.

### Copy Rules

- Remove sandbox/debug language from production UI.
- Avoid vague value props like "unlock powerful analytics".
- Use concrete service-worker language:
  - "Know what you took home this week."
  - "Track tips, tip-out, hourly pay, and sales."
  - "Fix missed or changed shifts from history."
  - "Export your income records when needed."

### Implementation Backlog Mapping

- Main implementation issue: RFP-118.
- Subscription wiring dependencies: existing subscription sandbox work, then real store products.

## Store Screenshot Story

### Screenshot Order

1. Daily entry:
   - Caption: `Log tips, tip-out, wages, and sales fast.`
   - Show the redesigned form with net take-home preview.
2. Today dashboard:
   - Caption: `See today's take-home at a glance.`
   - Show completed shift summary and totals.
3. Weekly report:
   - Caption: `Know what you made this week.`
   - Show period controls, totals, and one insight card.
4. Calendar/history:
   - Caption: `Find and fix any shift.`
   - Show status chips for completed, planned, missed, did not work.
5. Premium/export:
   - Caption: `Keep full history and export when needed.`
   - Show clean premium feature list, not payment debug data.

### Visual Rules

- Use real app screens, not abstract marketing graphics.
- Show phone-framed screenshots for store assets, but do not use fake data that looks impossible.
- Include both light and dark only if the app supports both well; otherwise keep one polished theme.
- Avoid claims about tax filing unless export/tax behavior is implemented and legally reviewed.

## Relaunch Copy Changes

### App Store / Google Play Short Description

`Track daily tips, tip-out, wages, sales, and take-home income from every shift.`

### Long Description Opening

`ProTip365 helps servers, bartenders, and tipped workers record shift income quickly and review what they actually took home by day, week, month, and year.`

### Keywords / Themes

- tip tracker
- server tips
- bartender income
- tip-out
- shift income
- take-home pay
- restaurant worker

## Required Layout Changes Before Relaunch

- Replace production paywall UI per RFP-118.
- Add first-run onboarding per RFP-123.
- Replace Settings placeholder structure per RFP-120.
- Ensure screenshots are captured after RFP-119, RFP-121, and RFP-122 are implemented.
- Replace placeholder privacy/terms/support URLs before store submission.

## Deferred

- Referral program.
- Employer/team tip pool workflows.
- Payroll/paycheck reconciliation.
- Tax advice positioning.
- Web landing page.
