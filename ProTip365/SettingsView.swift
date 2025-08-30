import SwiftUI
import Supabase

struct SettingsView: View {
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var defaultHourlyRate = ""
    @State private var targetDaily = ""
    @State private var targetWeekly = ""
    @State private var targetMonthly = ""
    @State private var targetSalesDaily = ""
    @State private var targetSalesWeekly = ""
    @State private var targetSalesMonthly = ""
    @State private var targetHoursDaily = ""
    @State private var targetHoursWeekly = ""
    @State private var targetHoursMonthly = ""
    @State private var weekStartDay = 0 // 0 = Sunday, 1 = Monday, etc.
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showSuggestIdeas = false
    @State private var suggestionText = ""
    @State private var showingSuggestSuccess = false
    @State private var isSendingSuggestion = false
    @State private var showingSaveSuccess = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @AppStorage("language") private var language = "en"
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    
    let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // User Info Card
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text(userName.isEmpty ? "User" : userName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassCard()
                    .padding(.horizontal)
                    
                    // Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Name", systemImage: "person.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Your name", text: $userName)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // Language Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label(languageSection, systemImage: "globe")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Picker(languageLabel, selection: $language) {
                            Text("English").tag("en")
                            Text("Français").tag("fr")
                            Text("Español").tag("es")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // Work Defaults Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(defaultsSection, systemImage: "briefcase.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label(hourlyRateLabel, systemImage: "dollarsign.circle")
                            Spacer()
                            TextField("15.00", text: $defaultHourlyRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .onTapGesture {
                                    if defaultHourlyRate == "15.00" || defaultHourlyRate == "0.00" {
                                        defaultHourlyRate = ""
                                    }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label(weekStartLabel, systemImage: "calendar")
                            Picker(weekStartLabel, selection: $weekStartDay) {
                                ForEach(0..<7) { index in
                                    Text(localizedWeekDay(index)).tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // Tip Targets Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(tipTargetsSection, systemImage: "banknote.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        targetRow(label: dailyTargetLabel,
                                  icon: "calendar.day.timeline.left",
                                  value: $targetDaily,
                                  placeholder: "100.00",
                                  color: .green)
                        
                        targetRow(label: weeklyTargetLabel,
                                  icon: "calendar.badge.clock",
                                  value: $targetWeekly,
                                  placeholder: "500.00",
                                  color: .blue)
                        
                        targetRow(label: monthlyTargetLabel,
                                  icon: "calendar",
                                  value: $targetMonthly,
                                  placeholder: "2000.00",
                                  color: .purple)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // Sales Targets Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(salesTargetsSection, systemImage: "cart.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        targetRow(label: dailySalesTargetLabel,
                                  icon: "chart.line.uptrend.xyaxis",
                                  value: $targetSalesDaily,
                                  placeholder: "500.00",
                                  color: .orange)
                        
                        targetRow(label: weeklySalesTargetLabel,
                                  icon: "chart.bar.fill",
                                  value: $targetSalesWeekly,
                                  placeholder: "3500.00",
                                  color: .orange)
                        
                        targetRow(label: monthlySalesTargetLabel,
                                  icon: "chart.pie.fill",
                                  value: $targetSalesMonthly,
                                  placeholder: "14000.00",
                                  color: .orange)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // Hours Targets Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(hoursTargetsSection, systemImage: "clock.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        targetRow(label: dailyHoursTargetLabel,
                                  icon: "timer",
                                  value: $targetHoursDaily,
                                  placeholder: "8",
                                  color: .indigo,
                                  isHours: true)
                        
                        targetRow(label: weeklyHoursTargetLabel,
                                  icon: "timer.circle.fill",
                                  value: $targetHoursWeekly,
                                  placeholder: "40",
                                  color: .indigo,
                                  isHours: true)
                        
                        targetRow(label: monthlyHoursTargetLabel,
                                  icon: "hourglass",
                                  value: $targetHoursMonthly,
                                  placeholder: "160",
                                  color: .indigo,
                                  isHours: true)
                    }
                    .padding()
                    .glassCard()
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: saveSettings) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text(saveButton)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal)
                    
                    // Support & Feedback Section
                    VStack(spacing: 12) {
                        // Support Button with availability check
                        if UIApplication.shared.canOpenURL(URL(string: "mailto:")!) {
                            Link(destination: URL(string: "mailto:support@protip365.com?subject=ProTip365%20Support%20Request")!) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.blue)
                                    Text(supportButton)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.forward.square")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .glassCard()
                            }
                            .padding(.horizontal)
                        } else {
                            // Fallback for simulator - just show the email address
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(supportButton)
                                        .foregroundColor(.primary)
                                    Text("support@protip365.com")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .glassCard()
                            .padding(.horizontal)
                        }
                        
                        // Feedback Button
                        Button(action: { showSuggestIdeas = true }) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                Text(suggestIdeasButton)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .glassCard()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Sign Out Button
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text(signOutButton)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Delete Account Button
                    Button(action: { showDeleteAccountAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text(deleteAccountButton)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, -10)
                    
                    // Clean bottom spacing - no version text
                    Spacer()
                        .frame(height: 30)
                }
                .padding(.vertical)
                .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .symbolRenderingMode(.hierarchical)
                }
            }
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
            .alert(deleteAccountConfirmTitle, isPresented: $showDeleteAccountAlert) {
                Button(cancelButton, role: .cancel) { }
                Button(deleteAccountButton, role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text(deleteAccountConfirmMessage)
            }
            .alert(saveSuccessTitle, isPresented: $showingSaveSuccess) {
                Button("OK") { }
            } message: {
                Text(saveSuccessMessage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showSuggestIdeas) {
                NavigationStack {
                    Form {
                        Section {
                            TextEditor(text: $suggestionText)
                                .frame(minHeight: 150)
                        } header: {
                            Text(yourSuggestionHeader)
                        } footer: {
                            Text(suggestionFooter)
                        }
                        
                        Section {
                            Button(action: sendSuggestion) {
                                HStack {
                                    Spacer()
                                    if isSendingSuggestion {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(sendSuggestionButton)
                                            .fontWeight(.semibold)
                                    }
                                    Spacer()
                                }
                            }
                            .disabled(suggestionText.isEmpty || isSendingSuggestion)
                        }
                    }
                    .navigationTitle(suggestIdeasTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(cancelButton) {
                                showSuggestIdeas = false
                                suggestionText = ""
                            }
                        }
                    }
                    .alert(successTitle, isPresented: $showingSuggestSuccess) {
                        Button("OK") {
                            showSuggestIdeas = false
                            suggestionText = ""
                        }
                    } message: {
                        Text(thankYouMessage)
                    }
                }
            }
        }
        .task {
            await loadUserInfo()
            await loadSettings()
        }
    }
    
    @ViewBuilder
    func targetRow(label: String, icon: String, value: Binding<String>, placeholder: String, color: Color, isHours: Bool = false) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(color)
            Spacer()
            TextField(placeholder, text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .onTapGesture {
                    if value.wrappedValue == "0" || value.wrappedValue == "0.00" || value.wrappedValue == "0.0" {
                        value.wrappedValue = ""
                    }
                }
        }
    }
    
    func loadUserInfo() async {
        do {
            let user = try await SupabaseManager.shared.client.auth.session.user
            await MainActor.run {
                userEmail = user.email ?? ""
                if let email = user.email {
                    let components = email.split(separator: "@")
                    if let firstPart = components.first {
                        let nameString = String(firstPart)
                        let cleanName = nameString
                            .replacingOccurrences(of: "_", with: " ")
                            .components(separatedBy: CharacterSet.decimalDigits)
                            .first ?? nameString
                        userName = cleanName
                            .trimmingCharacters(in: .whitespaces)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
                            .capitalized
                    }
                }
            }
        } catch {
            print("Error loading user info: \(error)")
        }
    }
    
    func loadSettings() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct Profile: Decodable {
                let default_hourly_rate: Double
                let target_tip_daily: Double
                let target_tip_weekly: Double
                let target_tip_monthly: Double
                let target_sales_daily: Double?
                let target_sales_weekly: Double?
                let target_sales_monthly: Double?
                let target_hours_daily: Double?
                let target_hours_weekly: Double?
                let target_hours_monthly: Double?
                let week_start: Int?
                let name: String?
            }
            
            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let userProfile = profiles.first {
                if let savedName = userProfile.name, !savedName.isEmpty {
                    userName = savedName
                }
                
                defaultHourlyRate = userProfile.default_hourly_rate > 0 ? String(format: "%.2f", userProfile.default_hourly_rate) : ""
                targetDaily = userProfile.target_tip_daily > 0 ? String(format: "%.2f", userProfile.target_tip_daily) : ""
                targetWeekly = userProfile.target_tip_weekly > 0 ? String(format: "%.2f", userProfile.target_tip_weekly) : ""
                targetMonthly = userProfile.target_tip_monthly > 0 ? String(format: "%.2f", userProfile.target_tip_monthly) : ""
                targetSalesDaily = (userProfile.target_sales_daily ?? 0) > 0 ? String(format: "%.2f", userProfile.target_sales_daily ?? 0) : ""
                targetSalesWeekly = (userProfile.target_sales_weekly ?? 0) > 0 ? String(format: "%.2f", userProfile.target_sales_weekly ?? 0) : ""
                targetSalesMonthly = (userProfile.target_sales_monthly ?? 0) > 0 ? String(format: "%.2f", userProfile.target_sales_monthly ?? 0) : ""
                targetHoursDaily = (userProfile.target_hours_daily ?? 0) > 0 ? String(format: "%.0f", userProfile.target_hours_daily ?? 0) : ""
                targetHoursWeekly = (userProfile.target_hours_weekly ?? 0) > 0 ? String(format: "%.0f", userProfile.target_hours_weekly ?? 0) : ""
                targetHoursMonthly = (userProfile.target_hours_monthly ?? 0) > 0 ? String(format: "%.0f", userProfile.target_hours_monthly ?? 0) : ""
                weekStartDay = userProfile.week_start ?? 0
            }
        } catch {
            print("Error loading settings: \(error)")
        }
    }
    
    func saveSettings() {
        isSaving = true
        
        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                
                struct ProfileUpdate: Encodable {
                    let default_hourly_rate: Double
                    let target_tip_daily: Double
                    let target_tip_weekly: Double
                    let target_tip_monthly: Double
                    let target_sales_daily: Double
                    let target_sales_weekly: Double
                    let target_sales_monthly: Double
                    let target_hours_daily: Double
                    let target_hours_weekly: Double
                    let target_hours_monthly: Double
                    let language: String
                    let week_start: Int
                    let name: String?
                }
                
                let updates = ProfileUpdate(
                    default_hourly_rate: Double(defaultHourlyRate) ?? 15.00,
                    target_tip_daily: Double(targetDaily) ?? 0,
                    target_tip_weekly: Double(targetWeekly) ?? 0,
                    target_tip_monthly: Double(targetMonthly) ?? 0,
                    target_sales_daily: Double(targetSalesDaily) ?? 0,
                    target_sales_weekly: Double(targetSalesWeekly) ?? 0,
                    target_sales_monthly: Double(targetSalesMonthly) ?? 0,
                    target_hours_daily: Double(targetHoursDaily) ?? 0,
                    target_hours_weekly: Double(targetHoursWeekly) ?? 0,
                    target_hours_monthly: Double(targetHoursMonthly) ?? 0,
                    language: language,
                    week_start: weekStartDay,
                    name: userName.isEmpty ? nil : userName
                )
                
                try await SupabaseManager.shared.client
                    .from("users_profile")
                    .update(updates)
                    .eq("user_id", value: userId)
                    .execute()
                
                UserDefaults.standard.set(Double(defaultHourlyRate) ?? 15.00, forKey: "defaultHourlyRate")
                
                await MainActor.run {
                    isSaving = false
                    showingSaveSuccess = true
                    
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    showError = true
                }
                print("Error saving settings: \(error)")
            }
        }
    }
    
    func deleteAccount() {
        isDeletingAccount = true
        
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let token = session.accessToken
                
                guard let url = URL(string: "https://ebffiippfaebdaaddbo-a4bo.supabase.co/functions/v1/delete-account") else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        await MainActor.run {
                            isDeletingAccount = false
                        }
                    } else {
                        struct ErrorResponse: Decodable {
                            let success: Bool
                            let error: String?
                        }
                        
                        let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                        let errorMessage = errorData?.error ?? "Failed to delete account"
                        
                        await MainActor.run {
                            isDeletingAccount = false
                            self.errorMessage = errorMessage
                            showError = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    func sendSuggestion() {
        guard !suggestionText.isEmpty else { return }
        
        isSendingSuggestion = true
        
        Task {
            do {
                let userEmail = try await SupabaseManager.shared.client.auth.session.user.email ?? "Unknown"
                
                let url = URL(string: "https://api.resend.com/emails")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer re_AAy3MDpT_LcKgzmGMquUXojtuhbVBoCGp", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let emailData = [
                    "from": "ProTip365 <feedback@protip365.com>",
                    "to": ["web@florabump.com"],
                    "subject": "ProTip365 - New Suggestion",
                    "html": """
                        <h2>New Suggestion from ProTip365</h2>
                        <p><strong>From:</strong> \(userEmail)</p>
                        <p><strong>Date:</strong> \(Date().formatted())</p>
                        <hr>
                        <p><strong>Suggestion:</strong></p>
                        <p>\(suggestionText.replacingOccurrences(of: "\n", with: "<br>"))</p>
                    """
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    await MainActor.run {
                        isSendingSuggestion = false
                        showingSuggestSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showSuggestIdeas = false
                            suggestionText = ""
                        }
                    }
                } else {
                    await MainActor.run {
                        isSendingSuggestion = false
                    }
                }
            } catch {
                await MainActor.run {
                    isSendingSuggestion = false
                }
                print("Error sending suggestion: \(error)")
            }
        }
    }
    
    func localizedWeekDay(_ index: Int) -> String {
        switch language {
        case "fr":
            return ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"][index]
        case "es":
            return ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"][index]
        default:
            return weekDays[index]
        }
    }
    
    // All localization properties
    var supportButton: String {
        switch language {
        case "fr": return "Support"
        case "es": return "Soporte"
        default: return "Support"
        }
    }
    
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
        default: return "Work Defaults"
        }
    }
    
    var hourlyRateLabel: String {
        switch language {
        case "fr": return "Taux horaire"
        case "es": return "Tarifa por hora"
        default: return "Hourly Rate"
        }
    }
    
    var weekStartLabel: String {
        switch language {
        case "fr": return "Début de semaine"
        case "es": return "Inicio de semana"
        default: return "Week starts on"
        }
    }
    
    var tipTargetsSection: String {
        switch language {
        case "fr": return "Objectifs de pourboires"
        case "es": return "Objetivos de propinas"
        default: return "Tip Targets"
        }
    }
    
    var salesTargetsSection: String {
        switch language {
        case "fr": return "Objectifs de ventes"
        case "es": return "Objetivos de ventas"
        default: return "Sales Targets"
        }
    }
    
    var hoursTargetsSection: String {
        switch language {
        case "fr": return "Objectifs d'heures"
        case "es": return "Objetivos de horas"
        default: return "Hours Targets"
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
    
    var dailySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes quotidiennes"
        case "es": return "Ventas diarias"
        default: return "Daily Sales"
        }
    }
    
    var weeklySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes hebdomadaires"
        case "es": return "Ventas semanales"
        default: return "Weekly Sales"
        }
    }
    
    var monthlySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes mensuelles"
        case "es": return "Ventas mensuales"
        default: return "Monthly Sales"
        }
    }
    
    var dailyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures quotidiennes"
        case "es": return "Horas diarias"
        default: return "Daily Hours"
        }
    }
    
    var weeklyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures hebdomadaires"
        case "es": return "Horas semanales"
        default: return "Weekly Hours"
        }
    }
    
    var monthlyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures mensuelles"
        case "es": return "Horas mensuales"
        default: return "Monthly Hours"
        }
    }
    
    var feedbackSection: String {
        switch language {
        case "fr": return "Commentaires"
        case "es": return "Comentarios"
        default: return "Feedback"
        }
    }
    
    var suggestIdeasButton: String {
        switch language {
        case "fr": return "Suggérer des idées"
        case "es": return "Sugerir ideas"
        default: return "Suggest Ideas"
        }
    }
    
    var suggestIdeasTitle: String {
        switch language {
        case "fr": return "Vos suggestions"
        case "es": return "Sus sugerencias"
        default: return "Your Suggestions"
        }
    }
    
    var yourSuggestionHeader: String {
        switch language {
        case "fr": return "Votre suggestion"
        case "es": return "Su sugerencia"
        default: return "Your suggestion"
        }
    }
    
    var suggestionFooter: String {
        switch language {
        case "fr": return "Partagez vos idées pour améliorer ProTip365"
        case "es": return "Comparta sus ideas para mejorar ProTip365"
        default: return "Share your ideas to improve ProTip365"
        }
    }
    
    var sendSuggestionButton: String {
        switch language {
        case "fr": return "Envoyer"
        case "es": return "Enviar"
        default: return "Send"
        }
    }
    
    var successTitle: String {
        switch language {
        case "fr": return "Merci!"
        case "es": return "¡Gracias!"
        default: return "Thank you!"
        }
    }
    
    var thankYouMessage: String {
        switch language {
        case "fr": return "Merci pour vos suggestions, nous les apprécions vraiment!"
        case "es": return "Gracias por sus sugerencias, realmente las apreciamos!"
        default: return "Thank you for your suggestions, we really appreciate it!"
        }
    }
    
    var saveButton: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save Settings"
        }
    }
    
    var saveSuccessTitle: String {
        switch language {
        case "fr": return "Succès"
        case "es": return "Éxito"
        default: return "Success"
        }
    }
    
    var saveSuccessMessage: String {
        switch language {
        case "fr": return "Vos paramètres ont été sauvegardés avec succès."
        case "es": return "Su configuración se ha guardado correctamente."
        default: return "Your settings have been saved successfully."
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
    
    var deleteAccountButton: String {
        switch language {
        case "fr": return "Supprimer le compte"
        case "es": return "Eliminar cuenta"
        default: return "Delete Account"
        }
    }
    
    var deleteAccountConfirmTitle: String {
        switch language {
        case "fr": return "Supprimer le compte"
        case "es": return "Eliminar cuenta"
        default: return "Delete Account"
        }
    }
    
    var deleteAccountConfirmMessage: String {
        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer votre compte? Cette action est irréversible."
        case "es": return "¿Está seguro de que desea eliminar su cuenta? Esta acción es irreversible."
        default: return "Are you sure you want to delete your account? This action cannot be undone."
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

