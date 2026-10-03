import SwiftUI

struct TimePickerSection: View {
    // MARK: - Bindings
    @Binding var selectedDate: Date
    @Binding var selectedEndDate: Date
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var selectedLunchBreak: String
    @Binding var showDatePicker: Bool
    @Binding var showEndDatePicker: Bool
    @Binding var showStartTimePicker: Bool
    @Binding var showEndTimePicker: Bool
    @Binding var showLunchBreakPicker: Bool

    // MARK: - Parameters
    let editingShift: ShiftWithEntry?
    let lunchBreakOptions: [String]
    let startsText: String
    let endsText: String
    let lunchBreakText: String

    // MARK: - Computed Properties
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

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Starts Row (Date and Time on same line)
            HStack {
                Text(startsText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    // Date Button (disabled when editing)
                    if editingShift != nil {
                        // Show as non-clickable text when editing
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Allow date selection for new entries
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDatePicker.toggle()
                                // Close other pickers
                                showStartTimePicker = false
                                showEndTimePicker = false
                                showLunchBreakPicker = false
                                showEndDatePicker = false
                            }
                        }) {
                            Text(dateFormatter.string(from: selectedDate))
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color(.systemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Time Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showStartTimePicker.toggle()
                            // Close other pickers
                            showDatePicker = false
                            showEndTimePicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(timeFormatter.string(from: startTime))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Inline Date Picker
            if showDatePicker {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Inline Start Time Picker
            if showStartTimePicker {
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: startTime) { _, newValue in
                        adjustEndDateForOvernightShift(newStartTime: newValue)
                    }
            }

            Divider()
                .padding(.horizontal, 8)

            // Ends Row (Date and Time on same line)
            HStack {
                Text(endsText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    // End Date Button (can be different for overnight shifts, disabled when editing)
                    if editingShift != nil {
                        // Show as non-clickable text when editing
                        Text(dateFormatter.string(from: selectedEndDate))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Allow end date selection for new entries
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEndDatePicker.toggle()
                                // Close other pickers
                                showDatePicker = false
                                showStartTimePicker = false
                                showEndTimePicker = false
                                showLunchBreakPicker = false
                            }
                        }) {
                            Text(dateFormatter.string(from: selectedEndDate))
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color(.systemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Time Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEndTimePicker.toggle()
                            // Close other pickers
                            showDatePicker = false
                            showStartTimePicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(timeFormatter.string(from: endTime))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Inline End Date Picker
            if showEndDatePicker {
                DatePicker("Select End Date", selection: $selectedEndDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: selectedEndDate) { _, _ in
                        // Close the date picker when a date is selected
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEndDatePicker = false
                        }
                    }
            }

            // Inline End Time Picker
            if showEndTimePicker {
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: endTime) { _, newValue in
                        adjustEndDateForOvernightShift(newEndTime: newValue)
                    }
            }

            Divider()
                .padding(.horizontal, 8)

            // Lunch Break Row
            HStack {
                Text(lunchBreakText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLunchBreakPicker.toggle()
                        // Close other pickers
                        showDatePicker = false
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
                Picker("Select Lunch Break", selection: $selectedLunchBreak) {
                    ForEach(lunchBreakOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Helper Functions
    private func adjustEndDateForOvernightShift(newStartTime: Date) {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let startHour = startComponents.hour ?? 0
        let startMinute = startComponents.minute ?? 0
        let endHour = endComponents.hour ?? 0
        let endMinute = endComponents.minute ?? 0

        // If end time is before or equal to start time, assume it's next day
        if endHour < startHour || (endHour == startHour && endMinute <= startMinute) {
            // Only update if not already set to next day
            let daysDiff = calendar.dateComponents([.day], from: selectedDate, to: selectedEndDate).day ?? 0
            if daysDiff == 0 {
                selectedEndDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            }
        } else {
            // If end time is after start time and dates are different, reset to same day
            let daysDiff = calendar.dateComponents([.day], from: selectedDate, to: selectedEndDate).day ?? 0
            if daysDiff > 0 {
                selectedEndDate = selectedDate
            }
        }
    }

    private func adjustEndDateForOvernightShift(newEndTime: Date) {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)

        let startHour = startComponents.hour ?? 0
        let startMinute = startComponents.minute ?? 0
        let endHour = endComponents.hour ?? 0
        let endMinute = endComponents.minute ?? 0

        // If end time is before or equal to start time, assume it's next day
        if endHour < startHour || (endHour == startHour && endMinute <= startMinute) {
            selectedEndDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        } else {
            // If end time is after start time, use same day
            selectedEndDate = selectedDate
        }
    }
}