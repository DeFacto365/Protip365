import SwiftUI

// MARK: - ShiftTimeSection Component
struct ShiftTimeSection: View {
    @Binding var selectedDate: Date
    @Binding var endDate: Date
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var selectedLunchBreak: String
    @Binding var showStartDatePicker: Bool
    @Binding var showEndDatePicker: Bool
    @Binding var showStartTimePicker: Bool
    @Binding var showEndTimePicker: Bool
    @Binding var showLunchBreakPicker: Bool

    let localization: AddShiftLocalization
    let lunchBreakOptions = ["None", "15 min", "30 min", "45 min", "60 min"]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            // Starts Row
            HStack {
                Text(localization.startsText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    // Date Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showStartDatePicker.toggle()
                            // Close other pickers when opening date picker
                            showEndDatePicker = false
                            showStartTimePicker = false
                            showEndTimePicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Time Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showStartTimePicker.toggle()
                            // Close other pickers when opening time picker
                            showStartDatePicker = false
                            showEndDatePicker = false
                            showEndTimePicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(timeFormatter.string(from: startTime))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Inline Date Picker
            if showStartDatePicker {
                DatePicker(localization.selectDateText, selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Inline Start Time Picker
            if showStartTimePicker {
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Divider
            Divider()
                .padding(.horizontal, 16)

            // Ends Row
            HStack {
                Text(localization.endsText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    // End Date Button (separate from start date)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEndDatePicker.toggle()
                            // Close other pickers when opening date picker
                            showStartDatePicker = false
                            showStartTimePicker = false
                            showEndTimePicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(dateFormatter.string(from: endDate))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Time Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEndTimePicker.toggle()
                            // Close other pickers when opening time picker
                            showStartDatePicker = false
                            showEndDatePicker = false
                            showStartTimePicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(timeFormatter.string(from: endTime))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Inline End Time Picker
            if showEndTimePicker {
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Inline End Date Picker
            if showEndDatePicker {
                DatePicker(localization.selectDateText, selection: $endDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Divider
            Divider()
                .padding(.horizontal, 16)

            // Lunch Break Row
            HStack {
                Text(localization.lunchBreakText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLunchBreakPicker.toggle()
                        // Close other pickers when opening lunch break picker
                        showStartDatePicker = false
                        showEndDatePicker = false
                        showStartTimePicker = false
                        showEndTimePicker = false
                    }
                }) {
                    Text(selectedLunchBreak)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Inline Lunch Break Picker
            if showLunchBreakPicker {
                Picker(localization.selectLunchBreakText, selection: $selectedLunchBreak) {
                    ForEach(lunchBreakOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .onChange(of: selectedLunchBreak) {
                    // Auto-close picker after selection with iOS-like delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLunchBreakPicker = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var selectedDate = Date()
    @Previewable @State var endDate = Date()
    @Previewable @State var startTime = Date()
    @Previewable @State var endTime = Date()
    @Previewable @State var selectedLunchBreak = "None"
    @Previewable @State var showStartDatePicker = false
    @Previewable @State var showEndDatePicker = false
    @Previewable @State var showStartTimePicker = false
    @Previewable @State var showEndTimePicker = false
    @Previewable @State var showLunchBreakPicker = false

    VStack {
        ShiftTimeSection(
            selectedDate: $selectedDate,
            endDate: $endDate,
            startTime: $startTime,
            endTime: $endTime,
            selectedLunchBreak: $selectedLunchBreak,
            showStartDatePicker: $showStartDatePicker,
            showEndDatePicker: $showEndDatePicker,
            showStartTimePicker: $showStartTimePicker,
            showEndTimePicker: $showEndTimePicker,
            showLunchBreakPicker: $showLunchBreakPicker,
            localization: AddShiftLocalization()
        )
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}