import SwiftUI
import Supabase

struct AppInfoSection: View {
    @Binding var language: String
    @Binding var showOnboarding: Bool

    private let localization: SettingsLocalization

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "v\(version) (\(build))"
    }

    init(
        language: Binding<String>,
        showOnboarding: Binding<Bool>
    ) {
        self._language = language
        self._showOnboarding = showOnboarding
        self.localization = SettingsLocalization(language: language.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title with icon
            HStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.languageSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            VStack(spacing: 20) {
            // App Info Section
            HStack(spacing: 16) {
                // Logo
                Image("Logo2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    // App Name
                    HStack(spacing: 0) {
                        Text("ProTip")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("365")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }

                    Text(appVersion)
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
                HStack(spacing: 12) {
                    Image(systemName: IconNames.Status.help)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
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
            }
            .buttonStyle(PlainButtonStyle())

            // Language Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: IconNames.Navigation.settings)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
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
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isAuthenticated: .constant(true), showOnboarding: $showOnboarding)
            }
        }
    }
}