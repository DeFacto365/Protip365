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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Top separator line - only in light mode
            if colorScheme == .light {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
            }

            HStack(spacing: isLargeDevice ? 24 : 8) {
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
                            // Individual circular glass buttons with depth
                            ZStack {
                                // No background for active state - clean iOS 26 look

                                Image(systemName: selectedTab == item.id ? item.activeIcon : item.icon)
                                    .font(.system(size: isLargeDevice ? 24 : 20, weight: selectedTab == item.id ? .semibold : .medium))
                                    .foregroundStyle(
                                        selectedTab == item.id ?
                                        .blue :
                                        Color.primary
                                    )
                                    .frame(width: isLargeDevice ? 40 : 32, height: isLargeDevice ? 40 : 32)
                                    .scaleEffect(selectedTab == item.id ? 1.15 : 1.0)
                                    .symbolEffect(.bounce, value: selectedTab == item.id)
                            }

                            // Labels with proper depth
                            Text(localizedLabel(for: item))
                                .font(.system(size: isLargeDevice ? 12 : 10, weight: selectedTab == item.id ? .semibold : .medium, design: .rounded))
                                .foregroundStyle(
                                    selectedTab == item.id ?
                                    .blue :
                                    Color.primary
                                )
                        }
                        .frame(minWidth: isLargeDevice ? 60 : 44, minHeight: isLargeDevice ? 60 : 50)
                        .frame(maxWidth: .infinity) // Fill available horizontal space
                        .multilineTextAlignment(.center)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                    .accessibilityLabel(localizedLabel(for: item))
                    .accessibilityAddTraits(selectedTab == item.id ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, isLargeDevice ? 24 : 16)
            .padding(.vertical, isLargeDevice ? 16 : 12)
            .padding(.bottom, safeAreaInsets.bottom > 0 ? (isLargeDevice ? -8 : -12) : -8)
        }
        .background(
            Group {
                if colorScheme == .dark {
                    // Completely transparent in dark mode - no background
                    Color.clear
                } else {
                    // Match page background in light mode
                    Color(.systemGroupedBackground)
                }
            }
            .ignoresSafeArea(.all)
        )
        .frame(maxWidth: .infinity)
        .clipped()
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: colorScheme == .dark ? 0 : 8, x: 0, y: colorScheme == .dark ? 0 : -2)
    }
    
    // Device size detection - only Pro Max models get large sizing
    private var isLargeDevice: Bool {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        // Only iPhone Pro Max models (not regular Pro models)
        // iPhone 14 Pro Max, 15 Pro Max, 16 Pro Max: 932 height
        // iPhone 12 Pro Max, 13 Pro Max: 926 height
        return screenHeight >= 926 && max(screenWidth, screenHeight) >= 932
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
            TabItem(id: "calendar", icon: "calendar.badge", label: "Calendar", activeIcon: "calendar.badge")
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
        ZStack {
            // Full screen background that extends to all edges
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)
                .zIndex(-1)

            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Content based on selected tab - no ScrollView wrapper needed as views handle their own scrolling
                    Group {
                        switch selectedTab {
                        case "dashboard":
                            DashboardView()
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
                            SettingsView(selectedTab: $selectedTab)
                        default:
                            DashboardView()
                        }
                    }
                    .frame(maxWidth: geometry.size.width)
                    .clipped() // Prevent content from extending beyond bounds
                    .zIndex(0) // Background content layer

                    // Floating translucent tab bar with proper depth
                    iOS26LiquidGlassTabBar(
                        selectedTab: $selectedTab,
                        scrollOffset: $scrollOffset,
                        tabItems: tabItems
                    )
                    .frame(maxWidth: geometry.size.width)
                    .zIndex(1) // Floating tab bar layer
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipped() // Ensure nothing extends beyond screen bounds
    }
}