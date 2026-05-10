# RFP-74 Daily Entry, Report, and Correction Flow Recommendations

## Decision

Prioritize speed over visual density. The core user is entering a shift after work, often on a phone, and the app should make the most common action obvious: log what happened today and see whether the numbers make sense.

## Daily / End-of-Shift Entry

### Target Flow

1. Open Today.
2. Tap Add shift or edit today's existing shift.
3. Complete a short Shift section:
   - Date, defaulted to today.
   - Start time and end time with native pickers or masked time fields.
   - Role/job location only if the current data model supports it; otherwise defer.
4. Complete the Money section:
   - Cash tips.
   - Credit/card tips.
   - Tip-out.
   - Sales.
   - Other income.
   - Hourly rate.
5. Review a sticky bottom summary:
   - Net tips.
   - Wage income.
   - Total take-home.
   - Tip percentage when sales are entered.
6. Tap Save shift.
7. Return to Today with a persistent confirmation row and updated totals.

### Screen Structure

- Header: `Add shift` or `Edit shift`, with Back/Cancel visible.
- Primary section: Shift.
- Primary section: Tips and pay.
- Secondary section: Details and notes, collapsed or lower on the screen.
- Sticky footer: calculated summary plus Save.

### Field Behavior

- Required: date, start time, end time, at least one income field or an explicit zero-income confirmation.
- Optional: notes, sales, other income, tip-out.
- Money fields use decimal keyboard, two-decimal normalization, and inline validation.
- Time fields reject invalid ranges unless the overnight-shift behavior is intentionally supported.
- Save disabled only for invalid input; do not block incomplete optional fields.

### Implementation Backlog Mapping

- Main implementation issue: RFP-119.
- Required supporting behavior:
  - Keyboard-aware scroll layout.
  - Bottom safe-area support.
  - Save confirmation on Today, not only on the form screen.
  - Edit mode uses the same form and preserves existing values.

## Weekly / Monthly Reporting

### Target Flow

1. User opens Reports.
2. Tabs or segmented control selects Week, Month, or Year.
3. Current period is shown with previous/next controls.
4. Summary appears first:
   - Total take-home.
   - Net tips.
   - Hours.
   - Average per hour.
5. Insight card appears below:
   - Best shift.
   - Biggest tip-out.
   - Progress versus target when target exists.
6. Shift list preview appears last, with rows linking to edit/history.

### Screen Structure

- Period control row: previous, current range, next.
- Summary metrics: compact, 2-column grid max on phones.
- Insight card: one plain-language result, not a chart.
- Breakdown: tips, wages, other income, tip-out, sales.
- Shift preview: last 3-5 records with View all.

### Empty States

- No data in the active period:
  - Message: no shifts logged for this period.
  - Primary CTA: Add shift.
  - Secondary CTA: Change period.
- Avoid showing a full zero metric grid before the first shift.

### Implementation Backlog Mapping

- Main implementation issue: RFP-122.
- Defer charts until after real usage validates which metrics users care about.

## Calendar / History Correction

### Target Flow

1. User opens Calendar/History.
2. Records are grouped by date or shown under a compact date strip.
3. Each row shows status, time, and money context:
   - Completed: time range, take-home, net tips.
   - Planned: time range and expected role/location if available.
   - Missed: missed status and original planned time.
   - Did not work: explicit status and date.
4. Tap row to edit the correct workflow:
   - Completed opens daily shift edit.
   - Planned/missed/did-not-work opens planned shift edit/status correction.
5. Status changes require clear confirmation for missed/did-not-work.

### Screen Structure

- Date grouping header.
- Status chip on every row.
- Edit affordance on the right.
- Filter row for All, Completed, Planned, Missed, Did not work.

### Status Rules

- Negative status actions should not appear on a new planned shift form.
- Missed and did-not-work actions should be visually separated from Save.
- Corrections should show a confirmation sheet before overwriting an existing planned status.

### Implementation Backlog Mapping

- Main implementation issue: RFP-121.
- Planned-shift negative status behavior can be handled inside RFP-121 unless it grows into a larger planned-shift redesign.

## V1 Non-Goals

- Full analytics dashboard.
- Custom chart library.
- Multi-employer payroll reconciliation.
- Tip pooling/team management.
- Web app layouts.

## Acceptance Checklist

- Daily entry supports fast add/edit with visible summary and validation.
- Reports support previous/next period review.
- Empty report states drive users to add a shift.
- Calendar/history rows make correction targets obvious.
- Negative planned-shift statuses are not easy to create accidentally.
