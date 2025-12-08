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

            // Tip Targets Section
            tipTargetsSectionView

            // Sales Targets Section
            salesTargetsSectionView

            // Hours Targets Section
            hoursTargetsSectionView
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

    private var tipTargetsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: IconNames.Financial.tips)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.tipTargetsSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            HStack {
                HStack(spacing: 12) {
                    Image(systemName: IconNames.Financial.percentage)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.monochrome)
                        .frame(width: 28, height: 28)
                    Text(localization.tipPercentageTargetLabel)
                        .foregroundStyle(.primary)
                }
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
                    .foregroundStyle(.tint)
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
                        .foregroundStyle(.tint)
                    Text(localization.tipPercentageNoteTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tint)
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private var salesTargetsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: IconNames.Financial.sales)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.salesTargetsSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            targetRow(label: localization.dailySalesTargetLabel,
                      icon: IconNames.Financial.income,
                      value: $targetSalesDaily,
                      placeholder: "500.00",
                      color: .primary)

            // Only show weekly and monthly if NOT variable schedule
            if !hasVariableSchedule {
                targetRow(label: localization.weeklySalesTargetLabel,
                          icon: IconNames.Financial.income,
                          value: $targetSalesWeekly,
                          placeholder: "3500.00",
                          color: .primary)

                targetRow(label: localization.monthlySalesTargetLabel,
                          icon: IconNames.Financial.income,
                          value: $targetSalesMonthly,
                          placeholder: "14000.00",
                          color: .primary)
            }

            // Variable schedule note
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: IconNames.Status.info)
                        .font(.caption)
                        .foregroundStyle(.tint)
                    Text(localization.variableScheduleNoteTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tint)
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private var hoursTargetsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: IconNames.Financial.hours)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 28, height: 28)
                Text(localization.hoursTargetsSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            targetRow(label: localization.dailyHoursTargetLabel,
                      icon: IconNames.Financial.hours,
                      value: $targetHoursDaily,
                      placeholder: "8",
                      color: .primary,
                      isHours: true)

            // Only show weekly and monthly if NOT variable schedule
            if !hasVariableSchedule {
                targetRow(label: localization.weeklyHoursTargetLabel,
                          icon: IconNames.Financial.hours,
                          value: $targetHoursWeekly,
                          placeholder: "40",
                          color: .primary,
                          isHours: true)

                targetRow(label: localization.monthlyHoursTargetLabel,
                          icon: IconNames.Financial.hours,
                          value: $targetHoursMonthly,
                          placeholder: "160",
                          color: .primary,
                          isHours: true)
            }

            // Variable schedule note
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: IconNames.Status.info)
                        .font(.caption)
                        .foregroundStyle(.tint)
                    Text(localization.variableScheduleNoteTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tint)
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // MARK: - Helper Views

    @ViewBuilder
    func targetRow(label: String, icon: String, value: Binding<String>, placeholder: String, color: Color, isHours: Bool = false) -> some View {
        HStack {
            Label(label, systemImage: icon)
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