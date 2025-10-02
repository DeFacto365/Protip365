import SwiftUI

struct DetailStatsSection: View {
    let shifts: [ShiftIncome]
    let localization: DetailLocalization
    let averageDeductionPercentage: Double
    let targetIncome: Double
    let targetTips: Double
    let targetSales: Double
    let targetHours: Double
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: 16) {
            // Income breakdown card
            DetailIncomeCard(
                shifts: shifts,
                localization: localization,
                averageDeductionPercentage: averageDeductionPercentage,
                targetIncome: targetIncome,
                targetTips: targetTips
            )

            // Performance metrics card
            DetailPerformanceCard(
                shifts: shifts,
                localization: localization,
                targetSales: targetSales,
                targetHours: targetHours
            )

            // Additional stats for iPad
            if horizontalSizeClass == .regular {
                DetailAveragesCard(
                    shifts: shifts,
                    localization: localization,
                    averageDeductionPercentage: averageDeductionPercentage
                )
            }
        }
    }
}