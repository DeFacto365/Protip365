import SwiftUI

struct AppInfoSection: View {
    @Binding var userEmail: String
    @Binding var language: String
    @Binding var showOnboarding: Bool

    private let localization: SettingsLocalization

    init(
        userEmail: Binding<String>,
        language: Binding<String>,
        showOnboarding: Binding<Bool>
    ) {
        self._userEmail = userEmail
        self._language = language
        self._showOnboarding = showOnboarding
        self.localization = SettingsLocalization(language: language.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 20) {
            // App Info Section
            HStack(spacing: 16) {
                // Logo
                Image("Logo2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    // App Name
                    HStack(spacing: 0) {
                        Text("ProTip")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("365")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }

                    Text(userEmail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // How to Use Button Section
            Button(action: {
                HapticFeedback.selection()
                showOnboarding = true
            }) {
                HStack {
                    Image(systemName: IconNames.Status.help)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.monochrome)
                        .frame(width: 28, height: 28)
                    Text(localization.howToUseText)
                        .foregroundStyle(.primary)
                        .font(.body)
                    Spacer()
                    Image(systemName: IconNames.Form.next)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Language Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: IconNames.Navigation.settings)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.monochrome)
                        .frame(width: 28, height: 28)
                    Text(localization.languageSection)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                Picker(localization.languageLabel, selection: $language) {
                    Text("English").tag("en")
                    Text("Français").tag("fr")
                    Text("Español").tag("es")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isAuthenticated: .constant(true), showOnboarding: $showOnboarding)
        }
    }
}