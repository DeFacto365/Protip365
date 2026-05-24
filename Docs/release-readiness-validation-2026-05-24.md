# ProTip365 Release Readiness Validation - 2026-05-24

## Summary

Release readiness is not complete. The local website compliance pages are present and Expo shared app static checks pass, but launch is blocked by public hosting/SSL, native iOS build environment evidence, tracked secret/config hygiene, support-function input handling, a tracked third-party API key in website template files, and Expo dependency advisories.

Linear tracking was synced under `RFP-113`.

## Baseline

- Repo: `/Users/jacquesbolduc/Github/ProTip365`
- Branch: `main`
- Commit: `4ecb6b21d17a2715bf57a2679c2005977ed57c5a`
- Existing local changes before validation: `.DS_Store`, Xcode `UserInterfaceState.xcuserstate`, and dirty marker in `browser-tools-mcp` from nested `.DS_Store`.
- Release-readiness scope: native app, Expo shared app, Supabase/security, website/store compliance, and Linear follow-up.

## Validation Results

### Passed

- `ProTip365Shared`: `npm run typecheck` passed.
- `ProTip365Shared`: `npx expo-doctor` passed all 18 checks.
- `ProTip365Shared`: `npx expo install --check` reported dependencies are up to date for the current Expo SDK.
- Local website routes returned HTTP 200 for `/`, `/privacy/`, `/terms/`, `/delete-account/`, `/privacy-policy.html`, and `/terms-of-service.html`.
- `bash -n Docs/website/upload.sh` passed.
- Current website FTP upload script uses environment variables rather than literal FTP credentials.

### Blocked Or Failed

- Native iOS build/simulator smoke could not be proven. Xcode listed only an ineligible destination for the schemes because the required iOS 26.5 simulator runtime is not installed, while local runtimes are iOS 26.4, 26.2, 26.0, and 18.6.
- Public URLs still fail store compliance:
  - `curl -L https://protip365.com/`, `/privacy`, `/terms`, and `/delete-account` failed SSL verification with an expired certificate.
  - `curl -k -L` reached `https://protip365.com/cgi-sys/suspendedpage.cgi`.
- `npm audit --audit-level=moderate` in `ProTip365Shared` reported 12 moderate vulnerabilities through Expo tooling: `postcss`, `uuid`, and `ws`.
- Tracked app config contains hardcoded release-sensitive values, including an App Store shared secret fallback.
- `supabase/functions/send-support/index.ts` interpolates user-controlled `subject` and `message` into HTML email without validation or escaping.
- Tracked website template files under `Docs/website/Codeytech - Applify - App Landing Page HTML v2/` contain a Google Maps API key.
- No Swift test or UI test files were found under `ProTip365`.

## Linear Updates

- `RFP-139`: commented with fresh local/public website evidence; remains open as hosting/SSL blocker.
- `RFP-140`: commented with fresh native build evidence; remains open as native release/build evidence blocker.
- `RFP-141`: commented that current repo FTP literals are gone; remains open pending provider-side credential rotation confirmation.
- `RFP-157`: created for hardcoded app secrets/config in tracked files.
- `RFP-158`: created for support email input validation and HTML escaping.
- `RFP-159`: created for tracked Google Maps API key in website template files.
- `RFP-129`: reopened because Expo dependency advisories remain.

## Next Fix Order

1. Fix `RFP-157` first. Remove hardcoded secret fallback, clean tracked env handling, document config injection, and rotate exposed secrets.
2. Fix `RFP-139` externally. Restore hosting and SSL so public compliance URLs resolve to the repo pages.
3. Fix `RFP-158` and redeploy Supabase functions. Validate support email input, escape HTML, require POST, and return generic errors.
4. Fix `RFP-159`. Remove or replace the tracked Google Maps API key and exclude unused template files from release upload.
5. Fix or formally accept `RFP-129`. Avoid a blind Expo major upgrade without a tested migration.
6. Fix the local Xcode runtime/destination mismatch and rerun all three native scheme builds plus simulator launch.

## Commands Run

```bash
git status --short
git branch --show-current
git rev-parse HEAD
xcodebuild -list -project ProTip365.xcodeproj
xcodebuild -project ProTip365.xcodeproj -scheme ProTip365 -showdestinations
xcodebuild -project ProTip365.xcodeproj -scheme ProTip365_StoreKit -showdestinations
xcodebuild -project ProTip365.xcodeproj -scheme ProTip365_StoreKitTest -showdestinations
xcodebuild -showsdks
xcrun simctl list runtimes
cd ProTip365Shared && npm run typecheck
cd ProTip365Shared && npm audit --audit-level=moderate
cd ProTip365Shared && npx expo-doctor
cd ProTip365Shared && npx expo config --type public
cd ProTip365Shared && npx expo install --check
bash -n Docs/website/upload.sh
python3 -m http.server 8765 --directory Docs/website
curl checks for local and public website URLs
tracked-file secret scans across app, website, Supabase, and docs
```
