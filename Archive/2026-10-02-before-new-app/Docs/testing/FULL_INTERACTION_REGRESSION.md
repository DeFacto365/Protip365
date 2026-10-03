# ProTip365 full interaction regression

Use this runbook for every Android release candidate. It covers the complete local-first workflow, including the features that the older MVP plan marked as deferred.

## Release gate

Record these before testing:

| Item | Value |
|---|---|
| Date / tester | |
| Source branch / commit | |
| Install source | Google Play internal test / local release candidate |
| Expected versionName / versionCode | |
| AVD / Android API | |
| Result folder | `~/Desktop/protip365-e2e-results/<date-time>-<commit>-full-regression/` |

A release passes only when:

- TypeScript and the full Jest suite pass.
- The real release artifact opens without a fatal exception or ANR.
- Every interaction below passes. Any failure blocks completion until it is fixed and retested.
- Destructive tests are performed only on disposable data and only after action-time confirmation.

## 1. Prepare the emulator and evidence

Do not reset an AVD or remove its Google account. Prefer an existing Google Play AVD.

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
emulator -list-avds
adb devices
# Reuse a running Google Play AVD. If none is running, select a Google Play AVD
# from the list above and launch it in a visible window:
emulator -avd "<selected-google-play-avd>"
```

Leave that visible emulator process running. Record its exact serial from `adb devices`; do not assume `emulator-5554`. In the creator terminal, set the serial and create one unique evidence path from the explicit repository:

```bash
cd /Users/jacquesbolduc/Github/ProTip365
export ANDROID_SERIAL="<serial-shown-by-adb-devices>"
export RESULTS="$HOME/Desktop/protip365-e2e-results/$(date +%F-%H%M%S)-$(git rev-parse --short HEAD)-full-regression"
test ! -e "$RESULTS" || { echo "Result folder already exists"; exit 1; }
mkdir -p "$RESULTS"
device_ready=0
for attempt in $(seq 1 90); do
  if [ "$(adb -s "$ANDROID_SERIAL" get-state 2>/dev/null)" = "device" ]; then
    device_ready=1
    break
  fi
  sleep 2
done
test "$device_ready" -eq 1 || { echo "Emulator did not become available within 180 seconds"; exit 1; }
boot_ready=0
for attempt in $(seq 1 90); do
  if [ "$(adb -s "$ANDROID_SERIAL" shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; then
    boot_ready=1
    break
  fi
  sleep 2
done
test "$boot_ready" -eq 1 || { echo "Android did not finish booting within 180 seconds"; exit 1; }
adb -s "$ANDROID_SERIAL" shell dumpsys package com.defacto365.protip365 | rg 'versionName|versionCode|installerPackageName'
```

Print the exact exports once and copy their output into every other terminal. Do not regenerate `RESULTS` independently:

```bash
printf 'export ANDROID_SERIAL=%q\nexport RESULTS=%q\n' "$ANDROID_SERIAL" "$RESULTS"
```

Before opening the newly installed app, clear old logs and start a filtered log in a second terminal. Leave it running through Play's Open action so the first release launch is captured:

```bash
adb -s "$ANDROID_SERIAL" logcat -c
adb -s "$ANDROID_SERIAL" logcat -v time AndroidRuntime:E ReactNativeJS:V Expo:V '*:S' | tee "$RESULTS/logcat.txt"
```

For Google Play verification, install/update only through the authorized internal-testing account. Do not sideload:

```bash
adb -s "$ANDROID_SERIAL" shell am start -a android.intent.action.VIEW -d "https://play.google.com/apps/internaltest/4700551426889638180"
```

If Google login, account selection, tester opt-in, or CAPTCHA appears, stop and leave the emulator on that screen for the owner. After authorization, opt in if needed, open the Play listing, tap Install or Update, wait for completion, then tap Open. Re-run the package check and require the recorded expected version plus the Play installer before testing:

```bash
export EXPECTED_VERSION_NAME="<expected-version-name>"
export EXPECTED_VERSION_CODE="<expected-version-code>"
package_dump="$(adb -s "$ANDROID_SERIAL" shell dumpsys package com.defacto365.protip365)"
printf '%s\n' "$package_dump" | rg -F "versionName=$EXPECTED_VERSION_NAME"
printf '%s\n' "$package_dump" | rg -F "versionCode=$EXPECTED_VERSION_CODE "
printf '%s\n' "$package_dump" | rg -F 'installerPackageName=com.android.vending'
```

Never capture a Google account, PIN, recovery key, backup password, or private notification in screenshots or video.

## 2. Disposable test data

Use clearly disposable values so deletion is safe and repeatable:

- Employer A: `Regression Bistro`, amber, rate `20.00`, deduction `10%`.
- Role A: `Server`, rate `22.00`.
- Employer B: `Regression Bar`, teal, rate `18.50`, deduction `0%`.
- Role B: `Bartender`, rate `24.00`.
- PIN: tester-selected disposable six-digit value; never write it in evidence.
- Backup password: tester-selected disposable value of at least eight characters; never write it in evidence.

Use dates in the current week. Keep at least one planned shift in the future and one in the past.

Start from the empty local profile produced by the prior completed run's section 11 erase. If an earlier run stopped before erase, do not clear the app with ADB; resume that run and complete its approved in-app erase before starting a new run. On the empty profile, verify Home's empty action opens Schedule before creating current-week data.

For any negative-value check where Android's decimal keyboard has no minus key, paste the value. If paste is unavailable, use the corresponding automated validation test as evidence and record that the manual entry mechanism was unavailable.

## 3. Employers and roles

1. Complete the full onboarding path: change language and verify the page updates, enter Employer A, test empty name plus zero/negative rate validation, choose currency, and use Add Shift. Verify it opens the shift form with Employer A selected. Return without saving.
2. In Add shift, use Add employer again to create Employer B. Use the inline Add role control to create Role A and Role B; verify its empty/zero/negative validation.
3. Open Settings → Employers. Edit Employer A's name, color, rate, and deduction. Verify deduction above 100% is rejected. Edit Role A's name and rate. Verify the changes persist after leaving and returning.
4. In Add shift, select Employer B and verify Employer A's role is never offered.
5. Create a shift for Employer A, then change Employer A and Role A rates. Verify the existing shift keeps its original rate snapshot and a new shift gets the new rate.
6. Try to remove Employer A after it has shift history. PASS when hard delete is unavailable/blocked and archive is offered.
7. Cancel the archive confirmation; verify no change. Confirm archive; verify the employer is hidden from new shifts but historical cards and stats still show its name. Unarchive it.

## 4. Schedule and shift lifecycle

Test Day, Week, and Month views. In each view, navigate backward and forward, navigate manually back to the current period, and open a populated day. There is no separate Today button.

1. Tap Add shift. Verify the selected employer's real default rate is visible, not merely a placeholder.
2. Tap Date. **RFP-234 PASS** when the native date picker opens and the app remains alive. Cancel, reopen, select a date, and confirm.
3. Tap start and end time. Verify the time picker opens. Create a normal shift and an overnight shift (20:00–02:00).
4. Add the available unpaid break. Verify it reduces expected wages. Paid-break math is domain-tested because the current form has no paid/unpaid toggle.
5. Enter expected tips, other income, and a note. Verify the live expected total.
6. Select a role, no role, and the other employer. Verify the hourly rate follows each selection and manual rate edits remain visible.
7. Save. Rapidly tap Save twice and verify the card appears exactly once in the correct date and employer.
8. Use Save and add another. Verify context is retained and the second shift is not a duplicate.
9. Create a zero-length shift; PASS when save is blocked with inline feedback.
10. Create an overlapping shift for the other employer; PASS when a warning appears and saving remains possible.
11. Edit a planned shift's employer, role, date, time, break, expected values, and note. Verify every edit persists.
12. Open Delete shift. Cancel and verify the shift remains. With action-time confirmation, delete one disposable planned shift and verify only that shift disappears.
13. Copy the current week. Cancel once. Confirm once and verify the preview/conflict behavior and no unexpected replacement. Navigate back to the original source week before repeating the action, then verify no duplicates.
14. Force-stop and relaunch the app. Verify all successfully saved records remain.

Useful commands:

```bash
adb -s "$ANDROID_SERIAL" shell am force-stop com.defacto365.protip365
adb -s "$ANDROID_SERIAL" shell am start -W -n com.defacto365.protip365/.MainActivity
adb -s "$ANDROID_SERIAL" shell pidof com.defacto365.protip365
```

## 5. Complete, edit, and mark shifts not worked

1. Open a past planned shift and choose Log it/Complete.
2. Verify planned values prefill actual start/end, breaks, rate, and deduction.
3. On step 1, edit actual start/end and a scheduled break. Toggle that break Skipped and Taken, verify its controls hide/show, then use Add break and edit the new break's time and duration.
4. Go to step 2, use Back, and verify the step-1 edits remain. Return to step 2.
5. Test Direct, Pooled, and Mixed tips, including direct tips, pool contribution, share received, tip-out, sales, other income, expected payout, actual received, and payout status. Cover no-payout, pending, partial, received, and disputed states. Toggle Mark disputed on and off and verify the status changes. Shift notes are edited on Edit shift, not on the completion form.
6. Save. **RFP-235 PASS** when the app returns normally with no white screen, fatal exception, or ANR.
7. Verify the result math: paid time, wages, net tips, gross, deduction, estimated net, variance, effective hourly, and payout status.
8. Reopen the completed shift. Use Correct to planned; cancel once and verify nothing changes. Confirm once and verify actuals are cleared and the shift returns to PLANNED. Complete it again, edit the editable actual values, then save; verify planned values remain unchanged and totals recalculate. Time/rate fields cannot be blank.
9. In Week view, choose Log past shift. Complete and save the resulting unplanned shift. Verify it appears once and counts in actual totals.
10. On separate disposable planned shifts choose Mark not worked. Verify confirm is disabled until a reason is selected. Tap every reason chip—Sick, Employer cancelled, Personal, Emergency, Schedule conflict, Weather or transportation, and Other—and verify selection moves correctly. Save Sick and verify MISSED. Save Other with its required note and verify MISSED. Save Employer cancelled and verify CANCELLED.

## 6. Templates and recurring schedules

1. Open Settings → Templates. Attempt to save an empty template and an invalid time range; verify validation. Exercise employer, role, start/end, break, expected tips, expected other income, and note fields, then cancel once and verify nothing was saved.
2. Create, edit, archive, and unarchive a template. Verify an archived template has no Use once/Make recurring actions. After unarchiving, verify Use once creates exactly one shift on the selected date. Duplicate handling is tested by applying the same template/date again; there is no Duplicate template button.
3. Start a recurring rule. Test weekly and every-two-weeks cadence, multiple weekdays, occurrence count, optional end date, excluded occurrences, overlap warnings, duplicate conflicts, and replacement selection.
4. Save the series. Repeat the save path and verify idempotency—no duplicate recurrence keys or shifts.
5. Edit a rule and verify the preview refreshes before save.
6. Tap End rule. PASS when a confirmation appears. Cancel and verify the rule stays active. Confirm and verify it becomes Ended while already-created shifts remain.

## 7. Stats and goals

1. Verify Overview against a hand calculation for scheduled/worked hours, wages, tips, gross, deductions, net, payouts, missed/cancelled shifts, and per-employer totals.
2. Verify planned shifts never count as earned income and missed/cancelled shifts count as zero actual earnings.
3. Exercise every trend metric. Verify week-over-week, month-over-month, best employer, and best weekday show values or a designed insufficient-data state—never NaN/Infinity.
4. Add a weekly goal for worked hours and each money metric. Test all-employers and one-employer targets.
5. Enter blank, zero, negative, below-0.1-hour, over-168-hour, and invalid targets; verify the form's raw-input validator shows visible feedback before minute rounding.
6. Save the same week/metric/employer combination twice with a new target. PASS when it updates one goal instead of creating a duplicate.
7. Toggle Repeat next week. Verify carry-forward with the automated domain test; the current Stats screen has no week navigator for a safe manual assertion.
8. Delete a goal. Cancel once, then reopen and pause for action-time owner/tester approval. Confirm only after approval; verify only that disposable goal is removed.

## 8. Settings, localization, reminders, export, and links

1. Change language EN → Français (Canada) → Español → EN. Visit Home, Schedule, Stats, Employers, Templates, Security, and Backup after each change. Verify labels update immediately while user-entered names/notes do not change.
2. Change currency through every available option and back. Verify totals reformat without changing stored numeric values.
3. Enter deduction below 0 and above 100%; verify validation. Save valid values and verify snapshot behavior on completed shifts.
4. Enter reminder delays `0`, `1.5`, `24`, blank, non-numeric, negative, and `25`. Verify valid values persist and invalid values show an error without replacing the last valid setting.
5. With PIN enabled on Android 13 or newer, reset the disposable app's notification permission state with the commands below. Return to the app, enable Post-shift reminder, and deny the prompt. Verify a clear message and an off toggle. Run the reset commands again, retry, and approve. PASS when the toggle remains enabled on the first approved attempt and the app does not lock during its own prompt.

   ```bash
   adb -s "$ANDROID_SERIAL" shell pm revoke com.defacto365.protip365 android.permission.POST_NOTIFICATIONS || true
   adb -s "$ANDROID_SERIAL" shell pm clear-permission-flags com.defacto365.protip365 android.permission.POST_NOTIFICATIONS user-set
   adb -s "$ANDROID_SERIAL" shell pm clear-permission-flags com.defacto365.protip365 android.permission.POST_NOTIFICATIONS user-fixed
   ```

6. Set the reminder delay to `0`. Create a disposable shift ending about two minutes in the future, background the app, and observe the generic post-shift notification after the end time. For cancellation, create another shift ending about two minutes in the future, turn Post-shift reminder off before it ends, background the app, and verify no notification arrives during the minute after its end. Turn reminders on again afterward.
7. Export CSV. Open/save the shared file without sending it to another person. Verify UTF-8 names, one row per shift, all planned/actual/tip/payout/reason fields, quoting, and cent-accurate values. Return from the share sheet and verify the app does not spuriously lock. Rapidly tap Export twice and verify only one share flow opens.
8. With PIN enabled, background the app to reach the lock screen. Open Privacy and Terms there and verify the expected pages load. Open Support only far enough to verify the email composer/address; do not send mail.
9. Open the purchase screen from an authorized store build. Verify lifetime/monthly products and Restore become available. Tap Restore and verify a successful restore result or a clear no-purchases result. Do not tap Buy or confirm a charge unless this is a licensed test account and the owner explicitly approves the purchase at action time. If the store returns no catalog, record product IDs, Play track, account, and logcat; do not change Play Console during regression.

## 9. Security, encrypted backup, and restore

1. Try to enable a PIN with invalid length, mismatched confirmation, and without acknowledging the warning. Verify validation.
2. Enable the disposable PIN. Verify a recovery key appears once; retain it privately only for this run and do not capture or publish it.
3. Background and reopen. Verify the app locks. Enter a wrong PIN and verify visible feedback/rate limiting; enter the correct PIN and verify access.
4. Test biometrics when supported. On an emulator without enrolled biometrics, a clear unavailable message is expected.
5. Try disabling with a wrong PIN; verify visible feedback and that protection remains enabled. Disable with the correct PIN, then re-enable for the erase test. This generates a new recovery key; retain this new key privately and discard the old one.
6. Unlock once with the new recovery key from step 5. Stage Reset access, cancel it, and verify data remains. Do not confirm Reset access; Erase local data is the single destructive end-of-run path.
7. Backup: verify short and mismatched passwords are rejected. Export an encrypted backup with a valid disposable password. PASS when the share sheet opens and no generic processing error appears. Cancel the share sheet once and verify the app neither locks nor reports a backup failure. Rapidly tap Create backup twice and verify only one share flow opens.
8. Save the backup privately. Add one disposable record after export.
9. Restore with a wrong password; verify authentication failure and no data changes.
10. Stage restore with the correct password. Cancel the document picker once, then stage it again and cancel the restore confirmation. Verify the app does not spuriously lock and the post-export record remains.
11. With action-time confirmation, restore the backup. Verify the post-export record is gone, backup records are present, settings reload, and no duplicate weekly goals appear.
12. Restore replaces and resynchronizes reminders from restored shifts and settings. Create an eligible disposable shift ending at least ten minutes in the future, toggle Post-shift reminder off/on, and edit/save the shift to force a known state. Confirm Android has a pending app-owned alarm before the erase test:

    ```bash
    adb -s "$ANDROID_SERIAL" shell dumpsys alarm | rg -i 'com\.defacto365\.protip365'
    ```

## 10. Home, routing, navigation, and read-only access

1. The no-current-week-data Home action was verified before disposable data setup in section 2.
2. With a future shift, verify Home shows the next shift and Log it opens that shift's completion route.
3. With an overdue planned shift, verify Close out opens its completion route.
4. On Schedule, tap the main body of a normal planned card, an actuals-pending card, and a worked card. Verify they route to Edit, Complete, and completed details respectively.
5. Expand and collapse each status card. Exercise every visible expanded action.
6. Use Android hardware Back and each header Back from every secondary screen. Verify no save occurs accidentally and the app returns to the expected prior screen.
7. If entitlement enforcement is enabled, verify expired/read-only actions route to the purchase screen while viewing records and CSV/backup remain available.

## 11. Erase local data — destructive final check

Perform this last. Confirm the tester knows all app data on the emulator will be removed.

1. With PIN enabled and disposable employers, shifts, templates, goals, settings, and reminder IDs present, save the specific pre-erase app-alarm evidence, then open Settings → Erase local data:

   ```bash
   adb -s "$ANDROID_SERIAL" shell dumpsys alarm | rg -i 'com\.defacto365\.protip365' > "$RESULTS/alarms-before-erase.txt"
   test -s "$RESULTS/alarms-before-erase.txt"
   ```

2. Cancel. Verify all data and the PIN remain.
3. Reopen the confirmation and pause. Obtain action-time confirmation from the owner/tester.
4. Confirm Erase everything. Save the post-erase alarm evidence and compare identifiers with the pre-erase file. **RFP-236 PASS** when the operation completes without aborting, every previously captured app-owned notification alarm is gone, the PIN is removed, and onboarding appears. If Android retains an unrelated package alarm, identify and document it rather than treating it as a notification reminder:

   ```bash
   adb -s "$ANDROID_SERIAL" shell dumpsys alarm | rg -i 'com\.defacto365\.protip365' > "$RESULTS/alarms-after-erase.txt" || true
   ```

5. Force-stop and relaunch. Verify no local data returns and no lock screen remains.

Do not use `adb shell pm clear`, reset the emulator, or remove Google accounts as a substitute; that bypasses the product interaction being tested.

## 12. Crash and evidence review

After each major section and once at the end:

```bash
adb -s "$ANDROID_SERIAL" shell dumpsys package com.defacto365.protip365 | rg 'versionName|versionCode|installerPackageName'
adb -s "$ANDROID_SERIAL" logcat -d -b crash -v time
adb -s "$ANDROID_SERIAL" logcat -d | rg -i 'FATAL EXCEPTION|AndroidRuntime|ANR|ReactNativeJS.*error|com.defacto365.protip365' | tail -200
adb -s "$ANDROID_SERIAL" exec-out screencap -p > "$RESULTS/final-screen.png"
```

Classify failures precisely:

- Product defect: reproducible app behavior differs from this runbook.
- Test defect: automation targeted the wrong state/control or polluted state.
- Environment blocker: Play account, Play catalog, network, emulator, or OS service prevents the product path.

For every failure record: exact step, expected/actual, versionCode, screenshot, relevant log lines, reproducibility, and whether another agent already owns it.

## 13. Result matrix

| Area | Result | Evidence / issue |
|---|---|---|
| Install/version/launch | PASS / FAIL / BLOCKED | |
| Employers and roles | PASS / FAIL / BLOCKED | |
| Schedule create/edit/delete/copy | PASS / FAIL / BLOCKED | |
| RFP-234 date picker | PASS / FAIL / NOT TESTED | |
| Completion/edit/no-shift/not-worked | PASS / FAIL / BLOCKED | |
| RFP-235 no white screen | PASS / FAIL / NOT TESTED | |
| Templates and recurrence | PASS / FAIL / BLOCKED | |
| Stats and goals | PASS / FAIL / BLOCKED | |
| Settings/localization/reminders | PASS / FAIL / BLOCKED | |
| CSV/links/purchases | PASS / FAIL / BLOCKED | |
| PIN/biometric/backup/restore | PASS / FAIL / BLOCKED | |
| Home/routing/Back/read-only | PASS / FAIL / BLOCKED | |
| RFP-236 erase local data | PASS / FAIL / NOT TESTED | |
| Persistence/relaunch | PASS / FAIL / BLOCKED | |
| Fatal/ANR log review | PASS / FAIL | |

## 14. Automated checks

Run before and after any fix:

```bash
cd /Users/jacquesbolduc/Github/ProTip365/app
npm run typecheck
npm test -- --runInBand
```

The focused Maestro flows remain under `Docs/testing/flows/`; they supplement this runbook but do not replace the full manual interaction pass. Update automation only after the manual path is stable and proven on a release artifact.
