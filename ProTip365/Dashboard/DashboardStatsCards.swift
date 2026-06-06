import SwiftUI

/// Statistics cards component for Dashboard view
struct DashboardStatsCards: View {
    let currentStats: DashboardMetrics.Stats
    let userTargets: DashboardMetrics.UserTargets
    let selectedPeriod: Int
    let monthViewType: Int
    let averageDeductionPercentage: Double
    let defaultHourlyRate: Double
    let localization: DashboardLocalization

    @Binding var detailViewData: DashboardMetrics.DetailViewData?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("weekStart") private var weekStartDay: Int = 0
    @AppStorage("hasVariableSchedule") private var hasVariableSchedule: Bool = false

    var periodText: String {
        DashboardMetrics.getPeriodText(
            selectedPeriod: selectedPeriod,
            monthViewType: monthViewType,
            localization: localization
        )
    }

    // IMPORTANT: These use the same logic as DashboardCharts.loadAllStats()
    // for consistent week calculation across the app
    var periodStartDate: Date? {
        guard selectedPeriod == 1 else { return nil } // Only for week view
        // Uses the same getStartOfWeek function as data loading
        return DashboardMetrics.getStartOfWeek(for: Date(), weekStartDay: weekStartDay)
    }

    var periodEndDate: Date? {
        guard selectedPeriod == 1, let startDate = periodStartDate else { return nil }
        // Week is always 7 days (start + 6 days), matching DashboardCharts logic
        return Calendar.current.date(byAdding: .day, value: 6, to: startDate)
    }

    var body: some View {
        // Stats Cards with advanced GlassEffectContainer for morphing animations
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                // Use unified compact cards for all views
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

    private var unifiedCompactCards: some View {
        VStack(spacing: 16) {
            // Performance Card (Keeping as is, or maybe moving below Hero?)
            // Let's put Hero First
            
            // 1. HERO: Total Earnings
            HeroStatCard(
                title: localization.totalIncomeText,
                value: DashboardMetrics.formatCurrency(currentStats.totalRevenue),
                rawValue: currentStats.totalRevenue,
                subtitle: periodText,
                color: .green
            )
            .padding(.bottom, 8)

            // 2. CHART: Weekly Distribution
            // Only show chart in Weekly view (selectedPeriod == 1)
            if selectedPeriod == 1 {
                let weeklyData = getWeeklyData(from: currentStats.shifts)
                EarningsChart(
                    data: weeklyData,
                    totalForWeek: currentStats.totalRevenue
                )
                .padding(.horizontal, 4) // Align with grid items
                .padding(.bottom, 12)
            }

            // 3. GRID: Secondary Stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Sales
                VerticalStatCard(
                    title: localization.salesText,
                    value: DashboardMetrics.formatCurrency(currentStats.sales),
                    icon: "cart.fill",
                    color: .purple
                )
                
                // Tips
                VerticalStatCard(
                    title: localization.tipsText,
                    value: DashboardMetrics.formatCurrency(currentStats.tips),
                    icon: "banknote.fill",
                    color: .green
                )
                
                // Hours
                VerticalStatCard(
                    title: localization.hoursWorkedText,
                    value: String(format: "%.1f", currentStats.hours),
                    icon: "clock.fill",
                    color: .blue,
                    caption: "hours"
                )
                
                // Net Salary (Est.)
                VerticalStatCard(
                    title: localization.expectedNetSalaryText,
                    value: DashboardMetrics.formatCurrency(currentStats.netIncome(deductionPercentage: averageDeductionPercentage)),
                    icon: "dollarsign.circle.fill",
                    color: .orange
                )
            }
            .padding(.bottom, 8)

            // 3. Performance Card (Moved below grid for flow)
            DashboardPerformanceCard(
                currentStats: currentStats,
                userTargets: userTargets,
                selectedPeriod: selectedPeriod,
                monthViewType: monthViewType,
                hasVariableSchedule: hasVariableSchedule,
                localization: localization
            )

            // 4. Details Section (Collapsible)
            DisclosureGroup(
                content: {
                    VStack(spacing: 12) {
                        Divider()
                        
                        // Other
                        if currentStats.other > 0 {
                            HStack {
                                Label(localization.otherText, systemImage: "square.and.pencil")
                                Spacer()
                                Text(DashboardMetrics.formatCurrency(currentStats.other))
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Tip Out
                        if currentStats.tipOut > 0 {
                             HStack {
                                Label(localization.tipOutText, systemImage: "minus.circle")
                                    .foregroundStyle(.red)
                                Spacer()
                                Text("-\(DashboardMetrics.formatCurrency(currentStats.tipOut))")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Gross Income
                        HStack {
                            Text(localization.totalGrossSalaryText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(DashboardMetrics.formatCurrency(currentStats.income))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                },
                label: {
                    Text(localization.showDetailsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            )
            .tint(.secondary)

            // Show Details Button - always show for all tabs
            showDetailsButton
        }
    }

    private var salesSection: some View {
        VStack(spacing: 4) {
            CompactGlassStatCard(
                title: localization.salesText,
                value: DashboardMetrics.formatCurrency(currentStats.sales),
                icon: "cart.fill",
                color: .purple,
                subtitle: selectedPeriod == 0 && getSalesTarget() > 0
                    ? String(format: localization.percentOfTargetText, Int((currentStats.sales / getSalesTarget()) * 100))
                    : nil
            )

            // Gray separator line
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, Spacing.xl)
        }
    }

    private var incomeSection: some View {
        CompactGlassStatCard(
            title: localization.expectedNetSalaryText,
            value: DashboardMetrics.formatCurrency(currentStats.netIncome(deductionPercentage: averageDeductionPercentage)),
            icon: "dollarsign.circle.fill",
            color: .blue,
            subtitle: "\(localization.totalGrossSalaryText): \(DashboardMetrics.formatCurrency(currentStats.income))"
        )
    }

    private var hoursSection: some View {
        CompactGlassStatCard(
            title: localization.hoursWorkedText,
            value: String(format: "%.1f hours", currentStats.hours),
            icon: "clock.badge",
            color: .blue,
            subtitle: selectedPeriod == 0 && getHoursTarget() > 0
                ? String(format: localization.percentOfTargetText, Int((currentStats.hours / getHoursTarget()) * 100))
                : nil
        )
    }

    private var tipsSection: some View {
        CompactGlassStatCard(
            title: localization.tipsText,
            value: DashboardMetrics.formatCurrency(currentStats.tips),
            icon: "banknote.fill",
            color: .green,
            subtitle: currentStats.tipPercentage > 0
                ? selectedPeriod == 0
                    ? String(format: localization.percentOfSalesText + " • " + localization.targetText + ": %.0f%%", currentStats.tipPercentage, userTargets.tipTargetPercentage)
                    : String(format: localization.percentOfSalesText, currentStats.tipPercentage)
                : nil
        )
    }

    private var otherSection: some View {
        CompactGlassStatCard(
            title: localization.otherText,
            value: DashboardMetrics.formatCurrency(currentStats.other),
            icon: "square.and.pencil",
            color: .blue,
            subtitle: nil
        )
    }

    private var subtotalSection: some View {
        HStack {
            Text(localization.subtotalText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            Spacer()
            Text(DashboardMetrics.formatCurrency(currentStats.income + currentStats.tips + currentStats.other))
                .font(.body)
                .fontWeight(.bold)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    private var tipOutSection: some View {
        HStack {
            Label(localization.tipOutText, systemImage: "minus.circle")
                .font(.body)
                .foregroundStyle(.red)
            Spacer()
            Text("-\(DashboardMetrics.formatCurrency(currentStats.tipOut))")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var totalIncomeSection: some View {
        HStack {
            Text(localization.totalIncomeText)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Spacer()
            Text(DashboardMetrics.formatCurrency(currentStats.totalRevenue))
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    private var showDetailsButton: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: Use NavigationLink to push to right pane
                NavigationLink(destination: DetailView(
                    shifts: currentStats.shifts.sorted { $0.shift_date > $1.shift_date },
                    detailType: "total",
                    periodText: periodText,
                    periodStartDate: periodStartDate,
                    periodEndDate: periodEndDate,
                    onEditShift: { shift in
                        // Handle edit if needed
                    }
                )) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .font(.body)
                        Text(localization.showDetailsText)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xxxl)
                    .padding(.vertical, Spacing.lg)
                    .background(currentStats.shifts.isEmpty ? Color.gray : Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(currentStats.shifts.isEmpty)
                .opacity(currentStats.shifts.isEmpty ? 0.6 : 1.0)
            } else {
                // iPhone: Use Button with sheet
                Button(action: {
                    detailViewData = DashboardMetrics.DetailViewData(
                        type: "total",
                        shifts: currentStats.shifts,
                        period: periodText,
                        startDate: periodStartDate,
                        endDate: periodEndDate
                    )
                    HapticManager.shared.impact(.light)
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .font(.body)
                        Text(localization.showDetailsText)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xxxl)
                    .padding(.vertical, Spacing.lg)
                    .background(currentStats.shifts.isEmpty ? Color.gray : Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(currentStats.shifts.isEmpty)
                .opacity(currentStats.shifts.isEmpty ? 0.6 : 1.0)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Methods

    private func getSalesTarget() -> Double {
        DashboardMetrics.getSalesTarget(
            selectedPeriod: selectedPeriod,
            monthViewType: monthViewType,
            userTargets: userTargets
        )
    }

    private func getHoursTarget() -> Double {
        DashboardMetrics.getHoursTarget(
            selectedPeriod: selectedPeriod,
            monthViewType: monthViewType,
            userTargets: userTargets
        )
    }

    // MARK: - Chart Helpers
    
    private func getWeeklyData(from shifts: [ShiftIncome]) -> [DailyEarnings] {
        let calendar = Calendar.current
        let today = Date()
        
        // Initialize 7 days with 0
        var days: [DailyEarnings] = []
        
        // 1. Get start of current week
        // Use the same weekStart logic as the rest of the dashboard
        let startOfWeek = DashboardMetrics.getStartOfWeek(for: today, weekStartDay: weekStartDay)
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            
            // Format Day String (e.g., "Mon")
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayString = formatter.string(from: date)
            
            // Find shifts for this day and sum earnings
            let dateKey = formatDateKey(date)
            let dailyTotal = shifts
                .filter { $0.shift_date == dateKey }
                .reduce(0) { $0 + calculateTotal(for: $1) }
            
            let isToday = calendar.isDateInToday(date)
            
            days.append(DailyEarnings(day: dayString, amount: dailyTotal, isToday: isToday))
        }
        
        return days
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func calculateTotal(for shift: ShiftIncome) -> Double {
        // Approximate total earnings for trend visual
        let hourlyIncome = (shift.hours ?? 0) * shift.hourly_rate
        let grossIncome = hourlyIncome + (shift.tips ?? 0)
        return grossIncome
    }
}
