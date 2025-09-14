import SwiftUI
import Supabase

struct OnboardingView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showOnboarding: Bool
    @State private var currentStep = 1
    @State private var selectedLanguage = "en"
    @State private var useMultipleEmployers = false
    @State private var weekStartDay = 0
    @State private var selectedSecurityType = SecurityType.none
    @State private var hasVariableSchedule = false
    @State private var tipTargetPercentage = "15"
    @State private var targetSalesDaily = ""
    @State private var targetSalesWeekly = ""
    @State private var targetSalesMonthly = ""
    @State private var targetHoursDaily = ""
    @State private var targetHoursWeekly = ""
    @State private var targetHoursMonthly = ""
    @State private var showPINSetup = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @StateObject private var securityManager = SecurityManager()
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?

    enum Field {
        case tipPercentage, dailySales, weeklySales, monthlySales, dailyHours, weeklyHours, monthlyHours
    }

    private let totalSteps = 7
    let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        NavigationStack {
            ZStack {
                // Consistent app background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding()

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // App Logo and Welcome
                            VStack(spacing: 16) {
                                Image("Logo2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)

                                VStack(spacing: 8) {
                                    Text(welcomeTitle)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)

                                    Text(currentStepDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 16)

                            // Step Content
                            Group {
                                switch currentStep {
                                case 1:
                                    languageStepView
                                case 2:
                                    multipleEmployersStepView
                                case 3:
                                    weekStartStepView
                                case 4:
                                    securityStepView
                                case 5:
                                    variableScheduleStepView
                                case 6:
                                    salesAndTipTargetsStepView
                                case 7:
                                    howToUseStepView
                                default:
                                    EmptyView()
                                }
                            }
                            .padding(.horizontal)

                            // Navigation Buttons
                            HStack(spacing: 16) {
                                if currentStep > 1 {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentStep -= 1
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Text(backButtonText)
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }

                                Spacer()

                                Button(action: handleNextStep) {
                                    Group {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            HStack {
                                                Text(currentStep == totalSteps ? finishButtonText : nextButtonText)
                                                if currentStep < totalSteps {
                                                    Image(systemName: "chevron.right")
                                                }
                                            }
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .opacity(isStepValid ? 1.0 : 0.6)
                                }
                                .disabled(!isStepValid || isLoading)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .padding(.bottom, 20) // Ensure buttons stay on screen
                    }
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelButtonText) {
                        showOnboarding = false
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showPINSetup) {
            NavigationStack {
                PINEntryView(
                    securityManager: securityManager,
                    isSettingPIN: true,
                    onSuccess: {
                        showPINSetup = false
                        selectedSecurityType = .pinCode
                    },
                    onCancel: {
                        showPINSetup = false
                        selectedSecurityType = .none
                    }
                )
                .navigationTitle("Set PIN Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showPINSetup = false
                            selectedSecurityType = .none
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onTapGesture {
            focusedField = nil
        }
        .onAppear {
            selectedLanguage = language
        }
    }

    // MARK: - Step Views

    private var languageStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label(languageSelectionTitle, systemImage: "globe")
                    .font(.headline)
                    .foregroundColor(.primary)

                Menu {
                    Button("English") {
                        selectedLanguage = "en"
                        language = "en"
                        HapticFeedback.selection()
                    }
                    Button("Français") {
                        selectedLanguage = "fr"
                        language = "fr"
                        HapticFeedback.selection()
                    }
                    Button("Español") {
                        selectedLanguage = "es"
                        language = "es"
                        HapticFeedback.selection()
                    }
                } label: {
                    HStack {
                        Text(selectedLanguage == "en" ? "English" : selectedLanguage == "fr" ? "Français" : "Español")
                            .foregroundColor(.primary)
                        Spacer()
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
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    private var multipleEmployersStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(multipleEmployersTitle, systemImage: "building.2.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                Toggle(multipleEmployersQuestion, isOn: $useMultipleEmployers)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: useMultipleEmployers) { _, _ in
                        HapticFeedback.selection()
                    }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(multipleEmployersExplanationTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    Text(multipleEmployersExplanation)
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
        }
    }

    private var weekStartStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(weekStartTitle, systemImage: "calendar")
                    .font(.headline)
                    .foregroundColor(.primary)

                Menu {
                    ForEach(0..<7) { index in
                        Button(localizedWeekDay(index)) {
                            weekStartDay = index
                            HapticFeedback.selection()
                        }
                    }
                } label: {
                    HStack {
                        Text(localizedWeekDay(weekStartDay))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(weekStartExplanationTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    Text(weekStartExplanation)
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
        }
    }

    private var securityStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(securityTitle, systemImage: "lock.shield")
                    .font(.headline)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(securityExplanationTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    Text(securityExplanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Menu {
                    Button(action: {
                        selectedSecurityType = .none
                        HapticFeedback.selection()
                    }) {
                        Label(noSecurityText, systemImage: "lock.open")
                    }

                    Button(action: {
                        selectedSecurityType = .biometric
                        HapticFeedback.selection()
                    }) {
                        Label(faceIDText, systemImage: "faceid")
                    }

                    Button(action: {
                        showPINSetup = true
                        HapticFeedback.selection()
                    }) {
                        Label(pinCodeText, systemImage: "number.square")
                    }
                } label: {
                    HStack {
                        Text(currentSecurityText)
                            .foregroundColor(.primary)
                        Spacer()
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
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    private var variableScheduleStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(variableScheduleTitle, systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundColor(.primary)

                Toggle(variableScheduleQuestion, isOn: $hasVariableSchedule)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: hasVariableSchedule) { _, _ in
                        HapticFeedback.selection()
                    }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(variableScheduleExplanationTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    Text(variableScheduleExplanation)
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
        }
    }

    private var salesAndTipTargetsStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(salesAndTipTargetsTitle, systemImage: "banknote.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Tip Target Section
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
                        .focused($focusedField, equals: .tipPercentage)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 100)
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Sales Targets Section
                targetRow(label: dailySalesTargetLabel,
                          icon: "chart.line.uptrend.xyaxis",
                          value: $targetSalesDaily,
                          placeholder: "500.00",
                          color: .primary,
                          focusField: .dailySales)

                if !hasVariableSchedule {
                    targetRow(label: weeklySalesTargetLabel,
                              icon: "chart.bar.fill",
                              value: $targetSalesWeekly,
                              placeholder: "3500.00",
                              color: .primary,
                              focusField: .weeklySales)

                    targetRow(label: monthlySalesTargetLabel,
                              icon: "chart.pie.fill",
                              value: $targetSalesMonthly,
                              placeholder: "14000.00",
                              color: .primary,
                              focusField: .monthlySales)
                }

                // Daily Hours Target (simplified from the old hours page)
                targetRow(label: dailyHoursTargetLabel,
                          icon: "timer",
                          value: $targetHoursDaily,
                          placeholder: "8",
                          color: .primary,
                          isHours: true,
                          focusField: .dailyHours)

                if !hasVariableSchedule {
                    targetRow(label: weeklyHoursTargetLabel,
                              icon: "timer.circle.fill",
                              value: $targetHoursWeekly,
                              placeholder: "40",
                              color: .primary,
                              isHours: true,
                              focusField: .weeklyHours)

                    targetRow(label: monthlyHoursTargetLabel,
                              icon: "hourglass",
                              value: $targetHoursMonthly,
                              placeholder: "160",
                              color: .primary,
                              isHours: true,
                              focusField: .monthlyHours)
                }

                if hasVariableSchedule {
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
        }
    }

    private var howToUseStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(howToUseTitle, systemImage: "questionmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Step 1: Employers (conditional)
                if useMultipleEmployers {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("1")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue)
                                .clipShape(Circle())
                            Text(step1EmployersTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        Text(step1EmployersDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 32)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Step 2: Calendar & Shifts
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(useMultipleEmployers ? "2" : "1")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.green)
                            .clipShape(Circle())
                        Text(step2CalendarTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text(step2CalendarDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
                .padding(12)
                .background(Color.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Step 3: Entries
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(useMultipleEmployers ? "3" : "2")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.orange)
                            .clipShape(Circle())
                        Text(step3EntriesTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text(step3EntriesDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
                .padding(12)
                .background(Color.orange.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Step 4: Dashboard
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(useMultipleEmployers ? "4" : "3")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.purple)
                            .clipShape(Circle())
                        Text(step4DashboardTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text(step4DashboardDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
                .padding(12)
                .background(Color.purple.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Sync Feature
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text(syncFeaturesTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text(syncFeaturesDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    private var oldTipTargetStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(tipTargetsTitle, systemImage: "banknote.fill")
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
                        .focused($focusedField, equals: .tipPercentage)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 100)
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

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
        }
    }

    private var salesTargetsStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(salesTargetsTitle, systemImage: "cart.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                targetRow(label: dailySalesTargetLabel,
                          icon: "chart.line.uptrend.xyaxis",
                          value: $targetSalesDaily,
                          placeholder: "500.00",
                          color: .primary,
                          focusField: .dailySales)

                if !hasVariableSchedule {
                    targetRow(label: weeklySalesTargetLabel,
                              icon: "chart.bar.fill",
                              value: $targetSalesWeekly,
                              placeholder: "3500.00",
                              color: .primary,
                              focusField: .weeklySales)

                    targetRow(label: monthlySalesTargetLabel,
                              icon: "chart.pie.fill",
                              value: $targetSalesMonthly,
                              placeholder: "14000.00",
                              color: .primary,
                              focusField: .monthlySales)
                }

                if hasVariableSchedule {
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
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    private var hoursTargetsStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(hoursTargetsTitle, systemImage: "clock.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                targetRow(label: dailyHoursTargetLabel,
                          icon: "timer",
                          value: $targetHoursDaily,
                          placeholder: "8",
                          color: .primary,
                          isHours: true,
                          focusField: .dailyHours)

                if !hasVariableSchedule {
                    targetRow(label: weeklyHoursTargetLabel,
                              icon: "timer.circle.fill",
                              value: $targetHoursWeekly,
                              placeholder: "40",
                              color: .primary,
                              isHours: true,
                              focusField: .weeklyHours)

                    targetRow(label: monthlyHoursTargetLabel,
                              icon: "hourglass",
                              value: $targetHoursMonthly,
                              placeholder: "160",
                              color: .primary,
                              isHours: true,
                              focusField: .monthlyHours)
                }

                if hasVariableSchedule {
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
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    @ViewBuilder
    func targetRow(label: String, icon: String, value: Binding<String>, placeholder: String, color: Color, isHours: Bool = false, focusField: Field? = nil) -> some View {
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
            .focused($focusedField, equals: focusField)
            .frame(width: 100)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                HapticFeedback.selection()
            }
        }
    }

    // MARK: - Helper Functions

    private var isStepValid: Bool {
        switch currentStep {
        case 1: return true // Language selection always valid
        case 2: return true // Multiple employers always valid (boolean)
        case 3: return true // Week start always valid
        case 4: return true // Security always valid
        case 5: return true // Variable schedule always valid (boolean)
        case 6: return !tipTargetPercentage.isEmpty && !targetSalesDaily.isEmpty && !targetHoursDaily.isEmpty // All targets required
        case 7: return true // How to use page always valid
        default: return false
        }
    }

    private var stepTitle: String {
        switch language {
        case "fr": return "Étape \(currentStep) sur \(totalSteps)"
        case "es": return "Paso \(currentStep) de \(totalSteps)"
        default: return "Step \(currentStep) of \(totalSteps)"
        }
    }

    private var currentStepDescription: String {
        switch currentStep {
        case 1: return languageStepDescription
        case 2: return multipleEmployersStepDescription
        case 3: return weekStartStepDescription
        case 4: return securityStepDescription
        case 5: return variableScheduleStepDescription
        case 6: return salesAndTipTargetsStepDescription
        case 7: return howToUseStepDescription
        default: return ""
        }
    }

    private var currentSecurityText: String {
        switch selectedSecurityType {
        case .biometric: return faceIDText
        case .pinCode: return pinCodeText
        case .none: return noSecurityText
        default: return noSecurityText
        }
    }

    private func localizedWeekDay(_ index: Int) -> String {
        switch language {
        case "fr":
            return ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"][index]
        case "es":
            return ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"][index]
        default:
            return weekDays[index]
        }
    }

    private func handleNextStep() {
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        isLoading = true

        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id

                struct ProfileUpdate: Encodable {
                    let language: String
                    let use_multiple_employers: Bool
                    let week_start: Int
                    let has_variable_schedule: Bool
                    let tip_target_percentage: Double
                    let target_sales_daily: Double
                    let target_sales_weekly: Double
                    let target_sales_monthly: Double
                    let target_hours_daily: Double
                    let target_hours_weekly: Double
                    let target_hours_monthly: Double
                }

                let updates = ProfileUpdate(
                    language: selectedLanguage,
                    use_multiple_employers: useMultipleEmployers,
                    week_start: weekStartDay,
                    has_variable_schedule: hasVariableSchedule,
                    tip_target_percentage: Double(tipTargetPercentage) ?? 15.0,
                    target_sales_daily: Double(targetSalesDaily) ?? 0,
                    target_sales_weekly: hasVariableSchedule ? 0 : (Double(targetSalesWeekly) ?? 0),
                    target_sales_monthly: hasVariableSchedule ? 0 : (Double(targetSalesMonthly) ?? 0),
                    target_hours_daily: Double(targetHoursDaily) ?? 0,
                    target_hours_weekly: hasVariableSchedule ? 0 : (Double(targetHoursWeekly) ?? 0),
                    target_hours_monthly: hasVariableSchedule ? 0 : (Double(targetHoursMonthly) ?? 0)
                )

                try await SupabaseManager.shared.client
                    .from("users_profile")
                    .update(updates)
                    .eq("user_id", value: userId)
                    .execute()

                // Set security type if not none
                if selectedSecurityType != .none {
                    securityManager.setSecurityType(selectedSecurityType)
                }

                // Update app storage values
                UserDefaults.standard.set(useMultipleEmployers, forKey: "useMultipleEmployers")
                UserDefaults.standard.set(hasVariableSchedule, forKey: "hasVariableSchedule")

                await MainActor.run {
                    language = selectedLanguage
                    showOnboarding = false
                    isLoading = false
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Localization

    // Welcome and General
    private var welcomeTitle: String {
        switch language {
        case "fr": return "Configuration initiale"
        case "es": return "Configuración inicial"
        default: return "Initial Setup"
        }
    }

    private var backButtonText: String {
        switch language {
        case "fr": return "Retour"
        case "es": return "Atrás"
        default: return "Back"
        }
    }

    private var nextButtonText: String {
        switch language {
        case "fr": return "Suivant"
        case "es": return "Siguiente"
        default: return "Next"
        }
    }

    private var finishButtonText: String {
        switch language {
        case "fr": return "Terminer"
        case "es": return "Finalizar"
        default: return "Finish"
        }
    }

    private var skipButtonText: String {
        switch language {
        case "fr": return "Passer"
        case "es": return "Omitir"
        default: return "Skip"
        }
    }

    // Step 1: Language
    private var languageSelectionTitle: String {
        switch language {
        case "fr": return "Choisissez votre langue"
        case "es": return "Elige tu idioma"
        default: return "Choose Your Language"
        }
    }

    private var languageStepDescription: String {
        switch language {
        case "fr": return "Dans quelle langue préférez-vous utiliser l'application?"
        case "es": return "¿En qué idioma prefieres usar la aplicación?"
        default: return "What language would you prefer to use the app in?"
        }
    }

    // Step 2: Multiple Employers
    private var multipleEmployersTitle: String {
        switch language {
        case "fr": return "Employeurs multiples"
        case "es": return "Múltiples empleadores"
        default: return "Multiple Employers"
        }
    }

    private var multipleEmployersQuestion: String {
        switch language {
        case "fr": return "Travaillez-vous pour plusieurs employeurs?"
        case "es": return "¿Trabajas para múltiples empleadores?"
        default: return "Do you work for multiple employers?"
        }
    }

    private var multipleEmployersStepDescription: String {
        switch language {
        case "fr": return "Aidez-nous à personnaliser l'application pour votre situation de travail"
        case "es": return "Ayúdanos a personalizar la aplicación para tu situación laboral"
        default: return "Help us customize the app for your work situation"
        }
    }

    private var multipleEmployersExplanationTitle: String {
        switch language {
        case "fr": return "Pourquoi cette question?"
        case "es": return "¿Por qué esta pregunta?"
        default: return "Why this question?"
        }
    }

    private var multipleEmployersExplanation: String {
        switch language {
        case "fr": return "Si vous avez plusieurs employeurs, vous pourrez créer des quarts de travail et définir des entrées par employeur. Cela vous permettra de mieux organiser et analyser vos revenus par source."
        case "es": return "Si tienes múltiples empleadores, podrás crear turnos y definir entradas por empleador. Esto te permitirá organizar y analizar mejor tus ingresos por fuente."
        default: return "If you have multiple employers, you'll be able to create shifts and define entries per employer. This will help you better organize and analyze your income by source."
        }
    }

    // Step 3: Week Start
    private var weekStartTitle: String {
        switch language {
        case "fr": return "Début de semaine"
        case "es": return "Inicio de semana"
        default: return "Week Start Day"
        }
    }

    private var weekStartStepDescription: String {
        switch language {
        case "fr": return "Quel jour commence votre semaine de travail? Cela affectera vos rapports hebdomadaires."
        case "es": return "¿Qué día comienza tu semana laboral? Esto afectará tus reportes semanales."
        default: return "What day does your work week start? This will affect your weekly reports."
        }
    }

    // Step 4: Security
    private var securityTitle: String {
        switch language {
        case "fr": return "Sécurité"
        case "es": return "Seguridad"
        default: return "Security"
        }
    }

    private var securityStepDescription: String {
        switch language {
        case "fr": return "Sécurisez l'accès à vos données financières sensibles"
        case "es": return "Asegura el acceso a tus datos financieros sensibles"
        default: return "Secure access to your sensitive financial data"
        }
    }

    private var securityExplanationTitle: String {
        switch language {
        case "fr": return "Sécurité supplémentaire"
        case "es": return "Seguridad adicional"
        default: return "Additional Security"
        }
    }

    private var securityExplanation: String {
        switch language {
        case "fr": return "En plus de votre nom d'utilisateur et mot de passe, vous pouvez ajouter une couche de sécurité supplémentaire pour restreindre l'accès à l'application."
        case "es": return "Además de tu nombre de usuario y contraseña, puedes agregar una capa adicional de seguridad para restringir el acceso a la aplicación."
        default: return "On top of your username and password, you can add an additional layer of security to restrict access to the app."
        }
    }

    private var faceIDText: String {
        switch language {
        case "fr": return "Face ID / Touch ID"
        case "es": return "Face ID / Touch ID"
        default: return "Face ID / Touch ID"
        }
    }

    private var pinCodeText: String {
        switch language {
        case "fr": return "Code PIN"
        case "es": return "Código PIN"
        default: return "PIN Code"
        }
    }

    private var noSecurityText: String {
        switch language {
        case "fr": return "Aucune"
        case "es": return "Ninguna"
        default: return "None"
        }
    }

    // Step 5: Variable Schedule
    private var variableScheduleTitle: String {
        switch language {
        case "fr": return "Horaire variable"
        case "es": return "Horario variable"
        default: return "Variable Schedule"
        }
    }

    private var variableScheduleQuestion: String {
        switch language {
        case "fr": return "Avez-vous un horaire de travail variable?"
        case "es": return "¿Tienes un horario de trabajo variable?"
        default: return "Do you have a variable work schedule?"
        }
    }

    private var variableScheduleStepDescription: String {
        switch language {
        case "fr": return "Aidez-nous à configurer vos objectifs en fonction de votre horaire"
        case "es": return "Ayúdanos a configurar tus objetivos según tu horario"
        default: return "Help us set up your goals based on your schedule"
        }
    }

    private var variableScheduleExplanationTitle: String {
        switch language {
        case "fr": return "Pourquoi cette question?"
        case "es": return "¿Por qué esta pregunta?"
        default: return "Why this question?"
        }
    }

    private var variableScheduleExplanation: String {
        switch language {
        case "fr": return "Si vous avez un horaire variable, nous ne configurerons que des objectifs quotidiens au lieu d'objectifs hebdomadaires et mensuels, car ceux-ci sont plus pertinents pour les horaires fixes et définis."
        case "es": return "Si tienes un horario variable, solo configuraremos objetivos diarios en lugar de objetivos semanales y mensuales, ya que estos son más relevantes para horarios fijos y definidos."
        default: return "If you have a variable schedule, we will only set daily targets instead of weekly and monthly targets, as those are more relevant for fixed, defined schedules."
        }
    }

    // Step 6: Tip Targets
    private var tipTargetsTitle: String {
        switch language {
        case "fr": return "Objectifs de pourboires"
        case "es": return "Objetivos de propinas"
        default: return "Tip Targets"
        }
    }

    private var tipTargetStepDescription: String {
        switch language {
        case "fr": return "Définissez votre objectif de pourcentage de pourboire"
        case "es": return "Establece tu objetivo de porcentaje de propinas"
        default: return "Set your tip percentage target"
        }
    }

    private var tipPercentageTargetLabel: String {
        switch language {
        case "fr": return "Pourcentage de pourboire cible"
        case "es": return "Porcentaje objetivo de propinas"
        default: return "Target Tip Percentage"
        }
    }

    private var tipPercentageNoteTitle: String {
        switch language {
        case "fr": return "Pourcentage des ventes"
        case "es": return "Porcentaje de ventas"
        default: return "Percentage of Sales"
        }
    }

    private var tipPercentageNoteMessage: String {
        switch language {
        case "fr": return "Définissez votre objectif de pourboire en pourcentage de vos ventes totales. Par exemple, 15% signifie que vous visez 15% de vos ventes en pourboires."
        case "es": return "Establezca su objetivo de propinas como porcentaje de sus ventas totales. Por ejemplo, 15% significa que apunta a 15% de sus ventas en propinas."
        default: return "Set your tip goal as a percentage of your total sales. For example, 15% means you aim for 15% of your sales in tips."
        }
    }

    // Step 7: Sales Targets
    private var salesTargetsTitle: String {
        switch language {
        case "fr": return "Objectifs de ventes"
        case "es": return "Objetivos de ventas"
        default: return "Sales Targets"
        }
    }

    private var salesTargetsStepDescription: String {
        switch language {
        case "fr": return "Définissez vos objectifs de ventes quotidiens"
        case "es": return "Establece tus objetivos de ventas diarios"
        default: return "Set your sales targets"
        }
    }

    private var dailySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes quotidiennes"
        case "es": return "Ventas diarias"
        default: return "Daily Sales"
        }
    }

    private var weeklySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes hebdomadaires"
        case "es": return "Ventas semanales"
        default: return "Weekly Sales"
        }
    }

    private var monthlySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes mensuelles"
        case "es": return "Ventas mensuales"
        default: return "Monthly Sales"
        }
    }

    // Step 8: Hours Targets
    private var hoursTargetsTitle: String {
        switch language {
        case "fr": return "Objectifs d'heures"
        case "es": return "Objetivos de horas"
        default: return "Hours Targets"
        }
    }

    private var hoursTargetsStepDescription: String {
        switch language {
        case "fr": return "Définissez vos objectifs d'heures de travail"
        case "es": return "Establece tus objetivos de horas de trabajo"
        default: return "Set your work hours targets"
        }
    }

    private var dailyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures quotidiennes"
        case "es": return "Horas diarias"
        default: return "Daily Hours"
        }
    }

    private var weeklyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures hebdomadaires"
        case "es": return "Horas semanales"
        default: return "Weekly Hours"
        }
    }

    private var monthlyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures mensuelles"
        case "es": return "Horas mensuales"
        default: return "Monthly Hours"
        }
    }

    // Variable Schedule Notes
    private var variableScheduleNoteTitle: String {
        switch language {
        case "fr": return "Horaire variable"
        case "es": return "Horario variable"
        default: return "Variable Schedule"
        }
    }

    private var variableScheduleNoteMessage: String {
        switch language {
        case "fr": return "Puisque vous avez un horaire variable, seuls les objectifs quotidiens sont affichés car ils sont plus pertinents pour votre situation."
        case "es": return "Como tienes un horario variable, solo se muestran los objetivos diarios ya que son más relevantes para tu situación."
        default: return "Since you have a variable schedule, only daily targets are shown as they're more relevant for your situation."
        }
    }

    private var variableScheduleHoursNoteMessage: String {
        switch language {
        case "fr": return "Avec un horaire variable, les objectifs d'heures quotidiens sont plus pratiques que les objectifs hebdomadaires ou mensuels."
        case "es": return "Con un horario variable, los objetivos de horas diarios son más prácticos que los objetivos semanales o mensuales."
        default: return "With a variable schedule, daily hours targets are more practical than weekly or monthly targets."
        }
    }

    // Week Start Explanatory Text
    private var weekStartExplanationTitle: String {
        switch language {
        case "fr": return "Pourquoi cette question?"
        case "es": return "¿Por qué esta pregunta?"
        default: return "Why this matters"
        }
    }

    private var weekStartExplanation: String {
        switch language {
        case "fr": return "Ceci définira comment vos rapports hebdomadaires sont calculés et organisés."
        case "es": return "Esto definirá cómo se calculan y organizan tus reportes semanales."
        default: return "This will define how your weekly reports are calculated and organized."
        }
    }

    // Combined Sales and Tip Targets
    private var salesAndTipTargetsTitle: String {
        switch language {
        case "fr": return "Objectifs et cibles"
        case "es": return "Objetivos y metas"
        default: return "Goals & Targets"
        }
    }

    private var salesAndTipTargetsStepDescription: String {
        switch language {
        case "fr": return "Définissez vos objectifs quotidiens pour les pourboires, les ventes et les heures"
        case "es": return "Establece tus objetivos diarios para propinas, ventas y horas"
        default: return "Set your daily goals for tips, sales, and hours"
        }
    }

    // How to Use Page
    private var howToUseTitle: String {
        switch language {
        case "fr": return "Comment utiliser l'app"
        case "es": return "Cómo usar la app"
        default: return "How to Use the App"
        }
    }

    private var howToUseStepDescription: String {
        switch language {
        case "fr": return "Apprenez le processus étape par étape pour suivre vos pourboires"
        case "es": return "Aprende el proceso paso a paso para rastrear tus propinas"
        default: return "Learn the step-by-step process to track your tips"
        }
    }

    // Step 1: Employers
    private var step1EmployersTitle: String {
        switch language {
        case "fr": return "Créer vos employeurs"
        case "es": return "Crear tus empleadores"
        default: return "Create Your Employers"
        }
    }

    private var step1EmployersDescription: String {
        switch language {
        case "fr": return "Commencez par ajouter vos employeurs dans l'onglet Employeurs. Cela vous aidera à organiser vos quarts et revenus par lieu de travail."
        case "es": return "Comienza agregando tus empleadores en la pestaña Empleadores. Esto te ayudará a organizar tus turnos e ingresos por lugar de trabajo."
        default: return "Start by adding your employers in the Employers tab. This helps organize your shifts and income by workplace."
        }
    }

    // Step 2: Calendar
    private var step2CalendarTitle: String {
        switch language {
        case "fr": return "Créer vos quarts dans le calendrier"
        case "es": return "Crear turnos en el calendario"
        default: return "Create Shifts in Calendar"
        }
    }

    private var step2CalendarDescription: String {
        switch language {
        case "fr": return "Utilisez l'onglet Calendrier pour créer des quarts de travail. Définissez vos heures, dates et employeur pour chaque quart."
        case "es": return "Usa la pestaña Calendario para crear turnos de trabajo. Define tus horas, fechas y empleador para cada turno."
        default: return "Use the Calendar tab to create work shifts. Set your hours, dates, and employer for each shift."
        }
    }

    // Step 3: Entries
    private var step3EntriesTitle: String {
        switch language {
        case "fr": return "Ajouter des entrées de pourboires"
        case "es": return "Agregar entradas de propinas"
        default: return "Add Tip Entries"
        }
    }

    private var step3EntriesDescription: String {
        switch language {
        case "fr": return "Pour chaque quart, tapez dessus pour ajouter vos pourboires, ventes et heures réelles. C'est ici que vous enregistrez vos gains quotidiens."
        case "es": return "Para cada turno, tócalo para agregar tus propinas, ventas y horas reales. Aquí es donde registras tus ganancias diarias."
        default: return "For each shift, tap it to add your tips, sales, and actual hours. This is where you record your daily earnings."
        }
    }

    // Step 4: Dashboard
    private var step4DashboardTitle: String {
        switch language {
        case "fr": return "Voir vos statistiques dans le tableau de bord"
        case "es": return "Ver estadísticas en el panel"
        default: return "View Stats in Dashboard"
        }
    }

    private var step4DashboardDescription: String {
        switch language {
        case "fr": return "Le tableau de bord vous montre un résumé de vos gains par jour, semaine, mois et année. Suivez vos progrès et vos tendances facilement."
        case "es": return "El panel te muestra un resumen de tus ganancias por día, semana, mes y año. Rastrea tu progreso y tendencias fácilmente."
        default: return "The dashboard shows you a rollup of your earnings by day, week, month, and year. Track your progress and trends easily."
        }
    }

    // Sync Features
    private var syncFeaturesTitle: String {
        switch language {
        case "fr": return "Synchronisation multi-appareils"
        case "es": return "Sincronización multi-dispositivo"
        default: return "Multi-Device Sync"
        }
    }

    private var syncFeaturesDescription: String {
        switch language {
        case "fr": return "Connectez-vous depuis iPhone, iPad, ou bientôt Android. Toutes vos données se synchronisent automatiquement entre vos appareils."
        case "es": return "Inicia sesión desde iPhone, iPad, o pronto Android. Todos tus datos se sincronizan automáticamente entre dispositivos."
        default: return "Log in from iPhone, iPad, or soon Android. All your data syncs automatically across your devices."
        }
    }

    private var cancelButtonText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

}