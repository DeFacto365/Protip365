import SwiftUI
import Supabase

struct SupportSettingsSection: View {
    @Binding var showSuggestIdeas: Bool
    @Binding var showingExportOptions: Bool
    @Binding var showOnboarding: Bool
    @Binding var shifts: [ShiftIncome]

    let language: String
    private let localization: SettingsLocalization

    init(
        showSuggestIdeas: Binding<Bool>,
        showingExportOptions: Binding<Bool>,
        showOnboarding: Binding<Bool>,
        shifts: Binding<[ShiftIncome]>,
        language: String
    ) {
        self._showSuggestIdeas = showSuggestIdeas
        self._showingExportOptions = showingExportOptions
        self._showOnboarding = showOnboarding
        self._shifts = shifts
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        Section(localization.supportSection) {
            VStack(spacing: Constants.formFieldSpacing) {
                // Suggest Ideas
                Button(action: {
                    showSuggestIdeas = true
                }) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundStyle(.yellow)
                            .frame(width: 24, height: 24)

                        Text(localization.suggestIdeas)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Constants.formPadding)
                }
                .buttonStyle(SecondaryButtonStyle())
                .liquidGlassForm()

                // Export Data
                Button(action: {
                    showingExportOptions = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.blue)
                            .frame(width: 24, height: 24)

                        Text(localization.exportData)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Constants.formPadding)
                }
                .buttonStyle(SecondaryButtonStyle())
                .liquidGlassForm()

                // App Tutorial
                Button(action: {
                    showOnboarding = true
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.green)
                            .frame(width: 24, height: 24)

                        Text(localization.appTutorial)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Constants.formPadding)
                }
                .buttonStyle(SecondaryButtonStyle())
                .liquidGlassForm()
            }
        }
        .sheet(isPresented: $showSuggestIdeas) {
            SuggestIdeasView(language: language)
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                exportManager: ExportManager(),
                shifts: shifts,
                language: language
            )
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isAuthenticated: .constant(true), showOnboarding: $showOnboarding)
        }
    }
}

// MARK: - Suggest Ideas View

struct SuggestIdeasView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var suggestionText = ""
    @State private var suggestionEmail = ""
    @State private var showThankYouMessage = false
    @State private var isSendingSuggestion = false

    let language: String
    private let localization: SettingsLocalization

    init(language: String) {
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.formSectionSpacing) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.yellow)

                        Text("Share Your Ideas")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Help us improve ProTip365 by sharing your suggestions and feedback.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Form
                    VStack(spacing: Constants.formFieldSpacing) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email (Optional)")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            TextField("your@email.com", text: $suggestionEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(LiquidGlassTextFieldStyle())
                        }
                        .padding(Constants.formPadding)
                        .liquidGlassForm()

                        // Suggestion Text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Suggestion")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            TextEditor(text: $suggestionText)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.formCornerRadius))
                        }
                        .padding(Constants.formPadding)
                        .liquidGlassForm()

                        // Submit Button
                        Button(action: sendSuggestion) {
                            HStack {
                                if isSendingSuggestion {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Text("Send Suggestion")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(suggestionText.isEmpty || isSendingSuggestion)
                        .padding(.horizontal, Constants.formPadding)
                    }
                    .padding()

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Suggest Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.cancelButton) {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showThankYouMessage {
                    thankYouOverlay
                }
            }
        }
    }

    private var thankYouOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("Thank You!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Your suggestion has been sent successfully.")
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(40)
        }
    }

    private func sendSuggestion() {
        guard !suggestionText.isEmpty else { return }

        isSendingSuggestion = true

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSendingSuggestion = false
            showThankYouMessage = true

            // Auto-dismiss after showing thank you
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
    }
}