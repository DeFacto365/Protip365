import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Manager
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private override init() {
        super.init()
        checkAuthorizationStatus()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
    }

    private func setupNotificationCategories() {
        // Apple HIG: Provide meaningful, actionable notification actions
        let viewShiftAction = UNNotificationAction(
            identifier: "VIEW_SHIFT",
            title: localizedString(key: "viewShift", language: UserDefaults.standard.string(forKey: "language") ?? "en"),
            options: [.foreground] // Opens app
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_SHIFT",
            title: localizedString(key: "snooze", language: UserDefaults.standard.string(forKey: "language") ?? "en"),
            options: []
        )

        let shiftCategory = UNNotificationCategory(
            identifier: "SHIFT_REMINDER",
            actions: [viewShiftAction, snoozeAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([shiftCategory])
    }

    // MARK: - Badge Management

    func clearAppBadge() {
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("⚠️ Failed to clear badge via UNUserNotificationCenter: \(error)")
                } else {
                    print("🔔 App badge cleared")
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
            print("🔔 App badge cleared")
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                self.isAuthorized = granted
            }

            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Shift Alert

    func scheduleShiftAlert(
        shiftId: UUID,
        shiftDate: Date,
        startTime: Date,
        employerName: String,
        alertMinutes: Int
    ) async throws {
        print("🚀 Starting notification scheduling...")
        print("🔐 Current authorization status: \(isAuthorized)")

        if !isAuthorized {
            print("❌ Not authorized, requesting permission...")
            let granted = await requestAuthorization()
            print("✅ Permission granted: \(granted)")
            if !granted {
                print("❌ User denied notification permission")
                throw NotificationError.notAuthorized
            }
            // Permission was granted, continue with function execution
        }

        // Calculate alert time
        let calendar = Calendar.current

        // Combine shift date with start time
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        var shiftDateComponents = calendar.dateComponents([.year, .month, .day], from: shiftDate)
        shiftDateComponents.hour = startComponents.hour
        shiftDateComponents.minute = startComponents.minute

        guard let shiftStartDateTime = calendar.date(from: shiftDateComponents) else {
            throw NotificationError.invalidDate
        }

        // Subtract alert minutes to get notification time
        guard let alertTime = calendar.date(byAdding: .minute, value: -alertMinutes, to: shiftStartDateTime) else {
            throw NotificationError.invalidDate
        }

        // Apple HIG: Don't schedule if alert time is in the past or too far in future
        let now = Date()
        if alertTime < now {
            print("❌ Alert time \(alertTime) is in the past (now: \(now))")
            print("❌ Not scheduling notification")
            return
        }

        let timeUntilAlert = alertTime.timeIntervalSince(now)

        // Apple HIG: Don't schedule notifications too far in advance (more than 7 days)
        let maxAdvanceTime: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        if timeUntilAlert > maxAdvanceTime {
            print("⚠️ Alert time is more than 7 days in advance, may not be delivered reliably")
        }

        print("⏳ Alert will fire in \(Int(timeUntilAlert / 60)) minutes")

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = localizedTitle()
        content.body = localizedBody(employerName: employerName, startTime: startTime)
        content.sound = .default

        // Apple HIG: Add meaningful actions
        content.categoryIdentifier = "SHIFT_REMINDER"

        // Set badge for notification payload (recommended approach)
        // The actual app badge will be managed by AlertManager using setBadgeCount
        content.badge = NSNumber(value: 1)

        // Add userInfo for handling when notification fires
        content.userInfo = [
            "type": "shiftReminder",
            "shiftId": shiftId.uuidString,
            "employerName": employerName,
            "startTime": startTime.timeIntervalSince1970
        ]

        // Create trigger
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alertTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Create request with shift ID as identifier
        let request = UNNotificationRequest(
            identifier: "shift-\(shiftId.uuidString)",
            content: content,
            trigger: trigger
        )

        // Schedule notification
        try await UNUserNotificationCenter.current().add(request)
        print("✅ Scheduled shift alert for \(alertTime)")
        print("🔔 Notification ID: shift-\(shiftId.uuidString)")
        print("🏢 Employer: \(employerName)")
        print("⏰ Alert time: \(alertTime)")
        print("📅 Shift time: \(shiftStartDateTime)")

        // If alert time is very soon (within 5 minutes), also add to bell alerts immediately
        if timeUntilAlert <= 300 { // 5 minutes = 300 seconds
            DispatchQueue.main.async {
                AlertManager.shared.addShiftReminderAlert(
                    shiftId: shiftId,
                    employerName: employerName,
                    startTime: startTime
                )
                print("🔔 Also added immediate bell alert (shift starting soon)")
            }
        }

        // Debug: List all pending notifications
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📝 Total pending notifications: \(pendingRequests.count)")
        for request in pendingRequests {
            if request.identifier.hasPrefix("shift-") {
                print("   - \(request.identifier): \(request.content.title)")
            }
        }
    }

    // MARK: - Cancel Shift Alert

    func cancelShiftAlert(shiftId: UUID) {
        let identifier = "shift-\(shiftId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("❌ Cancelled shift alert for \(shiftId)")
    }

    // MARK: - Update Shift Alert

    func updateShiftAlert(
        shiftId: UUID,
        shiftDate: Date,
        startTime: Date,
        employerName: String,
        alertMinutes: Int?
    ) async throws {
        // Cancel existing notification
        cancelShiftAlert(shiftId: shiftId)

        // Schedule new one if alert is set
        if let alertMinutes = alertMinutes, alertMinutes > 0 {
            try await scheduleShiftAlert(
                shiftId: shiftId,
                shiftDate: shiftDate,
                startTime: startTime,
                employerName: employerName,
                alertMinutes: alertMinutes
            )
        }
    }

    // MARK: - Testing Functions

    /// Test function to create a notification in 10 seconds
    func scheduleTestNotification() async {
        do {
            let testDate = Date().addingTimeInterval(10) // 10 seconds from now
            let testShiftTime = Date().addingTimeInterval(600) // 10 minutes from now

            try await scheduleShiftAlert(
                shiftId: UUID(),
                shiftDate: testDate,
                startTime: testShiftTime,
                employerName: "Test Restaurant",
                alertMinutes: 1 // 1 minute before "shift"
            )
            print("🧪 Test notification scheduled for 10 seconds from now")
        } catch {
            print("❌ Failed to schedule test notification: \(error)")
        }
    }

    // MARK: - Localization

    private func localizedTitle() -> String {
        let language = UserDefaults.standard.string(forKey: "language") ?? "en"
        // Apple HIG: Keep titles brief and clear, avoid app name prefix in notifications
        return localizedString(key: "upcomingShiftTitle", language: language)
    }

    private func localizedBody(employerName: String, startTime: Date) -> String {
        let language = UserDefaults.standard.string(forKey: "language") ?? "en"
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let timeString = formatter.string(from: startTime)

        let template = localizedString(key: "upcomingShiftMessage", language: language)
        return String(format: template, employerName, timeString)
    }

    private func localizedString(key: String, language: String) -> String {
        switch language {
        case "fr": return localizedStringFR(key: key)
        case "es": return localizedStringES(key: key)
        default: return localizedStringEN(key: key)
        }
    }

    private func localizedStringEN(key: String) -> String {
        switch key {
        case "upcomingShiftTitle": return "Shift Starting Soon"  // More urgent, actionable
        case "upcomingShiftMessage": return "%@ shift starts at %@" // Concise, clear
        case "notificationPermissionTitle": return "Enable Shift Reminders"
        case "notificationPermissionMessage": return "Get notified before your shifts start"
        case "viewShift": return "View Shift"
        case "snooze": return "Snooze"
        default: return key
        }
    }

    private func localizedStringFR(key: String) -> String {
        switch key {
        case "upcomingShiftTitle": return "Quart bientôt"  // "Shift soon"
        case "upcomingShiftMessage": return "Quart chez %@ à %@"  // Concise
        case "notificationPermissionTitle": return "Rappels de quart"
        case "notificationPermissionMessage": return "Recevez des rappels avant vos quarts"
        case "viewShift": return "Voir le quart"
        case "snooze": return "Reporter"
        default: return key
        }
    }

    private func localizedStringES(key: String) -> String {
        switch key {
        case "upcomingShiftTitle": return "Turno pronto"  // "Shift soon"
        case "upcomingShiftMessage": return "Turno en %@ a las %@"  // Concise
        case "notificationPermissionTitle": return "Recordatorios de turno"
        case "notificationPermissionMessage": return "Recibe avisos antes de tus turnos"
        case "viewShift": return "Ver turno"
        case "snooze": return "Posponer"
        default: return key
        }
    }

    // MARK: - Notification Delegate Methods

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle notification when app is in foreground
        handleNotification(notification)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification when user interacts with it
        handleNotification(response.notification)

        // Apple HIG: Handle notification actions appropriately
        switch response.actionIdentifier {
        case "VIEW_SHIFT":
            // Navigation will be handled by the existing handleNotification method
            print("📱 User tapped View Shift action")
        case "SNOOZE_SHIFT":
            handleSnoozeAction(response.notification)
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body
            print("📱 User tapped notification body")
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("📱 User dismissed notification")
        default:
            break
        }

        // Clear badge when user interacts with notification
        clearAppBadge()

        completionHandler()
    }

    private func handleSnoozeAction(_ notification: UNNotification) {
        // Apple HIG: Snooze should reschedule notification for a reasonable time
        let userInfo = notification.request.content.userInfo
        guard let shiftIdString = userInfo["shiftId"] as? String,
              let shiftId = UUID(uuidString: shiftIdString) else { return }

        Task {
            do {
                let content = notification.request.content.mutableCopy() as! UNMutableNotificationContent
                content.title = localizedString(key: "upcomingShiftTitle", language: UserDefaults.standard.string(forKey: "language") ?? "en")

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "snooze-\(shiftId.uuidString)",
                    content: content,
                    trigger: trigger
                )

                try await UNUserNotificationCenter.current().add(request)
                print("🔔 Snoozed shift notification for 10 minutes")
            } catch {
                print("❌ Failed to snooze notification: \(error)")
            }
        }
    }

    private func handleNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo

        guard let type = userInfo["type"] as? String,
              type == "shiftReminder",
              let shiftIdString = userInfo["shiftId"] as? String,
              let shiftId = UUID(uuidString: shiftIdString),
              let employerName = userInfo["employerName"] as? String,
              let startTimeInterval = userInfo["startTime"] as? TimeInterval else {
            return
        }

        let startTime = Date(timeIntervalSince1970: startTimeInterval)

        // Log notification received for debugging
        print("📱 Shift notification received for \(employerName) at \(startTime)")

        // Add to bell icon alerts
        DispatchQueue.main.async {
            AlertManager.shared.addShiftReminderAlert(
                shiftId: shiftId,
                employerName: employerName,
                startTime: startTime
            )
            print("🔔 Added shift reminder to bell alerts")
        }
    }
}

// MARK: - Notification Error

enum NotificationError: LocalizedError {
    case notAuthorized
    case invalidDate

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifications are not authorized. Please enable them in Settings."
        case .invalidDate:
            return "Invalid date for notification scheduling."
        }
    }
}

