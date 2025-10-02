# Android Implementation Guide: Shift Alert System

## Overview
This guide details the implementation of the Shift Alert notification system for the ProTip365 Android app to achieve feature parity with the iOS version.

## Database Changes
The following fields have been added to the database (already applied via SQL migration):

### shifts table
- `alert_minutes` (INTEGER, nullable) - Minutes before shift start to send alert (15, 30, 60, or 1440 for 1 day)

### users_profile table
- `default_alert_minutes` (INTEGER, default: 60) - User's default alert preference for new shifts

## Data Model Updates

### Update Shift.kt
```kotlin
data class Shift(
    val id: String? = null,
    val user_id: String,
    val employer_id: String?,
    val shift_date: String,
    val expected_hours: Double?,
    val hours: Double?,
    val lunch_break_minutes: Int?,
    val hourly_rate: Double?,
    val sales: Double?,
    val tips: Double?,
    val cash_out: Double?,
    val other: Double?,
    val notes: String?,
    val start_time: String?,
    val end_time: String?,
    val status: String?,
    val alert_minutes: Int? = null,  // NEW FIELD
    val created_at: String?
)
```

### Update UserProfile.kt
```kotlin
data class UserProfile(
    val user_id: String,
    val default_hourly_rate: Double,
    val week_start: Int,
    val tip_target_percentage: Double?,
    val name: String?,
    val default_employer_id: String?,
    val default_alert_minutes: Int? = 60  // NEW FIELD
)
```

## UI Implementation

### 1. Add Shift Screen Updates

#### AlertDropdown Component
Create a new composable for the alert selection dropdown:

```kotlin
@Composable
fun AlertDropdown(
    selectedAlert: String,
    onAlertSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val alertOptions = listOf(
        "None" to stringResource(R.string.alert_none),
        "15" to stringResource(R.string.alert_15_minutes),
        "30" to stringResource(R.string.alert_30_minutes),
        "60" to stringResource(R.string.alert_60_minutes),
        "1440" to stringResource(R.string.alert_1_day)
    )

    var expanded by remember { mutableStateOf(false) }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable { expanded = true }
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Notifications,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = stringResource(R.string.alert_label),
                style = MaterialTheme.typography.bodyLarge
            )
        }

        Text(
            text = getAlertDisplayText(selectedAlert),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }

    DropdownMenu(
        expanded = expanded,
        onDismissRequest = { expanded = false }
    ) {
        alertOptions.forEach { (value, label) ->
            DropdownMenuItem(
                text = { Text(label) },
                onClick = {
                    onAlertSelected(value)
                    expanded = false
                }
            )
        }
    }
}
```

#### AddShiftViewModel Updates
```kotlin
class AddShiftViewModel(
    private val supabaseManager: SupabaseManager,
    private val notificationManager: NotificationManager
) : ViewModel() {

    private val _selectedAlert = MutableStateFlow("60")
    val selectedAlert = _selectedAlert.asStateFlow()

    private val _defaultAlertMinutes = MutableStateFlow(60)

    init {
        loadUserDefaults()
    }

    private fun loadUserDefaults() {
        viewModelScope.launch {
            try {
                val profile = supabaseManager.getUserProfile()
                profile?.default_alert_minutes?.let { minutes ->
                    _defaultAlertMinutes.value = minutes
                    _selectedAlert.value = minutes.toString()
                }
            } catch (e: Exception) {
                Log.e("AddShiftViewModel", "Error loading user defaults", e)
            }
        }
    }

    fun saveShift() {
        viewModelScope.launch {
            try {
                val alertMinutes = when(selectedAlert.value) {
                    "None" -> null
                    else -> selectedAlert.value.toIntOrNull()
                }

                val shift = Shift(
                    // ... other fields
                    alert_minutes = alertMinutes
                )

                val savedShift = supabaseManager.saveShift(shift)

                // Schedule notification if alert is set
                alertMinutes?.let { minutes ->
                    savedShift.id?.let { shiftId ->
                        notificationManager.scheduleShiftAlert(
                            shiftId = shiftId,
                            shiftDate = selectedDate.value,
                            startTime = startTime.value,
                            employerName = selectedEmployer.value?.name ?: "",
                            alertMinutes = minutes
                        )
                    }
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
    }
}
```

### 2. Settings Screen Updates

#### Default Alert Setting Component
```kotlin
@Composable
fun DefaultAlertSetting(
    defaultAlert: String,
    onDefaultAlertChanged: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }

    val alertOptions = listOf(
        "None" to stringResource(R.string.alert_none),
        "15" to stringResource(R.string.alert_15_minutes),
        "30" to stringResource(R.string.alert_30_minutes),
        "60" to stringResource(R.string.alert_60_minutes),
        "1440" to stringResource(R.string.alert_1_day)
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable { expanded = !expanded }
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = Icons.Default.NotificationImportant,
                contentDescription = null
            )
            Text(stringResource(R.string.default_alert_label))
        }

        TextButton(onClick = { expanded = !expanded }) {
            Text(getAlertDisplayText(defaultAlert))
        }
    }

    // Dropdown implementation...
}
```

## Notification Manager Implementation

### NotificationManager.kt
```kotlin
class NotificationManager(private val context: Context) {

    companion object {
        private const val CHANNEL_ID = "shift_alerts"
        private const val CHANNEL_NAME = "Shift Alerts"
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for upcoming shifts"
                enableLights(true)
                enableVibration(true)
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun scheduleShiftAlert(
        shiftId: String,
        shiftDate: LocalDate,
        startTime: LocalTime,
        employerName: String,
        alertMinutes: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Calculate alert time
        val shiftDateTime = LocalDateTime.of(shiftDate, startTime)
        val alertDateTime = shiftDateTime.minusMinutes(alertMinutes.toLong())
        val alertMillis = alertDateTime.toInstant(ZoneOffset.UTC).toEpochMilli()

        // Don't schedule if in the past
        if (alertMillis <= System.currentTimeMillis()) {
            return
        }

        // Create intent for notification
        val intent = Intent(context, ShiftAlertReceiver::class.java).apply {
            putExtra("shift_id", shiftId)
            putExtra("employer_name", employerName)
            putExtra("start_time", startTime.toString())
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            shiftId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Schedule exact alarm
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                alertMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                alertMillis,
                pendingIntent
            )
        }
    }

    fun cancelShiftAlert(shiftId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ShiftAlertReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            shiftId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}
```

### ShiftAlertReceiver.kt
```kotlin
class ShiftAlertReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val shiftId = intent.getStringExtra("shift_id") ?: return
        val employerName = intent.getStringExtra("employer_name") ?: ""
        val startTime = intent.getStringExtra("start_time") ?: ""

        showNotification(context, shiftId, employerName, startTime)
    }

    private fun showNotification(
        context: Context,
        shiftId: String,
        employerName: String,
        startTime: String
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val notification = NotificationCompat.Builder(context, NotificationManager.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(context.getString(R.string.notification_title))
            .setContentText(
                context.getString(
                    R.string.notification_body,
                    employerName,
                    startTime
                )
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(shiftId.hashCode(), notification)
    }
}
```

## Localization Strings

### strings.xml (English)
```xml
<!-- Alert Settings -->
<string name="alert_label">Alert</string>
<string name="alert_none">None</string>
<string name="alert_15_minutes">15 minutes before</string>
<string name="alert_30_minutes">30 minutes before</string>
<string name="alert_60_minutes">1 hour before</string>
<string name="alert_1_day">1 day before</string>
<string name="default_alert_label">Default Alert</string>

<!-- Notifications -->
<string name="notification_title">Upcoming Shift</string>
<string name="notification_body">Your shift at %1$s starts at %2$s</string>
```

### strings.xml (French)
```xml
<!-- Alert Settings -->
<string name="alert_label">Alerte</string>
<string name="alert_none">Aucune</string>
<string name="alert_15_minutes">15 minutes avant</string>
<string name="alert_30_minutes">30 minutes avant</string>
<string name="alert_60_minutes">1 heure avant</string>
<string name="alert_1_day">1 jour avant</string>
<string name="default_alert_label">Alerte par défaut</string>

<!-- Notifications -->
<string name="notification_title">Quart de travail à venir</string>
<string name="notification_body">Votre quart chez %1$s commence à %2$s</string>
```

### strings.xml (Spanish)
```xml
<!-- Alert Settings -->
<string name="alert_label">Alerta</string>
<string name="alert_none">Ninguna</string>
<string name="alert_15_minutes">15 minutos antes</string>
<string name="alert_30_minutes">30 minutos antes</string>
<string name="alert_60_minutes">1 hora antes</string>
<string name="alert_1_day">1 día antes</string>
<string name="default_alert_label">Alerta predeterminada</string>

<!-- Notifications -->
<string name="notification_title">Turno próximo</string>
<string name="notification_body">Su turno en %1$s comienza a las %2$s</string>
```

## Manifest Permissions

Add to AndroidManifest.xml:
```xml
<!-- Notification permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- Register the receiver -->
<receiver
    android:name=".notifications.ShiftAlertReceiver"
    android:enabled="true"
    android:exported="false" />
```

## Testing Checklist

1. **Create New Shift**
   - [ ] Alert dropdown shows with default value from settings
   - [ ] Can select different alert options
   - [ ] Notification scheduled correctly
   - [ ] Alert persists when viewing/editing shift

2. **Edit Existing Shift**
   - [ ] Alert value loads correctly
   - [ ] Can change alert setting
   - [ ] Notification updates when alert changed
   - [ ] Notification cancels when alert set to "None"

3. **Settings Page**
   - [ ] Default alert setting shows current value
   - [ ] Can change default alert
   - [ ] New shifts use the default alert value
   - [ ] Setting persists after app restart

4. **Notifications**
   - [ ] Permission requested on first use
   - [ ] Notifications appear at correct time
   - [ ] Notification content is localized
   - [ ] Notifications work when app is closed

5. **Localization**
   - [ ] All alert options display in correct language
   - [ ] Notification content appears in user's language
   - [ ] Settings labels are translated

## Important Notes

1. **Android 12+ Notification Permission**: Request POST_NOTIFICATIONS permission at runtime for Android 12 and above
2. **Exact Alarm Permission**: For Android 12+, guide users to grant exact alarm permission in settings if denied
3. **Background Restrictions**: Test notifications with battery optimization to ensure they work reliably
4. **Time Zones**: Ensure notification scheduling accounts for device time zone
5. **Database Sync**: The alert_minutes field must sync properly with Supabase

## Migration Steps

1. Run the SQL migration script (already completed)
2. Update data models with new fields
3. Implement NotificationManager
4. Add UI components to Add/Edit Shift screen
5. Add Default Alert to Settings
6. Update localization files
7. Test all scenarios
8. Handle edge cases (past alerts, permission denials)

## Support Contact

For questions or issues during implementation, refer to the iOS implementation in:
- `/ProTip365/AddShift/AddShiftView.swift`
- `/ProTip365/Settings/WorkDefaultsSection.swift`
- `/ProTip365/Managers/NotificationManager.swift`