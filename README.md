# ProTip365

ProTip365 is being reset around a single Android-first, iOS-compatible product: a private, local-first schedule, tip, and earnings app for restaurant workers with one or more employers.

## Current status

V4 implementation is in progress (owner-authorized 2026-07-17). The Phase I MVP is being built in [`app/`](app/) per [`Docs/ADR-001-v4-architecture.md`](Docs/ADR-001-v4-architecture.md) — Expo React Native + TypeScript, local SQLite, no account/network. Build to-do list: [Linear · Protip365 project](https://linear.app/defacto365/project/protip365-e3ed5a412e11/overview) (RFP-213 … RFP-217).

There is intentionally no Supabase runtime or public website implementation at the repository root. The superseded V3 implementation is preserved under `Archive/v3-legacy-2026-07-17/`.

## Source of truth

1. [`Docs/PRD_V4.md`](Docs/PRD_V4.md) — approved product, UX, data, privacy, pricing, and release requirements.
2. [`Docs/PRODUCT_ONE_PAGER_V4.md`](Docs/PRODUCT_ONE_PAGER_V4.md) — concise Phase I positioning and pricing.
3. [`Docs/LINEAR_BACKLOG_V4.md`](Docs/LINEAR_BACKLOG_V4.md) — implementation backlog and acceptance criteria.
4. [`Docs/design/`](Docs/design/) — approved design direction and unapproved explorations, clearly separated.
5. [`.agents/product-marketing.md`](.agents/product-marketing.md) — current product-marketing context for agents.

## AI collaboration

- [`CLAUDE.md`](CLAUDE.md) defines Claude/Fable as a read-only reviewer by default and protects the V4 architecture and folder structure.
- Codex remains the primary implementation and architecture agent.
- External-agent recommendations must be reviewed against the canonical V4 sources before implementation.

## V4 implementation boundaries

- One shared cross-platform mobile codebase.
- Android ships first; iOS must pass the same critical-flow tests.
- Phase I uses encrypted on-device SQLite.
- Phase I requires no account, email, password, Supabase, or network connection.
- Superseded code and claims in `Archive/` are reference-only and must not be restored without explicit review.

## Repository policy

- Keep active root folders limited to current source, current documentation, and required configuration.
- Move superseded material into a dated folder under `Archive/`; do not mix it with active files.
- Never use archived store URLs, testimonials, security claims, or pricing without re-verification.
- Generated dependencies and build output are not source and must remain ignored.
