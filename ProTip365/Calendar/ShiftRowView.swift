import SwiftUI

// MARK: - Shift Row View
struct ShiftRowView: View {
    let shift: ShiftIncome
    let targetSalesDaily: Double
    let targetTipsDaily: Double
    let tipTargetPercentage: Double
    let averageDeductionPercentage: Double
    let onEdit: () -> Void
    let onDelete: () -> Void
    @AppStorage("language") private var language = "en"

    // Localization helper
    private var localization: ShiftRowLocalization {
        ShiftRowLocalization(language: language)
    }

    var body: some View {
        let _ = print("🎯 ShiftRowView - Sales Target: \(targetSalesDaily), Tips Target: \(targetTipsDaily)")
        return VStack(alignment: .leading, spacing: 12) {
            // Top section - Employer and Hours
            HStack {
                employerAndHoursSection
                Spacer()

                // Budget progress indicators (only show if targets are set and we have earnings)
                if shift.has_earnings && (targetSalesDaily > 0 || targetTipsDaily > 0) {
                    progressIndicatorsSection
                }
            }

            // Financial Breakdown section
            if shift.has_earnings {
                financialBreakdownSection
            } else {
                statusSection
            }

            // Action buttons at the bottom
            actionButtonsSection
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Sub-sections

    private var employerAndHoursSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Employer name at the top (smaller to fit on one line)
            if let employer = shift.employer_name {
                Text(employer)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            // Hours display (actual/expected format)
            hoursDisplaySection

            // Notes if available (but don't show if it's a "didn't work" reason)
            notesSection
        }
    }

    private var hoursDisplaySection: some View {
        HStack(spacing: 4) {
            if shift.has_earnings {
                // Show actual hours / expected hours
                Text("\(shift.hours ?? 0, specifier: "%.1f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let expectedHours = shift.expected_hours {
                    Text("/ \(expectedHours, specifier: "%.1f") hrs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("hrs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                // Check if "didn't work"
                let isDidntWork = shift.notes.map { localization.didntWorkReasons.contains($0) } ?? false

                if isDidntWork {
                    Text("0")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                } else if let expectedHours = shift.expected_hours {
                    Text("\(expectedHours, specifier: "%.1f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.tint)
                }

                Text("hrs")
                    .font(.subheadline)
                    .foregroundStyle(isDidntWork ? Color.red : Color.blue)
            }
        }
    }

    private var notesSection: some View {
        Group {
            if let notes = shift.notes, !notes.isEmpty {
                if !localization.didntWorkReasons.contains(notes) {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var progressIndicatorsSection: some View {
        HStack(spacing: 12) {
            // Sales progress
            if targetSalesDaily > 0 {
                SalesProgressIndicator(
                    actual: shift.sales ?? 0,
                    target: targetSalesDaily
                )
            }

            // Tips percentage indicator (based on sales)
            if (shift.sales ?? 0) > 0 {
                TipPercentageIndicator(
                    tips: shift.tips ?? 0,
                    sales: shift.sales ?? 0,
                    targetPercentage: tipTargetPercentage
                )
            }
        }
    }

    private var financialBreakdownSection: some View {
        VStack(spacing: 12) {
            // First row: Sales and Salary info
            firstFinancialRowSection

            // Second row: Tips, Other, Tip Out and Total
            secondFinancialRowSection
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var firstFinancialRowSection: some View {
        HStack(spacing: 16) {
            // Sales (if any)
            if (shift.sales ?? 0) > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.salesText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(shift.sales ?? 0))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }

            // Salary section - Net as main, Gross as subtitle (matching Dashboard style)
            if let baseIncome = shift.base_income, baseIncome > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.expectedNetSalaryText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    let netSalary = baseIncome * (1 - averageDeductionPercentage / 100)
                    Text(formatCurrency(netSalary))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    // Gross salary as subtitle in smaller text
                    Text("\(localization.grossSalaryText): \(formatCurrency(baseIncome))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private var secondFinancialRowSection: some View {
        HStack(spacing: 16) {
            // Tips
            if (shift.tips ?? 0) > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.tipsText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(shift.tips ?? 0))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }

            // Other
            if let other = shift.other, other > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.otherText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(other))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }

            // Tip Out
            if let tipOut = shift.cash_out, tipOut > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.tipOutText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("-\(formatCurrency(tipOut))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            // Total (always on the right)
            VStack(alignment: .trailing, spacing: 2) {
                Text(localization.totalText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatCurrency(shift.total_income ?? 0))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var statusSection: some View {
        HStack {
            Spacer()

            let isDidntWork = shift.notes.map { localization.didntWorkReasons.contains($0) } ?? false

            if isDidntWork, let reason = shift.notes {
                // Show the reason code for "didn't work" entries
                Text(reason.uppercased())
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                // Show "SCHEDULED" for regular future shifts
                Text("SCHEDULED")
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                HapticFeedback.light()
                onEdit()
            }) {
                HStack {
                    Image(systemName: IconNames.Actions.edit)
                        .font(.system(size: 14))
                    Text(localization.editText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(action: {
                HapticFeedback.light()
                onDelete()
            }) {
                HStack {
                    Image(systemName: IconNames.Actions.delete)
                        .font(.system(size: 14))
                    Text(localization.deleteText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    // MARK: - Helper Functions

    private func formatTimeRange(_ startTime: String, _ endTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short

        if let start = formatter.date(from: startTime),
           let end = formatter.date(from: endTime) {
            return "\(displayFormatter.string(from: start)) - \(displayFormatter.string(from: end))"
        }
        return ""
    }

    private func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
}