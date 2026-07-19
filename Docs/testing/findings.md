# ProTip365 Android — on-device test findings (2026-07-19)

Device: Pixel 9 emulator, Android 16 (API 36), arm64 · Build: signed Expo APK
(EAS artifact `bnrbY3vaNDniTmWuUYBT0Yatq4Niyrs7CZSN-01jlWY.apk`) · Tooling: Maestro 2.6.1.
Raw logs in this folder: `protip365-crash.txt`, `flow-02-datepicker-crash-logcat.txt`,
`flow-03-timepicker-crash-logcat.txt`.

## Confirmed app crashes / bugs

### BUG 1 — Date picker crashes the app (blocker)
- **What the user does:** Schedule → Add shift → tap the **Date** field.
- **What happens:** app dies instantly ("ProTip365 keeps stopping"); all form input is lost.
- **Root cause (one line):** `java.lang.IllegalArgumentException: MaterialDatePicker requires a value for the com.defacto365.protip365:attr/materialCalendarTheme attribute` thrown at `MaterialAttributes.resolveTypedValueOrThrow(MaterialAttributes.java:72)` via `MaterialDatePicker.onCreateDialog(MaterialDatePicker.java:273)` — the activity theme (`AppTheme` → `Theme.DeviceDefault.Light.DarkActionBar`) does not inherit from `Theme.MaterialComponents`.

```text
07-19 13:53:05.967 E/AndroidRuntime: FATAL EXCEPTION: main
Process: com.defacto365.protip365, PID: 5664
java.lang.IllegalArgumentException: com.google.android.material.datepicker.MaterialDatePicker
  requires a value for the com.defacto365.protip365:attr/materialCalendarTheme attribute to be
  set in your app theme. You can either set the attribute in your theme or update your theme
  to inherit from Theme.MaterialComponents (or a descendant).
	at com.google.android.material.resources.MaterialAttributes.resolveTypedValueOrThrow(MaterialAttributes.java:72)
	at com.google.android.material.resources.MaterialAttributes.resolveOrThrow(MaterialAttributes.java:89)
	at com.google.android.material.datepicker.SingleDateSelector.getDefaultThemeResId(SingleDateSelector.java:171)
	at com.google.android.material.datepicker.MaterialDatePicker.getThemeResId(MaterialDatePicker.java:267)
	at com.google.android.material.datepicker.MaterialDatePicker.onCreateDialog(MaterialDatePicker.java:273)
	at androidx.fragment.app.DialogFragment.prepareDialog(DialogFragment.java:925)
	...
```

### BUG 1b — Time picker crashes the app (same root cause)
- **What the user does:** Add shift (or Complete shift) → tap **Start**/**End** time field.
- **What happens:** identical instant crash.

```text
07-19 13:39:36.492 E/AndroidRuntime: FATAL EXCEPTION: main
Process: com.defacto365.protip365, PID: 5211
java.lang.UnsupportedOperationException: Failed to resolve attribute at index 0:
  TypedValue{t=0x2/d=0x7f04013d a=9}, theme={... com.defacto365.protip365:style/AppTheme,
  forced, android:style/Theme.DeviceDefault.Light.DarkActionBar, forced}
	at android.content.res.TypedArray.getColor(TypedArray.java:536)
	at com.google.android.material.timepicker.MaterialTimePicker.onCreateDialog(MaterialTimePicker.java:205)
	at androidx.fragment.app.DialogFragment.prepareDialog(DialogFragment.java:925)
	...
```

- **Fix direction for both:** make the Android app theme inherit a Material Components /
  Material 3 theme (Expo: `expo-build-properties` or an `android/app/src/main/res/values/styles.xml`
  override) so `materialCalendarTheme` / `materialTimePickerTheme` resolve.
- **Impact:** it is impossible to pick any date or time anywhere in the app.

### BUG 2 — White screen after "Save — mark shift worked" (major)
- **What the user does:** open a planned shift → Confirm your hours → Next → enter tips →
  **Save — mark shift worked**.
- **What happens:** permanently blank white screen (>20 s, no recovery without killing the
  app). No crash in logcat — the process stays alive; it is a navigation/render hang.
  The data IS saved: after relaunch, Stats correctly shows the entered tips ($120.50).

### BUG 3 — "Erase local data" fails (major)
- **What the user does:** Settings → **Erase local data** → confirm.
- **What happens:** dialog "Scheduled reminders could not be canceled. Your local data was
  not erased." The erase aborts. Reproduced with a completed shift + passcode enabled;
  the erase succeeded on earlier runs with less state (no completed shift, no passcode).
  Suspect the notification-cancel call fails (POST_NOTIFICATIONS never requested/granted on
  Android 13+) and the erase bails out instead of proceeding.

## Test-script-only issues (app is fine)

- **"Onboarding crash":** early suite runs appeared to crash during onboarding — this was
  Maestro's `hideKeyboard` issuing an Android back-press, which exits the app from the
  onboarding flow. No app defect (though accepting hardware-back to exit mid-onboarding
  without confirmation may be worth a UX look).
- **"5:00 PM" not found:** Android renders times with a narrow no-break space (U+202F)
  before AM/PM; literal-space text selectors miss it. App fine.
- **Passcode confirm field:** sending text without re-focusing landed extra characters in
  the first field (6-digit max). App validation correctly rejected it. App fine.
- **Lock screen after passcode enabled:** later flows initially failed because launches land
  on the (correctly working) lock screen; flows needed an unlock prelude. App fine.

## Verified working on-device
Onboarding (EN), employer creation, add shift with 30-min unpaid break, agenda display,
tips/stats math ($120.50 direct tips, $15 tip-out reflected), full FR/EN language switch,
passcode enable + lock + unlock (with recovery key generation), CSV export share sheet
(`protip365-shifts.csv`).

## Not testable until BUG 1 is fixed
Scheduling a shift on any other date (e.g. "tomorrow 18:00–23:30") and adjusting actual
start/end times — every path goes through the crashing pickers.
