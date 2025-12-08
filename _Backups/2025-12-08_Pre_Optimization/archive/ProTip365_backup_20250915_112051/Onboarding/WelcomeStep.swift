import SwiftUI

// MARK: - Welcome Step View

struct WelcomeStep: View {
    @ObservedObject var state: OnboardingState
    @AppStorage("language") private var language = "en"
    private let localization: OnboardingLocalization

    init(state: OnboardingState, language: String) {
        self.state = state
        self.localization = OnboardingLocalization(language: language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Welcome Header
            VStack(spacing: 16) {
                Image("Logo2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)

                VStack(spacing: 8) {
                    Text(localization.welcomeTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(localization.languageStepDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 16)

            // Language Selection
            languageSelectionView
        }
    }

    private var languageSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label(localization.languageSelectionTitle, systemImage: "globe")
                    .font(.headline)
                    .foregroundColor(.primary)

                Menu {
                    Button("English") {
                        state.selectedLanguage = "en"
                        language = "en"
                        HapticFeedback.selection()
                    }
                    Button("Français") {
                        state.selectedLanguage = "fr"
                        language = "fr"
                        HapticFeedback.selection()
                    }
                    Button("Español") {
                        state.selectedLanguage = "es"
                        language = "es"
                        HapticFeedback.selection()
                    }
                } label: {
                    HStack {
                        Text(selectedLanguageDisplayName)
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

    private var selectedLanguageDisplayName: String {
        switch state.selectedLanguage {
        case "en": return "English"
        case "fr": return "Français"
        case "es": return "Español"
        default: return "English"
        }
    }
}

// MARK: - Onboarding Progress Bar Component

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color(.systemGray4))
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)

                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? Color.blue : Color(.systemGray4))
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            }

            Text("\(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Info Box Component

struct InfoBox: View {
    let title: String
    let message: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Target Row Component

struct TargetRow: View {
    let label: String
    let icon: String
    @Binding var value: String
    let placeholder: String
    let color: Color
    let isHours: Bool
    let focusField: Field?
    @FocusState.Binding var focusedField: Field?

    init(
        label: String,
        icon: String,
        value: Binding<String>,
        placeholder: String,
        color: Color,
        isHours: Bool = false,
        focusField: Field? = nil,
        focusedField: FocusState<Field?>.Binding
    ) {
        self.label = label
        self.icon = icon
        self._value = value
        self.placeholder = placeholder
        self.color = color
        self.isHours = isHours
        self.focusField = focusField
        self._focusedField = focusedField
    }

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(color)
            Spacer()
            TextField(placeholder, text: $value, onEditingChanged: { editing in
                if editing && (value == "0" || value == "0.00" || value == "0.0" || value == placeholder) {
                    value = ""
                }
            })
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .foregroundColor(.blue)
            .focused($focusedField, equals: focusField)
            .frame(width: 100)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                HapticFeedback.selection()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            WelcomeStep(state: OnboardingState(), language: "en")
                .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}