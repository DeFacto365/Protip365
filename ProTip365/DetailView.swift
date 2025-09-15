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

    // Income = Net Salary + Tips + Other - Tip Out
    var totalIncome: Double {
        let netSalary = totalSalary * (1 - averageDeductionPercentage / 100)
        return netSalary + totalTips + totalOther - totalTipOut
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
                            if horizontalSizeClass == .regular && detailType == "total" {
                                // iPad Total Summary: Full-screen enhanced layout
                                VStack(spacing: 32) {
                                    // Top row: Cards spread across full width
                                    HStack(alignment: .top, spacing: 24) {
                                        summaryCard
                                            .frame(maxWidth: .infinity)

                                        // Additional statistics for iPad
                                        additionalStatsCard
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding(.horizontal, 20)

                                    // Shifts section below with grid layout for iPad
                                    shiftsSection
                                }
                            } else if horizontalSizeClass == .regular {
                                // iPad other views: Side-by-side layout
                                HStack(alignment: .top, spacing: 20) {
                                    // Summary on the left
                                    summaryCard
                                        .frame(maxWidth: 400)

                                    // Shifts on the right
                                    VStack(alignment: .leading) {
                                        shiftsSection
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            } else {
                                // iPhone: Vertical layout
                                summaryCard
                                shiftsSection
                            }
                        }
                    }
                    .padding(horizontalSizeClass == .regular ? 32 : 20)
                    .frame(maxWidth: horizontalSizeClass == .regular ? .infinity : .infinity)
                }
            }
            .navigationTitle("\(periodText) \(detailTitle)")
            .navigationBarTitleDisplayMode(horizontalSizeClass == .regular ? .large : .inline)
            .toolbar {
                ToolbarItem(placement: horizontalSizeClass == .regular ? .navigationBarLeading : .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        if horizontalSizeClass == .regular {
                            Label(doneText, systemImage: "xmark.circle.fill")
                                .font(.title2)
                        } else {
                            Text(doneText)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var additionalStatsCard: some View {
        VStack(spacing: 16) {
            // Averages Section
            VStack(spacing: 12) {
                Text("AVERAGES & TRENDS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Average per shift
                HStack {
                    Label("Avg per Shift", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatCurrency(shifts.isEmpty ? 0 : totalIncome / Double(shifts.count)))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }

                // Average hourly rate
                HStack {
                    Label("Avg Hourly", systemImage: "clock.badge")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatCurrency(totalHours > 0 ? totalIncome / totalHours : 0) + "/hr")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }

                // Average tip percentage
                HStack {
                    Label("Avg Tip %", systemImage: "percent")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(String(format: "%.1f%%", tipPercentage))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }

                Divider()

                // Best day
                if let bestShift = shifts.max(by: { ($0.total_income ?? 0) < ($1.total_income ?? 0) }) {
                    HStack {
                        Label("Best Day", systemImage: "star.fill")
                            .font(.body)
                            .foregroundStyle(.orange)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatCurrency(bestShift.total_income ?? 0))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                            Text(formatDate(bestShift.shift_date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Shift count
                HStack {
                    Label("Total Shifts", systemImage: "calendar")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(shifts.count)")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

                // Gross Salary
                HStack {
                    Label(grossSalaryText, systemImage: "dollarsign.circle")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(totalSalary))
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("\(hoursText): \(String(format: "%.1f", totalHours))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Net Salary (after deductions)
                HStack {
                    Label(netSalaryText, systemImage: "dollarsign.bank.building")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        let netSalary = totalSalary * (1 - averageDeductionPercentage / 100)
                        Text(formatCurrency(netSalary))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                        Text("-\(Int(averageDeductionPercentage))% deductions")
                            .font(.caption2)
                            .foregroundColor(.secondary)
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
                        Label(otherText, systemImage: "square.and.pencil")
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
                        Label(tipOutText, systemImage: "minus.circle")
                            .font(.body)
                            .foregroundStyle(.red)
                        Spacer()
                        Text("-\(formatCurrency(totalTipOut))")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
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
                            .foregroundStyle(.green)
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
                    Label(totalHoursText, systemImage: "clock.badge")
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
            HStack {
                Text(shiftDetailsText)
                    .font(horizontalSizeClass == .regular ? .headline : .caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(shifts.count) \(shifts.count == 1 ? "shift" : "shifts")")
                    .font(horizontalSizeClass == .regular ? .headline : .caption)
                    .foregroundColor(.secondary)
            }

            // Single column layout for all devices - no grid needed
            ForEach(shifts.sorted { $0.shift_date > $1.shift_date }, id: \.id) { shift in
                shiftCard(for: shift)
            }
        }
    }

    @ViewBuilder
    private func shiftCard(for shift: ShiftIncome) -> some View {
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
                                        .foregroundStyle(.tint)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Shift Stats Grid - Responsive based on device
                        if horizontalSizeClass == .regular {
                            // iPad: More detailed grid with proper spacing
                            HStack(alignment: .top, spacing: 0) {
                                // Hours
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(hoursText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f", shift.hours))
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .frame(minWidth: 60)

                                Spacer()

                                // Sales
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(salesText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatCurrency(shift.sales))
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .frame(minWidth: 100)

                                Spacer()

                                // Gross & Net Salary
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(grossSalaryText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    let salary = shift.base_income ?? (shift.hours * (shift.hourly_rate ?? 15.0))
                                    Text(formatCurrency(salary))
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .frame(minWidth: 100)

                                Spacer()

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(netSalaryText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    let salary = shift.base_income ?? (shift.hours * (shift.hourly_rate ?? 15.0))
                                    let netSalary = salary * (1 - averageDeductionPercentage / 100)
                                    Text(formatCurrency(netSalary))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.green)
                                }
                                .frame(minWidth: 100)

                                Spacer()

                                // Tips with percentage
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tipsText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(formatCurrency(shift.tips))
                                            .font(.body)
                                            .fontWeight(.medium)
                                        if shift.sales > 0 {
                                            Text("(\(String(format: "%.1f", (shift.tips / shift.sales) * 100))%)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                .frame(minWidth: 100)

                                Spacer()

                                // Other
                                if let other = shift.other, other > 0 {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(otherText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(other))
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }
                                    .frame(minWidth: 80)

                                    Spacer()
                                }

                                // Total
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(totalText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatCurrency(shift.total_income ?? 0))
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }
                                .frame(minWidth: 100)
                            }
                        } else {
                            // iPhone: Compact grid
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

                                // Net Salary (show net on iPhone for space)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(netSalaryText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    let salary = shift.base_income ?? (shift.hours * (shift.hourly_rate ?? 15.0))
                                    let netSalary = salary * (1 - averageDeductionPercentage / 100)
                                    Text(formatCurrency(netSalary))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.green)
                                }

                                // Tips with percentage
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tipsText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(formatCurrency(shift.tips))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        if shift.sales > 0 {
                                            Text("(\(String(format: "%.1f", (shift.tips / shift.sales) * 100))%)")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }

                                // Total
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(totalText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatCurrency(shift.total_income ?? 0))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }

                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
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

    var grossSalaryText: String {
        switch language {
        case "fr": return "Salaire brut"
        case "es": return "Salario bruto"
        default: return "Gross Salary"
        }
    }

    var netSalaryText: String {
        switch language {
        case "fr": return "Salaire net"
        case "es": return "Salario neto"
        default: return "Net Salary"
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