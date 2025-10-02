import SwiftUI

struct DetailedEntriesView: View {
    let date: Date
    let entries: [ShiftWithEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var showAddEntryView = false
    @State private var selectedShiftForEditing: ShiftWithEntry? = nil
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
        entries.reduce(0.0) { total, entry in
            let actualHours = entry.entry?.actual_hours ?? 0
            return total + (actualHours * entry.expected_shift.hourly_rate)
        }
    }

    private var totalSales: Double {
        entries.reduce(0.0) { $0 + ($1.entry?.sales ?? 0) }
    }

    private var totalTips: Double {
        entries.reduce(0.0) { $0 + ($1.entry?.tips ?? 0) }
    }

    private var totalIncome: Double {
        entries.reduce(0.0) { total, entry in
            let salary = (entry.entry?.actual_hours ?? 0) * entry.expected_shift.hourly_rate
            let tips = entry.entry?.tips ?? 0
            return total + salary + tips
        }
    }

    private var totalHours: Double {
        entries.reduce(0.0) { $0 + ($1.entry?.actual_hours ?? 0) }
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
    
    private func entryCard(_ entry: ShiftWithEntry) -> some View {
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
                    Text("\(String(format: "%.1f", entry.actual_hours ?? 0)) \(hoursText) • \(formatEntryTimes(entry: entry))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Financial breakdown
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        let basePay = (entry.actual_hours ?? 0) * entry.hourly_rate
                        Text("\(salaryText): $\(String(format: "%.2f", basePay))")
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

    // Helper function to format entry times - use actual times if available, otherwise expected times
    private func formatEntryTimes(entry: ShiftWithEntry) -> String {
        // Prioritize actual times from entry, otherwise use expected times from shift
        if let actualStart = entry.entry?.actual_start_time,
           let actualEnd = entry.entry?.actual_end_time {
            return "\(formatTimeWithoutSeconds(actualStart)) - \(formatTimeWithoutSeconds(actualEnd))"
        } else {
            // Use expected times from shift
            return "\(formatTimeWithoutSeconds(entry.expected_shift.start_time)) - \(formatTimeWithoutSeconds(entry.expected_shift.end_time))"
        }
    }

    // Helper function to format time without seconds
    private func formatTimeWithoutSeconds(_ timeString: String) -> String {
        // Input format is "HH:mm:ss", we want "HH:mm AM/PM"
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss"

        guard let date = inputFormatter.date(from: timeString) else {
            // If parsing fails, return the original without seconds
            let components = timeString.components(separatedBy: ":")
            if components.count >= 2 {
                return "\(components[0]):\(components[1])"
            }
            return timeString
        }

        let outputFormatter = DateFormatter()
        outputFormatter.timeStyle = .short
        outputFormatter.dateStyle = .none

        // Set locale based on language for proper time formatting
        switch language {
        case "fr":
            outputFormatter.locale = Locale(identifier: "fr_FR")
        case "es":
            outputFormatter.locale = Locale(identifier: "es_ES")
        default:
            outputFormatter.locale = Locale(identifier: "en_US")
        }

        return outputFormatter.string(from: date)
    }
}

#Preview {
    let sampleShift = ExpectedShift(
        id: UUID(),
        user_id: UUID(),
        employer_id: UUID(),
        shift_date: "2025-09-11",
        start_time: "08:00:00",
        end_time: "17:00:00",
        expected_hours: 8.0,
        hourly_rate: 15.0,
        lunch_break_minutes: 30,
        sales_target: nil,
        status: "completed",
        alert_minutes: nil,
        notes: nil,
        created_at: Date(),
        updated_at: Date()
    )

    let sampleEntry = ShiftEntry(
        id: UUID(),
        shift_id: sampleShift.id,
        user_id: UUID(),
        actual_start_time: "08:05:00",
        actual_end_time: "17:10:00",
        actual_hours: 8.2,
        sales: 250.0,
        tips: 125.0,
        cash_out: 0.0,
        other: 0.0,
        hourly_rate: 15.0,
        gross_income: 123.0,
        total_income: 248.0,
        net_income: 173.6,
        deduction_percentage: 30.0,
        notes: nil,
        created_at: Date(),
        updated_at: Date()
    )

    let sampleShiftWithEntry = ShiftWithEntry(
        expected_shift: sampleShift,
        entry: sampleEntry,
        employer_name: "Big John Bar"
    )

    DetailedEntriesView(
        date: Date(),
        entries: [sampleShiftWithEntry]
    )
}
