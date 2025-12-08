import SwiftUI
import Supabase

struct ProfileSettingsSection: View {
    @Binding var userEmail: String
    @Binding var userName: String
    @Environment(\.colorScheme) private var colorScheme

    let language: String
    private let localization: SettingsLocalization

    init(
        userEmail: Binding<String>,
        userName: Binding<String>,
        language: String
    ) {
        self._userEmail = userEmail
        self._userName = userName
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header with Icon
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.profileSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            // User Name
            HStack {
                Text(localization.nameLabel)
                    .foregroundStyle(.primary)
                Spacer()
                TextField("Enter your name", text: $userName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.primary)
                    .frame(width: 200)
                    .padding(8)
                    .liquidGlassForm()
            }

            // User Email (read-only)
            HStack {
                Text(localization.emailLabel)
                    .foregroundStyle(.primary)
                Spacer()
                Text(userEmail)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}
