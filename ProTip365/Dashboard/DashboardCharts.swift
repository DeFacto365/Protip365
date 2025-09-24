import SwiftUI
import Supabase

/// Chart and data loading components for Dashboard view
struct DashboardCharts {

    // MARK: - Helper Functions

    /// Converts Shift array to ShiftIncome array for compatibility
    private static func convertShiftsToShiftIncome(_ shifts: [Shift]) -> [ShiftIncome] {
        return shifts.map { shift in
            let hours = shift.hours ?? shift.expected_hours ?? 0
            let hourlyRate = shift.hourly_rate ?? 0
            let sales = shift.sales ?? 0
            let tips = shift.tips ?? 0
            let cashOut = shift.cash_out ?? 0
            let other = shift.other ?? 0

            // Calculate base income (hours * hourly rate)
            let baseIncome = hours * hourlyRate

            // Calculate net tips (tips - cash_out)
            let netTips = tips - cashOut

            // Calculate total income (base + net tips + other)
            let totalIncome = baseIncome + netTips + other

            // Calculate tip percentage if sales > 0
            let tipPercentage = sales > 0 ? (tips / sales) * 100 : 0

            return ShiftIncome(
                income_id: nil,
                shift_id: shift.id,
                user_id: shift.user_id,
                employer_id: shift.employer_id,
                employer_name: nil, // We don't have employer name in shifts table
                shift_date: shift.shift_date,
                expected_hours: shift.expected_hours,
                lunch_break_minutes: shift.lunch_break_minutes,
                net_expected_hours: shift.expected_hours,
                hours: hours,
                hourly_rate: shift.hourly_rate,
                sales: sales,
                tips: tips,
                cash_out: cashOut,
                other: other,
                base_income: baseIncome,
                net_tips: netTips,
                total_income: totalIncome,
                tip_percentage: tipPercentage,
                start_time: shift.start_time,
                end_time: shift.end_time,
                shift_status: shift.status,
                has_earnings: shift.status == "completed" || tips > 0 || sales > 0,
                shift_created_at: nil,
                earnings_created_at: nil,
                notes: shift.notes
            )
        }
    }

    // MARK: - Data Loading

    /// Loads user targets from Supabase
    static func loadTargets() async -> (targets: DashboardMetrics.UserTargets, hourlyRate: Double, deductionPercentage: Double) {
        var targets = DashboardMetrics.UserTargets()
        var hourlyRate: Double = 15.0
        var deductionPercentage: Double = 30.0

        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            struct Profile: Decodable {
                let default_hourly_rate: Double
                let average_deduction_percentage: Double?
                let tip_target_percentage: Double?
                let target_sales_daily: Double?
                let target_sales_weekly: Double?
                let target_sales_monthly: Double?
                let target_hours_daily: Double?
                let target_hours_weekly: Double?
                let target_hours_monthly: Double?
            }

            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            if let profile = profiles.first {
                hourlyRate = profile.default_hourly_rate
                deductionPercentage = profile.average_deduction_percentage ?? 30.0
                targets.tipTargetPercentage = profile.tip_target_percentage ?? 0
                targets.dailySales = profile.target_sales_daily ?? 0
                targets.weeklySales = profile.target_sales_weekly ?? 0
                targets.monthlySales = profile.target_sales_monthly ?? 0
                targets.dailyHours = profile.target_hours_daily ?? 0
                targets.weeklyHours = profile.target_hours_weekly ?? 0
                targets.monthlyHours = profile.target_hours_monthly ?? 0

                // Calculate income targets based on hourly rate
                targets.dailyIncome = profile.default_hourly_rate * (profile.target_hours_daily ?? 0)
                targets.weeklyIncome = profile.default_hourly_rate * (profile.target_hours_weekly ?? 0)
                targets.monthlyIncome = profile.default_hourly_rate * (profile.target_hours_monthly ?? 0)
            }
        } catch {
            print("Error loading targets: \(error)")
        }

        return (targets, hourlyRate, deductionPercentage)
    }

    /// Loads all statistics for different time periods
    static func loadAllStats(forceRefresh: Bool = false, defaultHourlyRate: Double, averageDeductionPercentage: Double) async -> (
        todayStats: DashboardMetrics.Stats,
        weekStats: DashboardMetrics.Stats,
        monthStats: DashboardMetrics.Stats,
        yearStats: DashboardMetrics.Stats,
        fourWeeksStats: DashboardMetrics.Stats
    ) {
        var todayStats = DashboardMetrics.Stats()
        var weekStats = DashboardMetrics.Stats()
        var monthStats = DashboardMetrics.Stats()
        var yearStats = DashboardMetrics.Stats()
        var fourWeeksStats = DashboardMetrics.Stats()

        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            struct Profile: Decodable {
                let week_start: Int?
            }

            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("week_start")
                .eq("user_id", value: userId)
                .execute()
                .value

            let weekStartDay = profiles.first?.week_start ?? 0

            let today = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            // Add delay on force refresh to ensure data is synced
            if forceRefresh {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
            }

            // Load Today's data from v_shift_income view
            let todayQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("shift_date", value: dateFormatter.string(from: today))

            let todayShifts: [ShiftIncome] = try await todayQuery.execute().value
            todayStats = DashboardMetrics.calculateStats(
                for: todayShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // Load Week's data from v_shift_income view
            let weekStart = DashboardMetrics.getStartOfWeek(for: today, weekStartDay: weekStartDay)
            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
            let weekQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("shift_date", value: dateFormatter.string(from: weekStart))
                .lte("shift_date", value: dateFormatter.string(from: weekEnd))

            let weekShifts: [ShiftIncome] = try await weekQuery.execute().value
            weekStats = DashboardMetrics.calculateStats(
                for: weekShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // Load Month's data (current calendar month) from v_shift_income view
            let calendar = Calendar.current
            let monthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
            let monthEnd = calendar.dateInterval(of: .month, for: today)?.end ?? today
            let monthQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("shift_date", value: dateFormatter.string(from: monthStart))
                .lt("shift_date", value: dateFormatter.string(from: monthEnd))

            let monthShifts: [ShiftIncome] = try await monthQuery.execute().value
            monthStats = DashboardMetrics.calculateStats(
                for: monthShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // Load Year's data (since January 1st) from v_shift_income view
            let yearStart = calendar.dateInterval(of: .year, for: today)?.start ?? today
            let yearQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("shift_date", value: dateFormatter.string(from: yearStart))
                .lte("shift_date", value: dateFormatter.string(from: today))

            let yearShifts: [ShiftIncome] = try await yearQuery.execute().value
            yearStats = DashboardMetrics.calculateStats(
                for: yearShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // Load 4 Weeks Pay data (last 4 complete weeks based on week start)
            var fourWeeksShifts: [ShiftIncome] = []
            var currentWeekStart = weekStart
            for _ in 0..<4 {
                let weekEndDate = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
                let weekQuery = SupabaseManager.shared.client
                    .from("v_shift_income")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .gte("shift_date", value: dateFormatter.string(from: currentWeekStart))
                    .lte("shift_date", value: dateFormatter.string(from: weekEndDate))

                let shifts: [ShiftIncome] = try await weekQuery.execute().value
                fourWeeksShifts.append(contentsOf: shifts)

                // Move to previous week
                currentWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
            }
            fourWeeksStats = DashboardMetrics.calculateStats(
                for: fourWeeksShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // Log refresh status
            if forceRefresh {
                #if DEBUG
                print("📊 Dashboard - Data refreshed successfully")
                print("  Today: \(todayStats.shifts.count) shifts")
                print("  Week: \(weekStats.shifts.count) shifts")
                print("  Month: \(monthStats.shifts.count) shifts")
                #endif
            }

        } catch {
            print("Error loading stats: \(error)")
        }

        return (todayStats, weekStats, monthStats, yearStats, fourWeeksStats)
    }
}