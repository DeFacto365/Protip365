import SwiftUI

struct TargetsSettingsSection: View {
    @Binding var targetSalesDaily: String
    @Binding var targetSalesWeekly: String
    @Binding var targetSalesMonthly: String
    @Binding var targetHoursDaily: String
    @Binding var targetHoursWeekly: String
    @Binding var targetHoursMonthly: String

    let language: String
    private let localization: SettingsLocalization

    init(
        targetSalesDaily: Binding<String>,
        targetSalesWeekly: Binding<String>,
        targetSalesMonthly: Binding<String>,
        targetHoursDaily: Binding<String>,
        targetHoursWeekly: Binding<String>,
        targetHoursMonthly: Binding<String>,
        language: String
    ) {
        self._targetSalesDaily = targetSalesDaily
        self._targetSalesWeekly = targetSalesWeekly
        self._targetSalesMonthly = targetSalesMonthly
        self._targetHoursDaily = targetHoursDaily
        self._targetHoursWeekly = targetHoursWeekly
        self._targetHoursMonthly = targetHoursMonthly
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        Section(localization.targetsSection) {
            VStack(spacing: Constants.formSectionSpacing) {
                // Daily Targets
                dailyTargetsView

                // Weekly Targets
                weeklyTargetsView

                // Monthly Targets
                monthlyTargetsView
            }
        }
    }

    private var dailyTargetsView: some View {
        VStack(alignment: .leading, spacing: Constants.formFieldSpacing) {
            Text(localization.dailyTargets)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, Constants.formPadding)

            VStack(spacing: Constants.formFieldSpacing) {
                // Daily Sales Target
                targetInputField(
                    title: localization.targetSales,
                    value: $targetSalesDaily,
                    prefix: "$",
                    placeholder: "500"
                )

                // Daily Hours Target
                targetInputField(
                    title: localization.targetHours,
                    value: $targetHoursDaily,
                    suffix: "h",
                    placeholder: "8"
                )
            }
            .padding(Constants.formPadding)
            .liquidGlassForm()
        }
    }

    private var weeklyTargetsView: some View {
        VStack(alignment: .leading, spacing: Constants.formFieldSpacing) {
            Text(localization.weeklyTargets)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, Constants.formPadding)

            VStack(spacing: Constants.formFieldSpacing) {
                // Weekly Sales Target
                targetInputField(
                    title: localization.targetSales,
                    value: $targetSalesWeekly,
                    prefix: "$",
                    placeholder: "3500"
                )

                // Weekly Hours Target
                targetInputField(
                    title: localization.targetHours,
                    value: $targetHoursWeekly,
                    suffix: "h",
                    placeholder: "40"
                )
            }
            .padding(Constants.formPadding)
            .liquidGlassForm()
        }
    }

    private var monthlyTargetsView: some View {
        VStack(alignment: .leading, spacing: Constants.formFieldSpacing) {
            Text(localization.monthlyTargets)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, Constants.formPadding)

            VStack(spacing: Constants.formFieldSpacing) {
                // Monthly Sales Target
                targetInputField(
                    title: localization.targetSales,
                    value: $targetSalesMonthly,
                    prefix: "$",
                    placeholder: "15000"
                )

                // Monthly Hours Target
                targetInputField(
                    title: localization.targetHours,
                    value: $targetHoursMonthly,
                    suffix: "h",
                    placeholder: "160"
                )
            }
            .padding(Constants.formPadding)
            .liquidGlassForm()
        }
    }

    private func targetInputField(
        title: String,
        value: Binding<String>,
        prefix: String? = nil,
        suffix: String? = nil,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            HStack {
                if let prefix = prefix {
                    Text(prefix)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                TextField(placeholder, text: value)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(LiquidGlassTextFieldStyle())

                if let suffix = suffix {
                    Text(suffix)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}