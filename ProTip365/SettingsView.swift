import SwiftUI
import Supabase

struct SettingsView: View {
    @State private var defaultHourlyRate = ""
    @State private var targetDaily = ""
    @State private var targetWeekly = ""
    @State private var targetMonthly = ""
    @State private var showSignOutAlert = false
    @AppStorage("language") private var language = "en"
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(languageLabel, selection: $language) {
                        Text("English").tag("en")
                        Text("Français").tag("fr")
                        Text("Español").tag("es")
                    }
                } header: {
                    Text(languageSection)
                }
                
                Section {
                    HStack {
                        Text(hourlyRateLabel)
                        Spacer()
                        TextField("$15.00", text: $defaultHourlyRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } header: {
                    Text(defaultsSection)
                }
                
                Section {
                    HStack {
                        Text(dailyTargetLabel)
                        Spacer()
                        TextField("$100", text: $targetDaily)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text(weeklyTargetLabel)
                        Spacer()
                        TextField("$500", text: $targetWeekly)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text(monthlyTargetLabel)
                        Spacer()
                        TextField("$2000", text: $targetMonthly)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } header: {
                    Text(targetsSection)
                }
                
                Section {
                    Button(action: saveSettings) {
                        HStack {
                            Spacer()
                            Text(saveButton)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
                
                Section {
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Spacer()
                            Text(signOutButton)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(settingsTitle)
            .alert(signOutConfirmTitle, isPresented: $showSignOutAlert) {
                Button(cancelButton, role: .cancel) { }
                Button(signOutButton, role: .destructive) {
                    Task {
                        try? await SupabaseManager.shared.client.auth.signOut()
                    }
                }
            } message: {
                Text(signOutConfirmMessage)
            }
        }
        .task {
            await loadSettings()
        }
    }
    
    func loadSettings() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            let profile: [UserProfile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let userProfile = profile.first {
                defaultHourlyRate = String(format: "%.2f", userProfile.default_hourly_rate)
                targetDaily = String(format: "%.0f", userProfile.target_tip_daily)
                targetWeekly = String(format: "%.0f", userProfile.target_tip_weekly)
                targetMonthly = String(format: "%.0f", userProfile.target_tip_monthly)
            }
        } catch {
            print("Error loading settings: \(error)")
        }
    }
    
    func saveSettings() {
        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                
                struct ProfileUpdate: Encodable {
                    let default_hourly_rate: Double
                    let target_tip_daily: Double
                    let target_tip_weekly: Double
                    let target_tip_monthly: Double
                    let language: String
                }
                
                let updates = ProfileUpdate(
                    default_hourly_rate: Double(defaultHourlyRate) ?? 15.00,
                    target_tip_daily: Double(targetDaily) ?? 100,
                    target_tip_weekly: Double(targetWeekly) ?? 500,
                    target_tip_monthly: Double(targetMonthly) ?? 2000,
                    language: language
                )
                
                try await SupabaseManager.shared.client
                    .from("users_profile")
                    .update(updates)
                    .eq("user_id", value: userId)
                    .execute()
                
            } catch {
                print("Error saving settings: \(error)")
            }
        }
    }
    
    // Localization
    var settingsTitle: String {
        switch language {
        case "fr": return "Réglages"
        case "es": return "Ajustes"
        default: return "Settings"
        }
    }
    
    var languageSection: String {
        switch language {
        case "fr": return "Langue"
        case "es": return "Idioma"
        default: return "Language"
        }
    }
    
    var languageLabel: String {
        switch language {
        case "fr": return "Choisir la langue"
        case "es": return "Elegir idioma"
        default: return "Choose Language"
        }
    }
    
    var defaultsSection: String {
        switch language {
        case "fr": return "Valeurs par défaut"
        case "es": return "Valores predeterminados"
        default: return "Defaults"
        }
    }
    
    var hourlyRateLabel: String {
        switch language {
        case "fr": return "Taux horaire"
        case "es": return "Tarifa por hora"
        default: return "Hourly Rate"
        }
    }
    
    var targetsSection: String {
        switch language {
        case "fr": return "Objectifs de pourboires"
        case "es": return "Objetivos de propinas"
        default: return "Tip Targets"
        }
    }
    
    var dailyTargetLabel: String {
        switch language {
        case "fr": return "Objectif quotidien"
        case "es": return "Objetivo diario"
        default: return "Daily Target"
        }
    }
    
    var weeklyTargetLabel: String {
        switch language {
        case "fr": return "Objectif hebdomadaire"
        case "es": return "Objetivo semanal"
        default: return "Weekly Target"
        }
    }
    
    var monthlyTargetLabel: String {
        switch language {
        case "fr": return "Objectif mensuel"
        case "es": return "Objetivo mensual"
        default: return "Monthly Target"
        }
    }
    
    var saveButton: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save Settings"
        }
    }
    
    var signOutButton: String {
        switch language {
        case "fr": return "Déconnexion"
        case "es": return "Cerrar sesión"
        default: return "Sign Out"
        }
    }
    
    var signOutConfirmTitle: String {
        switch language {
        case "fr": return "Confirmer"
        case "es": return "Confirmar"
        default: return "Confirm"
        }
    }
    
    var signOutConfirmMessage: String {
        switch language {
        case "fr": return "Voulez-vous vraiment vous déconnecter?"
        case "es": return "¿Realmente quieres cerrar sesión?"
        default: return "Are you sure you want to sign out?"
        }
    }
    
    var cancelButton: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
}
