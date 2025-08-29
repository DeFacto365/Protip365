import SwiftUI
import Supabase

struct ShiftEntryView: View {
    @State private var selectedDate = Date()
    @State private var hours = ""
    @State private var hourlyRate = ""
    @State private var sales = ""
    @State private var tips = ""
    @State private var cashOut = ""
    @State private var notes = ""
    @State private var selectedEmployerIndex = 0
    @State private var employers: [Employer] = []
    @State private var showSuccess = false
    @State private var useEmployer = false
    @AppStorage("language") private var language = "en"
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(dateLabel, selection: $selectedDate, displayedComponents: .date)
                    TextField(hoursLabel, text: $hours)
                        .keyboardType(.decimalPad)
                } header: {
                    Text(dateTimeSection)
                }
                
                Section {
                    Toggle(useEmployerLabel, isOn: $useEmployer)
                    if useEmployer && !employers.isEmpty {
                        Picker(selectEmployerLabel, selection: $selectedEmployerIndex) {
                            Text(noneLabel).tag(0)
                            ForEach(Array(employers.enumerated()), id: \.offset) { index, employer in
                                Text(employer.name).tag(index + 1)
                            }
                        }
                    }
                    if !useEmployer {
                        TextField(hourlyRateLabel, text: $hourlyRate)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text(employerSection)
                }
                
                Section {
                    TextField(salesLabel, text: $sales)
                        .keyboardType(.decimalPad)
                    TextField(tipsLabel, text: $tips)
                        .keyboardType(.decimalPad)
                    TextField(cashOutLabel, text: $cashOut)
                        .keyboardType(.decimalPad)
                } header: {
                    Text(earningsSection)
                }
                
                Section {
                    TextField(notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(notesSection)
                }
                
                Button(action: saveShift) {
                    HStack {
                        Spacer()
                        Text(saveShiftButton)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .listRowBackground(Color.blue)
                .foregroundColor(.white)
            }
            .navigationTitle(addShiftTitle)
            .alert(successTitle, isPresented: $showSuccess) {
                Button("OK") {
                    clearForm()
                }
            } message: {
                Text(successMessage)
            }
        }
        .task {
            await loadEmployers()
            await loadDefaults()
        }
    }
    
    func loadEmployers() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            employers = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
        } catch {
            print("Error loading employers: \(error)")
        }
    }
    
    func loadDefaults() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            let profile: [UserProfile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let userProfile = profile.first {
                hourlyRate = String(format: "%.2f", userProfile.default_hourly_rate)
            }
        } catch {
            print("Error loading defaults: \(error)")
        }
    }
    
    func saveShift() {
        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                struct NewShift: Encodable {
                    let user_id: String
                    let shift_date: String
                    let hours: Double
                    let sales: Double
                    let tips: Double
                    let cash_out: Double
                    let notes: String
                    let hourly_rate: Double
                    let employer_id: String?
                }
                
                var selectedEmployer: Employer? = nil
                if useEmployer && selectedEmployerIndex > 0 && selectedEmployerIndex <= employers.count {
                    selectedEmployer = employers[selectedEmployerIndex - 1]
                }
                
                let newShift = NewShift(
                    user_id: userId.uuidString,
                    shift_date: dateFormatter.string(from: selectedDate),
                    hours: Double(hours) ?? 0,
                    sales: Double(sales) ?? 0,
                    tips: Double(tips) ?? 0,
                    cash_out: Double(cashOut) ?? 0,
                    notes: notes,
                    hourly_rate: selectedEmployer?.hourly_rate ?? (Double(hourlyRate) ?? 15.00),
                    employer_id: selectedEmployer?.id.uuidString
                )
                
                try await SupabaseManager.shared.client
                    .from("shifts")
                    .insert(newShift)
                    .execute()
                
                showSuccess = true
            } catch {
                print("Error saving shift: \(error)")
            }
        }
    }
    
    func clearForm() {
        hours = ""
        sales = ""
        tips = ""
        cashOut = ""
        notes = ""
        selectedEmployerIndex = 0
    }
    
    // Localization
    var addShiftTitle: String {
        switch language {
        case "fr": return "Ajouter Quart"
        case "es": return "Agregar Turno"
        default: return "Add Shift"
        }
    }
    
    var dateTimeSection: String {
        switch language {
        case "fr": return "Date et Heures"
        case "es": return "Fecha y Horas"
        default: return "Date & Hours"
        }
    }
    
    var dateLabel: String {
        switch language {
        case "fr": return "Date"
        case "es": return "Fecha"
        default: return "Date"
        }
    }
    
    var hoursLabel: String {
        switch language {
        case "fr": return "Heures travaillées"
        case "es": return "Horas trabajadas"
        default: return "Hours worked"
        }
    }
    
    var employerSection: String {
        switch language {
        case "fr": return "Employeur (Optionnel)"
        case "es": return "Empleador (Opcional)"
        default: return "Employer (Optional)"
        }
    }
    
    var useEmployerLabel: String {
        switch language {
        case "fr": return "Utiliser un employeur"
        case "es": return "Usar empleador"
        default: return "Use employer"
        }
    }
    
    var selectEmployerLabel: String {
        switch language {
        case "fr": return "Sélectionner"
        case "es": return "Seleccionar"
        default: return "Select"
        }
    }
    
    var noneLabel: String {
        switch language {
        case "fr": return "Aucun"
        case "es": return "Ninguno"
        default: return "None"
        }
    }
    
    var hourlyRateLabel: String {
        switch language {
        case "fr": return "Taux horaire ($)"
        case "es": return "Tarifa por hora ($)"
        default: return "Hourly rate ($)"
        }
    }
    
    var earningsSection: String {
        switch language {
        case "fr": return "Revenus"
        case "es": return "Ganancias"
        default: return "Earnings"
        }
    }
    
    var salesLabel: String {
        switch language {
        case "fr": return "Ventes ($)"
        case "es": return "Ventas ($)"
        default: return "Sales ($)"
        }
    }
    
    var tipsLabel: String {
        switch language {
        case "fr": return "Pourboires ($)"
        case "es": return "Propinas ($)"
        default: return "Tips ($)"
        }
    }
    
    var cashOutLabel: String {
        switch language {
        case "fr": return "Partage pourboire ($)"
        case "es": return "Propina compartida ($)"
        default: return "Tip out ($)"
        }
    }
    
    var notesSection: String {
        switch language {
        case "fr": return "Notes"
        case "es": return "Notas"
        default: return "Notes"
        }
    }
    
    var notesPlaceholder: String {
        switch language {
        case "fr": return "Notes optionnelles..."
        case "es": return "Notas opcionales..."
        default: return "Optional notes..."
        }
    }
    
    var saveShiftButton: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save Shift"
        }
    }
    
    var successTitle: String {
        switch language {
        case "fr": return "Succès"
        case "es": return "Éxito"
        default: return "Success"
        }
    }
    
    var successMessage: String {
        switch language {
        case "fr": return "Quart sauvegardé!"
        case "es": return "Turno guardado!"
        default: return "Shift saved!"
        }
    }
}
