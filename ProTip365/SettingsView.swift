import SwiftUI
import Supabase

struct SettingsView: View {
    @Binding var selectedTab: String
    @State private var userEmail = ""
    @State private var defaultHourlyRate = ""
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
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showSuggestIdeas = false
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
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployersStorage = false
    @AppStorage("hasVariableSchedule") private var hasVariableSchedule = false

    // Unsaved changes detection
    @State private var showUnsavedChangesAlert = false
    @State private var originalValues: OriginalSettings?

    struct OriginalSettings {
        let defaultHourlyRate: String
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
    }
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    
    let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        mainScrollView
    }
    
    private var appLogoAndLanguageCard: some View {
        VStack(spacing: 20) {
            // App Info Section
            HStack(spacing: 16) {
                // Logo
                Image("Logo2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

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
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // How to Use Button Section
            Button(action: {
                HapticFeedback.selection()
                showOnboarding = true
            }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(.blue)
                    Text(howToUseText)
                        .foregroundStyle(.primary)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

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
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var workDefaultsSection: some View {
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
                    .foregroundColor(.blue)
                }
                .frame(width: 100)
                .padding(8)
                .liquidGlassForm()
            }
            
            LiquidGlassToggle(
                useMultipleEmployersLabel,
                icon: "building.2.fill",
                description: useMultipleEmployersDescriptionText,
                isOn: $useMultipleEmployers
            ) { newValue in
                useMultipleEmployersStorage = newValue
            }

            LiquidGlassToggle(
                variableScheduleLabel,
                icon: "calendar.badge.clock",
                description: variableScheduleDescription,
                isOn: $hasVariableSchedule
            ) { newValue in
                // Variable schedule setting changed
                // When enabled, this will hide weekly and monthly targets
            }

            // Explanation text for variable schedule
            if hasVariableSchedule {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(variableScheduleEnabledTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    Text(variableScheduleEnabledMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if useMultipleEmployers && !employers.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Label(defaultEmployerLabel, systemImage: "star.fill")
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEmployerPicker.toggle()
                                showWeekStartPicker = false
                            }
                        }) {
                            Text(employers.first(where: { $0.id == defaultEmployerId })?.name ?? noneLabel)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    if showEmployerPicker {
                        Picker("", selection: $defaultEmployerId) {
                            Text(noneLabel).tag(nil as UUID?)
                            ForEach(employers) { employer in
                                Text(employer.name).tag(employer.id as UUID?)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .onChange(of: defaultEmployerId) { _, _ in
                            HapticFeedback.selection()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showEmployerPicker = false
                                }
                            }
                        }
                    }
                }
            }
            
            VStack(spacing: 0) {
                HStack {
                    Label(weekStartLabel, systemImage: "calendar")
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showWeekStartPicker.toggle()
                            showEmployerPicker = false
                        }
                    }) {
                        Text(localizedWeekDay(weekStartDay))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                if showWeekStartPicker {
                    Picker("", selection: $weekStartDay) {
                        ForEach(0..<7) { index in
                            Text(localizedWeekDay(index)).tag(index)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: weekStartDay) { _, _ in
                        HapticFeedback.selection()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showWeekStartPicker = false
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var targetsExplanationSection: some View {
        VStack(spacing: 8) {
            Text(setYourGoalsTitle)
                .font(.headline)
                .foregroundColor(.primary)

            Text(setYourGoalsDescription)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var tipTargetsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(tipTargetsSection, systemImage: "banknote.fill")
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                Label(tipPercentageTargetLabel, systemImage: "percent")
                    .foregroundColor(.primary)
                Spacer()
                HStack {
                    TextField("15", text: $tipTargetPercentage, onEditingChanged: { editing in
                        if editing && (tipTargetPercentage == "15" || tipTargetPercentage == "0") {
                            tipTargetPercentage = ""
                        }
                        HapticFeedback.selection()
                    })
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.blue)
                    Text("%")
                        .foregroundColor(.secondary)
                }
                .frame(width: 100)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Tip percentage explanation
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(tipPercentageNoteTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                Text(tipPercentageNoteMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var salesTargetsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(salesTargetsSection, systemImage: "cart.fill")
                .font(.headline)
                .foregroundColor(.primary)

            targetRow(label: dailySalesTargetLabel,
                      icon: "chart.line.uptrend.xyaxis",
                      value: $targetSalesDaily,
                      placeholder: "500.00",
                      color: .primary)

            // Only show weekly and monthly if NOT variable schedule
            if !hasVariableSchedule {
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

            // Variable schedule note
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(variableScheduleNoteTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                Text(variableScheduleNoteMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var hoursTargetsSectionView: some View {
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

            // Only show weekly and monthly if NOT variable schedule
            if !hasVariableSchedule {
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

            // Variable schedule note
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(variableScheduleNoteTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                Text(variableScheduleHoursNoteMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 0) {
            // Export Data
            Button(action: {
                showingExportOptions = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundStyle(.blue)
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
                    .foregroundStyle(.blue)
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
            
            // Cancel Subscription Section
            VStack(alignment: .leading, spacing: 12) {
                Label(cancelSubscriptionTitle, systemImage: "creditcard.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(cancelSubscriptionInstructions)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(cancelSubscriptionWarning)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: {
                    HapticFeedback.selection()
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text(goToAppleAccountText)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
            }
            .padding()

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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }

    // MARK: - Security Section
    private var securitySection: some View {
        VStack(spacing: 0) {
            HStack {
                Text(securityTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Security Type Selection with Dropdown
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(securityOptionsLabel, systemImage: "lock.shield")
                        .foregroundColor(.primary)
                    Spacer()

                    Menu {
                        Button(action: {
                            // Verify security before removing
                            if securityManager.currentSecurityType != .none {
                                // We need to authenticate first before allowing removal
                                if securityManager.currentSecurityType == .pinCode {
                                    // Show PIN entry for verification
                                    isVerifyingToDisable = true
                                    showPINSetup = true
                                } else {
                                    // For biometric, authenticate first
                                    securityManager.authenticateWithBiometric { success in
                                        if success {
                                            selectedSecurityType = .none
                                            securityManager.disableAllSecurity()
                                            HapticFeedback.selection()
                                        }
                                    }
                                }
                            } else {
                                selectedSecurityType = .none
                                securityManager.disableAllSecurity()
                                HapticFeedback.selection()
                            }
                        }) {
                            Label(noSecurityText, systemImage: "lock.open")
                        }

                        Button(action: {
                            selectedSecurityType = .biometric
                            securityManager.setSecurityType(.biometric)
                            HapticFeedback.selection()
                        }) {
                            Label(faceIDText, systemImage: "faceid")
                        }

                        Button(action: {
                            if securityManager.currentSecurityType != .pinCode || securityManager.pinCodeHash.isEmpty {
                                showPINSetup = true
                                selectedSecurityType = .pinCode
                            } else {
                                selectedSecurityType = .pinCode
                                securityManager.setSecurityType(.pinCode)
                            }
                            HapticFeedback.selection()
                        }) {
                            Label(pinCodeText, systemImage: "number.square")
                        }
                    } label: {
                        HStack {
                            Text(currentSecurityText)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)
            }

            // Security Description
            Text(securityDescriptionText)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .multilineTextAlignment(.center)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
        .sheet(isPresented: $showPINSetup) {
            NavigationStack {
                PINEntryView(
                    securityManager: securityManager,
                    isSettingPIN: !isVerifyingToDisable,
                    onSuccess: {
                        showPINSetup = false
                        if isVerifyingToDisable {
                            // User verified PIN to disable security
                            selectedSecurityType = .none
                            securityManager.disableAllSecurity()
                            isVerifyingToDisable = false
                            HapticFeedback.selection()
                        } else {
                            // User set new PIN
                            securityManager.setSecurityType(.pinCode)
                        }
                    },
                    onCancel: {
                        showPINSetup = false
                        isVerifyingToDisable = false
                    }
                )
                .navigationTitle(isVerifyingToDisable ? "Verify PIN" : setPINTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(cancelText) {
                            showPINSetup = false
                            isVerifyingToDisable = false
                        }
                    }
                }
            }
        }
    }

    private var settingsContent: some View {
        VStack(spacing: 20) {
            appLogoAndLanguageCard
            workDefaultsSection
            securitySection
            targetsExplanationSection
            tipTargetsSectionView
            salesTargetsSectionView
            hoursTargetsSectionView

            actionButtonsSection

            Spacer()
                .frame(height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
        .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
    }
    
    private var mainScrollView: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // iOS 26 Style Header
                HStack {
                    // Cancel Button with iOS 26 style
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
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(settingsTitle)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    // Save Button with iOS 26 style
                    Button(action: {
                        HapticFeedback.medium()
                        Task {
                            await saveSettings()
                        }
                    }) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(hasUnsavedChanges ? Color.blue : Color.gray)
                                .clipShape(Circle())
                        }
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                ScrollView {
                    settingsContent
                        .padding(.bottom, 90) // Add padding for tab bar
                }
                .frame(maxWidth: .infinity)
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
                        // Email section first
                        Section {
                            TextField(suggestionEmailPlaceholder, text: $suggestionEmail)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .textContentType(.emailAddress)
                        } header: {
                            Text(suggestionEmailPlaceholder)
                        }

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
                                            .foregroundColor(.black)
                                    }
                                    Spacer()
                                }
                                .frame(minHeight: 44)
                                .background(suggestionText.isEmpty || suggestionEmail.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                            }
                            .listRowBackground(Color.clear)
                            .disabled(suggestionText.isEmpty || suggestionEmail.isEmpty || isSendingSuggestion)
                        }
                    }
                    .navigationTitle(suggestIdeasTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(action: {
                                showSuggestIdeas = false
                                suggestionText = ""
                                suggestionEmail = ""
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .onAppear {
                        // Pre-populate email with user's email
                        if suggestionEmail.isEmpty {
                            suggestionEmail = userEmail
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
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isAuthenticated: .constant(true), showOnboarding: $showOnboarding)
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

            // Store original values for change detection
            storeOriginalValues()
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
            .foregroundColor(.blue)
            .frame(width: 100)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .liquidGlassForm()
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
                    let tip_target_percentage: Double
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
                    tip_target_percentage: Double(tipTargetPercentage) ?? 0,
                    target_sales_daily: Double(targetSalesDaily) ?? 0,
                    target_sales_weekly: hasVariableSchedule ? 0 : (Double(targetSalesWeekly) ?? 0),
                    target_sales_monthly: hasVariableSchedule ? 0 : (Double(targetSalesMonthly) ?? 0),
                    target_hours_daily: Double(targetHoursDaily) ?? 0,
                    target_hours_weekly: hasVariableSchedule ? 0 : (Double(targetHoursWeekly) ?? 0),
                    target_hours_monthly: hasVariableSchedule ? 0 : (Double(targetHoursMonthly) ?? 0),
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
                    // Update original values after successful save
                    storeOriginalValues()

                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()

                    // Navigate back to dashboard after successful save
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        selectedTab = "dashboard"
                    }
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
            // Get the user session before deletion
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            let token = session.accessToken

            print("🗑️ Starting account deletion for user: \(userId)")

            // Step 1: Try server-side deletion via Edge Function (preferred method)
            // This handles cascading deletes safely on the server
            guard let url = URL(string: "https://ztzpjsbfzcccvbacgskc.supabase.co/functions/v1/delete-account") else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid delete account URL"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Add request body with user ID for verification
            let requestBody: [String: Any] = [
                "user_id": userId.uuidString,
                "confirm_deletion": true
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Server-side account deletion successful")
                    await MainActor.run {
                        isDeletingAccount = false
                    }
                    return
                } else {
                    print("⚠️ Server-side deletion failed, attempting client-side cleanup...")

                    // If server-side deletion fails, attempt client-side cleanup
                    try await performClientSideDataCleanup(userId: userId)

                    // Parse server error for user feedback
                    struct ErrorResponse: Decodable {
                        let success: Bool
                        let error: String?
                    }

                    let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                    let serverError = errorData?.error ?? "Server-side deletion failed"
                    print("❌ Server deletion error: \(serverError)")

                    await MainActor.run {
                        isDeletingAccount = false
                        errorMessage = "Account data cleaned up, but some server operations failed. Please contact support if issues persist."
                        showError = true
                    }
                }
            }
        } catch {
            print("❌ Account deletion failed: \(error)")

            // Attempt client-side cleanup as fallback
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                try await performClientSideDataCleanup(userId: session.user.id)

                await MainActor.run {
                    isDeletingAccount = false
                    errorMessage = "Account data cleaned up locally. Some server data may remain - please contact support."
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    errorMessage = "Failed to delete account: \(error.localizedDescription). Please contact support."
                    showError = true
                }
            }
        }
    }

    // MARK: - Client-Side Data Cleanup
    private func performClientSideDataCleanup(userId: UUID) async throws {
        print("🧹 Starting client-side data cleanup for user: \(userId)")

        // Delete in reverse order of dependencies to avoid foreign key constraints

        // 1. Delete shift_income records (has foreign keys to shifts and users)
        print("🗑️ Deleting shift income records...")
        try await SupabaseManager.shared.client
            .from("shift_income")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("✅ Shift income records deleted")

        // 2. Delete shifts records (has foreign key to users and employers)
        print("🗑️ Deleting shift records...")
        try await SupabaseManager.shared.client
            .from("shifts")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("✅ Shift records deleted")

        // 3. Delete employers records (has foreign key to users)
        print("🗑️ Deleting employer records...")
        try await SupabaseManager.shared.client
            .from("employers")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("✅ Employer records deleted")

        // 4. Delete users_profile record (has foreign key to users)
        print("🗑️ Deleting user profile...")
        try await SupabaseManager.shared.client
            .from("users_profile")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("✅ User profile deleted")

        // 5. Clear local app storage
        print("🗑️ Clearing local storage...")
        UserDefaults.standard.removeObject(forKey: "defaultHourlyRate")
        UserDefaults.standard.removeObject(forKey: "useMultipleEmployers")
        UserDefaults.standard.removeObject(forKey: "hasVariableSchedule")
        UserDefaults.standard.removeObject(forKey: "language")
        UserDefaults.standard.removeObject(forKey: "hasSetLanguage")
        UserDefaults.standard.synchronize()
        print("✅ Local storage cleared")

        // 6. Finally, delete the auth user (this should cascade delete anything remaining)
        print("🗑️ Deleting auth user...")
        try await SupabaseManager.shared.client.auth.admin.deleteUser(id: userId, shouldSoftDelete: false)
        print("✅ Auth user deleted")

        print("🎉 Client-side data cleanup completed successfully")
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
                    "userEmail": suggestionEmail.isEmpty ? userEmail : suggestionEmail,
                    "replyEmail": suggestionEmail
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        await MainActor.run {
                            isSendingSuggestion = false
                            showThankYouMessage = true
                            HapticFeedback.success()

                            // Auto-close the form after 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showSuggestIdeas = false
                                showThankYouMessage = false
                                suggestionText = ""
                                suggestionEmail = ""
                            }
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

    // MARK: - Security Localization
    var securityTitle: String {
        switch language {
        case "fr": return "Sécurité"
        case "es": return "Seguridad"
        default: return "Security"
        }
    }

    var faceIDText: String {
        switch language {
        case "fr": return "Face ID / Touch ID"
        case "es": return "Face ID / Touch ID"
        default: return "Face ID / Touch ID"
        }
    }

    var pinCodeText: String {
        switch language {
        case "fr": return "Code PIN"
        case "es": return "Código PIN"
        default: return "PIN Code"
        }
    }

    var securityOptionsLabel: String {
        switch language {
        case "fr": return "Options de sécurité"
        case "es": return "Opciones de seguridad"
        default: return "Security Options"
        }
    }

    var currentSecurityText: String {
        switch securityManager.currentSecurityType {
        case .biometric:
            return faceIDText
        case .pinCode:
            return pinCodeText
        case .none:
            return noSecurityText
        default:
            return noSecurityText
        }
    }

    var noSecurityText: String {
        switch language {
        case "fr": return "Aucune sécurité"
        case "es": return "Sin seguridad"
        default: return "No Security"
        }
    }

    var securityDescriptionText: String {
        switch language {
        case "fr": return "Protégez vos données financières sensibles avec Face ID ou un code PIN"
        case "es": return "Proteja sus datos financieros confidenciales con Face ID o código PIN"
        default: return "Protect your sensitive financial data with Face ID or PIN code"
        }
    }

    var setPINTitle: String {
        switch language {
        case "fr": return "Définir le code PIN"
        case "es": return "Establecer código PIN"
        default: return "Set PIN Code"
        }
    }

    var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
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
        case "fr": return "Êtes-vous sûr de vouloir supprimer votre compte? Cette action est irréversible.\n\nRappel: Vous devez également aller dans votre compte Apple pour annuler votre abonnement."
        case "es": return "¿Está seguro de que desea eliminar su cuenta? Esta acción es irreversible.\n\nRecordatorio: También debe ir a su cuenta de Apple para cancelar su suscripción."
        default: return "Are you sure you want to delete your account? This action cannot be undone.\n\nReminder: You must also go to your Apple account to cancel your subscription."
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

    var variableScheduleLabel: String {
        switch language {
        case "fr": return "Horaire variable"
        case "es": return "Horario variable"
        default: return "Variable Schedule"
        }
    }

    var variableScheduleDescription: String {
        switch language {
        case "fr": return "J'ai un horaire de travail variable"
        case "es": return "Tengo un horario de trabajo variable"
        default: return "I have a variable work schedule"
        }
    }

    var variableScheduleEnabledTitle: String {
        switch language {
        case "fr": return "Mode horaire variable activé"
        case "es": return "Modo horario variable activado"
        default: return "Variable Schedule Mode Active"
        }
    }

    var variableScheduleEnabledMessage: String {
        switch language {
        case "fr": return "Les objectifs hebdomadaires et mensuels pour les ventes et les heures sont désactivés. Seuls les objectifs quotidiens sont visibles car ils sont plus pertinents pour les horaires variables."
        case "es": return "Los objetivos semanales y mensuales para ventas y horas están desactivados. Solo los objetivos diarios son visibles porque son más relevantes para horarios variables."
        default: return "Weekly and monthly targets for sales and hours are hidden. Only daily targets are shown as they're more relevant for variable schedules."
        }
    }

    var variableScheduleNoteTitle: String {
        switch language {
        case "fr": return "Horaire variable"
        case "es": return "Horario variable"
        default: return "Variable Schedule"
        }
    }

    var variableScheduleNoteMessage: String {
        switch language {
        case "fr": return "Si vous avez un horaire variable, vous pouvez utiliser uniquement les objectifs quotidiens, qui seront plus pertinents. Les objectifs hebdomadaires et mensuels ne sont pas significatifs si vous ne travaillez pas un nombre fixe de jours."
        case "es": return "Si tienes un horario variable, puedes usar solo los objetivos diarios, que serán más relevantes. Los objetivos semanales y mensuales no tienen sentido si no trabajas un número fijo de días."
        default: return "If you have a variable schedule, you can just use daily targets, which will be more relevant. Weekly and monthly targets don't make sense if you don't work a fixed number of days."
        }
    }

    var variableScheduleHoursNoteMessage: String {
        switch language {
        case "fr": return "Si vous avez un horaire variable, vous pouvez utiliser uniquement les objectifs d'heures quotidiens, qui seront plus pertinents. Les objectifs hebdomadaires et mensuels ne sont pas significatifs si vous ne travaillez pas un nombre fixe de jours."
        case "es": return "Si tienes un horario variable, puedes usar solo los objetivos de horas diarios, que serán más relevantes. Los objetivos semanales y mensuales no tienen sentido si no trabajas un número fijo de días."
        default: return "If you have a variable schedule, you can just use daily hours targets, which will be more relevant. Weekly and monthly targets don't make sense if you don't work a fixed number of days."
        }
    }

    var tipPercentageTargetLabel: String {
        switch language {
        case "fr": return "Pourcentage de pourboire cible"
        case "es": return "Porcentaje objetivo de propinas"
        default: return "Target Tip Percentage"
        }
    }

    var tipPercentageNoteTitle: String {
        switch language {
        case "fr": return "Pourcentage des ventes"
        case "es": return "Porcentaje de ventas"
        default: return "Percentage of Sales"
        }
    }

    var tipPercentageNoteMessage: String {
        switch language {
        case "fr": return "Définissez votre objectif de pourboire en pourcentage de vos ventes totales. Par exemple, 15% signifie que vous visez 15% de vos ventes en pourboires."
        case "es": return "Establezca su objetivo de propinas como porcentaje de sus ventas totales. Por ejemplo, 15% significa que apunta a 15% de sus ventas en propinas."
        default: return "Set your tip goal as a percentage of your total sales. For example, 15% means you aim for 15% of your sales in tips."
        }
    }

    var useMultipleEmployersDescriptionText: String {
        switch language {
        case "fr": return "Suivre les quarts de travail avec différents employeurs"
        case "es": return "Seguir turnos con diferentes empleadores"
        default: return "Track shifts across different employers"
        }
    }

    var setYourGoalsTitle: String {
        switch language {
        case "fr": return "🎯 Fixez vos objectifs"
        case "es": return "🎯 Establece tus metas"
        default: return "🎯 Set your goals"
        }
    }

    var setYourGoalsDescription: String {
        switch language {
        case "fr": return "Définissez des objectifs quotidiens, hebdomadaires et mensuels. Votre tableau de bord affichera les progrès comme '2.0/8h' pour les heures travaillées vs prévues."
        case "es": return "Establezca objetivos diarios, semanales y mensuales. Su panel mostrará el progreso como '2.0/8h' para horas trabajadas vs esperadas."
        default: return "Set daily, weekly, and monthly targets. Your dashboard will show progress like '2.0/8h' for hours worked vs expected."
        }
    }
    
    private var suggestIdeasSheet: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if showThankYouMessage {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text(thankYouTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(thankYouMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()
                }
                .padding()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showSuggestIdeas = false
                        showThankYouMessage = false
                        suggestionText = ""
                        suggestionEmail = ""
                    }
                }
            } else {
                VStack(spacing: 0) {
                    // iOS 26 Style Header
                    HStack {
                        // Cancel Button with iOS 26 style
                        Button(action: {
                            showSuggestIdeas = false
                            suggestionText = ""
                            suggestionEmail = ""
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Text(suggestIdeasTitle)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()

                        // Send Button with iOS 26 style
                        Button(action: {
                            HapticFeedback.medium()
                            sendSuggestion()
                        }) {
                            if isSendingSuggestion {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .frame(width: 32, height: 32)
                                    .background(suggestionText.isEmpty || suggestionEmail.isEmpty ? Color.gray : Color.blue)
                                    .clipShape(Circle())
                            }
                        }
                        .disabled(suggestionText.isEmpty || suggestionEmail.isEmpty || isSendingSuggestion)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Suggestion Card - iOS 26 Style
                            VStack(alignment: .leading, spacing: 16) {
                                Label(yourSuggestionHeader, systemImage: "lightbulb.fill")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(suggestionFooter)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                // Email field first
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(suggestionEmailPlaceholder)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    TextField(suggestionEmailPlaceholder, text: $suggestionEmail)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding()
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .textContentType(.emailAddress)
                                }

                                // Suggestion text field second
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(yourSuggestionHeader)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    TextEditor(text: $suggestionText)
                                        .font(.body)
                                        .frame(minHeight: 120)
                                        .padding(12)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .scrollContentBackground(.hidden)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

                            Spacer()
                                .frame(height: 30)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 10)
                    }
                }
                .onAppear {
                    // Pre-populate email with user's email
                    if suggestionEmail.isEmpty {
                        suggestionEmail = userEmail
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

    var thankYouTitle: String {
        switch language {
        case "fr": return "Merci!"
        case "es": return "¡Gracias!"
        default: return "Thank You!"
        }
    }

    var thankYouMessage: String {
        switch language {
        case "fr": return "Merci pour vos commentaires, nous l'apprécions."
        case "es": return "Gracias por sus comentarios, lo apreciamos."
        default: return "Thank you for your feedback, we appreciate it."
        }
    }

    var suggestionEmailPlaceholder: String {
        switch language {
        case "fr": return "Votre adresse email"
        case "es": return "Su dirección de correo"
        default: return "Your email address"
        }
    }

    // MARK: - Unsaved Changes Detection

    // Unsaved changes detection
    private var hasUnsavedChanges: Bool {
        guard let original = originalValues else { return false }

        return original.defaultHourlyRate != defaultHourlyRate ||
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
               original.defaultEmployerId != defaultEmployerId
    }

    private func storeOriginalValues() {
        originalValues = OriginalSettings(
            defaultHourlyRate: defaultHourlyRate,
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
            defaultEmployerId: defaultEmployerId
        )
    }

    // Localized strings for unsaved changes alert
    private var unsavedChangesTitle: String {
        switch language {
        case "fr": return "Modifications non enregistrées"
        case "es": return "Cambios sin guardar"
        default: return "Unsaved Changes"
        }
    }

    private var unsavedChangesMessage: String {
        switch language {
        case "fr": return "Vous avez des modifications non enregistrées. Voulez-vous les enregistrer ou les annuler?"
        case "es": return "Tienes cambios sin guardar. ¿Quieres guardarlos o descartarlos?"
        default: return "You have unsaved changes. Do you want to save them or discard them?"
        }
    }

    private var saveButton: String {
        switch language {
        case "fr": return "Enregistrer"
        case "es": return "Guardar"
        default: return "Save"
        }
    }

    private var discardButton: String {
        switch language {
        case "fr": return "Ignorer"
        case "es": return "Descartar"
        default: return "Discard"
        }
    }

    private var howToUseText: String {
        switch language {
        case "fr": return "Comment utiliser ProTip365"
        case "es": return "Cómo usar ProTip365"
        default: return "How to Use ProTip365"
        }
    }

    // Cancel Subscription Strings
    private var cancelSubscriptionTitle: String {
        switch language {
        case "fr": return "Annuler l'abonnement"
        case "es": return "Cancelar suscripción"
        default: return "Cancel Subscription"
        }
    }

    private var cancelSubscriptionInstructions: String {
        switch language {
        case "fr": return "Allez dans votre compte Apple pour gérer votre abonnement. Puisque l'abonnement est géré par Apple, vous devez l'annuler directement dans vos paramètres Apple."
        case "es": return "Ve a tu cuenta de Apple para gestionar tu suscripción. Como la suscripción es gestionada por Apple, debes cancelarla directamente en tu configuración de Apple."
        default: return "Go to your Apple account to manage your subscription. Since the subscription is managed by Apple, you must cancel it directly in your Apple settings."
        }
    }

    private var cancelSubscriptionWarning: String {
        switch language {
        case "fr": return "⚠️ Important: Vous ne pourrez plus utiliser l'application après l'annulation. Pensez à exporter vos données avant de procéder."
        case "es": return "⚠️ Importante: No podrás usar la aplicación después de cancelar. Considera exportar tus datos antes de proceder."
        default: return "⚠️ Important: You will not be able to use the app after canceling. Consider exporting your data before proceeding."
        }
    }

    private var goToAppleAccountText: String {
        switch language {
        case "fr": return "Aller aux paramètres Apple"
        case "es": return "Ir a configuración de Apple"
        default: return "Go to Apple Settings"
        }
    }
}
