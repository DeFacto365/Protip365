import SwiftUI
import Supabase

struct DashboardView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var todayStats = Stats()
    @State private var weekStats = Stats()
    @State private var monthStats = Stats()
    @State private var statsPreloaded = false
    @State private var selectedPeriod = 0
    @State private var isLoading = false
    @State private var showingDetail = false
    @State private var selectedDetailType = ""
    @State private var detailShifts: [ShiftIncome] = []
    @State private var editingShift: ShiftIncome? = nil
    @State private var userTargets = UserTargets()
    
    // New managers for Phase 1 & 2 features
    @StateObject private var exportManager = ExportManager()
    @StateObject private var achievementManager = AchievementManager()
    @Namespace private var namespace
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var shareText = ""
    
    // Quick Entry Form States
    @State private var entryDate = Date()
    @State private var entrySales = ""
    @State private var entryTips = ""
    @State private var entryTipOut = ""
    @State private var entryOther = ""
    @State private var entryHours = ""
    @State private var isSavingEntry = false
    
    // Edit Shift Form States
    @State private var editEntryDate = Date()
    @State private var editEntrySales = ""
    @State private var editEntryTips = ""
    @State private var editEntryTipOut = ""
    @State private var editEntryOther = ""
    @State private var editEntryHours = ""
    
    @AppStorage("language") private var language = "en"
    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 15.00
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false
    
    struct Stats {
        var hours: Double = 0
        var sales: Double = 0
        var tips: Double = 0
        var tipOut: Double = 0
        var other: Double = 0
        var income: Double = 0  // This is salary (hours × rate)
        var tipPercentage: Double = 0
        var totalRevenue: Double = 0  // salary + tips + other - tipout
        var shifts: [ShiftIncome] = []
    }
    
    struct UserTargets {
        var dailyTips: Double = 0
        var weeklyTips: Double = 0
        var monthlyTips: Double = 0
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass Background with extension effect
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .backgroundExtensionEffect()
                
                ScrollView {
                    VStack(spacing: Constants.dashboardSectionSpacing) {
                        // Period Selector (Contextual Layer)
                        periodSelectorSection
                        
                        // Stats Cards (Main Content Layer)
                        statsCardsSection
                    }
                    .padding(.horizontal, Constants.leadingContentInset)
                    .padding(.bottom, Constants.tabBarHeight + Constants.safeAreaPadding)
                }
                .refreshable {
                    await preloadAllStats()
                    await loadTargets()
                }
                
                // Loading indicator overlay (only show during initial load)
                if isLoading && !statsPreloaded {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                }
            }
            .navigationTitle("Pro Tip 365")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // App logo
                    Image("Logo2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .sheet(isPresented: $showingDetail) {
                DetailView(
                    shifts: detailShifts.sorted { $0.shift_date > $1.shift_date },
                    detailType: selectedDetailType,
                    periodText: periodText,
                    onEditShift: { shift in
                        editingShift = shift
                        showingDetail = false
                    }
                )
            }
            .task {
                await preloadAllStats()
                await loadTargets()
                
                // Check for achievements only
                achievementManager.checkForAchievements(shifts: currentStats.shifts, currentStats: currentStats, targets: userTargets)
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(exportManager: exportManager, shifts: currentStats.shifts, language: language)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [shareText])
            }
            .sheet(isPresented: $achievementManager.showAchievement) {
                AchievementView(achievement: achievementManager.currentAchievement!)
            }
        }
    }
    
    var currentStats: Stats {
        switch selectedPeriod {
        case 1: return weekStats
        case 2: return monthStats
        default: return todayStats
        }
    }
    
    var periodText: String {
        switch selectedPeriod {
        case 1: return "Week"
        case 2: return "Month"
        default: return "Today"
        }
    }
    
    func formatIncomeWithTarget() -> String {
        let income = formatCurrency(currentStats.income)
        let target: Double
        switch selectedPeriod {
        case 1: target = userTargets.weeklyIncome
        case 2: target = userTargets.monthlyIncome
        default: target = userTargets.dailyIncome
        }
        if target > 0 {
            return "\(income)/\(formatCurrency(target))"
        }
        return income
    }
    
    func formatTipsWithTarget() -> String {
        let tips = formatCurrency(currentStats.tips)
        let target: Double
        switch selectedPeriod {
        case 1: target = userTargets.weeklyTips
        case 2: target = userTargets.monthlyTips
        default: target = userTargets.dailyTips
        }
        if target > 0 {
            return "\(tips)/\(formatCurrency(target))"
        }
        return tips
    }
    
    func formatSalesWithTarget() -> String {
        let sales = formatCurrency(currentStats.sales)
        let target: Double
        switch selectedPeriod {
        case 1: target = userTargets.weeklySales
        case 2: target = userTargets.monthlySales
        default: target = userTargets.dailySales
        }
        if target > 0 {
            return "\(sales)/\(formatCurrency(target))"
        }
        return sales
    }
    
    func formatHoursWithTarget() -> String {
        let hours = String(format: "%.1f", currentStats.hours)
        let target: Double
        switch selectedPeriod {
        case 1: target = userTargets.weeklyHours
        case 2: target = userTargets.monthlyHours
        default: target = userTargets.dailyHours
        }
        if target > 0 {
            return "\(hours)/\(String(format: "%.0f", target))h"
        }
        return "\(hours)h"
    }
    
    func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    func shareCurrentStats() {
        let periodName = selectedPeriod == 0 ? "Today" : selectedPeriod == 1 ? "This Week" : "This Month"
        
        shareText = """
        📊 ProTip365 - \(periodName) Summary
        
        💰 Total Revenue: \(formatCurrency(currentStats.totalRevenue))
        💵 Tips: \(formatCurrency(currentStats.tips))
        ⏰ Hours: \(String(format: "%.1f", currentStats.hours))h
        🛒 Sales: \(formatCurrency(currentStats.sales))
        
        🎯 Tip Percentage: \(String(format: "%.1f", currentStats.tipPercentage))%
        
        #ProTip365 #Waitstaff #Tips
        """
        
        showingShareSheet = true
    }
    
    func getStartOfWeek(for date: Date, weekStartDay: Int) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date) - 1
        let daysToSubtract = (currentWeekday - weekStartDay + 7) % 7
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
    }
    
    func loadTargets() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct Profile: Decodable {
                let default_hourly_rate: Double
                let target_tip_daily: Double
                let target_tip_weekly: Double
                let target_tip_monthly: Double
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
                defaultHourlyRate = profile.default_hourly_rate
                userTargets.dailyTips = profile.target_tip_daily
                userTargets.weeklyTips = profile.target_tip_weekly
                userTargets.monthlyTips = profile.target_tip_monthly
                userTargets.dailySales = profile.target_sales_daily ?? 0
                userTargets.weeklySales = profile.target_sales_weekly ?? 0
                userTargets.monthlySales = profile.target_sales_monthly ?? 0
                userTargets.dailyHours = profile.target_hours_daily ?? 0
                userTargets.weeklyHours = profile.target_hours_weekly ?? 0
                userTargets.monthlyHours = profile.target_hours_monthly ?? 0
                
                // Calculate income targets based on hourly rate
                userTargets.dailyIncome = profile.default_hourly_rate * (profile.target_hours_daily ?? 0)
                userTargets.weeklyIncome = profile.default_hourly_rate * (profile.target_hours_weekly ?? 0)
                userTargets.monthlyIncome = profile.default_hourly_rate * (profile.target_hours_monthly ?? 0)
            }
        } catch {
            print("Error loading targets: \(error)")
        }
    }
    
    func preloadAllStats() async {
        isLoading = true
        defer { 
            isLoading = false 
            statsPreloaded = true
        }
        
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
            
            // Load Today's data
            let todayQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("shift_date", value: dateFormatter.string(from: today))
            
            let todayShifts: [ShiftIncome] = try await todayQuery.execute().value
            var todayStatsTemp = Stats()
            todayStatsTemp.shifts = todayShifts
            
            // Load Week's data
            let weekStart = getStartOfWeek(for: today, weekStartDay: weekStartDay)
            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
            let weekQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("shift_date", value: dateFormatter.string(from: weekStart))
                .lte("shift_date", value: dateFormatter.string(from: weekEnd))
            
            let weekShifts: [ShiftIncome] = try await weekQuery.execute().value
            var weekStatsTemp = Stats()
            weekStatsTemp.shifts = weekShifts
            
            // Load Month's data (current calendar month)
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
            var monthStatsTemp = Stats()
            monthStatsTemp.shifts = monthShifts
            
            // Calculate stats for each period
            func calculateStats(for shifts: [ShiftIncome]) -> Stats {
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

                // Calculate total revenue: salary + tips + other - tip out
                stats.totalRevenue = stats.income + stats.tips + stats.other - stats.tipOut

                if stats.sales > 0 {
                    stats.tipPercentage = (stats.tips / stats.sales) * 100
                }

                return stats
            }
            
            // Update all stats
            await MainActor.run {
                todayStats = calculateStats(for: todayShifts)
                weekStats = calculateStats(for: weekShifts)
                monthStats = calculateStats(for: monthShifts)
            }
            
        } catch {
            print("Error loading stats: \(error)")
        }
    }
    

    // MARK: - Liquid Glass Layout Sections

    private var periodSelectorSection: some View {
        Picker("Period", selection: $selectedPeriod) {
            Text("Today").tag(0)
            Text("Week").tag(1)
            Text("Month").tag(2)
        }
        .pickerStyle(.segmented)
        .padding()
        .liquidGlassCard()
        .padding(.horizontal)
        .onChange(of: selectedPeriod) { _, _ in
            HapticFeedback.selection()
        }
    }
    
    private var statsCardsSection: some View {
        // Stats Cards with advanced GlassEffectContainer for morphing animations
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                // First Row: Total Salary and Tips (with percentage)
                HStack(spacing: 16) {
                    GlassStatCard(
                        title: "Total Salary",
                        value: formatIncomeWithTarget(),
                        icon: "dollarsign.circle.fill",
                        color: .blue,
                        subtitle: "Base pay from hours worked"
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        selectedDetailType = "income"
                        // Filter shifts that have salary/income (base_income > 0)
                        detailShifts = currentStats.shifts.filter { shift in
                            if let baseIncome = shift.base_income {
                                return baseIncome > 0
                            }
                            return (shift.hours * (shift.hourly_rate ?? defaultHourlyRate)) > 0
                        }
                        showingDetail = true
                        HapticFeedback.light()
                    }
                    
                    // Tips card with percentage badge
                    ZStack(alignment: .topTrailing) {
                        GlassStatCard(
                            title: "Tips",
                            value: formatTipsWithTarget(),
                            icon: "banknote.fill",
                            color: .blue,
                            subtitle: "Customer tips received"
                        )
                        .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                        .onTapGesture {
                            selectedDetailType = "tips"
                            // Filter shifts that have tips > 0
                            detailShifts = currentStats.shifts.filter { $0.tips > 0 }
                            showingDetail = true
                            HapticFeedback.light()
                        }
                        
                        // Percentage badge
                        if currentStats.tipPercentage > 0 {
                            Text(String(format: "%.0f%%", currentStats.tipPercentage))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple)
                                .cornerRadius(8)
                                .offset(x: -8, y: 8)
                        }
                    }
                }
                
                // Second Row: Other and Total Revenue
                HStack(spacing: 16) {
                    GlassStatCard(
                        title: "Other",
                        value: formatCurrency(currentStats.other),
                        icon: "plus.circle.fill",
                        color: .green,
                        subtitle: "Other amount received"
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        selectedDetailType = "other"
                        // Filter shifts that have other income > 0
                        detailShifts = currentStats.shifts.filter { ($0.other ?? 0) > 0 }
                        showingDetail = true
                        HapticFeedback.light()
                    }
                    
                    GlassStatCard(
                        title: "Total Revenue",
                        value: formatCurrency(currentStats.totalRevenue),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange,
                        subtitle: "Salary + tips + other - tip out"
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        selectedDetailType = "total"
                        // Show all shifts with any income (total_income > 0)
                        detailShifts = currentStats.shifts.filter { ($0.total_income ?? 0) > 0 }
                        showingDetail = true
                        HapticFeedback.light()
                    }
                }
                
                // Third Row: Hours and Sales
                HStack(spacing: 16) {
                    GlassStatCard(
                        title: "Hours Worked",
                        value: formatHoursWithTarget(),
                        icon: "clock.fill",
                        color: .teal,
                        subtitle: "Actual vs expected hours"
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        selectedDetailType = "hours"
                        // Filter shifts that have hours > 0
                        detailShifts = currentStats.shifts.filter { $0.hours > 0 }
                        showingDetail = true
                        HapticFeedback.light()
                    }
                    
                    GlassStatCard(
                        title: "Sales",
                        value: formatSalesWithTarget(),
                        icon: "cart.fill",
                        color: .indigo,
                        subtitle: "Total sales served"
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        selectedDetailType = "sales"
                        // Filter shifts that have sales > 0
                        detailShifts = currentStats.shifts.filter { $0.sales > 0 }
                        showingDetail = true
                        HapticFeedback.light()
                    }
                }
                
                // Show hint for clickable cards
                if !currentStats.shifts.isEmpty {
                    Text("Tap a card to view details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }
    
}
