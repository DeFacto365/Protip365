import SwiftUI
import Supabase

struct ContentView: View {
    @State private var isAuthenticated = false
    @AppStorage("language") private var language = "en"
    
    var body: some View {
        Group {
            if isAuthenticated {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label(dashboardTab, systemImage: "chart.bar")
                        }
                    
                    ShiftEntryView()
                        .tabItem {
                            Label(addShiftTab, systemImage: "plus.circle.fill")
                        }
                    
                    EmployersView()
                        .tabItem {
                            Label(employersTab, systemImage: "building.2")
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
            } else {
                AuthView(isAuthenticated: $isAuthenticated)
            }
        }
        .task {
            await checkAuth()
        }
    }
    
    func checkAuth() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
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
        case "fr": return "Ajouter"
        case "es": return "Agregar"
        default: return "Add Shift"
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
