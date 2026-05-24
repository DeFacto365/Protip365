import SwiftUI
import Supabase

/// Data structures and calculations for Dashboard metrics
struct DashboardMetrics {

    // MARK: - Data Structures

    struct Stats {
        var hours: Double = 0
        var sales: Double = 0
        var tips: Double = 0
        var tipOut: Double = 0
        var other: Double = 0
        var income: Double = 0  // This is GROSS salary (hours × rate)
        var tipPercentage: Double = 0
        var totalRevenue: Double = 0  // NET salary + tips + other - tipout
        var shifts: [ShiftIncome] = []

        // Calculate net salary after deductions
        func netIncome(deductionPercentage: Double) -> Double {
            return income * (1 - deductionPercentage / 100)
        }
    }

    struct UserTargets {
        var tipTargetPercentage: Double = 0
        var dailySales: Double = 0
        var weeklySales: Double = 0
        var monthlySales: Double = 0
        var dailyHours: Double = 0
        var weeklyHours: Double = 0
        var monthlyHours: Double = 0
        var dailyIncome: Double = 0
        var weeklyIncome: Double = 0
        var monthlyIncome: Double = 0
    }

    struct DetailViewData: Identifiable {
        let id = UUID()
        let type: String
        let shifts: [ShiftIncome]
        let period: String
    }

    // MARK: - Metric Calculations

    static func calculateStats(for shifts: [ShiftIncome], averageDeductionPercentage: Double, defaultHourlyRate: Double) -> Stats {
        var stats = Stats()
        // Only include shifts that have earnings (actual worked shifts)
        stats.shifts = shifts.filter { $0.has_earnings }

        for shift in stats.shifts {
            // Use actual hours from shift_income
            stats.hours += shift.hours
            stats.sales += shift.sales
            stats.tips += shift.tips
            // Use base_income if available (from v_shift_income view), otherwise calculate
            if let baseIncome = shift.base_income {
                stats.income += baseIncome
            } else {
                stats.income += (shift.hours * (shift.hourly_rate ?? defaultHourlyRate))
            }
            stats.tipOut += (shift.cash_out ?? 0)
            stats.other += (shift.other ?? 0)
        }

        // Calculate total revenue: NET salary + tips + other - tip out
        let netSalary = stats.income * (1 - averageDeductionPercentage / 100)
        stats.totalRevenue = netSalary + stats.tips + stats.other - stats.tipOut

        if stats.sales > 0 && !stats.sales.isNaN && !stats.tips.isNaN {
            stats.tipPercentage = (stats.tips / stats.sales) * 100
        } else {
            stats.tipPercentage = 0
        }

        return stats
    }

    // MARK: - Target Calculations

    static func getHoursTarget(selectedPeriod: Int, monthViewType: Int, userTargets: UserTargets) -> Double {
        switch selectedPeriod {
        case 0: return userTargets.dailyHours
        case 1: return userTargets.weeklyHours
        case 2:
            // For month view, use monthly target or calculate from 4 weeks if in 4-week mode
            if monthViewType == 1 && userTargets.weeklyHours > 0 {
                return userTargets.weeklyHours * 4
            }
            return userTargets.monthlyHours
        case 3:
            // For year view, calculate based on months elapsed
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            return userTargets.monthlyHours * Double(currentMonth)
        default: return 0
        }
    }

    static func getSalesTarget(selectedPeriod: Int, monthViewType: Int, userTargets: UserTargets) -> Double {
        switch selectedPeriod {
        case 0: return userTargets.dailySales
        case 1: return userTargets.weeklySales
        case 2:
            // For month view, use monthly target or calculate from 4 weeks if in 4-week mode
            if monthViewType == 1 && userTargets.weeklySales > 0 {
                return userTargets.weeklySales * 4
            }
            return userTargets.monthlySales
        case 3:
            // For year view, calculate based on months elapsed
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            return userTargets.monthlySales * Double(currentMonth)
        default: return 0
        }
    }

    // MARK: - Formatting Methods

    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    static func formatIncomeWithTarget(currentStats: Stats, selectedPeriod: Int, userTargets: UserTargets) -> String {
        let income = formatCurrency(currentStats.income)
        // Only show target for Today tab (selectedPeriod == 0)
        if selectedPeriod == 0 {
            let target = userTargets.dailyIncome
            let result = target > 0 ? "\(income)/\(formatCurrency(target))" : income
            print("💰 Format Income: Period=\(selectedPeriod), Income=\(income), Target=\(target), Result=\(result)")
            return result
        } else {
            // For Week, Month, Year - just show income without target
            print("💰 Format Income: Period=\(selectedPeriod), Income=\(income), No target for non-daily periods")
            return income
        }
    }

    static func formatTipsWithTarget(currentStats: Stats, selectedPeriod: Int, userTargets: UserTargets) -> String {
        let tips = formatCurrency(currentStats.tips)
        // Make percentage more prominent with bullet separator
        let percentageStr = currentStats.sales > 0 ? " • \(String(format: "%.1f", currentStats.tipPercentage))%" : ""

        // Only show target for Today tab (selectedPeriod == 0)
        if selectedPeriod == 0 && userTargets.tipTargetPercentage > 0 && currentStats.sales > 0 {
            let targetAmount = currentStats.sales * (userTargets.tipTargetPercentage / 100.0)
            let result = "\(tips)/\(formatCurrency(targetAmount))\(percentageStr)"
            print("💵 Format Tips: Period=\(selectedPeriod), Tips=\(tips), Sales=\(currentStats.sales), Target%=\(userTargets.tipTargetPercentage), TargetAmount=\(targetAmount), Percentage=\(currentStats.tipPercentage), Result=\(result)")
            return result
        } else {
            print("💵 Format Tips: Period=\(selectedPeriod), Tips=\(tips), Percentage=\(currentStats.tipPercentage), No target or only showing for Today")
            return tips + percentageStr
        }
    }

    static func formatHoursWithTarget(currentStats: Stats, selectedPeriod: Int, monthViewType: Int, userTargets: UserTargets) -> String {
        let hoursStr = String(format: "%.1fh", currentStats.hours)
        let target = getHoursTarget(selectedPeriod: selectedPeriod, monthViewType: monthViewType, userTargets: userTargets)
        if target > 0 {
            let percentage = (currentStats.hours / target) * 100
            return "\(hoursStr) (\(Int(percentage))%)"
        }
        return hoursStr
    }

    static func getProgressColor(percentage: Double) -> Color {
        if percentage >= 100 {
            return .green
        } else if percentage >= 75 {
            return .purple
        } else if percentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Date Utilities

    static func getStartOfWeek(for date: Date, weekStartDay: Int) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date) - 1
        let daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
    }

    static func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    static func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Period Text Generation

    static func getPeriodText(selectedPeriod: Int, monthViewType: Int, localization: DashboardLocalization) -> String {
        switch selectedPeriod {
        case 1: return localization.weekText
        case 2:
            return monthViewType == 0 ? localization.monthText : localization.fourWeeksText
        case 3: return localization.yearText
        default: return localization.todayText
        }
    }

    // MARK: - Share Text Generation

    static func generateShareText(currentStats: Stats, selectedPeriod: Int) -> String {
        let periodName = selectedPeriod == 0 ? "Today" : selectedPeriod == 1 ? "This Week" : "This Month"

        return """
        📊 ProTip365 - \(periodName) Summary

        💰 Total Revenue: \(formatCurrency(currentStats.totalRevenue))
        💵 Tips: \(formatCurrency(currentStats.tips))
        ⏰ Hours: \(String(format: "%.1f", currentStats.hours))h
        🛒 Sales: \(formatCurrency(currentStats.sales))

        🎯 Tip Percentage: \(String(format: "%.1f", currentStats.tipPercentage))%

        #ProTip365 #Waitstaff #Tips
        """
    }
}