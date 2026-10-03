# V3 legacy snapshot — 2026-07-17

This folder preserves the implementation and supporting material that were active before the V4 local-first reset.

## Contents

- `app/ProTip365Shared/` — Expo/React Native shell tied to Supabase authentication and the superseded workflow.
- `backend/supabase/` — historical migrations, functions, guides, and ad-hoc database scripts.
- `website/` — previous static landing/legal/support website and legacy screenshots.
- `docs/` — prior store copy, discovery snapshot, cleanup record, and release validation.
- `config/` — superseded root environment template and iOS-specific Cursor rule.

## Why it is archived

V4 Phase I requires no account or remote runtime and uses encrypted on-device SQLite. The V3 app, database scripts, website claims, screenshots, and store metadata do not represent the approved product.

## Rules

- Reference only; do not build, deploy, or publish from this folder.
- Do not treat any archived Google Play ID, App Store link, pricing, testimonial, security statement, or database migration as current.
- Recover domain logic or test cases only after comparing them with `Docs/PRD_V4.md`.
- Generated dependencies may exist in a local checkout but are ignored and are not source.

Snapshot source commit: `97b961a` (`Align mobile data layer with live Supabase schema`).
