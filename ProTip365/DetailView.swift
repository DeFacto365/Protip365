import SwiftUI

struct DetailView: View {
    let shifts: [ShiftIncome]
    let detailType: String
    let periodText: String
    var onEditShift: (ShiftIncome) -> Void
    @Environment(\.dismiss) var dismiss
    @AppStorage("language") private var language = "en"
    
    var totalSales: Double {
        shifts.reduce(0) { $0 + $1.sales }
    }
    
    var totalTips: Double {
        shifts.reduce(0) { $0 + $1.tips }
    }
    
    var totalSalary: Double {
        shifts.reduce(0) { $0 + ($1.hours * ($1.hourly_rate ?? 15.0)) }
    }
    
    var totalIncome: Double {
        shifts.reduce(0) { $0 + ($1.total_income ?? 0) }
    }
    
    var totalHours: Double {
        shifts.reduce(0) { $0 + $1.hours }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if shifts.isEmpty {
                    Text(noDataText)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(shifts, id: \.id) { shift in
                        Button(action: {
                            onEditShift(shift)
                            HapticFeedback.light()
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(formatDate(shift.shift_date))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Label("\(shift.hours, specifier: "%.1f") \(hoursText)", systemImage: "clock")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading) {
                                        Text(salaryText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(shift.hours * (shift.hourly_rate ?? 15.0)))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(salesText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(shift.sales))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(tipsText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(shift.tips))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(totalText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatCurrency(shift.total_income ?? 0))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                if let employer = shift.employer_name {
                                    Text(employer)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Section {
                        VStack(spacing: 12) {
                            HStack {
                                Text(totalSalaryLabel)
                                    .font(.headline)
                                Spacer()
                                Text(formatCurrency(totalSalary))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text(totalSalesLabel)
                                    .font(.subheadline)
                                Spacer()
                                Text(formatCurrency(totalSales))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text(totalTipsLabel)
                                    .font(.subheadline)
                                Spacer()
                                Text(formatCurrency(totalTips))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text(totalIncomeLabel)
                                    .font(.headline)
                                Spacer()
                                Text(formatCurrency(totalIncome))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text(totalHoursLabel)
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f", totalHours))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text(totalsHeader)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("\(periodText) - \(detailTitle)")
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
        case "income": return totalSalaryText
        case "tips": return tipsText
        case "tipout": return tipOutText
        case "sales": return salesText
        case "hours": return hoursText
        case "revenue": return totalRevenueText
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
    
    var tipOutText: String {
        switch language {
        case "fr": return "Partage pourboire"
        case "es": return "Propina compartida"
        default: return "Tip Out"
        }
    }
    
    var totalText: String {
        switch language {
        case "fr": return "Total"
        case "es": return "Total"
        default: return "Total"
        }
    }
    
    var hoursText: String {
        switch language {
        case "fr": return "heures"
        case "es": return "horas"
        default: return "hours"
        }
    }
    
    var totalSalaryText: String {
        switch language {
        case "fr": return "Salaire total"
        case "es": return "Salario total"
        default: return "Total Salary"
        }
    }
    
    var totalRevenueText: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingresos totales"
        default: return "Total Revenue"
        }
    }
    
    var salaryText: String {
        switch language {
        case "fr": return "Salaire"
        case "es": return "Salario"
        default: return "Salary"
        }
    }
    
    var totalSalaryLabel: String {
        switch language {
        case "fr": return "Salaire total"
        case "es": return "Salario total"
        default: return "Total Salary"
        }
    }
    
    var detailsText: String {
        switch language {
        case "fr": return "Détails"
        case "es": return "Detalles"
        default: return "Details"
        }
    }
    
    var totalsHeader: String {
        switch language {
        case "fr": return "TOTAUX"
        case "es": return "TOTALES"
        default: return "TOTALS"
        }
    }
    
    var totalSalesLabel: String {
        switch language {
        case "fr": return "Total des ventes"
        case "es": return "Ventas totales"
        default: return "Total Sales"
        }
    }
    
    var totalTipsLabel: String {
        switch language {
        case "fr": return "Total des pourboires"
        case "es": return "Propinas totales"
        default: return "Total Tips"
        }
    }
    
    var totalIncomeLabel: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingreso total"
        default: return "Total Income"
        }
    }
    
    var totalHoursLabel: String {
        switch language {
        case "fr": return "Total des heures"
        case "es": return "Horas totales"
        default: return "Total Hours"
        }
    }
}
