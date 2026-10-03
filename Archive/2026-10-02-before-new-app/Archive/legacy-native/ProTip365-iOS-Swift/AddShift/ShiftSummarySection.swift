import SwiftUI

// MARK: - ShiftSummarySection Component
struct ShiftSummarySection: View {
    let startTime: Date
    let endTime: Date
    let selectedLunchBreak: String
    let localization: AddShiftLocalization

    // MARK: - Computed Properties
    private var expectedHours: Double {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

        var totalMinutes = endMinutes - startMinutes
        if totalMinutes < 0 {
            totalMinutes += 24 * 60 // Add 24 hours if end time is next day
        }

        // Subtract lunch break
        let lunchMinutes = lunchBreakMinutes
        totalMinutes -= lunchMinutes

        return Double(totalMinutes) / 60.0
    }

    private var lunchBreakMinutes: Int {
        switch selectedLunchBreak {
        case "15 min": return 15
        case "30 min": return 30
        case "45 min": return 45
        case "60 min": return 60
        default: return 0
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Divider
            Divider()
                .padding(.horizontal, 16)

            // Shift Expected Hours Row - BOLD
            HStack {
                Text(localization.shiftExpectedHoursText)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                Text(String(format: "%.1f \(localization.hoursText)", expectedHours))
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Preview
#Preview {
    let calendar = Calendar.current
    let startTime = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    let endTime = calendar.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()

    VStack {
        ShiftSummarySection(
            startTime: startTime,
            endTime: endTime,
            selectedLunchBreak: "30 min",
            localization: AddShiftLocalization()
        )
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}