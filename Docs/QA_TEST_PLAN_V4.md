# ProTip365 V4 — Master QA Test Plan (MVP)

Status: draft for MVP verification
Date: 2026-07-17
Owner: Testing agent (execution to follow once the build in `app/` lands)
Sources: `Docs/ADR-001-v4-architecture.md`, `Docs/PRD_V4.md` §8–§11, `Docs/PRODUCT_ONE_PAGER_V4.md`, `Docs/LINEAR_BACKLOG_V4.md`

## Scope

This plan covers the MVP as bounded by ADR-001: employers & roles, scheduled
shifts (week view), the completion flow, calculations, weekly stats, settings
(language, deduction default, CSV export, erase data), and EN / fr-CA / es
localization. Everything the ADR defers is listed in the final section
("Deferred — do not test in MVP") so no effort is wasted on it.

Scenario format:

- **ID:** TP-nnn, grouped by area.
- **Type:** `unit` (Jest, `src/domain/` / `src/data/`), `integration`
  (repository + store level, still automated), or `manual-emulator`
  (human-driven on an emulator or device).
- **Priority:** `P0` = release blocker, `P1` = must fix before beta,
  `P2` = polish.

## Known environment constraints

The development machine (Windows 11) currently has **no Java JDK and no Android
SDK installed**. Consequences:

- `unit` and `integration` scenarios run fine with Node/Jest — no blocker.
- `manual-emulator` scenarios require either (a) installing Android Studio
  (bundles JDK + SDK + emulator), or (b) installing **Expo Go** on a physical
  Android or iOS device on the same Wi-Fi and running the Metro dev server.
  Expo Go is the fastest path but does not exercise a production-like build
  (no SQLCipher, different JS engine packaging); Android Studio emulator is
  required before any release-candidate sign-off.
- iOS simulator testing is impossible on Windows; iOS checks are limited to
  Expo Go on a physical iPhone until a macOS build machine exists.

---

## Area 1 — Employers & roles

### TP-001 — Create first employer during onboarding
- **Type:** manual-emulator | **Priority:** P0
- **Preconditions:** Fresh install, no local data.
- **Steps:** Launch app. Follow onboarding: enter employer name "Bistro Nord"
  and default hourly rate 15.75. Continue.
- **Expected:** Employer is created and selected as default; app continues to
  first-shift creation (PRD §8.1). No account/login is ever requested.

### TP-002 — Create a second employer with color and initials identity
- **Type:** manual-emulator | **Priority:** P0
- **Preconditions:** One employer exists.
- **Steps:** Settings → Employers → Add. Name "Café Sud", rate 16.50, pick a
  distinct color. Save.
- **Expected:** Both employers listed. Each shows its color swatch and derived
  initials (e.g. "BN", "CS"). The two identities are visually distinct in
  lists, week strip, and shift cards.

### TP-003 — Edit employer default rate does not rewrite history
- **Type:** integration | **Priority:** P0
- **Preconditions:** Employer with rate 15.75 has one planned shift snapshotting
  that rate.
- **Steps:** Change employer default rate to 18.00. Create a new planned shift.
- **Expected:** Existing shift keeps its 15.75 snapshot; new shift snapshots
  18.00 (PRD §9 Employers, §10 rules).

### TP-004 — Role rate overrides employer default
- **Type:** integration | **Priority:** P0
- **Preconditions:** Employer rate 15.75; role "Bartender" with rate 19.00.
- **Steps:** Create a planned shift and select the Bartender role. Create a
  second shift with no role.
- **Expected:** First shift snapshots 19.00; second snapshots 15.75. The
  expected-earnings preview reflects the correct rate in each case.

### TP-005 — Role selection constrained to the shift's employer
- **Type:** integration | **Priority:** P1
- **Preconditions:** Employer A has role "Bartender"; employer B has role
  "Server".
- **Steps:** Create a shift for employer B; open the role selector. Attempt (via
  repository API in tests) to attach employer A's role to employer B's shift.
- **Expected:** UI only offers employer B's roles. Data layer rejects a role
  belonging to a different employer (PRD §12 integrity).

### TP-006 — Deduction-rate override precedence: role > employer > global
- **Type:** unit | **Priority:** P1
- **Preconditions:** Global default 20%; employer override 25%; role override
  30%.
- **Steps:** Resolve the effective deduction rate for (a) shift with role,
  (b) shift with employer only, (c) shift where neither overrides.
- **Expected:** (a) 30%, (b) 25%, (c) 20%. Stored as integer basis points
  (3000/2500/2000).

### TP-007 — Employer identity rendered on every shift surface
- **Type:** manual-emulator | **Priority:** P1
- **Preconditions:** Two employers with different colors; shifts for both in the
  current week.
- **Steps:** Inspect week strip, agenda list, shift detail.
- **Expected:** Every shift shows employer color AND a text label/initials —
  color is never the only signal (PRD §15 accessibility).

### TP-008 — Employer input validation
- **Type:** integration | **Priority:** P1
- **Steps:** Attempt to save an employer with (a) empty name, (b) rate 0 or
  negative, (c) rate with locale decimal comma "15,75".
- **Expected:** (a) and (b) rejected with inline (non-modal) validation;
  (c) accepted and parsed as 15.75 when locale uses comma (PRD §10).

### TP-009 — Employer with historical shifts cannot be hard-deleted
- **Type:** integration | **Priority:** P1
- **Preconditions:** Employer with one completed shift.
- **Steps:** Attempt to delete/archive the employer.
- **Expected:** Only archive is offered; historical shifts and their snapshots
  remain intact and visible in stats (PRD §9 Employers).

### TP-010 — Editing a role rate leaves existing snapshots intact
- **Type:** unit | **Priority:** P1
- **Preconditions:** Role rate 19.00 snapshotted on a planned shift.
- **Steps:** Change role rate to 21.00; recompute the existing shift's expected
  earnings.
- **Expected:** Existing shift still computes from 19.00.

---

## Area 2 — Scheduled shifts

### TP-011 — Create a planned shift
- **Type:** manual-emulator | **Priority:** P0
- **Preconditions:** At least one employer.
- **Steps:** Tap the `Add shift` extended FAB on Schedule. Pick employer, date,
  start 17:00, end 23:00. Save.
- **Expected:** Shift appears with status `planned` in the week strip and agenda
  under the correct day, with employer identity and expected earnings.

### TP-012 — Expected-earnings preview updates live
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** While adding a shift, change end time, rate-bearing role, and
  unpaid break duration.
- **Expected:** The preview recalculates immediately after each change and
  matches `scheduled_hours × rate_snapshot` (PRD §10).

### TP-013 — Overnight shift (8 PM–2 AM)
- **Type:** integration + manual-emulator | **Priority:** P0
- **Steps:** Create a shift 20:00 → 02:00.
- **Expected:** Accepted as overnight, duration 6.0 h (not −18 h, not
  rejected). Shift is listed on its start date; expected earnings use 6 h
  (PRD §9 "Support overnight shifts", §10).

### TP-014 — Edit a planned shift
- **Type:** manual-emulator | **Priority:** P0
- **Steps:** Open a planned shift, change end time and break, save.
- **Expected:** Week strip, agenda, expected preview, and stats all reflect the
  change immediately (PRD §9 "Recalculate … immediately after an edit").

### TP-015 — Delete a planned shift
- **Type:** manual-emulator | **Priority:** P0
- **Steps:** Delete a planned shift.
- **Expected:** Removed from week strip, agenda, and stats. Employer, roles, and
  other shifts are untouched. (If soft-delete + Undo is implemented, Undo
  restores it fully; if not implemented in MVP, log a gap — do not fail.)

### TP-016 — Validation: end before start / impossible ranges
- **Type:** unit + manual-emulator | **Priority:** P0
- **Steps:** Attempt (a) start == end, (b) end earlier than start on the same
  day where overnight is not intended (e.g. 14:00 → 09:00 producing 19 h
  overnight — verify the UI makes the overnight interpretation explicit),
  (c) a shift spanning more than 24 h.
- **Expected:** Zero-length and >24 h shifts rejected with inline validation.
  End-before-start is either explicitly labeled overnight ("+1 day") or
  rejected — never silently saved as negative hours (PRD §9 "Prevent negative
  hours and impossible time ranges").

### TP-017 — Validation: negative money values
- **Type:** unit | **Priority:** P1
- **Steps:** Attempt negative expected tips, negative rate, negative break
  duration.
- **Expected:** All rejected. Totals can never go negative where not meaningful
  (PRD §12 integrity).

### TP-018 — Same-day multi-employer overlap is flagged, not blocked
- **Type:** integration + manual-emulator | **Priority:** P0
- **Preconditions:** Two employers.
- **Steps:** Create employer A shift 11:00–17:00, then employer B shift
  16:00–22:00 the same day.
- **Expected:** A visible overlap warning appears on save and in the week view,
  but the user can proceed (PRD §9 "Warn about overlapping shifts across
  employers without blocking").

### TP-019 — Adjacent (non-overlapping) same-day shifts are not flagged
- **Type:** integration | **Priority:** P1
- **Steps:** Employer A 11:00–16:00 and employer B 16:00–22:00 the same day.
- **Expected:** No overlap warning; both render clearly in the day's agenda.

### TP-020 — Week navigation
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** Navigate two weeks back, then forward past the current week.
- **Expected:** Correct dates and shifts each week; "today" indicator only on
  the current week; no shift duplication or loss when returning.

### TP-021 — Agenda grouping
- **Type:** manual-emulator | **Priority:** P1
- **Preconditions:** Shifts on three different days, one day with two shifts.
- **Steps:** Review the agenda under the week strip.
- **Expected:** Shifts grouped by day in chronological order; multi-shift days
  show all shifts sorted by start time; empty days handled gracefully.

### TP-022 — Scheduled unpaid break reduces expected hours; paid break does not
- **Type:** unit + integration | **Priority:** P0
- **Steps:** Create a 9 h shift (8:00–17:00) with a 15-min paid break and a
  30-min unpaid break (PRD §10 worked example).
- **Expected:** `scheduled_hours` = 8.5; expected wages use 8.5 h. The paid
  break is visible but subtracts nothing.

### TP-023 — Save-and-add-another keeps context prefilled
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** Add a shift, choose "Save and add another" (or equivalent), then
  add a second shift.
- **Expected:** Employer, role, rate, and common break stay prefilled; only
  date/time need entry (PRD §8.2). If the control is absent in the MVP build,
  log as a gap against PRD §8.2.

### TP-024 — Duplicate-save protection (idempotency)
- **Type:** integration | **Priority:** P1
- **Steps:** Trigger the same planned-shift save twice (double-tap simulation /
  repeated call with the same idempotency key).
- **Expected:** Exactly one shift exists (PRD §9 "Make retries idempotent").

---

## Area 3 — Completion flow

### TP-025 — Completion screen prefilled from schedule
- **Type:** manual-emulator | **Priority:** P0
- **Preconditions:** A planned shift whose end time has passed.
- **Steps:** Open the shift → "Complete shift".
- **Expected:** Actual start/end prefilled from scheduled values; scheduled
  breaks prefilled; rate snapshot and deduction rate prefilled; planned values
  remain visible for reference (PRD §8.3, §9).

### TP-026 — Adjust actual end time (+20 min)
- **Type:** integration + manual-emulator | **Priority:** P0
- **Preconditions:** Planned 17:00–23:00, no breaks, rate 15.00.
- **Steps:** Complete with actual end 23:20; save.
- **Expected:** `worked_hours` = 6.333… h → actual base wages 95.00;
  `hours_variance` = +0.33 h; result screen shows expected, actual, variance,
  and effective hourly (PRD §8.3 step 6). Minute-level precision preserved.

### TP-027 — Breaks: taken vs not taken
- **Type:** integration | **Priority:** P0
- **Preconditions:** Shift with one scheduled 30-min unpaid break.
- **Steps:** (a) Complete marking the break taken. (b) Repeat on another shift
  marking it not taken.
- **Expected:** (a) 30 min subtracted from actual paid time. (b) Nothing
  subtracted; the scheduled break row is untouched in both cases (scheduled and
  actual break rows are separate — PRD §10, §12).

### TP-028 — Paid break does not reduce actual paid time
- **Type:** unit | **Priority:** P0
- **Steps:** Actual shift 8:15–17:00 with a 15-min paid break and a 45-min
  unpaid lunch (PRD §10 example).
- **Expected:** `actual_paid_minutes` = 480 → 8.0 h. Only unpaid minutes
  subtract.

### TP-029 — Break outside the reported shift window rejected
- **Type:** unit + integration | **Priority:** P0
- **Steps:** Actual shift 17:00–23:00; attempt a break starting 16:30, and one
  starting 22:45 with 30-min duration (spills past end).
- **Expected:** Both rejected with a clear inline error (PRD §9 "breaks outside
  the reported shift").

### TP-030 — Overlapping breaks rejected
- **Type:** unit + integration | **Priority:** P0
- **Steps:** Add break 19:00–19:30, then attempt 19:15–19:45 in the same phase.
- **Expected:** Second break rejected (PRD §9, §12 "break rows of the same phase
  may not overlap").

### TP-031 — Total unpaid break exceeding shift duration rejected
- **Type:** unit | **Priority:** P0
- **Steps:** 2 h actual shift; attempt unpaid breaks totalling 2 h 30 min.
- **Expected:** Rejected; paid time can never go negative (PRD §9).

### TP-032 — Tip method: direct
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** Complete a shift choosing tip method `direct`.
- **Expected:** Direct tips and tip-out fields shown; pool-contribution and
  tip-share fields hidden or de-emphasized. Calculation model unchanged
  (PRD §10 "expose only applicable fields").

### TP-033 — Tip method: pooled
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** Complete a shift choosing `pooled`, entering pool contribution and
  tip-share received.
- **Expected:** Applicable fields shown; net tip math correct.

### TP-034 — Tip method: mixed
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** Complete a shift choosing `mixed`, entering direct tips, pool
  contribution, tip-share received, and tip-out paid.
- **Expected:** All four flows enterable; net tips =
  direct − pool_contribution + tip_share − tip_out.

### TP-035 — Net tip income across all four flows
- **Type:** unit | **Priority:** P0
- **Steps:** direct 120.00, pool contribution 20.00, tip-share 35.00, tip-out
  15.00.
- **Expected:** `net_tip_income` = 120 − 20 + 35 − 15 = 120.00. Also verify
  each flow in isolation and all zeros → 0.00.

### TP-036 — Sales optional; gross tip rate only when sales > 0
- **Type:** unit | **Priority:** P2
- **Steps:** Complete a shift (a) without sales, (b) with sales 800 and tips
  120 + share 0.
- **Expected:** (a) saves fine, no tip-rate shown and no division by zero;
  (b) gross tip rate 15% (PRD §10 `gross_tip_rate`).

### TP-037 — Single-transaction save marks shift worked
- **Type:** integration | **Priority:** P0
- **Steps:** Complete a shift; immediately query shift status and actuals. Then
  simulate a failure mid-save (e.g. throw inside the transaction in a test) and
  re-query.
- **Expected:** Success case: actuals row exists AND status is `worked` —
  atomically. Failure case: no partial write — status stays `planned`, no
  orphan actuals row (PRD §6 principle 3, §12 `completeScheduledShift`).

### TP-038 — Edit after completion preserves planned values
- **Type:** integration + manual-emulator | **Priority:** P0
- **Preconditions:** A worked shift.
- **Steps:** Edit the actual tips and actual end time; save. Inspect the shift
  detail.
- **Expected:** Scheduled start/end/breaks/expected values unchanged; variances
  recalculated; `updated_at` audit timestamp advanced (PRD §8.5).

### TP-039 — Mark not worked with reason
- **Type:** integration + manual-emulator | **Priority:** P0
- **Steps:** (a) Mark a planned shift not worked with reason
  `employer_cancelled`. (b) Mark another with `other` and no note, then with a
  note. (c) Mark one with `sick`.
- **Expected:** (a) status `cancelled`. (b) `other` without a note is rejected;
  with note saves as `missed`. (c) `missed`. All keep original scheduled hours
  and expected amounts, record zero actuals, and store a reason + timestamp
  (PRD §9, §11).

### TP-040 — Missed/cancelled shifts contribute zero earnings
- **Type:** unit | **Priority:** P0
- **Steps:** Aggregate a week containing one worked and one missed shift.
- **Expected:** Missed shift contributes 0 to actual hours/earnings but its
  scheduled hours/expected wages appear in missed/cancelled reporting
  (PRD §9 stats, §10).

### TP-041 — Complete an overnight shift
- **Type:** integration | **Priority:** P1
- **Preconditions:** Planned 20:00–02:00.
- **Steps:** Complete with actual 20:10–02:30 and one 30-min unpaid break at
  23:30.
- **Expected:** `actual_span` = 380 min, paid = 350 min ≈ 5.83 h; break at
  23:30 accepted as inside the window; a break at 03:00 rejected.

### TP-042 — Payout fields at completion and later update
- **Type:** integration | **Priority:** P1
- **Steps:** Complete a shift with expected payout 150, received 0. Later update
  received to 150.
- **Expected:** Status derives `pending` then `received`; updating payout never
  changes worked hours, tips, or the schedule (PRD §11).

### TP-043 — Completion is idempotent
- **Type:** integration | **Priority:** P1
- **Steps:** Submit the same completion twice (same idempotency key /
  double-tap).
- **Expected:** Exactly one `shift_actuals` row; totals counted once (PRD §9,
  §12 "at most one actual result per scheduled shift").

### TP-044 — Draft preserved on interruption
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** Start completing a shift, enter tips, background/kill the app,
  reopen.
- **Expected:** The in-progress actual-entry draft is recoverable; system back
  never silently discards it (PRD §9 Reliability, §15). If drafts are not in
  the MVP build, log as a gap.

---

## Area 4 — Calculations (unit tests, `src/domain/`)

### TP-045 — scheduled_hours with mixed breaks
- **Type:** unit | **Priority:** P0
- **Steps:** 8:00–17:00, 15-min paid + 30-min unpaid break.
- **Expected:** 510 paid minutes → 8.5 h (PRD §10 example, exact).

### TP-046 — expected_base_wages
- **Type:** unit | **Priority:** P0
- **Steps:** 8.5 h × 15.75.
- **Expected:** 133.88 after rounding to cents (verify documented rounding mode
  — half-up expected; flag if implementation differs).

### TP-047 — actual paid time (PRD worked example)
- **Type:** unit | **Priority:** P0
- **Steps:** Actual 8:15–17:00, paid 15-min break, unpaid 45-min lunch.
- **Expected:** 480 min → 8.0 h exactly.

### TP-048 — actual_gross_earnings composition
- **Type:** unit | **Priority:** P0
- **Steps:** base 180 + net tips 100 + other income 20.
- **Expected:** 300.00 (PRD §10 deduction example).

### TP-049 — estimated deductions and net at basis-point rate
- **Type:** unit | **Priority:** P0
- **Steps:** gross 300.00 at 4000 bp (40%).
- **Expected:** deductions 120.00, estimated net 180.00. Also verify 0 bp →
  net == gross, and 10000 bp → net 0.00.

### TP-050 — Deduction-rate bounds
- **Type:** unit | **Priority:** P1
- **Steps:** Attempt rates below 0 and above 10000 bp.
- **Expected:** Rejected/clamped per validation; stored value always within
  0–10000 (PRD §10).

### TP-051 — Variance signs
- **Type:** unit | **Priority:** P0
- **Steps:** (a) worked 6.33 h vs scheduled 6.0 h; (b) worked 5.5 h vs 6.0 h;
  (c) actual gross 250 vs expected 300.
- **Expected:** (a) +0.33 h, (b) −0.5 h, (c) −50.00. Sign convention is
  actual − expected everywhere.

### TP-052 — earnings_variance only when comparable
- **Type:** unit | **Priority:** P0
- **Steps:** Shift with no expected tips entered; compute earnings variance.
- **Expected:** No variance produced (null/absent), NOT a variance computed
  against expected tips = 0 (PRD §10 "Missing expected tips remain unknown").
  Hours variance still computes (hours are always comparable).

### TP-053 — effective_hourly and zero-hour edge
- **Type:** unit | **Priority:** P0
- **Steps:** (a) gross 300 / 8 h; (b) worked_hours = 0 with nonzero tips.
- **Expected:** (a) 37.50. (b) No division-by-zero crash: effective hourly is
  undefined/absent (or displayed as "—"), never `Infinity`/`NaN`.

### TP-054 — Payout status derivation boundaries
- **Type:** unit | **Priority:** P0
- **Steps:** Derive status for: expected 0/received 0; expected 150/received 0;
  expected 150/received 100; expected 150/received 150; expected 150/received
  150.01 or 200; manual `disputed` flag set.
- **Expected:** `not_expected`; `pending`; `partially_received`; `received`;
  received (with pending_payout floored at 0, never negative); `disputed`
  overrides derivation until cleared (PRD §9, §11).

### TP-055 — pending_payout floor
- **Type:** unit | **Priority:** P1
- **Steps:** expected 100, received 120.
- **Expected:** `pending_payout` = 0, not −20 (PRD §10 `max(…, 0)`).

### TP-056 — Overnight duration math
- **Type:** unit | **Priority:** P0
- **Steps:** 20:00→02:00 (360 min); 23:30→00:15 (45 min); 22:00→22:00 next-day
  flagged (should be rejected as 24 h or 0).
- **Expected:** Correct positive minute counts across midnight; degenerate
  cases rejected by validation.

### TP-057 — Zero-hour / degenerate shift edges
- **Type:** unit | **Priority:** P1
- **Steps:** Scheduled hours 0 after unpaid breaks equal span; wages at 0 h;
  variance when scheduled is 0.
- **Expected:** No negative paid minutes (validation blocks the input); all
  aggregates remain finite numbers.

### TP-058 — Money rounding and no float drift
- **Type:** unit | **Priority:** P0
- **Steps:** Sum 0.10 ten times; compute 7 h 50 min × 15.75; compute deduction
  on 33.33.
- **Expected:** Exact cent results (1.00; 123.38 assuming half-up; 13.33 at
  40%). Amounts stored/handled in integer cents or decimal-safe form — a test
  asserting `0.1 + 0.2` style drift never reaches persisted or displayed
  values (PRD §10 "without binary floating-point drift"). Break math uses
  integer minutes.

---

## Area 5 — Stats

### TP-059 — Week totals: expected vs actual
- **Type:** integration | **Priority:** P0
- **Preconditions:** A week with two worked shifts (known values) and one still
  planned.
- **Steps:** Open Stats for that week.
- **Expected:** Scheduled hours, actual hours, hours variance, expected base
  wages, actual base wages, net tips, gross, estimated net all match hand
  computation. The planned shift contributes to scheduled/expected columns
  only — never to actual earnings (PRD §9 stats).

### TP-060 — Per-employer aggregation
- **Type:** integration | **Priority:** P0
- **Preconditions:** Worked shifts for two employers in one week.
- **Steps:** View stats for all employers, then filter/segment per employer.
- **Expected:** Per-employer figures sum to the all-employer totals; each
  employer's figures use its own snapshots.

### TP-061 — Effective hourly is hours-weighted
- **Type:** unit | **Priority:** P0
- **Steps:** Shift A: 8 h, gross 320 (40/h). Shift B: 2 h, gross 30 (15/h).
- **Expected:** Week effective hourly = 350 ÷ 10 = 35.00 — NOT the average of
  rates (27.50).

### TP-062 — Empty week state
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** Navigate stats to a week with no shifts.
- **Expected:** A designed empty state (PRD §9 Reliability), zeros/dashes as
  appropriate, no crash, no NaN, no stale data from another week.

### TP-063 — Planned-only week shows no earned income
- **Type:** integration | **Priority:** P0
- **Steps:** Week with only planned shifts; open stats.
- **Expected:** Actual earnings 0 / absent; expected values present; no
  presentation of the plan as achieved income (PRD §9 "Planned shifts without
  earnings do not count as earned income").

### TP-064 — Missed shifts in stats
- **Type:** integration | **Priority:** P1
- **Steps:** Week with one worked and one missed shift; open stats.
- **Expected:** Actual totals exclude the missed shift; if the MVP shows
  missed/cancelled reporting, the missed shift's scheduled hours/expected wages
  appear there with its reason.

---

## Area 6 — Settings & data

### TP-065 — Language switch applies immediately and everywhere
- **Type:** manual-emulator | **Priority:** P0
- **Steps:** With data present, switch Settings → Language: EN → FR-CA → ES →
  EN. After each switch visit Schedule, Stats, a shift detail, the completion
  form, and Settings itself.
- **Expected:** All labels, tabs, buttons, statuses, and validation messages
  change instantly without restart (react-i18next reactive change). Employer
  names, roles, and notes are never translated. Preference persists across
  restart.

### TP-066 — Global default deduction rate and snapshot behavior
- **Type:** integration | **Priority:** P0
- **Steps:** Set global deduction to 25%. Complete shift 1. Change global to
  35%. Complete shift 2. Inspect both.
- **Expected:** Shift 1 keeps 25% snapshot; shift 2 uses 35%. Changing settings
  never rewrites completed history (PRD §10). The rate is editable per shift
  at completion.

### TP-067 — CSV export contains all shift fields
- **Type:** manual-emulator + integration | **Priority:** P0
- **Preconditions:** At least one worked shift with breaks, tips, tip-out, and
  payout data; one planned; one missed.
- **Steps:** Settings → Export CSV; share/save the file; open it.
- **Expected:** One row per shift including at minimum: employer, role, date,
  scheduled start/end, scheduled break minutes (paid/unpaid), actual
  start/end, actual break minutes, rate snapshot, direct tips, pool
  contribution, tip-share, tip-out, sales, other income, deduction rate,
  gross, estimated net, expected/actual payout, status, reason. Values match
  the app to the cent; CSV parses cleanly (quoting/commas/accents in employer
  names like "Café Sud" survive — UTF-8).

### TP-068 — Erase local data
- **Type:** manual-emulator | **Priority:** P0
- **Steps:** Settings → Erase All Local Data → confirm the explicit
  confirmation step.
- **Expected:** All employers, shifts, actuals, settings, and drafts removed;
  app returns to first-launch onboarding. Relaunching the app shows no
  residual data. Cancelling the confirmation leaves everything intact.

### TP-069 — Persistence across restart
- **Type:** manual-emulator | **Priority:** P0
- **Steps:** Create an employer and shifts; complete one; force-stop the app
  (not just background); relaunch.
- **Expected:** Every record and setting is present and identical; a save
  completed just before the kill is durable (PRD §9 "A successful save is
  immediately visible after app restart").

### TP-070 — Currency and time-format display
- **Type:** manual-emulator | **Priority:** P2
- **Steps:** Check money and time rendering under each language; if the MVP
  exposes 12/24-h or currency settings, toggle them.
- **Expected:** `Intl`-based formatting, no hardcoded "$"+string concatenation
  artifacts, no clipped totals with long formats (PRD §14 Localization).

---

## Area 7 — Localization spot checks

### TP-071 — fr-CA key coverage parity
- **Type:** unit | **Priority:** P1
- **Steps:** Automated test comparing `src/i18n` locale files: every key in
  `en` exists in `fr-CA` (and vice versa), no empty values.
- **Expected:** 100% parity; missing keys fail the test. Fallback to English
  works for any deliberately missing key.

### TP-072 — es key coverage parity
- **Type:** unit | **Priority:** P1
- **Steps:** Same parity test for `es` (neutral Latin American Spanish).
- **Expected:** 100% parity, no empty values.

### TP-073 — No hard-coded user-facing English in components
- **Type:** unit (static scan) | **Priority:** P1
- **Steps:** Grep/lint scan of `app/app/` and `app/src/ui/` for literal
  user-facing strings in JSX outside `t(...)` calls (allowlist for units,
  test IDs, and symbols).
- **Expected:** No untranslated user-facing literals; violations listed
  file-by-line (CLAUDE.md rule 8).

### TP-074 — Locale date/time/number formats
- **Type:** manual-emulator | **Priority:** P1
- **Steps:** In FR-CA, inspect week-strip day labels, shift times, money
  amounts, and decimal input; repeat in ES.
- **Expected:** Localized day/month names; decimal comma accepted in money
  inputs where the locale expects it; currency formatted via `Intl`; accented
  characters render correctly everywhere (é, à, ñ). Statuses and reason codes
  display translated labels while stored codes stay canonical.

---

## Area 8 — Manual emulator round (owner end-to-end script)

### TP-075 — Full MVP walkthrough
- **Type:** manual-emulator | **Priority:** P0
- **Preconditions:** Fresh install (or run TP-068 first). Android emulator via
  Android Studio, or Expo Go on a phone. Have ~15 minutes.

Follow the steps in order. After each step, the "You should see" line tells you
whether to continue. If anything differs, note the step number and what you saw.

1. Open the app for the first time. **You should see:** a welcome/onboarding
   screen in your device's language, with no login or account screen.
2. When asked for your first employer, type `Bistro Nord` and hourly rate
   `15.75`. Continue. **You should see:** the app move on without asking for an
   email or password.
3. Create your first shift when prompted: pick next Tuesday, 5:00 PM to
   11:00 PM. Save. **You should see:** the weekly schedule with that shift on
   Tuesday.
4. Go to Settings → Employers and add a second employer: `Café Sud`, rate
   `16.50`, and pick a different color. **You should see:** two employers, each
   with its own color.
5. Back on Schedule, tap `Add shift`. For Café Sud, add a shift next Friday
   8:00 PM to 2:00 AM. Save. **You should see:** the shift on Friday showing
   6 hours — not rejected and not a strange negative number.
6. Add one more shift: Bistro Nord, same Friday, 4:00 PM to 9:00 PM. Save.
   **You should see:** a warning that the two Friday shifts overlap — but the
   app still lets you save.
7. Look at the week. **You should see:** Tuesday and Friday populated, each
   shift showing its employer's color and name/initials, and an expected
   earnings amount on each.
8. Add a shift for yesterday (so it can be completed): Bistro Nord, 11:00 AM
   to 5:00 PM with a 30-minute unpaid break. Save.
9. Open yesterday's shift and tap `Complete shift`. **You should see:** the
   times already filled in from the schedule and the break listed.
10. Change the end time to 5:20 PM (you stayed 20 minutes late). Leave the
    break marked as taken.
11. Enter tips: direct tips `120`, tip-out paid `15`. If asked for a tip
    method, choose `Direct`. Leave sales empty.
12. Save the completion. **You should see:** one confirmation, then a result
    showing expected vs actual, the variance, and an effective hourly rate.
    Rough check: about 5.83 hours worked, roughly `$91.88` wages + `$105` net
    tips ≈ `$196.88` gross.
13. Open the completed shift again. **You should see:** the original planned
    times (11:00–5:00) still shown alongside your actual times (11:00–5:20) —
    the plan was not overwritten.
14. Go to Stats for the current week. **You should see:** actual earnings only
    from the completed shift; the future shifts count toward scheduled/expected
    only. The effective hourly matches step 12.
15. Filter or view stats by employer, if available. **You should see:** Bistro
    Nord carrying all the actual earnings; Café Sud only expected.
16. Go to Settings → Language and choose `Français (Canada)`. **You should
    see:** the entire app switch to French immediately — tabs, buttons,
    stats labels. Your employer names stay exactly as you typed them.
17. Still in French, glance at Schedule and the completed shift. **You should
    see:** dates in French, amounts unchanged, nothing clipped or in English
    (except names/notes you typed).
18. Switch language back to English. Go to Settings → Export CSV and share the
    file to yourself (email/drive). Open it. **You should see:** all your
    shifts with times, tips `120`, tip-out `15`, and `Café Sud` spelled
    correctly with its accent.
19. Close the app completely (swipe it away) and reopen it. **You should
    see:** everything still there, in English.
20. Go to Settings → Erase All Local Data, read the warning, and confirm.
    **You should see:** everything wiped and the first-launch onboarding
    screen from step 1 again.

- **Expected overall:** all 20 steps pass without crashes, data loss, English
  leaking into French mode, or the plan being overwritten by actuals.

---

## Deferred — do not test in MVP

Per ADR-001 ("Out of MVP"), the following are deliberately absent from the MVP
build. Do not raise defects for their absence and do not spend test effort on
them until they are scheduled. Listed here so future plans can pick them up.

| ID | Deferred area | What NOT to test now | Source |
|---|---|---|---|
| D-01 | Reminders / notifications | Post-shift 2-h reminder, pre-shift reminders, quiet hours, snooze, notification permission flows, lock-screen privacy copy | ADR-001; PRD §9 Local shift reminders |
| D-02 | Templates & recurring rules | Template CRUD, recurrence generation/preview, exceptions, series idempotency | ADR-001; PRD §9 Reusable templates |
| D-03 | Encrypted backup / restore | Full-backup export, restore on second device, backup format | ADR-001; PRD §13 |
| D-04 | Passcode / biometrics | Six-digit passcode, biometric lock, recovery key, rate limiting | ADR-001; PRD §9 Local access |
| D-05 | Database encryption (SQLCipher) | Encryption-at-rest verification — pre-release blocker tracked separately, not an MVP test | ADR-001 Persistence row |
| D-06 | Trial / paywall / IAP | 30-day trial, $19.99 unlock, $2.99 subscription, purchase restore, expired-trial read-only mode | ADR-001; PRD §18 |
| D-07 | Month / Day calendar views | Any calendar view other than the week strip + agenda | ADR-001 |
| D-08 | CSV import | Importing spreadsheets or prior data | ADR-001 |
| D-09 | Copy-forward of week/schedule | Copy shift/employer-week/full-week forward with conflict preview — verify presence before testing; if absent in MVP treat as deferred, not a defect | PRD §9 (ADR does not list it as delivered) |
| D-10 | Weekly goals & trends | Goals, week-over-week trends, best day/employer | PRD §9 (not in ADR MVP loop) |
| D-11 | Cloud Sync / Supabase | Any network/account behavior — Phase I has none by design | PRD §1, §12 |

If any deferred feature turns out to be partially present in the MVP build,
report it as scope drift to the owner rather than testing it ad hoc.

---

## Scenario summary

| Priority | Count | IDs |
|---|---|---|
| P0 | 44 | TP-001–004, 011, 013–016, 018, 022, 025–031, 035, 037–040, 045–049, 051–054, 056, 058–061, 063, 065–069, 075 |
| P1 | 29 | TP-005–010, 012, 017, 019–021, 023–024, 032–034, 041–044, 050, 055, 057, 062, 064, 071–074 |
| P2 | 2 | TP-036, 070 |
| **Total** | **75** | plus 11 deferred areas (D-01–D-11) explicitly out of MVP scope |

Suggested execution order once the build lands:

1. Unit suite (Area 4 + unit rows elsewhere) — pure `src/domain/`, no
   emulator needed.
2. Integration suite (repositories, atomic completion, aggregation).
3. Manual emulator pass: Areas 1–3 and 5–7 P0s, then TP-075 end-to-end.
4. P1 sweep, then P2.
