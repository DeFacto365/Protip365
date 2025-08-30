import SwiftUI
import Supabase

struct DashboardView: View {
    @State private var todayStats = Stats()
    @State private var weekStats = Stats()
    @State private var monthStats = Stats()
    @State private var selectedPeriod = 0
    @State private var isLoading = false
    @State private var showingDetail = false
    @State private var selectedDetailType = ""
    @State private var detailShifts: [ShiftIncome] = []
    @State private var showingQuickEntry = false
    @State private var showingQuickShift = false
    @State private var editingShift: ShiftIncome? = nil
    @State private var userTargets = UserTargets()
    
    // Quick Entry Form States
    @State private var entryDate = Date()
    @State private var entrySales = ""
    @State private var entryTips = ""
    @State private var entryTipOut = ""
    @State private var entryHours = ""
    @State private var isSavingEntry = false
    
    @AppStorage("language") private var language = "en"
    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 15.00
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false
    
    struct Stats {
        var hours: Double = 0
        var sales: Double = 0
        var tips: Double = 0
        var tipOut: Double = 0
        var income: Double = 0  // This is salary (hours × rate)
        var tipPercentage: Double = 0
        var totalRevenue: Double = 0  // salary + tips - tipout
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
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
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
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
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
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)
                        .onChange(of: selectedPeriod) { _, _ in
                            HapticFeedback.selection()
                            Task {
                                await loadStats()
                            }
                        }
                        
                        if isLoading {
                            ProgressView()
                                .padding(50)
                                .frame(maxWidth: .infinity)
                        } else {
                            // Stats Cards
                            VStack(spacing: 16) {
                                // First Row: Total Salary and Tips (with percentage)
                                HStack(spacing: 16) {
                                    GlassStatCard(
                                        title: totalSalaryText,
                                        value: formatIncomeWithTarget(),
                                        icon: "dollarsign.circle.fill",
                                        color: .green,
                                        subtitle: "Base pay from hours worked"
                                    )
                                    .onTapGesture {
                                        if !currentStats.shifts.isEmpty {
                                            selectedDetailType = "income"
                                            detailShifts = currentStats.shifts
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                showingDetail = true
                                            }
                                            HapticFeedback.light()
                                        }
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
                                            if /* selectedPeriod != 0 && */ !currentStats.shifts.isEmpty {
                                                selectedDetailType = "tips"
                                                detailShifts = currentStats.shifts
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    showingDetail = true
                                                }
                                                HapticFeedback.light()
                                            }
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
                                
                                // Second Row: Tip Out and Total Revenue
                                HStack(spacing: 16) {
                                    GlassStatCard(
                                        title: tipOutText,
                                        value: currentStats.tipOut > 0 ? "-" + formatCurrency(currentStats.tipOut) : formatCurrency(0),
                                        icon: "minus.circle.fill",
                                        color: .red,
                                        subtitle: "Tips shared with team"
                                    )
                                    .onTapGesture {
                                        if /* selectedPeriod != 0 && */ !currentStats.shifts.isEmpty {
                                            selectedDetailType = "tipout"
                                            detailShifts = currentStats.shifts
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                showingDetail = true
                                            }
                                            HapticFeedback.light()
                                        }
                                    }
                                    
                                    GlassStatCard(
                                        title: totalRevenueText,
                                        value: formatCurrency(currentStats.totalRevenue),
                                        icon: "chart.line.uptrend.xyaxis",
                                        color: .orange,
                                        subtitle: "Salary + tips - tip out"
                                    )
                                    .onTapGesture {
                                        if /* selectedPeriod != 0 && */ !currentStats.shifts.isEmpty {
                                            selectedDetailType = "revenue"
                                            detailShifts = currentStats.shifts
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                showingDetail = true
                                            }
                                            HapticFeedback.light()
                                        }
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
                                        if /* selectedPeriod != 0 && */ !currentStats.shifts.isEmpty {
                                            selectedDetailType = "hours"
                                            detailShifts = currentStats.shifts
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                showingDetail = true
                                            }
                                            HapticFeedback.light()
                                        }
                                    }
                                    
                                    GlassStatCard(
                                        title: salesText,
                                        value: formatSalesWithTarget(),
                                        icon: "cart.fill",
                                        color: .indigo,
                                        subtitle: "Total sales served"
                                    )
                                    .onTapGesture {
                                        if /* selectedPeriod != 0 && */ !currentStats.shifts.isEmpty {
                                            selectedDetailType = "sales"
                                            detailShifts = currentStats.shifts
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                showingDetail = true
                                            }
                                            HapticFeedback.light()
                                            }
                                        }
                                }
                                
                                // Show hint for clickable cards
                                if /* selectedPeriod != 0 && */ !currentStats.shifts.isEmpty {
                                    Text(tapToViewDetailsText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Empty State
                        if currentStats.hours == 0 && !isLoading {
                            EmptyStateCard(period: selectedPeriod, language: language)
                                .padding(.horizontal)
                                .padding(.top, 20)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await loadStats()
                    await loadTargets()
                }
            }
            .navigationTitle(dashboardTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("v1.0.12")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                    entryDate: .constant(dateFromString(shift.shift_date) ?? Date()),
                    entrySales: .constant(String(format: "%.2f", shift.sales)),
                    entryTips: .constant(String(format: "%.2f", shift.tips)),
                    entryTipOut: .constant(String(format: "%.2f", shift.cash_out ?? 0)),
                    entryHours: .constant(String(format: "%.1f", shift.hours)),
                    isSaving: $isSavingEntry,
                    editingShift: shift,
                    userTargets: userTargets,
                    currentPeriod: selectedPeriod,
                    hourlyRate: shift.hourly_rate ?? defaultHourlyRate,
                    useEmployers: useMultipleEmployers,
                    employerName: shift.employer_name,
                    employerHourlyRate: shift.hourly_rate,
                    isShiftMode: dateFromString(shift.shift_date) ?? Date() > Date(),
                    onSave: { updateShift(shift) },
                    onCancel: {
                        editingShift = nil
                    }
                )
            }
        }
        .task {
            await loadStats()
            await loadTargets()
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
    
    func loadStats() async {
        isLoading = true
        defer { isLoading = false }
        
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
            
            var query = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
            
            switch selectedPeriod {
            case 0: // Today
                query = query.eq("shift_date", value: dateFormatter.string(from: today))
            case 1: // This Week - USING WEEK START SETTING
                let weekStart = getStartOfWeek(for: today, weekStartDay: weekStartDay)
                let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
                query = query
                    .gte("shift_date", value: dateFormatter.string(from: weekStart))
                    .lte("shift_date", value: dateFormatter.string(from: weekEnd))
            case 2: // This Month - Last 30 days
                let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!
                query = query.gte("shift_date", value: dateFormatter.string(from: monthAgo))
            default:
                break
            }
            
            let shifts: [ShiftIncome] = try await query.execute().value
            
            var stats = Stats()
            stats.shifts = shifts
            
            for shift in shifts {
                stats.hours += shift.hours
                stats.sales += shift.sales
                stats.tips += shift.tips
                stats.income += (shift.hours * (shift.hourly_rate ?? defaultHourlyRate))
                stats.tipOut += (shift.cash_out ?? 0)
            }
            
            // Calculate total revenue: salary + tips - tip out
            stats.totalRevenue = stats.income + stats.tips - stats.tipOut
            
            if stats.sales > 0 {
                stats.tipPercentage = (stats.tips / stats.sales) * 100
            }
            
            await MainActor.run {
                switch selectedPeriod {
                case 1: weekStats = stats
                case 2: monthStats = stats
                default: todayStats = stats
                }
            }
            
        } catch {
            print("Error loading stats: \(error)")
        }
    }
    
    func saveQuickEntry() {
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
                    let hourly_rate: Double
                }
                
                let newShift = NewShift(
                    user_id: userId.uuidString,
                    shift_date: dateFormatter.string(from: entryDate),
                    hours: Double(entryHours) ?? 0,
                    sales: Double(entrySales) ?? 0,
                    tips: Double(entryTips) ?? 0,
                    cash_out: Double(entryTipOut),
                    hourly_rate: defaultHourlyRate
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
                
                await loadStats()
                
            } catch {
                await MainActor.run {
                    isSavingEntry = false
                    HapticFeedback.error()
                }
                print("Error saving quick entry: \(error)")
            }
        }
    }
    
    func updateShift(_ shift: ShiftIncome) {
        Task {
            await loadStats()
            editingShift = nil
        }
    }
    
    func clearQuickEntry() {
        entryDate = Date()
        entrySales = ""
        entryTips = ""
        entryTipOut = ""
        entryHours = ""
    }
    
    // Localization
    var dashboardTitle: String {
        switch language {
        case "fr": return "Tableau de bord"
        case "es": return "Panel de control"
        default: return "Dashboard"
        }
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
    
    var tipOutText: String {
        switch language {
        case "fr": return "Partage pourboire"
        case "es": return "Propina compartida"
        default: return "Tip Out"
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
