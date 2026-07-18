# ProTip365 design artifacts

## Approved direction

- [`approved/schedule-agenda.png`](approved/schedule-agenda.png) — Agenda view with employer initials/names and a date dot only when a shift exists.
- [`approved/schedule-week.png`](approved/schedule-week.png) — mobile-readable seven-day lane view.

The approved Schedule navigation is `Agenda`, `Week`, and `Day`, with Month available from the calendar control.

## Explorations

- [`explorations/schedule-day-reference.png`](explorations/schedule-day-reference.png) — interaction reference for the Day timeline; it must be redrawn without corporate logos or live clock-in/out language before implementation.
- [`explorations/landing-page/`](explorations/landing-page/) — three unapproved landing-page directions.
- [`explorations/app-mockups/claude/index.html`](explorations/app-mockups/claude/index.html) — Claude's unapproved nine-screen HTML mockup set (Agenda, Week lanes, Add Shift, dark-mode post-shift check-in and tips/payout, shift result, Stats, Employers, Settings, first run) applying the PRD §15 Shift Ledger direction; mock data is fictional and calculations are unvalidated. Rev 2 (2026-07-17, owner-directed): dark mode moved from warm brown to deep cool charcoal with white text, and Material 3 navigation adopted (extended `Add shift` FAB on Schedule screens only, active-indicator pill in the navigation bar), matching the Android-conventions block added to PRD §15. Rev 3 (2026-07-17, owner-directed): light mode is a pure white background with cool lavender `#E8E7F7` cards, cool-neutral lines/secondary text (no warm-brown cast), and soft card shadows; dark mode uses white for all text, with hierarchy carried by size and weight instead of grey. PRD §15 light-mode wording was updated to this palette on 2026-07-17; the mockups and PRD now agree.

Exploration images are not implementation specifications. Product text and calculations must follow `Docs/PRD_V4.md`.
