import SwiftUI
import Supabase

struct ProfileSettingsSection: View {
    @Binding var userEmail: String
    @Binding var defaultHourlyRate: String
    @Binding var tipTargetPercentage: String
    @Binding var weekStartDay: Int
    @Binding var useMultipleEmployers: Bool
    @Binding var defaultEmployerId: UUID?
    @Binding var employers: [Employer]
    @Binding var showEmployerPicker: Bool
    @Binding var showWeekStartPicker: Bool

    let language: String
    private let localization: SettingsLocalization

    init(
        userEmail: Binding<String>,
        defaultHourlyRate: Binding<String>,
        tipTargetPercentage: Binding<String>,
        weekStartDay: Binding<Int>,
        useMultipleEmployers: Binding<Bool>,
        defaultEmployerId: Binding<UUID?>,
        employers: Binding<[Employer]>,
        showEmployerPicker: Binding<Bool>,
        showWeekStartPicker: Binding<Bool>,
        language: String
    ) {
        self._userEmail = userEmail
        self._defaultHourlyRate = defaultHourlyRate
        self._tipTargetPercentage = tipTargetPercentage
        self._weekStartDay = weekStartDay
        self._useMultipleEmployers = useMultipleEmployers
        self._defaultEmployerId = defaultEmployerId
        self._employers = employers
        self._showEmployerPicker = showEmployerPicker
        self._showWeekStartPicker = showWeekStartPicker
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        Section(localization.profileSection) {
            VStack(spacing: Constants.formFieldSpacing) {
                // User Email (read-only)
                HStack {
                    Text("Email")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(userEmail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(Constants.formPadding)
                .liquidGlassForm()

                // Default Hourly Rate
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.defaultHourlyRate)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack {
                        Text("$")
                            .font(.body)
                            .foregroundStyle(.primary)
                        TextField("15.00", text: $defaultHourlyRate)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(LiquidGlassTextFieldStyle())
                    }
                }
                .padding(Constants.formPadding)
                .liquidGlassForm()

                // Tip Target Percentage
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.tipTargetPercentage)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack {
                        TextField("18", text: $tipTargetPercentage)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(LiquidGlassTextFieldStyle())
                        Text("%")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(Constants.formPadding)
                .liquidGlassForm()

                // Week Start Day
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.weekStartDay)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Button(action: { showWeekStartPicker = true }) {
                        HStack {
                            Text(WeekStartDay(rawValue: weekStartDay)?.name(language: language) ?? "Sunday")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Constants.formPadding)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .liquidGlassForm()

                // Use Multiple Employers Toggle
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(localization.useMultipleEmployers)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: $useMultipleEmployers)
                            .labelsHidden()
                    }
                }
                .padding(Constants.formPadding)
                .liquidGlassForm()

                // Default Employer (if multiple employers enabled)
                if useMultipleEmployers {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.defaultEmployer)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Button(action: { showEmployerPicker = true }) {
                            HStack {
                                if let defaultEmployerId = defaultEmployerId,
                                   let employer = employers.first(where: { $0.id == defaultEmployerId }) {
                                    Text(employer.name)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Select Employer")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(Constants.formPadding)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .liquidGlassForm()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .sheet(isPresented: $showWeekStartPicker) {
            WeekStartPickerView(selectedDay: $weekStartDay, language: language)
        }
        .sheet(isPresented: $showEmployerPicker) {
            EmployerPickerView(
                selectedEmployerId: $defaultEmployerId,
                employers: employers,
                language: language
            )
        }
    }
}

// MARK: - Week Start Picker

struct WeekStartPickerView: View {
    @Binding var selectedDay: Int
    @Environment(\.dismiss) private var dismiss
    let language: String
    private let localization: SettingsLocalization

    init(selectedDay: Binding<Int>, language: String) {
        self._selectedDay = selectedDay
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(WeekStartDay.allCases) { day in
                    Button(action: {
                        selectedDay = day.rawValue
                        dismiss()
                    }) {
                        HStack {
                            Text(day.name(language: language))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedDay == day.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(localization.weekStartDay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.doneButton) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Employer Picker

struct EmployerPickerView: View {
    @Binding var selectedEmployerId: UUID?
    @Environment(\.dismiss) private var dismiss
    let employers: [Employer]
    let language: String
    private let localization: SettingsLocalization

    init(selectedEmployerId: Binding<UUID?>, employers: [Employer], language: String) {
        self._selectedEmployerId = selectedEmployerId
        self.employers = employers
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(employers) { employer in
                    Button(action: {
                        selectedEmployerId = employer.id
                        dismiss()
                    }) {
                        HStack {
                            Text(employer.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedEmployerId == employer.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(localization.defaultEmployer)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.doneButton) {
                        dismiss()
                    }
                }
            }
        }
    }
}