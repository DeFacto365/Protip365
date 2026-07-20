# ProTip365 V4 — Google Play Submission Guide

Status: active submission playbook, updated from the live Google Play Console state.
Date: 2026-07-20
Scope: Android only. This guide does not cover the Apple App Store.

Read this top to bottom once before changing Play Console. Section 11 is the current owner/tester checklist.

---

## 0. Current verified state

This guide is based on `.agents/product-marketing.md`, the active V4 product and architecture documents, the code in `app/`, and the live Google Play Console.

1. **Package and app entry are final.** The V4 package is `com.defacto365.protip365`, and the dedicated V4 Play Console app entry has accepted signed releases.
2. **Phase I implementation is present.** The owner-authorized full Phase I scope in `Docs/ADR-001-v4-architecture.md` is implemented in `app/`. Public claims still depend on signed-build testing; do not claim a workflow is proven until its release test passes.
3. **Billing is integrated and configured.** `expo-iap` provides the store adapter. Google Play products `lifetime_unlock` and `monthly` are active. Entitlement enforcement remains disabled until the signed-store purchase test matrix passes.
4. **Internal testing is active.** Release 8 (`1.0.0`) is active on the internal track. Tester lists are assigned, and the same lists are enabled for licence testing.
5. **Privacy and terms are live.** `https://protip365.vercel.app/privacy` and `https://protip365.vercel.app/terms` both returned HTTP 200 on 2026-07-20.

---

## 1. Prerequisites

### 1.1 Play Console account state — check this first

The owner's Play Console developer account already exists: **developer ID `6320222294638558312`**. Sign in at https://play.google.com/console with the Google account tied to that developer ID.

- If the one-time $25 USD Google Play developer registration fee was already paid when this account was created, nothing further is owed. If Play Console shows a "complete your registration" or unpaid-fee banner, pay it before doing anything else — you cannot create or publish an app until the account is fully verified.
- **Check the existing app list before creating anything.** Go to **All apps** in the left nav. An old Cursor-era V3 submission may exist under this developer account (draft, rejected, unpublished, or previously live). Open it if it exists and note: its package name, its current status (draft/internal testing/production/removed), and whatever store listing copy, screenshots, or claims it contains.
- **Do not reuse the old V3 app entry.** Do not edit its store listing, do not upload the new V4 build to it, and do not copy its listing text, screenshots, or claims into the new app — V3's feature set, architecture (it depended on Supabase/accounts, which V4 explicitly does not use), and any pricing or claims it made are not valid for V4. `CLAUDE.md`'s `Archive/` rule applies here in spirit even though this is Play Console, not the repo: nothing from the old submission gets carried forward without an explicit decision from the owner.
- **Create a brand-new app entry for V4.** This is not just a precaution — it is required, because V4's Android package name (Section 1.2) is different from whatever the V3 app used, and Play Console ties one app entry to one immutable package name for its lifetime. A new package name means a new app entry regardless of preference.
- If you are unsure whether the V3 entry is still "yours" to leave alone or needs to be explicitly closed out (e.g., "Unpublish" or leave as an orphaned draft), that is a judgment call only the owner can make after looking at it — flagged in Section 11.

### 1.2 Final package name

`app/app.json` and the V4 Play Console entry use:
```json
"android": {
  "package": "com.defacto365.protip365"
}
```
This identifier is now permanent for this app entry. Changing it would require publishing a separate app.

### 1.3 Accounts and identity checklist

- [ ] Google account with access to developer ID `6320222294638558312` — confirm login works.
- [ ] Registration fee status confirmed paid (see 1.1).
- [x] Package name finalized as `com.defacto365.protip365`.
- [ ] Decide who is the "developer" identity shown on the store listing (individual or business name) — this affects the account type Play Console asks about and cannot be trivially changed later.

---

## 2. Keystore — generate the upload key

Google Play uses **Play App Signing**: you generate and hold an *upload key*, you upload your app signed with it, and Google verifies that signature and re-signs the app with a separate *app signing key* that Google manages and protects. You only need to create the upload key yourself.

### 2.1 Generate it, outside the repo

Do this in a folder that is never committed to git — **not** inside `C:\Github\Protip365`. Create it if it doesn't exist:

```powershell
New-Item -ItemType Directory -Force -Path "C:\Users\jack_\protip365-keys"
```

Then generate the keystore with `keytool` (ships with any JDK; if `keytool` isn't found, install a JDK or use the one bundled with Android Studio, typically at `%ProgramFiles%\Android\Android Studio\jbr\bin\keytool.exe`):

```powershell
keytool -genkeypair -v `
  -storetype PKCS12 `
  -keystore "C:\Users\jack_\protip365-keys\protip365-upload.keystore" `
  -alias protip365-upload `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

`keytool` will prompt for:
- A keystore password (this protects the file itself).
- A key password (protects the specific key inside the file — you can press Enter to reuse the keystore password).
- Your name/org/city/state/country — these become the certificate's identity fields; anything reasonable is fine, they are not shown to users.

`-validity 10000` gives roughly 27 years, which avoids ever needing to regenerate this for the life of the app.

### 2.2 Password handling

- Store the keystore password and key password in a password manager immediately — do not leave them only in shell history or a plaintext note.
- Do **not** put the keystore file or its passwords in `C:\Github\Protip365` at any point, not even temporarily. Confirm `C:\Users\jack_\protip365-keys\` is outside the repo root and is not a subfolder of it.
- Add a rule to your global gitignore or just keep discipline: never `git add` anything from that folder.

### 2.3 Why it must never be committed

If the upload keystore or its password leaks (e.g., committed to a public or even private repo that's later exposed), anyone with it can sign and upload builds that Play Console will accept as coming from you, up until you can prove compromise to Google and request a key reset. Google Play App Signing makes recovery possible (you're not permanently locked out the way you would be without it), but it is still a real incident, not a inconvenience — treat this file like a banking credential.

### 2.4 Wiring it into EAS Build (recommended path — see Section 3)

EAS can either manage a keystore for you in Expo's cloud, or use the one you just generated. Since you generated your own, tell EAS to use it:

```powershell
cd C:\Github\Protip365\app
eas credentials
```

This opens an interactive menu — choose Android, choose the production build profile, choose "Set up a new keystore" → "I already have one" (wording may vary slightly by EAS CLI version), and point it at `C:\Users\jack_\protip365-keys\protip365-upload.keystore`, supplying the alias (`protip365-upload`) and both passwords when asked. EAS stores the keystore encrypted on Expo's servers tied to your Expo account and uses it automatically for future builds — you will not need to re-enter it every time. If you prefer never to upload it to Expo's servers at all, EAS also supports `credentials.json` for fully local credential management; only worth the extra setup if that's a hard requirement.

### 2.5 Wiring it into local Gradle signing (only needed for the local-build path)

If you build locally instead of via EAS (Section 3.2), Gradle needs to know where the keystore is without you hardcoding the path or password into a committed file. Standard approach:

1. Create `C:\Github\Protip365\app\android\keystore.properties` (this file must be gitignored — check `app/android/.gitignore` or the root `.gitignore` covers `keystore.properties` before creating it):
   ```
   storeFile=C:\\Users\\jack_\\protip365-keys\\protip365-upload.keystore
   storePassword=<your keystore password>
   keyAlias=protip365-upload
   keyPassword=<your key password>
   ```
2. In `app/android/app/build.gradle`, add a `signingConfigs.release` block that reads from that properties file, and reference it from `buildTypes.release.signingConfig`. This is a native Android build file that does not currently exist in this Expo-managed project (there is no `app/android/` folder yet — Expo generates it on demand via `expo prebuild`). Setting this up correctly is a real code change; have Codex do it if you choose the local-build path, or use EAS Build instead and skip this entirely.

---

## 3. Build — produce the `.aab`

Google Play requires an Android App Bundle (`.aab`), not a raw `.apk`, for new apps.

### 3.1 EAS Build (cloud) — recommended on this machine

Your dev machine is ARM64 Windows; Android's native build tooling (Gradle, the Android SDK, NDK) is far better supported and far less fragile on x86/x64 Linux or macOS, which is what EAS Build's cloud workers run. Building locally on ARM64 Windows is possible but more likely to hit obscure toolchain issues. Use EAS unless there's a specific reason not to.

Steps:
```powershell
cd C:\Github\Protip365\app
npm install -g eas-cli   # one-time, if not already installed
eas login                 # sign in with your Expo account
```
There is currently no `eas.json` in `app/` — EAS will offer to create one the first time you run a build command, or you can scaffold it explicitly:
```powershell
eas build:configure
```
This asks which platforms (choose Android) and creates a default `eas.json` with `development`, `preview`, and `production` profiles. Then, once the package name is fixed (Section 1.2) and the keystore is wired (Section 2.4):
```powershell
eas build --platform android --profile production
```
This uploads your source to Expo's build servers, compiles it in the cloud, and gives you a download link to the resulting `.aab` when done (typically 10–20 minutes). No local Android SDK/NDK install is required for this path.

### 3.2 Local Gradle build — alternative

Only pursue this if you specifically want a fully offline/local build pipeline. Requires: Android Studio or the Android command-line SDK installed, `ANDROID_HOME` set, and a JDK. Steps:
```powershell
cd C:\Github\Protip365\app
npx expo prebuild --platform android    # generates app/android/ (native project)
cd android
.\gradlew.bat bundleRelease
```
This produces `app/android/app/build/outputs/bundle/release/app-release.aab`, signed using whatever `signingConfigs.release` you configured in Section 2.5. Expect this path to be slower to get right the first time on ARM64 Windows than EAS Build.

### 3.3 Either way, before you build

- [x] `app/app.json` `android.package` is `com.defacto365.protip365`.
- [x] Play accepted internal release version code 8 (`1.0.0`). Increment the version code for every later upload.
- [ ] You've run `npm test` and `npm run typecheck` in `app/` and both pass, so you're not uploading a build with known-broken logic.

---

## 4. Store listing copy — ready to paste

All copy below uses **only** claims that are (a) in `.agents/product-marketing.md`'s approved language, and (b) verified against the actual code in `app/` as of this guide (see Section 0.2). No testimonials, no star ratings, no iOS mention (per this task's explicit scope — note this reads differently from PRD §19's "Works on Android and iPhone" store-page story point, which is written for a future combined listing; flagging that as a PRD-vs-this-guide difference, not an error), and no encryption/passcode/biometric/reminder/goals/trends/backup-restore claims, since those are not implemented yet (Section 0.2). Cloud Sync is omitted entirely from the public listing rather than mentioned as "coming soon" — the marketing doc allows either, and omitting it entirely keeps the listing focused and avoids implying a feature is close if it isn't scheduled yet.

Google Play's Main Store Listing has three relevant text fields: **App name** (30 characters max), **Short description** (80 characters max), **Full description** (4000 characters max). Play has no separate "subtitle" field the way Apple's App Store does — the PRD's proposed subtitle ("Shifts & Real Hourly Pay") is folded into the short description below instead.

### 4.1 English (en-US)

**App name** (23 chars):
```
ProTip365 - Tip Tracker
```

**Short description** (76 chars):
```
Plan shifts across every job. See real hours, tips, and pay. Private, local.
```

**Full description**:
```
Plan every shift. Know what it actually paid.

ProTip365 is a private schedule and earnings tracker for servers, bartenders, and other tipped workers. Combine every employer into one weekly schedule, then record what a shift actually paid — no account required.

WHY PROTIP365

Tips are split across cash, card, and memory. Notes apps and spreadsheets don't understand tip-outs, tip pools, or multiple employers, and paper slips get lost. ProTip365 is built specifically for tipped work: enter your schedule once, then log the real result after each shift in seconds.

WHAT YOU CAN DO

Schedule
- Add employers and set a default hourly rate for each.
- Add roles with their own rates when one employer pays differently by role.
- Plan shifts ahead of time across all your employers in one weekly view.
- Copy a week's shifts forward to plan future weeks faster.

Complete each shift
- Confirm or adjust your actual start and end time against the plan.
- Record breaks taken, paid or unpaid.
- Log direct tips, pooled tips, tip-pool contributions, tip-outs paid, and tip-share received.
- Track sales and other income for the shift.
- Record expected and actual payout status: pending, partially received, received, or disputed.
- Mark a shift missed or cancelled with a reason if it didn't happen as planned.

See what it actually paid
- Compare scheduled hours and expected pay against what you actually worked and earned.
- See your effective hourly rate after tips and tip-outs.
- View totals by employer so you can compare where you actually make more.
- Set your own estimated deduction rate to see an estimated net figure for budgeting — this is an estimate you control, not tax advice or a payroll calculation.

Your data, your device
- No account, email, or password needed to use the app.
- Your schedule and earnings stay on your device unless you choose to export them.
- Export your full shift history to CSV any time, from Settings, and share it however you choose.
- Erase all local data from the app at any time, with a confirmation step.

Languages
- English, Canadian French, and Spanish, switchable any time in Settings.

PRICING

ProTip365 is free to use for 30 days. After the trial, unlock it permanently with a one-time purchase, or subscribe monthly if you'd rather pay as you go. There are no ads and no data sold.

ProTip365 does not manage employees, run payroll, calculate taxes, or file anything on your behalf. It's a personal record for people who already do tipped work and want to know, clearly, what a shift actually paid.
```
(≈2,555 characters — well under the 4,000 limit, leaving room to expand once deferred features ship. The French and Spanish full descriptions above run ≈3,240 and ≈2,900 characters respectively, both also under the limit.)

### 4.2 Canadian French (fr-CA)

**App name** (32 chars — 2 over the 30-char limit, see note below):
```
ProTip365 - Suivi des pourboires
```
This is 32 characters, which exceeds Play's 30-character limit for the App name field — shortened option (27 chars):
```
ProTip365 - Suivi de quarts
```
Use whichever a native Canadian French speaker confirms reads best at 29 characters or fewer; ADR/PRD §14 both require native-speaker review of restaurant/tip terminology before this ships, and that review has not happened yet (flagged again in Section 11).

**Short description** (70 chars):
```
Planifiez vos quarts, suivez pourboires et salaire réel. Privé, local.
```

**Full description**:
```
Planifiez chaque quart. Sachez ce qu'il a vraiment rapporté.

ProTip365 est un outil privé d'horaire et de suivi des revenus pour les serveuses, serveurs, bartenders et autres travailleurs à pourboires. Combinez tous vos employeurs dans un seul horaire hebdomadaire, puis enregistrez ce qu'un quart a réellement rapporté — aucun compte requis.

POURQUOI PROTIP365

Les pourboires se perdent entre l'argent comptant, la carte et la mémoire. Les applications de notes et les tableurs ne comprennent pas les pourboires partagés, les remises de pourboires ni les emplois multiples, et les feuilles papier s'égarent. ProTip365 est conçu spécifiquement pour le travail à pourboires : entrez votre horaire une fois, puis enregistrez le résultat réel après chaque quart en quelques secondes.

CE QUE VOUS POUVEZ FAIRE

Horaire
- Ajoutez des employeurs et fixez un taux horaire par défaut pour chacun.
- Ajoutez des postes avec leur propre taux lorsqu'un employeur paie différemment selon le poste.
- Planifiez vos quarts à l'avance pour tous vos employeurs dans une seule vue hebdomadaire.
- Copiez les quarts d'une semaine vers une semaine future pour planifier plus vite.

Complétez chaque quart
- Confirmez ou ajustez votre heure de début et de fin réelle par rapport au plan.
- Enregistrez les pauses prises, payées ou non payées.
- Notez les pourboires directs, les pourboires en commun, les contributions à la caisse commune, les remises versées et les parts de pourboires reçues.
- Suivez les ventes et les autres revenus du quart.
- Enregistrez le statut du versement prévu et réel : en attente, partiellement reçu, reçu ou contesté.
- Marquez un quart manqué ou annulé avec un motif s'il ne s'est pas déroulé comme prévu.

Voyez ce que ça a vraiment rapporté
- Comparez les heures prévues et le salaire attendu à ce que vous avez réellement travaillé et gagné.
- Consultez votre taux horaire réel après pourboires et remises.
- Visualisez les totaux par employeur pour comparer où vous gagnez réellement le plus.
- Fixez votre propre taux de déduction estimé pour obtenir un montant net estimé à des fins budgétaires — une estimation que vous contrôlez, pas un conseil fiscal ni un calcul de paie.

Vos données, votre appareil
- Aucun compte, courriel ni mot de passe requis pour utiliser l'application.
- Votre horaire et vos revenus restent sur votre appareil, sauf si vous choisissez de les exporter.
- Exportez tout votre historique de quarts en CSV en tout temps, depuis les paramètres, et partagez-le comme vous le souhaitez.
- Effacez toutes les données locales de l'application en tout temps, avec une confirmation.

Langues
- Anglais, français canadien et espagnol, modifiables en tout temps dans les paramètres.

TARIFICATION

ProTip365 est gratuit pendant 30 jours. Après l'essai, débloquez-le de façon permanente avec un achat unique, ou abonnez-vous mensuellement si vous préférez payer au fur et à mesure. Aucune publicité, aucune vente de données.

ProTip365 ne gère pas d'employés, ne fait pas la paie et ne calcule ni ne produit aucune déclaration fiscale en votre nom. C'est un registre personnel pour les gens qui font déjà du travail à pourboires et qui veulent savoir clairement ce qu'un quart a vraiment rapporté.
```

### 4.3 Neutral Latin American Spanish (es-419 / es)

**App name** (28 chars):
```
ProTip365 - Control Propinas
```

**Short description** (75 chars):
```
Organiza turnos de varios empleos. Ve horas, propinas y pago real. Privado.
```

**Full description**:
```
Planea cada turno. Descubre lo que de verdad pagó.

ProTip365 es una app privada de horarios e ingresos para meseras, meseros, bartenders y otros trabajadores con propinas. Combina todos tus empleadores en un solo horario semanal y registra lo que un turno realmente pagó, sin necesidad de crear una cuenta.

POR QUÉ PROTIP365

Las propinas se dispersan entre efectivo, tarjeta y memoria. Las notas y las hojas de cálculo no entienden de propinas compartidas, repartos de propinas ni de varios empleos, y los papeles se pierden. ProTip365 está hecho específicamente para el trabajo con propinas: registra tu horario una vez y anota el resultado real después de cada turno en segundos.

QUÉ PUEDES HACER

Horario
- Agrega empleadores y define una tarifa por hora predeterminada para cada uno.
- Agrega puestos con su propia tarifa cuando un empleador paga distinto según el puesto.
- Planea tus turnos con anticipación para todos tus empleadores en una sola vista semanal.
- Copia los turnos de una semana a una semana futura para planear más rápido.

Completa cada turno
- Confirma o ajusta tu hora de entrada y salida real frente a lo planeado.
- Registra los descansos tomados, pagados o no pagados.
- Anota propinas directas, propinas compartidas, aportes al fondo común, repartos entregados y partes de propina recibidas.
- Registra ventas y otros ingresos del turno.
- Anota el estado del pago esperado y real: pendiente, recibido parcialmente, recibido o en disputa.
- Marca un turno como perdido o cancelado con un motivo si no ocurrió según lo planeado.

Mira lo que de verdad pagó
- Compara las horas programadas y el pago esperado con lo que realmente trabajaste y ganaste.
- Consulta tu tarifa por hora real después de propinas y repartos.
- Ve los totales por empleador para comparar dónde ganas realmente más.
- Define tu propia tasa estimada de deducción para ver una cifra neta estimada para presupuestar — una estimación que tú controlas, no es asesoría fiscal ni un cálculo de nómina.

Tus datos, tu dispositivo
- No se necesita cuenta, correo ni contraseña para usar la app.
- Tu horario e ingresos permanecen en tu dispositivo a menos que decidas exportarlos.
- Exporta todo tu historial de turnos a CSV cuando quieras, desde Configuración, y compártelo como prefieras.
- Borra todos los datos locales de la app cuando quieras, con confirmación.

Idiomas
- Inglés, francés canadiense y español, cambiables en cualquier momento en Configuración.

PRECIOS

ProTip365 es gratis por 30 días. Después de la prueba, desbloquéalo de forma permanente con una compra única, o suscríbete mensualmente si prefieres pagar poco a poco. Sin anuncios ni venta de datos.

ProTip365 no administra empleados, no procesa nómina ni calcula ni presenta impuestos en tu nombre. Es un registro personal para quienes ya trabajan con propinas y quieren saber, con claridad, lo que un turno realmente pagó.
```

Native-speaker review of all three languages' restaurant/tip terminology is required by PRD §14 and has not happened — do not treat the FR-CA/ES copy above as final without that review (see Section 11).

---

## 5. Graphics checklist

Required assets and current status:

| Asset | Spec | Status |
|---|---|---|
| App icon | 512×512 px, 32-bit PNG, no alpha for the Play Store listing icon | `app/assets/icon.png` exists — confirm it's 512×512 and matches the in-app adaptive icon before uploading; Play's listing icon is a separate upload from the in-app `app.json` icon config. |
| Feature graphic | 1024×500 px, JPG or 24-bit PNG, no alpha | Not yet created. Needs a simple, on-brand design using the app's cobalt `#2B4BD7` / lavender `#E8E7F7` palette (per PRD §15) — do not put small text on it, it gets scaled down heavily in some placements. |
| Phone screenshots | Minimum 2, recommended 4–8; JPG or 24-bit PNG; each side between 320px and 3840px, max aspect ratio 2:1 | Not yet captured. Minimum 2 **per language** (en, fr-CA, es) since each localized listing needs its own screenshot set, or you can reuse English screenshots across all locales if you don't want to shoot 24 images — Play allows that, it's just less polished. |
| Tablet/7-inch, 10-inch screenshots | Optional | Skip for v1; ProTip365 is phone-first. |
| Promo video | Optional YouTube URL | Skip for v1. |

### Screens worth shooting once the app is running (per this build's actual screens)

1. Weekly schedule view with 2–3 shifts across at least two employers visible — this is the core "one schedule across employers" story.
2. Add/edit shift form (`shift-form.tsx`) showing employer, role, date/time, and break fields.
3. Complete-shift screen (`complete/[id].tsx`) with actual start/end and tip fields visible — shows the plan-vs-actual workflow.
4. Complete-shift result view showing expected vs. actual and variance, if it renders after saving.
5. Stats screen (`stats.tsx`) with the weekly expected-vs-actual totals and by-employer breakdown.
6. Settings screen showing the language switcher (English/Français/Español chips) — visually proves trilingual support without needing three separate screenshots of the same screen.
7. Settings screen scrolled to show CSV export and Erase All Local Data — supports the privacy story.
8. A missed/cancelled shift with a reason code selected, if that UI is reachable in this build — supports the "life happens" honesty of the product; if this isn't wired into a visible screen yet, substitute another shift-detail view instead.

Use a real (but fake/demo) employer name and a few realistic sample shifts before shooting — do not use test data like "asdf" or "Test Employer 1" in anything that will be public.

---

## 6. Data safety form — exact answers

Google Play's Data Safety section asks what data your app collects and shares. Answer based on the actual current build (Section 0.2), not the PRD's future plans.

**Does your app collect or share any of the required user data types?**
→ **No.** As of this build, nothing leaves the device. There is no analytics SDK, no crash-reporting SDK, no network call, and no backend in `app/package.json` or anywhere in `app/`. All data (employers, shifts, tips, notes) is stored only in the local SQLite database via `expo-sqlite`.

**Data types to declare:** none. Do not declare "Financial info," "App activity," or any other category as collected, since nothing is transmitted off-device.

**Is data encrypted in transit?**
→ **Not applicable / no data is transmitted.** There is no network transmission for this app to encrypt in the first place — Play's form typically lets you state this once you've declared no data collection.

**Data deletion**
→ Users can request that their data be deleted: **Yes, in-app deletion is available.** The path is Settings → Erase All Local Data (implemented, `app/(tabs)/settings.tsx`, function `eraseAllData()` in `src/data/db.ts`), which removes the local database contents with a confirmation dialog. There is no server-side account or data to separately delete, since none exists.

**CSV export — be precise about this one**
CSV export (Settings → Export CSV, implemented and working) is **user-initiated data sharing that the user controls, not automatic data collection by the app**. When a user taps Export CSV, the app writes a file locally and hands it to the OS share sheet (`expo-sharing`) — the user then chooses where it goes (email, Drive, Files, etc.), if anywhere. This is not "sharing data with third parties" in Play's Data Safety sense (that phrase means the developer/app itself sends data somewhere), so do not declare it as data sharing. If asked in the form whether the app allows users to request data export, answer **yes**, and describe it as user-initiated local export, not automatic sharing.

**Security practices section**
Play's form separately asks about security practices like "Data is encrypted in transit" and "You can request that data be deleted" as badges. Do not check "Data is encrypted at rest" or similar, since the local SQLite database is not currently encrypted (Section 0.2). Checking that box when it isn't true is a policy violation if Google audits it, not just an inaccuracy.

**Important: this answer set is only valid for this build.** The PRD's planned analytics event list (PRD §16, e.g. `employer_created`, `shift_completion_completed`, etc.) is not implemented yet — no analytics library exists in the app. **The day analytics ships, this entire Data Safety form must be redone** before that build goes to any public track, since "no data collected" would become false. Add a release-checklist item for that day now (see Section 11's follow-up note).

---

## 7. Content rating questionnaire — expected answers

Google Play's content rating questionnaire (via IARC) walks through categories. Expected answers for ProTip365, a personal productivity/utility app with no user-generated content, no social features, and no in-app messaging:

- **App category:** Utility / Productivity (or "Reference, News, or Education" adjacent — pick "Productivity" if offered directly).
- **Violence:** None.
- **Sexual content:** None.
- **Profanity/crude humor:** None.
- **Controlled substances (alcohol/drugs/tobacco references):** None — note the app is used *by* bartenders but does not depict, sell, or reference alcohol consumption; if the questionnaire asks about "references to alcohol," answer no, since the app itself contains no alcohol-related content or imagery.
- **Gambling:** None (no simulated or real gambling mechanics).
- **User-generated content shared with others:** None — notes and data entered by the user are private to their own device and are never shared with other users or made public.
- **Shares location:** No — the app does not use device location (PRD explicitly rules out location-based clock-in/out).
- **Shares personal info with other users:** No.
- **Digital purchases:** Yes, eventually (in-app purchase for lifetime unlock / monthly subscription — Section 9), even though not wired into this build. Declare "Yes" once IAP actually ships in a build being submitted to that track; for an internal-testing-only build with no working purchase flow, "No" is more accurate for that specific build, so answer honestly for whatever build you're actually rating.

Expected outcome: **Everyone** (or the regional equivalent, e.g. "3+"/"PEGI 3"). No content in this app should trigger a rating above that.

---

## 8. App content declarations

### 8.1 Privacy policy URL — live

The public policy pages are live:

- Privacy: `https://protip365.vercel.app/privacy`
- Terms: `https://protip365.vercel.app/terms`

Both URLs returned HTTP 200 on 2026-07-20. Keep the Play Console privacy-policy field pointed at the privacy URL, and update the policy before any release changes data collection, analytics, advertising, accounts, or cloud behavior.

The policy text below remains a reference copy. The deployed page is the operational version and should still receive appropriate owner/legal review for Canadian and Québec requirements.

Do not paste the raw text into Play Console — Play wants a URL, not the policy text itself.

#### Draft privacy policy (English — translate to fr-CA/es before publishing, if the site serves those locales)

```
ProTip365 — Privacy Policy

Last updated: [DATE OF PUBLICATION]

ProTip365 ("the app") is published by Defacto365. This policy explains what
happens to your information when you use ProTip365.

1. No account required
ProTip365 does not require you to create an account, sign in, or provide an
email address, password, or any other identifying credential to use the app.

2. Where your data lives
All information you enter into ProTip365 — including employer names, shift
schedules, hours worked, tips, tip-outs, sales figures, payout details, and
any notes — is stored only in a local database on your device. This
information is never transmitted to Defacto365, to any server we operate, or
to any third party, as part of normal use of the app.

3. What we collect
As of this version of the app, ProTip365 does not use any analytics,
advertising, or crash-reporting service, and does not send any data over the
network. We do not know what you enter into the app, how you use it, or
anything else about your activity, because nothing is sent to us. If a future
version of the app adds optional, privacy-conscious product analytics, this
policy will be updated first, the new version will describe exactly what is
collected, and any personal or financial data (tip amounts, employer names,
notes, schedules) will continue to be excluded from analytics.

4. Exporting your data
You may export your shift history to a CSV file at any time from within the
app (Settings → Export CSV). This is an action you take deliberately — the
app does not export or share your data automatically. Once exported, the
file is handed to your device's normal share/save mechanism, and what
happens to it after that (which app you send it to, where you save it) is
entirely your choice and outside ProTip365's control.

5. Deleting your data
You can permanently erase all data stored by ProTip365 on your device at any
time from within the app (Settings → Erase All Local Data), after a
confirmation step. This deletes the local database on your device. Because
we never receive a copy of your data, there is no separate "delete my
account" request to make with us — erasing it in the app is deletion.

6. Purchases
If you purchase a lifetime unlock or a monthly subscription through Google
Play, the transaction is handled entirely by Google Play Billing. We receive
confirmation that an entitlement is active on your device, but we do not
receive your payment card details, billing address, or other payment
information — that is handled by Google, subject to Google's own privacy
policy.

7. Children
ProTip365 is intended for general audiences and is not directed at children.
[OWNER TO CONFIRM: the product team has not yet finalized a policy for users
under 18 — see PRD_V4.md §21, open decision 2. This section must be
finalized, including any required age-gate or restriction, before this
policy is published.]

8. Changes to this policy
If this policy changes, the "Last updated" date above will change, and
material changes affecting how your data is handled will be described in
the app's release notes.

9. Contact
Questions about this policy or ProTip365's data practices can be sent to:
[CONFIRM CONTACT EMAIL — info@defacto365.com is the address on file
for this project; confirm whether this should be a dedicated support address
instead before publishing].
```

Bracketed `[...]` items are placeholders the owner must fill in before this goes live — do not publish with brackets still in the text.

### 8.2 Ads declaration

**No ads.** ProTip365 contains no advertising SDK and no ad placements anywhere in the current code. Declare "No, my app does not contain ads" in Play Console's Ads section. If this ever changes, this declaration must be updated before the release that adds ads.

### 8.3 Target audience and content

- **Target age group:** 18+ (adult; the product is aimed at working adults in tipped service jobs). Do not select any child-inclusive age range.
- **Not child-directed:** Confirm "No" when asked whether the app is designed to appeal to children, and "No" for the "primarily child-directed" declaration. This determines whether Google's Families/child-safety policies and COPPA-adjacent requirements apply — they should not, given this audience and content.
- Note the open PRD item (§21, decision 2: "Are users under 18 allowed?") is unresolved. If the owner decides to explicitly allow or restrict under-18 users later, both this declaration and the privacy policy (8.1, section 7) need to be revisited together.

---

## 9. Pricing setup

The app download remains **Free**. The live Play Console products match PRD §18:

| Product ID | Type | Purchase/base plan | United States | Canada | Availability | Status |
|---|---|---|---|---|---|---|
| `lifetime_unlock` | One-time product | `lifetime` (Buy) | USD $19.99 | CAD $27.99 | 173 countries/regions | Active |
| `monthly` | Subscription | `local-monthly`, monthly auto-renewing | USD $2.99/month | CAD $4.19/month | 174 countries/regions | Active |

No Play Billing free-trial or introductory offer is configured. This is intentional: the app supplies its own 30-day trial and should not create a second, overlapping store trial.

**Implementation status (2026-07-20):** `expo-iap` adds the Billing permission and connects the entitlement seam to Google Play. Internal release 8 contains the billing adapter, localized product lookup, pending-purchase handling, acknowledgement, restore, and foreground subscription refresh.

Remaining release gates:
1. Install release 8 from the internal-testing opt-in link on a licensed tester's real Android device.
2. Test localized product discovery, lifetime and monthly purchases, pending payment, acknowledgement, restore, subscription lapse, and offline refresh.
3. Keep `ENTITLEMENT_ENFORCEMENT_ENABLED` set to `false` until the signed-store test matrix passes.
4. Add server-side purchase-token validation only if fraud-resistant production entitlement becomes a requirement. Play Integrity is not a prerequisite for the current local-only phase.

---

## 10. Release strategy

Standard Play Console progression: **Internal testing → Closed testing → Open testing → Production.** Each track can hold its own build and can be promoted to the next once you're satisfied.

### Recommended path

1. **Internal testing — active.** Release 8 (`1.0.0`) is active. The `Android Testers` and `Maya` lists are assigned to the track and enabled under Licence testing. The first-time install still needs confirmation on a real device.
   - Opt-in link: `https://play.google.com/apps/internaltest/4700551426889638180`
   - The tester must use the exact invited Google account in both the browser and Play Store. Allow time for newly saved tester or release changes to propagate.
2. **Closed testing**, after release 8 installs successfully and the core loop and billing matrix pass on real devices. Check Testing → Production eligibility for the exact tester-count and duration requirements shown for this developer account.
3. **Production**, only after Data Safety, Content Rating, target-audience declarations, and every production eligibility item are confirmed for the release; real-device crash and billing tests pass; and the entitlement-enforcement decision is made.

---

## 11. Current owner/tester checklist

Already completed:

- [x] Final package and dedicated V4 app entry: `com.defacto365.protip365`.
- [x] Signed release 8 active on Internal testing.
- [x] Privacy and Terms pages live.
- [x] `lifetime_unlock` and `monthly` products active with regional pricing.
- [x] Internal tester lists assigned and enabled for licence testing.

Remaining:

1. **Install release 8 on the tester's real Android device.** Open the opt-in link with the invited Google account, confirm the same account is active in Play Store, and retry after propagation/cache troubleshooting if Play shows “Item not found.”
2. **Run the crash smoke test.** Tap a date to open the date picker, then complete a shift and confirm the app does not white-screen.
3. **Run the signed-store billing matrix** in Section 9 on the licensed tester account.
4. **Keep entitlement enforcement off** until the billing matrix passes.
5. **Verify the Play Dashboard production gates:** App content, Data Safety, Content Rating, target audience, and Testing → Production eligibility.
6. **Handle any old V3 listing separately.** Leaving, unpublishing, or replacing it is an owner decision and must not affect the V4 entry.

### Current blockers to promotion

1. Successful first-time installation on a real tester device is not yet confirmed.
2. The signed-store purchase and entitlement test matrix has not yet passed.
3. Production declarations and closed-test eligibility still need final verification in the live Console.
