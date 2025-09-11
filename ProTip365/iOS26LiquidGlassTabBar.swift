import SwiftUI

// Tab Item Structure
struct TabItem {
    let id: String
    let icon: String
    let label: String
    let activeIcon: String
}

// Scroll Tracking Components
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollOffsetReader: View {
    let coordinateSpace: String
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named(coordinateSpace)).minY
                )
        }
        .frame(height: 0)
    }
}

// iOS 26 Liquid Glass Tab Bar
struct iOS26LiquidGlassTabBar: View {
    @Binding var selectedTab: String
    @Binding var scrollOffset: CGFloat
    let tabItems: [TabItem]
    @AppStorage("language") private var language = "en"
    
    // Custom background to avoid SwiftUI material issues
    private var backgroundCapsule: some View {
        Capsule()
            .fill(Color.white.opacity(0.6))  // 60% white fill - more opaque
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.8), lineWidth: 1.0)  // 80% stroke - more visible border
            )
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabItems, id: \.id) { item in
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedTab = item.id
                    }
                }) {
                    VStack(spacing: 2) {
                        // Individual circular glass buttons
                        Image(systemName: selectedTab == item.id ? item.activeIcon : item.icon)
                            .font(.system(size: 18, weight: selectedTab == item.id ? .semibold : .medium))
                            .foregroundStyle(
                                selectedTab == item.id ? 
                                Color(hex: "0288FF") : // Same blue as Add/Shift button
                                Color.primary  // 100% opacity for icons
                            )
                            .frame(width: 32, height: 32)
                            .scaleEffect(selectedTab == item.id ? 1.1 : 1.0)
                            .symbolEffect(.bounce, value: selectedTab == item.id)
                        
                        // Labels with 100% opacity
                        Text(localizedLabel(for: item))
                            .font(.system(size: 9, weight: selectedTab == item.id ? .semibold : .medium, design: .rounded))
                            .foregroundStyle(
                                selectedTab == item.id ? 
                                Color(hex: "0288FF") : // Same blue as Add/Shift button
                                Color.primary  // 100% opacity for text
                            )
                    }
                    .frame(minWidth: 44) // iOS minimum touch target
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                .accessibilityLabel(localizedLabel(for: item))
                .accessibilityAddTraits(selectedTab == item.id ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundCapsule)  // Custom translucent background
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, safeAreaInsets.bottom > 0 ? -12 : -8)
    }
    
    // Safe area calculation
    private var safeAreaInsets: EdgeInsets {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return EdgeInsets(top: 44, leading: 0, bottom: 34, trailing: 0)
        }
        return EdgeInsets(
            top: window.safeAreaInsets.top,
            leading: window.safeAreaInsets.left,
            bottom: window.safeAreaInsets.bottom,
            trailing: window.safeAreaInsets.right
        )
    }
    
    // Localized labels
    private func localizedLabel(for item: TabItem) -> String {
        switch item.id {
        case "dashboard":
            switch language {
            case "fr": return "Tableau"
            case "es": return "Panel"
            default: return "Dashboard"
            }
        case "shifts":
            switch language {
            case "fr": return "Quarts"
            case "es": return "Turnos"
            default: return "Shifts"
            }
        case "calendar":
            switch language {
            case "fr": return "Calendrier"
            case "es": return "Calendario"
            default: return "Calendar"
            }
        case "employers":
            switch language {
            case "fr": return "Employeurs"
            case "es": return "Empleadores"
            default: return "Employers"
            }
        case "calculator":
            switch language {
            case "fr": return "Calculer"
            case "es": return "Calcular"
            default: return "Calculator"
            }
        case "settings":
            switch language {
            case "fr": return "Réglages"
            case "es": return "Ajustes"
            default: return "Settings"
            }
        default:
            return item.label
        }
    }
}

// Main View with iOS 26 Liquid Glass Implementation
struct iOS26LiquidGlassMainView: View {
    @State private var selectedTab = "dashboard"
    @State private var scrollOffset: CGFloat = 0
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false
    
    // Tab items based on app configuration
    private var tabItems: [TabItem] {
        var items = [
            TabItem(id: "dashboard", icon: "chart.bar", label: "Dashboard", activeIcon: "chart.bar.fill"),
            TabItem(id: "shifts", icon: "calendar", label: "Shifts", activeIcon: "calendar.circle.fill"),
            TabItem(id: "calendar", icon: "calendar.badge.clock", label: "Calendar", activeIcon: "calendar.badge.clock.fill")
        ]
        
        // Only add employers if enabled
        if useMultipleEmployers {
            items.append(TabItem(id: "employers", icon: "building.2", label: "Employers", activeIcon: "building.2.fill"))
        }
        
        items.append(contentsOf: [
            TabItem(id: "calculator", icon: "percent", label: "Calculator", activeIcon: "percent"),
            TabItem(id: "settings", icon: "gear", label: "Settings", activeIcon: "gear.circle.fill")
        ])
        
        return items
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background that shows through translucent controls
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.systemBackground).opacity(0.8),
                    Color.blue.opacity(0.1) // App's accent color
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content based on selected tab - no ScrollView wrapper needed as views handle their own scrolling
            Group {
                switch selectedTab {
                case "dashboard":
                    DashboardView()
                case "shifts":
                    ShiftsCalendarView()
                case "calendar":
                    CalendarShiftsView()
                case "employers":
                    if useMultipleEmployers {
                        EmployersView()
                    } else {
                        DashboardView()
                    }
                case "calculator":
                    TipCalculatorView()
                case "settings":
                    SettingsView()
                default:
                    DashboardView()
                }
            }
            
            // Floating translucent tab bar
            iOS26LiquidGlassTabBar(
                selectedTab: $selectedTab,
                scrollOffset: $scrollOffset,
                tabItems: tabItems
            )
        }
    }
}