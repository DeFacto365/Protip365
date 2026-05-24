import SwiftUI

struct NotificationBell: View {
    @ObservedObject var alertManager: AlertManager
    @State private var showingAlertsList = false
    @State private var animateBell = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            showingAlertsList = true
        }) {
            ZStack {
                // Bell icon
                Image(systemName: alertManager.hasUnreadAlerts ? "bell.fill" : "bell")
                    .font(.title2)
                    .foregroundColor(alertManager.hasUnreadAlerts ? .blue : .secondary)
                    .scaleEffect(animateBell ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: animateBell)

                // Notification badge
                if alertManager.hasUnreadAlerts {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -4)
                        }
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAlertsList) {
            AlertsListView(alertManager: alertManager)
        }
        .onChange(of: alertManager.hasUnreadAlerts) { _, newValue in
            if newValue {
                animateBell = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animateBell = false
                }
            }
        }
    }
}

struct AlertsListView: View {
    @ObservedObject var alertManager: AlertManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("language") private var language = "en"

    var title: String {
        switch language {
        case "fr": return "Notifications"
        case "es": return "Notificaciones"
        default: return "Notifications"
        }
    }

    var noAlertsMessage: String {
        switch language {
        case "fr": return "Aucune notification"
        case "es": return "Sin notificaciones"
        default: return "No notifications"
        }
    }

    var clearAllText: String {
        switch language {
        case "fr": return "Tout effacer"
        case "es": return "Borrar todo"
        default: return "Clear All"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if alertManager.alerts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text(noAlertsMessage)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(alertManager.alerts) { alert in
                            AlertRowView(alert: alert, alertManager: alertManager)
                        }
                        .onDelete(perform: deleteAlerts)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !alertManager.alerts.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(clearAllText) {
                            alertManager.clearAllAlerts()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }

    private func deleteAlerts(offsets: IndexSet) {
        for index in offsets {
            let alert = alertManager.alerts[index]
            alertManager.clearAlert(alert)
        }
    }
}

struct AlertRowView: View {
    let alert: AppAlert
    let alertManager: AlertManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Alert type icon
                Image(systemName: alertIconForType(alert.type))
                    .font(.title3)
                    .foregroundColor(alertColorForType(alert.type))
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(alert.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                Spacer()

                // Time stamp
                VStack {
                    Text(timeAgoString(from: alert.date))
                        .font(.caption)
                        .foregroundColor(Color.secondary)

                    Spacer()
                }
            }

            // Action button
            if !alert.action.isEmpty {
                HStack {
                    Spacer()
                    Button(alert.action) {
                        // Handle alert action
                        handleAlertAction(alert)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func alertIconForType(_ type: AppAlert.AlertType) -> String {
        switch type {
        case .missingShift:
            return "calendar.badge.exclamationmark"
        case .incompleteShift:
            return "exclamationmark.triangle"
        case .targetAchieved:
            return "target"
        case .personalBest:
            return "star.fill"
        case .reminder:
            return "bell"
        }
    }

    private func alertColorForType(_ type: AppAlert.AlertType) -> Color {
        switch type {
        case .missingShift:
            return .orange
        case .incompleteShift:
            return .red
        case .targetAchieved:
            return .green
        case .personalBest:
            return .purple
        case .reminder:
            return .blue
        }
    }

    private func handleAlertAction(_ alert: AppAlert) {
        // This could be enhanced to handle different actions
        // For now, we'll just dismiss the alert
        alertManager.clearAlert(alert)
    }

    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "Now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        }
    }
}

#Preview {
    let alertManager = AlertManager()
    // Add some sample alerts for preview
    alertManager.alerts = [
        AppAlert(type: .missingShift, title: "Missing Shift Data", message: "You had a shift yesterday but no data was entered.", action: "Enter Data", date: Date()),
        AppAlert(type: .targetAchieved, title: "🎉 Tip Target Achieved!", message: "You've hit your daily tip target!", action: "View Details", date: Date().addingTimeInterval(-3600))
    ]
    alertManager.hasUnreadAlerts = true

    return NotificationBell(alertManager: alertManager)
}