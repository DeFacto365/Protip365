import SwiftUI

// MARK: - Calendar Date View (iOS 26 Style)
struct CalendarDateView: View {
    let date: Date
    let shifts: [ShiftWithEntry]
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            // Date number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 17, weight: isToday || isSelected ? .bold : .medium))
                .foregroundStyle(isToday && !isSelected ? .white : .primary)

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
                .fill(
                    isSelected ? Color(.systemGroupedBackground) :
                    (isToday ? Color.blue.opacity(0.2) : Color.clear)
                )
        )
        .contentShape(Rectangle())
        .onAppear {
            // Debug logging
            if !shifts.isEmpty {
                print("📅 CalendarDateView - Showing \(shifts.count) shifts for date \(Calendar.current.component(.day, from: date))")
            }
        }
    }

    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }

    private func colorForShift(_ shift: ShiftWithEntry, index: Int) -> Color {
        // Use different colors based on shift status
        switch shift.expected_shift.status.lowercased() {
        case "completed":
            // Completed shifts - green variations
            return [Color.green, Color.mint, Color.green.opacity(0.8)][index % 3]
        case "planned":
            // Planned/upcoming shifts - purple variations
            return [Color.purple, Color.indigo, Color.purple.opacity(0.8)][index % 3]
        case "missed":
            // Missed shifts - always red
            return Color.red
        default:
            // Default for unknown status or nil - orange variations
            return [Color.orange, Color.yellow, Color.orange.opacity(0.8)][index % 3]
        }
    }
}