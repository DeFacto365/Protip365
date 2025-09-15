import SwiftUI

struct DetailShiftsList: View {
    let shifts: [ShiftIncome]
    let localization: DetailLocalization
    let averageDeductionPercentage: Double
    var onEditShift: (ShiftIncome) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localization.shiftDetailsText)
                    .font(horizontalSizeClass == .regular ? .headline : .caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(shifts.count) \(shifts.count == 1 ? "shift" : "shifts")")
                    .font(horizontalSizeClass == .regular ? .headline : .caption)
                    .foregroundColor(.secondary)
            }

            // Single column layout for all devices - no grid needed
            ForEach(shifts.sorted { $0.shift_date > $1.shift_date }, id: \.id) { shift in
                shiftCard(for: shift)
            }
        }
    }

    @ViewBuilder
    private func shiftCard(for shift: ShiftIncome) -> some View {
        Button(action: {
            onEditShift(shift)
            HapticFeedback.light()
        }) {
            VStack(spacing: 12) {
                // Date and Employer
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDate(shift.shift_date))
                            .font(.headline)
                            .foregroundColor(.primary)
                        if let employer = shift.employer_name {
                            Text(employer)
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Shift Stats Grid - Responsive based on device
                if horizontalSizeClass == .regular {
                    // iPad: More detailed grid with proper spacing
                    HStack(alignment: .top, spacing: 0) {
                        // Hours
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.hoursText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", shift.hours))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .frame(minWidth: 60)

                        Spacer()

                        // Sales
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.salesText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(shift.sales))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .frame(minWidth: 100)

                        Spacer()

                        // Gross & Net Salary
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.grossSalaryText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let salary = shift.base_income ?? (shift.hours * (shift.hourly_rate ?? 15.0))
                            Text(formatCurrency(salary))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .frame(minWidth: 100)

                        Spacer()

                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.netSalaryText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let salary = shift.base_income ?? (shift.hours * (shift.hourly_rate ?? 15.0))
                            let netSalary = salary * (1 - averageDeductionPercentage / 100)
                            Text(formatCurrency(netSalary))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                        .frame(minWidth: 100)

                        Spacer()

                        // Tips with percentage
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.tipsText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(formatCurrency(shift.tips))
                                    .font(.body)
                                    .fontWeight(.medium)
                                if shift.sales > 0 {
                                    Text("(\(String(format: "%.1f", (shift.tips / shift.sales) * 100))%)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .frame(minWidth: 100)

                        Spacer()

                        // Other
                        if let other = shift.other, other > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localization.otherText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatCurrency(other))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .frame(minWidth: 80)

                            Spacer()
                        }

                        // Total
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.totalText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(shift.total_income ?? 0))
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                        .frame(minWidth: 100)
                    }
                } else {
                    // iPhone: Compact grid
                    HStack(spacing: 20) {
                        // Hours
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.hoursText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", shift.hours))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        // Net Salary (show net on iPhone for space)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.netSalaryText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let salary = shift.base_income ?? (shift.hours * (shift.hourly_rate ?? 15.0))
                            let netSalary = salary * (1 - averageDeductionPercentage / 100)
                            Text(formatCurrency(netSalary))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }

                        // Tips with percentage
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.tipsText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(formatCurrency(shift.tips))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if shift.sales > 0 {
                                    Text("(\(String(format: "%.1f", (shift.tips / shift.sales) * 100))%)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.green)
                                }
                            }
                        }

                        // Total
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.totalText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(shift.total_income ?? 0))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
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