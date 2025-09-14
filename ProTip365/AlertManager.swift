import Foundation
import SwiftUI

class AlertManager: ObservableObject {
    @Published var alerts: [AppAlert] = []
    @Published var showAlert = false
    @Published var currentAlert: AppAlert?
    @Published var hasUnreadAlerts = false

    private var language: String {
        UserDefaults.standard.string(forKey: "language") ?? "en"
    }

    init() {
        loadPersistedAlerts()
    }

    func checkForMissingShifts(shifts: [ShiftIncome], targets: DashboardView.UserTargets) {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let yesterdayString = dateFormatter.string(from: yesterday)

        let yesterdayShifts = shifts.filter { $0.shift_date == yesterdayString }

        if yesterdayShifts.isEmpty {
            let alert = AppAlert(
                type: .missingShift,
                title: localizedString(key: "missingShiftTitle"),
                message: localizedString(key: "missingShiftMessage"),
                action: localizedString(key: "enterData"),
                date: yesterday
            )
            addAlert(alert)
        }
    }

    func checkForTargetAchievements(currentStats: DashboardView.Stats, targets: DashboardView.UserTargets, period: Int) {
        if targets.tipTargetPercentage > 0 && currentStats.sales > 0 {
            let tipTarget = currentStats.sales * (targets.tipTargetPercentage / 100.0)
            if currentStats.tips >= tipTarget {
                let message = "\(localizedString(key: "tipTargetAchievedMessage")) \(formatCurrency(tipTarget))"
                let alert = AppAlert(
                    type: .targetAchieved,
                    title: localizedString(key: "tipTargetAchievedTitle"),
                    message: message,
                    action: localizedString(key: "viewDetails"),
                    date: Date()
                )
                addAlert(alert)
            }
        }
    }

    func clearAlert(_ alert: AppAlert) {
        alerts.removeAll { $0.id == alert.id }
        updateUnreadStatus()
    }

    func clearAllAlerts() {
        alerts.removeAll()
        hasUnreadAlerts = false
    }

    private func addAlert(_ alert: AppAlert) {
        if !alerts.contains(where: { $0.title == alert.title && $0.date == alert.date }) {
            alerts.append(alert)
            currentAlert = alert
            showAlert = true
            updateUnreadStatus()
        }
    }

    private func loadPersistedAlerts() {
        updateUnreadStatus()
    }

    private func updateUnreadStatus() {
        hasUnreadAlerts = !alerts.isEmpty
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
        case "missingShiftTitle": return "Missing Shift Data"
        case "missingShiftMessage": return "You had a shift yesterday but no data was entered."
        case "enterData": return "Enter Data"
        case "tipTargetAchievedTitle": return "🎉 Tip Target Achieved!"
        case "tipTargetAchievedMessage": return "You've hit your tip target!"
        case "viewDetails": return "View Details"
        default: return key
        }
    }

    private func localizedStringFR(key: String) -> String {
        switch key {
        case "missingShiftTitle": return "Données manquantes"
        case "missingShiftMessage": return "Vous aviez un quart hier."
        case "enterData": return "Saisir"
        case "tipTargetAchievedTitle": return "🎉 Objectif atteint!"
        case "tipTargetAchievedMessage": return "Objectif de pourboire atteint!"
        case "viewDetails": return "Détails"
        default: return key
        }
    }

    private func localizedStringES(key: String) -> String {
        switch key {
        case "missingShiftTitle": return "Datos faltantes"
        case "missingShiftMessage": return "Tuviste un turno ayer."
        case "enterData": return "Ingresar"
        case "tipTargetAchievedTitle": return "🎉 ¡Objetivo alcanzado!"
        case "tipTargetAchievedMessage": return "¡Objetivo de propinas alcanzado!"
        case "viewDetails": return "Detalles"
        default: return key
        }
    }
}

struct AppAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let title: String
    let message: String
    let action: String
    let date: Date

    enum AlertType {
        case missingShift
        case incompleteShift
        case targetAchieved
        case personalBest
        case reminder
    }
}