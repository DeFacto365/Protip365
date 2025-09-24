import SwiftUI

// MARK: - Shift Alert Section Component
struct ShiftAlertSection: View {
    @Binding var selectedAlert: String
    @Binding var showAlertPicker: Bool
    let localization: AddShiftLocalization
    @AppStorage("language") private var language = "en"

    private let alertOptions = ["None", "15 minutes", "30 minutes", "60 minutes", "1 day before"]

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Alert Selection Row
            Button(action: {
                showAlertPicker.toggle()
            }) {
                HStack {
                    Label(localization.alertText, systemImage: "bell")
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(localizedAlertText(selectedAlert))
                        .font(.body)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(0.5)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Alert Picker (shown when expanded)
            if showAlertPicker {
                VStack(spacing: 0) {
                    ForEach(alertOptions, id: \.self) { option in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedAlert = option
                                showAlertPicker = false
                            }
                        }) {
                            HStack {
                                Text(localizedAlertText(option))
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedAlert == option {
                                    Image(systemName: "checkmark")
                                        .font(.body)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                selectedAlert == option ?
                                Color.accentColor.opacity(0.1) : Color.clear
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        if option != alertOptions.last {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func localizedAlertText(_ alertOption: String) -> String {
        switch alertOption {
        case "None":
            switch language {
            case "fr": return "Aucune"
            case "es": return "Ninguna"
            default: return "None"
            }
        case "15 minutes":
            switch language {
            case "fr": return "15 minutes avant"
            case "es": return "15 minutos antes"
            default: return "15 minutes before"
            }
        case "30 minutes":
            switch language {
            case "fr": return "30 minutes avant"
            case "es": return "30 minutos antes"
            default: return "30 minutes before"
            }
        case "60 minutes":
            switch language {
            case "fr": return "1 heure avant"
            case "es": return "1 hora antes"
            default: return "1 hour before"
            }
        case "1 day before":
            switch language {
            case "fr": return "1 jour avant"
            case "es": return "1 día antes"
            default: return "1 day before"
            }
        default:
            return alertOption
        }
    }
}