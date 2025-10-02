import SwiftUI
import Supabase

struct SettingsView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    // State variables
    @State private var userEmail = ""
    @State private var defaultHourlyRate = ""
    @State private var averageDeductionPercentage = ""
    @State private var tipTargetPercentage = ""
    @State private var targetTipDaily = ""
    @State private var targetTipWeekly = ""
    @State private var targetTipMonthly = ""
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
    @State private var showEmployerPicker = false
    @State private var showWeekStartPicker = false
    @State private var showDefaultAlertPicker = false
    @State private var defaultAlertString = "60 minutes"
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showSuggestIdeas = false
    @State private var showSupport = false
    @State private var suggestionText = ""
    @State private var suggestionEmail = ""
    @State private var showThankYouMessage = false
    @State private var isSendingSuggestion = false
    @State private var showingExportOptions = false
    @State private var shifts: [ShiftIncome] = []
    @State private var saveButtonText = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPINSetup = false
    @State private var isVerifyingToDisable = false
    @State private var selectedSecurityType = SecurityType.none
    @State private var showOnboarding = false
    @StateObject private var securityManager = SecurityManager()
    @State private var userName = ""
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployersStorage = false
    @AppStorage("hasVariableSchedule") private var hasVariableSchedule = false

    // Unsaved changes detection
    @State private var showUnsavedChangesAlert = false
    @State private var originalValues: OriginalSettings?

    struct OriginalSettings {
        let userName: String
        let defaultHourlyRate: String
        let averageDeductionPercentage: String
        let tipTargetPercentage: String
        let targetTipDaily: String
        let targetTipWeekly: String
        let targetTipMonthly: String
        let targetSalesDaily: String
        let targetSalesWeekly: String
        let targetSalesMonthly: String
        let targetHoursDaily: String
        let targetHoursWeekly: String
        let targetHoursMonthly: String
        let weekStartDay: Int
        let useMultipleEmployers: Bool
        let hasVariableSchedule: Bool
        let defaultEmployerId: UUID?
        let defaultAlertString: String
        let language: String
    }

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass

    private let localization: SettingsLocalization

    init(selectedTab: Binding<String>) {
        self._selectedTab = selectedTab
        self.localization = SettingsLocalization()
    }

    var body: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                settingsHeader

                ScrollView {
                    settingsContent
                        .padding(.bottom, 90) // Add padding for tab bar
                }
                .frame(maxWidth: .infinity)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert(localization.unsavedChangesTitle, isPresented: $showUnsavedChangesAlert) {
            Button(localization.saveButton) {
                Task {
                    await saveSettings()
                }
            }
            Button(localization.discardButton, role: .destructive) {
                selectedTab = "dashboard"
            }
            Button(localization.cancelButton, role: .cancel) { }
        } message: {
            Text(localization.unsavedChangesMessage)
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
            saveButtonText = localization.saveSettingsText

            // Store original values for change detection
            storeOriginalValues()
        }
        .onChange(of: saveButtonText) { _, newValue in
            if newValue == localization.savedText {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    saveButtonText = localization.saveSettingsText
                }
            }
        }
    }

    // MARK: - View Components

    private var settingsHeader: some View {
        HStack {
            // Cancel Button
            Button(action: {
                if hasUnsavedChanges {
                    showUnsavedChangesAlert = true
                } else {
                    selectedTab = "dashboard"
                }
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(localization.settingsTitle)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Save Button
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
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(hasUnsavedChanges ? Color.accentColor : Color.gray)
                }
            }
            .disabled(isSaving || !hasUnsavedChanges)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var settingsContent: some View {
        VStack(spacing: 20) {
            AppInfoSection(
                language: $language,
                showOnboarding: $showOnboarding
            )

            ProfileSettingsSection(
                userEmail: $userEmail,
                userName: $userName,
                language: language
            )

            WorkDefaultsSection(
                defaultHourlyRate: $defaultHourlyRate,
                averageDeductionPercentage: $averageDeductionPercentage,
                useMultipleEmployers: $useMultipleEmployers,
                hasVariableSchedule: $hasVariableSchedule,
                defaultEmployerId: $defaultEmployerId,
                employers: $employers,
                showEmployerPicker: $showEmployerPicker,
                showWeekStartPicker: $showWeekStartPicker,
                weekStartDay: $weekStartDay,
                defaultAlert: $defaultAlertString,
                showDefaultAlertPicker: $showDefaultAlertPicker,
                language: language
            )

            SecuritySettingsSection(
                showPINSetup: $showPINSetup,
                isVerifyingToDisable: $isVerifyingToDisable,
                selectedSecurityType: $selectedSecurityType,
                securityManager: securityManager,
                language: language
            )

            TargetsSettingsSection(
                tipTargetPercentage: $tipTargetPercentage,
                targetSalesDaily: $targetSalesDaily,
                targetSalesWeekly: $targetSalesWeekly,
                targetSalesMonthly: $targetSalesMonthly,
                targetHoursDaily: $targetHoursDaily,
                targetHoursWeekly: $targetHoursWeekly,
                targetHoursMonthly: $targetHoursMonthly,
                hasVariableSchedule: $hasVariableSchedule,
                language: language
            )

            SupportSettingsSection(
                showSuggestIdeas: $showSuggestIdeas,
                showSupport: $showSupport,
                showingExportOptions: $showingExportOptions,
                showOnboarding: $showOnboarding,
                shifts: $shifts,
                suggestionText: $suggestionText,
                suggestionEmail: $suggestionEmail,
                showThankYouMessage: $showThankYouMessage,
                isSendingSuggestion: $isSendingSuggestion,
                userEmail: $userEmail,
                language: language
            )

            // Subscription Management Section - Only for active subscribers
            SubscriptionManagementSection(
                subscriptionManager: subscriptionManager,
                language: language
            )

            AccountSettingsSection(
                showSignOutAlert: $showSignOutAlert,
                showDeleteAccountAlert: $showDeleteAccountAlert,
                isDeletingAccount: $isDeletingAccount,
                language: language
            )

            #if DEBUG
            // Debug Section - Only visible in DEBUG builds
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.orange)
                        .frame(width: 28, height: 28)
                    Text("Developer Tools")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                NavigationLink {
                    SubscriptionDebugView(subscriptionManager: subscriptionManager)
                } label: {
                    HStack {
                        Text("Subscription Debug")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: IconNames.Form.next)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }

                NavigationLink {
                    StoreKitTestDebugView()
                } label: {
                    HStack {
                        Text("StoreKit Debug")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: IconNames.Form.next)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            #endif

            Spacer()
                .frame(height: 30)
        }
        .padding(.horizontal, sizeClass == .regular ? 32 : 16)
        .padding(.vertical)
    }

    // MARK: - Helper Methods

    private var hasUnsavedChanges: Bool {
        guard let original = originalValues else { return false }

        return original.userName != userName ||
               original.defaultHourlyRate != defaultHourlyRate ||
               original.averageDeductionPercentage != averageDeductionPercentage ||
               original.tipTargetPercentage != tipTargetPercentage ||
               original.targetTipDaily != targetTipDaily ||
               original.targetTipWeekly != targetTipWeekly ||
               original.targetTipMonthly != targetTipMonthly ||
               original.targetSalesDaily != targetSalesDaily ||
               original.targetSalesWeekly != targetSalesWeekly ||
               original.targetSalesMonthly != targetSalesMonthly ||
               original.targetHoursDaily != targetHoursDaily ||
               original.targetHoursWeekly != targetHoursWeekly ||
               original.targetHoursMonthly != targetHoursMonthly ||
               original.weekStartDay != weekStartDay ||
               original.useMultipleEmployers != useMultipleEmployers ||
               original.hasVariableSchedule != hasVariableSchedule ||
               original.defaultEmployerId != defaultEmployerId ||
               original.defaultAlertString != defaultAlertString ||
               original.language != language
    }

    private func storeOriginalValues() {
        originalValues = OriginalSettings(
            userName: userName,
            defaultHourlyRate: defaultHourlyRate,
            averageDeductionPercentage: averageDeductionPercentage,
            tipTargetPercentage: tipTargetPercentage,
            targetTipDaily: targetTipDaily,
            targetTipWeekly: targetTipWeekly,
            targetTipMonthly: targetTipMonthly,
            targetSalesDaily: targetSalesDaily,
            targetSalesWeekly: targetSalesWeekly,
            targetSalesMonthly: targetSalesMonthly,
            targetHoursDaily: targetHoursDaily,
            targetHoursWeekly: targetHoursWeekly,
            targetHoursMonthly: targetHoursMonthly,
            weekStartDay: weekStartDay,
            useMultipleEmployers: useMultipleEmployers,
            hasVariableSchedule: hasVariableSchedule,
            defaultEmployerId: defaultEmployerId,
            defaultAlertString: defaultAlertString,
            language: language
        )
    }

    // MARK: - Data Loading Functions

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
            _ = try await SupabaseManager.shared.client.auth.session.user.id

            // Load all shifts for the user (for export purposes) using new simplified method
            let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
            let endDate = Date()
            let shiftsWithEntries = try await SupabaseManager.shared.fetchShiftsWithEntries(from: startDate, to: endDate)

            // Convert to ShiftIncome for compatibility with export system
            shifts = shiftsWithEntries.map { shiftWithEntry in
                let shift = shiftWithEntry.expected_shift
                let entry = shiftWithEntry.entry

                let hours = entry?.actual_hours ?? shift.expected_hours
                let sales = entry?.sales ?? 0
                let tips = entry?.tips ?? 0
                let cashOut = entry?.cash_out ?? 0
                let other = entry?.other ?? 0

                let baseIncome = hours * shift.hourly_rate
                let netTips = tips - cashOut
                let totalIncome = baseIncome + netTips + other
                let tipPercentage = sales > 0 ? (tips / sales) * 100 : 0

                return ShiftIncome(
                    income_id: entry?.id,
                    shift_id: shift.id,
                    user_id: shift.user_id,
                    employer_id: shift.employer_id,
                    employer_name: shiftWithEntry.employer_name,
                    shift_date: shift.shift_date,
                    expected_hours: shift.expected_hours,
                    lunch_break_minutes: shift.lunch_break_minutes,
                    net_expected_hours: shift.expected_hours,
                    hours: hours,
                    hourly_rate: shift.hourly_rate,
                    sales: sales,
                    tips: tips,
                    cash_out: cashOut,
                    other: other,
                    base_income: baseIncome,
                    net_tips: netTips,
                    total_income: totalIncome,
                    tip_percentage: tipPercentage,
                    sales_target: shift.sales_target,
                    start_time: shift.start_time,
                    end_time: shift.end_time,
                    actual_start_time: entry?.actual_start_time,
                    actual_end_time: entry?.actual_end_time,
                    shift_status: shift.status,
                    shift_created_at: shift.created_at,
                    earnings_created_at: entry?.created_at,
                    notes: entry?.notes ?? shift.notes
                )
            }
        } catch {
            print("Error loading shifts: \(error)")
        }
    }

    func loadSettings() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            struct Profile: Decodable {
                let default_hourly_rate: Double
                let average_deduction_percentage: Double?
                let tip_target_percentage: Double?
                let target_tip_daily: Double?
                let target_tip_weekly: Double?
                let target_tip_monthly: Double?
                let target_sales_daily: Double?
                let target_sales_weekly: Double?
                let target_sales_monthly: Double?
                let target_hours_daily: Double?
                let target_hours_weekly: Double?
                let target_hours_monthly: Double?
                let week_start: Int?
                let name: String?
                let use_multiple_employers: Bool?
                let has_variable_schedule: Bool?
                let default_employer_id: String?
                let default_alert_minutes: Int?
            }

            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            print("🔍 Found \(profiles.count) profile(s) for user \(userId)")

            if let userProfile = profiles.first {
                print("🔍 Profile name field: '\(userProfile.name ?? "nil")'")
                defaultHourlyRate = userProfile.default_hourly_rate > 0 ? String(format: "%.2f", userProfile.default_hourly_rate) : ""
                averageDeductionPercentage = userProfile.average_deduction_percentage != nil ? String(format: "%.0f", userProfile.average_deduction_percentage ?? 30) : ""
                tipTargetPercentage = (userProfile.tip_target_percentage ?? 0) > 0 ? String(format: "%.0f", userProfile.tip_target_percentage ?? 0) : ""
                targetTipDaily = (userProfile.target_tip_daily ?? 0) > 0 ? String(format: "%.2f", userProfile.target_tip_daily ?? 0) : ""
                targetTipWeekly = (userProfile.target_tip_weekly ?? 0) > 0 ? String(format: "%.2f", userProfile.target_tip_weekly ?? 0) : ""
                targetTipMonthly = (userProfile.target_tip_monthly ?? 0) > 0 ? String(format: "%.2f", userProfile.target_tip_monthly ?? 0) : ""
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

                // Load variable schedule setting
                if let variableSchedule = userProfile.has_variable_schedule {
                    hasVariableSchedule = variableSchedule
                }

                if let defaultEmployerIdString = userProfile.default_employer_id {
                    defaultEmployerId = UUID(uuidString: defaultEmployerIdString)
                }

                // Load default alert setting
                if let defaultAlertMinutes = userProfile.default_alert_minutes {
                    switch defaultAlertMinutes {
                    case 15: defaultAlertString = "15 minutes"
                    case 30: defaultAlertString = "30 minutes"
                    case 60: defaultAlertString = "60 minutes"
                    case 1440: defaultAlertString = "1 day before"
                    default: defaultAlertString = "60 minutes"
                    }
                } else {
                    defaultAlertString = "60 minutes"
                }

                // Load user name
                userName = userProfile.name ?? ""
                print("🔍 Loaded user name: '\(userName)' from profile")
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
                let average_deduction_percentage: Double
                let tip_target_percentage: Double
                let target_sales_daily: Double
                let target_sales_weekly: Double
                let target_sales_monthly: Double
                let target_hours_daily: Double
                let target_hours_weekly: Double
                let target_hours_monthly: Double
                let language: String
                let preferred_language: String
                let week_start: Int
                let name: String?
                let use_multiple_employers: Bool
                let has_variable_schedule: Bool
                let default_employer_id: String?
                let default_alert_minutes: Int
            }

            // Convert alert string to minutes
            let alertMinutes: Int = {
                switch defaultAlertString {
                case "15 minutes": return 15
                case "30 minutes": return 30
                case "60 minutes": return 60
                case "1 day before": return 1440
                case "None": return 0
                default: return 60
                }
            }()

            let updates = ProfileUpdate(
                default_hourly_rate: Double(defaultHourlyRate) ?? 15.00,
                average_deduction_percentage: min(100, max(0, Double(averageDeductionPercentage) ?? 30)),
                tip_target_percentage: Double(tipTargetPercentage) ?? 0,
                target_sales_daily: Double(targetSalesDaily) ?? 0,
                target_sales_weekly: hasVariableSchedule ? 0 : (Double(targetSalesWeekly) ?? 0),
                target_sales_monthly: hasVariableSchedule ? 0 : (Double(targetSalesMonthly) ?? 0),
                target_hours_daily: Double(targetHoursDaily) ?? 0,
                target_hours_weekly: hasVariableSchedule ? 0 : (Double(targetHoursWeekly) ?? 0),
                target_hours_monthly: hasVariableSchedule ? 0 : (Double(targetHoursMonthly) ?? 0),
                language: language,
                preferred_language: language,
                week_start: weekStartDay,
                name: userName.isEmpty ? nil : userName,
                use_multiple_employers: useMultipleEmployers,
                has_variable_schedule: hasVariableSchedule,
                default_employer_id: defaultEmployerId?.uuidString,
                default_alert_minutes: alertMinutes
            )
            
            print("🔍 Saving user name: '\(userName)' (will be nil if empty: \(userName.isEmpty))")

            try await SupabaseManager.shared.client
                .from("users_profile")
                .update(updates)
                .eq("user_id", value: userId)
                .execute()
            
            print("🔍 Profile update completed successfully")

            UserDefaults.standard.set(Double(defaultHourlyRate) ?? 15.00, forKey: "defaultHourlyRate")

            await MainActor.run {
                isSaving = false
                saveButtonText = localization.savedText
                // Update original values after successful save
                storeOriginalValues()

                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()

                // Settings saved successfully - stay on settings page
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