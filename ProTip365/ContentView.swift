import SwiftUI
import Supabase

struct ContentView: View {
    @State private var isAuthenticated = false
    @StateObject private var securityManager = SecurityManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var alertManager = AlertManager()
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false // Added to check setting
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            // Full screen background that extends to all edges
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)

            Group {
                // Check security lock first
                if securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                    EnhancedLockScreenView(securityManager: securityManager)
                } else if isAuthenticated {
                    // Show loading or main view while checking subscription
                    if subscriptionManager.isCheckingSubscription {
                        // Show main app view while checking (prevents flash)
                        mainAppView
                            .disabled(true)
                            .overlay(
                                Color.black.opacity(0.3)
                                    .ignoresSafeArea()
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.5)
                                            .tint(.white)
                                    )
                            )
                    } else if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
                        mainAppView
                    } else {
                        SubscriptionView(subscriptionManager: subscriptionManager)
                    }
                } else {
                    AuthView(isAuthenticated: $isAuthenticated)
                }
            }
        }
        .task {
            await checkAuth()
            if securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                securityManager.authenticate()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
            isAuthenticated = false
            securityManager.isUnlocked = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidDeleteAccount)) { _ in
            isAuthenticated = false
            securityManager.isUnlocked = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // If security is enabled and app is locked, trigger authentication
                if securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                    securityManager.authenticate()
                }

                // Refresh subscription status when app becomes active
                Task {
                    await subscriptionManager.refreshSubscriptionStatus()
                }
            case .inactive:
                // Lock the app when it becomes inactive
                if securityManager.currentSecurityType != .none {
                    securityManager.isUnlocked = false
                    securityManager.showPINEntry = false
                }
            case .background:
                // Also lock when entering background
                if securityManager.currentSecurityType != .none {
                    securityManager.isUnlocked = false
                    securityManager.showPINEntry = false
                }
            @unknown default:
                break
            }
        }
    }

    // Localization
    var dashboardTab: String {
        switch language {
        case "fr": return "Tableau"
        case "es": return "Panel"
        default: return "Dashboard"
        }
    }

    var calendarTab: String {
        switch language {
        case "fr": return "Calendrier"
        case "es": return "Calendario"
        default: return "Calendar"
        }
    }

    var employersTab: String {
        switch language {
        case "fr": return "Employeurs"
        case "es": return "Empleadores"
        default: return "Employers"
        }
    }

    var calculatorTab: String {
        switch language {
        case "fr": return "Calculer"
        case "es": return "Calcular"
        default: return "Calculator"
        }
    }

    var settingsTab: String {
        switch language {
        case "fr": return "Réglages"
        case "es": return "Ajustes"
        default: return "Settings"
        }
    }

    var mainAppView: some View {
        Group {
            if sizeClass == .regular {
                // iPad Layout - Use sidebar navigation
                NavigationSplitView {
                    List {
                        NavigationLink(destination: DashboardView()) {
                            Label(dashboardTab, systemImage: "chart.bar")
                        }

                        NavigationLink(destination: CalendarShiftsView()) {
                            Label(calendarTab, systemImage: "calendar")
                        }

                        // Only show Employers if enabled
                        if useMultipleEmployers {
                            NavigationLink(destination: EmployersView()) {
                                Label(employersTab, systemImage: "building.2")
                            }
                        }

                        NavigationLink(destination: TipCalculatorView()) {
                            Label(calculatorTab, systemImage: "percent")
                        }
                        NavigationLink(destination: SettingsViewWrapper()) {
                            Label(settingsTab, systemImage: "gear")
                        }
                    }
                    .navigationTitle("ProTip365")
                    .listStyle(.sidebar)
                } detail: {
                    DashboardView()
                }
            } else {
                // iPhone Layout - Use Liquid Glass Navigation
                iOS26LiquidGlassMainView()
            }
        }
        .environmentObject(subscriptionManager)
        .environmentObject(SupabaseManager.shared)
        .environmentObject(alertManager)
        .alert(alertManager.currentAlert?.title ?? "", isPresented: $alertManager.showAlert) {
            Button("OK") {
                if let alert = alertManager.currentAlert {
                    alertManager.clearAlert(alert)
                }
            }
            if let alert = alertManager.currentAlert, !alert.action.isEmpty {
                Button(alert.action) {
                    handleAlertAction(alert)
                    alertManager.clearAlert(alert)
                }
            }
        } message: {
            if let alert = alertManager.currentAlert {
                Text(alert.message)
            }
        }
    }

    func handleAlertAction(_ alert: AppAlert) {
        switch alert.type {
        case .missingShift, .incompleteShift:
            break
        case .targetAchieved, .personalBest:
            break
        case .reminder:
            break
        }
    }

    func checkAuth() async {
        do {
            _ = try await SupabaseManager.shared.client.auth.session
            await MainActor.run {
                isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                isAuthenticated = false
            }
        }

        // Listen for auth state changes
        for await state in SupabaseManager.shared.client.auth.authStateChanges {
            await MainActor.run {
                isAuthenticated = state.session != nil
            }
        }
    }
}

// Wrapper for SettingsView on iPad that doesn't need selectedTab
struct SettingsViewWrapper: View {
    @State private var dummySelectedTab = "settings"

    var body: some View {
        SettingsView(selectedTab: $dummySelectedTab)
    }
}
