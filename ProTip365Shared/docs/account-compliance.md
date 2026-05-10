# Account Lifecycle and Store Compliance

## Implemented

- Settings exposes support, privacy policy, and terms links.
- Settings exposes account deletion request flow.
- Deletion request clears local shift/subscription data before preparing the support email.
- Failure states are user-safe and logged with `console.warn`.

## Required Before Store Submission

- Replace placeholder `https://protip365.com/privacy` with the live privacy policy URL.
- Replace placeholder `https://protip365.com/terms` with the live terms URL if terms are used.
- Confirm `support@protip365.com` is active.
- Add backend account deletion once Supabase user lifecycle is finalized.
- Verify the public account deletion link meets App Store and Google Play requirements.
