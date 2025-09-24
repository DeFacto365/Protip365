import SwiftUI
import Foundation

struct NotificationBell: View {
    @ObservedObject var alertManager: AlertManager
    @State private var showingAlertsList = false
    @State private var animateBell = false

    var body: some View {
        ZStack {
            // Invisible background to capture taps
            Color.clear
                .frame(width: 44, height: 44)

            // iOS notification center icon
            Image(systemName: "list.bullet.rectangle")
                .font(.title2)
                .foregroundColor(alertManager.hasUnreadAlerts ? .blue : .secondary)
                .scaleEffect(animateBell ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: animateBell)

            // iOS-style notification badge
            if alertManager.hasUnreadAlerts && alertManager.alerts.count > 0 {
                Text("\(alertManager.alerts.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(minWidth: 18, minHeight: 18)
                    .background(.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.light()
            showingAlertsList = true
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await alertManager.clearAlert(alert)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete(perform: deleteAlerts) // Keep for compatibility
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
                            Task {
                                await alertManager.clearAllAlerts()
                            }
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
            Task {
                await alertManager.clearAlert(alert)
            }
        }
    }
}

struct AlertRowView: View {
    let alert: DatabaseAlert
    let alertManager: AlertManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Alert type icon
                Image(systemName: alertIconForType(alert.alert_type))
                    .font(.title3)
                    .foregroundColor(alertColorForType(alert.alert_type))
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
                    Text(timeAgoString(from: alert.created_at))
                        .font(.caption)
                        .foregroundColor(Color.secondary)

                    Spacer()
                }
            }

            // Action button (only shows "View Shift" style actions)
            if let action = alert.action, !action.isEmpty && isNavigationAction(alert.alert_type) {
                HStack {
                    Spacer()
                    Button(action) {
                        // Handle alert action without dismissing alert
                        handleAlertActionOnly(alert)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            // iOS standard: tap alert to navigate to content
            handleAlertTap(alert)
        }
    }

    private func alertIconForType(_ type: String) -> String {
        switch type {
        case "missingShift":
            return "calendar.badge.exclamationmark"
        case "incompleteShift":
            return "exclamationmark.triangle"
        case "targetAchieved":
            return "target"
        case "personalBest":
            return "star.fill"
        case "reminder":
            return "bell"
        case "shiftReminder":
            return "clock.badge"
        default:
            return "bell"
        }
    }

    private func alertColorForType(_ type: String) -> Color {
        switch type {
        case "missingShift":
            return .orange
        case "incompleteShift":
            return .red
        case "targetAchieved":
            return .green
        case "personalBest":
            return .purple
        case "reminder":
            return .blue
        case "shiftReminder":
            return .blue
        default:
            return .blue
        }
    }

    private func isNavigationAction(_ alertType: String) -> Bool {
        // Only show action button for alerts that have navigation actions
        return ["shiftReminder", "incompleteShift", "missingShift"].contains(alertType)
    }

    private func handleAlertTap(_ alert: DatabaseAlert) {
        // iOS standard: tap alert to navigate and auto-dismiss
        navigateToContent(alert)
        dismiss() // Close the alerts sheet
    }

    private func handleAlertActionOnly(_ alert: DatabaseAlert) {
        // Handle the action button without dismissing the sheet
        navigateToContent(alert)
    }

    private func navigateToContent(_ alert: DatabaseAlert) {
        switch alert.alert_type {
        case "missingShift", "incompleteShift":
            // Navigate to calendar for adding entry
            NotificationCenter.default.post(name: .navigateToCalendar, object: nil)
        case "shiftReminder":
            // Navigate to the specific shift for editing
            if let shiftId = alert.getShiftId() {
                NotificationCenter.default.post(name: .navigateToShift, object: shiftId)
            } else {
                // Fallback to calendar if no specific shift ID
                NotificationCenter.default.post(name: .navigateToCalendar, object: nil)
            }
        case "targetAchieved", "personalBest":
            // These don't have navigation, just mark as read
            Task {
                await alertManager.clearAlert(alert)
            }
        default:
            break
        }
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
    VStack {
        // Simple bell icon for preview
        Image(systemName: "bell.badge")
            .font(.title2)
            .foregroundColor(.blue)
    }
}