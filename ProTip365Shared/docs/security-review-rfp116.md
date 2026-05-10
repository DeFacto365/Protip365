# RFP-116 Security Review

## Scope

- Expo React Native app code.
- Environment config and secret handling.
- Auth/session lifecycle.
- Local storage and secure storage usage.
- Subscription/account deletion flows.
- Supabase schema, functions, RLS assumptions, and account lifecycle.
- Dependency audit through `npm audit --json`.

## Confirmed Findings

### High: Account deletion can delete auth before all user data is removed

- Evidence:
  - `supabase/functions/delete-account/index.ts:59` deletes `shift_income` without checking the returned error.
  - `supabase/functions/delete-account/index.ts:65` deletes `shifts` without checking the returned error.
  - `supabase/functions/delete-account/index.ts:71` deletes `employers` without checking the returned error.
  - `supabase/functions/delete-account/index.ts:77` deletes `user_profiles`, but the schema uses `users_profile`.
  - `supabase/functions/delete-account/index.ts:83` deletes the auth user after the unchecked data deletes.
- Impact: If any data deletion fails, the auth user can still be removed, leaving orphaned personal or financial records and breaking account-deletion compliance.
- Recommended fix:
  - Correct the profile table name.
  - Check every delete response.
  - Abort before `auth.admin.deleteUser` on any failure.
  - Prefer a single audited SQL/RPC deletion transaction if Supabase constraints permit.

### High: Public email existence oracle

- Evidence:
  - `supabase/migrations/check_email_exists.sql:4` creates `public.check_email_exists`.
  - `supabase/migrations/check_email_exists.sql:7` runs as `SECURITY DEFINER`.
  - `supabase/migrations/check_email_exists.sql:12` reads `auth.users`.
  - `supabase/migrations/check_email_exists.sql:20` grants execute to `anon`.
- Impact: Unauthenticated callers can enumerate registered emails.
- Recommended fix:
  - Drop the public function or revoke `anon` access.
  - Use generic auth responses that do not disclose whether an email exists.
  - If needed internally, restrict execution to service-role-only backend code.

### Medium: Support email HTML injection

- Evidence:
  - `supabase/functions/send-support/index.ts:23` reads user-controlled `subject` and `message`.
  - `supabase/functions/send-support/index.ts:35` interpolates `subject` into the outgoing email subject.
  - `supabase/functions/send-support/index.ts:38` through `43` interpolate `userEmail`, `subject`, and `message` into HTML without escaping.
- Impact: A user can inject HTML into support emails. This can mislead support recipients or alter email rendering.
- Recommended fix:
  - Escape HTML for all interpolated HTML fields.
  - Validate subject/message length and type.
  - Keep newline-to-`<br>` conversion after escaping.

### Medium: Password reset tokens are stored plaintext

- Evidence:
  - `supabase/migrations/20250910220000_create_password_reset_tokens.sql:6` stores `token TEXT NOT NULL UNIQUE`.
  - `supabase/migrations/20250910220000_create_password_reset_tokens.sql:13` indexes the plaintext token.
- Impact: Database read exposure would allow direct token replay until expiry.
- Recommended fix:
  - Store a keyed or salted hash of the token.
  - Compare hashes in backend code.
  - Keep short expiry and single-use semantics.

### Medium: Shift and subscription records are stored in AsyncStorage

- Evidence:
  - `ProTip365Shared/src/storage/shiftRepository.ts:7` reads shift records from AsyncStorage.
  - `ProTip365Shared/src/storage/shiftRepository.ts:19` writes full shift records to AsyncStorage.
  - `ProTip365Shared/src/storage/subscriptionRepository.ts:7` reads subscription state from AsyncStorage.
  - `ProTip365Shared/src/storage/subscriptionRepository.ts:16` writes subscription state to AsyncStorage.
- Impact: Shift income and entitlement state are stored in plaintext app storage. This is acceptable for temporary local-only development data but not for production-sensitive income records or trusted entitlement state.
- Recommended fix:
  - Move trusted subscription/entitlement state to server/store receipt verification.
  - Store sensitive local income data in encrypted storage or sync it to Supabase behind RLS.
  - Keep AsyncStorage only for non-sensitive UI preferences.

### Medium: PostCSS dependency advisory

- Evidence:
  - `npm audit --json` reports GHSA-qx2v-qp2m-jg93 for `postcss <8.5.10`.
  - `ProTip365Shared/package-lock.json:8247` locks `node_modules/postcss`.
  - `ProTip365Shared/package-lock.json:8248` uses `8.4.49`.
- Impact: The vulnerable dependency is in the Expo/Metro toolchain. Exploitability in this mobile project appears build-time/tooling-scoped, but it should be resolved before release.
- Recommended fix:
  - Upgrade Expo/Metro dependency chain to a version that resolves PostCSS to `>=8.5.10`.
  - Re-run `npm audit`, Expo doctor, tests, typecheck, and export.

### High: Website FTP credentials committed in deployment docs/scripts

- Evidence:
  - `Docs/website/upload.sh` contained FTP host, username, and password literals.
  - `Docs/website/ftp-upload-guide.md` contained FTP host and username literals.
  - `_Backups/2025-12-08_Pre_Optimization/Docs/website/upload.sh` contained the same FTP credential literals.
- Impact: Anyone with repository access or git history access could retrieve deployment credentials and modify the public ProTip365 website.
- Recommended fix:
  - Rotate the exposed FTP credential in Bluehost immediately.
  - Keep deployment credentials in a password manager or CI secret store.
  - Use environment variables for local upload scripts.
  - Consider purging the secret from git history if this repository is shared outside trusted maintainers.

## False Positives / No Finding

- Shared app secrets: no hardcoded production API keys were identified in the shared app source during this pass.
- Supabase session token persistence: the shared app uses SecureStore-backed storage in `src/lib/secureStorage.ts`, which is appropriate for auth session material.

## Required Linear Bugs

- Account deletion leaves data behind before auth deletion.
- Public email existence oracle.
- Support email HTML injection.
- Plaintext password reset tokens.
- Sensitive shift/subscription data in AsyncStorage.
- PostCSS vulnerable dependency.
- Website FTP credentials committed in deployment docs/scripts.

## Remediation Status

Fixed in the RFP-116 dev pass:

- Account deletion now checks delete errors before deleting the auth user and uses `users_profile.user_id`.
- Public email existence RPC is removed for fresh and existing database paths.
- Support email fields are length-limited and HTML-escaped before rendering.
- Password reset token schema now stores `token_hash`; existing plaintext tokens are invalidated during migration.
- Shared app shift and subscription repositories now use SecureStore-backed storage instead of AsyncStorage.
- `npm audit --json` reports zero vulnerabilities after the PostCSS override and lockfile refresh.
- Website FTP credentials were removed from current docs/scripts and backup copies; upload scripts now require environment variables.

Remaining manual security action:

- Rotate the exposed Bluehost FTP credential. The repository no longer contains the plaintext value in the working tree, but the credential may still exist in git history.

Final verification commands:

- `npm test`
- `npm run typecheck`
- `npx expo-doctor`
- `npm audit --json`
- `deno check supabase/functions/delete-account/index.ts`
- `deno check supabase/functions/send-support/index.ts`
- `npx expo export --platform all --output-dir /tmp/protip365-security-fixes-export`
- `git diff --check`
