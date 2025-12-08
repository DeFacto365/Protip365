import SwiftUI

struct DetailView: View {
    let shifts: [ShiftIncome]
    let detailType: String
    let periodText: String
    var onEditShift: (ShiftIncome) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("language") private var language = "en"
    @AppStorage("averageDeductionPercentage") private var averageDeductionPercentage: Double = 30.0
    @AppStorage("targetTipDaily") private var targetTipDaily: Double = 0
    @AppStorage("targetTipWeekly") private var targetTipWeekly: Double = 0
    @AppStorage("targetTipMonthly") private var targetTipMonthly: Double = 0
    @AppStorage("targetSalesDaily") private var targetSalesDaily: Double = 0
    @AppStorage("targetSalesWeekly") private var targetSalesWeekly: Double = 0
    @AppStorage("targetSalesMonthly") private var targetSalesMonthly: Double = 0
    @AppStorage("targetHoursDaily") private var targetHoursDaily: Double = 0
    @AppStorage("targetHoursWeekly") private var targetHoursWeekly: Double = 0
    @AppStorage("targetHoursMonthly") private var targetHoursMonthly: Double = 0
    @AppStorage("targetIncomeDaily") private var targetIncomeDaily: Double = 0
    @AppStorage("targetIncomeWeekly") private var targetIncomeWeekly: Double = 0
    @AppStorage("targetIncomeMonthly") private var targetIncomeMonthly: Double = 0

    // Localization helper
    private var localization: DetailLocalization {
        DetailLocalization(language: language)
    }


    // Get targets based on period
    var targetIncome: Double {
        switch periodText.lowercased() {
        case "today": return targetIncomeDaily
        case "week": return targetIncomeWeekly
        case "month", "4 weeks": return targetIncomeMonthly
        case "year": return targetIncomeMonthly * 12
        default: return 0
        }
    }

    var targetTips: Double {
        switch periodText.lowercased() {
        case "today": return targetTipDaily
        case "week": return targetTipWeekly
        case "month", "4 weeks": return targetTipMonthly
        case "year": return targetTipMonthly * 12
        default: return 0
        }
    }

    var targetSales: Double {
        switch periodText.lowercased() {
        case "today": return targetSalesDaily
        case "week": return targetSalesWeekly
        case "month", "4 weeks": return targetSalesMonthly
        case "year": return targetSalesMonthly * 12
        default: return 0
        }
    }

    var targetHours: Double {
        switch periodText.lowercased() {
        case "today": return targetHoursDaily
        case "week": return targetHoursWeekly
        case "month", "4 weeks": return targetHoursMonthly
        case "year": return targetHoursMonthly * 12
        default: return 0
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if shifts.isEmpty {
                            DetailEmptyState(localization: localization)
                        } else {
                            if horizontalSizeClass == .regular && detailType == "total" {
                                // iPad Total Summary: Full-screen enhanced layout
                                VStack(spacing: 32) {
                                    // Top row: Cards spread across full width
                                    HStack(alignment: .top, spacing: 24) {
                                        DetailStatsSection(
                                            shifts: shifts,
                                            localization: localization,
                                            averageDeductionPercentage: averageDeductionPercentage,
                                            targetIncome: targetIncome,
                                            targetTips: targetTips,
                                            targetSales: targetSales,
                                            targetHours: targetHours
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
                                    .padding(.horizontal, 20)

                                    // Shifts section below
                                    DetailShiftsList(
                                        shifts: shifts,
                                        localization: localization,
                                        averageDeductionPercentage: averageDeductionPercentage,
                                        onEditShift: onEditShift
                                    )
                                }
                            } else if horizontalSizeClass == .regular {
                                // iPad other views: Side-by-side layout
                                HStack(alignment: .top, spacing: 20) {
                                    // Summary on the left
                                    DetailStatsSection(
                                        shifts: shifts,
                                        localization: localization,
                                        averageDeductionPercentage: averageDeductionPercentage,
                                        targetIncome: targetIncome,
                                        targetTips: targetTips,
                                        targetSales: targetSales,
                                        targetHours: targetHours
                                    )
                                    .frame(maxWidth: 400)

                                    // Shifts on the right
                                    VStack(alignment: .leading) {
                                        DetailShiftsList(
                                            shifts: shifts,
                                            localization: localization,
                                            averageDeductionPercentage: averageDeductionPercentage,
                                            onEditShift: onEditShift
                                        )
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            } else {
                                // iPhone: Vertical layout
                                DetailStatsSection(
                                    shifts: shifts,
                                    localization: localization,
                                    averageDeductionPercentage: averageDeductionPercentage,
                                    targetIncome: targetIncome,
                                    targetTips: targetTips,
                                    targetSales: targetSales,
                                    targetHours: targetHours
                                )
                                DetailShiftsList(
                                    shifts: shifts,
                                    localization: localization,
                                    averageDeductionPercentage: averageDeductionPercentage,
                                    onEditShift: onEditShift
                                )
                            }
                        }
                    }
                    .padding(horizontalSizeClass == .regular ? 32 : 20)
                    .frame(maxWidth: horizontalSizeClass == .regular ? .infinity : .infinity)
                }
            }
            .navigationTitle("\(periodText) \(localization.detailTitle(for: detailType))")
            .navigationBarTitleDisplayMode(horizontalSizeClass == .regular ? .large : .inline)
            .toolbar {
                ToolbarItem(placement: horizontalSizeClass == .regular ? .navigationBarLeading : .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        if horizontalSizeClass == .regular {
                            Label(localization.doneText, systemImage: "xmark.circle.fill")
                                .font(.title2)
                        } else {
                            Text(localization.doneText)
                        }
                    }
                }
            }
        }
    }
}