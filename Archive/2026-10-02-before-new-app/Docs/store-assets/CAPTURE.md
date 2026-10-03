# Store screenshot capture runbook

Status 2026-07-20: the app was restyled to the owner-approved "Shift Receipt" design
(see `Docs/design/README.md`). The PNGs in `screenshots/` and `screenshots-store/` still show the
OLD lavender/cobalt design and must be recaptured. The Windows machine cannot run the Android
emulator (no CPU virtualization), so capture happens on the Mac.

## Pipeline (replicates the existing sets)

1. Pull the latest branch and start the app on a Pixel-class emulator (portrait, 1080-wide;
   the previous raw set was 1080x2424 from a Pixel 9 image). Dark mode OFF for the standard set.
2. Seed the demo data used by the marketing screens: two employers ("Bar Toro" BT, "La Maison" LM),
   a current week with two completed shifts, one past shift not yet closed out, and one planned
   shift tonight. Amounts should be realistic and consistent across screens (see the reference
   mock `Docs/design/explorations/home-redesign/claude/receipt-screens.html`, but enter the data
   through the app so every number is real).
3. Capture with `adb exec-out screencap -p > <name>.png` into `screenshots/` (raw, 1080-wide):
   - `01-schedule.png` — Agenda view with the mixed week (replace: was Schedule home)
   - `02-add-shift.png` — Add shift ticket form
   - `03-complete-shift.png` — Close out, tips & payout step
   - `04-stats.png` — Stats month view
   - `05-employers.png` — Employers list
   - `06-settings.png` — Settings
   - NEW `00-home.png` — the Home week-tally receipt (this is now the lead store screenshot)
4. Recompose the store set in `screenshots-store/` at 1242x2208 using the same framing as the
   current files (raw capture centered on the brand background). Keep filenames aligned.
5. Update `app-screens.html` captions if screens changed, and verify every image really comes from
   the running app — the gallery promises "no mockups".

## Play requirements

Phone screenshots: PNG/JPEG, 320-3840 px per side, max 2:1 aspect. The 1242x2208 set complies.
