# Windows native development setup

Installed and checked on September 14, 2026 on the Snapdragon Windows ARM laptop.

- Node.js 24.19.0 ARM64 and npm 11.17.0.
- Microsoft OpenJDK 17.0.20.1 x64, using Windows compatibility support.
- EAS CLI 24.4.0, signed into the existing ProTip365 Expo project.
- Android command-line tools, SDK platforms/build tools, adb and native compilers under `%LOCALAPPDATA%\Android\Sdk`.
- User `JAVA_HOME`, `ANDROID_HOME`, and PATH configured. Open a new PowerShell window after setup.

Android Studio and its emulator are not installed: [Google does not support Windows ARM hosts](https://developer.android.com/studio/install). The owner clarified that they have an iPhone and a MacBook, but NO Android phone. Continue Android emulator and iOS simulator testing on the MacBook after checking its hardware and tool compatibility. The USB instructions below apply only if an Android phone becomes available.

## Verify tools and connect Android

```powershell
node --version
npm.cmd --version
java -version
adb version
eas.cmd whoami
adb devices -l
```

Enable Developer options and USB debugging on the Android phone, connect by USB, and approve the computer's debugging request on the phone. Device-specific USB drivers may be needed if it does not appear; install those only after identifying the phone manufacturer.

## Build and run locally

```powershell
cd C:\Github\Protip365\app
npm.cmd run android
```

This generates the ignored Android project and starts an Android development build. The first local attempt compiled many native components but was stopped because of memory pressure; a complete local build is not yet verified. Prefer the successful cloud-built APK for phone testing.

## Cloud and iOS

Expo authentication and access to `@defacto365/protip365` are verified. EAS can upload this local project without a GitHub sync. An iPhone build additionally needs device registration and Apple signing credentials; use Expo's interactive credential flow. Do not paste account passwords into chat.

The existing Android `preview` profile references a missing local upload keystore. Use the separate test profile for a cloud debug APK:

```powershell
cd C:\Github\Protip365\app
eas.cmd build --platform android --profile android-debug
```

This uses the standard debug key and needs a running Metro development server when launched. It does not establish Play billing or release-signing validation. Root `.easignore` controls the uploaded repository archive; the app-level ignore file alone does not exclude historical root folders.

The first successful cloud APK is saved at `C:\Github\Protip365\artifacts\protip365-redesign-debug.apk`. Once a phone is authorized in `adb devices`, install and connect Metro:

```powershell
adb install -r C:\Github\Protip365\artifacts\protip365-redesign-debug.apk
adb reverse tcp:8081 tcp:8081
cd C:\Github\Protip365\app
npx.cmd expo start --localhost
```

If an installed copy uses a different signing key, do not uninstall it automatically; resolve the signature mismatch while preserving any local test data.

No store publishing is authorized. Do not run `eas submit` or enable automatic submission. Native phone checks and StoreKit/Play purchase sandbox testing remain separate from building an APK or IPA.

See [redesign verification](REDESIGN_VERIFICATION_2026-09-14.md) for build/test results and open release gates.
