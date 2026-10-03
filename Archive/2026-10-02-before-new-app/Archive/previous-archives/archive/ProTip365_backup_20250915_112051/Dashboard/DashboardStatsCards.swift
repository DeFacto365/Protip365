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

    var periodText: String {
        DashboardMetrics.getPeriodText(
            selectedPeriod: selectedPeriod,
            monthViewType: monthViewType,
            localization: localization
        )
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
        VStack(spacing: 12) {
            // Sales at the top
            salesSection

            // Income section
            incomeSection

            // Hours section
            hoursSection

            // Tips section
            tipsSection

            // Other section (only if there's other income)
            if currentStats.other > 0 {
                otherSection
            }

            // Subtotal
            subtotalSection

            // Tip Out (negative) - only if there's tip out
            if currentStats.tipOut > 0 {
                tipOutSection
            }

            Divider()

            // Total Income
            totalIncomeSection

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
                    ? "\(Int((currentStats.sales / getSalesTarget()) * 100))% of target"
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
                ? "\(Int((currentStats.hours / getHoursTarget()) * 100))% of target"
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
                    ? String(format: "%.1f%% of sales • Target: %.0f%%", currentStats.tipPercentage, userTargets.tipTargetPercentage)
                    : String(format: "%.1f%% of sales", currentStats.tipPercentage)
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
                        period: periodText
                    )
                    HapticFeedback.light()
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
}