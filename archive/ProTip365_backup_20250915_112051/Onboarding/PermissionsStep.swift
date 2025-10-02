import SwiftUI

// MARK: - Permissions Step View

struct PermissionsStep: View {
    @ObservedObject var state: OnboardingState
    private let localization: OnboardingLocalization

    init(state: OnboardingState, language: String) {
        self.state = state
        self.localization = OnboardingLocalization(language: language)
    }

    var body: some View {
        Group {
            switch state.currentStep {
            case 2:
                multipleEmployersStepView
            case 3:
                weekStartStepView
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Multiple Employers Step

    private var multipleEmployersStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(localization.multipleEmployersTitle, systemImage: "building.2.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                Toggle(localization.multipleEmployersQuestion, isOn: $state.useMultipleEmployers)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: state.useMultipleEmployers) { _, _ in
                        HapticFeedback.selection()
                    }

                InfoBox(
                    title: localization.multipleEmployersExplanationTitle,
                    message: localization.multipleEmployersExplanation,
                    color: .blue
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - Week Start Step

    private var weekStartStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(localization.weekStartTitle, systemImage: "calendar")
                    .font(.headline)
                    .foregroundColor(.primary)

                Menu {
                    ForEach(0..<7) { index in
                        Button(localization.localizedWeekDay(index)) {
                            state.weekStartDay = index
                            HapticFeedback.selection()
                        }
                    }
                } label: {
                    HStack {
                        Text(localization.localizedWeekDay(state.weekStartDay))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                InfoBox(
                    title: localization.weekStartExplanationTitle,
                    message: localization.weekStartExplanation,
                    color: .blue
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var state = OnboardingState()

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Multiple Employers Preview
                        Group {
                            Text("Multiple Employers Step")
                                .font(.title2)
                                .fontWeight(.bold)

                            PermissionsStep(state: {
                                let previewState = OnboardingState()
                                previewState.currentStep = 2
                                return previewState
                            }(), language: "en")
                        }

                        Divider()

                        // Week Start Preview
                        Group {
                            Text("Week Start Step")
                                .font(.title2)
                                .fontWeight(.bold)

                            PermissionsStep(state: {
                                let previewState = OnboardingState()
                                previewState.currentStep = 3
                                return previewState
                            }(), language: "en")
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Permissions Steps")
            }
        }
    }

    return PreviewWrapper()
}