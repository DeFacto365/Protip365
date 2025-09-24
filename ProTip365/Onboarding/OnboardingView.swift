import SwiftUI
import Supabase

struct OnboardingView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showOnboarding: Bool
    @StateObject private var state = OnboardingState()
    @StateObject private var securityManager = SecurityManager()
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?

    private let totalSteps = 7
    private var localization: OnboardingLocalization {
        return OnboardingLocalization(language: language)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Consistent app background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    OnboardingProgressBar(currentStep: state.currentStep, totalSteps: totalSteps)
                        .padding()

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Step Content
                            Group {
                                switch state.currentStep {
                                case 1:
                                    WelcomeStep(state: state, language: language)
                                case 2, 3:
                                    PermissionsStep(state: state, language: language)
                                case 4, 5:
                                    SetupStep(state: state, language: language)
                                case 6, 7:
                                    CompletionStep(state: state, language: language)
                                default:
                                    EmptyView()
                                }
                            }
                            .padding(.horizontal)

                            // Navigation Buttons
                            navigationButtons
                        }
                        .padding(.bottom, 20) // Ensure buttons stay on screen
                    }
                }
            }
            .navigationTitle(localization.stepTitle(currentStep: state.currentStep, totalSteps: totalSteps))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.cancelButtonText) {
                        showOnboarding = false
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .alert("Error", isPresented: $state.showError) {
            Button("OK") { }
        } message: {
            Text(state.errorMessage)
        }
        .onTapGesture {
            focusedField = nil
        }
        .onAppear {
            state.selectedLanguage = language
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if state.currentStep > 1 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state.currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(localization.backButtonText)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Spacer()

            Button(action: handleNextStep) {
                Group {
                    if state.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        HStack {
                            Text(state.currentStep == totalSteps ? localization.finishButtonText : localization.nextButtonText)
                            if state.currentStep < totalSteps {
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                }
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(state.isStepValid ? 1.0 : 0.6)
            }
            .disabled(!state.isStepValid || state.isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Helper Functions

    private func handleNextStep() {
        if state.currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                state.currentStep += 1
            }
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        state.isLoading = true

        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id

                // Save single employer if not using multiple employers
                if !state.useMultipleEmployers && !state.singleEmployerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let employer = Employer(
                        id: UUID(),
                        user_id: userId,
                        name: state.singleEmployerName.trimmingCharacters(in: .whitespacesAndNewlines),
                        hourly_rate: 15.00,  // Default hourly rate
                        active: true,
                        created_at: Date()
                    )

                    try await SupabaseManager.shared.client
                        .from("employers")
                        .insert(employer)
                        .execute()
                }

                let updates = OnboardingProfileUpdate(
                    preferred_language: state.selectedLanguage,
                    use_multiple_employers: state.useMultipleEmployers,
                    week_start: state.weekStartDay,
                    has_variable_schedule: state.hasVariableSchedule,
                    tip_target_percentage: Double(state.tipTargetPercentage) ?? 15.0,
                    target_sales_daily: Double(state.targetSalesDaily) ?? 0,
                    target_sales_weekly: state.hasVariableSchedule ? 0 : (Double(state.targetSalesWeekly) ?? 0),
                    target_sales_monthly: state.hasVariableSchedule ? 0 : (Double(state.targetSalesMonthly) ?? 0),
                    target_hours_daily: Double(state.targetHoursDaily) ?? 0,
                    target_hours_weekly: state.hasVariableSchedule ? 0 : (Double(state.targetHoursWeekly) ?? 0),
                    target_hours_monthly: state.hasVariableSchedule ? 0 : (Double(state.targetHoursMonthly) ?? 0)
                )

                try await SupabaseManager.shared.client
                    .from("users_profile")
                    .update(updates)
                    .eq("user_id", value: userId)
                    .execute()

                // Set security type if not none
                if state.selectedSecurityType != .none {
                    securityManager.setSecurityType(state.selectedSecurityType)
                }

                // Update app storage values
                UserDefaults.standard.set(state.useMultipleEmployers, forKey: "useMultipleEmployers")
                UserDefaults.standard.set(state.hasVariableSchedule, forKey: "hasVariableSchedule")

                await MainActor.run {
                    language = state.selectedLanguage
                    showOnboarding = false
                    state.isLoading = false
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    state.errorMessage = error.localizedDescription
                    state.showError = true
                    state.isLoading = false
                }
            }
        }
    }
}