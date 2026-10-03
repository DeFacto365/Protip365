# Local data product decision — October 3, 2026

The user confirmed the redesigned ProTip365 experience:

- No sign-up, email, username, password or cloud account.
- Tips, shifts and earnings stay on the user's device.
- No multi-device synchronization or web dashboard.
- A seven-day app-managed trial starts on first launch; no store checkout is required to start it. After expiry, adding or editing records requires a purchase. Existing trial start dates and paid entitlements are preserved.
- Exports remain available even when the user stops using the app.
- An optional local PIN is desired to keep earnings private on a shared phone.

The active Android implementation in app/ already has local encrypted SQLite,
CSV/PDF export and JSON backup/restore, with no Supabase connection. The optional
PIN is not yet implemented in that code; do not advertise it as available.
JSON backups currently contain readable records, so do not claim password-
encrypted backup files. Purchase restoration restores store access, not records.

Landing-page messaging targets the redesigned app and emphasizes earnings
privacy specifically. Avoid "we collect nothing" because the store, app update
service, website host and fonts may receive technical request information.
Avoid suggesting iOS and Android share records automatically.

English: Your earnings stay on your phone. No account. No password.
We can't see your tips or shifts.

French: Tes revenus restent sur ton téléphone. Pas de compte.
Pas de mot de passe. On ne voit ni tes pourboires ni tes quarts.

Spanish: Tus ingresos se quedan en tu teléfono. Sin cuenta.
Sin contraseña. No podemos ver tus propinas ni tus turnos.
