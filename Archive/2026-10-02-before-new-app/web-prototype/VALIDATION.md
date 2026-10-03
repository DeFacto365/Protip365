# Prototype validation — October 2, 2026

The merged prototype was inspected against the Perplexity reference's 12 screens. It retains ProTip365's cream, sage, clay and brown palette, fonts and p. logo, with four grouped journeys and an interactive phone preview.

Verified in the local running browser:

- Job creation, configurable week start and goal, French/English switching.
- Overnight 19:00–02:00 with a 30-minute unpaid break calculates 6.5 hours.
- Cash 40.50 + card 100 + shared tips 10 − tip-out 20.50 = 130 net tips. With an illustrative wage of 17.50/hour, hourly earnings are 37.50.
- Saving updates home, calendar, statistics and filtered statements; results survive refresh.
- Editing 210 to 211,50 updates net tips from 190 to 191.50. Undo restores the original; deleting and undoing restores the record and weekly total.
- CSV and JSON files downloaded successfully; the exported JSON restored successfully, including a legacy entry without recorded hours. Such entries show no hourly rate.
- Demo reload returns labeled examples. Existing prototype storage is normalized without resetting personal entries.
- Desktop inspected at 1280px and mobile at 390px; screenshots saved. Amount inputs request decimal keyboards.
- Six domain tests pass, covering comma/zero/invalid amounts, optional hours, totals, configurable week boundaries, overnight shifts, unpaid breaks and wage-inclusive rates.

Reminders are simulated. Statements are personal records with CSV/print options. No official payroll or tax submission is implemented.

Human completion time and the sister's uncoached usability session remain unmeasured. No native build, backend or public deployment was performed.
