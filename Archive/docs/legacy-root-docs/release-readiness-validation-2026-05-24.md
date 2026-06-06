# ProTip365 Release Readiness Validation - 2026-05-24

## Summary

Release readiness is not complete only because the public website is still serving an expired/suspended hosting target and operational secret rotation/deployment confirmation is still required. Repo-side blockers found during this pass were fixed in commit `0dc8029`: native simulator builds pass, Expo checks pass, tracked secret scans are clean for the known exposed patterns, and local website compliance routes pass.

Linear tracking was synced under `RFP-113`.

## Baseline

- Repo: `/Users/jacquesbolduc/Github/ProTip365`
- Branch: `main`
- Commit: `0dc8029`
- Existing local changes before validation: `.DS_Store`, Xcode `UserInterfaceState.xcuserstate`, and dirty marker in `browser-tools-mcp` from nested `.DS_Store`.
- Release-readiness scope: native app, Expo shared app, Supabase/security, website/store compliance, and Linear follow-up.

## Validation Results

### Passed

- `ProTip365Shared`: `npm run typecheck` passed.
- Native iOS simulator builds passed for `ProTip365`, `ProTip365_StoreKit`, and `ProTip365_StoreKitTest`.
- `ProTip365` installed and launched on iPhone 16 Pro simulator with bundle id `com.protip365.monthly`.
- `ProTip365Shared`: `npx expo-doctor` passed all 21 checks.
- `ProTip365Shared`: `npm audit --audit-level=moderate` passed with 0 vulnerabilities.
- Local website routes returned HTTP 200 for `/`, `/privacy/`, `/terms/`, and `/delete-account/`.
- `bash -n Docs/website/upload.sh` passed.
- Current website FTP upload script uses environment variables rather than literal FTP credentials.
- `deno check supabase/functions/send-support/index.ts` passed.
- Tracked-file secret scan returned no hits for the known Supabase URL/key, App Store shared secret, Google API key pattern, FTP password variable assignment, or Supabase service-role assignment.

### Blocked Or Failed

- Public URLs still fail store compliance:
  - `curl -L https://protip365.com/privacy`, `/terms`, and `/delete-account` failed SSL verification.
  - `curl -k -L` reached `https://protip365.com/cgi-sys/suspendedpage.cgi`.
- Exposed credentials/secrets still need provider-side rotation confirmation. The repo no longer tracks the known literals, but this pass cannot prove the external secrets were rotated.
- Supabase function changes pass local type-checking, but this pass did not deploy the updated function to Supabase.
- No Swift test or UI test files were found under `ProTip365`.

## Linear Updates

- `RFP-139`: remains open as external hosting/SSL blocker.
- `RFP-140`: native simulator build and launch evidence now passes locally; signed release build evidence is still external.
- `RFP-141`: repo literals are gone; remains open pending provider-side credential rotation confirmation.
- `RFP-157`: repo-side hardcoded config/secret exposure fixed.
- `RFP-158`: repo-side support input validation and escaping fixed; deployment still pending.
- `RFP-159`: repo-side tracked Google Maps key exposure fixed.
- `RFP-129`: Expo audit and doctor now pass.

## Next Fix Order

1. Fix `RFP-139` externally. Restore hosting and SSL so public compliance URLs resolve to the repo pages.
2. Rotate exposed provider credentials/secrets externally and record proof on `RFP-141`/`RFP-157`.
3. Deploy the updated Supabase `send-support` function and record deployment evidence on `RFP-158`.
4. Produce signed release build evidence for `RFP-140`.

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
xcodebuild -downloadPlatform iOS -buildVersion 26.5 -architectureVariant universal
xcodebuild -project ProTip365.xcodeproj -scheme ProTip365 -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/ProTip365DerivedData-ProTip365 -skipPackagePluginValidation SUPABASE_URL=https://example.supabase.co SUPABASE_ANON_KEY=placeholder_publishable_key_for_build_only APP_STORE_SHARED_SECRET=placeholder_shared_secret_for_build_only build
xcodebuild -project ProTip365.xcodeproj -scheme ProTip365_StoreKit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/ProTip365DerivedData-StoreKit -skipPackagePluginValidation SUPABASE_URL=https://example.supabase.co SUPABASE_ANON_KEY=placeholder_publishable_key_for_build_only APP_STORE_SHARED_SECRET=placeholder_shared_secret_for_build_only build
xcodebuild -project ProTip365.xcodeproj -scheme ProTip365_StoreKitTest -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/ProTip365DerivedData-StoreKitTest -skipPackagePluginValidation SUPABASE_URL=https://example.supabase.co SUPABASE_ANON_KEY=placeholder_publishable_key_for_build_only APP_STORE_SHARED_SECRET=placeholder_shared_secret_for_build_only build
xcrun simctl install 2CC69716-9882-453C-B851-523363955DC9 /tmp/ProTip365DerivedData-ProTip365/Build/Products/Debug-iphonesimulator/ProTip365.app
xcrun simctl launch 2CC69716-9882-453C-B851-523363955DC9 com.protip365.monthly
cd ProTip365Shared && npm run typecheck
cd ProTip365Shared && npm audit --audit-level=moderate
cd ProTip365Shared && npx expo-doctor
deno check supabase/functions/send-support/index.ts
bash -n Docs/website/upload.sh
python3 -m http.server 8765 --directory Docs/website
curl checks for local and public website URLs
tracked-file secret scans across app, website, Supabase, and docs
```
