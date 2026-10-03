import SwiftUI

struct SetupStep: View {
    @EnvironmentObject var securityManager: SecurityManager

    @ObservedObject var state: OnboardingState
    private let localization: OnboardingLocalization

    init(state: OnboardingState, language: String) {
        self.state = state
        self.localization = OnboardingLocalization(language: language)
    }

    var body: some View {
        Group {
            switch state.currentStep {
            case 4:
                securityStepView
            case 5:
                variableScheduleStepView
            default:
                EmptyView()
            }
        }
        .sheet(isPresented: $state.showPINSetup) {
            PINSetupSheet(
                state: state,
                securityManager: securityManager,
                localization: localization
            )
        }
    }

    // MARK: - Security Step

    private var securityStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(localization.securityTitle, systemImage: "lock.shield")
                    .font(.headline)
                    .foregroundColor(.primary)

                InfoBox(
                    title: localization.securityExplanationTitle,
                    message: localization.securityExplanation,
                    color: .blue
                )

                Menu {
                    Button(action: {
                        state.selectedSecurityType = .none
                        HapticFeedback.selection()
                    }) {
                        Label(localization.noSecurityText, systemImage: "lock.open")
                    }

                    Button(action: {
                        Task {
                            let success = await securityManager.authenticateWithBiometrics(
                                reason: localization.securityExplanation
                            )
                            await MainActor.run {
                                if success {
                                    state.selectedSecurityType = .biometric
                                }
                                HapticFeedback.selection()
                            }
                        }
                    }) {
                        Label(localization.faceIDText, systemImage: "faceid")
                    }

                    Button(action: {
                        state.showPINSetup = true
                        HapticFeedback.selection()
                    }) {
                        Label(localization.pinCodeText, systemImage: "number.square")
                    }
                } label: {
                    HStack {
                        Text(currentSecurityText)
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
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - Variable Schedule Step

    private var variableScheduleStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(localization.variableScheduleTitle, systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundColor(.primary)

                Toggle(localization.variableScheduleQuestion, isOn: $state.hasVariableSchedule)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: state.hasVariableSchedule) { _, _ in
                        HapticFeedback.selection()
                    }

                InfoBox(
                    title: localization.variableScheduleExplanationTitle,
                    message: localization.variableScheduleExplanation,
                    color: .blue
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - Helper Properties

    private var currentSecurityText: String {
        switch state.selectedSecurityType {
        case .biometric: return localization.faceIDText
        case .pinCode: return localization.pinCodeText
        case .none: return localization.noSecurityText
        default: return localization.noSecurityText
        }
    }
}

// MARK: - PIN Setup Sheet

struct PINSetupSheet: View {
    @ObservedObject var state: OnboardingState
    let securityManager: SecurityManager
    let localization: OnboardingLocalization

    var body: some View {
        NavigationStack {
            PINEntryView(
                securityManager: securityManager,
                isSettingPIN: true,
                onSuccess: {
                    state.showPINSetup = false
                    state.selectedSecurityType = .pinCode
                },
                onCancel: {
                    state.showPINSetup = false
                    state.selectedSecurityType = .none
                }
            )
            .navigationTitle("Set PIN Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.cancelButtonText) {
                        state.showPINSetup = false
                        state.selectedSecurityType = .none
                    }
                }
            }
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
                        // Security Step Preview
                        Group {
                            Text("Security Step")
                                .font(.title2)
                                .fontWeight(.bold)

                            SetupStep(state: {
                                let previewState = OnboardingState()
                                previewState.currentStep = 4
                                return previewState
                            }(), language: "en")
                        }

                        Divider()

                        // Variable Schedule Preview
                        Group {
                            Text("Variable Schedule Step")
                                .font(.title2)
                                .fontWeight(.bold)

                            SetupStep(state: {
                                let previewState = OnboardingState()
                                previewState.currentStep = 5
                                return previewState
                            }(), language: "en")
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Setup Steps")
            }
        }
    }

    return PreviewWrapper()
}
