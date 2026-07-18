# ADR-001 — ProTip365 V4 Phase I architecture

Status: accepted (owner-authorized, 2026-07-17)
Authorized by: Jacques (owner) — "It's now time to build the app."

This record satisfies the CLAUDE.md requirement that an approved architecture
document exist before the app is scaffolded. It binds all agents (Codex, Claude,
subagents) until superseded.

## Decisions

| Concern | Decision | Rationale |
|---|---|---|
| Location | `app/` at repo root | Single active codebase folder per repository policy |
| Framework | Expo SDK (React Native) + TypeScript, single codebase | Fixed by PRD §1/§14 |
| Navigation | `expo-router` (file-based) with 3 tabs: Schedule, Stats, Settings | PRD §7 IA; Material 3 patterns per PRD §15 |
| State | `zustand` stores; no Redux | Small surface, testable |
| Persistence | `expo-sqlite`; repository layer in `src/data/` — UI never touches SQL directly | PRD §12; encryption (SQLCipher/op-sqlite) is a pre-release blocker tracked separately, NOT in the MVP |
| Business logic | Pure TypeScript in `src/domain/` (calculations, validation, shift state machine); no React/DB imports | CLAUDE.md rule: calculations independent from UI and persistence |
| i18n | `i18next` + `react-i18next`; keys only in UI, locales `en`, `fr-CA`, `es` | Phase I requirement |
| Testing | Jest + ts-jest for domain/data; component smoke tests optional | Testing agent owns coverage |
| Design tokens | Light: white bg, `#E8E7F7` cards, cobalt `#2B4BD7` actions, cool neutrals; Dark: `#0E1118` bg, ALL text white; green only for confirmed money; M3 extended `Add shift` FAB on Schedule only, nav active-pill, 48 dp targets | Owner-approved mockups rev 3 (`Docs/design/explorations/app-mockups/claude/index.html`) |
| In scope (owner ruling 2026-07-18: "full Phase I in the release") | Everything in PRD §9 Phase I, including: Save & add another; Copy week forward; templates & recurring rules; unplanned shifts; Day/Month views; goals/trends; passcode/biometrics; local reminders; encrypted backup/restore; trial + paywall UI. SQLCipher enabled. | Supersedes the earlier MVP deferral rows; QA plan's "Deferred" section D-01…D-11 is obsolete for these items and they must be actively tested |
| Still deferred | Real store billing (IAP adapter — trial enforcement stays DISABLED until it ships), CSV import, soft-delete undo (confirm dialog suffices), completion draft recovery, Cloud Sync | Billing needs store products + dev-build testing; undo/draft-recovery per owner ruling 2026-07-18 |

## Phase I constraints (unchanged)

No account, no Supabase, no network dependency. Android first; iOS from the same
codebase. `Archive/` stays untouched.

## Folder contract

```
app/
  app/            # expo-router routes (tabs, modals)
  src/domain/     # pure TS: calc.ts, validate.ts, types.ts (+ tests)
  src/data/       # sqlite repositories, migrations
  src/state/      # zustand stores
  src/i18n/       # locales en / fr-CA / es
  src/ui/         # shared components, tokens.ts
```
