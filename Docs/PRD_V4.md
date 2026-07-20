# ProTip365 V4 — Product Requirements Document

Status: discovery recommendation
Date: 2026-07-17
Product: Android-first mobile app with iOS parity
Working positioning: **Plan every shift. Know what it actually paid.**

## 1. Executive decision

ProTip365 should be rebuilt as a product, but not rewritten from zero technically.

- Keep one Expo React Native and TypeScript codebase for Android and iOS.
- Use the current shared app as the foundation.
- Review and recover the six commits on `origin/codex/protip365-completion-loop`; they substantially improve the codebase but do not yet solve the core workflow.
- Back up and preserve the existing Supabase project, but remove it from the Phase I runtime path.
- Make encrypted on-device SQLite the Phase I source of truth.
- Require no account, email, login, or password for Phase I.
- Offer an optional local passcode and biometric app lock.
- Defer account-based multi-device Cloud Sync and label it `Coming Soon`.
- Center the product on personal shift management across one or more employers, followed by expected-versus-actual earnings reconciliation.
- The device user is the employee. They create employers, receive schedules, plan shifts, then record actual results.
- Make Android the first release target while continuously building and testing iOS from the same codebase.

The current app has useful assets and business logic, but it does not make the planned-shift lifecycle clear enough. V4 must support two distinct moments: quickly entering scheduled shifts ahead of time, then completing each shift with actual hours and earnings. Completing a shift must update the planned record and actual result atomically.

## 2. Product thesis

Tipped workers may receive schedules from multiple employers and need one personal weekly view before they work. Afterwards, they need to know how actual hours and earnings compared with the schedule and expectations. Existing apps are feature-rich but frequently criticized for intrusive ads, sync problems, data loss, confusing multi-job workflows, or slow entry.

ProTip365 will win only if it becomes the most trustworthy and quickest personal record of:

- where and when the user is scheduled to work;
- how scheduled hours compare with actual hours;
- what they earned in tips and wages;
- what they paid out;
- their true hourly earnings;
- whether the expected amount was actually paid;
- how one shift or employer compares with another.

The product promise is not “more charts.” It is: **one schedule across employers, followed by a trustworthy expected-versus-actual record.**

## 3. Target customer

### Primary customer

A server or bartender who:

- works at least two tipped shifts per week;
- has variable hours, cash/card tips, or tip-outs;
- personally tracks or wants to track income;
- may work for more than one employer;
- currently relies on memory, Notes, paper, a spreadsheet, or an unsatisfactory tip app;
- wants a private schedule and earnings record that their employers cannot access.

Research recruitment should emphasize ages 20–35 and women, without making the interface gender-coded or excluding older workers.

### Secondary customer, later

- Other restaurant roles with variable tips.
- Delivery, salon, and other tipped workers only after the restaurant workflow retains users.

### Explicitly out of scope

- Employee or team management.
- Scheduling staff for an employer.
- Payroll processing.
- Tip-pool administration for a restaurant.
- Tax filing or tax advice.
- POS integrations in the MVP.

The app does not manage other employees. The local device user is the employee and adds employers such as McDonald's and Burger King.

## 4. Market evidence

The audience hypothesis is directionally correct, but the age range is broader than 20–30.

- The 2025 BLS Current Population Survey reports 1.754 million waiters/waitresses with a median age of 25.8; 69.8% are women.
- The same survey reports 432,000 bartenders with a median age of 34.6; 57.2% are women.
- BLS occupational employment estimates produce a broader employment proxy of roughly 3.03 million U.S. waiters/waitresses and bartenders combined. The total differs because it uses a different survey and employment methodology.
- The National Restaurant Association reports 68% of waitstaff and 60% of bartenders are women.
- Statistics Canada reports that 70.2% of food-service workers were under 35 in 2023 and 56.7% were women.

This is a meaningful niche, but it is crowded. ProTip365 should not use a top-down market count as proof of demand. Retention and repeated shift logging are the real tests.

### Competitive snapshot

| Product | Evidence | Strength | Repeated weakness/opportunity |
| --- | --- | --- | --- |
| ServerLife | 4.8 on iOS and Android; 100K+ Android installs | Mature forecasting, reminders, jobs, goals | Complexity, prior data/timezone and billing complaints |
| TipSee | 100K+ Android installs | Long feature list, multiple jobs, reports | Intrusive ads, support, sync/data-loss and calculation complaints |
| Just the Tips | Established iOS/Android product | Tip-outs, multiple workplaces, export, localization | Ads and recurring reporting/notification bugs |
| Waiter Pal | Strong iOS rating | Time tracking, offline use, reminders | High subscription price and workflow customization complaints |
| TipMax and newer entrants | Modern niche products | Clean tracking plus goals or training | Limited differentiation and smaller proof base |
| Notes, paper, spreadsheets | Free and familiar | Flexible, private, no account required | No automatic calculation, comparison, recovery, or structured history |

### Market conclusion

“Tip tracker with charts” is not differentiated. The strongest opening is:

1. one weekly schedule across multiple employers;
2. fast entry of several planned shifts when a schedule arrives;
3. one completion step that preserves the plan and records actual hours and earnings;
4. clear expected-versus-actual statistics by shift, week, and employer;
5. accurate effective hourly earnings after tip-out;
6. privacy, export, deletion, and reliable recovery;
7. a calm, ad-free experience.

## 5. Jobs to be done

### Planning job

When I receive schedules from one or more employers, help me enter my shifts quickly and see one reliable weekly schedule.

### Completion job

After each shift, help me record actual hours and earnings against the planned shift so I can see the variance and know what the shift actually paid.

### Emotional job

Help me feel in control of irregular income without turning this into bookkeeping.

### Trust job

Give me a private record I can recover, export, correct, and delete.

### Payday job

Help me compare what I recorded with what I was actually paid, without pretending to be payroll software.

## 6. Product principles

1. **Schedule first.** Planned shifts are created ahead of time and drive the weekly experience.
2. **Plan versus actual.** Preserve the original plan and record actual results separately.
3. **One completion transaction.** Actual hours, earnings, and worked status are saved together.
4. **Fast schedule entry.** Make it efficient to add several shifts for one employer, then switch employers.
5. **Progressive detail.** Schedule fields are simple; actual tips, tip-out, sales, and notes appear when completing the shift.
6. **Transparent math.** Every expected, actual, and variance total has a documented formula and visible breakdown.
7. **Private by default.** No employer access, data sale, public profile, or social leaderboard.
8. **Inclusive design.** Do not make young or female synonymous with decorative, pink, or low-contrast design.
9. **Cross-platform parity.** Android ships first; iOS is never maintained as a separate product.

## 7. Information architecture

Use three primary destinations with a persistent Add Shift action:

1. **Schedule**
   - week calendar as the default view;
   - today and upcoming shifts across all employers;
   - employer color/label on every shift;
   - quick add, duplicate, edit, cancel, and complete actions;
   - navigation to past and future weeks.
2. **Stats**
   - expected versus actual hours and earnings;
   - weekly, monthly, and employer filters;
   - shift history and result details;
   - comparisons and variances.
3. **Settings**
   - employers;
   - global work/break defaults and employer/role overrides;
   - estimated deduction-rate default and employer/role overrides;
   - currency and time format;
   - reminders;
   - language, export, backup/restore, privacy, security, and erase local data.

Add Shift remains globally accessible from Schedule. The calendar is not optional or secondary; it is the product's primary planning surface.

## 8. Core user journeys

### 8.1 First session

1. App detects the device language and offers English, Canadian French, or Spanish.
2. User continues locally without creating an account.
3. App offers an optional six-digit passcode and biometric lock.
4. App asks for the first employer name and default hourly rate.
5. App opens Add Scheduled Shift.
6. User enters date, planned start/end time, and optional break.
7. User can save and add another shift for the same employer.
8. App opens the weekly schedule with all planned shifts visible.

Target: employer plus first planned shift in under three minutes.

### 8.2 Enter a new schedule

1. User selects an employer.
2. User adds several upcoming shifts using “Save and add another,” duplicate, or repeat controls.
3. Employer, role, role-specific rate, and common break remain prefilled.
4. User switches employer and enters that schedule.
5. The combined week view detects overlaps and shows every employer clearly.

Target: enter a typical week in under two minutes, validated with users.

### 8.3 Complete a planned shift

1. User opens a past or current planned shift.
2. User taps “Complete shift.”
3. Planned start/end, break, hours, and expected base wage remain visible.
4. User confirms or changes the prefilled actual start/end times, records each break taken, and enters tip, tip-out, tip-share, and payout details.
5. One transaction saves the actual result and marks the planned shift worked.
6. The result shows expected, actual, variance, and effective hourly earnings.

Target: complete a planned shift in under 30 seconds.

### 8.4 Unplanned shift

The user may explicitly add an unplanned worked shift for a last-minute call-in or forgotten schedule entry. This is a fallback, not the primary workflow, and must be labeled as unplanned.

### 8.5 Correct a shift

Editing actual values must not destroy the original planned values. Changes to a completed shift recalculate variances and preserve an audit timestamp.

## 9. Functional requirements

### Phase I — Core release

#### Local access and security

- No account, email, login, password, or network connection is required.
- Offer an optional six-digit local passcode and device biometrics.
- Store the random database-encryption key in the operating-system keychain/keystore.
- The passcode gates access to the encryption key; it is not an online password.
- Allow recovery through configured biometrics or a user-held recovery key.
- If no recovery method is available, resetting access erases local data; explain this before passcode creation.
- Provide an explicit Erase All Local Data action with confirmation.
- Keep privacy, terms, support, and data-storage explanations available without unlocking financial records.

#### Onboarding

- Starts immediately on first launch without authentication.
- Employer name and default hourly rate required.
- Currency is detected from the device region and confirmed during onboarding.
- Role is optional during initial employer creation.
- Introduce post-shift reminder permission only after the first future shift is created, when the value is clear.
- Continue directly into creation of the first scheduled shift.
- Skip only optional fields, not employer setup.
- Existing local users bypass onboarding safely.

#### Employers

- Create, edit, archive, and select a default employer.
- Store a required default hourly rate plus optional location label, color, and break-plan defaults.
- A global break plan in Settings is the fallback. Each employer and role may override it because break policies differ between jobs.
- A break preset stores a label such as `Morning break` or `Lunch`, optional typical start time, default duration, and whether it is paid or unpaid.
- Settings allows a user-entered estimated deduction rate for budgeting. The global rate is the fallback; an employer or role may override it.
- Do not preselect a rate from the user's region. The user must enter or confirm the percentage.
- Create one or more roles under an employer, each with its own hourly rate.
- A role-specific rate overrides the employer default when that role is selected.
- A shift snapshots the selected rate so later employer or role changes never rewrite history.
- Do not hard-delete an employer with historical shifts.
- Support multiple employers as a core free capability.
- The local device user is the employee; no team or employee roster exists.

#### Schedule management

- Create shifts ahead of time with status `planned`.
- Create, edit, and delete a shift from the calendar and shift-detail screen.
- Editing reruns time, overnight, duplicate, and cross-employer overlap validation.
- A completed shift exposes separate edits for scheduled values, actual values, and payout values.
- Deleting a completed shift clearly lists the linked actual and payout data that will also be removed from active views.
- Use recoverable soft deletion with immediate Undo; permanent deletion follows the documented retention policy.
- Deleting one shift never deletes its employer, role, copied source shift, or other schedule entries.
- Recalculate schedule and statistics immediately after an edit, deletion, restoration, or undo.
- Record:
  - employer;
  - work date;
  - scheduled start/end time;
  - zero or more scheduled breaks, each with label, optional start time, duration, and paid/unpaid status;
  - expected hourly rate snapshot;
  - optional role;
  - optional expected tips;
  - optional expected other income;
  - optional expected payout;
  - optional notes.
- Support overnight shifts.
- Add several shifts efficiently using save-and-add-another and duplicate.
- Copy a selected shift, selected employer schedule, or full week forward by one or more weeks.
- Before copying, preview destination dates, employer/role/rate snapshots, duplicates, and cross-employer overlaps.
- Copy planned fields only; never copy reported actual start/end times, actual breaks, tips, payouts, worked status, or completion notes.
- Allow the user to skip or replace individual destination conflicts before confirming.
- Edit a planned shift or mark it not worked with a required reason.
- Phase I reason codes: `sick`, `employer_cancelled`, `personal`, `emergency`, `schedule_conflict`, `weather_or_transportation`, and `other`.
- `other` requires a note; status and reason code may be corrected later.
- `employer_cancelled` maps to `cancelled`; employee-side reasons map to `missed`.
- Preserve the original scheduled hours and expected amounts for missed/cancelled statistics, but record zero actual hours and earnings.
- Never copy missed/cancelled status or reason when copying a schedule forward.
- Warn about overlapping shifts across employers without blocking an intentional overlap.
- Show all employers in one week calendar with accessible labels in addition to color.
- Navigate backward and forward across weeks.
- Preserve the entered schedule draft when navigation or connectivity is interrupted.
- Make retries idempotent so one planned shift cannot be saved twice.

#### Reusable templates and recurring shifts

- Create, edit, archive, and reuse schedule templates for an employer and optional role.
- A template may store scheduled start/end time, one or more break presets, rate source, expected tips, expected other income, expected payout, notes, and reminder preferences.
- Templates contain planned values only; they never contain actual hours, tips, payouts, completion state, or missed/cancelled reasons.
- Create recurring rules from a template using selected weekdays, weekly or biweekly cadence, start date, and optional end date or occurrence count.
- Preview every generated occurrence, duplicate, and cross-employer overlap before saving.
- Allow individual conflicts to be skipped or replaced without discarding the rest of the series.
- Editing one occurrence creates an exception. Editing future occurrences never rewrites past, completed, missed, cancelled, or manually changed shifts.
- Archiving a template or ending a rule never deletes shifts already generated from it.
- Recurrence generation is idempotent so reopening or retrying cannot duplicate shifts.

#### Actual shift completion

- Complete an existing planned shift as the primary workflow.
- Preserve scheduled values and record separate actual values:
  - user-reported actual start and end time, prefilled from the schedule for confirmation;
  - zero or more actual breaks, each with label, start time, duration, and paid/unpaid status;
  - actual hourly-rate snapshot, normally inherited from the scheduled employer/role;
  - tip method: direct, pooled, or mixed;
  - direct tips received;
  - tip-pool contribution, when applicable;
  - tip-share received;
  - tip-out paid;
  - optional sales;
  - optional other income;
  - estimated deduction-rate snapshot, prefilled from the role, employer, or global setting and editable for this shift;
  - expected payout;
  - cumulative actual payout received;
  - optional notes.
- Cash/card split is optional and only shown when enabled.
- Derive pending payout and payout status from expected and actual received amounts.
- Payout statuses include `not_expected`, `pending`, `partially_received`, `received`, and `disputed`.
- Actual payout may be updated later without altering the scheduled shift or worked-time record.
- Prevent negative hours and impossible time ranges.
- This is not a live clock-in/clock-out system. The app does not run a time clock, infer attendance, or use location to decide when work started or ended.
- At completion, ask whether the scheduled start/end were accurate and let the user adjust them to the minute.
- Prefill scheduled/default breaks and let the user mark each as taken or not taken, change its start and duration, or add another break.
- Paid breaks are recorded but do not reduce paid hours. Only actual unpaid-break duration is subtracted from actual paid time.
- Prevent overlapping breaks, breaks outside the reported shift, and total unpaid-break time greater than the reported shift duration.
- One transaction saves actual values and marks the shift worked.
- Support an explicitly unplanned worked shift as a fallback.
- Preserve the actual-entry draft when navigation or connectivity is interrupted.
- Make retries idempotent so completion cannot create duplicate results.

#### Local shift reminders

- If a planned shift still has no actual entry or not-worked status two hours after its scheduled end, send one local reminder.
- The reminder runs entirely on the device and requires no account, server, or network connection.
- Creating or editing a shift schedules or reschedules its reminder. Completing, marking not worked, cancelling, or deleting the shift cancels it.
- Tapping the notification opens that shift's post-shift check-in with `Complete shift`, `Mark not worked`, and `Remind me later` actions.
- Never notify for a shift already marked worked, missed, cancelled, or deleted, and never send duplicate reminders for the same due time.
- Allow the user to disable reminders or change the post-shift delay in Settings; the initial default is two hours.
- Request notification permission contextually after a future shift exists. Permission denial must not block scheduling or shift entry.
- When permission is unavailable, show the same outstanding item in the in-app `Actuals pending` state.
- Use privacy-safe lock-screen copy by default: do not expose employer names, earnings, tips, reason codes, or notes in the notification text.
- Resolve reminder time from the shift's scheduled end timestamp, including overnight shifts, timezone changes, and daylight-saving transitions.
- Localize notification copy and actions in English, Canadian French, and Spanish.
- Support optional pre-shift reminders with a user-selected lead time per shift, template, or global default.
- Support quiet hours and clearly state whether time-sensitive pre-shift reminders may bypass them.
- Allow capped recurring reminders for unresolved post-shift entries; stop immediately when the shift is completed, missed, cancelled, or deleted.
- Let users snooze an individual reminder without changing the global reminder schedule.

#### Schedule and history

- Show planned and completed shifts together in the calendar.
- Show past shifts in list form when reviewing history.
- Filter by date range, employer, and status.
- Open a shift detail with visible calculation breakdown.
- Create, edit, delete, restore, and undo deletion of a shift.
- Planned shifts without earnings do not count as earned income.

#### Expected-versus-actual stats

- Show current week and selectable periods:
  - scheduled hours;
  - actual worked hours;
  - hours variance;
  - expected base wages;
  - actual base wages;
  - direct tips;
  - tip-pool contributions;
  - tip-share received;
  - tip-out paid;
  - net tip income;
  - expected total only when an expected-tip value or clearly labeled forecast exists;
  - actual gross earnings, defined as base wages plus net tip income plus other income;
  - estimated deductions;
  - estimated net earnings;
  - earnings variance only when expected and actual totals are comparable;
  - expected payout;
  - actual payout received;
  - pending payout;
  - missed/cancelled shifts, scheduled hours, and expected base wages by reason;
  - effective hourly rate.
- Show stats by employer and across all employers.
- Allow employer and role comparisons using their historical rate snapshots.
- Never treat missing expected tips as zero.
- Never count planned, missed, or cancelled shifts as actual earnings.
- Clearly distinguish scheduled, expected, forecast, actual, and paid amounts.
- Label the result `Estimated net` or `Estimated after deductions`; do not present it as verified take-home pay, payroll, a tax return, or tax advice.

#### Weekly goals and basic trends

- Allow weekly goals for worked hours, net tip income, actual gross earnings, or estimated net earnings across all employers or one employer.
- Show scheduled/expected progress separately from actual progress so a plan is never presented as achieved income.
- Carry a goal forward only when the user explicitly chooses to repeat it.
- Use the configured first day of week and timezone consistently across schedule, goals, and statistics.
- Show basic week-over-week and month-over-month trends for hours, base wages, net tips, actual gross earnings, estimated net earnings, and effective hourly rate.
- Show best weekday and best employer using a user-selected metric and a clearly stated date range.
- Require sufficient completed-shift data, show the sample size, and use an insufficient-data state instead of ranking unreliable results.
- Never treat missing expected tips as zero or claim that a correlation explains performance.

#### Reliability

- Planned-shift creation and completed-shift recording are separate operations for separate lifecycle moments.
- One transactional backend operation records actual values and marks the planned shift worked.
- A failed save leaves a recoverable draft.
- A successful save is immediately visible after app restart.
- Empty, loading, offline, retry, and partial-data states are designed.

### Phase II — Retention build

- Payout aging, overdue reminders, and received-payment history beyond the Phase I shift-level reconciliation.
- Dark mode.
- Optional app lock using device security.
- Local retry queue for poor connectivity.

### Future — Proven-value expansion

Only after retention is demonstrated:

- Forecasting.
- Widgets.
- Receipt capture.
- Advanced tip-out presets.
- Advanced multi-employer insights.
- Tax-oriented exports with legal review.
- POS import experiments.

### Explicitly deferred

- Achievements and gamification engine.
- Social comparison.
- Community wage benchmarks.
- Full payroll/tax calculation.
- Employer accounts.
- AI features without a validated job.

## 10. Calculation rules

All amounts are stored and calculated without binary floating-point drift. Currency and rounding rules are explicit.

Definitions:

- `scheduled_span_minutes = minutes_between(scheduled_start_time, scheduled_end_time)`
- `scheduled_paid_minutes = scheduled_span_minutes - sum(scheduled_unpaid_break_minutes)`
- `scheduled_hours = scheduled_paid_minutes ÷ 60`
- `expected_base_wages = scheduled_hours × expected_hourly_rate_snapshot`
- `expected_gross_total = expected_base_wages + expected_tips + expected_other_income`, only when optional expected components were explicitly entered or produced by a clearly labeled forecast
- `actual_span_minutes = minutes_between(reported_actual_start_time, reported_actual_end_time)`
- `actual_paid_minutes = actual_span_minutes - sum(actual_unpaid_break_minutes)`
- `worked_hours = actual_paid_minutes ÷ 60`
- `actual_base_wages = worked_hours × actual_hourly_rate_snapshot`
- `net_tip_income = direct_tips_received - tip_pool_contribution + tip_share_received - tip_out_paid`
- `actual_gross_earnings = actual_base_wages + net_tip_income + other_income`
- `estimated_deductions = actual_gross_earnings × estimated_deduction_rate`
- `estimated_net_earnings = actual_gross_earnings - estimated_deductions`
- `expected_estimated_deductions = expected_gross_total × estimated_deduction_rate`, only when `expected_gross_total` is valid
- `expected_estimated_net = expected_gross_total - expected_estimated_deductions`, only when `expected_gross_total` is valid
- `hours_variance = worked_hours - scheduled_hours`
- `earnings_variance = actual_gross_earnings - expected_gross_total`, only when the totals are comparable
- `pending_payout = max(expected_payout - actual_payout_received, 0)`
- `effective_hourly = actual_gross_earnings ÷ worked_hours`
- `gross_tip_rate = (direct_tips_received + tip_share_received) ÷ sales`, only when sales is greater than zero

Example: a scheduled shift from 8:00 AM to 5:00 PM spans 540 minutes. A 15-minute paid morning break does not reduce paid time; a 30-minute unpaid lunch produces 510 scheduled paid minutes, or 8.5 hours. If the user later reports an 8:15 AM start, 5:00 PM end, the paid morning break, and a 45-minute unpaid lunch starting at 1:00 PM, actual paid time is 480 minutes, or 8.0 hours.

Deduction example: $180 in actual base wages + $100 in net tip income + $20 in other income produces $300 in actual gross earnings. With a user-entered 40% estimated deduction rate, estimated deductions are $120 and `Estimated net` is $180.

Rules:

- Preserve both expected and actual values for each historical shift.
- A rate change at an employer affects future planned shifts, not history.
- A role-specific rate takes precedence over the employer default and is snapshotted on the planned shift.
- Break calculations use integer minutes. Paid breaks remain visible but are not subtracted from scheduled or actual paid minutes.
- Scheduled break rows and reported actual break rows remain separate so changing an actual lunch never rewrites the plan.
- A planned shift contributes zero earned income until earnings are recorded.
- `missed` and `cancelled` shifts contribute zero.
- Direct, pooled, and mixed tip methods expose only applicable fields, but preserve the same calculation model.
- Tip-pool contribution and tip-out paid are distinct: pool contribution enters a shared pool; tip-out is paid directly to another role or worker.
- Tip-share received is income allocated back from a pool or another role.
- Expected payout, actual earnings, and actual payout received are distinct values.
- Pending payout is never included as money already received.
- Missing expected tips remain unknown; they are never treated as zero for variance.
- The estimated deduction rate is user-entered, stored as integer basis points, and constrained to 0–100%.
- The effective rate is snapshotted when a shift is completed. Changing Settings affects future completions and never silently rewrites history.
- The rate applies to actual base wages, net tip income after pool/tip-out adjustments, and other income, matching the user's requested budgeting model.
- Actual payout received remains separate from estimated net earnings; receiving money does not prove the deduction estimate is correct.
- Forecasts based on historical tips must be labeled as forecasts, show their basis, and remain separate from user-entered expectations.
- Locale-aware input accepts decimal comma and decimal point appropriately.
- The label “net tips” means after tip-out, not after tax.
- The app never presents estimated tax deductions as actual take-home pay.

## 11. Shift state model

Required user-visible states:

- `planned`
- `worked`
- `missed`
- `cancelled`

“Actuals pending” is derived when a planned shift has ended but has no actual result; it need not be stored as a separate state.

Allowed transitions:

- planned → worked
- planned → missed
- planned → cancelled
- worked → planned only through an explicit correction with confirmation

The planned shift remains the stable schedule record. Completing it adds or updates one actual result and changes status consistently without overwriting the original plan.

Every `missed` or `cancelled` transition requires a reason code and timestamp. A reason may be corrected later, but the shift's original schedule remains intact. Reason codes are private user data and are never sent to product analytics.

Payout state is separate from shift state:

- `not_expected`
- `pending`
- `partially_received`
- `received`
- `disputed`

A shift may be worked while its payout remains pending. Updating payout state must never change worked hours, tips earned, or the original schedule.

## 12. Data and backend plan

### Existing live state

The connected Supabase project is healthy, but its migration and security state is not release-ready.

- Core live data exists in `users_profile`, `employers`, `expected_shifts`, and `shift_entries`.
- Live row counts at discovery: one profile, two employers, six expected shifts, and five shift entries.
- The live migration history is empty while the repository contains dozens of SQL scripts.
- All public tables have RLS enabled, but grants and policies are overly broad and duplicated.
- Several public security-definer functions reference obsolete tables or columns.
- Anonymous and authenticated roles have excessive table privileges.

No destructive work should occur until the existing Supabase project has a verified snapshot. Supabase remediation is deferred to the Cloud Sync phase because Phase I does not connect to it.

### Phase I local database

- Use `expo-sqlite` as the source of truth on Android and iOS.
- Enable SQLCipher for database encryption in production builds.
- Keep all Phase I operations available offline.
- Generate stable UUIDs on the device.
- Include `created_at`, `updated_at`, `deleted_at`, `version`, and `origin_device_id` metadata so future synchronization can be added without replacing local records.
- Run versioned, transactional SQLite migrations during app upgrades.
- Keep a local migration history table and test upgrades from every released schema version.
- Do not require Supabase Auth or any remote API in Phase I.

### Canonical product model

Use eleven core concepts in SQLite:

1. `profiles`
2. `employers`
3. `employer_roles`
4. `break_presets`
5. `scheduled_shifts`
6. `shift_breaks` — separate scheduled and reported-actual break rows
7. `shift_actuals` — at most one actual result per scheduled shift
8. `shift_payouts` — one Phase I reconciliation record per shift
9. `schedule_templates`
10. `recurrence_rules`
11. `weekly_goals`

`employer_roles` stores employer-scoped role names, default rates, and optional estimated-deduction overrides. The local profile stores the global deduction-rate fallback. `break_presets` stores global, employer, or role defaults. `shift_breaks` snapshots scheduled and reported actual breaks separately. `shift_actuals` snapshots the deduction rate used for the estimate. `shift_payouts` keeps expected, received, pending, and disputed payout state separate because payment may change after the actual work record is complete.

Every employer requires a name and default hourly rate. A role belongs to one employer and may override that default rate. Scheduled shifts snapshot the effective employer/role rate.

Use clear local table names aligned with these concepts. Existing Supabase rows are preserved separately and imported through an explicit migration tool if needed; they do not dictate the new local schema.

### Required integrity

- Every row belongs to the local profile and uses a stable UUID.
- Employer/role, employer/shift, shift/actual, and shift/payout relationships are enforced with SQLite foreign keys.
- Every planned shift belongs to an employer.
- A selected role must belong to the same employer as the shift.
- One actual result per planned shift is enforced.
- One Phase I payout-reconciliation record per shift is enforced.
- Every shift break is explicitly scheduled or actual; an actual break may reference its scheduled source but never overwrites it.
- Break start/duration must fit inside its corresponding shift span, and break rows of the same phase may not overlap.
- Every recurrence rule belongs to one schedule template, and every template belongs to one employer.
- Generated shifts retain their source template/rule identifiers without depending on those records for historical validity.
- Recurrence exceptions and idempotency keys prevent duplicate generated shifts.
- Scheduled and actual fields remain separate so completion cannot erase the plan.
- Totals cannot be negative where not meaningful.
- Estimated deduction rates are stored as basis points between 0 and 10,000 and are snapshotted on completed shifts.
- Start/end/timezone rules support overnight and daylight-saving changes.
- Use an IANA timezone snapshot and a local work date for reporting.
- Soft-deleted rows retain tombstones for recovery and future synchronization.

### Atomic local operations

Create one domain operation such as `completeScheduledShift` that runs in an exclusive SQLite transaction:

1. requires an existing planned shift for the primary path;
2. preserves its scheduled values;
3. upserts user-reported actual start/end, actual break rows, earnings, tip flows, and initial payout-reconciliation values;
4. marks the shift worked;
5. returns expected gross, actual gross, estimated deductions/net, payout, variance, and effective-hourly totals;
6. accepts an idempotency key.

Use separate idempotent local transactions for planned-shift creation, schedule copy-forward, recurring-shift generation, goal updates, payout updates, missed/cancelled reasons, and soft deletion. An unplanned worked shift may create both planned and actual records explicitly, but must not be the default path.

### Migration sequence

1. Freeze remote schema changes and back up the existing Supabase project.
2. Define the canonical SQLite schema and migration runner.
3. Build a read-only importer for any existing Supabase user data that must be retained.
4. Add local schema, integrity, encryption, and migration tests.
5. Ship compatible app code with SQLite as the source of truth.
6. Keep the Supabase snapshot untouched until Cloud Sync design begins.

## 13. Security and privacy release blockers

Before Phase I beta:

- SQLCipher is enabled and verified on Android and iOS production-like builds;
- the database key is random and stored in the operating-system keychain/keystore;
- passcode attempts are rate-limited and biometric fallback behaves correctly;
- passcode/recovery limitations are explained before activation;
- encrypted full-backup export and restore are tested on a second device;
- CSV export contains only fields explicitly selected by the user;
- Erase All Local Data removes the database, encryption key, drafts, and local preferences as documented;
- app logs, crash reports, and analytics contain no employer names, schedules, notes, tips, or payout amounts;
- privacy disclosures state that Phase I data stays on the device unless the user exports it;
- Canadian privacy review, including PIPEDA and applicable Quebec requirements, is complete;
- the policy for users under 18 is decided.

Before paid Phase I launch:

- no unresolved high or critical security findings;
- the 30-day trial and one-time purchase entitlement are validated on Apple and Google;
- restoring the one-time purchase never claims to restore local data;
- expired-trial users can always view and export their existing records;
- privacy, terms, and support URLs are live and monitored.

Supabase RLS, grants, functions, Auth, account deletion, and server-side subscription validation become blockers only before Cloud Sync leaves `Coming Soon`.

## 14. Technical architecture

### Mobile

- Expo React Native with TypeScript.
- One repository and feature set for Android and iOS.
- Android is the daily development and first-release priority.
- iOS build, typecheck, and critical-flow tests run on every release candidate.
- Feature modules: onboarding, local security, employers, schedule, shift completion, stats, export/restore, settings.
- Shared domain module owns statuses, calculations, validation, currency, and time rules.
- SQLite repositories isolate persistence details from screens.
- The UI and domain services never call Supabase directly.
- A future sync adapter may observe local changes without replacing SQLite as the source of truth.

### Local storage and future Cloud Sync

```text
Screens → domain services → encrypted SQLite
                              ├─ CSV/report export
                              ├─ encrypted ProTip365 backup
                              └─ future Supabase sync adapter
```

Phase I includes no remote login or data synchronization. Cloud Sync will later add account creation, automatic encrypted backup/restore, and multiple-device synchronization. The marketing one-pager must show Cloud Sync as `Coming Soon` and must not accept payment for it before it works.

### Localization

- Bundle English, Canadian French (`fr-CA`), and neutral Latin American Spanish resources in the app.
- Detect the device language on first launch and fall back to English.
- Allow language changes during onboarding and in Settings.
- Store language preference locally per device; Cloud Sync will not force one language across devices.
- Translate passcode, recovery, purchase, export, and restore screens.
- Use `i18next` with `react-i18next` for reactive language changes, interpolation, and pluralization.
- Store statuses, reason codes, tip methods, and payout states as canonical untranslated codes.
- Never translate employer names, custom roles, or notes.
- Keep language, currency, region, timezone, and 12/24-hour format as separate settings.
- Use `Intl.NumberFormat` and `Intl.DateTimeFormat` rather than hardcoded USD or date strings.
- Full backups use canonical keys; user-facing reports may use localized headings.
- Require native-speaker review of restaurant, tip-pool, payout, and missed-shift terminology.

### Recovery branch

`origin/codex/protip365-completion-loop` is six commits ahead of `main` and contains:

- refactored screens;
- CRUD and report improvements;
- password reset;
- settings/security work;
- tests;
- canonical schema migration work;
- splash assets and Expo QA fixes.

It passed typecheck, 17 tests, and Expo export for Android, iOS, and web in an isolated review. It still has four Expo patch-version mismatches and retains the broken multi-step earnings workflow. Recover it into a dedicated foundation branch after code review; do not treat it as the finished V4.

### Quality gates

- TypeScript strict typecheck.
- Unit tests for calculations, statuses, currency, locale, overnight shifts, breaks, and daylight-saving boundaries.
- SQLite repository and migration tests across every released local schema version.
- Android and iOS end-to-end tests for onboarding, passcode/biometrics, first shift, copy-forward, completion, edit/delete/restore, export/import, trial expiry, purchase restore, and erase-local-data.
- Localization key-parity, fallback, long-string, accent, pluralization, currency, and date-format tests for English, Canadian French, and Spanish.
- Expo doctor clean.
- Zero known critical/high dependency vulnerabilities.
- Successful production-like builds for both platforms.

## 15. UX and visual direction

Recommended direction: **The Shift Receipt** (owner-approved 2026-07-20).

- Use IBM Plex Mono app-wide so schedules, forms, totals, and results read as one private shift ledger.
- Light “paper receipt” palette: background `#E9E4D7`, paper `#F6F2E9`, ink `#20211E`, dim text `#7C7A70`, negative red `#D8472B`, confirmed-money green `#2E7D4F`, user-entry pen blue `#2B4BD7`, and rules `#C9C3B2`.
- Dark “night ticket” palette: background `#12151C`, paper `#1E222C`, ink `#F0EEE6`, dim text `#8B92A5`, negative red `#FF7A5C`, confirmed-money green `#5CD69B`, user-entry pen blue `#8FA8FF`, and rules `#3A4152`.
- Use receipt cards with dashed rules and hard-offset shadows, rotated bordered uppercase stamps, ink/pen hard-shadow buttons, bordered chips, and bordered segmented tabs.
- Use pen blue for user-entered values and ink for computed values. Reserve green for confirmed money and red for negative amounts or close-out attention.
- Keep cards, buttons, chips, fields, stamps, and tabs square with radius `0`.
- Home is the first and initial tab. Its weekly tally uses existing model semantics for hours worked, wages, combined gross tips, tip-out paid, total earned, real hourly rate, and goal progress; it also links the next shift and overdue close-outs to the existing completion flow. It must not split tips into cash/card fields.
- Large touch targets and one clear primary action per screen remain required.

Android platform conventions (Material 3):

- Use four always-visible navigation labels in this order: Home, Schedule, Stats, Settings; the active state uses the square ink-on-paper receipt treatment.
- Use a square, ink hard-shadow floating action button labeled `Add shift`, positioned bottom-right above the navigation bar; do not center-dock the FAB.
- Support system and predictive back everywhere; back or dismissal never discards an in-progress actual-entry draft.
- Use Material segmented buttons or tabs for view switching, and Material date/time pickers and exposed dropdown menus for form fields.
- Scale all text in sp and lay out edge-to-edge with correct status-bar and gesture insets (Android 15+).
- The fixed brand palette is an explicit decision; Material You dynamic color is not used.
- iOS keeps the same structure with platform-appropriate navigation transitions and Human Interface touch-target minimums.

Avoid:

- cocktail imagery as the main identity — EXCEPTION (owner decision, 2026-07-18): the app icon/logo is the V3 martini-glass-with-coin mark, explicitly re-approved from `Archive/v3-legacy-2026-07-17/website/images/protip365-logo.png`; in-app UI still avoids cocktail decoration;
- gender-coded styling;
- decorative gradients that weaken readability;
- tiny calendar dots as the only status signal;
- icon-only actions without accessible labels;
- modal alerts for ordinary validation;
- a five-tab structure with a placeholder paywall.

Accessibility requirements:

- WCAG AA contrast;
- dynamic type without clipped totals;
- screen-reader labels and logical focus order;
- reduced-motion support;
- status communicated by text/icon as well as color;
- keyboard-safe forms;
- minimum 48×48 dp touch targets on Android and 44×44 pt on iOS.

## 16. Success metrics and instrumentation

### Activation

A user is activated when they:

1. create an employer;
2. add at least one upcoming planned shift;
3. view it in the combined weekly schedule;
4. later complete a planned shift with actual values.

Measure planning activation and completed-loop activation separately.

### North-star behavior

Weekly users who plan shifts and complete actuals for at least 60% of shifts that they worked.

### Validation targets

These are decision thresholds, not market benchmarks:

- 60–70% of trial users activate;
- median first employer and planned shift created in under three minutes;
- median typical week entered in under two minutes;
- median planned-shift completion recorded in under 30 seconds;
- at least 40% return to complete a planned shift within seven days;
- week-four retention reaches at least 25–30%;
- retained users record at least 60% of their worked shifts;
- save success exceeds 99.5%;
- zero confirmed data-loss incidents.

### Required events

- local_onboarding_started/completed;
- passcode_enabled/disabled;
- biometric_lock_enabled/disabled;
- onboarding_started/completed;
- employer_created;
- planned_shift_created/edited/cancelled;
- schedule_week_viewed;
- shift_completion_started/completed/failed;
- actuals_pending_viewed;
- payout_expected_recorded;
- payout_received_recorded;
- payout_marked_disputed;
- shift_edited/deleted;
- expected_actual_result_viewed;
- stats_filtered;
- export_requested/completed;
- backup_restore_started/completed/failed;
- local_data_erase_started/completed;
- trial_started/expired;
- lifetime_unlock_started/completed;
- reminder_enabled;
- post_shift_reminder_scheduled/cancelled/opened/snoozed;
- pre_shift_reminder_scheduled/cancelled/opened;
- schedule_template_created/edited/archived/applied;
- recurrence_rule_created/edited/ended;
- weekly_goal_created/progress_viewed;
- trend_viewed;
- employer_or_day_comparison_viewed;
- notification_permission_prompted/granted/denied;
- paywall_viewed, only when monetization is tested.

Never send tip amounts, employer names, notes, schedules, or other financial content to product analytics.

## 17. Validation gates

### Gate 1 — Problem

Interview 20 screened tipped workers.

Proceed when:

- at least 60% report a recurring tracking/control problem;
- the problem has a concrete consequence such as schedule conflicts, multi-employer confusion, budgeting uncertainty, pay discrepancy, employer comparison, or tax-season reconstruction;
- at least 10 agree to a two-week diary or prototype test.

Stop or reposition if the dominant response is “I do not track and there is no consequence.”

### Gate 2 — Workflow prototype

Test the interactive prototype with 10 target users.

Proceed when:

- at least 90% add two employers and a week of shifts without help;
- median planned-shift completion is 30 seconds or less;
- “employer,” “role rate,” “scheduled,” “actual,” “direct tips,” “pooled tips,” “tip-out,” “tip-share,” “pending payout,” “variance,” and “effective hourly” are understood;
- users can explain expected-versus-actual statistics correctly.

### Gate 3 — Private beta

Recruit at least 30 activated testers for four weeks.

Proceed when:

- activation is at least 70%;
- week-four retention is at least 30%;
- retained users log at least 60% of worked shifts;
- no data-loss, migration, export/restore, passcode, or erase-local-data failure is found.

Iterate twice before expanding scope if retention is below target.

### Gate 4 — Public launch

Proceed when:

- SQLite migrations and restore paths are reproducible;
- security blockers are closed;
- legal/support URLs and Erase All Local Data work;
- Android and iOS release matrices pass;
- pricing has been tested with users;
- support and incident processes exist.

## 18. Monetization decision

### Phase I — Local

- Give every new installation a 30-day free trial of all Phase I functionality.
- After the trial, offer either a USD $19.99 one-time lifetime unlock or a USD $2.99/month auto-renewing subscription through Apple/Google in-app purchase.
- Do not limit employers, shifts, statistics, languages, or exports during the trial or on either paid option.
- When the trial expires without purchase, keep existing data readable and exportable; disable new creation/editing until unlock or subscription.
- When a monthly subscription lapses, apply the same rule: existing data stays readable and exportable; new creation/editing requires resubscribing or the lifetime unlock.
- Restoring the purchase restores the entitlement on supported store devices, not the local database.
- Keep manual CSV export and encrypted full backup/restore available to every user, including after trial expiry.
- Validate equivalent regional pricing in App Store Connect and Google Play before release.

### Future — Cloud Sync (`Coming Soon`)

- Planned price: USD $2.99/month.
- Includes account-based multi-device synchronization, automatic cloud backup, recovery, and device migration.
- All Phase I product functionality remains available in the local lifetime and monthly versions.
- Do not sell, preorder, or start the Cloud subscription until synchronization and recovery pass release gates.
- If a future Cloud subscription expires, preserve the current local database and disable only synchronization.

## 19. Go-to-market hypothesis

### Message

**Plan every shift. Know what it actually paid.**
Combine schedules from every employer, then compare expected hours and earnings with the actual result.

### Initial channels

- App Store and Google Play search optimization.
- Short, real-worker creator demonstrations.
- Hospitality-school and local restaurant-worker pilots.
- Relevant worker communities, with permission and no astroturfing.
- A free shift/tip spreadsheet as a lead magnet and optional import path.

Do not buy paid acquisition until retention is credible.

### Store-page story

1. See every employer in one weekly schedule.
2. Add a new work schedule quickly.
3. Complete each planned shift in seconds.
4. Compare expected hours and earnings with actual results.
5. Keep a private, exportable record.
6. Works on Android and iPhone.

One-pager pricing block:

- `30 days free`
- `Local lifetime — $19.99 one-time`
- `Local monthly — $2.99/month`
- `Cloud Sync — Coming Soon`

Proposed store title: `ProTip365 – Tip Tracker`
Proposed subtitle: `Shifts & Real Hourly Pay`

## 20. Delivery roadmap

### Foundation stage 0 — Decisions and recovery

- Lock the confirmed model: the user is the employee and creates one or more employers.
- Reauthenticate Linear.
- Interview target users.
- Review and recover the completion branch.
- Freeze and baseline Supabase.
- Create one canonical vocabulary and calculation specification.

### Foundation stage 1 — Secure local foundation

- Encrypted SQLite schema and reproducible local migrations.
- Passcode, biometrics, recovery warning, export/restore, and erase-local-data.
- Shared planned-versus-actual domain model and atomic completion operation.
- Clean Expo dependency and build gates.

### Product Phase I — Core release

- Onboarding.
- Employers.
- Weekly schedule management.
- Reusable schedule templates and safe recurring-shift rules.
- Planned-shift completion with separate actual values.
- Privacy-safe local reminder when a past shift still needs actuals or a missed/cancelled reason.
- Pre-shift reminders, quiet hours, snoozing, and capped recurring reminders.
- Schedule, Stats, detail/edit/delete.
- Weekly expected-versus-actual results.
- Weekly goals, basic trends, and best-day/employer comparisons.
- English, Canadian French, and Spanish.
- CSV export and encrypted full backup/restore.
- Thirty-day trial, $19.99 one-time unlock, and $2.99/month local subscription.
- Draft recovery and idempotent local transactions.
- Android/iOS critical-path testing.

### Product Phase II — Private beta and retention

- Prototype and usability fixes.
- Payout aging and receipt history, dark mode, and beta-derived product improvements.
- Four-week beta instrumentation.
- Reliability and support workflow.

### Launch

- Store assets and live legal/support website.
- One-pager labels Cloud Sync `Coming Soon`.
- Android production release.
- iOS release after the same acceptance suite passes.
- Pricing experiment only after retention evidence.

## 21. Open product decisions

These decisions require owner confirmation or user research:

1. Is the launch geography Canada, the United States, or both?
2. Are users under 18 allowed?
3. Should expected tips be manually entered, forecast from history, or omitted from Phase I?
4. Which launch currencies are required in addition to CAD and USD?
5. Should tax exports be offered only as raw records, with no tax calculation?

## 22. Source links

- [BLS 2025 labor-force characteristics by occupation](https://www.bls.gov/cps/cpsaat11.htm)
- [BLS 2025 detailed occupation demographics](https://www.bls.gov/cps/cpsaat11b.htm)
- [BLS occupational employment estimates](https://www.bls.gov/news.release/ocwage.t01.htm)
- [National Restaurant Association employee demographics](https://restaurant.org/research-and-media/u-s-restaurant-employee-demographics/)
- [Statistics Canada food-services workforce study](https://www150.statcan.gc.ca/n1/pub/11-621-m/11-621-m2025013-eng.htm)
- [ServerLife on Google Play](https://play.google.com/store/apps/details?id=com.mzbapps.serverlife&hl=en_US)
- [ServerLife on the App Store](https://apps.apple.com/us/app/serverlife-tip-tracker/id1098987860)
- [TipSee on Google Play](https://play.google.com/store/apps/details?id=com.wcd.tipsee&hl=en_US)
- [Just the Tips on Google Play](https://play.google.com/store/apps/details?id=twinoakstechnologies.justthetips&hl=en_US)
- [Waiter Pal on the App Store](https://apps.apple.com/us/app/waiter-pal-tip-tracker/id1619187216)
- [IRS tip recordkeeping and reporting](https://www.irs.gov/businesses/small-businesses-self-employed/tip-recordkeeping-and-reporting)
- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Expo SQLite and SQLCipher](https://docs.expo.dev/versions/latest/sdk/sqlite/)
- [Expo localization](https://docs.expo.dev/guides/localization/)
- [Expo FileSystem](https://docs.expo.dev/versions/latest/sdk/filesystem/)
- [Expo Sharing](https://docs.expo.dev/versions/latest/sdk/sharing/)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play one-time products](https://developer.android.com/google/play/billing/one-time-products)
- [Supabase pricing](https://supabase.com/pricing)
