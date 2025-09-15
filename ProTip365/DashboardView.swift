import SwiftUI
import Supabase

struct DashboardView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var todayStats = Stats()
    @State private var weekStats = Stats()
    @State private var monthStats = Stats()
    @State private var yearStats = Stats()
    @State private var fourWeeksStats = Stats()
    @State private var statsPreloaded = false
    @State private var initialLoadStarted = false
    @State private var selectedPeriod = 0
    @State private var monthViewType = 0 // 0 = Calendar Month, 1 = 4 Weeks Pay
    @State private var isLoading = false
    @State private var showingDetail = false
    @State private var detailViewData: DetailViewData? = nil
    @State private var editingShift: ShiftIncome? = nil
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    struct DetailViewData: Identifiable {
        let id = UUID()
        let type: String
        let shifts: [ShiftIncome]
        let period: String
    }
    @State private var userTargets = UserTargets()
    @AppStorage("averageDeductionPercentage") private var averageDeductionPercentage: Double = 30.0

    // New managers for Phase 1 & 2 features
    @StateObject private var exportManager = ExportManager()
    @StateObject private var achievementManager = AchievementManager()
    @EnvironmentObject var alertManager: AlertManager
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
                            .onAppear {
                                #if DEBUG
                                print("🎯 Stats Cards Section Appeared")
                                #endif
                            }
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? Spacing.xxxxl : Spacing.lg)  // Reduced from 26 to 12 for iPhone
                    .padding(.bottom, horizontalSizeClass == .regular ? Spacing.xxl : (Constants.tabBarHeight + Spacing.xl))  // Reduced bottom padding
                    .frame(maxWidth: .infinity)
                }
                .refreshable {
                    // Force fresh data load on pull-to-refresh
                    await MainActor.run {
                        // Reset preloaded flag to ensure fresh fetch
                        statsPreloaded = false
                    }

                    // Fetch fresh data from Supabase
                    await preloadAllStats(forceRefresh: true)
                    await loadTargets()

                    // Check for achievements after refresh
                    await MainActor.run {
                        achievementManager.checkForAchievements(shifts: currentStats.shifts, currentStats: currentStats, targets: userTargets)
                        alertManager.checkForMissingShifts(shifts: currentStats.shifts, targets: userTargets)
                        alertManager.checkForTargetAchievements(currentStats: currentStats, targets: userTargets, period: selectedPeriod)
                    }
                }
                
                // Loading indicator overlay (show during initial load)
                if (isLoading || !statsPreloaded) && initialLoadStarted {
                    ZStack {
                        Color.primary.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text(loadingStatsText)
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(Spacing.xxxl)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .navigationTitle(proTip365Text)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NotificationBell(alertManager: alertManager)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    // App logo
                    Image("Logo2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .fullScreenCover(item: horizontalSizeClass == .regular ? $detailViewData : .constant(nil)) { data in
                DetailView(
                    shifts: data.shifts.sorted { $0.shift_date > $1.shift_date },
                    detailType: data.type,
                    periodText: data.period,
                    onEditShift: { shift in
                        editingShift = shift
                        detailViewData = nil
                    }
                )
            }
            .sheet(item: horizontalSizeClass != .regular ? $detailViewData : .constant(nil)) { data in
                DetailView(
                    shifts: data.shifts.sorted { $0.shift_date > $1.shift_date },
                    detailType: data.type,
                    periodText: data.period,
                    onEditShift: { shift in
                        editingShift = shift
                        detailViewData = nil
                    }
                )
            }
            .task {
                // Use task modifier for initial load - runs once when view appears
                if !initialLoadStarted {
                    initialLoadStarted = true
                    let startTime = Date()
                    print("📊 Dashboard - Initial load starting at \(startTime)")
                    await preloadAllStats()
                    await loadTargets()
                    let loadTime = Date().timeIntervalSince(startTime)
                    print("📊 Dashboard - Load completed in \(String(format: "%.2f", loadTime)) seconds")

                    // Check for achievements after initial load
                    achievementManager.checkForAchievements(shifts: currentStats.shifts, currentStats: currentStats, targets: userTargets)

                    // Check for alerts after initial load
                    alertManager.checkForMissingShifts(shifts: currentStats.shifts, targets: userTargets)
                    alertManager.checkForTargetAchievements(currentStats: currentStats, targets: userTargets, period: selectedPeriod)
                }
            }
            .onAppear {
                // Double-check on appear - only if task hasn't started
                if !initialLoadStarted && !statsPreloaded {
                    initialLoadStarted = true
                    Task {
                        await preloadAllStats()
                        await loadTargets()
                    }
                } else if statsPreloaded {
                    // If we already have data but view is appearing again,
                    // do a background refresh to catch any changes from other devices
                    Task {
                        await preloadAllStats(forceRefresh: true)
                    }
                }
            }
            .onChange(of: selectedPeriod) { _, _ in
                // Update view when period changes
                Task {
                    // Small delay to ensure UI updates
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
            .onChange(of: monthViewType) { _, _ in
                // Update view when month view type changes
                Task {
                    // Small delay to ensure UI updates
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(exportManager: exportManager, shifts: currentStats.shifts, language: language)
            }
            .sheet(isPresented: $showingShareSheet) {
                TextShareSheet(text: shareText)
            }
            .sheet(isPresented: $achievementManager.showAchievement) {
                AchievementView(achievement: achievementManager.currentAchievement!)
            }
            .sheet(item: $editingShift, onDismiss: {
                // Reload data after editing
                Task {
                    await preloadAllStats()
                }
            }) { shift in
                AddEntryView(editingShift: shift)
                    .environmentObject(SupabaseManager.shared)
            }
        }
    }
    
    var currentStats: Stats {
        switch selectedPeriod {
        case 1: return weekStats
        case 2:
            // Month tab - check if Calendar Month or 4 Weeks
            return monthViewType == 0 ? monthStats : fourWeeksStats
        case 3: return yearStats
        default: return todayStats
        }
    }

    var periodText: String {
        switch selectedPeriod {
        case 1: return weekText
        case 2:
            return monthViewType == 0 ? monthText : fourWeeksText
        case 3: return yearText
        default:
            // Inline the translation to avoid potential circular reference
            switch language {
            case "fr": return "Aujourd'hui"
            case "es": return "Hoy"
            default: return "Today"
            }
        }
    }
    
    func formatIncomeWithTarget() -> String {
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
    
    func formatTipsWithTarget() -> String {
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
    
    func formatSalesWithTarget() -> String {
        return formatCurrency(currentStats.sales)
    }
    
    func formatHoursWithTarget() -> String {
        let hoursStr = String(format: "%.1fh", currentStats.hours)
        let target = getHoursTarget()
        if target > 0 {
            let percentage = (currentStats.hours / target) * 100
            return "\(hoursStr) (\(Int(percentage))%)"
        }
        return hoursStr
    }

    private func getHoursTarget() -> Double {
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
    
    func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getSalesTarget() -> Double {
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

    private func getProgressColor(percentage: Double) -> Color {
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
                defaultHourlyRate = profile.default_hourly_rate
                averageDeductionPercentage = profile.average_deduction_percentage ?? 30.0
                userTargets.tipTargetPercentage = profile.tip_target_percentage ?? 0
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
    
    func preloadAllStats(forceRefresh: Bool = false) async {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
                statsPreloaded = true
                if forceRefresh {
                    HapticFeedback.success()
                }
            }
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
            // Add a small delay on force refresh to ensure data is synced
            if forceRefresh {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
            }

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

            // Load Year's data (since January 1st)
            let yearStart = calendar.dateInterval(of: .year, for: today)?.start ?? today
            let yearQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("shift_date", value: dateFormatter.string(from: yearStart))
                .lte("shift_date", value: dateFormatter.string(from: today))

            let yearShifts: [ShiftIncome] = try await yearQuery.execute().value
            var yearStatsTemp = Stats()
            yearStatsTemp.shifts = yearShifts

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
            var fourWeeksStatsTemp = Stats()
            fourWeeksStatsTemp.shifts = fourWeeksShifts

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
            
            // Update all stats
            await MainActor.run {
                // Clear existing data if force refresh
                if forceRefresh {
                    todayStats = Stats()
                    weekStats = Stats()
                    monthStats = Stats()
                    yearStats = Stats()
                    fourWeeksStats = Stats()
                }

                // Calculate and update with fresh data
                todayStats = calculateStats(for: todayShifts)
                weekStats = calculateStats(for: weekShifts)
                monthStats = calculateStats(for: monthShifts)
                yearStats = calculateStats(for: yearShifts)
                fourWeeksStats = calculateStats(for: fourWeeksShifts)

                // Log refresh status
                if forceRefresh {
                    #if DEBUG
                    print("📊 Dashboard - Data refreshed successfully")
                    print("  Today: \(todayStats.shifts.count) shifts")
                    print("  Week: \(weekStats.shifts.count) shifts")
                    print("  Month: \(monthStats.shifts.count) shifts")
                    #endif
                }
            }
            
        } catch {
            print("Error loading stats: \(error)")
        }
    }
    

    // MARK: - Liquid Glass Layout Sections

    private var periodSelectorSection: some View {
        VStack(spacing: 12) {
            Picker("Period", selection: $selectedPeriod) {
                Text("Today").tag(0)
                Text("Week").tag(1)
                Text("Month").tag(2)
                Text("Year").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            .liquidGlassCard()
            .padding(.horizontal)
            .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
            .onChange(of: selectedPeriod) { _, _ in
                HapticFeedback.selection()
            }

            // Show month type toggle only when Month is selected
            if selectedPeriod == 2 {
                HStack(spacing: 16) {
                    Button(action: {
                        monthViewType = 0
                        HapticFeedback.selection()
                    }) {
                        HStack {
                            Image(systemName: monthViewType == 0 ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(monthViewType == 0 ? Color.blue : Color.secondary)
                            Text(calendarMonthText)
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    Button(action: {
                        monthViewType = 1
                        HapticFeedback.selection()
                    }) {
                        HStack {
                            Image(systemName: monthViewType == 1 ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(monthViewType == 1 ? Color.blue : Color.secondary)
                            Text(fourWeeksPayText)
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .liquidGlassCard()
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var statsCardsSection: some View {
        // Stats Cards with advanced GlassEffectContainer for morphing animations
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                // Use compact horizontal cards for all views
                unifiedCompactCards
                    .onAppear {
                        #if DEBUG
                        print("📊 Unified Cards Rendered (Period: \(selectedPeriod))")
                        #endif
                    }
            }
            .padding(.horizontal)
        }
    }

    private var regularViewCards: some View {
        Group {
            // Sales Card at the top (full width)
            VStack(spacing: 4) {
                ZStack(alignment: .bottom) {
                    GlassStatCard(
                        title: salesText,
                        value: formatCurrency(currentStats.sales),
                        icon: "cart.fill",
                        color: .purple,
                        subtitle: getSalesTarget() > 0
                            ? "\(Int((currentStats.sales / getSalesTarget()) * 100))% of target"
                            : nil
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
                    .onTapGesture {
                        let filtered = currentStats.shifts.filter { $0.sales > 0 }
                        detailViewData = DetailViewData(
                            type: "sales",
                            shifts: filtered,
                            period: periodText
                        )
                        HapticFeedback.light()
                    }

                    // Add progress indicator for all tabs with targets
                    if getSalesTarget() > 0 {
                        VStack(spacing: 4) {
                            let target = getSalesTarget()
                            let percentage = (currentStats.sales / target) * 100

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.tint.opacity(0.2))
                                        .frame(height: 8)

                                    // Progress
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(getProgressColor(percentage: percentage))
                                        .frame(width: min(geometry.size.width * (percentage / 100), geometry.size.width), height: 8)
                                        .animation(.easeInOut(duration: 0.3), value: currentStats.sales)
                                }
                            }
                            .frame(height: 8)

                            // Target text with percentage
                            HStack {
                                Text("\(Int(percentage))% of target")
                                    .font(.caption2)
                                    .foregroundStyle(getProgressColor(percentage: percentage))
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Target: \(formatCurrency(target))")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.lg)
                    }
                }

                // Gray separator line like tip-out
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
                    .padding(.horizontal, Spacing.xl)
            }

            // Adaptive layout for iPad vs iPhone
            if horizontalSizeClass == .regular {
                // iPad: 3-column layout
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    // Row 1: Salary, Hours, Tips
                    GlassStatCard(
                        title: expectedNetSalaryText,
                        value: formatCurrency(currentStats.netIncome(deductionPercentage: averageDeductionPercentage)),
                        icon: "dollarsign.bank.building",
                        color: .blue,
                        subtitle: "\(totalGrossSalaryText): \(formatIncomeWithTarget())"
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        let filteredShifts = currentStats.shifts.filter { shift in
                            let hasIncome: Bool
                            if let baseIncome = shift.base_income {
                                hasIncome = baseIncome > 0
                            } else {
                                hasIncome = (shift.hours * (shift.hourly_rate ?? defaultHourlyRate)) > 0
                            }
                            return hasIncome
                        }
                        detailViewData = DetailViewData(
                            type: "income",
                            shifts: filteredShifts,
                            period: periodText
                        )
                        HapticFeedback.light()
                    }

                    GlassStatCard(
                        title: hoursWorkedText,
                        value: formatHoursWithTarget(),
                        icon: "clock.badge",
                        color: .teal,
                        subtitle: getHoursTarget() > 0
                            ? "\(Int((currentStats.hours / getHoursTarget()) * 100))% of target"
                            : actualVsExpectedHoursText
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        let filtered = currentStats.shifts.filter { $0.hours > 0 }
                        detailViewData = DetailViewData(
                            type: "hours",
                            shifts: filtered,
                            period: periodText
                        )
                        HapticFeedback.light()
                    }

                    // Tips card with percentage badge
                    ZStack(alignment: .topTrailing) {
                        GlassStatCard(
                            title: tipsText,
                            value: formatTipsWithTarget(),
                            icon: "banknote.fill",
                            color: .green,
                            subtitle: currentStats.tipPercentage > 0 ? String(format: "%.1f%% of sales", currentStats.tipPercentage) : customerTipsReceivedText
                        )
                        .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                        .onTapGesture {
                            let filtered = currentStats.shifts.filter { $0.tips > 0 }
                            detailViewData = DetailViewData(
                                type: "tips",
                                shifts: filtered,
                                period: periodText
                            )
                            HapticFeedback.light()
                        }

                        // Percentage badge
                        if currentStats.tipPercentage > 0 {
                            Text(String(format: "%.0f%%", currentStats.tipPercentage))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.sm + 2)
                                .padding(.vertical, Spacing.xs)
                                .background(.tint)
                                .cornerRadius(8)
                                .offset(x: -8, y: 8)
                        }
                    }

                    // Row 2: Other and Total Revenue
                    GlassStatCard(
                        title: otherText,
                        value: formatCurrency(currentStats.other),
                        icon: "square.and.pencil",
                        color: .blue,
                        subtitle: otherAmountReceivedText
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        let filtered = currentStats.shifts.filter { ($0.other ?? 0) > 0 }
                        detailViewData = DetailViewData(
                            type: "other",
                            shifts: filtered,
                            period: periodText
                        )
                        HapticFeedback.light()
                    }

                    GlassStatCard(
                        title: totalRevenueText,
                        value: formatCurrency(currentStats.totalRevenue),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue,
                        subtitle: salaryPlusTipsFormulaText
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        let filtered = currentStats.shifts.filter { ($0.total_income ?? 0) > 0 }
                        detailViewData = DetailViewData(
                            type: "total",
                            shifts: filtered,
                            period: periodText
                        )
                        HapticFeedback.light()
                    }
                }
            } else {
                // iPhone: 2-column layout
                HStack(spacing: 16) {
                    GlassStatCard(
                        title: expectedNetSalaryText,
                        value: formatCurrency(currentStats.netIncome(deductionPercentage: averageDeductionPercentage)),
                        icon: "dollarsign.bank.building",
                        color: .blue,
                        subtitle: "\(totalGrossSalaryText): \(formatIncomeWithTarget())"
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        print("💰 Salary Card Tapped")
                        print("  Current period: \(selectedPeriod)")
                        print("  Total shifts: \(currentStats.shifts.count)")
                        print("  Current income: \(currentStats.income)")

                        // Filter shifts that have salary/income (base_income > 0)
                        let filteredShifts = currentStats.shifts.filter { shift in
                            let hasIncome: Bool
                            if let baseIncome = shift.base_income {
                                hasIncome = baseIncome > 0
                            } else {
                                hasIncome = (shift.hours * (shift.hourly_rate ?? defaultHourlyRate)) > 0
                            }
                            print("  Shift: \(shift.shift_date), Base Income: \(shift.base_income ?? 0), Hours: \(shift.hours), Has Income: \(hasIncome)")
                            return hasIncome
                        }
                        print("  Filtered shifts: \(filteredShifts.count)")

                        // Set both values with a small delay to ensure state is updated
                        // Create detail data and show sheet
                        detailViewData = DetailViewData(
                            type: "income",
                            shifts: filteredShifts,
                            period: periodText
                        )
                        print("  DetailViewData created with \(filteredShifts.count) shifts")
                        HapticFeedback.light()
                    }

                    GlassStatCard(
                        title: hoursWorkedText,
                        value: formatHoursWithTarget(),
                        icon: "clock.badge",
                        color: .teal,
                        subtitle: getHoursTarget() > 0
                            ? "\(Int((currentStats.hours / getHoursTarget()) * 100))% of target"
                            : actualVsExpectedHoursText
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        let filtered = currentStats.shifts.filter { $0.hours > 0 }
                        detailViewData = DetailViewData(
                            type: "hours",
                            shifts: filtered,
                            period: periodText
                        )
                        HapticFeedback.light()
                    }
                }

                // Second Row: Tips (with percentage badge and sales info)
                HStack(spacing: 16) {
                    // Tips card with percentage badge
                    ZStack(alignment: .topTrailing) {
                        GlassStatCard(
                            title: tipsText,
                            value: formatTipsWithTarget(),
                            icon: "banknote.fill",
                            color: .green,
                            subtitle: currentStats.tipPercentage > 0 ? String(format: "%.1f%% of sales", currentStats.tipPercentage) : customerTipsReceivedText
                        )
                        .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                        .onTapGesture {
                            let filtered = currentStats.shifts.filter { $0.tips > 0 }
                            detailViewData = DetailViewData(
                                type: "tips",
                                shifts: filtered,
                                period: periodText
                            )
                            HapticFeedback.light()
                        }

                        // Percentage badge
                        if currentStats.tipPercentage > 0 {
                            Text(String(format: "%.0f%%", currentStats.tipPercentage))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.sm + 2)
                                .padding(.vertical, Spacing.xs)
                                .background(.tint)
                                .cornerRadius(8)
                                .offset(x: -8, y: 8)
                        }
                    }

                    GlassStatCard(
                        title: otherText,
                        value: formatCurrency(currentStats.other),
                        icon: "square.and.pencil",
                        color: .blue,
                        subtitle: otherAmountReceivedText
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        let filtered = currentStats.shifts.filter { ($0.other ?? 0) > 0 }
                        detailViewData = DetailViewData(
                            type: "other",
                            shifts: filtered,
                            period: periodText
                        )
                        HapticFeedback.light()
                    }
                }

                // Third Row: Total Revenue (alone, full width)
                GlassStatCard(
                    title: totalRevenueText,
                    value: formatCurrency(currentStats.totalRevenue),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    subtitle: salaryPlusTipsFormulaText
                )
                .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                .onTapGesture {
                    let filtered = currentStats.shifts.filter { ($0.total_income ?? 0) > 0 }
                    detailViewData = DetailViewData(
                        type: "total",
                        shifts: filtered,
                        period: periodText
                    )
                    HapticFeedback.light()
                }
            } // End of iPhone layout else block
                
                // Show hint for clickable cards
                if !currentStats.shifts.isEmpty {
                    Text(tapCardForDetailsText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }

    private var unifiedCompactCards: some View {
        VStack(spacing: 12) {
            // Sales at the top
            VStack(spacing: 4) {
                CompactGlassStatCard(
                    title: salesText,
                    value: formatCurrency(currentStats.sales),
                    icon: "cart.fill",
                    color: .purple,
                    subtitle: getSalesTarget() > 0
                        ? "\(Int((currentStats.sales / getSalesTarget()) * 100))% of target"
                        : nil
                )

                // Gray separator line
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, Spacing.xl)
            }

            // Income Cards
            CompactGlassStatCard(
                title: expectedNetSalaryText,
                value: formatCurrency(currentStats.netIncome(deductionPercentage: averageDeductionPercentage)),
                icon: "dollarsign.circle.fill",
                color: .blue,
                subtitle: "\(totalGrossSalaryText): \(formatCurrency(currentStats.income))"
            )

            // Hours below salary
            CompactGlassStatCard(
                title: hoursWorkedText,
                value: String(format: "%.1f hours", currentStats.hours),
                icon: "clock.badge",
                color: .blue,
                subtitle: getHoursTarget() > 0
                    ? "\(Int((currentStats.hours / getHoursTarget()) * 100))% of target"
                    : nil
            )

            CompactGlassStatCard(
                title: tipsText,
                value: formatCurrency(currentStats.tips),
                icon: "banknote.fill",
                color: .green,
                subtitle: currentStats.tipPercentage > 0
                    ? String(format: "%.1f%% of sales • Target: %.0f%%", currentStats.tipPercentage, userTargets.tipTargetPercentage)
                    : nil
            )

            if currentStats.other > 0 {
                CompactGlassStatCard(
                    title: otherText,
                    value: formatCurrency(currentStats.other),
                    icon: "square.and.pencil",
                    color: .blue,
                    subtitle: nil
                )
            }

            // Subtotal
            HStack {
                Text(subtotalText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(currentStats.income + currentStats.tips + currentStats.other))
                    .font(.body)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)

            // Tip Out (negative)
            if currentStats.tipOut > 0 {
                HStack {
                    Label(tipOutText, systemImage: "minus.circle")
                        .font(.body)
                        .foregroundStyle(.red)
                    Spacer()
                    Text("-\(formatCurrency(currentStats.tipOut))")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            // Total Income
            HStack {
                Text(totalIncomeText)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Text(formatCurrency(currentStats.totalRevenue))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)

            // Performance Metrics section removed - sales already shown in tips subtitle

            // Show Details Button
            if !currentStats.shifts.isEmpty {
                Button(action: {
                    detailViewData = DetailViewData(
                        type: "total",
                        shifts: currentStats.shifts,
                        period: periodText
                    )
                    HapticFeedback.light()
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .font(.body)
                        Text(showDetailsText)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xxxl)
                    .padding(.vertical, Spacing.lg)
                    .background(.tint)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
        }
    }

    private var yearViewCards: some View {
        VStack(spacing: 12) {
            // Sales at the top
            VStack(spacing: 4) {
                CompactGlassStatCard(
                    title: salesText,
                    value: formatCurrency(currentStats.sales),
                    icon: "cart.fill",
                    color: .purple,
                    subtitle: getSalesTarget() > 0
                        ? "\(Int((currentStats.sales / getSalesTarget()) * 100))% of target"
                        : nil
                )
                .onTapGesture {
                    let filtered = currentStats.shifts.filter { $0.sales > 0 }
                    detailViewData = DetailViewData(
                        type: "sales",
                        shifts: filtered,
                        period: periodText
                    )
                    HapticFeedback.light()
                }

                // Gray separator line
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, Spacing.xl)
            }

            // Total Salary
            CompactGlassStatCard(
                title: expectedNetSalaryText,
                value: formatCurrency(currentStats.netIncome(deductionPercentage: averageDeductionPercentage)),
                icon: "dollarsign.circle.fill",
                color: .blue,
                subtitle: "\(totalGrossSalaryText): \(formatIncomeWithTarget())"
            )
            .onTapGesture {
                print("💰 Year Salary Card Tapped")
                print("  Total shifts: \(currentStats.shifts.count)")
                print("  Current income: \(currentStats.income)")

                let filtered = currentStats.shifts.filter { shift in
                    let hasIncome: Bool
                    if let baseIncome = shift.base_income {
                        hasIncome = baseIncome > 0
                    } else {
                        hasIncome = (shift.hours * (shift.hourly_rate ?? defaultHourlyRate)) > 0
                    }
                    print("  Shift: \(shift.shift_date), Base Income: \(shift.base_income ?? 0), Has Income: \(hasIncome)")
                    return hasIncome
                }
                print("  Filtered shifts: \(filtered.count)")
                detailViewData = DetailViewData(
                    type: "income",
                    shifts: filtered,
                    period: periodText
                )
                HapticFeedback.light()
            }

            // Hours Worked (moved below salary)
            CompactGlassStatCard(
                title: hoursWorkedText,
                value: formatHoursWithTarget(),
                icon: "clock.badge",
                color: .purple,
                subtitle: getHoursTarget() > 0
                    ? "\(Int((currentStats.hours / getHoursTarget()) * 100))% of target"
                    : totalHoursCompletedText
            )
            .onTapGesture {
                let filtered = currentStats.shifts.filter { $0.hours > 0 }
                detailViewData = DetailViewData(
                    type: "hours",
                    shifts: filtered,
                    period: periodText
                )
                HapticFeedback.light()
            }

            // Tips with sales info in subtitle
            CompactGlassStatCard(
                title: tipsText,
                value: formatTipsWithTarget(),
                icon: "banknote.fill",
                color: .blue,
                subtitle: currentStats.tipPercentage > 0 ? String(format: "%.0f%% of sales", currentStats.tipPercentage) : customerTipsReceivedText
            )
            .onTapGesture {
                let filtered = currentStats.shifts.filter { $0.tips > 0 }
                detailViewData = DetailViewData(
                    type: "tips",
                    shifts: filtered,
                    period: periodText
                )
                HapticFeedback.light()
            }

            // Other
            CompactGlassStatCard(
                title: "Other",
                value: formatCurrency(currentStats.other),
                icon: "plus.circle.fill",
                color: .blue,
                subtitle: otherAmountReceivedText
            )
            .onTapGesture {
                let filtered = currentStats.shifts.filter { ($0.other ?? 0) > 0 }
                detailViewData = DetailViewData(
                    type: "other",
                    shifts: filtered,
                    period: periodText
                )
                HapticFeedback.light()
            }

            // Total Revenue
            CompactGlassStatCard(
                title: totalRevenueText,
                value: formatCurrency(currentStats.totalRevenue),
                icon: "chart.line.uptrend.xyaxis",
                color: .orange,
                subtitle: "Salary + tips + other - tip out"
            )
            .onTapGesture {
                let filtered = currentStats.shifts.filter { ($0.total_income ?? 0) > 0 }
                detailViewData = DetailViewData(
                    type: "total",
                    shifts: filtered,
                    period: periodText
                )
                HapticFeedback.light()
            }

            // Show hint for clickable cards
            if !currentStats.shifts.isEmpty {
                Text("Tap a card to view details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Translations

    private var loadingStatsText: String {
        switch language {
        case "fr": return "Chargement des statistiques..."
        case "es": return "Cargando estadísticas..."
        default: return "Loading stats..."
        }
    }

    private var proTip365Text: String {
        return "ProTip365" // App name should not be translated
    }

    private var weekText: String {
        switch language {
        case "fr": return "Semaine"
        case "es": return "Semana"
        default: return "Week"
        }
    }

    private var monthText: String {
        switch language {
        case "fr": return "Mois"
        case "es": return "Mes"
        default: return "Month"
        }
    }

    private var fourWeeksText: String {
        switch language {
        case "fr": return "4 Semaines"
        case "es": return "4 Semanas"
        default: return "4 Weeks"
        }
    }

    private var yearText: String {
        switch language {
        case "fr": return "Année"
        case "es": return "Año"
        default: return "Year"
        }
    }

    private var todayText: String {
        switch language {
        case "fr": return "Aujourd'hui"
        case "es": return "Hoy"
        default: return "Today"
        }
    }

    private var calendarMonthText: String {
        switch language {
        case "fr": return "Mois calendrier"
        case "es": return "Mes calendario"
        default: return "Calendar Month"
        }
    }

    private var fourWeeksPayText: String {
        switch language {
        case "fr": return "Paie 4 semaines"
        case "es": return "Pago 4 semanas"
        default: return "4 Weeks Pay"
        }
    }

    private var totalGrossSalaryText: String {
        switch language {
        case "fr": return "Salaire brut prévu"
        case "es": return "Salario bruto esperado"
        default: return "Expected Gross Salary"
        }
    }

    private var expectedNetSalaryText: String {
        switch language {
        case "fr": return "Salaire net"
        case "es": return "Salario neto"
        default: return "Net Salary"
        }
    }

    private var basePayFromHoursText: String {
        switch language {
        case "fr": return "Salaire de base des heures travaillées"
        case "es": return "Pago base de horas trabajadas"
        default: return "Base pay from hours worked"
        }
    }

    private var tipsText: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }

    private var customerTipsReceivedText: String {
        switch language {
        case "fr": return "Pourboires clients reçus"
        case "es": return "Propinas de clientes recibidas"
        default: return "Customer tips received"
        }
    }

    private var otherText: String {
        switch language {
        case "fr": return "Autre"
        case "es": return "Otro"
        default: return "Other"
        }
    }

    private var otherAmountReceivedText: String {
        switch language {
        case "fr": return "Autre montant reçu"
        case "es": return "Otra cantidad recibida"
        default: return "Other amount received"
        }
    }

    private var totalRevenueText: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingresos totales"
        default: return "Total Revenue"
        }
    }

    private var salaryPlusTipsFormulaText: String {
        switch language {
        case "fr": return "Salaire + pourboires + autre - partage"
        case "es": return "Salario + propinas + otro - reparto"
        default: return "Salary + tips + other - tip out"
        }
    }

    private var hoursWorkedText: String {
        switch language {
        case "fr": return "Heures travaillées"
        case "es": return "Horas trabajadas"
        default: return "Hours Worked"
        }
    }

    private var actualVsExpectedHoursText: String {
        switch language {
        case "fr": return "Heures réelles vs prévues"
        case "es": return "Horas reales vs esperadas"
        default: return "Actual vs expected hours"
        }
    }

    private var totalHoursCompletedText: String {
        switch language {
        case "fr": return "Total des heures complétées"
        case "es": return "Total de horas completadas"
        default: return "Total hours completed"
        }
    }

    private var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }

    private var totalSalesServedText: String {
        switch language {
        case "fr": return "Total des ventes servies"
        case "es": return "Total de ventas servidas"
        default: return "Total sales served"
        }
    }

    private var tapCardForDetailsText: String {
        switch language {
        case "fr": return "Appuyez sur une carte pour voir les détails"
        case "es": return "Toca una tarjeta para ver detalles"
        default: return "Tap a card to view details"
        }
    }

    private var subtotalText: String {
        switch language {
        case "fr": return "SOUS-TOTAL"
        case "es": return "SUBTOTAL"
        default: return "SUBTOTAL"
        }
    }

    private var totalIncomeText: String {
        switch language {
        case "fr": return "REVENU TOTAL"
        case "es": return "INGRESOS TOTALES"
        default: return "TOTAL INCOME"
        }
    }

    private var showDetailsText: String {
        switch language {
        case "fr": return "Afficher les détails"
        case "es": return "Mostrar detalles"
        default: return "Show Details"
        }
    }

    private var tipOutText: String {
        switch language {
        case "fr": return "Partage"
        case "es": return "Reparto"
        default: return "Tip Out"
        }
    }

}

struct TextShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
