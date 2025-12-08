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
                    .onChange(of: state.useMultipleEmployers) { _, newValue in
                        HapticFeedback.selection()
                        if newValue {
                            // Clear single employer name when switching to multiple
                            state.singleEmployerName = ""
                            // Show employers page later
                            state.showEmployersPage = true
                        } else {
                            state.showEmployersPage = false
                        }
                    }

                // Show employer name input for single employer mode
                if !state.useMultipleEmployers {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.employerNameLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField(localization.employerNamePlaceholder, text: $state.singleEmployerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .submitLabel(.done)
                    }
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Show default employer picker if multiple employers enabled and employers exist
                if state.useMultipleEmployers && !state.employers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.defaultEmployerLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Menu {
                            ForEach(state.employers) { employer in
                                Button(employer.name) {
                                    state.defaultEmployerId = employer.id
                                    HapticFeedback.selection()
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedEmployerName)
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
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
        .sheet(isPresented: $state.showEmployersPage) {
            NavigationStack {
                EmployersView(isOnboarding: true)
                    .navigationTitle(localization.setupEmployersTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(localization.doneButtonText) {
                                state.showEmployersPage = false
                            }
                            .fontWeight(.semibold)
                        }
                    }
            }
        }
        .onAppear {
            // Load employers when step appears
            if state.useMultipleEmployers {
                Task {
                    await loadEmployers()
                }
            }
        }
        .onChange(of: state.showEmployersPage) { _, isShowing in
            // Reload employers when employer page is dismissed
            if !isShowing && state.useMultipleEmployers {
                Task {
                    await loadEmployers()
                }
            }
        }
    }

    // MARK: - Helper Methods

    private var selectedEmployerName: String {
        if let defaultEmployerId = state.defaultEmployerId,
           let employer = state.employers.first(where: { $0.id == defaultEmployerId }) {
            return employer.name
        }
        return localization.selectEmployerPlaceholder
    }

    private func loadEmployers() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            let employers: [Employer] = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .order("name")
                .execute()
                .value

            await MainActor.run {
                state.employers = employers
                // Auto-select first employer if none selected
                if state.defaultEmployerId == nil && !employers.isEmpty {
                    state.defaultEmployerId = employers.first?.id
                }
            }
        } catch {
            print("❌ Error loading employers: \(error)")
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