import SwiftUI

// MARK: - ProTip365 Design System
// This file contains the complete design system for ProTip365
// to ensure UI/UX consistency across all platforms (iOS and future Android)

// MARK: - Icon Guidelines (Following Apple HIG)
// 1. Use SF Symbols exclusively for system icons
// 2. Use hierarchical or monochrome rendering for better visual hierarchy
// 3. Use semantic colors (.primary, .secondary) for automatic dark mode support
// 4. Use consistent weights: .regular for inactive, .semibold for active states
// 5. Use filled variants for selected states (e.g., chart.bar → chart.bar.fill)
// 6. Apply symbolEffect for interactive feedback when appropriate

// MARK: - Color Palette

extension Color {
    // MARK: - Primary Colors
    static let primaryBlue = Color.blue
    static let primaryPurple = Color.purple
    static let primaryGreen = Color.green
    static let primaryRed = Color.red
    static let primaryOrange = Color.orange
    static let primaryYellow = Color.yellow

    // MARK: - Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue

    // MARK: - Text Colors (Dark Mode Adaptive)
    // Note: Always use these semantic colors instead of hardcoded colors like Color.black
    // They automatically adapt between light and dark modes following Apple's HIG
    static let textPrimary = Color.primary  // Use for main text content
    static let textSecondary = Color.secondary  // Use for supporting text
    static let textTertiary = Color(.tertiaryLabel)  // Use for less important text
    static let textPlaceholder = Color(.placeholderText)  // Use for placeholder text

    // MARK: - Surface Colors (Dark Mode Adaptive)
    static let surfacePrimary = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
    static let surfaceTertiary = Color(.tertiarySystemBackground)
    static let surfaceGrouped = Color(.systemGroupedBackground)
    static let surfaceSecondaryGrouped = Color(.secondarySystemGroupedBackground)

    // MARK: - Achievement Colors
    static let achievementGold = Color.yellow
    static let achievementSilver = Color.gray
    static let achievementBronze = Color.orange
    static let achievementSpecial = Color.purple
}

// MARK: - Typography System

struct Typography {
    // MARK: - Font Weights
    static let light = Font.Weight.light
    static let regular = Font.Weight.regular
    static let medium = Font.Weight.medium
    static let semibold = Font.Weight.semibold
    static let bold = Font.Weight.bold

    // MARK: - Font Styles
    static let largeTitle = Font.largeTitle
    static let title1 = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let caption2 = Font.caption2
    static let footnote = Font.footnote

    // MARK: - Custom Font Combinations
    static let heroTitle = Font.largeTitle.weight(.bold)
    static let cardTitle = Font.headline.weight(.semibold)
    static let cardSubtitle = Font.subheadline.weight(.medium)
    static let buttonText = Font.body.weight(.semibold)
    static let tabBarText = Font.caption.weight(.medium)
    static let statisticValue = Font.title2.weight(.bold)
    static let statisticLabel = Font.caption.weight(.medium)
}

// MARK: - Spacing System

struct Spacing {
    // Base spacing unit (4pt grid system)
    static let unit: CGFloat = 4

    // MARK: - Standard Spacing Values
    static let xs: CGFloat = 2      // 2pt
    static let sm: CGFloat = 4      // 4pt
    static let md: CGFloat = 8      // 8pt
    static let lg: CGFloat = 12     // 12pt
    static let xl: CGFloat = 16     // 16pt
    static let xxl: CGFloat = 20    // 20pt
    static let xxxl: CGFloat = 24   // 24pt
    static let xxxxl: CGFloat = 32  // 32pt

    // MARK: - Component Specific Spacing
    static let buttonPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let formFieldSpacing: CGFloat = 12
    static let listItemSpacing: CGFloat = 8
    static let tabBarPadding: CGFloat = 20

    // MARK: - Layout Spacing
    static let screenPadding: CGFloat = 20
    static let safeAreaPadding: CGFloat = 30
    static let leadingContentInset: CGFloat = 26
}

// MARK: - Border Radius System

struct BorderRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let round: CGFloat = 50  // For circular elements

    // MARK: - Component Specific Radius
    static let button = md          // 12pt
    static let card = lg           // 16pt
    static let form = sm           // 8pt
    static let tabBar = xl         // 20pt
    static let sheet = lg          // 16pt
}

// MARK: - Icon System

struct Icons {
    // MARK: - Icon Sizes (Following Apple HIG)
    static let small: Font = .caption2          // ~11pt
    static let medium: Font = .body             // ~17pt
    static let large: Font = .title3            // ~20pt
    static let xlarge: Font = .title2           // ~22pt
    static let xxlarge: Font = .largeTitle      // ~34pt

    // MARK: - Tab Bar Icons
    static let tabBarSize: Font = .system(size: 20, weight: .regular)
    static let tabBarSizeActive: Font = .system(size: 20, weight: .semibold)

    // MARK: - Button Icons
    static let buttonIcon: Font = .body
    static let navigationIcon: Font = .body

    // MARK: - Dashboard Icons
    static let statCardIcon: Font = .title3
    static let emptyStateIcon: Font = .system(size: 48)
}

// MARK: - Shadow System

struct Shadows {
    static let light = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    static let heavy = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    static let card = Shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    static let button = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Button Style System

struct PrimaryButton: ButtonStyle {
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.buttonText)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.buttonPadding)
            .background(
                LinearGradient(
                    colors: isEnabled ? [.primaryBlue, .primaryBlue.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.button))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
}

struct SecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.buttonText.weight(.medium))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.buttonPadding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.button)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.buttonText)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.buttonPadding)
            .background(Color.error)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.button))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButton: ButtonStyle {
    let color: Color

    init(color: Color = .primaryBlue) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundColor(color)
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Styles

struct GlassCard: ViewModifier {
    let padding: CGFloat

    init(padding: CGFloat = Spacing.cardPadding) {
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.card, style: .continuous))
            .shadow(
                color: Shadows.card.color,
                radius: Shadows.card.radius,
                x: Shadows.card.x,
                y: Shadows.card.y
            )
    }
}

struct StatCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.cardPadding)
            .frame(minHeight: 100)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.card, style: .continuous))
            .shadow(
                color: Shadows.card.color,
                radius: Shadows.card.radius,
                x: Shadows.card.x,
                y: Shadows.card.y
            )
    }
}

// MARK: - Text Field Style

struct ProTipTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Typography.body)
            .padding(Spacing.lg)
            .background(Color.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.form))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.form)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
    }
}

// MARK: - Extensions for Easy Usage

extension View {
    // MARK: - Card Modifiers
    func glassCard(padding: CGFloat = Spacing.cardPadding) -> some View {
        modifier(GlassCard(padding: padding))
    }

    func statCard() -> some View {
        modifier(StatCard())
    }

    // MARK: - Button Styles
    func primaryButton(isEnabled: Bool = true) -> some View {
        buttonStyle(PrimaryButton(isEnabled: isEnabled))
    }

    func secondaryButton() -> some View {
        buttonStyle(SecondaryButton())
    }

    func destructiveButton() -> some View {
        buttonStyle(DestructiveButton())
    }

    func iconButton(color: Color = .primaryBlue) -> some View {
        buttonStyle(IconButton(color: color))
    }

    // MARK: - Text Field Style
    func proTipTextFieldStyle() -> some View {
        textFieldStyle(ProTipTextFieldStyle())
    }

    // MARK: - Common Layout Modifiers
    func screenPadding() -> some View {
        padding(.horizontal, Spacing.screenPadding)
    }

    func sectionSpacing() -> some View {
        padding(.bottom, Spacing.sectionSpacing)
    }

    // MARK: - Typography Helpers
    func heroTitle() -> some View {
        font(Typography.heroTitle)
    }

    func cardTitle() -> some View {
        font(Typography.cardTitle)
    }

    func cardSubtitle() -> some View {
        font(Typography.cardSubtitle)
    }

    func statisticValue() -> some View {
        font(Typography.statisticValue)
    }

    func statisticLabel() -> some View {
        font(Typography.statisticLabel)
    }

    // MARK: - Color Helpers
    func primaryText() -> some View {
        foregroundColor(.textPrimary)
    }

    func secondaryText() -> some View {
        foregroundColor(.textSecondary)
    }

    func tertiaryText() -> some View {
        foregroundColor(.textTertiary)
    }

    func successColor() -> some View {
        foregroundColor(.success)
    }

    func errorColor() -> some View {
        foregroundColor(.error)
    }

    func warningColor() -> some View {
        foregroundColor(.warning)
    }
}

// MARK: - Animation System

struct Animations {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.6)
}

// MARK: - Icon Names

struct IconNames {
    // MARK: - Navigation Icons
    static let dashboard = "chart.bar"
    static let employers = "building.2"
    static let calculator = "percent"
    static let settings = "gear"
    static let calendar = "calendar"

    // MARK: - Action Icons
    static let add = "plus"
    static let edit = "pencil"
    static let delete = "trash"
    static let share = "square.and.arrow.up"
    static let export = "arrow.up.doc"
    static let save = "checkmark"
    static let cancel = "xmark"

    // MARK: - Status Icons
    static let success = "checkmark.circle.fill"
    static let error = "xmark.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let info = "info.circle.fill"
    static let loading = "hourglass"

    // MARK: - Data Icons
    static let money = "dollarsign.circle"
    static let tips = "banknote.fill"
    static let hours = "clock.badge"
    static let sales = "dollarsign.circle"
    static let income = "dollarsign.bank.building"

    // MARK: - Security Icons
    static let lock = "lock.fill"
    static let unlock = "lock.open"
    static let faceID = "faceid"
    static let touchID = "touchid"
    static let pin = "key"

    // MARK: - Achievement Icons
    static let star = "star.fill"
    static let crown = "crown.fill"
    static let target = "target"
    static let trophy = "trophy.fill"

    // MARK: - Communication Icons
    static let notification = "bell"
    static let notificationBadge = "bell.fill"
    static let email = "envelope"
    static let support = "questionmark.circle"
    static let idea = "lightbulb"
}

// MARK: - Layout System

struct Layout {
    // MARK: - Grid System
    static let columns2 = Array(repeating: GridItem(.flexible()), count: 2)
    static let columns3 = Array(repeating: GridItem(.flexible()), count: 3)
    static let columns4 = Array(repeating: GridItem(.flexible()), count: 4)

    // MARK: - Fixed Sizes
    static let buttonHeight: CGFloat = 50
    static let tabBarHeight: CGFloat = 80
    static let navigationBarHeight: CGFloat = 44
    static let cardMinHeight: CGFloat = 100
    static let formFieldHeight: CGFloat = 44
    static let iconSize: CGFloat = 24
    static let avatarSize: CGFloat = 40

    // MARK: - Responsive Breakpoints
    static let compactWidth: CGFloat = 375
    static let regularWidth: CGFloat = 768
    static let largeWidth: CGFloat = 1024
}

// MARK: - Usage Guidelines

/*
 USAGE GUIDELINES FOR UI/UX CONSISTENCY:

 1. COLORS:
    - Use semantic colors (.success, .error, .warning) for status indicators
    - Use .textPrimary, .textSecondary for text hierarchy
    - Use .surfacePrimary, .surfaceSecondary for backgrounds

 2. TYPOGRAPHY:
    - Use Typography constants for consistent font sizing
    - Use .heroTitle() for page titles
    - Use .cardTitle() and .cardSubtitle() for cards
    - Use .statisticValue() and .statisticLabel() for numbers

 3. SPACING:
    - Use Spacing constants (xs, sm, md, lg, xl) for all spacing
    - Use .screenPadding() for consistent screen margins
    - Use .sectionSpacing() between major sections

 4. BUTTONS:
    - Use .primaryButton() for main actions
    - Use .secondaryButton() for alternative actions
    - Use .destructiveButton() for delete/dangerous actions
    - Use .iconButton() for icon-only actions

 5. CARDS:
    - Use .glassCard() for standard card appearance
    - Use .statCard() for statistic displays

 6. ANIMATIONS:
    - Use Animations.quick for micro-interactions
    - Use Animations.spring for natural movements
    - Keep animations consistent across similar interactions

 7. ICONS:
    - Use Icons constants for consistent iconography
    - Maintain 24pt icon size for most use cases
    - Use semantic icon names that match their purpose

 8. LAYOUT:
    - Follow 4pt grid system using Spacing.unit
    - Use Layout constants for fixed dimensions
    - Maintain consistent component heights
*/