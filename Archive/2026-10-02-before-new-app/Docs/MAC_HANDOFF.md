# MacBook continuation

Prepared September 30, 2026. Repository: `https://github.com/DeFacto365/Protip365.git`. Branch: `codex/v4-reset-and-landing-ux`.

The owner has an iPhone and a MacBook, but no Android phone. Do not assume physical Android access. Do not publish to either store.

## Get the work

In GitHub Desktop, clone this repository (or fetch an existing clone) and select `codex/v4-reset-and-landing-ux`. Preserve any local changes before switching or pulling. Open the repository folder in Codex on the Mac.

For a new checkout using Terminal:

```sh
git clone --branch codex/v4-reset-and-landing-ux https://github.com/DeFacto365/Protip365.git
cd Protip365
```

## Prompt for Codex

Continue the ProTip365 pre-launch redesign and complete implementation and native testing for iOS and Android. Do not publish to stores.

Inspect repository instructions, branch, and uncommitted changes first. Preserve existing work. Read the redesign game plan, ADR-002, the redesign verification report, and Windows native setup notes in Docs. Compare every requirement against the implementation and complete missing work.

The September 14 verification passed TypeScript and all 238 tests across 34 suites. Both mobile Hermes exports passed. EAS Android debug build 5449b39f-c1c1-43ef-a875-a8001049e271 succeeded; the downloaded ARM64 APK signature and package identity were checked. These results do not establish native runtime or purchase-flow correctness. No iOS native build or device validation was completed. The Windows local build was stopped for memory pressure before producing an APK.

Inspect this Mac's hardware and install compatible development tools as needed. Use an Android emulator, the iOS Simulator, and the owner's iPhone. Ask for direct user interaction only when installation, device access, or account authentication requires it; continue independent work meanwhile. Install dependencies from app/package-lock.json with npm ci after checking the required Node version.

Resolve the documented SDK compatibility warnings and automatic Android light/dark configuration. Verify actual native workflows, including shift completion and draft recovery, the payment ledger, reversals, backup/restore, offline behavior, keyboard handling, accessibility, and all three languages. Test purchases in supported sandbox environments and identify remaining gaps.

Use existing signing identities where available. Do not replace release keys or erase app data. The Windows preview profile references a missing local upload keystore; the android-debug profile uses a standard test key and needs Metro. Windows credentials, node_modules, generated native projects, and APK artifacts are intentionally excluded from Git; configure the Mac's tools and account access directly.

Carry implementation and testing through to completion. Update the verification report with actual evidence, reproducible commands, and remaining blockers. Do not claim launch readiness from tests or successful builds alone.
