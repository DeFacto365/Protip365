# ProTip365 Supabase Schema Source of Truth

The mobile app source of truth for shifts is:

- `expected_shifts`: planned shifts, schedule data, alert settings, notes, and status.
- `shift_entries`: completed shift earnings linked one-to-one to `expected_shifts`.

`users_profile` and `employers` are the supporting user-owned public tables used by the app.

The canonical migration-chain definition is:

- `supabase/migrations/20260617184452_canonical_expected_shifts_shift_entries.sql`

The older `supabase/simplifydb/20240924_simplify_database_structure.sql` file is historical design context only. Do not treat it as the active migration source of truth.

Keep RLS enabled on these public tables. Data API access should stay intentionally granted to `authenticated` and `service_role`, with no broad `anon` table grants.
