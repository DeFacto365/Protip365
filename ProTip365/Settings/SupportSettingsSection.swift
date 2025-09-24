import SwiftUI
import Supabase

struct SupportSettingsSection: View {
    @Binding var showSuggestIdeas: Bool
    @Binding var showSupport: Bool
    @Binding var showingExportOptions: Bool
    @Binding var showOnboarding: Bool
    @Binding var shifts: [ShiftIncome]
    @Binding var suggestionText: String
    @Binding var suggestionEmail: String
    @Binding var showThankYouMessage: Bool
    @Binding var isSendingSuggestion: Bool
    @Binding var userEmail: String

    let language: String
    private let localization: SettingsLocalization

    init(
        showSuggestIdeas: Binding<Bool>,
        showSupport: Binding<Bool>,
        showingExportOptions: Binding<Bool>,
        showOnboarding: Binding<Bool>,
        shifts: Binding<[ShiftIncome]>,
        suggestionText: Binding<String>,
        suggestionEmail: Binding<String>,
        showThankYouMessage: Binding<Bool>,
        isSendingSuggestion: Binding<Bool>,
        userEmail: Binding<String>,
        language: String
    ) {
        self._showSuggestIdeas = showSuggestIdeas
        self._showSupport = showSupport
        self._showingExportOptions = showingExportOptions
        self._showOnboarding = showOnboarding
        self._shifts = shifts
        self._suggestionText = suggestionText
        self._suggestionEmail = suggestionEmail
        self._showThankYouMessage = showThankYouMessage
        self._isSendingSuggestion = isSendingSuggestion
        self._userEmail = userEmail
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title with icon
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.supportSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            VStack(spacing: 0) {
            // Export Data
            Button(action: {
                showingExportOptions = true
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(localization.exportData)
                            .foregroundStyle(.primary)
                        Text(localization.exportDataDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: IconNames.Form.next)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding()

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)

            // Onboarding Guide (Testing)
            Button(action: {
                HapticFeedback.selection()
                showOnboarding = true
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(localization.onboardingGuide)
                            .foregroundStyle(.primary)
                        Text(localization.onboardingGuideSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: IconNames.Form.next)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding()

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)

            // Support
            Button(action: {
                HapticFeedback.selection()
                showSupport = true
            }) {
                HStack {
                    Image(systemName: IconNames.Communication.email)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                    VStack(alignment: .leading) {
                        Text(localization.supportSection)
                            .foregroundStyle(.primary)
                        Text("support@protip365.com")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: IconNames.Form.next)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding()
            }

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 0.5)

            // Suggest Ideas
            Button(action: {
                HapticFeedback.selection()
                showSuggestIdeas = true
            }) {
                HStack {
                    Text(localization.suggestIdeas)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: IconNames.Form.next)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .sheet(isPresented: $showSuggestIdeas) {
            feedbackSheet(isSupport: false)
        }
        .sheet(isPresented: $showSupport) {
            feedbackSheet(isSupport: true)
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

    // MARK: - Feedback Sheet (for both Support and Suggestions)

    private func feedbackSheet(isSupport: Bool) -> some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if showThankYouMessage {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: IconNames.Status.success)
                        .font(.largeTitle)
                        .foregroundStyle(.tint)

                    Text(localization.thankYouTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(localization.thankYouMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showSuggestIdeas = false
                        showThankYouMessage = false
                        suggestionText = ""
                        suggestionEmail = ""
                    }
                }
            } else {
                VStack(spacing: 0) {
                    // iOS 26 Style Header
                    HStack {
                        // Cancel Button
                        Button(action: {
                            if isSupport {
                                showSupport = false
                            } else {
                                showSuggestIdeas = false
                            }
                            suggestionText = ""
                            suggestionEmail = ""
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Text(isSupport ? localization.supportSection : localization.suggestIdeas)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()

                        // Send Button
                        Button(action: {
                            HapticFeedback.medium()
                            sendSuggestion()
                        }) {
                            if isSendingSuggestion {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(suggestionText.isEmpty || suggestionEmail.isEmpty ? Color.gray : Color.accentColor)
                            }
                        }
                        .disabled(suggestionText.isEmpty || suggestionEmail.isEmpty || isSendingSuggestion)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Feedback Card - iOS 26 Style
                            VStack(alignment: .leading, spacing: 16) {
                                Label(isSupport ? localization.contactSupport : localization.yourSuggestionHeader, systemImage: isSupport ? IconNames.Communication.email : "lightbulb")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(isSupport ? localization.supportDescription : localization.suggestionFooter)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                // Email field first
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localization.suggestionEmailPlaceholder)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    TextField(localization.suggestionEmailPlaceholder, text: $suggestionEmail)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding()
                                        .background(Color(.systemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .textContentType(.emailAddress)
                                }

                                // Message text field second
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(isSupport ? localization.yourMessage : localization.yourSuggestionHeader)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    ZStack(alignment: .topLeading) {
                                        if suggestionText.isEmpty {
                                            Text(isSupport ? localization.describeYourIssue : localization.writeYourSuggestion)
                                                .font(.body)
                                                .foregroundStyle(.secondary.opacity(0.5))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 12)
                                        }

                                        TextEditor(text: $suggestionText)
                                            .font(.body)
                                            .padding(8)
                                            .scrollContentBackground(.hidden)
                                            .background(Color.clear)
                                    }
                                    .frame(minHeight: 120)
                                    .background(Color(.systemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

                            Spacer()
                                .frame(height: 30)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 10)
                    }
                }
                .onAppear {
                    // Pre-populate email with user's email
                    if suggestionEmail.isEmpty {
                        suggestionEmail = userEmail
                    }
                }
            }
        }
    }

    // MARK: - Send Suggestion Function
    private func sendSuggestion() {
        guard !suggestionText.isEmpty else { return }

        isSendingSuggestion = true

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session

                // Get Supabase URL from your SupabaseManager
                let supabaseURL = "https://ztzpjsbfzcccvbacgskc.supabase.co" // Your actual Supabase URL
                guard let url = URL(string: "\(supabaseURL)/functions/v1/send-suggestion") else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body = [
                    "suggestion": suggestionText,
                    "userEmail": suggestionEmail.isEmpty ? userEmail : suggestionEmail,
                    "replyEmail": suggestionEmail
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        await MainActor.run {
                            isSendingSuggestion = false
                            showThankYouMessage = true
                            HapticFeedback.success()

                            // Auto-close the form after showing the message for 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                showSuggestIdeas = false
                                showThankYouMessage = false
                                suggestionText = ""
                                suggestionEmail = ""
                            }
                        }
                    } else {
                        let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        let errorMessage = errorData?["error"] as? String ?? "Unknown error"
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    }
                }
            } catch {
                await MainActor.run {
                    isSendingSuggestion = false
                    // Handle error silently for now
                }
            }
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