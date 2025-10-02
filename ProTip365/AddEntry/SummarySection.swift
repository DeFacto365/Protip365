import SwiftUI

struct SummarySection: View {
    // MARK: - Parameters
    let didntWork: Bool
    let missedReason: String
    let sales: String
    let tips: String
    let tipOut: String
    let other: String
    let calculatedHours: Double
    let selectedEmployer: Employer?
    let defaultHourlyRate: Double
    let totalEarnings: Double

    // Localized strings
    let summaryText: String
    let didntWorkText: String
    let reasonText: String
    let salesText: String
    let grossPayText: String
    let tipsText: String
    let otherText: String
    let tipOutText: String
    let totalEarningsText: String

    // App Storage for deduction percentage
    @AppStorage("averageDeductionPercentage") private var averageDeductionPercentage: Double = 30.0
    @AppStorage("language") private var language = "en"

    // Computed property for net salary
    private var expectedNetSalary: Double {
        let deductionMultiplier = 1.0 - (averageDeductionPercentage / 100.0)
        return totalEarnings * deductionMultiplier
    }

    private var expectedNetSalaryText: String {
        switch language {
        case "fr": return "Salaire net attendu"
        case "es": return "Salario neto esperado"
        default: return "Expected net salary"
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(summaryText)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()

                // Show status badge if didn't work
                if didntWork {
                    Text(didntWorkText.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Show reason if didn't work
            if didntWork && !missedReason.isEmpty {
                HStack {
                    Text(reasonText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(missedReason)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }

                Divider()
            }

            // Sales at the top (stats only)
            if !didntWork {
                HStack {
                    Text(salesText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", Double(sales) ?? 0))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Divider()
            }

            // Income components
            if !didntWork {
                // Gross Pay (Base Pay)
                HStack {
                    Text(grossPayText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", calculatedHours * (selectedEmployer?.hourly_rate ?? defaultHourlyRate)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // Tips
                HStack {
                    Text(tipsText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", Double(tips) ?? 0))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // Other
                if Double(other) ?? 0 > 0 {
                    HStack {
                        Text(otherText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", Double(other) ?? 0))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                // Tip Out (negative)
                if Double(tipOut) ?? 0 > 0 {
                    HStack {
                        Text(tipOutText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "-$%.2f", Double(tipOut) ?? 0))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    }
                }

                Divider()

                // Expected Net Salary (after deductions) - Main total line
                HStack {
                    Text(expectedNetSalaryText)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(String(format: "$%.2f", expectedNetSalary))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}