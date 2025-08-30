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
                        // Quick Add Button
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
                                        color: .green
                                    )
                                    .onTapGesture {
                                        if selectedPeriod != 0 && !currentStats.shifts.isEmpty {
                                            selectedDetailType = "income"
                                            detailShifts = currentStats.shifts
                                            showingDetail = true
                                            HapticFeedback.light()
                                        }
                                    }
                                    
                                    // Tips card with percentage badge
                                    ZStack(alignment: .topTrailing) {
                                        GlassStatCard(
                                            title: tipsText,
                                            value: formatTipsWithTarget(),
                                            icon: "banknote.fill",
                                            color: .blue
                                        )
                                        .onTapGesture {
                                            if selectedPeriod != 0 && !currentStats.shifts.isEmpty {
                                                selectedDetailType = "tips"
                                                detailShifts = currentStats.shifts
                                                showingDetail = true
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
                                        color: .red
                                    )
                                    .onTapGesture {
                                        if selectedPeriod != 0 && !currentStats.shifts.isEmpty {
                                            selectedDetailType = "tipout"
                                            detailShifts = currentStats.shifts
                                            showingDetail = true
                                            HapticFeedback.light()
                                        }
                                    }
                                    
                                    GlassStatCard(
                                        title: totalRevenueText,
                                        value: formatCurrency(currentStats.totalRevenue),
                                        icon: "chart.line.uptrend.xyaxis",
                                        color: .orange
                                    )
                                    .onTapGesture {
                                        if selectedPeriod != 0 && !currentStats.shifts.isEmpty {
                                            selectedDetailType = "revenue"
                                            detailShifts = currentStats.shifts
                                            showingDetail = true
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
                                        color: .teal
                                    )
                                    .onTapGesture {
                                        if selectedPeriod != 0 && !currentStats.shifts.isEmpty {
                                            selectedDetailType = "hours"
                                            detailShifts = currentStats.shifts
                                            showingDetail = true
                                            HapticFeedback.light()
                                        }
                                    }
                                    
                                    GlassStatCard(
                                        title: salesText,
                                        value: formatSalesWithTarget(),
                                        icon: "cart.fill",
                                        color: .indigo
                                    )
                                    .onTapGesture {
                                        if selectedPeriod != 0 && !currentStats.shifts.isEmpty {
                                            selectedDetailType = "sales"
                                            detailShifts = currentStats.shifts
                                            showingDetail = true
                                            HapticFeedback.light()
                                        }
                                    }
                                }
                                
                                // Show hint for clickable cards
                                if selectedPeriod != 0 && !currentStats.shifts.isEmpty {
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
                    onSave: saveQuickEntry,
                    onCancel: {
                        showingQuickEntry = false
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

// MARK: - Glass Stat Card Component
struct GlassStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let period: Int
    let language: String
    
    var message: String {
        switch period {
        case 0:
            switch language {
            case "fr": return "Aucune donnée pour aujourd'hui"
            case "es": return "Sin datos para hoy"
            default: return "No shifts recorded today"
            }
        case 1:
            switch language {
            case "fr": return "Aucune donnée cette semaine"
            case "es": return "Sin datos esta semana"
            default: return "No shifts this week"
            }
        default:
            switch language {
            case "fr": return "Aucune donnée ce mois"
            case "es": return "Sin datos este mes"
            default: return "No shifts this month"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

// MARK: - Quick Entry View
struct QuickEntryView: View {
    @Binding var entryDate: Date
    @Binding var entrySales: String
    @Binding var entryTips: String
    @Binding var entryTipOut: String
    @Binding var entryHours: String
    @Binding var isSaving: Bool
    var editingShift: ShiftIncome?
    var userTargets: DashboardView.UserTargets
    var currentPeriod: Int
    var hourlyRate: Double
    var onSave: () -> Void
    var onCancel: () -> Void
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    
    enum Field {
        case sales, tips, tipOut, hours
    }
    
    var calculatedSalary: Double {
        let hours = Double(entryHours) ?? 0
        return hours * hourlyRate
    }
    
    var calculatedTotal: Double {
        let tips = Double(entryTips) ?? 0
        let tipOut = Double(entryTipOut) ?? 0
        return calculatedSalary + tips - tipOut
    }
    
    var isFutureDate: Bool {
        entryDate > Date()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(dateLabel, selection: $entryDate, displayedComponents: .date)
                        .disabled(editingShift != nil)
                        .onChange(of: entryDate) { _, _ in
                            focusedField = nil
                        }
                }
                
                Section {
                    HStack {
                        Text(hoursLabel)
                        Spacer()
                        TextField("0.0", text: $entryHours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .hours)
                            .frame(width: 100)
                        if getHoursTarget() > 0 {
                            Text("/ \(String(format: "%.0f", getHoursTarget()))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !isFutureDate {
                    Section {
                        // Salary (calculated)
                        HStack {
                            Text(salaryLabel)
                            Spacer()
                            Text(formatCurrency(calculatedSalary))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(salesLabel)
                            Spacer()
                            TextField(formatCurrency(0), text: $entrySales)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .sales)
                                .frame(width: 100)
                            if getSalesTarget() > 0 {
                                Text("/ \(formatCurrency(getSalesTarget()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text(tipsLabel)
                            Spacer()
                            TextField(formatCurrency(0), text: $entryTips)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .tips)
                                .frame(width: 100)
                            if getTipsTarget() > 0 {
                                Text("/ \(formatCurrency(getTipsTarget()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text(tipOutLabel)
                            Spacer()
                            TextField(formatCurrency(0), text: $entryTipOut)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .tipOut)
                                .frame(width: 100)
                        }
                        
                        // Total (calculated)
                        HStack {
                            Text(totalLabel)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatCurrency(calculatedTotal))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    } header: {
                        Text(earningsSection)
                    }
                }
                
                Section {
                    Button(action: onSave) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text(editingShift != nil ? updateButton : saveButton)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving || entryHours.isEmpty)
                }
            }
            .navigationTitle(editingShift != nil ? editShiftTitle : newEntryTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelButton) {
                        onCancel()
                    }
                }
            }
        }
    }
    
    func getSalesTarget() -> Double {
        switch currentPeriod {
        case 1: return userTargets.weeklySales / 7
        case 2: return userTargets.monthlySales / 30
        default: return userTargets.dailySales
        }
    }
    
    func getTipsTarget() -> Double {
        switch currentPeriod {
        case 1: return userTargets.weeklyTips / 7
        case 2: return userTargets.monthlyTips / 30
        default: return userTargets.dailyTips
        }
    }
    
    func getHoursTarget() -> Double {
        switch currentPeriod {
        case 1: return userTargets.weeklyHours / 7
        case 2: return userTargets.monthlyHours / 30
        default: return userTargets.dailyHours
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
    
    // Localization
    var newEntryTitle: String {
        switch language {
        case "fr": return "Nouvelle entrée"
        case "es": return "Nueva entrada"
        default: return "New Entry"
        }
    }
    
    var editShiftTitle: String {
        switch language {
        case "fr": return "Modifier le quart"
        case "es": return "Editar turno"
        default: return "Edit Shift"
        }
    }
    
    var dateLabel: String {
        switch language {
        case "fr": return "Date"
        case "es": return "Fecha"
        default: return "Date"
        }
    }
    
    var earningsSection: String {
        switch language {
        case "fr": return "Revenus"
        case "es": return "Ganancias"
        default: return "Earnings"
        }
    }
    
    var salaryLabel: String {
        switch language {
        case "fr": return "Salaire"
        case "es": return "Salario"
        default: return "Salary"
        }
    }
    
    var salesLabel: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }
    
    var tipsLabel: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }
    
    var tipOutLabel: String {
        switch language {
        case "fr": return "Partage pourboire"
        case "es": return "Propina compartida"
        default: return "Tip Out"
        }
    }
    
    var totalLabel: String {
        switch language {
        case "fr": return "Total"
        case "es": return "Total"
        default: return "Total"
        }
    }
    
    var hoursLabel: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }
    
    var saveButton: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save"
        }
    }
    
    var updateButton: String {
        switch language {
        case "fr": return "Mettre à jour"
        case "es": return "Actualizar"
        default: return "Update"
        }
    }
    
    var cancelButton: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
}

// MARK: - Detail View
struct DetailView: View {
    let shifts: [ShiftIncome]
    let detailType: String
    let periodText: String
    var onEditShift: (ShiftIncome) -> Void
    @Environment(\.dismiss) var dismiss
    @AppStorage("language") private var language = "en"
    
    var totalSales: Double {
        shifts.reduce(0) { $0 + $1.sales }
    }
    
    var totalTips: Double {
        shifts.reduce(0) { $0 + $1.tips }
    }
    
    var totalIncome: Double {
        shifts.reduce(0) { $0 + ($1.total_income ?? 0) }
    }
    
    var totalHours: Double {
        shifts.reduce(0) { $0 + $1.hours }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if shifts.isEmpty {
                    Text(noDataText)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(shifts, id: \.id) { shift in
                        Button(action: {
                            onEditShift(shift)
                            HapticFeedback.light()
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(formatDate(shift.shift_date))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Label("\(shift.hours, specifier: "%.1f") \(hoursText)", systemImage: "clock")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading) {
                                        Text(salesText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(shift.sales))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(tipsText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(shift.tips))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(totalText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(shift.total_income ?? 0))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                if let employer = shift.employer_name {
                                    Text(employer)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Section {
                        VStack(spacing: 12) {
                            HStack {
                                Text(totalSalesLabel)
                                    .font(.subheadline)
                                Spacer()
                                Text(formatCurrency(totalSales))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text(totalTipsLabel)
                                    .font(.subheadline)
                                Spacer()
                                Text(formatCurrency(totalTips))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text(totalIncomeLabel)
                                    .font(.headline)
                                Spacer()
                                Text(formatCurrency(totalIncome))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text(totalHoursLabel)
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f", totalHours))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text(totalsHeader)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("\(periodText) - \(detailTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(doneText) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.locale = Locale.current
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var detailTitle: String {
        switch detailType {
        case "income": return totalSalaryText
        case "tips": return tipsText
        case "tipout": return tipOutText
        case "sales": return salesText
        case "hours": return hoursText
        case "revenue": return totalRevenueText
        default: return detailsText
        }
    }
    
    // Localization
    var noDataText: String {
        switch language {
        case "fr": return "Aucune donnée"
        case "es": return "Sin datos"
        default: return "No data"
        }
    }
    
    var doneText: String {
        switch language {
        case "fr": return "Terminé"
        case "es": return "Listo"
        default: return "Done"
        }
    }
    
    var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
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
    
    var totalText: String {
        switch language {
        case "fr": return "Total"
        case "es": return "Total"
        default: return "Total"
        }
    }
    
    var hoursText: String {
        switch language {
        case "fr": return "heures"
        case "es": return "horas"
        default: return "hours"
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
    
    var detailsText: String {
        switch language {
        case "fr": return "Détails"
        case "es": return "Detalles"
        default: return "Details"
        }
    }
    
    var totalsHeader: String {
        switch language {
        case "fr": return "TOTAUX"
        case "es": return "TOTALES"
        default: return "TOTALS"
        }
    }
    
    var totalSalesLabel: String {
        switch language {
        case "fr": return "Total des ventes"
        case "es": return "Ventas totales"
        default: return "Total Sales"
        }
    }
    
    var totalTipsLabel: String {
        switch language {
        case "fr": return "Total des pourboires"
        case "es": return "Propinas totales"
        default: return "Total Tips"
        }
    }
    
    var totalIncomeLabel: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingreso total"
        default: return "Total Income"
        }
    }
    
    var totalHoursLabel: String {
        switch language {
        case "fr": return "Total des heures"
        case "es": return "Horas totales"
        default: return "Total Hours"
        }
    }
}
