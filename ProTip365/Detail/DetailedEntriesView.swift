import SwiftUI

struct DetailedEntriesView: View {
    let date: Date
    let entries: [ShiftIncome]
    @Environment(\.dismiss) private var dismiss
    @State private var showAddEntryView = false
    @State private var selectedShiftForEditing: ShiftIncome? = nil
    @AppStorage("language") private var language = "en"
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var totalSalary: Double {
        entries.reduce(0.0) { $0 + ($1.base_income ?? 0) }
    }
    
    private var totalSales: Double {
        entries.reduce(0.0) { $0 + ($1.sales ?? 0) }
    }
    
    private var totalTips: Double {
        entries.reduce(0.0) { $0 + ($1.tips ?? 0) }
    }
    
    private var totalIncome: Double {
        entries.reduce(0.0) { $0 + ($1.total_income ?? 0) }
    }
    
    private var totalHours: Double {
        entries.reduce(0.0) { $0 + ($1.hours ?? 0) }
    }

    // MARK: - Translation Properties
    private var doneText: String {
        switch language {
        case "fr": return "Terminé"
        case "es": return "Hecho"
        default: return "Done"
        }
    }

    private var weekText: String {
        switch language {
        case "fr": return "Semaine"
        case "es": return "Semana"
        default: return "Week"
        }
    }

    private var dayText: String {
        switch language {
        case "fr": return "Jour"
        case "es": return "Día"
        default: return "Day"
        }
    }

    private var tipsText: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }

    private var hoursText: String {
        switch language {
        case "fr": return "heures"
        case "es": return "horas"
        default: return "hours"
        }
    }

    private var salaryText: String {
        switch language {
        case "fr": return "Salaire"
        case "es": return "Salario"
        default: return "Salary"
        }
    }

    private var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }

    private var totalText: String {
        switch language {
        case "fr": return "Total"
        case "es": return "Total"
        default: return "Total"
        }
    }

    private var totalsText: String {
        switch language {
        case "fr": return "TOTAUX"
        case "es": return "TOTALES"
        default: return "TOTALS"
        }
    }

    private var totalSalaryText: String {
        switch language {
        case "fr": return "Salaire total"
        case "es": return "Salario total"
        default: return "Total Salary"
        }
    }

    private var totalSalesText: String {
        switch language {
        case "fr": return "Ventes totales"
        case "es": return "Ventas totales"
        default: return "Total Sales"
        }
    }

    private var totalTipsText: String {
        switch language {
        case "fr": return "Pourboires totaux"
        case "es": return "Propinas totales"
        default: return "Total Tips"
        }
    }

    private var totalIncomeText: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingresos totales"
        default: return "Total Income"
        }
    }

    private var totalHoursText: String {
        switch language {
        case "fr": return "Heures totales"
        case "es": return "Horas totales"
        default: return "Total Hours"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Header
                    Text(dateFormatter.string(from: date))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.top)
                    
                    // Individual Entries
                    ForEach(entries, id: \.id) { entry in
                        entryCard(entry)
                    }
                    
                    // Totals Section
                    if entries.count > 1 {
                        totalsCard
                    }
                }
                .padding()
            }
            .navigationTitle("\(entries.count > 1 ? weekText : dayText) - \(tipsText)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(doneText) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showAddEntryView) {
                AddEntryView(editingShift: selectedShiftForEditing)
                    .environmentObject(SupabaseManager())
            }
        }
    }
    
    private func entryCard(_ entry: ShiftIncome) -> some View {
        Button(action: {
            selectedShiftForEditing = entry
            showAddEntryView = true
            HapticFeedback.light()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Time info
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", entry.hours ?? 0)) \(hoursText) • \(timeFormatter.string(from: date))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Financial breakdown
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(salaryText): $\(String(format: "%.2f", entry.base_income ?? 0))")
                        Text("\(salesText): $\(String(format: "%.2f", entry.sales ?? 0))")
                        Text("\(tipsText): $\(String(format: "%.2f", entry.tips ?? 0))")
                        Text("\(totalText): $\(String(format: "%.2f", entry.total_income ?? 0))")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding()
            .liquidGlassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text(totalsText)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(totalSalaryText): $\(String(format: "%.2f", totalSalary))")
                Text("\(totalSalesText): $\(String(format: "%.2f", totalSales))")
                Text("\(totalTipsText): $\(String(format: "%.2f", totalTips))")
                Text("\(totalIncomeText): $\(String(format: "%.2f", totalIncome))")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Text("\(totalHoursText): \(String(format: "%.1f", totalHours))")
            }
        }
        .padding()
        .liquidGlassCard()
    }
}

#Preview {
    DetailedEntriesView(
        date: Date(),
        entries: [
            ShiftIncome(
                income_id: UUID(),
                shift_id: UUID(),
                user_id: UUID(),
                employer_id: UUID(),
                employer_name: "Big John Bar",
                shift_date: "2025-09-11",
                expected_hours: 8.0,
                lunch_break_minutes: 30,
                net_expected_hours: 7.5,
                hours: 8.0,
                hourly_rate: 15.0,
                sales: 250.0,
                tips: 125.0,
                cash_out: 0.0,
                other: 0.0,
                base_income: 90.0,
                net_tips: 125.0,
                total_income: 215.0,
                tip_percentage: 50.0,
                start_time: "08:00",
                end_time: "17:00",
                shift_status: "completed",
                has_earnings: true,
                shift_created_at: "2025-09-11T08:00:00Z",
                earnings_created_at: "2025-09-11T17:00:00Z",
                notes: nil
            )
        ]
    )
}
