import SwiftUI

// MARK: - Calendar Date View (iOS 26 Style)
struct CalendarDateView: View {
    let date: Date
    let shifts: [ShiftIncome]

    var body: some View {
        VStack(spacing: 4) {
            // Date number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 17, weight: isToday ? .bold : .medium))
                .foregroundStyle(isToday ? .white : .primary)

            // iOS 26 style colored dots for events
            if !shifts.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(shifts.enumerated()), id: \.offset) { index, shift in
                        if index < 3 { // Show max 3 dots
                            Circle()
                                .fill(colorForShift(shift, index: index))
                                .frame(width: 6, height: 6)
                        }
                    }

                    // Show "+N" if more than 3 shifts
                    if shifts.count > 3 {
                        Text("+\(shifts.count - 3)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // Empty space to maintain consistent height
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(width: 44, height: 44)
        .background(
            Circle()
                .fill(isToday ? Color(.systemGray4) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }

    private func colorForShift(_ shift: ShiftIncome, index: Int) -> Color {
        // Use different colors based on shift status and earnings
        if shift.has_earnings {
            // Completed shifts with earnings
            if let total = shift.total_income, total > 0 {
                return [Color.green, Color.blue, Color.purple][index % 3]
            } else {
                return Color.orange // Completed but no earnings
            }
        } else {
            // Planned shifts (no earnings yet)
            switch shift.shift_status {
            case "planned":
                return [Color.cyan, Color.mint, Color.indigo][index % 3]
            case "missed":
                return Color.red
            default:
                return [Color.gray, Color.secondary, Color.primary][index % 3]
            }
        }
    }
}