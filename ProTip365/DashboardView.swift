import SwiftUI
import Supabase

struct DashboardView: View {
    @State private var todayStats = Stats()
    @State private var weekStats = Stats()
    @State private var monthStats = Stats()
    @State private var statsPreloaded = false
    @State private var selectedPeriod = 0
    @State private var isLoading = false
    @State private var showingDetail = false
    @State private var selectedDetailType = ""
    @State private var detailShifts: [ShiftIncome] = []
    @State private var showingQuickEntry = false
    @State private var showingQuickShift = false
    @State private var editingShift: ShiftIncome? = nil
    @State private var userTargets = UserTargets()
    
    // New managers for Phase 1 & 2 features
    @StateObject private var exportManager = ExportManager()
    @StateObject private var achievementManager = AchievementManager()
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
                // Enhanced iOS 26 Background with Liquid Glass
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quick Add Buttons
                        HStack(spacing: 12) {
                            // Add Entry Button (Past/Today)
                            Button(action: {
                                showingQuickEntry = true
                                HapticFeedback.light()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text(quickAddText)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            
                            // Add Shift Button (Future)
                            Button(action: {
                                showingQuickShift = true
                                HapticFeedback.light()
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.title2)
                                    Text(quickAddShiftText)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "0288FF"), Color(hex: "0288FF").opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color(hex: "0288FF").opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Period Selector with glass effect
                        Picker("Period", selection: $selectedPeriod) {
                            Text(todayText).tag(0)
                            Text(weekText).tag(1)
                            Text(monthText).tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        .liquidGlassCard(material: .ultraThin)
                        .padding(.horizontal)
                        .onChange(of: selectedPeriod) { _, _ in
                            HapticFeedback.selection()
                        }
                        
                        // Stats Cards (always show, with loading indicator overlay if needed)
                        ZStack {
                            // Stats Cards
                            VStack(spacing: 16) {
                                // First Row: Total Salary and Tips (with percentage)
                                HStack(spacing: 16) {
                                    GlassStatCard(
                                        title: totalSalaryText,
                                        value: formatIncomeWithTarget(),
                                        icon: "dollarsign.circle.fill",
                                        color: Color(hex: "0288FF"),
                                        subtitle: "Base pay from hours worked"
                                    )
                                    .onTapGesture {
                                        selectedDetailType = "income"
                                        detailShifts = currentStats.shifts
                                        showingDetail = true
                                        HapticFeedback.light()
                                    }
                                    
                                    // Tips card with percentage badge
                                    ZStack(alignment: .topTrailing) {
                                        GlassStatCard(
                                            title: tipsText,
                                            value: formatTipsWithTarget(),
                                            icon: "banknote.fill",
                                            color: .blue,
                                            subtitle: "Customer tips received"
                                        )
                                        .onTapGesture {
                                            selectedDetailType = "tips"
                                            detailShifts = currentStats.shifts
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
                                        title: otherText,
                                        value: formatCurrency(currentStats.other),
                                        icon: "plus.circle.fill",
                                        color: .green,
                                        subtitle: "Other amount received"
                                    )
                                    .onTapGesture {
                                        selectedDetailType = "other"
                                        detailShifts = currentStats.shifts
                                        showingDetail = true
                                        HapticFeedback.light()
                                    }
                                    
                                    GlassStatCard(
                                        title: totalRevenueText,
                                        value: formatCurrency(currentStats.totalRevenue),
                                        icon: "chart.line.uptrend.xyaxis",
                                        color: .orange,
                                        subtitle: "Salary + tips + other - tip out"
                                    )
                                    .onTapGesture {
                                        selectedDetailType = "revenue"
                                        detailShifts = currentStats.shifts
                                        showingDetail = true
                                        HapticFeedback.light()
                                    }
                                }
                                
                                // Third Row: Hours and Sales
                                HStack(spacing: 16) {
                                    GlassStatCard(
                                        title: hoursWorkedText,
                                        value: formatHoursWithTarget(),
                                        icon: "clock.fill",
                                        color: .teal,
                                        subtitle: "Actual vs expected hours"
                                    )
                                    .onTapGesture {
                                        selectedDetailType = "hours"
                                        detailShifts = currentStats.shifts
                                        showingDetail = true
                                        HapticFeedback.light()
                                    }
                                    
                                    GlassStatCard(
                                        title: salesText,
                                        value: formatSalesWithTarget(),
                                        icon: "cart.fill",
                                        color: .indigo,
                                        subtitle: "Total sales served"
                                    )
                                    .onTapGesture {
                                        selectedDetailType = "sales"
                                        detailShifts = currentStats.shifts
                                        showingDetail = true
                                        HapticFeedback.light()
                                    }
                                }
                                
                                // Show hint for clickable cards
                                if !currentStats.shifts.isEmpty {
                                    Text(tapToViewDetailsText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                    }
                    
                    // Loading indicator overlay (only show during initial load)
                    if isLoading && !statsPreloaded {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.clear)
                    }
                }
                .padding(.vertical, 24)
                .refreshable {
                    await preloadAllStats()
                    await loadTargets()
                }
            }
            .navigationTitle(dashboardTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // App logo
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            .sheet(isPresented: $showingQuickEntry) {
                QuickEntryView(
                    entryDate: $entryDate,
                    entrySales: $entrySales,
                    entryTips: $entryTips,
                    entryTipOut: $entryTipOut,
                    entryOther: $entryOther,
                    entryHours: $entryHours,
                    isSaving: $isSavingEntry,
                    editingShift: nil,
                    userTargets: userTargets,
                    currentPeriod: selectedPeriod,
                    hourlyRate: defaultHourlyRate,
                    useEmployers: useMultipleEmployers,
                    employerName: nil,
                    employerHourlyRate: nil,
                    isShiftMode: false,
                    onSave: saveQuickEntry,
                    onCancel: {
                        showingQuickEntry = false
                        clearQuickEntry()
                    }
                )
            }
            .sheet(isPresented: $showingQuickShift) {
                QuickEntryView(
                    entryDate: $entryDate,
                    entrySales: $entrySales,
                    entryTips: $entryTips,
                    entryTipOut: $entryTipOut,
                    entryOther: $entryOther,
                    entryHours: $entryHours,
                    isSaving: $isSavingEntry,
                    editingShift: nil,
                    userTargets: userTargets,
                    currentPeriod: selectedPeriod,
                    hourlyRate: defaultHourlyRate,
                    useEmployers: useMultipleEmployers,
                    employerName: nil,
                    employerHourlyRate: nil,
                    isShiftMode: true,
                    onSave: saveQuickEntry,
                    onCancel: {
                        showingQuickShift = false
                        clearQuickEntry()
                    }
                )
            }
            .sheet(item: $editingShift) { shift in
                QuickEntryView(
                    entryDate: $editEntryDate,
                    entrySales: $editEntrySales,
                    entryTips: $editEntryTips,
                    entryTipOut: $editEntryTipOut,
                    entryOther: $editEntryOther,
                    entryHours: $editEntryHours,
                    isSaving: $isSavingEntry,
                    editingShift: shift,
                    userTargets: userTargets,
                    currentPeriod: selectedPeriod,
                    hourlyRate: shift.hourly_rate ?? defaultHourlyRate,
                    useEmployers: useMultipleEmployers,
                    employerName: shift.employer_name,
                    employerHourlyRate: shift.hourly_rate,
                    isShiftMode: dateFromString(shift.shift_date) ?? Date() > Date(),
                    onSave: { startTime, endTime in updateShift(shift, startTime: startTime, endTime: endTime) },
                    onCancel: {
                        editingShift = nil
                    },
                    onDelete: {
                        deleteShift(shift)
                    }
                )
            }
        }
        .onChange(of: editingShift) { _, newShift in
            if let shift = newShift {
                initializeEditingData(shift)
            }
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
    
    var currentStats: Stats {
        switch selectedPeriod {
        case 1: return weekStats
        case 2: return monthStats
        default: return todayStats
        }
    }
    
    var periodText: String {
        switch selectedPeriod {
        case 1: return weekText
        case 2: return monthText
        default: return todayText
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
            
            // Load Month's data
            let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!
            let monthQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("shift_date", value: dateFormatter.string(from: monthAgo))
            
            let monthShifts: [ShiftIncome] = try await monthQuery.execute().value
            var monthStatsTemp = Stats()
            monthStatsTemp.shifts = monthShifts
            
            // Calculate stats for each period
            func calculateStats(for shifts: [ShiftIncome]) -> Stats {
                var stats = Stats()
                stats.shifts = shifts
                
                for shift in shifts {
                    stats.hours += shift.hours
                    stats.sales += shift.sales
                    stats.tips += shift.tips
                    stats.income += (shift.hours * (shift.hourly_rate ?? defaultHourlyRate))
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
    
    func saveQuickEntry(startTime: String?, endTime: String?) {
        Task {
            isSavingEntry = true
            
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                struct NewShift: Encodable {
                    let user_id: String
                    let shift_date: String
                    let hours: Double
                    let sales: Double
                    let tips: Double
                    let cash_out: Double?
                    let other: Double?
                    let hourly_rate: Double
                    let start_time: String?
                    let end_time: String?
                }
                
                let newShift = NewShift(
                    user_id: userId.uuidString,
                    shift_date: dateFormatter.string(from: entryDate),
                    hours: Double(entryHours) ?? 0,
                    sales: Double(entrySales) ?? 0,
                    tips: Double(entryTips) ?? 0,
                    cash_out: Double(entryTipOut),
                    other: Double(entryOther),
                    hourly_rate: defaultHourlyRate,
                    start_time: startTime,
                    end_time: endTime
                )
                
                try await SupabaseManager.shared.client
                    .from("shifts")
                    .insert(newShift)
                    .execute()
                
                await MainActor.run {
                    isSavingEntry = false
                    showingQuickEntry = false
                    clearQuickEntry()
                    HapticFeedback.success()
                }
                
                await preloadAllStats()
                
            } catch {
                await MainActor.run {
                    isSavingEntry = false
                    HapticFeedback.error()
                }
                print("Error saving quick entry: \(error)")
            }
        }
    }
    
    func updateShift(_ shift: ShiftIncome, startTime: String?, endTime: String?) {
        Task {
            do {
                isSavingEntry = true
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                
                struct UpdatedShiftIncome: Encodable {
                    let actual_hours: Double
                    let sales: Double
                    let tips: Double
                    let cash_out: Double
                    let other: Double
                    let actual_start_time: String?
                    let actual_end_time: String?
                }
                
                let updatedIncome = UpdatedShiftIncome(
                    actual_hours: Double(editEntryHours) ?? 0,
                    sales: Double(editEntrySales) ?? 0,
                    tips: Double(editEntryTips) ?? 0,
                    cash_out: Double(editEntryTipOut) ?? 0,
                    other: Double(editEntryOther) ?? 0,
                    actual_start_time: startTime,
                    actual_end_time: endTime
                )
                
                // If earnings record exists, update it; otherwise create new one
                if let incomeId = shift.income_id {
                    try await SupabaseManager.shared.client
                        .from("shift_income")
                        .update(updatedIncome)
                        .eq("id", value: incomeId.uuidString)
                        .execute()
                } else {
                    // Create new earnings record
                    struct NewShiftIncome: Encodable {
                        let shift_id: String
                        let user_id: String
                        let actual_hours: Double
                        let sales: Double
                        let tips: Double
                        let cash_out: Double
                        let other: Double
                        let actual_start_time: String?
                        let actual_end_time: String?
                    }
                    
                    let newIncome = NewShiftIncome(
                        shift_id: shift.shift_id?.uuidString ?? shift.id.uuidString,
                        user_id: userId.uuidString,
                        actual_hours: Double(editEntryHours) ?? 0,
                        sales: Double(editEntrySales) ?? 0,
                        tips: Double(editEntryTips) ?? 0,
                        cash_out: Double(editEntryTipOut) ?? 0,
                        other: Double(editEntryOther) ?? 0,
                        actual_start_time: startTime,
                        actual_end_time: endTime
                    )
                    
                    try await SupabaseManager.shared.client
                        .from("shift_income")
                        .insert(newIncome)
                        .execute()
                }
                
                await preloadAllStats()
                
                await MainActor.run {
                    isSavingEntry = false
                    editingShift = nil
                }
            } catch {
                print("Error updating shift: \(error)")
                await MainActor.run {
                    isSavingEntry = false
                }
            }
        }
    }
    
    func deleteShift(_ shift: ShiftIncome) {
        Task {
            do {
                isSavingEntry = true
                
                try await SupabaseManager.shared.client
                    .from("shifts")
                    .delete()
                    .eq("id", value: shift.id.uuidString)
                    .execute()
                
                await preloadAllStats()
                
                await MainActor.run {
                    isSavingEntry = false
                    editingShift = nil
                    HapticFeedback.success()
                }
            } catch {
                print("Error deleting shift: \(error)")
                await MainActor.run {
                    isSavingEntry = false
                }
            }
        }
    }
    
    func clearQuickEntry() {
        entryDate = Date()
        entrySales = ""
        entryTips = ""
        entryTipOut = ""
        entryOther = ""
        entryHours = ""
    }
    
    func initializeEditingData(_ shift: ShiftIncome) {
        editEntryDate = dateFromString(shift.shift_date) ?? Date()
        editEntrySales = String(format: "%.2f", shift.sales)
        editEntryTips = String(format: "%.2f", shift.tips)
        editEntryTipOut = String(format: "%.2f", shift.cash_out ?? 0)
        editEntryOther = String(format: "%.2f", shift.other ?? 0)
        editEntryHours = String(format: "%.1f", shift.hours)
    }
    
    // Localization
    var dashboardTitle: String {
        return "Pro Tip 365"
    }
    
    var quickAddText: String {
        switch language {
        case "fr": return "Ajouter une entrée"
        case "es": return "Agregar entrada"
        default: return "Add entry"
        }
    }
    
    var quickAddShiftText: String {
        switch language {
        case "fr": return "Ajouter un quart"
        case "es": return "Agregar turno"
        default: return "Add shift"
        }
    }
    
    var todayText: String {
        switch language {
        case "fr": return "Aujourd'hui"
        case "es": return "Hoy"
        default: return "Today"
        }
    }
    
    var weekText: String {
        switch language {
        case "fr": return "Semaine"
        case "es": return "Semana"
        default: return "Week"
        }
    }
    
    var monthText: String {
        switch language {
        case "fr": return "Mois"
        case "es": return "Mes"
        default: return "Month"
        }
    }
    
    var totalSalaryText: String {
        switch language {
        case "fr": return "Salaire total"
        case "es": return "Salario total"
        default: return "Total Salary"
        }
    }
    
    var totalRevenueText: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingresos totales"
        default: return "Total Revenue"
        }
    }
    
    var tipsText: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }
    
    var otherText: String {
        switch language {
        case "fr": return "Autre"
        case "es": return "Otro"
        default: return "Other"
        }
    }
    
    var hoursWorkedText: String {
        switch language {
        case "fr": return "Heures travaillées"
        case "es": return "Horas trabajadas"
        default: return "Hours Worked"
        }
    }
    
    var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }
    
    var tapToViewDetailsText: String {
        switch language {
        case "fr": return "Touchez une carte pour voir les détails"
        case "es": return "Toca una tarjeta para ver detalles"
        default: return "Tap a card to view details"
        }
    }
}
