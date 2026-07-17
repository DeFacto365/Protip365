# ProTip365 V4 — Linear-ready backlog

Date: 2026-07-17
Target project: [ProTip365](https://linear.app/defacto365/project/protip365-e3ed5a412e11/overview)

Linear could not be updated during discovery because the connected account returned an expired OAuth grant. This backlog is ready to enter after reauthentication.

## Recommended project milestones

1. **M0 — Product validation**
2. **M1 — Secure local foundation**
3. **M2 — Phase I core app**
4. **M3 — Private beta**
5. **M4 — Public launch**
6. **M5 — Cloud Sync (Coming Soon)**

Recommended labels:

- `area:product`
- `area:mobile`
- `area:backend`
- `area:ux`
- `area:growth`
- `area:legal`
- `area:qa`
- `type:research`
- `type:security`
- `platform:android`
- `platform:ios`
- `priority:blocker`

## M0 — Product validation

### V4-001 — Lock the confirmed product vocabulary and boundary

Priority: blocker
Area: product

Acceptance:

- Record the confirmed model: the local device user is the employee and creates one or more employers.
- Confirm that ProTip365 manages the user's personal schedule, not other employees.
- Canonical terms are approved: employer, role, default rate, role rate, scheduled shift, actual result, direct tips, pooled tips, tip-pool contribution, tip-out paid, tip-share received, expected payout, pending payout, actual received, variance, and effective hourly.

### V4-002 — Interview 20 screened tipped workers

Area: product
Type: research

Acceptance:

- Recruit primarily servers/bartenders working at least two tipped shifts weekly.
- Include multiple ages, genders, Android/iOS users, and single/multiple employers.
- Capture how schedules arrive, how multiple employers are combined, current conflict handling, actual-entry habits, and trust concerns.
- Report whether the Gate 1 thresholds in `Docs/PRD_V4.md` are met.

### V4-003 — Run a two-week schedule-and-actuals diary

Area: product
Type: research

Acceptance:

- At least 10 interview participants join.
- Record when schedules arrive, how shifts change, and when/why actual completion is skipped.
- Identify the minimum fields and accelerators for entering a full week and completing a shift.

### V4-004 — Prototype multi-employer scheduling and shift completion

Area: ux

Acceptance:

- Prototype covers language detection, optional passcode, employer setup, entering several shifts, switching employers, weekly calendar, overlap warning, shift completion, expected-versus-actual result, correction, and export.
- Test with at least 10 target users.
- At least 90% create two employers and a week of shifts without help.
- Median typical-week entry is under two minutes.
- Median planned-shift completion is 30 seconds or less.

### V4-005 — Decide launch geography, age policy, currency, and languages

Priority: blocker
Area: product/legal

Acceptance:

- Canada/United States launch scope documented.
- Minimum age and consent approach documented.
- English, Canadian French, and neutral Latin American Spanish are confirmed for Phase I.
- Launch currencies and regional formatting are documented independently from language.
- Privacy/legal review requirements assigned.

### V4-006 — Approve V4 positioning and monetization test

Area: growth

Acceptance:

- Approve or revise “Plan every shift. Know what it actually paid.”
- Validate the confirmed 30-day trial and USD $19.99 one-time local unlock.
- Present future Cloud Sync as `Coming Soon` at a planned USD $2.99/month.
- No paid acquisition is approved before retention gate.

### V4-007 — Define Phase I payout-reconciliation semantics

Area: product
Type: research

Acceptance:

- Define when expected payout becomes known and how the user updates it.
- Define cumulative actual received, partial receipt, pending balance, received, and disputed states.
- Distinguish earned income from money actually received.
- Test terminology with users without making payroll or tax-filing claims.

## M1 — Secure local foundation

### V4-101 — Recover and review the completion-loop branch

Priority: blocker
Area: mobile

Acceptance:

- Create a dedicated V4 foundation branch from `main`.
- Review the six commits on `origin/codex/protip365-completion-loop`.
- Preserve useful refactors, tests, CRUD, reset flow, and assets.
- Resolve conflicts deliberately; do not merge directly to `main`.
- Record accepted/rejected changes.

### V4-102 — Normalize Expo dependencies and CI checks

Area: mobile/qa

Acceptance:

- Expo doctor passes.
- Typecheck and all tests pass.
- Android and iOS exports/builds pass.
- No critical/high dependency vulnerability remains.
- CI runs these checks on every pull request.

### V4-103 — Preserve the existing Supabase project for future migration

Priority: blocker
Area: backend

Acceptance:

- Export schema, grants, policies, functions, migration metadata, and aggregate row counts.
- Create and verify a restorable snapshot.
- Document which existing rows must eventually be imported into the local model.
- Freeze remote mutations; Supabase is not used by the Phase I app runtime.

### V4-104 — Design the encrypted SQLite schema and migration runner

Priority: blocker
Area: backend

Acceptance:

- SQLite schema covers profiles, employers, roles, scheduled shifts, actuals, payouts, settings, and migration history.
- Stable UUIDs and `created_at`, `updated_at`, `deleted_at`, `version`, and `origin_device_id` metadata are included.
- Foreign keys, uniqueness, checks, and indexes enforce the PRD model.
- Transactional migrations upgrade from every released schema version.
- Tests reproduce a clean database and upgrade fixtures.

### V4-105 — Implement SQLite repositories and local transactions

Priority: blocker
Area: mobile/backend

Acceptance:

- UI and domain code use repository interfaces rather than Supabase directly.
- `expo-sqlite` is the Phase I source of truth.
- Create, update, copy-forward, completion, payout, missed/cancelled, soft-delete, and restore operations are transactional.
- All Phase I workflows work with airplane mode enabled.
- Existing direct Supabase calls are removed from Phase I screens.

### V4-106 — Implement SQLCipher, passcode, and biometrics

Priority: blocker
Area: mobile
Type: security

Acceptance:

- SQLCipher is enabled on Android and iOS production-like builds.
- Random database key is stored in the operating-system keychain/keystore.
- Optional six-digit passcode and biometrics gate access to the key.
- Failed attempts are rate-limited.
- Biometric and recovery-key fallback are tested.
- No recovery path silently weakens encryption.

### V4-107 — Implement encrypted backup, restore, and local erase

Priority: blocker
Area: mobile
Type: security

Acceptance:

- Full `.protip365` backup preserves canonical records and schema version.
- Backup is encrypted with a portable recovery secret, not only a device-held key.
- Restore validates version, integrity, duplicates, and relationships before commit.
- CSV export is separate and human-readable.
- Erase All Local Data removes database, keys, drafts, and local preferences as documented.
- Cross-device restore tests pass on Android and iOS.

### V4-108 — Define canonical scheduled-versus-actual domain model

Priority: blocker
Area: mobile/backend

Acceptance:

- Statuses and allowed transitions match the PRD.
- Calculation formulas and rounding are shared and tested.
- Scheduled and actual time/rate/currency/timezone snapshots are separate and defined.
- Employer default rate and employer-scoped role overrides are defined.
- Planned shifts do not contribute earnings.
- Missing expected tips are not treated as zero.
- Direct tips, pool contribution, tip-share received, tip-out paid, expected payout, actual received, and pending payout formulas are tested.
- Overnight and daylight-saving rules are documented.

### V4-109 — Implement atomic, idempotent local shift completion

Priority: blocker
Area: mobile/backend

Acceptance:

- One exclusive SQLite transaction requires the planned shift, preserves scheduled values, upserts reported actual start/end, actual breaks, tip flows, initial payout values, and marks it worked.
- It accepts a unique idempotency key.
- Retrying cannot create duplicate records.
- Transaction failure leaves no partial result.
- It returns expected, actual, payout, variance, and effective-hourly totals.
- Relationship, rollback, duplicate, and malformed-input tests pass.

### V4-110 — Define local access recovery and data-retention behavior

Priority: blocker
Area: mobile/legal

Acceptance:

- Phase I contains no account, email login, or password reset.
- Passcode setup clearly explains biometric/recovery-key options and unrecoverable-data risk.
- Reset without recovery erases local data only after explicit confirmation.
- Soft-deletion retention and permanent-purge timing are documented.
- Privacy copy accurately explains local-only storage and user-initiated exports.

## M2 — Phase I core app

### V4-201 — Build first-session onboarding

Area: mobile/ux

Acceptance:

- First launch reaches onboarding without account creation.
- Device language is detected with English fallback.
- User can select English, Canadian French, or Spanish.
- Optional passcode/biometric setup appears before employer setup.
- Employer name and default hourly rate are required.
- Currency is confirmed from the user profile.
- Initial role and reminder are optional.
- Existing local users are not sent through onboarding again.
- Add Scheduled Shift follows immediately.

### V4-202 — Build employer management

Area: mobile

Acceptance:

- Create, edit, archive, and choose default employer.
- Employer creation requires name and default hourly rate.
- Optional location label, color, and employer/role break-plan overrides are supported.
- Settings provides a global fallback break plan; each preset includes label, optional typical start, duration, and paid/unpaid status.
- Settings supports a user-entered estimated deduction-rate fallback with optional employer/role overrides.
- Create employer-scoped roles with role-specific hourly rates.
- Selected role rate overrides the employer default.
- Planned shifts snapshot the selected rate so later changes do not rewrite history.
- Historical shifts remain valid when an employer is archived.
- Multiple employers are a core free capability.
- No employee roster or employer-facing account exists.

### V4-203 — Build fast planned-shift entry

Priority: blocker
Area: mobile/ux

Acceptance:

- Creates shifts ahead of time with employer, optional role, date, scheduled start/end, break, and snapshotted expected rate.
- Supports optional expected tips and other income so expected gross and estimated net are calculated only from known values.
- Supports save-and-add-another and duplicate for entering a full schedule quickly.
- Copies a selected shift, one employer's schedule, or a full week forward by one or more weeks.
- Copy preview shows destination dates, employer/role/rate snapshots, duplicates, and overlaps.
- Copying includes planned fields only and never copies actual hours, tips, payouts, worked status, or completion notes.
- User can skip or replace individual conflicts before confirmation.
- Keeps employer, role, rate, and multiple break defaults when appropriate.
- Supports overnight shifts and warns about cross-employer overlaps.
- Draft survives interruption.
- Retry cannot create a duplicate planned shift.

### V4-204 — Build planned-shift completion and unplanned fallback

Area: mobile/ux

Acceptance:

- Opens from an existing planned shift and displays scheduled values.
- Prefills scheduled start/end and lets the user confirm or report different actual start/end times to the minute.
- Prefills every scheduled/default break and lets the user mark it taken, change its start/duration, or add another paid or unpaid break.
- Records rate, direct/pooled/mixed tip method, direct tips, pool contribution, tip-share received, tip-out paid, expected payout, actual payout received, and optional details.
- Prefills the estimated deduction rate from role, employer, or global settings and lets the user override it for that shift.
- The app does not provide live clock-in/out, attendance inference, or location-based time tracking.
- One action saves actuals and marks the shift worked.
- Never overwrites original scheduled values.
- Supports an explicitly labeled unplanned worked shift as a fallback.
- Instrumented completion duration is measurable.

### V4-205 — Build the weekly Schedule experience

Area: mobile/ux

Acceptance:

- Week calendar is the default planning surface.
- All employers appear together with accessible labels, not color alone.
- Today, upcoming shifts, actuals pending, and conflicts are clear.
- Add, duplicate, edit, cancel, miss, and complete are available in context.
- “Mark not worked” requires a reason and preserves the original schedule.
- Past and future week navigation works.
- Empty, loading, offline, and retry states are complete.

### V4-206 — Build schedule history and shift detail

Area: mobile/ux

Acceptance:

- Planned and completed shifts appear in calendar and list history.
- Filter by date, employer, and status.
- Detail shows scheduled values, actual values, variance, and exact calculation breakdown.
- Edit and delete work.
- Planned/missed/cancelled records never inflate earnings.

### V4-207 — Build expected-versus-actual stats

Area: mobile

Acceptance:

- Shows scheduled versus actual hours and base wages, variance, direct tips, pool contributions, tip-share received, tip-out paid, net tip income, other income, actual gross earnings, estimated deductions, estimated net earnings, expected payout, actual payout received, pending payout, and effective hourly.
- Supports week, month, employer, and all-employer views.
- Supports employer and role comparisons using historical rate snapshots.
- Missing expected tips remain unknown rather than becoming zero.
- Expected estimated net appears only when every included expected component is known.
- Expected-total variance appears only when the compared totals are valid.
- Uses completed/worked records only for actual earnings.
- Empty/partial periods are represented accurately.
- No rolling-query cap silently removes data.

### V4-208 — Implement locale-safe money, time, and currency handling

Priority: blocker
Area: mobile/backend

Acceptance:

- Decimal comma and decimal point inputs work by locale.
- Currency code is not hardcoded to USD.
- Overnight shifts, multiple breaks, and paid versus unpaid break calculations work correctly using integer minutes.
- Tests cover launch locales and daylight-saving boundaries.
- Estimated deduction percentages accept locale-safe input and are stored as integer basis points from 0 to 10,000.

### V4-209 — Implement local drafts and crash-safe recovery

Area: mobile

Acceptance:

- Unsaved form data survives app restart.
- Local saves use idempotency keys and transactions.
- User sees pending, failed, and confirmed states.
- Tests simulate app termination and database errors at each save stage.
- No network queue is required in Phase I.

### V4-210 — Add privacy-safe product analytics

Area: product/mobile

Acceptance:

- Implements the PRD event list.
- No amounts, employer names, schedules, notes, or financial content are sent.
- Consent/disclosure matches launch jurisdiction.
- Planning activation, completed-loop activation, schedule-entry time, completion time, shift coverage, and retention are reportable.

### V4-211 — Complete accessibility pass

Area: ux/qa

Acceptance:

- WCAG AA contrast.
- Dynamic type does not clip totals/forms.
- Screen-reader flow is complete.
- Status is not color-only.
- Touch targets and keyboard behavior meet requirements.
- Android and iOS accessibility checks pass.

### V4-212 — Finalize the Phase I visual system

Area: ux/mobile

Acceptance:

- Approved Shift Ledger visual direction is tokenized.
- The light theme covers all Phase I screens and states; dark mode is deferred to the retention phase.
- Branding is consistent across app, website, and stores.
- No archived testimonials, awards, or unsupported security claims are reused.

### V4-213 — Build Phase I payout reconciliation

Priority: blocker
Area: mobile/backend

Acceptance:

- User can record expected payout while scheduling or completing a shift.
- User can record or update cumulative actual payout received later.
- Pending payout is derived without counting unpaid money as received.
- Supports `not_expected`, `pending`, `partially_received`, `received`, and `disputed`.
- Payout updates never rewrite scheduled or actual worked-time/tip records.
- Shift detail and stats show expected, received, and pending amounts clearly.
- Idempotent update and relationship/integrity tests pass.

### V4-214 — Build missed and cancelled shift reasons

Priority: blocker
Area: mobile/backend

Acceptance:

- User can mark a planned shift not worked.
- Required Phase I reasons are Sick, Employer Cancelled, Personal, Emergency, Schedule Conflict, Weather/Transportation, and Other.
- Other requires a note.
- Employer Cancelled maps to `cancelled`; employee-side reasons map to `missed`.
- Original scheduled hours, rate, role, and expected amounts remain intact.
- Missed/cancelled shifts record zero actual hours and earnings.
- Stats show missed/cancelled counts, scheduled hours, and expected base wages by reason.
- Copy-forward never copies missed/cancelled status or reason.
- Reasons remain private and are excluded from product analytics.

### V4-215 — Complete Phase I shift create, edit, and delete

Priority: blocker
Area: mobile/backend

Acceptance:

- User can create, edit, and delete shifts from the weekly calendar and shift detail.
- Editing reruns time, overnight, duplicate, and overlap validation.
- Completed shifts expose scheduled, actual, and payout edits separately.
- Deleting a completed shift warns that its actual and payout data leave active views too.
- Deletion is soft and immediately undoable; restoration returns linked data consistently.
- Permanent deletion follows the documented retention policy.
- Deleting one shift never affects its employer, role, copied source, or other shifts.
- Schedule and stats update immediately after edit, delete, undo, or restore.

### V4-216 — Build Phase I CSV export and encrypted backup/restore

Priority: blocker
Area: mobile

Acceptance:

- CSV exports scheduled, actual, tip, payout, employer, role, currency, and timezone fields.
- Full `.protip365` backup preserves canonical codes, IDs, relationships, settings, and schema version.
- Full backup is encrypted and portable to a new device.
- Import previews counts, validates integrity, and handles duplicates before commit.
- Export and restore work without an account or network connection.
- Existing records remain exportable after trial expiry.

### V4-217 — Complete Phase I English, Canadian French, and Spanish localization

Priority: blocker
Area: mobile/ux

Acceptance:

- `i18next` and `react-i18next` replace static module-level strings.
- Device language is detected with English fallback and can be changed in onboarding/Settings.
- Passcode, recovery, purchase, export, and restore flows are translated.
- Statuses and reason codes remain canonical in storage and localized in the UI.
- Employer names, custom roles, and notes remain user-entered text.
- Currency, locale, timezone, and 12/24-hour formatting are independent.
- Key-parity, fallback, long-string, accent, pluralization, and formatting tests pass.
- Native-speaker review covers restaurant, tip-pool, payout, and missed-shift terms.

### V4-218 — Implement 30-day trial and $19.99 lifetime unlock

Priority: blocker
Area: mobile/growth

Acceptance:

- Every new installation receives all Phase I functionality for 30 days.
- Apple/Google one-time product unlocks local lifetime access at the configured regional equivalent of USD $19.99.
- After expiry, existing records remain readable and exportable while creation/editing requires unlock.
- Purchase restore restores entitlement but never claims to restore local records.
- Trial-reset limitations without an account are documented and tested against store capabilities.
- No Cloud Sync subscription is sold in Phase I.

### V4-219 — Build Phase I local shift reminders

Priority: blocker
Area: mobile/ux

Acceptance:

- A planned shift with no actual entry or not-worked status schedules one local notification for two hours after its scheduled end.
- Creating or editing a shift schedules or reschedules the notification; completing, missing, cancelling, or deleting it cancels the notification.
- Tapping the notification opens the correct shift with `Complete shift`, `Mark not worked`, and `Remind me later` actions.
- Duplicate reminders are prevented, including after app restart and shift edits.
- Overnight shifts, timezone changes, and daylight-saving transitions resolve to the correct local due time.
- The user can disable reminders or change the delay in Settings.
- Notification permission is requested only after a future shift exists; denial never blocks scheduling or completion.
- When permission is unavailable, the shift remains visible under `Actuals pending` in the app.
- Lock-screen copy is privacy-safe and excludes employer names, earnings, tips, reason codes, and notes by default.
- English, Canadian French, and Spanish notification copy and actions pass localization tests.
- Android and iOS scheduling, cancellation, deep-link, and restart behavior pass device tests.
- User can configure optional pre-shift reminders globally, per template, or per shift.
- Quiet hours, individual snoozing, and capped repeat reminders for unresolved shift entries work without duplicate notifications.
- Completing, missing, cancelling, or deleting a shift cancels every related reminder immediately.

### V4-220 — Build reusable schedule templates and recurring shifts

Priority: blocker
Area: mobile/backend/ux

Acceptance:

- User can create, edit, archive, and apply employer/role schedule templates.
- Templates store planned fields and reminder preferences only; actual hours, tips, payouts, statuses, and reasons are never copied.
- Recurring rules support selected weekdays, weekly/biweekly cadence, start date, and optional end date or occurrence count.
- A preview shows every occurrence, duplicate, and cross-employer overlap before commit.
- Individual conflicts can be skipped or replaced.
- Editing one occurrence creates an exception; changing future occurrences never rewrites past or manually changed shifts.
- Ending a rule or archiving a template never deletes generated shifts.
- Idempotency and restart tests prove that recurrence generation cannot create duplicates.

### V4-221 — Build weekly goals and basic comparisons

Priority: blocker
Area: mobile/analytics/ux

Acceptance:

- User can set a weekly goal for worked hours, net tip income, actual gross earnings, or estimated net earnings across all employers or one employer.
- Scheduled/expected progress and actual progress are displayed separately.
- Goals repeat only when explicitly enabled and use the configured week start and timezone.
- Stats show basic week-over-week and month-over-month trends for hours, base wages, net tips, actual gross earnings, estimated net earnings, and effective hourly rate.
- Best weekday and employer comparisons use a user-selected metric and state the date range and completed-shift sample size.
- Insufficient data produces a neutral empty state instead of an unreliable ranking.
- Missing expected tips remain unknown and no trend makes causal claims.

### V4-222 — Restore estimated deduction and net budgeting

Priority: blocker
Area: mobile/backend/ux

Acceptance:

- Settings supports a user-entered estimated deduction percentage with optional employer and role overrides; no jurisdictional rate is preselected.
- Shift completion snapshots the effective rate and allows a one-shift override without rewriting defaults or history.
- Actual gross earnings equal base wages plus net tip income plus other income.
- Estimated deductions equal actual gross earnings multiplied by the snapshotted rate; Estimated net equals gross minus estimated deductions.
- Expected estimated net is shown only when the expected gross components are known.
- Stats and shift detail show Gross, Estimated deductions, and Estimated net as separate values.
- Actual payout received remains separate from the estimate.
- UI copy states that the value is a budgeting estimate, not payroll, verified take-home pay, tax filing, or tax advice.
- A 40% example and boundary tests for 0% and 100% pass with currency-safe rounding.

## M3 — Private beta

### V4-301 — Recruit and operate a 30-user four-week beta

Area: product

Acceptance:

- At least 30 users activate.
- Weekly interviews and issue triage run.
- Report activation, shift coverage, W1/W4 retention, save failures, and support themes.
- Gate 3 decision is documented.

### V4-302 — Validate Phase I reminders and recurring templates in beta

Area: mobile

Acceptance:

- Measure reminder opt-in, reminder-to-entry completion, snoozing, template adoption, recurrence exceptions, and duplicate-prevention failures.
- Interview users about timing, quiet hours, recurrence editing, and conflict previews.
- Document beta changes without removing the Phase I offline and privacy guarantees.

### V4-303 — Add advanced report exports

Area: mobile/backend/legal

Acceptance:

- Builds on the Phase I CSV and encrypted full backup.
- Adds custom date, employer, role, status, and payout filters.
- Currency/timezone are explicit.
- Does not claim to be a tax return.

### V4-304 — Add advanced forecasting and comparisons

Area: mobile/ux

Acceptance:

- Builds on Phase I goals, trends, recurring schedules, and basic comparisons.
- Advanced comparisons require enough data and state their date range.
- Forecasting uses consistent expected-versus-actual definitions and is always labeled as an estimate.
- Charts remain secondary to readable totals.

### V4-305 — Add payout aging and payment history

Area: mobile/product

Acceptance:

- Builds on the Phase I shift-level payout reconciliation.
- Shows how long payouts have remained pending.
- Supports a history of partial receipts when users need more than the Phase I cumulative amount.
- Optional overdue reminders are configurable.
- The feature does not claim to validate payroll, tax, or legal compliance.
- Instrument whether it creates a recurring payday use case.

### V4-306 — Run reliability, security, and deletion beta tests

Priority: blocker
Area: qa/security

Acceptance:

- Zero confirmed data loss.
- Save success exceeds 99.5%.
- Local transaction retries do not duplicate records.
- Passcode, migration, export/restore, trial expiry, purchase restore, and erase-local-data pass on both platforms.

### V4-307 — Add dark mode

Area: ux/mobile

Acceptance:

- Extends the approved Shift Ledger tokens without changing information hierarchy or calculations.
- Covers every screen, state, chart, notification deep link, and purchase/export flow.
- Maintains WCAG AA contrast and status indicators that do not depend on color alone.
- Follows the device setting with an explicit user override.
- Android and iOS visual-regression and accessibility checks pass.

## M4 — Public launch

### V4-401 — Restore and monitor the public website

Priority: blocker
Area: growth/legal

Acceptance:

- Homepage, privacy, terms, support, and deletion pages return successfully over valid HTTPS.
- Content matches actual data practices.
- Pricing shows `30 days free` and `Local lifetime — $19.99 one-time`.
- Cloud Sync is visibly tagged `Coming Soon · planned $2.99/month` and cannot be purchased.
- Uptime/certificate monitoring is enabled.
- Store listings link to the correct pages.

### V4-402 — Prepare Android store release

Area: growth/platform:android

Acceptance:

- Listing tells the six-frame PRD story.
- Data Safety form matches implementation.
- Privacy/support URLs and local-data-erasure instructions work.
- One-time lifetime product and 30-day trial behavior match the app.
- Cloud subscription is not offered.
- Closed/open testing and production checklists pass.

### V4-403 — Prepare iOS store release

Area: growth/platform:ios

Acceptance:

- Same critical-flow suite passes.
- App Privacy answers match implementation.
- Erase All Local Data is available in app.
- One-time purchase and trial terms are complete.
- Review credentials/instructions contain no production-user data.

### V4-404 — Establish support and incident response

Area: product/security

Acceptance:

- Support owner and response target are defined.
- Data-loss, passcode/recovery, billing, export/restore, privacy, and security runbooks exist.
- Users can report a problem from the app.
- Incident and breach-notification obligations are documented.

### V4-405 — Make launch and monetization decision

Priority: blocker
Area: product/growth

Acceptance:

- Gate 4 evidence is reviewed.
- Retention and reliability justify launch.
- Thirty-day trial and $19.99 local lifetime unlock are verified in both stores.
- Decision is explicitly launch, iterate, reposition, or stop.

## M5 — Cloud Sync (`Coming Soon`)

Cloud work does not block Phase I local launch.

### V4-501 — Reconcile and secure Supabase for Cloud Sync

Area: backend/security

Acceptance:

- Live schema is reproduced by timestamped migrations.
- Obsolete functions, broad grants, duplicate policies, and unsafe security-definer paths are removed.
- Authenticated ownership and two-user RLS tests pass.
- Backups and restore are verified before importing local users.

### V4-502 — Add optional Cloud account and authentication

Area: mobile/backend

Acceptance:

- Local users create an account only when enabling Cloud Sync.
- Local data remains available if login or network access fails.
- Password recovery, session handling, account deletion, privacy, and legal flows pass.

### V4-503 — Build conflict-safe SQLite-to-Supabase synchronization

Area: mobile/backend

Acceptance:

- SQLite remains the device source of truth.
- Initial upload, second-device download, tombstones, versions, retries, and conflicts are tested.
- Upgrade from local to Cloud cannot duplicate or lose shifts.
- Cloud cancellation preserves the latest local database and disables only synchronization.

### V4-504 — Launch Cloud Sync subscription

Area: growth/mobile/backend

Acceptance:

- Planned price is USD $2.99/month with verified regional equivalents.
- Subscription provides multi-device sync, automatic cloud backup, recovery, and migration.
- Server-side entitlement validation and store lifecycle handling pass.
- `Coming Soon` is removed only after Cloud release gates pass.
