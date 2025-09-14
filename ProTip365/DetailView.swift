import SwiftUI

struct DetailView: View {
    let shifts: [ShiftIncome]
    let detailType: String
    let periodText: String
    var onEditShift: (ShiftIncome) -> Void
    @Environment(\.dismiss) var dismiss
    @AppStorage("language") private var language = "en"
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

    // Calculations
    var totalSalary: Double {
        shifts.reduce(0) { total, shift in
            if let baseIncome = shift.base_income {
                return total + baseIncome
            }
            return total + (shift.hours * (shift.hourly_rate ?? 15.0))
        }
    }

    var totalTips: Double {
        shifts.reduce(0) { $0 + $1.tips }
    }

    var totalOther: Double {
        shifts.reduce(0) { $0 + ($1.other ?? 0) }
    }

    var totalTipOut: Double {
        shifts.reduce(0) { $0 + ($1.cash_out ?? 0) }
    }

    // Income = Salary + Tips + Other - Tip Out
    var totalIncome: Double {
        totalSalary + totalTips + totalOther - totalTipOut
    }

    var totalHours: Double {
        shifts.reduce(0) { $0 + $1.hours }
    }

    var totalSales: Double {
        shifts.reduce(0) { $0 + $1.sales }
    }

    var tipPercentage: Double {
        guard totalSales > 0, !totalSales.isNaN, !totalTips.isNaN else { return 0 }
        return (totalTips / totalSales) * 100
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
                            EmptyStateView()
                        } else {
                            // Summary Card - iOS 26 Liquid Glass Style
                            summaryCard

                            // Individual Shifts
                            shiftsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("\(periodText) \(detailTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(doneText) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var summaryCard: some View {
        VStack(spacing: 16) {
            // Income Components Section
            VStack(spacing: 12) {
                Text(incomeBreakdownText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Salary
                HStack {
                    Label(salaryText, systemImage: "dollarsign.circle.fill")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(totalSalary))
                            .font(.body)
                            .fontWeight(.semibold)
                        if targetIncome > 0 && totalSalary > 0 {
                            Text("\(targetText): \(formatCurrency(targetIncome * 0.6))") // Assuming 60% is salary
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Tips
                HStack {
                    Label(tipsText, systemImage: "banknote.fill")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(totalTips))
                            .font(.body)
                            .fontWeight(.semibold)
                        if targetTips > 0 {
                            Text("\(targetText): \(formatCurrency(targetTips))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Other
                if totalOther > 0 {
                    HStack {
                        Label(otherText, systemImage: "plus.circle.fill")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(formatCurrency(totalOther))
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }

                // Tip Out (negative)
                if totalTipOut > 0 {
                    HStack {
                        Label(tipOutText, systemImage: "minus.circle.fill")
                            .font(.body)
                            .foregroundColor(.red)
                        Spacer()
                        Text("-\(formatCurrency(totalTipOut))")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }

                Divider()

                // Total Income
                HStack {
                    Label(totalIncomeText, systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(totalIncome))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        if targetIncome > 0 {
                            Text("\(targetText): \(formatCurrency(targetIncome))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Hours and Sales Section
            VStack(spacing: 12) {
                Text(performanceMetricsText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Total Hours
                HStack {
                    Label(totalHoursText, systemImage: "clock.fill")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f hours", totalHours))
                            .font(.body)
                            .fontWeight(.semibold)
                        if targetHours > 0 {
                            Text("\(targetText): \(String(format: "%.0f hours", targetHours))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Total Sales
                HStack {
                    Label(totalSalesText, systemImage: "cart.fill")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(totalSales))
                            .font(.body)
                            .fontWeight(.semibold)
                        if targetSales > 0 {
                            Text("\(targetText): \(formatCurrency(targetSales))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Tip Percentage
                if totalSales > 0 && totalTips > 0 {
                    HStack {
                        Label(tipPercentText, systemImage: "percent")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(String(format: "%.1f%%", tipPercentage))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private var shiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(shiftDetailsText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(shifts.sorted { $0.shift_date > $1.shift_date }, id: \.id) { shift in
                Button(action: {
                    onEditShift(shift)
                    HapticFeedback.light()
                }) {
                    VStack(spacing: 12) {
                        // Date and Employer
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(shift.shift_date))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if let employer = shift.employer_name {
                                    Text(employer)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Shift Stats Grid
                        HStack(spacing: 20) {
                            // Hours
                            VStack(alignment: .leading, spacing: 2) {
                                Text(hoursText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f", shift.hours))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            // Salary
                            VStack(alignment: .leading, spacing: 2) {
                                Text(salaryText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                let salary = shift.base_income ?? (shift.hours * (shift.hourly_rate ?? 15.0))
                                Text(formatCurrency(salary))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            // Tips
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tipsText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatCurrency(shift.tips))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            // Total
                            VStack(alignment: .leading, spacing: 2) {
                                Text(totalText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatCurrency(shift.total_income ?? 0))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }

                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(noDataText)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(noShiftsRecordedText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.locale = Locale.current

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    var detailTitle: String {
        switch detailType {
        case "income": return incomeText
        case "tips": return tipsText
        case "sales": return salesText
        case "hours": return hoursText
        case "total": return summaryText
        case "other": return otherText
        default: return detailsText
        }
    }

    // Localization
    var noDataText: String {
        switch language {
        case "fr": return "Aucune donnée"
        case "es": return "Sin datos"
        default: return "No data"
        }
    }

    var doneText: String {
        switch language {
        case "fr": return "Terminé"
        case "es": return "Listo"
        default: return "Done"
        }
    }

    var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }

    var tipsText: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }

    var detailsText: String {
        switch language {
        case "fr": return "Détails"
        case "es": return "Detalles"
        default: return "Details"
        }
    }

    var incomeBreakdownText: String {
        switch language {
        case "fr": return "RÉPARTITION DES REVENUS"
        case "es": return "DESGLOSE DE INGRESOS"
        default: return "INCOME BREAKDOWN"
        }
    }

    var performanceMetricsText: String {
        switch language {
        case "fr": return "MÉTRIQUES DE PERFORMANCE"
        case "es": return "MÉTRICAS DE RENDIMIENTO"
        default: return "PERFORMANCE METRICS"
        }
    }

    var shiftDetailsText: String {
        switch language {
        case "fr": return "DÉTAILS DES QUARTS"
        case "es": return "DETALLES DE TURNOS"
        default: return "SHIFT DETAILS"
        }
    }

    var salaryText: String {
        switch language {
        case "fr": return "Salaire"
        case "es": return "Salario"
        default: return "Salary"
        }
    }

    var hoursText: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }

    var totalText: String {
        switch language {
        case "fr": return "Total"
        case "es": return "Total"
        default: return "Total"
        }
    }

    var otherText: String {
        switch language {
        case "fr": return "Autre"
        case "es": return "Otro"
        default: return "Other"
        }
    }

    var tipOutText: String {
        switch language {
        case "fr": return "Partage"
        case "es": return "Reparto"
        default: return "Tip Out"
        }
    }

    var totalIncomeText: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingresos totales"
        default: return "Total Income"
        }
    }

    var totalHoursText: String {
        switch language {
        case "fr": return "Heures totales"
        case "es": return "Horas totales"
        default: return "Total Hours"
        }
    }

    var totalSalesText: String {
        switch language {
        case "fr": return "Ventes totales"
        case "es": return "Ventas totales"
        default: return "Total Sales"
        }
    }

    var tipPercentText: String {
        switch language {
        case "fr": return "% Pourboire"
        case "es": return "% Propina"
        default: return "Tip %"
        }
    }

    var targetText: String {
        switch language {
        case "fr": return "Objectif"
        case "es": return "Objetivo"
        default: return "Target"
        }
    }

    var noShiftsRecordedText: String {
        switch language {
        case "fr": return "Aucun quart enregistré pour cette période"
        case "es": return "No hay turnos registrados para este período"
        default: return "No shifts recorded for this period"
        }
    }

    var incomeText: String {
        switch language {
        case "fr": return "Revenu"
        case "es": return "Ingresos"
        default: return "Income"
        }
    }

    var summaryText: String {
        switch language {
        case "fr": return "Résumé"
        case "es": return "Resumen"
        default: return "Summary"
        }
    }
}