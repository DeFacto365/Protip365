# ProTip365 Release Validation - 2026-06-06

## Summary

ProTip365 is not 100% complete for release. The repo-side validation pass is green after the shared Expo app cleanup and archive cleanup. External release blockers remain open for public SSL/hosting, credential rotation proof, Supabase deployment proof, and signed store build evidence.

Current validation refresh: 2026-06-06 22:28 EDT.

## Linear Status Checked

- `RFP-24` UI/UX expert review: Done.
- `RFP-73` page-by-page mobile UX review: Done.
- `RFP-76` UX implementation backlog: Done.
- `RFP-113` final autonomous quality gate: In Progress.
- `RFP-139` public privacy/terms/support/deletion URLs: In Progress.
- `RFP-140` native subscriptions and signed release builds: In Review.
- `RFP-141` exposed FTP credential rotation: In Progress.
- `RFP-157` hardcoded app secrets: In Review.
- `RFP-158` support email function sanitization: In Review.
- `RFP-25` relaunch readiness: Backlog.

`RFP-158` appears fixed in the repo: `supabase/functions/send-support/index.ts` validates subject/message length, escapes rendered HTML, and returns a generic error response. Linear status still needs review/closure.

## Changes Made

- Updated `ProTip365Shared` from `expo@~56.0.8` to `expo@~56.0.9`, matching the version expected by the current Expo SDK checks.
- Fixed `ProTip365/supabase/functions/delete-user/index.ts` catch handling so Deno can type-check the function under strict unknown catch semantics.
- Archived legacy native iOS/Xcode material, root legacy docs, backups, unused website templates/demo assets, WordPress exports, older ProTip365 landing variants, and obsolete browser tooling reference material under `Archive/`.
- Kept current active website material limited to `Docs/website/index.html`, legal/support/delete-account pages, upload docs/scripts, and referenced `Docs/website/images/` assets.

## Validation Passed

- `git diff --check`
- `cd ProTip365Shared && npm run typecheck`
- `cd ProTip365Shared && npm audit --audit-level=moderate`
- `cd ProTip365Shared && npx expo-doctor`
- `cd ProTip365Shared && npx expo install --check`
- `cd ProTip365Shared && npx expo export --platform all`
- `deno check --node-modules-dir=auto supabase/functions/send-support/index.ts`
- `deno check --node-modules-dir=auto supabase/functions/delete-account/index.ts`
- Active website static asset reference check: passed, no missing local assets in current pages.
- Active-path secret scan: no tracked literal service-role key, App Store shared secret, Google Maps API key, FTP password, or Resend API key found. Remaining hits are placeholders, docs, or environment-variable reads.

## Native Build Warnings

The legacy native Swift project is archived and no longer the active app source. The current source of truth is `ProTip365Shared/`.

## Security Review

Tracked secret scan found only placeholders/examples or expected environment-variable references:

- `.env.example`: empty `APP_STORE_SHARED_SECRET=` placeholder.
- archived placeholder Google key in legacy Android backup.
- documentation examples using placeholder build secrets.
- runtime environment variable reads for `SUPABASE_SERVICE_ROLE_KEY`.
- FTP upload script reads credentials from environment variables.

No active tracked literal service-role key, App Store shared secret, Google Maps key, or FTP password was found in the checked active app paths.

## Remaining External Blockers

- Public URLs still fail SSL certificate verification with expired certificate result `ssl_verify=10`:
  - `https://protip365.com/`
  - `https://protip365.com/privacy`
  - `https://protip365.com/privacy-policy.html`
  - `https://protip365.com/terms`
  - `https://protip365.com/terms-of-service.html`
  - `https://protip365.com/support`
  - `https://protip365.com/delete-account`
- Provider-side credential rotation proof is still required for `RFP-141` / `RFP-157`.
- Supabase deployment proof is still required for `RFP-158`.
- Signed release build and store subscription product evidence is still required for `RFP-140`.
- Final `Funct-Dev-Security` closure cannot be recorded until the external blockers are resolved and retested.
