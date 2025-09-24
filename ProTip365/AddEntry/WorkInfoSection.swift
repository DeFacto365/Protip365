import SwiftUI

struct WorkInfoSection: View {
    // MARK: - Bindings
    @Binding var selectedEmployer: Employer?
    @Binding var didntWork: Bool
    @Binding var missedReason: String
    @Binding var showEmployerPicker: Bool
    @Binding var showReasonPicker: Bool
    @Binding var calculatedHours: Double

    // MARK: - Parameters
    let employers: [Employer]
    let useMultipleEmployers: Bool
    let missedReasonOptions: [String]
    let employerText: String
    let didntWorkText: String
    let reasonText: String
    let selectReasonText: String
    let statusText: String
    let totalHoursText: String
    let hoursUnit: String
    let showDidntWorkOption: Bool  // Control whether to show the "Didn't work" toggle

    // MARK: - Action Closures
    let closeOtherPickers: (String?) -> Void

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Employer Row (if enabled)
            if useMultipleEmployers {
                HStack {
                    Text(employerText)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEmployerPicker.toggle()
                            if showEmployerPicker {
                                closeOtherPickers("employer")
                            }
                        }
                    }) {
                        Text(selectedEmployer?.name ?? "Select Employer")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

                // Inline Employer Picker
                if showEmployerPicker {
                    Picker("Select Employer", selection: $selectedEmployer) {
                        ForEach(employers, id: \.id) { employer in
                            Text(employer.name)
                                .tag(employer as Employer?)
                        }
                    }
                    .pickerStyle(.wheel)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: selectedEmployer) { _, _ in
                        // Just close the picker when employer is selected
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEmployerPicker = false
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 8)
            }

            // Didn't Work Toggle (only shown for new entries)
            if showDidntWorkOption {
                HStack {
                    Text(didntWorkText)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    CompactLiquidGlassToggle(isOn: $didntWork) { newValue in
                        if !newValue {
                            missedReason = ""
                            showReasonPicker = false
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // Reason Picker (shown when Didn't Work is toggled)
            if didntWork {
                HStack {
                    Text(reasonText)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showReasonPicker.toggle()
                            if showReasonPicker {
                                closeOtherPickers("reason")
                            }
                        }
                    }) {
                        HStack {
                            Text(missedReason.isEmpty ? selectReasonText : missedReason)
                                .font(.body)
                                .foregroundColor(missedReason.isEmpty ? .secondary : .primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

                // Inline Reason Picker
                if showReasonPicker {
                    Picker(selectReasonText, selection: $missedReason) {
                        Text(selectReasonText).tag("")
                        ForEach(missedReasonOptions, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                    .pickerStyle(.wheel)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: missedReason) { _, _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showReasonPicker = false
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 8)
            }

            // Status Display - Show even when didn't work
            HStack {
                if didntWork {
                    Text(statusText)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    HStack(spacing: 8) {
                        Text(didntWorkText.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        if !missedReason.isEmpty {
                            Text("(\(missedReason))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text(totalHoursText)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(String(format: "%.1f %@", calculatedHours, hoursUnit))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}