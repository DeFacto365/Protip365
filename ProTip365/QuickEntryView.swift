import SwiftUI
import Supabase

struct QuickEntryView: View {
    @Binding var entryDate: Date
    @Binding var entrySales: String
    @Binding var entryTips: String
    @Binding var entryTipOut: String
    @Binding var entryHours: String
    @Binding var isSaving: Bool
    var editingShift: ShiftIncome?
    var userTargets: DashboardView.UserTargets
    var currentPeriod: Int
    var hourlyRate: Double
    var useEmployers: Bool = false
    var employerName: String? = nil
    var employerHourlyRate: Double? = nil
    var onSave: () -> Void
    var onCancel: () -> Void
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    
    enum Field {
        case sales, tips, tipOut, hours
    }
    
    var calculatedSalary: Double {
        let hours = Double(entryHours) ?? 0
        let rate = useEmployers ? (employerHourlyRate ?? hourlyRate) : hourlyRate
        
        // Prevent NaN values
        guard !hours.isNaN && !rate.isNaN else { return 0 }
        guard hours >= 0 && rate >= 0 else { return 0 }
        
        return hours * rate
    }
    
    var calculatedTotal: Double {
        let tips = Double(entryTips) ?? 0
        let tipOut = Double(entryTipOut) ?? 0
        let salary = calculatedSalary
        
        // Prevent NaN values
        guard !tips.isNaN && !tipOut.isNaN && !salary.isNaN else { return 0 }
        
        return salary + tips - tipOut
    }
    
    var isFutureDate: Bool {
        entryDate > Date()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(dateLabel, selection: $entryDate, displayedComponents: .date)
                        .disabled(editingShift != nil)
                        .onChange(of: entryDate) { _, _ in
                            focusedField = nil
                        }
                    
                    if useEmployers, let employerName = employerName {
                        HStack {
                            Text(employerLabel)
                            Spacer()
                            Text(employerName)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text(hoursLabel)
                        Spacer()
                        TextField("0.0", text: $entryHours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .hours)
                            .frame(width: 100)
                        if getHoursTarget() > 0 {
                            Text("/ \(String(format: "%.0f", getHoursTarget()))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !isFutureDate {
                    Section {
                        // Salary (calculated)
                        HStack {
                            Text(salaryLabel)
                            Spacer()
                            Text(formatCurrency(calculatedSalary))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(salesLabel)
                            Spacer()
                            TextField(formatCurrency(0), text: $entrySales)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .sales)
                                .frame(width: 100)
                            if getSalesTarget() > 0 {
                                Text("/ \(formatCurrency(getSalesTarget()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text(tipsLabel)
                            Spacer()
                            TextField(formatCurrency(0), text: $entryTips)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .tips)
                                .frame(width: 100)
                            if getTipsTarget() > 0 {
                                Text("/ \(formatCurrency(getTipsTarget()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text(tipOutLabel)
                            Spacer()
                            TextField(formatCurrency(0), text: $entryTipOut)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .tipOut)
                                .frame(width: 100)
                        }
                        
                        // Total (calculated)
                        HStack {
                            Text(totalLabel)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatCurrency(calculatedTotal))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    } header: {
                        Text(earningsSection)
                    }
                }
                
                Section {
                    Button(action: onSave) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text(editingShift != nil ? updateButton : saveButton)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving || entryHours.isEmpty)
                }
            }
            .navigationTitle(editingShift != nil ? editShiftTitle : newEntryTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelButton) {
                        onCancel()
                    }
                }
            }
        }
    }
    
    func getSalesTarget() -> Double {
        switch currentPeriod {
        case 1: 
            let target = userTargets.weeklySales / 7
            return target.isNaN ? 0 : target
        case 2: 
            let target = userTargets.monthlySales / 30
            return target.isNaN ? 0 : target
        default: 
            let target = userTargets.dailySales
            return target.isNaN ? 0 : target
        }
    }
    
    func getTipsTarget() -> Double {
        switch currentPeriod {
        case 1: 
            let target = userTargets.weeklyTips / 7
            return target.isNaN ? 0 : target
        case 2: 
            let target = userTargets.monthlyTips / 30
            return target.isNaN ? 0 : target
        default: 
            let target = userTargets.dailyTips
            return target.isNaN ? 0 : target
        }
    }
    
    func getHoursTarget() -> Double {
        switch currentPeriod {
        case 1: 
            let target = userTargets.weeklyHours / 7
            return target.isNaN ? 0 : target
        case 2: 
            let target = userTargets.monthlyHours / 30
            return target.isNaN ? 0 : target
        default: 
            let target = userTargets.dailyHours
            return target.isNaN ? 0 : target
        }
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    // Localization
    var newEntryTitle: String {
        switch language {
        case "fr": return "Nouvelle entrée"
        case "es": return "Nueva entrada"
        default: return "New Entry"
        }
    }
    
    var editShiftTitle: String {
        switch language {
        case "fr": return "Modifier le quart"
        case "es": return "Editar turno"
        default: return "Edit Shift"
        }
    }
    
    var dateLabel: String {
        switch language {
        case "fr": return "Date"
        case "es": return "Fecha"
        default: return "Date"
        }
    }
    
    var employerLabel: String {
        switch language {
        case "fr": return "Employeur"
        case "es": return "Empleador"
        default: return "Employer"
        }
    }
    
    var earningsSection: String {
        switch language {
        case "fr": return "Revenus"
        case "es": return "Ganancias"
        default: return "Earnings"
        }
    }
    
    var salaryLabel: String {
        switch language {
        case "fr": return "Salaire"
        case "es": return "Salario"
        default: return "Salary"
        }
    }
    
    var salesLabel: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }
    
    var tipsLabel: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }
    
    var tipOutLabel: String {
        switch language {
        case "fr": return "Partage pourboire"
        case "es": return "Propina compartida"
        default: return "Tip Out"
        }
    }
    
    var totalLabel: String {
        switch language {
        case "fr": return "Total"
        case "es": return "Total"
        default: return "Total"
        }
    }
    
    var hoursLabel: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }
    
    var saveButton: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save"
        }
    }
    
    var updateButton: String {
        switch language {
        case "fr": return "Mettre à jour"
        case "es": return "Actualizar"
        default: return "Update"
        }
    }
    
    var cancelButton: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
}
