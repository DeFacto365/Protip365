import SwiftUI
import Supabase

struct SettingsView: View {
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
    @State private var weekStartDay = 0
    @State private var useMultipleEmployers = false
    @State private var defaultEmployerId: UUID? = nil
    @State private var employers: [Employer] = []
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showSuggestIdeas = false
    @State private var suggestionText = ""
    @State private var isSendingSuggestion = false
    @State private var showingExportOptions = false
    @State private var shifts: [ShiftIncome] = []
    @State private var saveButtonText = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployersStorage = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    
    let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        NavigationStack {
            mainScrollView
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert(deleteAccountTitle, isPresented: $showDeleteAccountAlert) {
            Button(deleteAccountConfirmButton, role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
            Button(cancelButton, role: .cancel) { }
        } message: {
            Text(deleteAccountConfirmMessage)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showSuggestIdeas) {
            suggestIdeasSheet
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                exportManager: ExportManager(),
                shifts: shifts,
                language: language
            )
        }
        .task {
            // Set device language if not already set
            if language == "en" && !UserDefaults.standard.bool(forKey: "hasSetLanguage") {
                let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
                switch deviceLanguage {
                case "fr": language = "fr"
                case "es": language = "es"
                default: language = "en"
                }
                UserDefaults.standard.set(true, forKey: "hasSetLanguage")
            }
            
            await loadUserInfo()
            await loadSettings()
            await loadEmployers()
            await loadShifts()
            useMultipleEmployers = useMultipleEmployersStorage
            saveButtonText = saveSettingsText
        }
        .onChange(of: saveButtonText) { _, newValue in
            if newValue == savedText {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    saveButtonText = saveSettingsText
                }
            }
        }
    }
    
    private var mainScrollView: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // App Logo Card - Compact
                    HStack(spacing: 16) {
                        // Logo with Liquid Glass
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .liquidGlassCard(material: .regular, shape: .roundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // App Name
                            HStack(spacing: 0) {
                                Text("ProTip")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("365")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(userEmail)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard()
                    .padding(.horizontal)
                    // Language Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label(languageSection, systemImage: "globe")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker(languageLabel, selection: $language) {
                            Text("English").tag("en")
                            Text("Français").tag("fr")
                            Text("Español").tag("es")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .liquidGlassCard()
                    .padding(.horizontal)
                    
                    // Work Defaults Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(defaultsSection, systemImage: "briefcase.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Label(hourlyRateLabel, systemImage: "dollarsign.circle")
                                .foregroundColor(.primary)
                            Spacer()
                            HStack {
                                Text("$")
                                    .foregroundColor(.secondary)
                                TextField("15.00", text: $defaultHourlyRate, onEditingChanged: { editing in
                                    if editing && (defaultHourlyRate == "15.00" || defaultHourlyRate == "0.00") {
                                        defaultHourlyRate = ""
                                    }
                                    HapticFeedback.selection()
                                })
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            }
                            .frame(width: 100)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemFill))
                            .cornerRadius(8)
                        }
                        
                        Toggle(isOn: $useMultipleEmployers) {
                            Label(useMultipleEmployersLabel, systemImage: "building.2.fill")
                        }
                        .toggleStyle(IOSStandardToggleStyle())
                        .onChange(of: useMultipleEmployers) { _, newValue in
                            useMultipleEmployersStorage = newValue
                        }
                        
                        if useMultipleEmployers && !employers.isEmpty {
                            HStack {
                                Label(defaultEmployerLabel, systemImage: "star.fill")
                                Spacer()
                                Picker("", selection: $defaultEmployerId) {
                                    Text(noneLabel).tag(nil as UUID?)
                                    ForEach(employers) { employer in
                                        Text(employer.name).tag(employer.id as UUID?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .liquidGlassForm(material: .ultraThin)
                                .padding(8)
                                .onChange(of: defaultEmployerId) { _, _ in
                                    HapticFeedback.selection()
                                }
                            }
                        }
                        
                        HStack {
                            Label(weekStartLabel, systemImage: "calendar")
                            Spacer()
                            Picker("", selection: $weekStartDay) {
                                ForEach(0..<7) { index in
                                    Text(localizedWeekDay(index)).tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                            .liquidGlassForm(material: .ultraThin)
                            .padding(8)
                            .onChange(of: weekStartDay) { _, _ in
                                HapticFeedback.selection()
                            }
                        }
                    }
                    .padding()
                    .liquidGlassCard()
                    .padding(.horizontal)
                    
                    // Targets Explanation
                    VStack(spacing: 8) {
                        Text("🎯 Set your goals")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Set daily, weekly, and monthly targets. Your dashboard will show progress like '2.0/8h' for hours worked vs expected.")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .liquidGlassCard(material: .ultraThin)
                    .padding(.horizontal)
                    
                    // Tip Targets Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(tipTargetsSection, systemImage: "banknote.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        targetRow(label: dailyTargetLabel,
                                  icon: "calendar.day.timeline.left",
                                  value: $targetDaily,
                                  placeholder: "100.00",
                                  color: .primary)
                        
                        targetRow(label: weeklyTargetLabel,
                                  icon: "calendar.badge.clock",
                                  value: $targetWeekly,
                                  placeholder: "500.00",
                                  color: .primary)
                        
                        targetRow(label: monthlyTargetLabel,
                                  icon: "calendar",
                                  value: $targetMonthly,
                                  placeholder: "2000.00",
                                  color: .primary)
                    }
                    .padding()
                    .liquidGlassCard()
                    .padding(.horizontal)
                    
                    // Sales Targets Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(salesTargetsSection, systemImage: "cart.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        targetRow(label: dailySalesTargetLabel,
                                  icon: "chart.line.uptrend.xyaxis",
                                  value: $targetSalesDaily,
                                  placeholder: "500.00",
                                  color: .primary)
                        
                        targetRow(label: weeklySalesTargetLabel,
                                  icon: "chart.bar.fill",
                                  value: $targetSalesWeekly,
                                  placeholder: "3500.00",
                                  color: .primary)
                        
                        targetRow(label: monthlySalesTargetLabel,
                                  icon: "chart.pie.fill",
                                  value: $targetSalesMonthly,
                                  placeholder: "14000.00",
                                  color: .primary)
                    }
                    .padding()
                    .liquidGlassCard()
                    .padding(.horizontal)
                    
                    // Hours Targets Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label(hoursTargetsSection, systemImage: "clock.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        targetRow(label: dailyHoursTargetLabel,
                                  icon: "timer",
                                  value: $targetHoursDaily,
                                  placeholder: "8",
                                  color: .primary,
                                  isHours: true)
                        
                        targetRow(label: weeklyHoursTargetLabel,
                                  icon: "timer.circle.fill",
                                  value: $targetHoursWeekly,
                                  placeholder: "40",
                                  color: .primary,
                                  isHours: true)
                        
                        targetRow(label: monthlyHoursTargetLabel,
                                  icon: "hourglass",
                                  value: $targetHoursMonthly,
                                  placeholder: "160",
                                  color: .primary,
                                  isHours: true)
                    }
                    .padding()
                    .liquidGlassCard()
                    .padding(.horizontal)
                    
                    // All Action Buttons in One Card
                    VStack(spacing: 0) {
                        // Export Data
                        Button(action: {
                            showingExportOptions = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .foregroundStyle(Color(hex: "0288FF"))
                                VStack(alignment: .leading) {
                                    Text(exportDataButton)
                                        .foregroundStyle(.primary)
                                    Text(exportDataDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal)
                        
                        // Support
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(Color(hex: "0288FF"))
                            VStack(alignment: .leading) {
                                Text(supportButton)
                                    .foregroundStyle(.primary)
                                Text("support@protip365.com")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .frame(height: 0.5)
                            .padding(.horizontal)
                        
                        // Suggest Ideas
                        Button(action: {
                            HapticFeedback.selection()
                            showSuggestIdeas = true
                        }) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.orange)
                                Text(suggestIdeasButton)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                        
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .frame(height: 0.5)
                            .padding(.horizontal)
                        
                        // Sign Out
                        Button(action: {
                            HapticFeedback.medium()
                            showSignOutAlert = true
                        }) {
                            HStack {
                                Text(signOutButton)
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .padding()
                        }
                        
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .frame(height: 0.5)
                            .padding(.horizontal)
                        
                        // Delete Account
                        Button(action: {
                            HapticFeedback.medium()
                            showDeleteAccountAlert = true
                        }) {
                            HStack {
                                Text(deleteAccountButton)
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding()
                    .liquidGlassCard()
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 30)
                }
                .padding(.vertical)
                .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
            }
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(.systemGroupedBackground), Color(.systemGroupedBackground).opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.ultraThinMaterial)
            )
            .navigationTitle(settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        HapticFeedback.selection()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    VStack(spacing: 2) {
                        Button(action: {
                            HapticFeedback.medium()
                            Task {
                                await saveSettings()
                            }
                        }) {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: "0288FF"))
                            }
                        }
                        .disabled(isSaving)
                        
                        if saveButtonText == savedText {
                            Text(savedText)
                                .font(.caption2)
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }
                    }
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
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text(deleteAccountConfirmMessage)
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
                            Button(action: {
                                HapticFeedback.medium()
                                sendSuggestion()
                            }) {
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
                            .buttonStyle(PrimaryButtonStyle(material: .regular, tintColor: .blue))
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
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(
                    exportManager: ExportManager(),
                    shifts: shifts,
                    language: language
                )
            }
            .task {
            // Set device language if not already set
            if language == "en" && !UserDefaults.standard.bool(forKey: "hasSetLanguage") {
                let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
                switch deviceLanguage {
                case "fr": language = "fr"
                case "es": language = "es"
                default: language = "en"
                }
                UserDefaults.standard.set(true, forKey: "hasSetLanguage")
            }
            
            await loadUserInfo()
            await loadSettings()
            await loadEmployers()
            await loadShifts()
            useMultipleEmployers = useMultipleEmployersStorage
            saveButtonText = saveSettingsText
        }
        .onChange(of: saveButtonText) { _, newValue in
            if newValue == savedText {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    saveButtonText = saveSettingsText
                }
            }
        }
    }
    
    @ViewBuilder
    func targetRow(label: String, icon: String, value: Binding<String>, placeholder: String, color: Color, isHours: Bool = false) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(color)
            Spacer()
            TextField(placeholder, text: value, onEditingChanged: { editing in
                if editing && (value.wrappedValue == "0" || value.wrappedValue == "0.00" || value.wrappedValue == "0.0" || value.wrappedValue == placeholder) {
                    value.wrappedValue = ""
                }
            })
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 100)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .onTapGesture {
                HapticFeedback.selection()
            }
        }
    }
    
    func loadUserInfo() async {
        do {
            let user = try await SupabaseManager.shared.client.auth.session.user
            await MainActor.run {
                userEmail = user.email ?? ""
            }
        } catch {
            print("Error loading user info: \(error)")
        }
    }
    
    func loadEmployers() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            employers = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .order("name")
                .execute()
                .value
        } catch {
            print("Error loading employers: \(error)")
        }
    }
    
    func loadShifts() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            // Load all shifts for the user (for export purposes)
            let shiftsQuery = SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("shift_date", ascending: false)
            
            shifts = try await shiftsQuery.execute().value
        } catch {
            print("Error loading shifts: \(error)")
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
                let use_multiple_employers: Bool?
                let default_employer_id: String?
            }
            
            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let userProfile = profiles.first {
                
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
                
                if let useEmployers = userProfile.use_multiple_employers {
                    useMultipleEmployers = useEmployers
                    useMultipleEmployersStorage = useEmployers
                }
                
                if let defaultEmployerIdString = userProfile.default_employer_id {
                    defaultEmployerId = UUID(uuidString: defaultEmployerIdString)
                }
            }
        } catch {
            print("Error loading settings: \(error)")
        }
    }
    
    func saveSettings() async {
        isSaving = true
        
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
                    let use_multiple_employers: Bool
                    let default_employer_id: String?
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
                    name: nil,
                    use_multiple_employers: useMultipleEmployers,
                    default_employer_id: defaultEmployerId?.uuidString
                )
                
                try await SupabaseManager.shared.client
                    .from("users_profile")
                    .update(updates)
                    .eq("user_id", value: userId)
                    .execute()
                
                UserDefaults.standard.set(Double(defaultHourlyRate) ?? 15.00, forKey: "defaultHourlyRate")
                
                await MainActor.run {
                    isSaving = false
                    saveButtonText = savedText
                    
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
    
    func deleteAccount() async {
        isDeletingAccount = true
        
        do {
                let session = try await SupabaseManager.shared.client.auth.session
                let token = session.accessToken
                
                guard let url = URL(string: "https://ztzpjsbfzcccvbacgskc.supabase.co/functions/v1/delete-account") else {
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
                        let deleteErrorMessage = errorData?.error ?? "Failed to delete account"
                        
                        await MainActor.run {
                            isDeletingAccount = false
                            errorMessage = deleteErrorMessage
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
    
    // MARK: - Send Suggestion Function
    func sendSuggestion() {
        guard !suggestionText.isEmpty else { return }
        
        isSendingSuggestion = true
        
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                
                // Get Supabase URL from your SupabaseManager
                let supabaseURL = "https://ztzpjsbfzcccvbacgskc.supabase.co" // Your actual Supabase URL
                guard let url = URL(string: "\(supabaseURL)/functions/v1/send-suggestion") else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body = [
                    "suggestion": suggestionText,
                    "userEmail": userEmail
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        await MainActor.run {
                            isSendingSuggestion = false
                            showSuggestIdeas = false
                            suggestionText = ""
                            HapticFeedback.success()
                        }
                    } else {
                        let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        let errorMessage = errorData?["error"] as? String ?? "Unknown error"
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    }
                }
            } catch {
                await MainActor.run {
                    isSendingSuggestion = false
                    errorMessage = "Failed to send: \(error.localizedDescription)"
                    showError = true
                }
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
    
    var nameLabel: String {
        switch language {
        case "fr": return "Nom"
        case "es": return "Nombre"
        default: return "Name"
        }
    }
    
    var yourNamePlaceholder: String {
        switch language {
        case "fr": return "Votre nom"
        case "es": return "Su nombre"
        default: return "Your name"
        }
    }
    
    var saveSettingsText: String {
        switch language {
        case "fr": return "Enregistrer"
        case "es": return "Guardar"
        default: return "Save"
        }
    }
    
    var savedText: String {
        switch language {
        case "fr": return "Enregistré!"
        case "es": return "¡Guardado!"
        default: return "Saved!"
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
    
    var useMultipleEmployersLabel: String {
        switch language {
        case "fr": return "Utiliser plusieurs employeurs"
        case "es": return "Usar múltiples empleadores"
        default: return "Use Multiple Employers"
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
    
    var defaultEmployerLabel: String {
        switch language {
        case "fr": return "Employeur par défaut"
        case "es": return "Empleador predeterminado"
        default: return "Default Employer"
        }
    }
    
    var noneLabel: String {
        switch language {
        case "fr": return "Aucun"
        case "es": return "Ninguno"
        default: return "None"
        }
    }
    
    var exportDataButton: String {
        switch language {
        case "fr": return "Exporter les données"
        case "es": return "Exportar datos"
        default: return "Export Data"
        }
    }
    
    var exportDataDescription: String {
        switch language {
        case "fr": return "Exporter vers CSV ou Excel"
        case "es": return "Exportar a CSV o Excel"
        default: return "Export to CSV or Excel"
        }
    }
    
    private var suggestIdeasSheet: some View {
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
                    Button(action: {
                        HapticFeedback.medium()
                        sendSuggestion()
                    }) {
                        HStack {
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
                    .buttonStyle(PrimaryButtonStyle(material: .regular, tintColor: .blue))
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
        }
    }
    
    // MARK: - Missing Localized Text Properties
    var deleteAccountTitle: String {
        switch language {
        case "fr": return "Supprimer le compte"
        case "es": return "Eliminar cuenta"
        default: return "Delete Account"
        }
    }
    
    var deleteAccountConfirmButton: String {
        switch language {
        case "fr": return "Supprimer"
        case "es": return "Eliminar" 
        default: return "Delete"
        }
    }
}
