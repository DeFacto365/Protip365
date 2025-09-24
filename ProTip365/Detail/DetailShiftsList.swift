import SwiftUI

struct DetailShiftsList: View {
    let shifts: [ShiftIncome]
    let localization: DetailLocalization
    let averageDeductionPercentage: Double
    var onEditShift: (ShiftIncome) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Group shifts by date
    private var shiftsByDate: [(date: String, shifts: [ShiftIncome])] {
        let grouped = Dictionary(grouping: shifts) { $0.shift_date }
        return grouped.map { (date: $0.key, shifts: $0.value) }
            .sorted { $0.date > $1.date }
    }

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

            // Group by date - one card per day
            ForEach(shiftsByDate, id: \.date) { dateGroup in
                dayCard(date: dateGroup.date, shifts: dateGroup.shifts)
            }
        }
    }

    @ViewBuilder
    private func dayCard(date: String, shifts: [ShiftIncome]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date header
            Text(formatDate(date))
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.top, 12)

            // Shifts for this date
            ForEach(shifts.sorted {
                // Sort by employer name then by hours if same employer
                if let emp1 = $0.employer_name, let emp2 = $1.employer_name, emp1 != emp2 {
                    return emp1 < emp2
                }
                return ($0.hours ?? 0) > ($1.hours ?? 0)
            }, id: \.id) { shift in
                shiftSubCard(for: shift)
                    .padding(.horizontal)
            }

            Spacer().frame(height: 8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func shiftSubCard(for shift: ShiftIncome) -> some View {
        Button(action: {
            onEditShift(shift)
            HapticFeedback.light()
        }) {
            VStack(spacing: 8) {
                // Employer header if available
                if let employer = shift.employer_name {
                    HStack {
                        Text(employer)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Shift details grid
                if horizontalSizeClass == .regular {
                    // iPad layout
                    iPadShiftDetails(shift: shift)
                } else {
                    // iPhone layout
                    iPhoneShiftDetails(shift: shift)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func iPadShiftDetails(shift: ShiftIncome) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Hours
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.hoursText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", shift.hours ?? 0))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(minWidth: 60)

            Spacer()

            // Sales
            if (shift.sales ?? 0) > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.salesText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(shift.sales ?? 0))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(minWidth: 80)

                Spacer()
            }

            // Net Salary
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.netSalaryText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                let salary = shift.base_income ?? ((shift.hours ?? 0) * (shift.hourly_rate ?? 15.0))
                let netSalary = salary * (1 - averageDeductionPercentage / 100)
                Text(formatCurrency(netSalary))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(minWidth: 80)

            Spacer()

            // Tips
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.tipsText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatCurrency(shift.tips ?? 0))
                    .font(.subheadline)
                    .fontWeight(.medium)
                if (shift.sales ?? 0) > 0 {
                    Text("(\(String(format: "%.1f%%", ((shift.tips ?? 0) / (shift.sales ?? 1)) * 100)))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 80)

            Spacer()

            // Total
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.totalText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatCurrency(shift.total_income ?? 0))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .frame(minWidth: 80)
        }
    }

    @ViewBuilder
    private func iPhoneShiftDetails(shift: ShiftIncome) -> some View {
        HStack(spacing: 16) {
            // Hours
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.hoursText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", shift.hours ?? 0))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            // Net Salary
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.netSalaryText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                let salary = shift.base_income ?? ((shift.hours ?? 0) * (shift.hourly_rate ?? 15.0))
                let netSalary = salary * (1 - averageDeductionPercentage / 100)
                Text(formatCurrency(netSalary))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }

            // Tips
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.tipsText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatCurrency(shift.tips ?? 0))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            // Total
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.totalText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatCurrency(shift.total_income ?? 0))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()
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