import SwiftUI

// MARK: - Select-On-Focus TextField
struct SelectOnFocusTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var focusField: Field?
    let focusedField: FocusState<Field?>.Binding
    var keyboardType: UIKeyboardType = .decimalPad

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.textAlignment = .right
        textField.textColor = .systemBlue
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text

        // Handle focus
        if focusField == focusedField.wrappedValue {
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
                // Select all text when focused
                DispatchQueue.main.async {
                    uiView.selectedTextRange = uiView.textRange(from: uiView.beginningOfDocument, to: uiView.endOfDocument)
                }
            }
        } else {
            if uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectOnFocusTextField

        init(_ parent: SelectOnFocusTextField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.focusedField.wrappedValue = parent.focusField
            // Select all text when editing begins
            DispatchQueue.main.async {
                textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            // Don't clear focus here, let SwiftUI handle it
        }
    }
}

// MARK: - Completion Step View

struct CompletionStep: View {
    @ObservedObject var state: OnboardingState
    @FocusState private var focusedField: Field?
    private let localization: OnboardingLocalization

    init(state: OnboardingState, language: String) {
        self.state = state
        self.localization = OnboardingLocalization(language: language)
    }

    var body: some View {
        Group {
            switch state.currentStep {
            case 6:
                salesAndTipTargetsStepView
            case 7:
                howToUseStepView
            default:
                EmptyView()
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }

    // MARK: - Sales and Tip Targets Step

    private var salesAndTipTargetsStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(localization.salesAndTipTargetsTitle, systemImage: "banknote.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Tip Target Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(localization.tipPercentageTargetLabel, systemImage: "percent")
                            .foregroundColor(.primary)
                        Spacer()
                        HStack(spacing: 4) {
                            SelectOnFocusTextField(
                                text: $state.tipTargetPercentage,
                                placeholder: "15",
                                focusField: .tipPercentage,
                                focusedField: $focusedField
                            )
                            .frame(width: 60)
                            Text("%")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            focusedField = .tipPercentage
                        }
                    }

                    InfoBox(
                        title: localization.tipPercentageNoteTitle,
                        message: localization.tipPercentageNoteMessage,
                        color: .blue
                    )
                }

                // Average Deduction Percentage Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(localization.averageDeductionPercentageLabel, systemImage: "minus.circle.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        HStack(spacing: 4) {
                            SelectOnFocusTextField(
                                text: $state.averageDeductionPercentage,
                                placeholder: "30",
                                focusField: .averageDeductionPercentage,
                                focusedField: $focusedField
                            )
                            .frame(width: 60)
                            Text("%")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            focusedField = .averageDeductionPercentage
                        }
                    }

                    InfoBox(
                        title: localization.averageDeductionPercentageNoteTitle,
                        message: localization.averageDeductionPercentageNoteMessage,
                        color: .orange
                    )
                }

                // Sales Targets Section
                TargetRow(
                    label: localization.dailySalesTargetLabel,
                    icon: "chart.line.uptrend.xyaxis",
                    value: $state.targetSalesDaily,
                    placeholder: "500.00",
                    color: .primary,
                    focusField: .dailySales,
                    focusedField: $focusedField
                )

                if !state.hasVariableSchedule {
                    TargetRow(
                        label: localization.weeklySalesTargetLabel,
                        icon: "chart.bar.fill",
                        value: $state.targetSalesWeekly,
                        placeholder: "3500.00",
                        color: .primary,
                        focusField: .weeklySales,
                        focusedField: $focusedField
                    )

                    TargetRow(
                        label: localization.monthlySalesTargetLabel,
                        icon: "chart.pie.fill",
                        value: $state.targetSalesMonthly,
                        placeholder: "14000.00",
                        color: .primary,
                        focusField: .monthlySales,
                        focusedField: $focusedField
                    )
                }

                // Daily Hours Target
                TargetRow(
                    label: localization.dailyHoursTargetLabel,
                    icon: "timer",
                    value: $state.targetHoursDaily,
                    placeholder: "8",
                    color: .primary,
                    isHours: true,
                    focusField: .dailyHours,
                    focusedField: $focusedField
                )

                if !state.hasVariableSchedule {
                    TargetRow(
                        label: localization.weeklyHoursTargetLabel,
                        icon: "timer.circle.fill",
                        value: $state.targetHoursWeekly,
                        placeholder: "40",
                        color: .primary,
                        isHours: true,
                        focusField: .weeklyHours,
                        focusedField: $focusedField
                    )

                    TargetRow(
                        label: localization.monthlyHoursTargetLabel,
                        icon: "hourglass",
                        value: $state.targetHoursMonthly,
                        placeholder: "160",
                        color: .primary,
                        isHours: true,
                        focusField: .monthlyHours,
                        focusedField: $focusedField
                    )
                }

                if state.hasVariableSchedule {
                    InfoBox(
                        title: localization.variableScheduleNoteTitle,
                        message: localization.variableScheduleNoteMessage,
                        color: .blue
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - How to Use Step

    private var howToUseStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(localization.howToUseTitle, systemImage: "questionmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Step 1: Employers (conditional)
                if state.useMultipleEmployers {
                    StepCard(
                        number: "1",
                        title: localization.step1EmployersTitle,
                        description: localization.step1EmployersDescription,
                        color: .blue
                    )
                }

                // Step 2: Calendar & Shifts
                StepCard(
                    number: state.useMultipleEmployers ? "2" : "1",
                    title: localization.step2CalendarTitle,
                    description: localization.step2CalendarDescription,
                    color: .green
                )

                // Step 3: Entries
                StepCard(
                    number: state.useMultipleEmployers ? "3" : "2",
                    title: localization.step3EntriesTitle,
                    description: localization.step3EntriesDescription,
                    color: .orange
                )

                // Step 4: Dashboard
                StepCard(
                    number: state.useMultipleEmployers ? "4" : "3",
                    title: localization.step4DashboardTitle,
                    description: localization.step4DashboardDescription,
                    color: .purple
                )

                // Sync Feature
                SyncFeatureCard(
                    title: localization.syncFeaturesTitle,
                    description: localization.syncFeaturesDescription
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Step Card Component

struct StepCard: View {
    let number: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(number)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(color)
                    .clipShape(Circle())
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 32)
        }
        .padding(12)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Sync Feature Card Component

struct SyncFeatureCard: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 32)
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var state = OnboardingState()

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Sales and Tip Targets Preview
                        Group {
                            Text("Sales & Tip Targets Step")
                                .font(.title2)
                                .fontWeight(.bold)

                            CompletionStep(state: {
                                let previewState = OnboardingState()
                                previewState.currentStep = 6
                                previewState.hasVariableSchedule = false
                                return previewState
                            }(), language: "en")
                        }

                        Divider()

                        // How to Use Preview
                        Group {
                            Text("How to Use Step")
                                .font(.title2)
                                .fontWeight(.bold)

                            CompletionStep(state: {
                                let previewState = OnboardingState()
                                previewState.currentStep = 7
                                previewState.useMultipleEmployers = true
                                return previewState
                            }(), language: "en")
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Completion Steps")
            }
        }
    }

    return PreviewWrapper()
}