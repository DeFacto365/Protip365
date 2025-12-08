import SwiftUI

// MARK: - Glass Effect Types
enum GlassEffectIntensity {
    case regular
    case prominent
    case subtle
}

enum GlassEffectTransition {
    case identity
    case opacity
    case scale
}

// MARK: - Glass Effect Container
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            content
        }
    }
}

// MARK: - Background Extension Effect
extension View {
    /// Creates an immersive background that extends beyond safe areas
    func backgroundExtensionEffect() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
}

// MARK: - Glass Effect Modifier with Availability Check
struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(Circle())
    }
}

// MARK: - Glass Effect Modifier for Rounded Rectangle
struct GlassEffectRoundedModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
extension View {
    /// Primary glass surface using native glassEffect (Apple's exact pattern)
    func liquidGlassCard() -> some View {
        self
            .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
    }
    
    /// Secondary glass surface for buttons using native glassEffect
    /// Use .buttonStyle(.glass) instead of this modifier for Apple's native implementation
    @available(*, deprecated, message: "Use .buttonStyle(.glass) instead for Apple's native implementation")
    func liquidGlassButton() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Constants.buttonCornerRadius, style: .continuous))
    }
    
    /// Tertiary glass surface for form elements using native glassEffect (Apple's exact pattern)
    func liquidGlassForm() -> some View {
        self
            .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.formCornerRadius))
    }
    
    /// Enhanced glass surface with custom intensity
    func liquidGlassCard(intensity: GlassEffectIntensity = .regular) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    /// Glass surface for circular elements (icons, buttons)
    func liquidGlassCircle(intensity: GlassEffectIntensity = .regular) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(Circle())
    }
    
    /// Glass surface for pill-shaped elements
    func liquidGlassPill(intensity: GlassEffectIntensity = .regular) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
    
    /// Glass surface with custom corner radius
    func liquidGlassCustom(cornerRadius: CGFloat, intensity: GlassEffectIntensity = .regular) -> some View {
        self
            .background(.ultraThinMaterial)
    }
    
    /// Glass effect with smooth transition
    func liquidGlassWithTransition(intensity: GlassEffectIntensity = .regular) -> some View {
        self
            .background(.ultraThinMaterial)
    }
    
    /// Glass effect with custom transition
    func liquidGlassWithCustomTransition(intensity: GlassEffectIntensity = .regular, transition: GlassEffectTransition = .identity) -> some View {
        self
            .background(.ultraThinMaterial)
    }
    
    /// Interactive glass effect with press animation
    func liquidGlassInteractive(intensity: GlassEffectIntensity = .regular) -> some View {
        self
            .background(.ultraThinMaterial)
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: UUID())
    }
    
    /// Form row background with proper Liquid Glass layering
    func formRowBackground() -> some View {
        self
            .listRowBackground(
                Color(.secondarySystemGroupedBackground)
                    .overlay(.ultraThinMaterial.opacity(0.3))
            )
    }
    
    /// Example: Multiple cards with GlassEffectContainer for optimal performance
    func multipleCardsExample() -> some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                // Multiple cards that will be optimized by GlassEffectContainer
                Text("Card 1")
                    .liquidGlassCard()
                Text("Card 2")
                    .liquidGlassCard()
                Text("Card 3")
                    .liquidGlassCard()
            }
        }
    }
    
    /// Example: Form elements with GlassEffectContainer
    func formElementsExample() -> some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 12) {
                TextField("Input 1", text: .constant(""))
                    .liquidGlassForm()
                TextField("Input 2", text: .constant(""))
                    .liquidGlassForm()
                TextField("Input 3", text: .constant(""))
                    .liquidGlassForm()
            }
        }
    }
    
    /// Example: Button grid with GlassButtonStyle (Recommended)
    func buttonGridExample() -> some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button("1") { }
                        .buttonStyle(.borderedProminent)
                    Button("2") { }
                        .buttonStyle(.borderedProminent)
                    Button("3") { }
                        .buttonStyle(.borderedProminent)
                }
                HStack(spacing: 8) {
                    Button("4") { }
                        .buttonStyle(.borderedProminent)
                    Button("5") { }
                        .buttonStyle(.borderedProminent)
                    Button("6") { }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    /// Legacy glassCard for backward compatibility (deprecated)
    @available(*, deprecated, message: "Use liquidGlassCard() instead for proper Liquid Glass implementation")
    func glassCard() -> some View {
        liquidGlassCard()
    }
    
    /// Legacy glassButton for backward compatibility (deprecated)
    @available(*, deprecated, message: "Use liquidGlassButton() instead for proper Liquid Glass implementation")
    func glassButton() -> some View {
        liquidGlassButton()
    }
}

// MARK: - Haptic Feedback
enum HapticFeedback {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - Loading Overlay with Advanced Liquid Glass
struct LoadingOverlay: View {
    @Binding var isLoading: Bool
    var message: String = "Loading..."
    
    var body: some View {
        if isLoading {
            ZStack {
                // Background with glass effect
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                        .background(.ultraThinMaterial)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
        }
    }
}

// MARK: - Success Toast with Liquid Glass
struct SuccessToast: View {
    @Binding var show: Bool
    let message: String
    
    var body: some View {
        VStack {
            if show {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                        .background(.ultraThinMaterial)
                    
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: show)
                .onAppear {
                    HapticFeedback.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            show = false
                        }
                    }
                }
            }
            
            Spacer()
        }
        .animation(.spring(), value: show)
    }
}

// MARK: - Custom TextField Style with Liquid Glass
struct LiquidGlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .liquidGlassForm()
    }
}

// MARK: - Custom Button Styles with Liquid Glass
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isEnabled ?
                        [Color.blue, Color.blue.opacity(0.8)] :
                        [Color.gray, Color.gray.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticFeedback.light()
                }
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticFeedback.medium()
                }
            }
    }
}

// MARK: - Empty State View with Liquid Glass
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 200)
                .padding(.top)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
