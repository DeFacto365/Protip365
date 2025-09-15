import SwiftUI

struct DetailIncomeCard: View {
    let shifts: [ShiftIncome]
    let localization: DetailLocalization
    let averageDeductionPercentage: Double
    let targetIncome: Double
    let targetTips: Double

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

    var body: some View {
        VStack(spacing: 12) {
            Text(localization.incomeBreakdownText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Gross Salary
            HStack {
                Label(localization.grossSalaryText, systemImage: "dollarsign.circle")
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(totalSalary))
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("\(localization.hoursText): \(String(format: "%.1f", totalHours))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Net Salary (after deductions)
            HStack {
                Label(localization.netSalaryText, systemImage: "dollarsign.bank.building")
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    let netSalary = totalSalary * (1 - averageDeductionPercentage / 100)
                    Text(formatCurrency(netSalary))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                    Text("-\(Int(averageDeductionPercentage))% deductions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Tips
            HStack {
                Label(localization.tipsText, systemImage: "banknote.fill")
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(totalTips))
                        .font(.body)
                        .fontWeight(.semibold)
                    if targetTips > 0 {
                        Text("\(localization.targetText): \(formatCurrency(targetTips))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Other
            if totalOther > 0 {
                HStack {
                    Label(localization.otherText, systemImage: "square.and.pencil")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatCurrency(totalOther))
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }

            // Tip Out (negative)
            if totalTipOut > 0 {
                HStack {
                    Label(localization.tipOutText, systemImage: "minus.circle")
                        .font(.body)
                        .foregroundStyle(.red)
                    Spacer()
                    Text("-\(formatCurrency(totalTipOut))")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
            }

            Divider()

            // Total Income
            HStack {
                Label(localization.totalIncomeText, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(totalIncome))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    if targetIncome > 0 {
                        Text("\(localization.targetText): \(formatCurrency(targetIncome))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
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