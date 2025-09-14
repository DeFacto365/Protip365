import SwiftUI
import Supabase

struct RefactoredSettingsView: View {
    @Binding var selectedTab: String

    // MARK: - State Variables
    @State private var userEmail = ""
    @State private var defaultHourlyRate = ""
    @State private var tipTargetPercentage = ""
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

    // MARK: - UI State
    @State private var showEmployerPicker = false
    @State private var showWeekStartPicker = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showSuggestIdeas = false
    @State private var showingExportOptions = false
    @State private var shifts: [ShiftIncome] = []
    @State private var showOnboarding = false

    // MARK: - Security State
    @State private var showPINSetup = false
    @State private var isVerifyingToDisable = false
    @State private var selectedSecurityType = SecurityType.none
    @StateObject private var securityManager = SecurityManager()

    // MARK: - Save State
    @State private var saveButtonText = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var originalValues: OriginalSettings?
    @State private var showUnsavedChangesAlert = false

    // MARK: - App Storage
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployersStorage = false

    private let localization: SettingsLocalization

    init(selectedTab: Binding<String>) {
        self._selectedTab = selectedTab
        self.localization = SettingsLocalization()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.formSectionSpacing) {
                    // Profile Section
                    ProfileSettingsSection(
                        userEmail: $userEmail,
                        defaultHourlyRate: $defaultHourlyRate,
                        tipTargetPercentage: $tipTargetPercentage,
                        weekStartDay: $weekStartDay,
                        useMultipleEmployers: $useMultipleEmployers,
                        defaultEmployerId: $defaultEmployerId,
                        employers: $employers,
                        showEmployerPicker: $showEmployerPicker,
                        showWeekStartPicker: $showWeekStartPicker,
                        language: language
                    )

                    // Targets Section
                    TargetsSettingsSection(
                        targetSalesDaily: $targetSalesDaily,
                        targetSalesWeekly: $targetSalesWeekly,
                        targetSalesMonthly: $targetSalesMonthly,
                        targetHoursDaily: $targetHoursDaily,
                        targetHoursWeekly: $targetHoursWeekly,
                        targetHoursMonthly: $targetHoursMonthly,
                        language: language
                    )

                    // Security Section
                    SecuritySettingsSection(
                        showPINSetup: $showPINSetup,
                        isVerifyingToDisable: $isVerifyingToDisable,
                        selectedSecurityType: $selectedSecurityType,
                        securityManager: securityManager,
                        language: language
                    )

                    // Support Section
                    SupportSettingsSection(
                        showSuggestIdeas: $showSuggestIdeas,
                        showingExportOptions: $showingExportOptions,
                        showOnboarding: $showOnboarding,
                        shifts: $shifts,
                        language: language
                    )

                    // Account Section
                    AccountSettingsSection(
                        showSignOutAlert: $showSignOutAlert,
                        showDeleteAccountAlert: $showDeleteAccountAlert,
                        isDeletingAccount: $isDeletingAccount,
                        language: language
                    )

                    // Save Button
                    if hasUnsavedChanges {
                        Button(action: {
                            Task { await saveSettings() }
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                    Text(localization.savingButton)
                                        .foregroundStyle(.white)
                                } else {
                                    Text(localization.saveButton)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isSaving)
                        .padding(.horizontal)
                        .padding(.bottom, Constants.safeAreaPadding)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, Constants.safeAreaPadding)
            }
            .navigationTitle(localization.settingsTitle)
            .navigationBarTitleDisplayMode(.large)
            .background(Color.adaptiveGroupedBackground.ignoresSafeArea())
            .task {
                await loadSettings()
                await loadShifts()
                setupInitialValues()
            }
            .onChange(of: useMultipleEmployers) { _, newValue in
                useMultipleEmployersStorage = newValue
                if newValue {
                    Task { await loadEmployers() }
                }
            }
            .alert(localization.errorSavingSettings, isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert(localization.unsavedChangesTitle, isPresented: $showUnsavedChangesAlert) {
                Button(localization.cancelButton, role: .cancel) { }
                Button(localization.saveButton) {
                    Task { await saveSettings() }
                }
            } message: {
                Text(localization.unsavedChangesMessage)
            }
        }
    }

    // MARK: - Computed Properties

    private var hasUnsavedChanges: Bool {
        guard let original = originalValues else { return false }
        return original.hourlyRate != defaultHourlyRate ||
               original.tipTarget != tipTargetPercentage ||
               original.targetSalesDaily != targetSalesDaily ||
               original.targetSalesWeekly != targetSalesWeekly ||
               original.targetSalesMonthly != targetSalesMonthly ||
               original.targetHoursDaily != targetHoursDaily ||
               original.targetHoursWeekly != targetHoursWeekly ||
               original.targetHoursMonthly != targetHoursMonthly ||
               original.weekStartDay != weekStartDay ||
               original.useMultipleEmployers != useMultipleEmployers ||
               original.defaultEmployerId != defaultEmployerId
    }

    // MARK: - Methods

    private func setupInitialValues() {
        originalValues = OriginalSettings(
            hourlyRate: defaultHourlyRate,
            tipTarget: tipTargetPercentage,
            targetTipDaily: "",
            targetTipWeekly: "",
            targetTipMonthly: "",
            targetSalesDaily: targetSalesDaily,
            targetSalesWeekly: targetSalesWeekly,
            targetSalesMonthly: targetSalesMonthly,
            targetHoursDaily: targetHoursDaily,
            targetHoursWeekly: targetHoursWeekly,
            targetHoursMonthly: targetHoursMonthly,
            weekStartDay: weekStartDay,
            useMultipleEmployers: useMultipleEmployers,
            defaultEmployerId: defaultEmployerId
        )
    }

    private func loadSettings() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            userEmail = try await SupabaseManager.shared.client.auth.session.user.email ?? ""

            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            if let profile = profiles.first {
                await MainActor.run {
                    defaultHourlyRate = String(profile.default_hourly_rate)
                    tipTargetPercentage = String(profile.tip_target_percentage ?? 0)
                    targetSalesDaily = String(profile.target_sales_daily ?? 0)
                    targetSalesWeekly = String(profile.target_sales_weekly ?? 0)
                    targetSalesMonthly = String(profile.target_sales_monthly ?? 0)
                    targetHoursDaily = String(profile.target_hours_daily ?? 0)
                    targetHoursWeekly = String(profile.target_hours_weekly ?? 0)
                    targetHoursMonthly = String(profile.target_hours_monthly ?? 0)
                    weekStartDay = profile.week_start ?? 0
                    useMultipleEmployers = profile.use_multiple_employers ?? false
                    defaultEmployerId = profile.default_employer_id
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func loadEmployers() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            let employers: [Employer] = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            await MainActor.run {
                self.employers = employers
            }
        } catch {
            print("Error loading employers: \(error)")
        }
    }

    private func loadShifts() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            let shifts: [ShiftIncome] = try await SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            await MainActor.run {
                self.shifts = shifts
            }
        } catch {
            print("Error loading shifts: \(error)")
        }
    }

    private func saveSettings() async {
        isSaving = true

        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            let update = ProfileUpdate(
                default_hourly_rate: Double(defaultHourlyRate) ?? 15.0,
                tip_target_percentage: Double(tipTargetPercentage),
                target_tip_daily: nil,
                target_tip_weekly: nil,
                target_tip_monthly: nil,
                target_sales_daily: Double(targetSalesDaily),
                target_sales_weekly: Double(targetSalesWeekly),
                target_sales_monthly: Double(targetSalesMonthly),
                target_hours_daily: Double(targetHoursDaily),
                target_hours_weekly: Double(targetHoursWeekly),
                target_hours_monthly: Double(targetHoursMonthly),
                week_start: weekStartDay,
                use_multiple_employers: useMultipleEmployers,
                default_employer_id: defaultEmployerId
            )

            try await SupabaseManager.shared.client
                .from("users_profile")
                .update(update)
                .eq("user_id", value: userId)
                .execute()

            await MainActor.run {
                isSaving = false
                setupInitialValues()
                HapticFeedback.success()
            }

        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}