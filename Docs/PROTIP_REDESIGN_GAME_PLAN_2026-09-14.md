# ProTip365 — UI/UX and functional improvement game plan

Date: September 14, 2026
Status: proposed implementation plan, requested by the owner. Owner clarification: the app is not live and has no users to migrate. Deliver one complete pre-launch release. This document does not silently supersede the approved PRD, architecture, design tokens or store pricing. It identifies the proposed changes to those decisions below.

## 1. Outcome

Make ProTip365 the app a restaurant worker can comfortably use after a busy shift to answer:

**What did I earn? What have I received? What am I still waiting for?**

Scheduling supports that promise. The app should feel attractive and familiar on iOS and Android, remain useful offline, and make money records understandable without requiring bookkeeping knowledge.

Keep the active Expo/React Native codebase, pure calculation layer, local database, employer and role records, translations, purchase infrastructure and backup facilities. Verify these capabilities rather than assuming every release gate has passed. Keep the restaurant-worker audience. A nursing agreement engine is a separate product expansion and is not part of this repair.

Deliver one complete release, built and verified through two internal workstreams:

1. **Workstream A — easier daily use:** refreshed design, better Home, faster shift entry/completion, clear terminology, drafts, accessibility and reliable corrections.
2. **Workstream B — trustworthy payment tracking:** dated receipts, payments covering multiple shifts, partial settlement, reconciliation, a clean payment model and useful money summaries.

Do not combine the redesign with cloud sync, employer management, POS integrations, tax filing, payroll processing or a framework replacement.

## 2. Evidence and limits

This is a code- and requirements-grounded plan, not a completed hands-on usability audit. Native screenshots, interaction measurements and participant results must be collected in milestone 0. Existing screenshots may be obsolete: `Docs/store-assets/CAPTURE.md` explicitly warns that some assets show an older design.

Confirmed starting points:

| Observation | Source | Product consequence |
|---|---|---|
| Home places a detailed weekly receipt before unfinished shifts | `app/app/(tabs)/index.tsx` | The daily action can be buried under reporting |
| The second completion step exposes numerous money fields together | `app/app/complete/[id].tsx` | A common shift requires navigating fields irrelevant to that worker |
| Payouts are cumulative values attached to individual shifts | `app/src/domain/types.ts`, `app/src/data/repositories.ts` | A payment covering several shifts has no first-class dated allocation record |
| Financial calculations are separated from UI and persistence | `app/src/domain/calc.ts`, `stats.ts` | Preserve and extend this boundary; do not rewrite arithmetic into screens |
| Approved design and current tokens differ in some details | `Docs/ADR-001-v4-architecture.md`, `app/src/ui/tokens.ts` | Establish one new documented design reference before changing components |
| Lifetime and monthly options unlock the same local features | `Docs/PRODUCT_ONE_PAGER_V4.md` | Recurring-revenue strategy needs a separate decision; a cosmetic redesign does not fix it |

## 3. Proposed visual direction

**A calm earnings app with a distinctive shift receipt at the end.** The receipt becomes a memorable result, rather than the visual structure of every form and setting.

### Design system

- Light mode: clean off-white background, white surfaces, dark ink and one restrained teal/green brand accent. Use warm paper only in the completed-shift receipt. These are proposed directions, not approved final color values.
- Dark mode: neutral charcoal surfaces, clear foreground contrast and restrained accents. Design dark mode explicitly instead of merely inverting colors.
- Typography: platform-appropriate sans-serif for navigation, labels and instructions; tabular numerals for money. Reserve monospaced text for receipt details. Limit all-caps to short secondary labels.
- Hierarchy: one obvious next action; one primary total per section; secondary breakdown available on demand. Do not display six equally prominent financial numbers.
- Components: consistent spacing, moderately rounded cards and controls, quiet dividers, minimal shadows. Avoid paper borders, stamps and decorative handwriting on editable forms.
- Money language: green can mean confirmed receipt; a separate neutral treatment means calculated earnings; amber with a label means pending or needs attention. Never rely on color alone.
- Motion: brief confirmation after saving; respect reduced-motion settings. No celebratory animation for uncertain or unpaid amounts.
- Brand: retain the ProTip365 identity. Do not spend this phase redesigning the logo or inventing testimonials.

### Required design deliverables

Produce one coherent clickable prototype covering Home, Schedule, Add shift, Close shift, Shift result, Money, Record payment, Employer setup and Settings. Show iOS and Android versions of the important controls. Include light/dark, empty, incomplete, error, loading, long-content and large-text states.

Review the core flow before polishing every screen. Prototype values must come from the agreed money examples, not arbitrary attractive totals. The acceptance review uses the actual small-screen layouts, not only enlarged desktop presentations.

## 4. Navigation and screens

Proposed four tabs: **Home · Schedule · Money · Settings**. Money replaces the top-level Stats destination and contains both Payments and Insights. This is a proposed change to the four-tab ADR; document the supersession before implementation. Existing statistics remain available.

| Screen | First thing the user sees | Main action | Secondary content |
|---|---|---|---|
| Home | A shift that needs closing, if one exists | Finish shift | This week's earnings, pending receipts, next shift |
| Schedule | Readable agenda with employer name and time | Add shift | Week/Day modes, Month picker, templates, copy week |
| Close shift | Confirmed/default hours and the employer's usual tip arrangement | Save shift | Changed hours, extra fields and corrections |
| Shift result | Earned amount and clear received/pending breakdown | Done | Detailed receipt, edit, share/export |
| Money / Payments | Expected amounts grouped by employer and payment period | Record payment | Partials, discrepancies, history |
| Money / Insights | Earnings and effective hourly rate for a chosen period | Change period/employer | Trends, goals and detailed totals |
| Settings | Employers, privacy, backup and preferences | Context-specific | Purchases, language, support |

### Home rules

1. If a shift needs closing, show it above the weekly totals. Provide a way to see all unfinished shifts.
2. If no action is pending, show a concise weekly summary and the next scheduled shift.
3. A future shift opens its details; the primary CTA must not encourage completing it prematurely. Permit deliberate corrections/unplanned work through explicit actions.
4. Pending payments are distinct from missing shift details. A user can finish recording work and still await payment.
5. With no records, show a useful first action rather than a full receipt of zeroes.
6. An employer name accompanies every mixed-employer amount or shift where ambiguity is possible.

### Scheduling

Keep existing Agenda/Week/Day and Month access, templates, recurring rules and copy-forward. Default to a readable agenda on small screens; preserve the user's selected view. Show date, employer, role if relevant, hours and status without needing color decoding.

Quick add needs employer, date and times. Rate and breaks come from clearly visible defaults. Optional forecasts and notes sit behind an expansion. Save-and-add-another keeps the employer and sensible settings. Warn about overlaps while allowing an intentional override. Copy only scheduled information; never copy actual earnings or payments.

### Employer setup

First-run setup asks for employer name, hourly rate and currency confirmation. Role can wait. Explain local storage briefly and offer optional app lock without creating an account.

Then capture the usual tip arrangement when it becomes relevant: direct tips, pool share, or mixed; common tip-out method; whether money is normally received that day or later. Defaults are editable and cannot silently rewrite historical records. Do not infer legal or payroll rules from the employer's name or the user's location.

### Close a shift

The common path fits a short sheet or screen:

1. **Hours:** show scheduled times and breaks; confirm in one action or edit exceptions.
2. **Tips:** show only fields required by this employer's arrangement.
3. **Receipt timing:** confirm what was received now and what is expected later; allow “I don't know yet.”

Move sales, other income, rate changes and estimated deduction details into labeled optional sections. Keep them available to existing users. Selecting a tip method changes the form and examples; it does not erase entered values without an explanation.

Use familiar explanations: “Tips before sharing,” “Shared with the team,” “Your share from the pool,” “Received today.” Test EN, fr-CA and Spanish wording with users. Terminology must reflect actual money movement, not just rename every current database field.

Show a clear preview before saving, with a brief breakdown. Save atomically. If the app is interrupted, restore the draft; if it is already saved, opening the draft must not create a duplicate. Editing later preserves original scheduled values and updates affected summaries.

## 5. Functional redesign: earnings are not receipts

### Definitions

| Term | Meaning |
|---|---|
| Recorded earnings | Wages calculated from recorded work plus tips/other income after recorded sharing; not a verified payslip |
| Received | Money the user confirms receiving, with a date and source |
| Expected later | A user-confirmed amount expected through a specific payout route |
| Unknown | Information not yet supplied; must not become zero |
| Needs review | Unmatched money, inconsistent entries or a user-reported discrepancy; not a legal finding |
| Estimated net | Optional user-configured budgeting estimate, clearly separate from actual deposits |

Do not compare gross wage calculations directly with a net bank deposit and label the difference missing pay. Wage deductions and the treatment of tips may differ. The payment workstream initially reconciles comparable user-confirmed payout amounts. Full payslip interpretation remains outside this plan.

### Worked acceptance example

A worker records $200 in tips and $40 shared with the team: net tip income is $160. They received $60 and expect $100 later. Another shift has $80 expected later. A subsequent $150 tip payment is allocated $100 to the first shift and $50 to the second, leaving $30 outstanding.

Required result: tip earnings never increase when that $150 payment is entered. The second shift remains partially paid. The first shift's receipt history retains both receipt events. Wages are separate from this example. A correction or reversal updates balances without silently rewriting the original events.

### Proposed data additions

Keep scheduled and actual shift records. Add, behind the existing repository boundary:

- **Expected payout items:** employer, optional shift link, type, confirmed comparable amount, currency and optional expected date/period.
- **Receipt events:** amount, currency, received date, employer/source, optional reference and correction/reversal metadata.
- **Allocations:** link part of a receipt to one or more expected items. A receipt may remain partly unallocated.

Derive balances and statuses from the records. Avoid maintaining several editable totals that can disagree. Prevent duplicate saves, cross-currency allocation, excessive allocation and accidental cross-employer matching. Do not infer “late” when no expected date is known. Show overpayments/unallocated funds rather than clamping them away. Clearly distinguish settled, partial, awaiting, unknown and disputed.

For card/cash and mixed-pool situations, write real worked examples with participants before schema implementation. Specifically prevent double-counting tips collected for the pool and the share returned to the worker.

### Pre-launch data model

The owner confirms that ProTip365 is not live and has no users to migrate. Implement the clean target schema directly; customer migration, legacy opening balances, backward-compatible exports and production downgrade planning are outside scope. Preserve source and any useful developer fixtures. Use a separate disposable test database for schema changes; do not assume permission to erase unidentified local data. Build and test backup/restore against the new schema for the first public release.

## 6. iOS and Android quality

Shared product and data rules; platform-appropriate presentation and navigation. Do not create a second codebase.

| Area | iOS | Android |
|---|---|---|
| Navigation | Familiar tab bar, sheets and back gestures | System/predictive Back, appropriate sheets, edge-to-edge insets |
| Controls | Platform date/time pickers, clear sheet dismissal | Android pickers, keyboard/system Back behaviour |
| Type | Dynamic Type and VoiceOver | System font scaling and TalkBack |
| Touch | Aim for at least 44pt targets; preserve current generous shared targets | At least 48dp targets |
| Layout | Safe areas, home indicator, small iPhone and large text | Gesture and three-button navigation, compact phones and varied screen sizes |
| Interaction | Keyboard never hides money entry or Save; draft retained | Same requirement, including hardware/system Back |
| Purchases | StoreKit purchase/restore/lapse scenarios | Google Play purchase/pending/restore/lapse scenarios |

Use semantic screen-reader labels for amounts and payment status, sensible focus order and no color-only meaning. Target 4.5:1 normal-text contrast and 3:1 large text and essential control boundaries where applicable. Test large accessibility text without truncating amounts or hiding actions. Verify reduced motion and meaningful error announcements on-device. These are acceptance targets, not claims of current compliance.

Official references checked for planning: [Apple accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [Apple UI design tips](https://developer.apple.com/design/tips/), [Android predictive Back](https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back), [Android edge-to-edge](https://developer.android.com/design/ui/mobile/guides/layout-and-content/edge-to-edge). Read the exact Expo v57 documentation required by `app/AGENTS.md` before implementation.

## 7. Delivery backlog and order

| Milestone | Work | Definition of done | Planning effort |
|---|---|---|---:|
| 0 — Baseline | Build the current app on both platforms; capture core flows; verify current tests and backups; observe 6–8 target users | Current defects separated from proposed improvements; baseline completion time/errors recorded; safe disposable test data | 2–3 days |
| 1 — Experience specification | Finalize terminology, money examples, prototype and component system; test with 6–8 workers including direct/pooled tips | Users can explain earned vs received vs pending; common close-out succeeds without coaching; proposed ADR/PRD changes documented | 4–6 days |
| 2 — Daily workflow implementation | Shared components, Home priority, quick add, employer defaults, shorter completion, draft recovery, localized copy | Existing capabilities remain accessible; native critical flows and regression pass; measured daily entry improves | 8–12 days |
| 3 — Payment model implementation | Receipt/allocation domain, clean schema, money screens, export/restore, correction handling | Worked money scenarios and new-schema fixtures reconcile exactly | 7–10 days |
| 4 — Cross-platform hardening | Real-device usability/accessibility, interruption, offline, overnight, locale and purchase checks | No unresolved data-loss, incorrect-money or critical-flow failures on either platform | 4–6 days |
| 5 — Controlled beta | Recruit consenting workers, observe repeated real use, fix failures and refresh store assets | Four-week behaviour evidence, clear release decision, no unsupported public claims | 4 weeks elapsed; 3–5 active workdays initially plus fixes |

The effort figures above are a human-team planning reference, not a measured Codex delivery schedule. Codex will carry the implementation through both workstreams and verification. Re-estimate from the baseline build and prototype rather than treating 6–9 weeks as a commitment or required waiting period. Native build access, store testing and any external user-study period remain real calendar dependencies. The proposed four-week beta is an evidence-gathering option, not a reason to delay implementation.

Both workstreams belong to the same complete release. Use internal builds and checkpoints to isolate failures; do not split the public release merely to separate UI work from payment changes. Validate money calculations and persistence before release.

### First implementation batch

Start with the existing Home and completion flows, shared typography/components, and a representative employer-default configuration. Capture before/after on both platforms. Establish the first reliable synthetic money scenarios before adding payment storage. Keep purchase behaviour unchanged during this batch.

### File map

- Home/navigation: `app/app/(tabs)/index.tsx`, `_layout.tsx`.
- Schedule and entry: `app/app/(tabs)/schedule.tsx`, `app/app/shift-form.tsx`, `templates.tsx`.
- Close-out: `app/app/complete/[id].tsx`.
- Employer onboarding: `app/app/onboarding.tsx`, `employers.tsx` and employer store/domain.
- Design system: `app/src/ui/tokens.ts`, `typography.tsx`, `components.tsx`, `DateTimeField.tsx`.
- Money: `app/src/domain/types.ts`, `calc.ts`, `stats.ts`, new receipt/allocation modules; repository/store changes behind their current boundaries.
- Data safety: `app/src/data/db.ts`, `repositories.ts`, `backup.ts`, and backup/restore state.
- All copy: `app/src/i18n/en.ts`, `fr-CA.ts`, `es.ts`.
- Canonical documents: update the PRD, one-pager, ADR, design index, backlog and QA plan together as decisions are adopted. Keep `Archive/` reference-only.

## 8. Verification and success measures

### Functional scenarios required on both platforms

Direct tips; pooled tips; mixed tips; no tips; unknown amounts; cash retained; delayed card tips; partial/multi-shift payment; unallocated excess; edited/reversed receipt; cancellation; unplanned shift; overnight shift with breaks; multiple employers; rate change without rewritten history; decimal comma; EN/fr-CA/Spanish; DST/time-zone boundary; interrupted save; duplicate tap; restored backup; new-schema seeded balances; expired subscription with records still accessible.

Automate deterministic calculations, allocations, persistence, idempotency and backup round trips. Use targeted UI tests for critical user journeys and native manual checks for appearance, keyboard, accessibility and store behaviour. Run the repository's TypeScript and Jest checks and the relevant release regression. Screenshot review alone cannot establish correctness.

### Proposed usability gates

- First employer and first shift: median under 2 minutes after the user understands the task.
- Common repeat close-out: median under 30 seconds without coaching; exceptions may take longer.
- Record and allocate a straightforward payment: under 45 seconds.
- At least 7 of 8 formative participants distinguish earnings, received funds and pending funds correctly.
- No silent income duplication, lost receipt or stored-total discrepancy in the defined test suite.
- No clipped amounts or inaccessible primary actions in the tested large-text and screen-reader flows.

Small studies are formative, not population-level proof. Compare against the baseline; revise targets if the actual task complexity warrants it, recording the reason.

### Four-week beta decision

Target 20–30 consenting workers, including both platforms and more than one tip arrangement. Measure the proportion of worked shifts logged, repeat weekly use, unresolved entries, payment-check completion and support burden. A proposed continuation gate is at least 60% of activated participants still using the app in week 4 and a median of at least 70% of worked shifts recorded among those with shifts that week. Treat these as decision thresholds, not industry benchmarks.

Use voluntary diaries or opt-in, aggregated research exports initially. Do not silently add remote analytics to the local-only architecture. Do not collect actual financial amounts merely to measure screen completion. Separate staff-assisted success from independent use.

## 9. Monetization and release boundaries

There are no live customers or subscriber transitions to manage. Treat the pricing and entitlement setup as pre-launch product design. Current documented USD19.99 lifetime versus USD2.99/month makes lifetime cheaper after seven monthly payments; recurring income therefore requires a separate offer decision grounded in usage.

After beta, examine whether buyers value continuing payment reconciliation enough to support an annual plan for new customers, or whether a one-time utility remains the honest fit. Choose the launch offering based on continuing user value; no legacy-customer packaging is required. Cloud sync remains unavailable until its separate architecture, privacy and recovery gates are met. No new price is approved by this document.

Refresh store screenshots and privacy/support copy only from the released behaviour. Test store billing on actual signed builds. Publishing, price changes and rollout occur as explicit release actions after results are reviewable; this plan performs none of them.

## 10. Proposed changes to existing decisions

| Existing decision | Proposed change | Adoption point |
|---|---|---|
| Receipt styling throughout the app | Receipt for results; simpler main surfaces and forms | Prototype/design decision in milestone 1 |
| Home / Schedule / Stats / Settings | Home / Schedule / Money / Settings; preserve Insights within Money | Navigation decision in milestone 1 |
| Broad two-step completion form | Employer-specific common path with progressive detail | Workflow acceptance in milestone 1 |
| Cumulative per-shift payouts | Dated receipt and allocation records with a clean pre-launch schema | Data/ADR review before milestone 3 |
| Completion draft recovery deferred | Make recovery part of the daily-flow repair | Milestone 2 specification and tests |
| Existing lifetime/monthly offer | Review the pre-launch offering after usability and value testing | After beta evidence |

The immediate objective is a reliable, appealing daily app. Success is a worker closing a shift easily and trusting the explanation of their money—not the number of redesigned screens or added features.
