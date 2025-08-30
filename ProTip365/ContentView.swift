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
                        NavigationLink(destination: ShiftsCalendarView()) {
                            Label(addShiftTab, systemImage: "plus.circle.fill")
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
                        NavigationLink(destination: SettingsView()) {
                            Label(settingsTab, systemImage: "gear")
                        }
                    }
                    .navigationTitle("ProTip365")
                    .listStyle(.sidebar)
                } detail: {
                    DashboardView()
                }
            } else {
                // iPhone Layout - Keep tab bar
                TabView {
                    DashboardView()
                        .tabItem {
                            Label(dashboardTab, systemImage: "chart.bar")
                        }
                    
                    ShiftsCalendarView()
                        .tabItem {
                            Label(addShiftTab, systemImage: "calendar")
                        }
                    
                    // Only show Employers tab if enabled
                    if useMultipleEmployers {
                        EmployersView()
                            .tabItem {
                                Label(employersTab, systemImage: "building.2")
                            }
                    }
                    
                    TipCalculatorView()
                        .tabItem {
                            Label(calculatorTab, systemImage: "percent")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label(settingsTab, systemImage: "gear")
                        }
                }
            }
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
    
    // Localization
    var dashboardTab: String {
        switch language {
        case "fr": return "Tableau"
        case "es": return "Panel"
        default: return "Dashboard"
        }
    }
    
    var addShiftTab: String {
        switch language {
        case "fr": return "Quarts"
        case "es": return "Turnos"
        default: return "Shifts"
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
