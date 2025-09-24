import SwiftUI

struct TargetsSettingsSection: View {
    @Binding var tipTargetPercentage: String
    @Binding var targetSalesDaily: String
    @Binding var targetSalesWeekly: String
    @Binding var targetSalesMonthly: String
    @Binding var targetHoursDaily: String
    @Binding var targetHoursWeekly: String
    @Binding var targetHoursMonthly: String
    @Binding var hasVariableSchedule: Bool

    let language: String
    private let localization: SettingsLocalization

    @FocusState private var focusedField: Field?

    enum Field {
        case tipTarget
        case salesDaily
        case salesWeekly
        case salesMonthly
        case hoursDaily
        case hoursWeekly
        case hoursMonthly
    }

    init(
        tipTargetPercentage: Binding<String>,
        targetSalesDaily: Binding<String>,
        targetSalesWeekly: Binding<String>,
        targetSalesMonthly: Binding<String>,
        targetHoursDaily: Binding<String>,
        targetHoursWeekly: Binding<String>,
        targetHoursMonthly: Binding<String>,
        hasVariableSchedule: Binding<Bool>,
        language: String
    ) {
        self._tipTargetPercentage = tipTargetPercentage
        self._targetSalesDaily = targetSalesDaily
        self._targetSalesWeekly = targetSalesWeekly
        self._targetSalesMonthly = targetSalesMonthly
        self._targetHoursDaily = targetHoursDaily
        self._targetHoursWeekly = targetHoursWeekly
        self._targetHoursMonthly = targetHoursMonthly
        self._hasVariableSchedule = hasVariableSchedule
        self.language = language
        self.localization = SettingsLocalization(language: language)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Targets explanation
            targetsExplanationSection

            // All Targets in One Card
            allTargetsSection
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside text fields
            focusedField = nil
        }
    }

    // MARK: - Section Views

    private var targetsExplanationSection: some View {
        VStack(spacing: 8) {
            Text(localization.setYourGoalsTitle)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(localization.setYourGoalsDescription)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private var allTargetsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Title
            HStack(spacing: 12) {
                Image(systemName: "target") // Target/bullseye icon
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.yourTargetsTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            // MARK: - Tip Targets
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.tipTargetsSection)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                HStack {
                    Text(localization.tipPercentageShortLabel)
                        .foregroundStyle(.primary)
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
                        .foregroundStyle(.primary)
                        .focused($focusedField, equals: .tipTarget)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100)
                    .padding(8)
                    .liquidGlassForm()
                }

                // Tip percentage explanation
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: IconNames.Status.info)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Text(localization.tipPercentageNoteTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    Text(localization.tipPercentageNoteMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            // MARK: - Sales Targets
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.salesTargetsSection)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                targetRow(label: localization.dailySalesTargetLabel,
                          value: $targetSalesDaily,
                          placeholder: "500.00",
                          field: .salesDaily)

                // Only show weekly and monthly if NOT variable schedule
                if !hasVariableSchedule {
                    targetRow(label: localization.weeklySalesTargetLabel,
                              value: $targetSalesWeekly,
                              placeholder: "3500.00",
                              field: .salesWeekly)

                    targetRow(label: localization.monthlySalesTargetLabel,
                              value: $targetSalesMonthly,
                              placeholder: "14000.00",
                              field: .salesMonthly)
                }

                // Variable schedule note for sales
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: IconNames.Status.info)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Text(localization.variableScheduleNoteTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    Text(localization.variableScheduleNoteMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            // MARK: - Hours Targets
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.hoursTargetsSection)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                targetRow(label: localization.dailyHoursTargetLabel,
                          value: $targetHoursDaily,
                          placeholder: "8",
                          isHours: true,
                          field: .hoursDaily)

                // Only show weekly and monthly if NOT variable schedule
                if !hasVariableSchedule {
                    targetRow(label: localization.weeklyHoursTargetLabel,
                              value: $targetHoursWeekly,
                              placeholder: "40",
                              isHours: true,
                              field: .hoursWeekly)

                    targetRow(label: localization.monthlyHoursTargetLabel,
                              value: $targetHoursMonthly,
                              placeholder: "160",
                              isHours: true,
                              field: .hoursMonthly)
                }

                // Variable schedule note for hours
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: IconNames.Status.info)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Text(localization.variableScheduleNoteTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    Text(localization.variableScheduleHoursNoteMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    // MARK: - Helper Views

    @ViewBuilder
    func targetRow(label: String, value: Binding<String>, placeholder: String, isHours: Bool = false, field: Field) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            TextField(placeholder, text: value, onEditingChanged: { editing in
                if editing && (value.wrappedValue == "0" || value.wrappedValue == "0.00" || value.wrappedValue == "0.0" || value.wrappedValue == placeholder) {
                    value.wrappedValue = ""
                }
            })
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.tint)
            .focused($focusedField, equals: field)
            .frame(width: 100)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .liquidGlassForm()
            .onTapGesture {
                HapticFeedback.selection()
            }
        }
    }
}