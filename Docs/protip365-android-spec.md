# ProTip365 — Android App Build Spec

**For:** Codex
**From:** the approved web prototype (landing page + interactive demo)
**Updated:** 2026-10-03
**Version:** 2.0 — Global positioning
**Status:** This document is the source of truth for the Android build's UX, visual design, and business logic.

## Global revision: read this first

This version supersedes the original regional spec. ProTip365 is a global app, not a product for one province or country. Keep the approved visual design and fast shift-entry flow; replace regional assumptions with user-controlled language, currency, locale and reporting settings.

- **Must ship:** English, French and Spanish; configurable currency; localized dates, times and money; neutral tip and earnings summaries; no mandatory account.
- **Remove:** hardcoded minimum wages, automatic tax-allocation thresholds, jurisdiction-specific form columns and tax-return line numbers.
- **Do not copy blindly:** the web demo's sample wages, dollar signs, sample dates and tax-oriented wording. This revised spec takes precedence over older prototype behavior.
- **Out of scope for this release:** currency conversion, tax filing, automated legal or minimum-wage compliance, and country-specific reporting templates. These can become separately validated regional modules later.

---

## 1. What ProTip365 is

ProTip365 is a global tip and shift tracker for restaurant and bar workers (servers, bartenders, bussers, hosts, barbacks), primarily aged **15–30**, including people who are less comfortable with technology. It is designed to support workers with **more than one job**, wherever they work.

The core promise:

> Log a shift in ~10 seconds. See what you really make — this week, this month, this year — across every job.

The introductory hook:

> You work hard for your tips. Make every shift count.

Explain what the product does before showing charts: “ProTip365 is a simple app for restaurant and bar staff to track shifts, tips and earnings across all their jobs.” The ten-second promise is a usability target for a returning user with defaults already set, not a guarantee for every first-time entry.

The single most important interaction in the whole app is **logging a shift with tips**. Everything else (stats, calendar, exports) is a payoff for that habit.

### Design principles (non-negotiable)

1. **One primary action.** The "+ / Add my tips" button is always in the same place and is the only prominent CTA.
2. **Speed over completeness.** Job, date and hours are pre-filled. Every tip field is optional. Never force a value the user may not know (e.g. cash tips when only the card report is available).
3. **Plain words, no jargon.** "Given to others (tip-out)", not "tip-out disbursement". Reading level ~grade 6–8. No moving/menus-heavy UI.
4. **No account wall.** Local-first data; sign-up/backup offered later, never forced.
5. **Trust through safety.** Undo/Edit right after saving; free export so users never feel locked in.
6. **English, French and Spanish from day one.** Follow the device language when supported, otherwise use English. Language does not determine country or currency.
7. **Global by default.** Let users control their currency and regional formatting. Never present a local wage or tax rule as universally applicable.

---

## 2. Reference assets (use these, don't reimagine)

| Asset | Where |
|---|---|
| Landing page (visual direction, screen list) | https://www.protip365.com/ |
| Interactive prototype (click through every flow; demo data) | https://www.protip365.com/prototype.html |
| Prototype source (HTML/CSS/JS, incl. all calculations in `app.js`) | GitHub `DeFacto365/Protip365`, branch `website/protip365-landing-2026-10`, folder `Docs/website-live/` |
| Live Android listing (already published) | `com.defacto365.protip365` on Google Play |

Use `app.js` as a reference for the visual layout, navigation, net tips, overnight hours and configurable week ranges. Implement production-safe calculations using this spec: actual dates, precise money arithmetic, saved currency and wage snapshots, and locale-aware formatting. Do not import demo-only defaults or regional compliance logic.

---

## 3. Visual design system

The previous in-repo theme (blue/grey, Inter-like, `theme.ts` with `#2563EB` primary) is **retired**. Replace with this system.

### 3.1 Palette

| Token | Hex | Use |
|---|---|---|
| `bg` | `#FAF8F3` | App background (warm cream) |
| `surface` | `#FFFEFB` | Cards |
| `paper` | `#F1EEE8` | Secondary surfaces, KPI cards, segmented control track |
| `ink` | `#3F2A22` | Primary text, primary buttons, tab bar icons |
| `ink2` | `#6B564C` | Secondary text |
| `ink3` | `#8C7D74` | Tertiary/hint text |
| `line` | `#E7E2D8` | Hairline borders (1px) |
| `sage` | `#8A9C7D` | Brand accent, progress bar fill, success ring |
| `sageSoft` | `#E0E5D6` | Hero card background, tinted KPI |
| `greenDark` | `#5B6E4F` | Buttons on sage backgrounds, eyebrow text |
| `clay` | `#A67B65` | Secondary accent, "today" bar in week chart |
| `blush` | `#F0E2D8` | Tinted KPI card, warning surfaces |
| `sand` | `#D9D6C8` | Inactive chart bars |

**Job colors** (assigned in order when a job is created): `#A67B65`, `#6F8FA3`, `#8A9C7D`, `#C9A15B`, `#9C7A9A`. Each job keeps its color everywhere: calendar dots, shift rows, charts, statements.

### 3.2 Typography

- **Display / numerals:** *Fraunces* (opsz 9–144, weights 500 & 600). Used for: screen titles, big money numbers, chart values. Never bold-800; this brand is soft, not punchy.
- **Body / UI:** *Work Sans* (400, 500, 600). Used for everything else.
- Both are on Google Fonts; for the app, bundle the font files locally (no network fetch at runtime).
- Numerals in money contexts: tabular figures.

Sizes (from the prototype): screen title 28/34, section 20, hero total 52–54, KPI value 22–24, body 16, secondary 14, hint 13, eyebrow 11 (letter-spacing +0.16em, uppercase, `greenDark`).

### 3.3 Logo & decorative elements

- **Logo:** sage (`#8A9C7D`) rounded square (corner radius ≈ 25% of size), white **"p."** set in Fraunces 600. Works at 24px (favicon/status) and 200px.
- **Wordmark:** `protip365` in Work Sans 600, the `365` in weight 400.
- **Leaf motif:** a simple 4-leaf sprig SVG (see `landing.css` / `index.html` source, class `lp-leaf`) in a muted sage `#C3CDB9`. Used sparingly: top-right of the Home hero card and the Welcome hero. Decorative only; never carries meaning.

### 3.4 Component shapes

- **Primary button:** pill (fully rounded), height 58 (44–46 small), background `ink`, label `#FBFAF6`, Work Sans 500. No drop shadows.
- **Cards:** radius 22, `surface` background, 1px `line` border. Tinted KPI cards (`sageSoft` / `blush` / `paper`) have no border.
- **Hero card (Home):** radius 26, `sageSoft` background, leaf motif, 54px Fraunces total, sage progress bar.
- **Chips (selection):** pill, 1.5px `line` border; selected state = `ink` background, `#FBFAF6` text.
- **Inputs:** height 56, radius 16, `line` border; focus = `greenDark` border + soft sage halo. Money fields show the selected currency symbol or ISO code, not a fixed `$`. Accept locale-appropriate decimal input and use a numeric keypad.
- **Bottom tab bar:** 5 tabs (Home, Calendar, **center +**, Stats, Me). The center **+** is a 56px circle, `ink` background, white plus, slightly raised (overlapping the bar), with a cream ring matching the bar background.
- **Icons:** Lucide (already in deps), stroke 1.8–2, `ink2` inactive / `greenDark` active.
- **Motion:** minimal. Screen entry: 220ms fade+12px slide. Success ring: 350ms scale pop. Respect OS reduced-motion setting.

---

## 4. Information architecture

```
Onboarding (first launch only, 3 screens, no account)
  Welcome → Add first job → Week & reminder

Main app: bottom tab bar
  Home       — this week's tips, goal progress, recent shifts, "+ Add my tips"
  Calendar   — month grid with per-day tips + job dots; tap a day → its shifts
  (+)        — Log shift flow (2 steps: job & hours → tips) → Saved summary
  Stats      — Week / Month / Year segments, week bar chart, by-job, best day, tips/sales %
  Me         — jobs list, add job, tip statement, annual earnings summary, CSV export, settings

Notifications
  End-of-shift reminder → deep-link opens Log shift pre-filled
```

**Screen inventory (12 screens — build all of them):**
1. Welcome
2. Add first job (onboarding)
3. Week & reminder (onboarding)
4. Home
5. Reminder (lock-screen notification visual)
6. Log shift — step 1: job & hours
7. Log shift — step 2: tips
8. Saved summary
9. Calendar
10. Stats
11. Me (jobs & exports & settings)
12. Tip statement (region-neutral)

---

## 5. Data model

```
Job
  id              uuid
  name            string (required, e.g. "Bar Le Zinc")
  role            string (Server | Bartender | Busser | Host | Barback | custom)
  hourlyRate      decimal nullable (user-entered; no legal/default wage)
  currencyCode    string  (ISO 4217 code; defaults to settings.defaultCurrencyCode)
  color           enum    (job palette, assigned round-robin)
  defaultStart    time    (e.g. "17:00")
  defaultEnd      time    (e.g. "23:30")
  defaultBreak    minutes (default 30)
  archivedAt      timestamp nullable
  createdAt       timestamp

Shift
  id              uuid
  jobId           fk
  currencyCode    string  (snapshot from job at creation)
  hourlyRateSnapshot decimal nullable (rate used for this shift)
  date            yyyy-mm-dd (local)
  startTime       time
  endTime         time        (may be past midnight — see §6.1)
  breakMinutes    number (default 30, 0 allowed)
  cashTips        number (nullable — unknown ≠ 0)
  cardTips        number (nullable)
  tipIn           number (nullable)  // received from pool / tip sharing
  tipOut          number (nullable)  // given to bar, kitchen, bussers…
  sales           number (nullable)  // user's own sales before tax
  note            string (nullable)
  createdAt / updatedAt  timestamps

Settings
  weekStartDay    0–6 (Sun=0; locale default, otherwise Monday)
  reminderEnabled boolean (default true)
  reminderOffset  minutes after usual end time (default 15)
  weeklyGoal      number (nullable)
  language        "fr" | "en" | "es" (follow system on first run; fallback "en")
  formattingLocale string (device locale by default; separately configurable)
  defaultCurrencyCode string (ISO 4217; infer if reliable, otherwise ask)
  timeZone        string (IANA zone used for new shifts and reminders)
  goalCurrencyCode string nullable (currency of weeklyGoal)
  backupEnabled   boolean (default false)
```

Multiple shifts per job per day are allowed (lunch at one job, dinner at another). Never aggregate a day into one record.

Persist money as exact decimal values or integer minor units appropriate to the selected currency. The model notation above describes business values, not a requirement to use floating-point numbers. Store the shift's time zone and an explicit end date or overnight flag when needed.

Existing records must retain their original currency and hourly-rate snapshot when job settings change. Do not silently relabel old amounts. If migrating legacy records with no currency, ask the user to confirm the currency once before treating the records as typed money.

---

## 6. Business logic (production rules)

### 6.1 Hours

```
minutesWorked = endTime − startTime; add 24h if endTime < startTime
hoursWorked   = (minutesWorked − breakMinutes) / 60, floored at 0
```

Equal start/end times must not silently create a 24-hour shift: request correction or an explicit end date. Use local shift dates and saved time zones; handle daylight-saving changes using actual start/end timestamps rather than a fixed 24-hour assumption. Never allow an unpaid break greater than the shift duration.

### 6.2 Money

```
netTips(shift)   = cashTips + cardTips + tipIn − tipOut
wage(shift)      = hoursWorked × shift.hourlyRateSnapshot
totalPay(shift)  = wage + netTips
realHourly(shift)= totalPay / hoursWorked          // the app's flagship metric
```

Treat `null` (unknown) as 0 in sums, but never block saving on missing fields.

An unset wage is not a zero wage. When the rate is unknown, show “Tips per hour” = net tips / hours and mark total earnings as incomplete; show “Total earnings per hour” only when wages are available. Do not call wage-inclusive earnings “tips per hour.” If hours are zero or unknown, display “Not available” rather than dividing by zero.

### Currency handling

- Default to one currency for a simple first-run experience, with an optional override per job.
- Never add, average or compare unlike currencies. Home and Stats use a currency selector when records span multiple currencies, or separate labeled totals per currency.
- Goals and day-of-week comparisons use the same currency as the selected data.
- Include the currency code in PDFs and CSVs and anywhere a symbol could be ambiguous.
- No exchange-rate integration or automatic conversion in this release.

### 6.3 Week / month / year ranges

- Week runs `weekStartDay` → +6 days. Default the first day from the locale when reliable, otherwise Monday; the user can change it. A reporting week is not necessarily a pay period.
- Month = selected calendar month. Year = Jan 1 to today for the current year; show the actual year, never a fixed sample year.
- For tip statements, offer last completed week as a convenience and a custom date range for weekly, fortnightly, monthly or other pay periods.

### 6.4 Global tip reporting and summaries

1. **Tips as a percentage of sales:** when sales are positive, `tipPercent = (cashTips + cardTips) / sales × 100`. Label this “Customer tips / sales”; pooled tips and tip-outs do not enter this numerator. Calculate a period ratio only from shifts with recorded positive sales, using the matching tips from those same shifts. No automatic threshold, legal warning or wage-allocation claim.
2. **Tip statement:** per employer and date range, show cash tips, card tips, shared tips received, tip-outs, optional sales and net tips. **Net = cash + card + tipIn − tipOut.** Use plain column names, not jurisdiction-specific form codes.
3. **Wage setting:** the user enters their hourly rate. No hardcoded legal minimum, region inferred from language, or automatic legal warning.
4. **Annual earnings summary:** selected calendar year, grouped by employer and currency. Show wage estimates separately from net tips; indicate missing wage data. This is a personal record, not a tax return or an official government form.
5. **Reporting disclaimer:** “Reporting requirements depend on your country and region. This summary is for your records and does not replace official tax forms or professional advice.” Localize it into all three languages.

### 6.5 Reminders

- One local notification per scheduled job day: fires at `job.defaultEnd + reminderOffset` (default 15 min).
- Request Android notification permission only after the user enables reminders or schedules a shift. Permission denial must not block shift entry. A default-on toggle represents a preference, not permission already granted.
- Body (fr): « Comment était ton quart au [job] ? Ajoute tes pourboires (10 s). » / (en): "How did your shift at [job] go? Tap to add your tips (10 sec)." / (es): "¿Cómo te fue en tu turno en [job]? Añade tus propinas (10 s)."
- Tap → opens Log shift step 1 with **job, date, hours pre-filled**; user only types tips.
- Provide an explicit “Remind me tomorrow” action; do not assume the OS supports a reliable swipe-dismiss callback. Schedule in the shift's time zone, including overnight end dates. Avoid duplicate reminders and cancel the reminder once the shift is logged. If no shift is scheduled, do not infer workdays from the job's usual end time alone.

---

## 7. Screen-by-screen spec

### 7.1 Onboarding (3 screens, ≤30s total)

### Welcome
- Hero: `sageSoft` rounded panel, leaf motif, large "p." logo mark.
- Headline: FR « Tes quarts. Tes pourboires. » / EN "Your shifts. Your tips." / ES "Tus turnos. Tus propinas."
- Hook: EN "You work hard for your tips. Make every shift count." / FR « Tu travailles fort pour tes pourboires. Fais compter chaque quart. » / ES "Trabajas duro por tus propinas. Haz que cada turno cuente."
- Context: “A simple app for restaurant and bar staff to track shifts, tips and earnings across all their jobs.” Translate this as well; do not assume the screenshots explain what the product is.
- Language picker (Français / English / Español) as three chips, preselected from system locale.
- Suggest the device currency if reliable; offer a compact, editable currency selector here without creating an extra onboarding screen. Otherwise ask the user to choose. Never infer currency from language alone.
- Primary CTA: "Get started". Secondary text link: "I already use another app" → (V2: importer; for now a no-op with an explanation).
- Footer reassurance: "No account needed. Your data stays on your phone."

### Add first job (steps indicator 1/2)
- Fields: employer name (required); role chips (Server default); optional hourly wage with the selected currency (blank by default, hint: “Enter your hourly wage to include salary in your earnings”); color swatches. Show the currency from Welcome with an optional override.
- A valid currency is necessary for meaningful money totals. Do not require wage or create a legal default.
- CTA "Continue". A visible "skip with sample data" is available in the web demo only — do not ship sample data in production.

### Week & reminder (steps indicator 2/2)
- "When does your week start?" — localized weekday chips (locale default, otherwise Monday), subtitle: "Choose how your weekly totals are grouped."
- Reminder toggle (default on): "Remind me after each shift — 15 min after your usual end time."
- Optional weekly tip goal in the selected currency. No goal means no progress bar and no divide-by-zero error.
- CTA "Done" → Home (empty state).

Home, first run: show a zero amount in the user's currency and locale, plus “Log your first shift to see what you're really making.” Keep the + button prominent.

### 7.2 Home

- Header: small brandmark + "Hi [name]".
- **Hero card** (`sageSoft`, leaf): eyebrow "YOUR TIPS THIS WEEK"; 54px Fraunces total of `netTips` for current week and selected currency; caption "tips you kept · N shifts logged"; sage progress bar when a positive `weeklyGoal` exists in that currency. Localize the goal caption and amount.
- Pill CTA inside the card: **"+ Add my tips"** (the one primary action).
- Two KPI cards below: This month (net tips, `blush` tint) and Total earnings/hour (wage + net tips divided by hours, `sageSoft` tint). If any relevant wages are missing, show Tips/hour instead, with a hint that salary is not included.
- "Recent shifts" list (last 4–5): job color dot, job name, "Fri Oct 2 · 6.0 h", right-aligned net tips + realHourly underneath.
- Week label: "Week of [weekStart date]".

### 7.3 Log shift — step 1: job & hours

- Back arrow; step dots 1/2; title "Log a shift".
- **Job picker**: one row per active job (color dot, name, role and locale-formatted hourly rate with currency, radio circle). If the rate is unset, show “Hourly wage not set.” Selected = ink border + filled radio.
- **When?**: chips Today / Yesterday / Other (date picker).
- **Hours**: Start + End time pickers side by side; computed pill below: "6.5 h worked" (updates live; overnight handled automatically).
- **Unpaid break**: chips None / 15 / 30 / 45 / 60 min (default from job, usually 30).
- Pre-fill logic: from reminder deep link → that job + today + job default times. From + button → last logged shift's job/times if none scheduled.
- CTA "Next: tips".

### 7.4 Log shift — step 2: tips

- Step dots 2/2; context line: job color dot, job name, "Fri Oct 2 · 6.5 h".
- Four amount fields (all optional, numeric keypads):
  1. **Cash tips**
  2. **Card tips** (hint: "On your end-of-shift report")
  3. **Received from the pool** (hint: "Tips other people shared with you")
  4. **Given to others (tip-out)** (hint: "To bar, kitchen, bussers…")
- Quick-add chips under cash: +5 / +10 / +20 / +50 units of the job's currency. Clearly show the currency; these are conveniences, not assumptions about local cash denominations.
- Collapsible "+ More: sales & note": sales (“Your sales — optional, used to calculate customer tips as a percentage of sales”) and free-text note. Apply one consistent sales basis; do not silently mix tax-inclusive and tax-exclusive figures.
- **Sticky footer**: "You take home" + live-updating net total in Fraunces; primary button "Save shift".
- Empty tip fields are never an error. Save is enabled for a valid job, currency, date and time range; invalid numeric inputs or breaks must be corrected without clearing the draft.

### 7.5 Saved summary

- Sage success ring with check; "Shift saved"; job + date.
- Two KPIs: "Tips you made" (net) and "Real hourly".
- Comparison line (only if history exists for that weekday+job): "▲ $12 more than your usual Friday at Bar Le Zinc."
- Neutral “Customer tips were X% of recorded sales” insight when positive sales exist. No legal threshold or allocation warning.
- CTA "Done" → Home. Secondary: "Undo" (deletes) and "Edit" (reopens the draft, step 1, values restored).

### 7.6 Calendar

- Month header with prev/next arrows; month net total on the right.
- Legend: job color dots + names.
- 7-column grid, weeks starting `weekStartDay`. Day cell: date number, net tips (compact, e.g. $98), row of job-color dots. Today outlined; selected filled ink.
- Below: selected day header; its shift rows (tap → edit) or empty state "No shift this day" + "Add a shift on this day".
- For reminder scheduling, offer an optional “Plan a shift” action using the job/date/start/end fields. Keep planned shifts distinct from completed shifts and exclude them from actual earnings until completed. This is a supporting action, not a competing primary CTA.

### 7.7 Stats

- Segmented control: **Week | Month | Year** (no date pickers; "More" custom range is V2).
- Hero: total tips for range and selected currency (44px Fraunces), subtitle with localized shift count, hours and estimated wage-inclusive earnings when complete. All dollar amounts shown elsewhere in this document are illustrative examples, never hardcoded UI.
- Two KPIs: Real hourly, Avg per shift.
- **Week segment only:** "Your week at a glance" — vertical bar chart, one bar per day (sage bars; today in clay; height = net tips; value label above bar).
- "By job" — horizontal bars with job colors and totals.
- "Best day: [weekday]" — per-weekday average net tips across all time, best highlighted.
- Customer tips / sales banner if matching sales data exists for the range. Explain that pooled tips and tip-outs are excluded from this ratio and omit records with missing sales.

### 7.8 Me

- **My jobs**: list with edit; "Add a job" (reuses onboarding job form). Unlimited jobs — do not paywall or cap.
- **Paperwork**: "Tip statement" (per date range, per job → statement screen); "Annual earnings summary" (PDF, selected year by employer and currency); "Export all my data" (CSV — free, always).
- **Settings**: backup toggle ("So you never lose it if you change phones" — optional, opt-in cloud sync); shift reminders toggle; week starts on; language; default currency; formatting locale; time-zone behavior; about/privacy links.

### 7.9 Tip statement (global)

- Header: job + pay period (default: last completed week range based on `weekStartDay`; picker to change).
- Table per shift: Date | Cash tips | Card tips | Shared tips received | Tip-outs | Net tips. Optional sales can appear in an expanded table. Keep multiple same-day shifts separate, with a totals row.
- Highlight card: "Net tips" with the formula “Cash + card + shared tips − tip-outs,” in Fraunces.
- Show the employer, selected currency, period, generation date and selected language. Offer a custom start/end range rather than assuming weekly payroll.
- Show customer tips / recorded sales as a neutral percentage when data exists. Do not reproduce government form codes or imply certified compliance.
- CTA "Share PDF" → Android share sheet (PDF), suitable for a manager or personal records.
- Footer: “Reporting requirements depend on your country and region. This summary is for your records and does not replace official tax forms or professional advice.”

---

## 8. Localization

- Ship complete `en`, `fr` and `es` dictionaries, including onboarding, validation, notifications, accessibility labels, exports, errors and offline states. Do not ship a Spanish landing page with an English-only app.
- Use the device's supported language on first launch and English as fallback. Language, formatting locale, time zone and currency are separate settings; Spanish does not imply a particular country or currency.
- Use locale-aware number and currency formatting with ISO currency codes. Symbol placement, grouping, decimal separators and precision follow locale and currency metadata. Never hardcode a dollar prefix or two decimal places.
- Accept comma and period decimal entry as appropriate; reject ambiguous values instead of guessing. Convert to precise storage values only after parsing.
- Localize dates, month and weekday labels, 12/24-hour time, plural forms, decimal-hour labels and PDF headings. Internal dates remain machine-readable.
- Test currency examples such as USD, CAD, EUR, MXN, GBP and JPY. They are test cases, not an exclusive supported-country list.
- CSV exports use stable column keys, ISO dates, explicit currency codes and unambiguous numeric fields; PDFs use the selected UI language and formatting locale.
- Use tabular numerals and layouts that allow longer French and Spanish strings. Do not shrink critical labels below readable sizes to fit.

---

## 9. Non-functional requirements

- **Local-first:** all data on device (SQLite/AsyncStorage/SecureStore per existing repo patterns). Cloud sync (Supabase, already in the repo) is **opt-in** from Me → Backup, and must never gate features.
- **Fast:** cold start to Home < 1.5s on a mid-range phone. Logging a shift requires at most 6 taps + typing amounts.
- **Private:** no analytics on tip amounts; privacy policy at https://www.protip365.com/privacy .
- **Offline:** 100% of core flows work offline.
- **Min SDK:** whatever the current Play listing supports; keep the existing app id and signing config.

---

## 10. What already exists in the repo (integration notes)

- `ProTip365Shared/` is an **Expo / React Native** app (Expo 56, RN 0.85, React Navigation 7, Supabase JS, expo-secure-store, expo-localization). Build the Android app **in this project** — this spec is stack-agnostic but assumes that codebase.
- `src/theme.ts` currently has the old blue palette — replace tokens wholesale with §3.1.
- `AuthScreen.tsx` exists today; per §1.4 do not make it the entry point. Keep auth only as the opt-in backup path.
- Supabase schema/migrations exist in `supabase/` — extend with the §5 model if cloud backup sync is in scope; otherwise keep local-first.
- The earlier inspection found placeholder screens (`PlaceholderScreens.tsx`). Inspect the current branch before implementing; preserve working flows and migrate existing user records rather than overwriting newer code based on an old inventory.
- The Play listing is live; ship as an update to `com.defacto365.protip365`.

## 11. Acceptance checklist

- [ ] Fresh install → logging a shift takes ≤ 3 screens of onboarding + one flow, no account.
- [ ] A shift can be saved with only card tips filled (no forced cash, no forced hours edit).
- [ ] Overnight shift (17:00 → 01:30) = 8.0 h with a 30-min break.
- [ ] Two shifts, two jobs, same day — both appear separately, both count.
- [ ] Changing week start day immediately re-slices all weekly totals.
- [ ] Real hourly = (wage + net tips) / hours on Home, Stats and Saved.
- [ ] Tip statement PDF matches cash + card + tipIn − tipOut, includes the currency and selected period, and opens the Android share sheet.
- [ ] No region-specific threshold, minimum wage, tax-form column or return-line number appears in the global experience.
- [ ] Given recorded customer tips of 20 and sales of 100, the insight is 20%; given zero or missing sales, no ratio is shown. It makes no legal claim.
- [ ] Reminder deep-link pre-fills job/date/hours.
- [ ] Undo right after save removes the shift; Edit reopens it with values.
- [ ] CSV export contains every shift, every field, one row per shift.
- [ ] Full FR, EN and ES pass with no clipped text at 320dp width and system font scale 1.3, including errors, notifications and PDFs.
- [ ] Given a fresh install, no wage is assumed. An unset wage produces Tips/hour rather than falsely complete wage-inclusive earnings.
- [ ] Given two jobs in EUR and USD, Home and Stats never combine them into one unconverted amount or one average.
- [ ] Given a currency change on a job, historical shifts retain their original currency and wage snapshot.
- [ ] Given a JPY job, money uses that currency's precision; comma-decimal inputs in supported locales are parsed accurately.
- [ ] Given a language change, the country/currency do not silently change; given a time-zone change, past shift dates remain stable.
- [ ] Given equal start/end times or a break longer than the shift, the draft is retained and the user receives a clear correction prompt.
- [ ] Given no scheduled shift, the app does not send a nightly work reminder merely because a default end time exists.

## 12. Codex implementation priorities

- **P0:** migrate existing records safely; preserve the sage/cream/clay design; implement local-first shift and tip entry, multi-employer tracking, three-language UI, precise currency-aware math, calendar and period totals.
- **P1:** produce shareable tip statements and annual summaries, maintain free CSV export, and implement opt-in reminders with real schedule information and permission handling.
- **P2:** add custom analytics ranges, import tools and optional cloud backup improvements after the core flow is stable.
- **Not in this build:** regional legal checks, tax filing and currency conversion. Do not hold the basic app behind authentication or a location-specific compliance workflow.

When a prototype shortcut conflicts with this version, implement this version. Before calling the work complete, run the acceptance checklist and provide screenshots in all three languages plus tests covering money, overnight shifts, date ranges and legacy-data migration.
