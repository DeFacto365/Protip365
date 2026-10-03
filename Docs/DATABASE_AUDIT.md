# Database review — 2026-10-03

## Architecture and compatibility

The redesigned app currently has no Supabase client or cloud synchronization.
Android/iOS use encrypted SQLite, with a SecureStore-held key, and the web preview
uses localStorage. Supabase project `ztzpjsbfzcccvbacgskc` is the older backend.
Fixing that backend does not migrate existing cloud records into the new app.
The legacy tables hold decimal dollars; the new app holds integer cents.
No unit conversion or production-record migration was performed.

This review covers schema compatibility, data integrity and access security.
It is not a legal/privacy certification or a guarantee against all runtime errors.

## Live fixes applied

- Anonymous clients have no application-table privileges.
- Signed-in clients have only owner-scoped CRUD on ordinary records. Explicit
  UPDATE checks prevent changing ownership. Duplicate policies were consolidated.
- Subscriptions and audit events are read-only to their owner. Reset tokens and
  performance baselines are backend-only. Client TRUNCATE, REFERENCES and TRIGGER
  privileges were removed, as was access to global monitoring views.
- Composite foreign keys prevent linking another user's employer or scheduled
  shift. Indexes cover these relationships and previously unindexed foreign keys.
- Calendar/recent-shift RPCs now query expected_shifts/shift_entries instead of a
  nonexistent shifts table. They retain legacy gross-tip/dollar semantics.
- Account-data deletion now uses real tables in foreign-key-safe order and
  requires auth.uid(). Email enumeration and audit-writing definer functions are
  unavailable to clients. Definer functions have fixed search paths.
- The unused new-user trigger function no longer references nonexistent profile
  columns. No signup trigger was attached or signup workflow introduced.
- Check constraints reject negative/non-finite rates, tips and sales, invalid
  hours above 24, invalid deductions and invalid break lengths. Null optional
  values and zero tips remain valid.
- Both deployed deletion endpoints authenticate with getUser(), invoke checked
  transactional data cleanup, then delete only that authenticated identity.
  A cleanup failure stops before auth deletion. JWT verification stays enabled.
- Email OTP expiry changed from 86400 to 1800 seconds; leaked-password protection
  enabled and verified after reopening the settings.

Existing counts remained: 1 auth user, 1 profile, 2 employers, 6 scheduled shifts,
5 entries. No existing records were changed or deleted by the audit.

## New app storage fixes

Parallel initialization now shares one promise, preventing competing keys and
connections. The saved key must be 64 hexadecimal characters. Native opening
checks SQLCipher support before creating the state table and closes failed
connections. Failures remain visible and retryable; no automatic database/key
reset is performed.

## Verification

- Live SQL regression passed under the authenticated role: own-record access,
  cross-user isolation, ownership reassignment rejection, cross-owner link
  rejection, protected subscription/log/token privileges, anonymous denial,
  overnight shifts, zero tips, correct RPC totals, negative/NaN rejection,
  invalid-hours rejection and account cleanup with a default employer.
- Synthetic fixtures were inside a transaction and rolled back. The other
  fixture owner's records survived account cleanup.
- Both public deletion endpoints return HTTP 401 without authorization.
- 34 automated app tests pass, including 4 new native-storage mock tests and
  6 deletion-handler tests. TypeScript validation passes.
- Native SQLCipher checks are mocked here; run the updated Android build on the
  emulator before release to confirm the actual SQLCipher build and persistence.
- Actual auth-account deletion was not performed against the existing user.
  Data cleanup and endpoint control flow were tested separately. Data cleanup
  and Auth API deletion cannot be one database transaction; a later Auth failure
  returns a retryable error.

## Remaining notices and release limits

The live security advisor now has only intentional signed-in schema visibility
and the authenticated account-deletion SECURITY DEFINER notice. All relevant
tables have RLS and owner checks; the deletion RPC has no caller-supplied user ID.
See [GraphQL visibility guidance](https://supabase.com/docs/guides/database/database-linter?lint=0027_pg_graphql_authenticated_table_exposed)
and [definer function guidance](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).
Performance advisories are informational: archived backup tables without primary
keys, unused indexes on this low-traffic project, and absolute Auth connections.
No RLS initialization/duplicate-policy/missing-FK-index notices remain.

Managed Postgres is 17.6.1.052. Supabase documents newer security maintenance
releases; schedule a managed upgrade with its backup/restart process separately.
No database-engine restart or paid-plan change was made.

Legacy subscriptions must be written only by a trusted purchase-verification
backend. Restoring client subscription writes would reopen a security issue.
This does not verify the new app's Google Play purchase sandbox.
Existing-user data migration into the redesigned app is still a release gate;
UI changes alone do not carry old Supabase records into the local store.

## Reproduction and migrations

`supabase/tests/legacy_database_regression.sql` contains rollback-only fixtures.
Run it as an administrative database session; do not strip its transaction.
Migrations amend the existing project and are not a fresh-schema bootstrap.
The Supabase migration tool assigned live versions; local filenames mirror them:

- 20261003164833 — harden_legacy_database
- 20261003165006 — index_owner_relationships
- 20261003165251 — validate_shift_amounts

Function source is under supabase/functions, deployed as delete-account v4 and
delete-user v2. No database keys, JWTs or personal row exports are included.
