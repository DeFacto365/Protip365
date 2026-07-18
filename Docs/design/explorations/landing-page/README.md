# Landing-page explorations

## Original drafts

These directions were rejected for excessive content density and remain only as audit evidence:

1. [`01-shift-ledger.png`](01-shift-ledger.png) — balanced product story, capabilities, privacy, and pricing.
2. [`02-week-in-focus.png`](02-week-in-focus.png) — weekly planning is the dominant visual.
3. [`03-private-shiftbook.png`](03-private-shiftbook.png) — local privacy and expected-versus-actual positioning.

Known draft limitations:

- The production Google Play URL is not verified; `Store link required` is intentional.
- iOS must remain labeled `Coming soon on the App Store`.
- Generated references may contain deprecated clock-in/out wording, corporate logos, or unsupported PDF export copy. These must be corrected before implementation.
- No original direction is approved.

## UX review

- [`UX_AUDIT_2026-07-17.md`](UX_AUDIT_2026-07-17.md) records the hierarchy, content-density, accuracy, and accessibility issues found in these original drafts.

## Simplified directions

These replacements apply the audit recommendation: one promise, one dominant screenshot, three short outcomes, compact privacy/pricing reassurance, and one primary action.

1. [`revised/01-quiet-weekly-control.png`](revised/01-quiet-weekly-control.png) — balanced multi-employer schedule, earnings, and privacy story.
2. [`revised/02-week-at-a-glance.png`](revised/02-week-at-a-glance.png) — the weekly schedule is the primary visual proof.
3. [`revised/03-honest-payoff.png`](revised/03-honest-payoff.png) — expected-versus-actual earnings lead the story.

These are visual hierarchy explorations, not implementation specifications. Embedded mock data must be checked against the PRD before implementation. No revised direction is approved until the owner selects it.

## Deployment

- `claude/index.html` is deployed to Vercel (owner-created project `florabump/protip365`): **https://protip365.vercel.app** (production, 2026-07-18). Redeploy after edits; the Google Play CTA is still a placeholder link.

## Claude draft (2026-07-17)

- [`claude/index.html`](claude/index.html) — a working HTML exploration applying the UX-audit structure (one promise, one dominant screenshot, three outcomes, compact reassurance, single Google Play action with `Coming soon for iOS`) in a warm editorial style aimed at the 20–35 audience: cream/dusk palette, coral accent, Fraunces/Outfit type, fictional color-coded employers.
- Draft limitations: the Google Play link is a placeholder pending a verified store URL, fonts load from Google Fonts and must be self-hosted for production, and privacy copy assumes encrypted local storage passes release tests. Not approved until the owner selects it.
- Rev 2 (2026-07-17, owner-directed): trilingual EN / FR-CA / ES via an in-page language switcher (auto-detects browser language, translates the phone mock including Québec 24-hour times), and local pricing shown as `$19.99 once — or $2.99/month`. The former pricing conflict is resolved: the PRD, one-pager, product-marketing context, and Linear backlog were updated on 2026-07-17 to the same two local pricing options. Open question for the owner: future Cloud Sync is still planned at $2.99/month, the same price as the local monthly plan — decide whether local monthly subscribers will get Cloud Sync included or whether the Cloud price changes.

## External-agent exploration

- [`claude/index.html`](claude/index.html) — standalone Claude landing-page concept. It is unapproved, uses a placeholder Google Play link, and loads Google Fonts externally; keep it outside the production architecture unless explicitly selected and reviewed.
