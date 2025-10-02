import SwiftUI

struct WorkDefaultsSection: View {
    @Binding var defaultHourlyRate: String
    @Binding var averageDeductionPercentage: String
    @Binding var useMultipleEmployers: Bool
    @Binding var hasVariableSchedule: Bool
    @Binding var defaultEmployerId: UUID?
    @Binding var employers: [Employer]
    @Binding var showEmployerPicker: Bool
    @Binding var showWeekStartPicker: Bool
    @Binding var weekStartDay: Int
    @Binding var defaultAlert: String
    @Binding var showDefaultAlertPicker: Bool

    let language: String
    private let localization: SettingsLocalization

    @AppStorage("useMultipleEmployers") private var useMultipleEmployersStorage = false
    private let alertOptions = ["None", "15 minutes", "30 minutes", "60 minutes", "1 day before"]

    init(
        defaultHourlyRate: Binding<String>,
        averageDeductionPercentage: Binding<String>,
        useMultipleEmployers: Binding<Bool>,
        hasVariableSchedule: Binding<Bool>,
        defaultEmployerId: Binding<UUID?>,
        employers: Binding<[Employer]>,
        showEmployerPicker: Binding<Bool>,
        showWeekStartPicker: Binding<Bool>,
        weekStartDay: Binding<Int>,
        defaultAlert: Binding<String>,
        showDefaultAlertPicker: Binding<Bool>,
        language: String
    ) {
        self._defaultHourlyRate = defaultHourlyRate
        self._averageDeductionPercentage = averageDeductionPercentage
        self._useMultipleEmployers = useMultipleEmployers
        self._hasVariableSchedule = hasVariableSchedule
        self._defaultEmployerId = defaultEmployerId
        self._employers = employers
        self._showEmployerPicker = showEmployerPicker
        self._showWeekStartPicker = showWeekStartPicker
        self._weekStartDay = weekStartDay
        self._defaultAlert = defaultAlert
        self._showDefaultAlertPicker = showDefaultAlertPicker
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: IconNames.Navigation.employersFill)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.workDefaultsSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            // Hourly Rate
            HStack {
                Text(localization.hourlyRateLabel)
                    .foregroundStyle(.primary)
                Spacer()
                HStack {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("15.00", text: $defaultHourlyRate, onEditingChanged: { editing in
                        if editing && (defaultHourlyRate == "15.00" || defaultHourlyRate == "0.00") {
                            defaultHourlyRate = ""
                        }
                        HapticFeedback.selection()
                    })
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.primary)
                }
                .frame(width: 100)
                .padding(8)
                .liquidGlassForm()
            }

            // Average Deduction Percentage
            HStack {
                Text(localization.averageDeductionLabel)
                    .foregroundStyle(.primary)
                Spacer()
                TextField("30", text: $averageDeductionPercentage, onEditingChanged: { editing in
                    if editing && (averageDeductionPercentage == "30" || averageDeductionPercentage == "0") {
                        averageDeductionPercentage = ""
                    }
                    HapticFeedback.selection()
                })
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
                .onChange(of: averageDeductionPercentage) { _, newValue in
                    // Validate input to ensure it's between 0 and 100
                    if let value = Double(newValue), value > 100 {
                        averageDeductionPercentage = "100"
                    }
                }
                .frame(width: 100)
                .padding(8)
                .liquidGlassForm()
            }

            // Explanation text for average deduction
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: IconNames.Status.info)
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Text(localization.averageDeductionNoteTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                Text(localization.averageDeductionNoteMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Multiple Employers Toggle
            LiquidGlassToggle(
                localization.useMultipleEmployers,
                description: useMultipleEmployersDescriptionText,
                isOn: $useMultipleEmployers
            ) { newValue in
                useMultipleEmployersStorage = newValue
            }

            // Variable Schedule Toggle
            LiquidGlassToggle(
                localization.variableScheduleLabel,
                description: localization.variableScheduleDescription,
                isOn: $hasVariableSchedule
            ) { newValue in
                // Variable schedule setting changed
                // When enabled, this will hide weekly and monthly targets
            }

            // Explanation text for variable schedule
            if hasVariableSchedule {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: IconNames.Status.info)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Text(localization.variableScheduleEnabledTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    Text(localization.variableScheduleEnabledMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Default Employer Picker (if multiple employers enabled)
            if useMultipleEmployers && !employers.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text(localization.defaultEmployer)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEmployerPicker.toggle()
                                showWeekStartPicker = false
                            }
                        }) {
                            Text(employers.first(where: { $0.id == defaultEmployerId })?.name ?? localization.noneLabel)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    if showEmployerPicker {
                        Picker("", selection: $defaultEmployerId) {
                            Text(localization.noneLabel).tag(nil as UUID?)
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

            // Week Start Day Picker
            VStack(spacing: 0) {
                HStack {
                    Text(localization.weekStartDay)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showWeekStartPicker.toggle()
                            showEmployerPicker = false
                        }
                    }) {
                        Text(localizedWeekDay(weekStartDay))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGroupedBackground))
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

            // Default Alert Picker
            VStack(spacing: 0) {
                HStack {
                    Text(localization.defaultAlertLabel)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDefaultAlertPicker.toggle()
                            showWeekStartPicker = false
                            showEmployerPicker = false
                        }
                    }) {
                        Text(localizedAlertText(defaultAlert))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                if showDefaultAlertPicker {
                    Picker("", selection: $defaultAlert) {
                        ForEach(alertOptions, id: \.self) { option in
                            Text(localizedAlertText(option)).tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: defaultAlert) { _, _ in
                        HapticFeedback.selection()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDefaultAlertPicker = false
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
    }

    // MARK: - Helper Methods

    private func localizedWeekDay(_ index: Int) -> String {
        let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        switch language {
        case "fr":
            return ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"][index]
        case "es":
            return ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"][index]
        default:
            return weekDays[index]
        }
    }

    private var useMultipleEmployersDescriptionText: String {
        switch language {
        case "fr": return "Suivre les quarts de travail avec différents employeurs"
        case "es": return "Seguir turnos con diferentes empleadores"
        default: return "Track shifts across different employers"
        }
    }

    private func localizedAlertText(_ alertOption: String) -> String {
        switch alertOption {
        case "None":
            switch language {
            case "fr": return "Aucune"
            case "es": return "Ninguna"
            default: return "None"
            }
        case "15 minutes":
            switch language {
            case "fr": return "15 minutes avant"
            case "es": return "15 minutos antes"
            default: return "15 minutes before"
            }
        case "30 minutes":
            switch language {
            case "fr": return "30 minutes avant"
            case "es": return "30 minutos antes"
            default: return "30 minutes before"
            }
        case "60 minutes":
            switch language {
            case "fr": return "1 heure avant"
            case "es": return "1 hora antes"
            default: return "1 hour before"
            }
        case "1 day before":
            switch language {
            case "fr": return "1 jour avant"
            case "es": return "1 día antes"
            default: return "1 day before"
            }
        default:
            return alertOption
        }
    }
}