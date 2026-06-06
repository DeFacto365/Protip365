import SwiftUI
import Supabase

/// Chart and data loading components for Dashboard view
struct DashboardCharts {

    // MARK: - Caching for Performance

    private static var cachedData: (data: [ShiftIncome], cacheTime: Date)? = nil
    private static let cacheValiditySeconds: TimeInterval = 300 // 5 minutes

    private static func isCacheValid() -> Bool {
        guard let cache = cachedData else { return false }
        return Date().timeIntervalSince(cache.cacheTime) < cacheValiditySeconds
    }

    static func invalidateCache() {
        print("📊 Dashboard - Cache invalidated")
        cachedData = nil
    }

    // MARK: - Helper Functions

    /// Converts ShiftWithEntry array to ShiftIncome array for compatibility with existing DashboardMetrics
    private static func convertShiftWithEntriesToShiftIncome(_ shiftsWithEntries: [ShiftWithEntry]) -> [ShiftIncome] {
        return shiftsWithEntries.map { shiftWithEntry in
            let shift = shiftWithEntry.expected_shift
            let entry = shiftWithEntry.entry

            let hours = entry?.actual_hours ?? shift.expected_hours
            let sales = entry?.sales ?? 0
            let tips = entry?.tips ?? 0
            let cashOut = entry?.cash_out ?? 0
            let other = entry?.other ?? 0

            // Calculate base income (hours * hourly rate)
            let baseIncome = hours * shift.hourly_rate

            // Calculate net tips (tips - cash_out)
            let netTips = tips - cashOut

            // Calculate total income (base + net tips + other)
            let totalIncome = baseIncome + netTips + other

            // Calculate tip percentage if sales > 0
            let tipPercentage = sales > 0 ? (tips / sales) * 100 : 0

            return ShiftIncome(
                income_id: entry?.id,
                shift_id: shift.id,
                user_id: shift.user_id,
                employer_id: shift.employer_id,
                employer_name: shiftWithEntry.employer_name,
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
                sales_target: shift.sales_target,
                start_time: shift.start_time,
                end_time: shift.end_time,
                actual_start_time: entry?.actual_start_time,
                actual_end_time: entry?.actual_end_time,
                shift_status: shift.status,
                shift_created_at: shift.created_at,
                earnings_created_at: entry?.created_at,
                notes: entry?.notes ?? shift.notes
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

    /// Loads all statistics for different time periods with optimized single query
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
            let calendar = Calendar.current

            // Calculate all date ranges
            let yearStart = calendar.dateInterval(of: .year, for: today)?.start ?? today
            let weekStart = DashboardMetrics.getStartOfWeek(for: today, weekStartDay: weekStartDay)
            let fourWeeksStart = calendar.date(byAdding: .weekOfYear, value: -3, to: weekStart) ?? weekStart

            // PERFORMANCE OPTIMIZATION: Use cache if valid, otherwise single query for entire year of data
            let allShifts: [ShiftIncome]
            if !forceRefresh && isCacheValid() {
                print("📊 Dashboard - Using cached data")
                allShifts = cachedData!.data
            } else {
                print("📊 Dashboard - Loading year data with single query...")
                let allShiftsWithEntries = try await SupabaseManager.shared.fetchShiftsWithEntries(from: yearStart, to: today)
                let convertedShifts = convertShiftWithEntriesToShiftIncome(allShiftsWithEntries)

                // Cache the data
                cachedData = (data: convertedShifts, cacheTime: Date())
                allShifts = convertedShifts
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)

            // Filter data for each time period from the single dataset
            let todayShifts = allShifts.filter { $0.shift_date == todayString }
            todayStats = DashboardMetrics.calculateStats(
                for: todayShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // Week data
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let weekStartString = dateFormatter.string(from: weekStart)
            let weekEndString = dateFormatter.string(from: weekEnd)
            let weekShifts = allShifts.filter {
                $0.shift_date >= weekStartString && $0.shift_date <= weekEndString
            }
            weekStats = DashboardMetrics.calculateStats(
                for: weekShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // Month data
            let monthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
            let monthEnd = calendar.dateInterval(of: .month, for: today)?.end ?? today
            let monthStartString = dateFormatter.string(from: monthStart)
            let monthEndString = dateFormatter.string(from: monthEnd)
            let monthShifts = allShifts.filter {
                $0.shift_date >= monthStartString && $0.shift_date < monthEndString
            }
            monthStats = DashboardMetrics.calculateStats(
                for: monthShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // Year data (already have all shifts from yearStart)
            yearStats = DashboardMetrics.calculateStats(
                for: allShifts,
                averageDeductionPercentage: averageDeductionPercentage,
                defaultHourlyRate: defaultHourlyRate
            )

            // 4 Weeks data
            let fourWeeksStartString = dateFormatter.string(from: fourWeeksStart)
            let fourWeeksEndString = dateFormatter.string(from: weekEnd)
            let fourWeeksShifts = allShifts.filter {
                $0.shift_date >= fourWeeksStartString && $0.shift_date <= fourWeeksEndString
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