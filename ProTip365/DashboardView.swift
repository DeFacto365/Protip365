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

    struct DetailViewData: Identifiable {
        let id = UUID()
        let type: String
        let shifts: [ShiftIncome]
        let period: String
    }
    @State private var userTargets = UserTargets()
    
    // New managers for Phase 1 & 2 features
    @StateObject private var exportManager = ExportManager()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var alertManager = AlertManager()
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
                                print("🎯 Stats Cards Section Appeared")
                                print("  - Selected Period: \(selectedPeriod)")
                                print("  - Is Year View: \(selectedPeriod == 3)")
                                print("  - Stats Preloaded: \(statsPreloaded)")
                                print("  - Current Stats Income: \(currentStats.income)")
                                print("  - Current Stats Tips: \(currentStats.tips)")
                            }
                    }
                    .padding(.horizontal, Constants.leadingContentInset)
                    .padding(.bottom, Constants.tabBarHeight + Constants.safeAreaPadding)
                }
                .refreshable {
                    await preloadAllStats()
                    await loadTargets()
                }
                
                // Loading indicator overlay (show during initial load)
                if (isLoading || !statsPreloaded) && initialLoadStarted {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text(loadingStatsText)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(24)
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
            .sheet(item: $detailViewData) { data in
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
                        let startTime = Date()
                        print("📊 Dashboard - Fallback load triggered at \(startTime)")
                        await preloadAllStats()
                        await loadTargets()
                        let loadTime = Date().timeIntervalSince(startTime)
                        print("📊 Dashboard - Fallback load completed in \(String(format: "%.2f", loadTime)) seconds")
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
            .sheet(item: $editingShift) { shift in
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
        let target: Double
        switch selectedPeriod {
        case 1: target = userTargets.weeklyIncome
        case 2: target = userTargets.monthlyIncome
        case 3: target = userTargets.monthlyIncome * 12 // Yearly target = monthly * 12
        default: target = userTargets.dailyIncome
        }
        let result = target > 0 ? "\(income)/\(formatCurrency(target))" : income
        print("💰 Format Income: Period=\(selectedPeriod), Income=\(income), Target=\(target), Result=\(result)")
        return result
    }
    
    func formatTipsWithTarget() -> String {
        let tips = formatCurrency(currentStats.tips)
        let percentageStr = currentStats.sales > 0 ? " (\(String(format: "%.1f", currentStats.tipPercentage))%)" : ""

        if userTargets.tipTargetPercentage > 0 && currentStats.sales > 0 {
            let targetAmount = currentStats.sales * (userTargets.tipTargetPercentage / 100.0)
            let result = "\(tips)/\(formatCurrency(targetAmount))\(percentageStr)"
            print("💵 Format Tips: Period=\(selectedPeriod), Tips=\(tips), Sales=\(currentStats.sales), Target%=\(userTargets.tipTargetPercentage), TargetAmount=\(targetAmount), Percentage=\(currentStats.tipPercentage), Result=\(result)")
            return result
        } else {
            print("💵 Format Tips: Period=\(selectedPeriod), Tips=\(tips), Percentage=\(currentStats.tipPercentage), No target or sales")
            return tips + percentageStr
        }
    }
    
    func formatSalesWithTarget() -> String {
        return formatCurrency(currentStats.sales)
    }
    
    func formatHoursWithTarget() -> String {
        return String(format: "%.1fh", currentStats.hours)
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
    
    func preloadAllStats() async {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
                statsPreloaded = true
                print("📊 Dashboard - Stats preloaded successfully")
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

                // Calculate total revenue: salary + tips + other - tip out
                stats.totalRevenue = stats.income + stats.tips + stats.other - stats.tipOut

                if stats.sales > 0 && !stats.sales.isNaN && !stats.tips.isNaN {
                    stats.tipPercentage = (stats.tips / stats.sales) * 100
                } else {
                    stats.tipPercentage = 0
                }

                return stats
            }
            
            // Update all stats
            await MainActor.run {
                todayStats = calculateStats(for: todayShifts)
                weekStats = calculateStats(for: weekShifts)
                monthStats = calculateStats(for: monthShifts)
                yearStats = calculateStats(for: yearShifts)
                fourWeeksStats = calculateStats(for: fourWeeksShifts)

                // Debug logging
                print("📊 Dashboard - Today Stats:")
                print("  Hours: \(todayStats.hours)")
                print("  Income (Salary): \(todayStats.income)")
                print("  Tips: \(todayStats.tips)")
                print("  Other: \(todayStats.other)")
                print("  Tip Out: \(todayStats.tipOut)")
                print("  Total Revenue: \(todayStats.totalRevenue)")
                print("  Shifts count: \(todayStats.shifts.count)")

                print("📊 Dashboard - Year Stats:")
                print("  Total Revenue: \(yearStats.totalRevenue)")
                print("  Shifts count: \(yearStats.shifts.count)")

                print("📊 Dashboard - 4 Weeks Stats:")
                print("  Total Revenue: \(fourWeeksStats.totalRevenue)")
                print("  Shifts count: \(fourWeeksStats.shifts.count)")

                if let firstShift = todayStats.shifts.first {
                    print("📊 First shift details:")
                    print("  Hours: \(firstShift.hours)")
                    print("  Base Income: \(firstShift.base_income ?? 0)")
                    print("  Hourly Rate: \(firstShift.hourly_rate ?? 0)")
                    print("  Has Earnings: \(firstShift.has_earnings)")
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
                                .foregroundColor(monthViewType == 0 ? .blue : .secondary)
                            Text(calendarMonthText)
                                .foregroundColor(.primary)
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
                                .foregroundColor(monthViewType == 1 ? .blue : .secondary)
                            Text(fourWeeksPayText)
                                .foregroundColor(.primary)
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
                        print("📊 Unified Cards Rendered (Period: \(selectedPeriod))")
                    }
            }
            .padding(.horizontal)
        }
    }

    private var regularViewCards: some View {
        let _ = print("📆 Building Regular View Cards for Period: \(selectedPeriod)")
        let incomeValue = formatIncomeWithTarget()
        let tipsValue = formatTipsWithTarget()
        let _ = print("  Regular Cards - Income: \(incomeValue)")
        let _ = print("  Regular Cards - Tips: \(tipsValue)")

        return Group {
            // First Row: Total Salary and Tips (with percentage)
            HStack(spacing: 16) {
                    GlassStatCard(
                        title: totalSalaryText,
                        value: incomeValue,
                        icon: "dollarsign.bank.building",
                        color: .blue,
                        subtitle: basePayFromHoursText
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
                    
                    // Tips card with percentage badge
                    ZStack(alignment: .topTrailing) {
                        GlassStatCard(
                            title: tipsText,
                            value: tipsValue,
                            icon: "banknote.fill",
                            color: .blue,
                            subtitle: customerTipsReceivedText
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
                
                // Third Row: Hours and Sales
                HStack(spacing: 16) {
                    GlassStatCard(
                        title: hoursWorkedText,
                        value: formatHoursWithTarget(),
                        icon: "clock.badge",
                        color: .teal,
                        subtitle: actualVsExpectedHoursText
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
                    
                    GlassStatCard(
                        title: salesText,
                        value: formatSalesWithTarget(),
                        icon: "dollarsign.circle",
                        color: .indigo,
                        subtitle: totalSalesServedText
                    )
                    .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
                    .onTapGesture {
                        let filtered = currentStats.shifts.filter { $0.sales > 0 }
                        detailViewData = DetailViewData(
                            type: "sales",
                            shifts: filtered,
                            period: periodText
                        )
                        HapticFeedback.light()
                    }
                }
                
                // Show hint for clickable cards
                if !currentStats.shifts.isEmpty {
                    Text(tapCardForDetailsText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }

    private var unifiedCompactCards: some View {
        VStack(spacing: 12) {
            // Income Cards
            CompactGlassStatCard(
                title: totalSalaryText,
                value: formatCurrency(currentStats.income),
                icon: "dollarsign.circle.fill",
                color: .blue,
                subtitle: nil
            )

            CompactGlassStatCard(
                title: tipsText,
                value: formatCurrency(currentStats.tips),
                icon: "banknote.fill",
                color: .blue,
                subtitle: nil
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
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatCurrency(currentStats.income + currentStats.tips + currentStats.other))
                    .font(.body)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Tip Out (negative)
            if currentStats.tipOut > 0 {
                HStack {
                    Label(tipOutText, systemImage: "minus.circle")
                        .font(.body)
                        .foregroundColor(.red)
                    Spacer()
                    Text("-\(formatCurrency(currentStats.tipOut))")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
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
                    .foregroundColor(.primary)
                Spacer()
                Text(formatCurrency(currentStats.totalRevenue))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Performance Metrics
            CompactGlassStatCard(
                title: hoursWorkedText,
                value: String(format: "%.1f hours", currentStats.hours),
                icon: "clock.badge",
                color: .blue,
                subtitle: nil
            )

            CompactGlassStatCard(
                title: salesText,
                value: formatCurrency(currentStats.sales),
                icon: "dollarsign.circle",
                color: .blue,
                subtitle: nil
            )

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
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
        }
    }

    private var yearViewCards: some View {
        let _ = print("📅 Building Year View Cards")
        let incomeValue = formatIncomeWithTarget()
        let tipsValue = formatTipsWithTarget()
        let _ = print("  Income Value: \(incomeValue)")
        let _ = print("  Tips Value: \(tipsValue)")

        return VStack(spacing: 12) {
            // Total Salary
            CompactGlassStatCard(
                title: totalSalaryText,
                value: incomeValue,
                icon: "dollarsign.circle.fill",
                color: .blue,
                subtitle: "Base pay from hours worked"
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

            // Tips
            CompactGlassStatCard(
                title: tipsText,
                value: tipsValue,
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

            // Hours Worked
            CompactGlassStatCard(
                title: hoursWorkedText,
                value: formatHoursWithTarget(),
                icon: "clock.badge",
                color: .purple,
                subtitle: totalHoursCompletedText
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

            // Sales
            CompactGlassStatCard(
                title: salesText,
                value: formatSalesWithTarget(),
                icon: "dollarsign.circle",
                color: .indigo,
                subtitle: totalSalesServedText
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

            // Show hint for clickable cards
            if !currentStats.shifts.isEmpty {
                Text("Tap a card to view details")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

    private var totalSalaryText: String {
        switch language {
        case "fr": return "Salaire total"
        case "es": return "Salario total"
        default: return "Total Salary"
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
