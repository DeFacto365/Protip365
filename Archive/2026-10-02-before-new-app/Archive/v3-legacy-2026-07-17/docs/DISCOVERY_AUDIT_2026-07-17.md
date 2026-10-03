# ProTip365 discovery audit

Date: 2026-07-17
Scope: repository, archive, live Supabase, product, market, marketing, UX, architecture, and red-team review

## Outcome

The project is recoverable. The recommendation is a product reset on top of a salvaged technical foundation, not a blind rewrite and not a continuation of the current interface. The confirmed product lifecycle is: add employers, enter scheduled shifts ahead of time, then record actual hours and earnings against each planned shift.

No application code, production database row, or external project record was changed during discovery.

## Repository inventory

Current repository:

- Path: `C:\Github\Protip365`
- Branch: `main`
- Commit at review: `97b961a` (`Align mobile data layer with live Supabase schema`)
- `origin/main` matched.
- Active source:
  - `ProTip365Shared/` — Expo React Native and TypeScript mobile app;
  - `supabase/` — database scripts and functions;
  - `Docs/website/` — static public website.

Archive:

- `Archive/docs`: approximately 850 files, 214 MB.
- `Archive/legacy-native`: approximately 472 files, 57 MB.
- `Archive/previous-archives`: approximately 1,630 files, 333 MB.
- It contains historical Android/Kotlin and iOS/Swift implementations, database scripts, release material, screenshots, marketing material, and nested prior archives.

Archive decision:

- Do not restore either native app as the main implementation.
- Recover domain rules and test cases for overnight shifts, breaks, overlap, missed shifts, locale-aware money, and completed-only reporting.
- Use screenshots only as workflow evidence.
- Do not reuse archived testimonials, awards, encryption statements, or other unsupported marketing claims.
- Keep the archive read-only and outside normal build/test paths.

## Current shared app

Stack:

- Expo `56.0.9`
- React Native `0.85.3`
- React `19.2.3`
- TypeScript
- Supabase JavaScript `2.105.4`

Current shell:

- Today
- Calendar
- Add
- Reports
- Settings

What exists:

- email authentication;
- employer creation and deletion;
- planned shift creation;
- tip/income attachment to a shift;
- basic reports;
- settings.

Material workflow and correctness problems:

- onboarding exists but is not connected as a reliable first-use flow;
- employer setup is hidden in Settings;
- shifts can exist without an employer;
- earnings entry requires a pre-existing shift and sends the user away to create one;
- returning from shift creation can leave stale selection state;
- editing earnings can overwrite prior values with zero because the form is not safely prefilled;
- saving earnings and completing a shift are two requests, so partial success is possible;
- the completion error is ignored;
- planned shifts can inflate reports through expected hours/base income;
- reports use rolling windows and cap queries at 100 shifts;
- currency is hardcoded to USD;
- comma-decimal input is unsafe;
- edit/delete, actual-time entry, offline recovery, and idempotent retry are incomplete;
- password-reset links have no complete main-branch deep-link flow;
- the paywall and app assets are placeholders;
- a large `PlaceholderScreens.tsx` still concentrates unrelated workflows.

Main-branch validation:

- `npm run typecheck`: passed after clean dependency installation.
- Expo doctor: 20/21 checks; Expo patch version was behind the expected version.
- Dependency audit: one critical, one high, and one low vulnerability at the time of review.

## Recoverable completion branch

Remote branch: `origin/codex/protip365-completion-loop`
Tip: `b91d6db`
Relationship: six commits ahead of `main`, with `main` as its merge base

It adds:

- refactored shared screens and dashboard;
- mobile CRUD and reports;
- password reset;
- settings and security work;
- tests;
- canonical schema migration work;
- secret cleanup;
- Android/Expo QA fixes;
- splash/logo assets.

Isolated validation:

- dependency install: passed with zero reported vulnerabilities;
- typecheck: passed;
- tests: 4 files, 17 tests passed;
- Expo export: passed for Android, iOS, and web;
- Expo doctor: 20/21, with four Expo patch-version mismatches.

Decision:

- Recover it into a dedicated V4 foundation branch after review.
- Do not merge it directly into `main`.
- It is a better foundation, not a finished product: the separate shift-then-income flow and non-atomic save remain.

## Live Supabase audit

Connected project:

- Name: `ProTip365`
- Reference: `ztzpjsbfzcccvbacgskc`
- Database: PostgreSQL 17.6
- Health at review: available

Core live data:

| Table | Rows |
| --- | ---: |
| `users_profile` | 1 |
| `employers` | 2 |
| `expected_shifts` | 6 |
| `shift_entries` | 5 |
| `achievements` | 0 |
| `alerts` | 0 |
| `password_reset_tokens` | 0 |
| `performance_baseline` | 0 |
| `security_audit_log` | 0 |
| `user_subscriptions` | 0 |

Key findings:

- RLS is enabled on public tables, but policy roles and grants are broader than required.
- The database migration history is empty.
- The repository contains many timestamped and ad-hoc SQL scripts, so the live database cannot currently be reproduced confidently.
- `employers.user_id` is nullable.
- Relationship constraints do not fully enforce same-user ownership across employer, scheduled shift, and actual result.
- `shift_entries` correctly has a one-result-per-shift uniqueness constraint.
- Anonymous and authenticated roles have excessive privileges across public tables.
- Several policies are duplicated or lack complete update checks.
- The security audit log allows an overly broad insert path.
- Multiple security-definer functions have mutable search paths or unsafe execution grants.
- Account deletion and calendar/recent-shift functions reference obsolete table names.
- New-user profile creation references columns that do not match the live profile table and may fail silently.
- Email existence checking exposes an account-enumeration risk.
- Leaked-password protection is disabled and OTP expiry exceeds one hour.
- A historical backup schema exists but is not a substitute for a verified current backup.

Decision:

- Freeze schema changes.
- Back up and prove restore first.
- Create one baseline migration matching live state.
- Apply additive integrity/security migrations.
- Test every policy with two users.
- Add separate idempotent planned-shift creation and atomic planned-shift completion operations.
- Preserve populated physical table names initially if that lowers migration risk; use `employers`, `scheduled shifts`, and `actual results` as product concepts.

## Product and market challenge

Independent reviews agreed on:

- women are a strong majority of waitstaff and a smaller majority of bartenders;
- the practical age segment is closer to 20–35 than 20–30;
- the target should be behavioral rather than demographic;
- basic tip tracking, charts, goals, calendars, and multiple jobs are established features;
- trust failures, ads, slow entry, sync problems, and confusing multi-job handling are recurring competitor weaknesses;
- the confirmed wedge is one personal schedule across multiple employers, followed by expected-versus-actual hours and earnings;
- payday reconciliation may create a stronger recurring use case, but must be validated before being built;
- employee management, payroll, tax filing, social comparison, and POS integration should not enter the first release.

Recommended user:

> A server or bartender working scheduled shifts for one or more employers who needs one private schedule and a dependable expected-versus-actual earnings record.

Recommended promise:

> Plan every shift. Know what it actually paid.

## UX challenge

Recommended navigation:

1. Schedule
2. Stats
3. Settings

Recommended main flow:

`Add employer → enter planned shifts when the schedule arrives → view combined week → complete each shift with actual hours and tips → review expected versus actual`

Important corrections:

- The local device user is the employee; they create employers such as McDonald's and Burger King.
- Planned schedule values and actual result values remain separate.
- Entering several planned shifts must be fast.
- Completing a planned shift saves actuals and worked status together.
- Tips and hours first; advanced detail progressively disclosed.
- Planned shifts never count as earnings.
- Week calendar is the primary planning view, with list history available for review.
- Dark mode for after-shift use.
- No color-only calendar status, tiny controls, clipped large text, or icon-only actions.

Visual direction:

- calm “Shift Ledger” rather than nightlife/cocktail branding;
- warm neutral surfaces, dark text, cobalt actions, restrained green confirmation;
- strong numeric hierarchy;
- consistent light/dark themes;
- no gender-coded visual language.

## Owner-confirmed Phase I requirements

- Phase I is local-only and uses encrypted on-device SQLite.
- No account, email, login, or password is required.
- Optional six-digit passcode and device biometrics protect local access.
- CSV export and encrypted full backup/restore are included.
- English, Canadian French, and Spanish are bundled and selectable per device.
- Phase I includes a 30-day trial followed by a USD $19.99 one-time lifetime unlock.
- Cloud Sync is deferred, labeled `Coming Soon`, and planned at USD $2.99/month.
- Employer creation requires employer name and default hourly rate.
- Employers may have roles with role-specific hourly rates.
- Planned shifts snapshot the applicable employer/role rate.
- Actual clock-in/out is compared with scheduled time.
- Tips distinguish direct, pooled/mixed, tip-pool contribution, tip-out paid, and tip-share received.
- Expected payout, cumulative actual received, pending, partial, received, and disputed states are included.
- A shift, one employer's schedule, or a full week can be copied forward; actuals and payout data are never copied.
- A planned shift can be marked not worked with a required reason such as Sick or Employer Cancelled.
- Users can create, edit, delete, undo deletion, and restore shifts.

## Red-team conditions

Do not start feature implementation until:

- canonical employer, scheduled-shift, actual-result, and variance terms are locked;
- launch geography, age policy, currencies, and languages are decided;
- the database is backed up and reproducible;
- the unsafe/broken database paths have an approved remediation sequence;
- the first-session flow is validated;
- Android-first is understood as release priority, not a second codebase.

Do not launch until:

- Erase All Local Data, encrypted backup/restore, and export work on Android and iOS;
- privacy, terms, support, and deletion URLs are live;
- no unresolved high/critical security issue remains;
- Android and iOS pass the same critical-flow tests;
- time, currency, locale, offline retry, and duplicate-save cases pass;
- the beta shows repeated logging without data loss.

## External-system blocker

The existing Linear project was reachable only through an expired OAuth connection. Linear returned `invalid_grant`, so no issues or milestones were created.

The complete import-ready backlog is in `Docs/LINEAR_BACKLOG_V4.md`. Reauthenticate Linear before attempting import.

## Deliverables

- `Docs/PRD_V4.md` — full product, UX, data, architecture, security, validation, monetization, and launch plan.
- `Docs/LINEAR_BACKLOG_V4.md` — milestone and issue backlog with acceptance criteria.
- `Docs/DISCOVERY_AUDIT_2026-07-17.md` — evidence and decisions from this discovery.
- `Docs/PRODUCT_ONE_PAGER_V4.md` — approved local-first Phase I positioning, pricing, and Cloud Sync `Coming Soon` message.
