# ProTip365 web prototype

A separate, browser-only usability prototype. No native app data or builds are used. The current version combines the inspected Perplexity prototype's 12-screen journey with ProTip365's cream, sage, clay, typography, and original logo.

Run from the repository root:

```powershell
node web-prototype/server.mjs
```

Open http://127.0.0.1:4173. Override the port with `PROTIP_WEB_PORT` if needed.

French is the initial language. The landing page opens the Welcome preview; the left journey lets users visit First launch, Every shift, Check my money, and Paperwork. “Try the demo” opens the home screen. The Me screen provides English, reloadable demonstration data, and an empty-account reset. Entries persist in this browser under `protip365-web-prototype-v1` with schema version 2. Prior prototype entries are normalized without discarding them. Reset and delete operations offer a 15-second undo. Demonstration records remain labeled even when real entries are added. Fonts load from Google Fonts, with system font fallbacks.

## Usability test

Without explaining navigation, ask the tester to:

1. Record yesterday's tips.
2. Add tomorrow's shift.
3. Find their weekly net tips.

Repeat after resetting to an empty account. Observe hesitation, errors, and requests for help. Target a first entry within one minute and repeat entries within 20 seconds; those targets require a human session and are not certified by automated checks.

Amounts are CAD. Net tips = cash + card + tips shared in - tip-out. Tips per hour excludes wages; hourly earnings includes the snapshotted wage and net tips only for records with known wages and worked hours. Wages are optional, and sample wage rates are illustrative. Worked hours subtract unpaid breaks and support overnight shifts. Week starts are configurable (Monday initially). Dates use the viewer's local calendar. Equal shift start/end times are rejected.

Jobs, usual hours, weekly goals, monthly calendar browsing, planned shifts, week/month/year insights, job totals, weekday averages, CSV exports, JSON backup/restore, and a printable personal tip statement are implemented. The reminder screen is simulated and its setting does not schedule browser or native notifications. Statements are preparatory personal records, without statutory allocation or tax calculations. PDF output uses the browser print dialog.

Run calculation checks with `node --test web-prototype/domain.test.mjs`.
