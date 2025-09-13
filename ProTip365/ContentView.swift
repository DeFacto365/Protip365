import SwiftUI
import Supabase

struct ContentView: View {
    @State private var isAuthenticated = false
    @StateObject private var biometricAuth = BiometricAuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false // Added to check setting
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        Group {
            // Check biometric lock first
            if biometricAuth.biometricEnabled && !biometricAuth.isUnlocked {
                LockScreenView(biometricAuth: biometricAuth)
            } else if isAuthenticated {
                // Check subscription status
              //  if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
                    mainAppView
                //} else {
                  //  SubscriptionView(subscriptionManager: subscriptionManager)
                //}
            } else {
                AuthView(isAuthenticated: $isAuthenticated)
            }
        }
        .task {
            print("🚀 ContentView task started - checking authentication...")
            await checkAuth()
            if biometricAuth.biometricEnabled && !biometricAuth.isUnlocked {
                biometricAuth.authenticate()
            }
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
    }
    
    func checkAuth() async {
        print("🔐 Checking existing authentication session...")

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            print("✅ Existing session found: \(session.user.id)")
            await MainActor.run {
                isAuthenticated = true
            }
        } catch {
            print("❌ No existing session found: \(error.localizedDescription)")
            await MainActor.run {
                isAuthenticated = false
            }
        }

        // Listen for auth state changes
        print("👂 Listening for auth state changes...")
        for await state in SupabaseManager.shared.client.auth.authStateChanges {
            print("🔄 Auth state changed: \(state.event)")
            if let session = state.session {
                print("   Session user: \(session.user.id)")
            } else {
                print("   No session")
            }
            await MainActor.run {
                isAuthenticated = state.session != nil
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
}

// Wrapper for SettingsView on iPad that doesn't need selectedTab
struct SettingsViewWrapper: View {
    @State private var dummySelectedTab = "settings"

    var body: some View {
        SettingsView(selectedTab: $dummySelectedTab)
    }
}
