import SwiftUI

// MARK: - iOS 26 Liquid Glass Toggle Style
struct LiquidGlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundStyle(.primary)

            Spacer()

            // Custom toggle switch with liquid glass effect
            ZStack {
                // Background track
                Capsule()
                    .fill(configuration.isOn ?
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                configuration.isOn ?
                                    Color.accentColor.opacity(0.3) :
                                    Color(.systemGray4),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: configuration.isOn ?
                            Color.accentColor.opacity(0.3) :
                            Color.black.opacity(0.1),
                        radius: configuration.isOn ? 8 : 4,
                        x: 0,
                        y: 2
                    )

                // Thumb with liquid glass effect
                Circle()
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 3,
                        x: 0,
                        y: 1
                    )
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                    )
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
            }
            .frame(width: 51, height: 31)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                    HapticFeedback.light()
                }
            }
        }
    }
}

// MARK: - Enhanced Liquid Glass Toggle with Label
struct LiquidGlassToggle: View {
    let title: String
    let icon: String?
    let description: String?
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)?

    init(
        _ title: String,
        icon: String? = nil,
        description: String? = nil,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.description = description
        self._isOn = isOn
        self.onChange = onChange
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .toggleStyle(LiquidGlassToggleStyle())
        .onChange(of: isOn) { _, newValue in
            onChange?(newValue)
        }
    }
}

// MARK: - Compact Toggle (for inline use)
struct CompactLiquidGlassToggle: View {
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)?

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .toggleStyle(LiquidGlassToggleStyle())
            .onChange(of: isOn) { _, newValue in
                HapticFeedback.light()
                onChange?(newValue)
            }
    }
}

// MARK: - Toggle Section for Settings
struct LiquidGlassToggleSection: View {
    let title: String?
    let footer: String?
    @ViewBuilder let content: () -> any View

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 16)
            }

            VStack(spacing: 1) {
                AnyView(content())
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

            if let footer = footer {
                Text(footer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview Extension
extension View {
    func liquidGlassToggleStyle() -> some View {
        self.toggleStyle(LiquidGlassToggleStyle())
    }
}

// MARK: - Preview
struct LiquidGlassToggle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Standard toggle with icon
            LiquidGlassToggle(
                "Notifications",
                icon: "bell.fill",
                description: "Receive daily reminders",
                isOn: .constant(true)
            )
            .padding(.horizontal)

            // Simple toggle
            LiquidGlassToggle(
                "Dark Mode",
                isOn: .constant(false)
            )
            .padding(.horizontal)

            // Compact toggle
            HStack {
                Text("Enable Feature")
                Spacer()
                CompactLiquidGlassToggle(isOn: .constant(true))
            }
            .padding(.horizontal)

            // Toggle section
            LiquidGlassToggleSection(
                title: "Preferences",
                footer: "These settings affect how the app behaves"
            ) {
                VStack(spacing: 0) {
                    LiquidGlassToggle(
                        "Use Multiple Employers",
                        icon: "building.2.fill",
                        isOn: .constant(true)
                    )
                    .padding()

                    Divider()

                    LiquidGlassToggle(
                        "Auto-Save",
                        icon: "square.and.arrow.down.fill",
                        isOn: .constant(false)
                    )
                    .padding()
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }
}