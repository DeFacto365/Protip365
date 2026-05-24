import SwiftUI

struct DetailPerformanceCard: View {
    let shifts: [ShiftIncome]
    let localization: DetailLocalization
    let targetSales: Double
    let targetHours: Double

    // Calculations
    var totalHours: Double {
        shifts.reduce(0) { $0 + $1.hours }
    }

    var totalSales: Double {
        shifts.reduce(0) { $0 + $1.sales }
    }

    var totalTips: Double {
        shifts.reduce(0) { $0 + $1.tips }
    }

    var tipPercentage: Double {
        guard totalSales > 0, !totalSales.isNaN, !totalTips.isNaN else { return 0 }
        return (totalTips / totalSales) * 100
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(localization.performanceMetricsText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Total Hours
            HStack {
                Text(localization.totalHoursText)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f hours", totalHours))
                        .font(.body)
                        .fontWeight(.semibold)
                    if targetHours > 0 {
                        Text("\(localization.targetText): \(String(format: "%.0f hours", targetHours))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Total Sales
            HStack {
                Text(localization.totalSalesText)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(totalSales))
                        .font(.body)
                        .fontWeight(.semibold)
                    if targetSales > 0 {
                        Text("\(localization.targetText): \(formatCurrency(targetSales))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Tip Percentage
            if totalSales > 0 && totalTips > 0 {
                HStack {
                    Text(localization.tipPercentText)
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(String(format: "%.1f%%", tipPercentage))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}