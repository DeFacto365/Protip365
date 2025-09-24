import SwiftUI

// MARK: - ShiftDetailsSection Component
struct ShiftDetailsSection: View {
    @Binding var selectedEmployer: Employer?
    @Binding var comments: String
    @Binding var showEmployerPicker: Bool
    @Binding var showStartDatePicker: Bool
    @Binding var showEndDatePicker: Bool
    @Binding var showStartTimePicker: Bool
    @Binding var showEndTimePicker: Bool
    @Binding var showLunchBreakPicker: Bool

    let employers: [Employer]
    let localization: AddShiftLocalization

    var body: some View {
        VStack(spacing: 0) {
            // Employer Row (moved to top)
            HStack {
                Text(localization.employerText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showEmployerPicker.toggle()
                        // Close other pickers when opening employer picker
                        showStartDatePicker = false
                        showEndDatePicker = false
                        showStartTimePicker = false
                        showEndTimePicker = false
                        showLunchBreakPicker = false
                    }
                }) {
                    Text(selectedEmployer?.name ?? localization.selectEmployerText)
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

            // Inline Employer Picker
            if showEmployerPicker {
                Picker(localization.selectEmployerText, selection: $selectedEmployer) {
                    ForEach(employers, id: \.id) { employer in
                        Text(employer.name)
                            .tag(employer as Employer?)
                    }
                }
                .pickerStyle(.wheel)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .onChange(of: selectedEmployer) {
                    // Auto-close picker after selection with iOS-like delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEmployerPicker = false
                        }
                    }
                }
            }

            // Divider
            Divider()
                .padding(.horizontal, 16)

            // Comments Row
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.commentsText)
                    .font(.body)
                    .foregroundColor(.primary)

                TextField(localization.addNotesText, text: $comments, axis: .vertical)
                    .font(.body)
                    .textFieldStyle(.plain)
                    .lineLimit(2...2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var selectedEmployer: Employer? = nil
    @Previewable @State var comments = ""
    @Previewable @State var showEmployerPicker = false
    @Previewable @State var showStartDatePicker = false
    @Previewable @State var showEndDatePicker = false
    @Previewable @State var showStartTimePicker = false
    @Previewable @State var showEndTimePicker = false
    @Previewable @State var showLunchBreakPicker = false

    let sampleEmployers = [
        Employer(id: UUID(), user_id: UUID(), name: "Restaurant ABC", hourly_rate: 15.0, active: true, created_at: Date()),
        Employer(id: UUID(), user_id: UUID(), name: "Coffee Shop XYZ", hourly_rate: 12.0, active: true, created_at: Date())
    ]

    VStack {
        ShiftDetailsSection(
            selectedEmployer: $selectedEmployer,
            comments: $comments,
            showEmployerPicker: $showEmployerPicker,
            showStartDatePicker: $showStartDatePicker,
            showEndDatePicker: $showEndDatePicker,
            showStartTimePicker: $showStartTimePicker,
            showEndTimePicker: $showEndTimePicker,
            showLunchBreakPicker: $showLunchBreakPicker,
            employers: sampleEmployers,
            localization: AddShiftLocalization()
        )
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}