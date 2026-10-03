# ProTip365 Privacy Policy Update

> **OWNER PUBLICATION COPY — EXTERNAL VERCEL SITE**
>
> Replace the privacy policy at `https://protip365.vercel.app/privacy` with the copy below. This repository file is only the publication source; adding it here does **not** update the live site. The live site is external to this repository and must be updated by the owner. Do not publish the old statement that “nothing is ever sent”: EAS Update sends limited technical data to Expo.
>
> The owner should replace the date if publication occurs after July 21, 2026 and obtain any legal review they consider appropriate. This draft describes the verified app behavior; it is not legal advice.
>
> Publish only the policy beginning at **“ProTip365 — Privacy Policy”** and ending after the contact address; do not publish this owner-instruction banner. After deployment, verify the live URL shows the new EAS Update section, then reconfirm that the Play Console privacy-policy URL still points to it.

---

# ProTip365 — Privacy Policy

**Last updated: July 21, 2026**

ProTip365 (the “app”) is published by Defacto365. This policy explains what happens to information when you use ProTip365.

## 1. No account required

You do not need to create an account, sign in, or provide an email address or password to use ProTip365. Defacto365 does not operate a user-account database for the app.

## 2. Your work records stay on your device

Information you enter into ProTip365—including employer names, shift schedules, hours worked, wages, tips, tip-outs, sales, payout details, goals, settings, and notes—is stored in an on-device SQLite database protected with SQLCipher encryption. The app creates a random database encryption key and protects it in the device’s secure storage. These user-entered records are not sent to Defacto365, Expo, Google, or a developer-operated server during normal app use.

ProTip365 can optionally protect access with a local passcode and supported device biometrics. The passcode verifier is stored in the device’s secure storage. Biometric checks are performed by the device operating system; ProTip365 receives only the authentication result and does not receive or store fingerprint or face templates. The app lock controls access to the app; it is not an online account password.

## 3. Limited EAS Update technical data

ProTip365 uses Expo Application Services (EAS) Update to check for and deliver app updates. When the app checks for an update, it sends the device operating system and a randomized installation token to Expo over HTTPS. As with other HTTPS connections, Expo also receives connection information such as the device’s IP address. Expo may use this technical data to deliver the correct update and report update adoption, failed installs, early crashes, and related diagnostics.

This EAS Update data does not include the employer names, shifts, schedules, hours, wages, tips, sales, payouts, goals, notes, CSV exports, backups, passcode, or biometric information stored in ProTip365. Expo processes the technical data as a service provider. Defacto365 may see update-level adoption and failed-install metrics in the EAS dashboard, but does not receive the user-entered work or financial records stored in the app.

ProTip365 does not contain an advertising SDK or a general-purpose product analytics or crash-reporting SDK. Network access is also used when you choose to open an external link and when the app communicates with Google Play Billing.

## 4. Local reminders

If you enable post-shift reminders, ProTip365 schedules and processes them locally on your device. They do not require a ProTip365 account or a Defacto365 server. The lock-screen notification uses generic text—“Shift follow-up” and “A scheduled shift may still need your update.”—and does not show employer names, wages, tips, or earnings. You can disable reminders in the app or manage notification permission in your device settings.

## 5. Exporting and backing up your data

You can start a CSV export from ProTip365. The CSV is a plaintext file and can contain the work and financial information you entered. You can also create a full backup protected with a password you choose; the backup is encrypted before it is offered for sharing.

Both actions are initiated by you and open the operating system’s share sheet. ProTip365 does not choose or contact a recipient. You decide whether and where to send or save the file. After a file leaves the app, the selected service or destination controls its storage, security, retention, and deletion. Keep exported CSV files secure and use a strong backup password.

## 6. Purchases

Lifetime purchases and monthly subscriptions are processed by Google Play Billing. Google handles payment card details, billing addresses, and other payment information under Google’s privacy policy and payment terms. ProTip365 receives product and purchase or entitlement status on the device to provide and restore access, but Defacto365 does not receive payment card details or process payments on its own server. ProTip365 has no developer-operated billing backend and does not send purchase history or purchase tokens to a Defacto365 server.

## 7. Deleting data

You can use **Settings → Erase All Local Data** to remove the ProTip365 work records and local app-lock data stored in the app. There is no ProTip365 account to delete.

Local erasure cannot remove:

- CSV files or encrypted backups that you already saved or shared outside the app;
- Google Play purchase and subscription records controlled by Google;
- EAS Update technical data already processed by Expo;
- the local trial and Google Play entitlement record; or
- an already-created CSV or encrypted backup that remains in the app cache until the operating system removes it.

No verified end-user request process is currently available for deleting EAS Update installation tokens or metrics. Defacto365 will update this policy if Expo confirms a deletion process. Questions about this technical data can be sent to the contact address below.

## 8. Children

ProTip365 is intended for working adults aged 18 and over. It is not directed to children and is not designed to appeal to children. The current app does not use an age-verification gate, so this statement describes the intended audience rather than a technical block on installation.

## 9. Changes to this policy

If this policy changes, the “Last updated” date will change. Material changes to how information is handled will be described in the app’s release notes or another appropriate notice.

## 10. Contact

Questions about this policy or ProTip365’s data practices can be sent to [info@defacto365.com](mailto:info@defacto365.com).
