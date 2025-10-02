import Foundation
import SwiftUI
import UserNotifications

class AlertManager: ObservableObject {
    static let shared = AlertManager()

    @Published var alerts: [DatabaseAlert] = []
    @Published var showAlert = false
    @Published var currentAlert: DatabaseAlert?
    @Published var hasUnreadAlerts = false

    private var language: String {
        UserDefaults.standard.string(forKey: "language") ?? "en"
    }

    private init() {
        print("🔔 AlertManager initializing...")
        Task {
            await loadAlertsFromDatabase()
        }
    }

    func checkForMissingShiftEntries(shifts: [ShiftWithEntry]) {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let yesterdayString = dateFormatter.string(from: yesterday)

        // Check for shifts from yesterday that are planned but have no earnings data
        let yesterdayPlannedShifts = shifts.filter { shiftWithEntry in
            shiftWithEntry.shift_date == yesterdayString &&
            shiftWithEntry.status == "planned" &&
            shiftWithEntry.entry == nil
        }

        if !yesterdayPlannedShifts.isEmpty {
            for shift in yesterdayPlannedShifts {
                Task {
                    let shiftData: [String: Any] = [
                        "shiftId": shift.id.uuidString
                    ]

                    await createAlert(
                        alertType: "incompleteShift",
                        title: localizedString(key: "incompleteShiftTitle"),
                        message: localizedString(key: "incompleteShiftMessage"),
                        action: localizedString(key: "addEntry"),
                        data: shiftData
                    )
                }

                // Schedule iOS push notification
                scheduleLocalNotification(
                    title: localizedString(key: "incompleteShiftTitle"),
                    body: localizedString(key: "incompleteShiftMessage"),
                    identifier: "missing-entry-\(shift.id.uuidString)"
                )
            }
        }
    }

    func checkForMissingShifts(shifts: [ShiftIncome], targets: DashboardMetrics.UserTargets) {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let yesterdayString = dateFormatter.string(from: yesterday)

        let yesterdayShifts = shifts.filter { $0.shift_date == yesterdayString }

        if yesterdayShifts.isEmpty {
            Task {
                await createAlert(
                    alertType: "missingShift",
                    title: localizedString(key: "missingShiftTitle"),
                    message: localizedString(key: "missingShiftMessage"),
                    action: localizedString(key: "enterData")
                )
            }
        }
    }

    // MARK: - Local Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
                self.scheduleDailyNotificationCheck()
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }
    }

    func scheduleDailyNotificationCheck() {
        // Schedule a daily check at noon for yesterday's shifts
        let content = UNMutableNotificationContent()
        content.title = "ProTip365"
        content.sound = .default

        // Create a trigger for every day at noon
        var dateComponents = DateComponents()
        dateComponents.hour = 12
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-shift-check", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling daily notification: \(error)")
            } else {
                print("✅ Daily notification check scheduled for noon")
            }
        }
    }

    private func scheduleLocalNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "ProTip - \(title)"
        content.body = body
        content.sound = .default
        // Set badge for notification payload (iOS 17+ recommended approach)
        // App badge count is managed separately via setBadgeCount in updateAppBadgeCount()
        content.badge = NSNumber(value: 1)

        // Schedule for immediate delivery (or you can set a specific time)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Notification scheduled: \(title)")
            }
        }
    }

    func checkYesterdayShifts() async {
        // This method will be called from the app delegate or when app becomes active
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let today = Date()

        guard let shifts = try? await SupabaseManager.shared.fetchShiftsWithEntries(from: yesterday, to: today) else { return }
        checkForMissingShiftEntries(shifts: shifts)
    }

    // MARK: - Test Alert (for debugging)

    func addTestAlert() {
        Task {
            await createAlert(
                alertType: "reminder",
                title: "Test Alert",
                message: "This is a test alert to verify the bell icon is working.",
                action: "Dismiss"
            )
            print("🔔 Test alert added to bell icon")
        }
    }


    func addTestShiftAlert() {
        let testShiftId = UUID()
        let testStartTime = Date().addingTimeInterval(1800) // 30 minutes from now

        Task {
            let alertData: [String: Any] = [
                "shiftId": testShiftId.uuidString,
                "employerName": "Test Restaurant",
                "startTime": testStartTime.timeIntervalSince1970
            ]

            await createAlert(
                alertType: "shiftReminder",
                title: localizedString(key: "upcomingShiftTitle"),
                message: String(format: localizedString(key: "upcomingShiftMessage"), "Test Restaurant", "2:30 PM"),
                action: localizedString(key: "viewShift"),
                data: alertData
            )
            print("🔔 Test shift alert added to bell icon with navigation")
        }
    }

    // MARK: - Shift Reminder Alerts

    func addShiftReminderAlert(shiftId: UUID, employerName: String, startTime: Date) {
        Task {
            // Create an alert for the upcoming shift
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: startTime)

            let title = localizedString(key: "upcomingShiftTitle")
            let message = String(format: localizedString(key: "upcomingShiftMessage"), employerName, timeString)

            // Create data payload with shift info
            let alertData: [String: Any] = [
                "shiftId": shiftId.uuidString,
                "employerName": employerName,
                "startTime": startTime.timeIntervalSince1970
            ]

            await createAlert(
                alertType: "shiftReminder",
                title: title,
                message: message,
                action: localizedString(key: "viewShift"),
                data: alertData
            )
        }
    }

    func checkForTargetAchievements(currentStats: DashboardMetrics.Stats, targets: DashboardMetrics.UserTargets, period: Int) {
        if targets.tipTargetPercentage > 0 && currentStats.sales > 0 {
            let tipTarget = currentStats.sales * (targets.tipTargetPercentage / 100.0)
            if currentStats.tips >= tipTarget {
                let message = "\(localizedString(key: "tipTargetAchievedMessage")) \(formatCurrency(tipTarget))"
                Task {
                    await createAlert(
                        alertType: "targetAchieved",
                        title: localizedString(key: "tipTargetAchievedTitle"),
                        message: message,
                        action: localizedString(key: "viewDetails")
                    )
                }
            }
        }
    }

    func clearAlert(_ alert: DatabaseAlert) async {
        do {
            try await SupabaseManager.shared.deleteAlert(alert.id)
            await loadAlertsFromDatabase()
        } catch {
            print("❌ Error deleting alert: \(error)")
        }
    }

    func clearAllAlerts() async {
        do {
            for alert in alerts {
                try await SupabaseManager.shared.deleteAlert(alert.id)
            }
            await loadAlertsFromDatabase()
        } catch {
            print("❌ Error deleting all alerts: \(error)")
        }
    }

    private func createAlert(
        alertType: String,
        title: String,
        message: String,
        action: String? = nil,
        data: [String: Any]? = nil
    ) async {
        do {
            let alertId = try await SupabaseManager.shared.createAlert(
                alertType: alertType,
                title: title,
                message: message,
                action: action,
                data: data
            )
            await loadAlertsFromDatabase()

            // Show the newest alert if it exists
            if let newAlert = alerts.first(where: { $0.id == alertId }) {
                await MainActor.run {
                    currentAlert = newAlert
                    showAlert = true
                }
            }
        } catch {
            print("❌ Error creating alert: \(error)")
        }
    }

    private func loadAlertsFromDatabase() async {
        do {
            // Fetch only unread alerts (the correct behavior)
            let fetchedAlerts = try await SupabaseManager.shared.fetchUnreadAlerts()

            await MainActor.run {
                alerts = fetchedAlerts
                updateUnreadStatus()
            }
        } catch {
            print("❌ Error loading alerts from database: \(error)")
            await MainActor.run {
                alerts = []
                updateUnreadStatus()
            }
        }
    }

    func refreshAlerts() async {
        await loadAlertsFromDatabase()
    }

    func updateAppBadge() {
        updateAppBadgeCount()
    }

    private func updateUnreadStatus() {
        // Since we delete read alerts, all alerts in the array are unread
        hasUnreadAlerts = !alerts.isEmpty

        // Update app badge count using iOS 17+ recommended method
        updateAppBadgeCount()
    }

    @available(iOS, deprecated: 17.0, message: "Use setBadgeCount for iOS 17+")
    private func setLegacyBadgeCount(_ count: Int) {
        // This is intentionally using the deprecated API for iOS 16 compatibility
        // The warning is expected and can be ignored
        UIApplication.shared.applicationIconBadgeNumber = count
    }

    private func updateAppBadgeCount() {
        let badgeCount = alerts.count

        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(badgeCount) { error in
                if let error = error {
                    print("⚠️ Failed to set badge count via UNUserNotificationCenter: \(error)")
                } else {
                    print("🔔 App badge updated to \(badgeCount) via setBadgeCount")
                }
            }
        } else {
            // Fallback for iOS 16 and earlier
            DispatchQueue.main.async { [weak self] in
                self?.setLegacyBadgeCount(badgeCount)
                print("🔔 App badge updated to \(badgeCount) via UIApplication")
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    private func localizedString(key: String) -> String {
        switch language {
        case "fr": return localizedStringFR(key: key)
        case "es": return localizedStringES(key: key)
        default: return localizedStringEN(key: key)
        }
    }

    private func localizedStringEN(key: String) -> String {
        switch key {
        // Apple HIG: Use clear, actionable language
        case "missingShiftTitle": return "Complete Yesterday's Shift"
        case "missingShiftMessage": return "Add earnings data to track your progress"
        case "incompleteShiftTitle": return "Update Shift Data"
        case "incompleteShiftMessage": return "Complete yesterday's shift information"
        case "enterData": return "Add Now"
        case "addEntry": return "Complete"
        case "tipTargetAchievedTitle": return "Target Reached! 🎉"
        case "tipTargetAchievedMessage": return "Congratulations on reaching your goal!"
        case "viewDetails": return "View Details"
        case "upcomingShiftTitle": return "Shift Starting Soon"
        case "upcomingShiftMessage": return "%@ shift begins at %@"
        case "viewShift": return "View Shift"
        default: return key
        }
    }

    private func localizedStringFR(key: String) -> String {
        switch key {
        case "missingShiftTitle": return "Données manquantes"
        case "missingShiftMessage": return "Vous aviez un quart hier."
        case "incompleteShiftTitle": return "Ajouter l'entrée d'hier"
        case "incompleteShiftMessage": return "N'oubliez pas d'ajouter votre entrée au quart d'hier"
        case "enterData": return "Saisir"
        case "addEntry": return "Ajouter"
        case "tipTargetAchievedTitle": return "🎉 Objectif atteint!"
        case "tipTargetAchievedMessage": return "Objectif de pourboire atteint!"
        case "viewDetails": return "Détails"
        case "upcomingShiftTitle": return "Quart à venir"
        case "upcomingShiftMessage": return "Votre quart chez %@ commence à %@"
        case "viewShift": return "Voir le quart"
        default: return key
        }
    }

    private func localizedStringES(key: String) -> String {
        switch key {
        case "missingShiftTitle": return "Datos faltantes"
        case "missingShiftMessage": return "Tuviste un turno ayer."
        case "incompleteShiftTitle": return "Agregar entrada de ayer"
        case "incompleteShiftMessage": return "No olvides agregar tu entrada al turno de ayer"
        case "enterData": return "Ingresar"
        case "addEntry": return "Agregar"
        case "tipTargetAchievedTitle": return "🎉 ¡Objetivo alcanzado!"
        case "tipTargetAchievedMessage": return "¡Objetivo de propinas alcanzado!"
        case "viewDetails": return "Detalles"
        case "upcomingShiftTitle": return "Turno próximo"
        case "upcomingShiftMessage": return "Su turno en %@ comienza a las %@"
        case "viewShift": return "Ver turno"
        default: return key
        }
    }
}

// Legacy AppAlert structs have been replaced by DatabaseAlert in Models.swift
// All alerts are now stored in the database for cross-device sync
