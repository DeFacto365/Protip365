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
| Navigation | `expo-router` (file-based) with 4 tabs, in order: Home (initial), Schedule, Stats, Settings | Owner-approved 2026-07-20; Home is the weekly receipt/payoff surface while Schedule remains the planning surface |
| State | `zustand` stores; no Redux | Small surface, testable |
| Persistence | `expo-sqlite`; repository layer in `src/data/` — UI never touches SQL directly | PRD §12; encryption (SQLCipher/op-sqlite) is a pre-release blocker tracked separately, NOT in the MVP |
| Business logic | Pure TypeScript in `src/domain/` (calculations, validation, shift state machine); no React/DB imports | CLAUDE.md rule: calculations independent from UI and persistence |
| i18n | `i18next` + `react-i18next`; keys only in UI, locales `en`, `fr-CA`, `es` | Phase I requirement |
| Testing | Jest + ts-jest for domain/data; component smoke tests optional | Testing agent owns coverage |
| Design tokens | Owner-approved 2026-07-20 “Shift Receipt”: IBM Plex Mono app-wide; light paper palette `bg #E9E4D7`, `paper #F6F2E9`, `ink #20211E`, `dim #7C7A70`, `red #D8472B`, `green #2E7D4F`, `pen #2B4BD7`, `rule #C9C3B2`; dark “night ticket” palette `bg #12151C`, `paper #1E222C`, `ink #F0EEE6`, `dim #8B92A5`, `red #FF7A5C`, `green #5CD69B`, `pen #8FA8FF`, `rule #3A4152`; square radius `0`, dashed receipt rules, hard-offset shadows, bordered stamps/chips/segmented tabs; pen for entered values, ink for computed values, green only for confirmed money, red for negatives | Owner-approved 2026-07-20 from `Docs/design/explorations/home-redesign/claude/receipt-screens.html`; 48 dp minimum targets remain required |
| In scope (owner ruling 2026-07-18: "full Phase I in the release") | Everything in PRD §9 Phase I, including: Save & add another; Copy week forward; templates & recurring rules; unplanned shifts; Day/Month views; goals/trends; passcode/biometrics; local reminders; encrypted backup/restore; trial + paywall UI. SQLCipher enabled. | Supersedes the earlier MVP deferral rows; QA plan's "Deferred" section D-01…D-11 is obsolete for these items and they must be actively tested |
| Billing implementation (owner-authorized 2026-07-19) | `expo-iap` provides the shared Google Play / StoreKit adapter. Trial enforcement stays DISABLED until signed testing-track builds complete purchase, pending-payment, acknowledgement, restore, lapse, and offline-refresh testing. | Store products and signed-store testing are still release gates; local data remains usable without a network connection. |
| Still deferred | CSV import, soft-delete undo (confirm dialog suffices), completion draft recovery, Cloud Sync | Undo/draft-recovery per owner ruling 2026-07-18; Cloud Sync remains `Coming Soon`. |

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
