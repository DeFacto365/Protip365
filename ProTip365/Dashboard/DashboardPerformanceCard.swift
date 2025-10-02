import SwiftUI

/// Expandable performance card showing target vs actual metrics
struct DashboardPerformanceCard: View {
    let currentStats: DashboardMetrics.Stats
    let userTargets: DashboardMetrics.UserTargets
    let selectedPeriod: Int
    let monthViewType: Int
    let hasVariableSchedule: Bool
    let localization: DashboardLocalization

    @AppStorage("performanceCardExpanded") private var isExpanded: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Calculated Properties

    private var hasAnyTargets: Bool {
        let targets = getTargetsForPeriod()
        return targets.hours > 0 || targets.tips > 0 || targets.sales > 0 || targets.tipPercentage > 0
    }

    private var overallPerformance: Double {
        var performances: [Double] = []
        let targets = getTargetsForPeriod()

        if targets.hours > 0 && currentStats.hours > 0 {
            performances.append((currentStats.hours / targets.hours) * 100)
        }
        if targets.sales > 0 && currentStats.sales > 0 {
            performances.append((currentStats.sales / targets.sales) * 100)
        }
        if targets.tipPercentage > 0 && currentStats.tipPercentage > 0 {
            performances.append((currentStats.tipPercentage / targets.tipPercentage) * 100)
        }

        guard !performances.isEmpty else { return 0 }
        return performances.reduce(0, +) / Double(performances.count)
    }

    private var performanceColor: Color {
        let percentage = overallPerformance
        if percentage >= 95 {
            return .green
        } else if percentage >= 80 {
            return .orange
        } else {
            return .red
        }
    }

    private var performanceIcon: String {
        let percentage = overallPerformance
        if percentage >= 95 {
            return "🟢"
        } else if percentage >= 80 {
            return "🟡"
        } else {
            return "🔴"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            headerView

            // Expandable content
            if isExpanded {
                expandedContentView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // MARK: - Subviews

    private var headerView: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
                HapticFeedback.light()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.blue, .green, .orange)

                Text(localization.performanceText + ":")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if hasAnyTargets {
                    Text(performanceIcon)
                    Text("\(Int(overallPerformance))%")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(performanceColor)
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var expandedContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasAnyTargets {
                targetsContentView
            } else {
                noTargetsView
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    @ViewBuilder
    private var targetsContentView: some View {
        let targets = getTargetsForPeriod()

        // Hours
        if targets.hours > 0 {
            targetRow(
                name: localization.hoursWorkedText,
                actual: currentStats.hours,
                target: targets.hours,
                suffix: " " + localization.hoursShortText,
                isCurrency: false
            )
        }

        // Sales
        if targets.sales > 0 {
            targetRow(
                name: localization.salesText,
                actual: currentStats.sales,
                target: targets.sales,
                suffix: "",
                isCurrency: true
            )
        }

        // Tip Percentage (combines both tip amount and percentage tracking)
        if targets.tipPercentage > 0 && currentStats.tipPercentage > 0 {
            targetRow(
                name: localization.tipPercentageText,
                actual: currentStats.tipPercentage,
                target: targets.tipPercentage,
                suffix: "%",
                isCurrency: false
            )
        }
    }

    private var noTargetsView: some View {
        VStack(spacing: 12) {
            Text("💡")
                .font(.largeTitle)

            Text(localization.setTargetsPromptText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Note: Navigation to settings would be handled by parent view
            // Could add a callback here if needed
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func targetRow(
        name: String,
        actual: Double,
        target: Double,
        suffix: String,
        isCurrency: Bool
    ) -> some View {
        let percentage = target > 0 ? (actual / target) * 100 : 0
        let statusIcon = getStatusIcon(percentage: percentage)
        let progressColor = getProgressColor(percentage: percentage)

        return VStack(alignment: .leading, spacing: 6) {
            // Status icon + Name + Percentage
            HStack(spacing: 6) {
                Text(statusIcon)
                    .font(.body)

                Text(name + ":")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("\(Int(percentage))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(progressColor)

                Spacer()
            }

            // Actual / Target values
            Text(formatValue(actual, isCurrency: isCurrency) +
                 " / " +
                 formatValue(target, isCurrency: isCurrency) + suffix)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Progress bar
            ProgressView(value: min(actual / target, 1.0))
                .tint(progressColor)
                .frame(height: 4)
        }
    }

    // MARK: - Helper Methods

    private func getTargetsForPeriod() -> (hours: Double, tips: Double, sales: Double, tipPercentage: Double) {
        // Calculate sales target using shift-specific targets
        let effectiveSalesTarget = DashboardMetrics.calculateEffectiveSalesTarget(
            shifts: currentStats.shifts,
            defaultTarget: userTargets.dailySales
        )

        // For variable schedule users, only use daily targets
        if hasVariableSchedule {
            return (
                hours: userTargets.dailyHours,
                tips: userTargets.dailyIncome,
                sales: effectiveSalesTarget,
                tipPercentage: userTargets.tipTargetPercentage
            )
        }

        switch selectedPeriod {
        case 0: // Today
            return (
                hours: userTargets.dailyHours,
                tips: userTargets.dailyIncome,
                sales: effectiveSalesTarget,
                tipPercentage: userTargets.tipTargetPercentage
            )
        case 1: // Week
            return (
                hours: userTargets.weeklyHours,
                tips: userTargets.weeklyIncome,
                sales: effectiveSalesTarget,
                tipPercentage: userTargets.tipTargetPercentage
            )
        case 2: // Month or 4 Weeks
            if monthViewType == 1 && userTargets.weeklyHours > 0 {
                // 4 weeks mode - calculate from weekly
                return (
                    hours: userTargets.weeklyHours * 4,
                    tips: userTargets.weeklyIncome * 4,
                    sales: effectiveSalesTarget,
                    tipPercentage: userTargets.tipTargetPercentage
                )
            } else {
                // Calendar month mode
                return (
                    hours: userTargets.monthlyHours,
                    tips: userTargets.monthlyIncome,
                    sales: effectiveSalesTarget,
                    tipPercentage: userTargets.tipTargetPercentage
                )
            }
        case 3: // Year
            let currentMonth = Calendar.current.component(.month, from: Date())
            return (
                hours: userTargets.monthlyHours * Double(currentMonth),
                tips: userTargets.monthlyIncome * Double(currentMonth),
                sales: effectiveSalesTarget,
                tipPercentage: userTargets.tipTargetPercentage
            )
        default:
            return (0, 0, 0, 0)
        }
    }

    private func getStatusIcon(percentage: Double) -> String {
        if percentage >= 95 {
            return "✅"
        } else if percentage >= 80 {
            return "⚠️"
        } else {
            return "📊" // Neutral chart icon instead of negative X
        }
    }

    private func getProgressColor(percentage: Double) -> Color {
        if percentage >= 95 {
            return .green
        } else if percentage >= 80 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatValue(_ value: Double, isCurrency: Bool) -> String {
        if isCurrency {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: value)) ?? "$0"
        } else {
            return String(format: "%.1f", value)
        }
    }
}
