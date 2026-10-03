# ProTip365 — EAS Submit Setup Guide

> **Guide only — owner setup required.** This documents checklist item J. It does not create a credential or change `app/eas.json`. Creating the Google credential is a one-time, owner-only web-console task.

The service-account JSON key is a secret. Treat it like the upload keystore: never commit it, never paste it into chat or logs, and store it outside the repository, for example at `C:\Users\jack_\protip365-keys\play-service-account.json`.

## 1. Create and authorize the Google Play service account

1. Sign in to Google Play Console as the owner and open **Setup → API access**.
2. Create or link the Google Cloud project used for ProTip365. If a project is already linked, use that project.
3. Create a service account for EAS Submit and copy its service-account email address.
4. In Google Cloud Console, open **IAM & Admin → Service Accounts**, select the account, then choose **Keys → Add key → Create new key → JSON**.
5. Move the downloaded JSON key outside the repository, for example to:

   ```text
   C:\Users\jack_\protip365-keys\play-service-account.json
   ```

6. Back in Play Console, give that service account access only to ProTip365 (`com.defacto365.protip365`) with **View app information (read-only)** and **Release apps to testing tracks**.
7. For production automation later, also grant **Release to production, exclude devices, and use Play App Signing**. Grant **Manage testing tracks and edit tester lists** only if the automation must change tester configuration; it is not needed just to upload an internal release. Do not grant Admin, financial, order, or review permissions.

Google may move or rename these screens. If a label differs, preserve the permission intent above.

## 2. Add the submit profile during the submit run

When the owner is ready to submit, replace the empty `submit.production` object in `app/eas.json` with exactly:

```json
"submit": {
  "production": {
    "android": {
      "serviceAccountKeyPath": "C:\\Users\\jack_\\protip365-keys\\play-service-account.json",
      "track": "internal"
    }
  }
}
```

The doubled backslashes are required JSON escaping. The path points outside `C:\Github\Protip365`; only the path belongs in `eas.json`, never the key contents. Do not move or copy the key into the repository.

This guide does not apply that edit. The `eas.json` change belongs to the actual submit run.

## 3. Submit the latest EAS build

Before running the command, confirm the newest Android EAS artifact is the intended production `.aab` for `com.defacto365.protip365`. `--latest` is mutable and selects the most recent Android build; it does not create a build. The current latest build is `versionCode 9`.

From `C:\Github\Protip365\app`, run:

```powershell
npx eas-cli submit --platform android --profile production --latest --non-interactive
```

The submit profile sends that build to the Google Play **internal** track.

## 4. Complete Play prerequisites

Before submitting or promoting a release:

- Complete the Play Console App Content declarations using `Docs/PLAY_APP_CONTENT_WALKTHROUGH.md`.
- Publish the updated privacy policy from `Docs/PRIVACY_POLICY_UPDATE.md`, then verify the live privacy-policy URL includes the EAS Update disclosure.

Google Play may require App Content to be complete even for an internal-track submission. Production promotion also remains subject to Play Console eligibility and review gates.

## Troubleshooting

- **Missing or invalid service account:** Confirm the external file path exists on the machine running the command, the file is the JSON key for the intended service account, and the key has not been disabled or deleted.
- **Insufficient permission or HTTP 403:** Confirm the service account has access to `com.defacto365.protip365`, **View app information (read-only)**, and **Release apps to testing tracks**. Add the production release permission only when production automation is needed.
- **App Content incomplete or release blocked:** Complete the forms in `Docs/PLAY_APP_CONTENT_WALKTHROUGH.md`, publish the policy from `Docs/PRIVACY_POLICY_UPDATE.md`, and resolve any remaining Play Console Dashboard tasks.
- **Wrong artifact selected:** Confirm EAS `--latest` points to the intended production Android `.aab`, not a preview `.apk`.

Once the owner has created the key and the external path exists on the machine running the command, Codex or Claude can run step 3. They must not print, copy, or commit the key.
