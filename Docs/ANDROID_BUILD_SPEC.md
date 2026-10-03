# ProTip365 — Android App Build Spec

**For:** Codex
**From:** the approved web prototype (landing page + interactive demo)
**Date:** 2026-10-02
**Status:** This document is the source of truth for the Android build's UX, visual design, and business logic.

---

## 1. What ProTip365 is

ProTip365 is a tip and shift tracker for restaurant and bar workers in Québec (servers, bartenders, bussers, hosts, barbacks), aged **15–30**, many of them **low-tech users**. Most work **more than one job**.

The core promise:

> Log a shift in ~10 seconds. See what you really make — this week, this month, this year — across every job.

The single most important interaction in the whole app is **logging a shift with tips**. Everything else (stats, calendar, exports) is a payoff for that habit.

### Design principles (non-negotiable)

1. **One primary action.** The "+ / Add my tips" button is always in the same place and is the only prominent CTA.
2. **Speed over completeness.** Job, date and hours are pre-filled. Every tip field is optional. Never force a value the user may not know (e.g. cash tips when only the card report is available).
3. **Plain words, no jargon.** "Given to others (tip-out)", not "tip-out disbursement". Reading level ~grade 6–8. No moving/menus-heavy UI.
4. **No account wall.** Local-first data; sign-up/backup offered later, never forced.
5. **Trust through safety.** Undo/Edit right after saving; free export so users never feel locked in.
6. **Bilingual French/English from day one** (fr-CA default market).

---

## 2. Reference assets (use these, don't reimagine)

| Asset | Where |
|---|---|
| Landing page (visual direction, screen list) | https://www.protip365.com/ |
| Interactive prototype (click through every flow; demo data) | https://www.protip365.com/prototype.html |
| Prototype source (HTML/CSS/JS, incl. all calculations in `app.js`) | GitHub `DeFacto365/Protip365`, branch `website/protip365-landing-2026-10`, folder `Docs/website-live/` |
| Live Android listing (already published) | `com.defacto365.protip365` on Google Play |

`app.js` in the prototype source contains the **exact working business logic** (net tips, hours with overnight handling, week ranges, the 8% check, the TP statement math). Port it; don't re-derive it.

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
- **Inputs:** height 56, radius 16, `line` border; focus = `greenDark` border + soft sage halo. Money fields show `$` prefix inside the field; numeric keypad (`inputMode="decimal"`).
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
  Stats      — Week / Month / Year segments, week bar chart, by-job, best day, 8% check
  Me         — jobs list, add job, tip statement, tax summary, CSV export, settings

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
12. Tip statement (Québec)

---

## 5. Data model

```
Job
  id              uuid
  name            string (required, e.g. "Bar Le Zinc")
  role            string (Server | Bartender | Busser | Host | Barback | custom)
  hourlyRate      number  (default 13.30 — Québec tipped minimum as of 2026-05-01)
  color           enum    (job palette, assigned round-robin)
  defaultStart    time    (e.g. "17:00")
  defaultEnd      time    (e.g. "23:30")
  defaultBreak    minutes (default 30)
  archivedAt      timestamp nullable
  createdAt       timestamp

Shift
  id              uuid
  jobId           fk
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
  weekStartDay    0–6 (Sun=0; default Monday)
  reminderEnabled boolean (default true)
  reminderOffset  minutes after usual end time (default 15)
  weeklyGoal      number (nullable)
  language        "fr" | "en" (follow system on first run)
  backupEnabled   boolean (default false)
  tippedMinimumWage  number (cached, default 13.30; update on app update)
```

Multiple shifts per job per day are allowed (lunch at one job, dinner at another). Never aggregate a day into one record.

---

## 6. Business logic (port exactly from `app.js`)

### 6.1 Hours

```
minutesWorked = (endTime − startTime), +24h if ≤ 0   // overnight support
hoursWorked   = (minutesWorked − breakMinutes) / 60, floored at 0
```

### 6.2 Money

```
netTips(shift)   = cashTips + cardTips + tipIn − tipOut
wage(shift)      = hoursWorked × job.hourlyRate
totalPay(shift)  = wage + netTips
realHourly(shift)= totalPay / hoursWorked          // the app's flagship metric
```

Treat `null` (unknown) as 0 in sums, but never block saving on missing fields.

### 6.3 Week / month / year ranges

- Week runs `weekStartDay` → +6 days. All weekly totals use this range, **aligned with the user's pay period** (this is the single most requested feature in competitor reviews — do not hardcode Sunday).
- Month = calendar month. Year = Jan 1 – today ("2026 so far").

### 6.4 Québec compliance logic

1. **8% allocation check.** If `sales` is recorded for a shift/period: `tipPercent = (cash + card) / sales × 100`. If `< 8`, show a warning: tips below 8% of sales → the employer may allocate the difference on the pay. Show on the Saved summary and in Stats. Source: https://www.revenuquebec.ca/en/citizens/your-situation/employees-who-receive-tips-benefits-and-obligations/
2. **Tip statement (per pay period, per job).** Mirrors Revenu Québec form **TP-1019.4-V**: columns B (tips received), C (valet/porter-type tips), D (tips received via sharing = `tipIn`), E (tips given out = `tipOut`). **Net to declare = B + C + D − E.** Generate as a shareable PDF (employer name, period, per-day table, totals). Employees in regulated establishments (restaurants, bars, hotels) must report tips in writing each pay period.
3. **Wage check.** If `job.hourlyRate < settings.tippedMinimumWage` (13.30 since 2026-05-01; source: https://www.quebec.ca/nouvelles/actualites/details/hausse-du-salaire-minimum-des-aujourdhui-le-taux-general-du-salaire-minimum-setablit-a-1660-lheure-70097 ), warn on the job form. Never block saving.
4. **Year summary PDF:** totals by employer, Jan 1 – Dec 31, phrased for tax filing. Direct tips go on line 10400 federally (https://www.canada.ca/en/revenue-agency/campaigns/track-report-tips-gratuities.html). Do not give tax advice beyond pointing at the totals.

### 6.5 Reminders

- One local notification per scheduled job day: fires at `job.defaultEnd + reminderOffset` (default 15 min).
- Body (fr): « Comment était ton quart au [job] ? Ajoute tes pourboires (10 s). » / (en): "How did your shift at [job] go? Tap to add your tips (10 sec)."
- Tap → opens Log shift step 1 with **job, date, hours pre-filled**; user only types tips.
- If dismissed, one snooze to the next morning. Never more than one nudge per shift. Tone never nags.

---

## 7. Screen-by-screen spec

### 7.1 Onboarding (3 screens, ≤30s total)

**Welcome**
- Hero: `sageSoft` rounded panel, leaf motif, large "p." logo mark.
- Headline: FR « Tes quarts. Tes pourboires. » / EN "Your shifts. Your tips."
- Sub: "Log a shift in ten seconds and see what you really make — every week, every job."
- Language picker (Français / English) as two chips, preselected from system locale.
- Primary CTA: "Get started". Secondary text link: "I already use another app" → (V2: importer; for now a no-op with an explanation).
- Footer reassurance: "No account needed. Your data stays on your phone."

**Add first job** (steps indicator 1/2)
- Fields: employer name (required, only required field in the whole app); role chips (Server default); hourly wage with `$` (default 13.30, hint: "Québec tipped minimum is $13.30/h"); color swatches.
- CTA "Continue". A visible "skip with sample data" is available in the web demo only — do not ship sample data in production.

**Week & reminder** (steps indicator 2/2)
- "When does your week start?" — chips Mon…Sun (default Monday), subtitle: "So your totals match your paycheque."
- Reminder toggle (default on): "Remind me after each shift — 15 min after your usual end time."
- Optional weekly tip goal with `$` input.
- CTA "Done" → Home (empty state).

**Home, first run:** show the hero card with $0.00 and a single message: "Log your first shift to see what you're really making." with the + button.

### 7.2 Home

- Header: small brandmark + "Hi [name]".
- **Hero card** (`sageSoft`, leaf): eyebrow "YOUR TIPS THIS WEEK"; 54px Fraunces total of `netTips` for current week; caption "tips you kept · N shifts logged"; sage progress bar toward `weeklyGoal` with "X% of your $Y goal".
- Pill CTA inside the card: **"+ Add my tips"** (the one primary action).
- Two KPI cards below: This month (net tips, `blush` tint) and Tips/hour (real hourly = totalPay/hours, `sageSoft` tint).
- "Recent shifts" list (last 4–5): job color dot, job name, "Fri Oct 2 · 6.0 h", right-aligned net tips + realHourly underneath.
- Week label: "Week of [weekStart date]".

### 7.3 Log shift — step 1: job & hours

- Back arrow; step dots 1/2; title "Log a shift".
- **Job picker**: one row per active job (color dot, name, "role · $13.30/h", radio circle). Selected = ink border + filled radio.
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
- Quick-add chips under cash: +5 / +10 / +20 / +50.
- Collapsible "+ More: sales & note": sales ("Your sales before tax — optional, used for the 8% check") and free-text note.
- **Sticky footer**: "You take home" + live-updating net total in Fraunces; primary button "Save shift".
- Empty fields are never an error. Save always enabled.

### 7.5 Saved summary

- Sage success ring with check; "Shift saved"; job + date.
- Two KPIs: "Tips you made" (net) and "Real hourly".
- Comparison line (only if history exists for that weekday+job): "▲ $12 more than your usual Friday at Bar Le Zinc."
- 8% warning if sales recorded and under threshold.
- CTA "Done" → Home. Secondary: "Undo" (deletes) and "Edit" (reopens the draft, step 1, values restored).

### 7.6 Calendar

- Month header with prev/next arrows; month net total on the right.
- Legend: job color dots + names.
- 7-column grid, weeks starting `weekStartDay`. Day cell: date number, net tips (compact, e.g. $98), row of job-color dots. Today outlined; selected filled ink.
- Below: selected day header; its shift rows (tap → edit) or empty state "No shift this day" + "Add a shift on this day".

### 7.7 Stats

- Segmented control: **Week | Month | Year** (no date pickers; "More" custom range is V2).
- Hero: total tips for range (44px Fraunces), subtitle "N shifts · X h · total pay incl. wage $Y".
- Two KPIs: Real hourly, Avg per shift.
- **Week segment only:** "Your week at a glance" — vertical bar chart, one bar per day (sage bars; today in clay; height = net tips; value label above bar).
- "By job" — horizontal bars with job colors and totals.
- "Best day: [weekday]" — per-weekday average net tips across all time, best highlighted.
- 8% check banner if sales data exists for the range.

### 7.8 Me

- **My jobs**: list with edit; "Add a job" (reuses onboarding job form). Unlimited jobs — do not paywall or cap.
- **Paperwork**: "Tip statement for my boss" (per pay period, per job → statement screen); "Year summary for taxes" (PDF, Jan–Dec by employer); "Export all my data" (CSV — free, always).
- **Settings**: backup toggle ("So you never lose it if you change phones" — optional, opt-in cloud sync); shift reminders toggle; week starts on; language; about/privacy links.

### 7.9 Tip statement (Québec)

- Header: job + pay period (default: last completed week range based on `weekStartDay`; picker to change).
- Table per day: Sales | B Tips | D In | E Out; totals row.
- Highlight card: "Net tips to declare — B + C + D − E" in Fraunces.
- 8% banner (ok/warn).
- CTA "Share PDF with my manager" → Android share sheet (PDF). Footer note: "Based on Revenu Québec form TP-1019.4-V. Declare your tips in writing at the end of each pay period."

---

## 8. Localization

- `fr-CA` and `en` from day one. French is the primary market (Québec).
- All strings in a translations file; default language follows system locale, switchable in Me.
- Money format: fr-CA `$1 234,56`; en-CA `$1,234.56`. Use tabular numerals.

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
- Screens today are placeholders (`PlaceholderScreens.tsx`) — build the 12 screens here.
- The Play listing is live; ship as an update to `com.defacto365.protip365`.

## 11. Acceptance checklist

- [ ] Fresh install → logging a shift takes ≤ 3 screens of onboarding + one flow, no account.
- [ ] A shift can be saved with only card tips filled (no forced cash, no forced hours edit).
- [ ] Overnight shift (17:00 → 01:30) = 8.0 h with a 30-min break.
- [ ] Two shifts, two jobs, same day — both appear separately, both count.
- [ ] Changing week start day immediately re-slices all weekly totals.
- [ ] Real hourly = (wage + net tips) / hours on Home, Stats and Saved.
- [ ] Tip statement PDF matches B + C + D − E and opens the Android share sheet.
- [ ] 8% warning appears only when sales < 8% and sales exist.
- [ ] Reminder deep-link pre-fills job/date/hours.
- [ ] Undo right after save removes the shift; Edit reopens it with values.
- [ ] CSV export contains every shift, every field, one row per shift.
- [ ] Full FR and EN pass with no clipped text at 320dp width and system font scale 1.3.
