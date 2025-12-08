import SwiftUI

struct DetailAveragesCard: View {
    let shifts: [ShiftIncome]
    let localization: DetailLocalization
    let averageDeductionPercentage: Double

    // Calculations
    var totalSalary: Double {
        shifts.reduce(0) { total, shift in
            if let baseIncome = shift.base_income {
                return total + baseIncome
            }
            return total + (shift.hours * (shift.hourly_rate ?? 15.0))
        }
    }

    var totalTips: Double {
        shifts.reduce(0) { $0 + $1.tips }
    }

    var totalOther: Double {
        shifts.reduce(0) { $0 + ($1.other ?? 0) }
    }

    var totalTipOut: Double {
        shifts.reduce(0) { $0 + ($1.cash_out ?? 0) }
    }

    var totalIncome: Double {
        let netSalary = totalSalary * (1 - averageDeductionPercentage / 100)
        return netSalary + totalTips + totalOther - totalTipOut
    }

    var totalHours: Double {
        shifts.reduce(0) { $0 + $1.hours }
    }

    var totalSales: Double {
        shifts.reduce(0) { $0 + $1.sales }
    }

    var tipPercentage: Double {
        guard totalSales > 0, !totalSales.isNaN, !totalTips.isNaN else { return 0 }
        return (totalTips / totalSales) * 100
    }

    var body: some View {
        VStack(spacing: 16) {
            // Averages Section
            VStack(spacing: 12) {
                Text("AVERAGES & TRENDS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Average per shift
                HStack {
                    Text("Avg per Shift")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatCurrency(shifts.isEmpty ? 0 : totalIncome / Double(shifts.count)))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }

                // Average hourly rate
                HStack {
                    Text("Avg Hourly")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatCurrency(totalHours > 0 ? totalIncome / totalHours : 0) + "/hr")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                // Average tip percentage
                HStack {
                    Text("Avg Tip %")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(String(format: "%.1f%%", tipPercentage))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }

                Divider()

                // Best day
                if let bestShift = shifts.max(by: { ($0.total_income ?? 0) < ($1.total_income ?? 0) }) {
                    HStack {
                        Text("Best Day")
                            .font(.body)
                            .foregroundStyle(.orange)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatCurrency(bestShift.total_income ?? 0))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                            Text(formatDate(bestShift.shift_date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Shift count
                HStack {
                    Text("Total Shifts")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(shifts.count)")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
}