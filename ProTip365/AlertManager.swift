import Foundation
import SwiftUI

class AlertManager: ObservableObject {
    @Published var alerts: [AppAlert] = []
    @Published var showAlert = false
    @Published var currentAlert: AppAlert?
    
    func checkForMissingShifts(shifts: [ShiftIncome], targets: DashboardView.UserTargets) {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        
        // Check for missing shift from yesterday
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let yesterdayString = dateFormatter.string(from: yesterday)
        
        let yesterdayShifts = shifts.filter { $0.shift_date == yesterdayString }
        
        if yesterdayShifts.isEmpty {
            // Check if there was an expected shift (you could add logic here based on user's typical schedule)
            let alert = AppAlert(
                type: .missingShift,
                title: "Missing Shift Data",
                message: "You had a shift yesterday but no data was entered. Don't forget to record your earnings!",
                action: "Enter Data",
                date: yesterday
            )
            addAlert(alert)
        }
        
        // Check for missing data in recent shifts
        checkForIncompleteShifts(shifts: shifts)
    }
    
    func checkForTargetAchievements(currentStats: DashboardView.Stats, targets: DashboardView.UserTargets, period: Int) {
        let periodName = period == 0 ? "daily" : period == 1 ? "weekly" : "monthly"
        
        // Check tip targets
        let tipTarget = period == 0 ? targets.dailyTips : period == 1 ? targets.weeklyTips : targets.monthlyTips
        if tipTarget > 0 && currentStats.tips >= tipTarget {
            let alert = AppAlert(
                type: .targetAchieved,
                title: "🎉 Tip Target Achieved!",
                message: "You've hit your \(periodName) tip target of \(formatCurrency(tipTarget))!",
                action: "View Details",
                date: Date()
            )
            addAlert(alert)
        }
        
        // Check sales targets
        let salesTarget = period == 0 ? targets.dailySales : period == 1 ? targets.weeklySales : targets.monthlySales
        if salesTarget > 0 && currentStats.sales >= salesTarget {
            let alert = AppAlert(
                type: .targetAchieved,
                title: "🔥 Sales Target Crushed!",
                message: "You've exceeded your \(periodName) sales target of \(formatCurrency(salesTarget))!",
                action: "View Details",
                date: Date()
            )
            addAlert(alert)
        }
        
        // Check hours targets
        let hoursTarget = period == 0 ? targets.dailyHours : period == 1 ? targets.weeklyHours : targets.monthlyHours
        if hoursTarget > 0 && currentStats.hours >= hoursTarget {
            let alert = AppAlert(
                type: .targetAchieved,
                title: "💪 Hours Goal Met!",
                message: "You've reached your \(periodName) hours target of \(String(format: "%.1f", hoursTarget))h!",
                action: "View Details",
                date: Date()
            )
            addAlert(alert)
        }
        
        // Check for personal bests
        checkForPersonalBests(currentStats: currentStats, period: period)
    }
    
    private func checkForIncompleteShifts(shifts: [ShiftIncome]) {
        let calendar = Calendar.current
        let today = Date()
        
        // Check last 3 days for incomplete shifts
        for dayOffset in 1...3 {
            guard let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: checkDate)
            
            let dayShifts = shifts.filter { $0.shift_date == dateString }
            
            for shift in dayShifts {
                if shift.hours == 0 && shift.sales == 0 && shift.tips == 0 {
                    let alert = AppAlert(
                        type: .incompleteShift,
                        title: "Incomplete Shift Data",
                        message: "Your shift on \(formatDate(shift.shift_date)) appears to be missing earnings data.",
                        action: "Complete Shift",
                        date: checkDate
                    )
                    addAlert(alert)
                }
            }
        }
    }
    
    private func checkForPersonalBests(currentStats: DashboardView.Stats, period: Int) {
        // This would need to be enhanced with historical data storage
        // For now, we'll just check for high performance indicators
        
        if currentStats.tipPercentage > 20 {
            let alert = AppAlert(
                type: .personalBest,
                title: "⭐ Excellent Tip Performance!",
                message: "Your \(String(format: "%.1f", currentStats.tipPercentage))% tip rate is outstanding!",
                action: "Celebrate",
                date: Date()
            )
            addAlert(alert)
        }
        
        if currentStats.hours > 0 && (currentStats.totalRevenue / currentStats.hours) > 25 {
            let alert = AppAlert(
                type: .personalBest,
                title: "🚀 High Hourly Rate!",
                message: "You're earning $\(String(format: "%.2f", currentStats.totalRevenue / currentStats.hours))/hour!",
                action: "Keep It Up",
                date: Date()
            )
            addAlert(alert)
        }
    }
    
    private func addAlert(_ alert: AppAlert) {
        // Don't add duplicate alerts
        if !alerts.contains(where: { $0.title == alert.title && $0.date == alert.date }) {
            alerts.append(alert)
            currentAlert = alert
            showAlert = true
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        return displayFormatter.string(from: date)
    }
    
    func clearAlert(_ alert: AppAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
    
    func clearAllAlerts() {
        alerts.removeAll()
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
