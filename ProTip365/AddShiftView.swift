import SwiftUI
import Supabase

struct AddShiftView: View {
    let selectedDate: Date
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    // Shift selection state
    @State private var availableShifts: [Shift] = []
    @State private var selectedShift: Shift?
    @State private var showShiftPicker = false
    
    // Form fields for earnings data
    @State private var actualHours = ""
    @State private var sales = ""
    @State private var tips = ""
    @State private var cashOut = ""
    @State private var other = ""
    @State private var actualStartTime = ""
    @State private var actualEndTime = ""
    @State private var notes = ""
    
    // Quick shift creation fields (when no existing shift)
    @State private var expectedHours = ""
    @State private var lunchBreakMinutes = ""
    @State private var selectedEmployerIndex = 0
    @State private var employers: [Employer] = []
    @State private var useEmployer = false
    @State private var hourlyRate = ""
    
    @State private var isLoading = false
    @State private var showUnsavedChangesAlert = false
    @AppStorage("language") private var language = "en"
    
    var hasUnsavedChanges: Bool {
        return !actualHours.isEmpty || !sales.isEmpty || !tips.isEmpty || 
               !cashOut.isEmpty || !other.isEmpty || !notes.isEmpty
    }
    
    var isSelectedDateTodayOrFuture: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date()) || selectedDate > Date()
    }
    
    var needsShiftSelection: Bool {
        availableShifts.count > 1
    }
    
    // Break down complex UI into smaller computed properties
    var dateSectionView: some View {
        Section {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(dateSection)
                    .foregroundStyle(.primary)
                Spacer()
                Text(dateFormatter.string(from: selectedDate))
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .listRowBackground(Color.clear)
        }
    }
    
    // Break down the shift selection into smaller pieces
    func shiftDisplayView(for shift: Shift) -> some View {
        VStack(alignment: .leading) {
            Text(shift.start_time ?? "No time")
            if let employer = employers.first(where: { $0.id == shift.employer_id }) {
                Text(employer.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var shiftPicker: some View {
        Picker("Select Shift", selection: $selectedShift) {
            ForEach(availableShifts, id: \.id) { shift in
                shiftDisplayView(for: shift)
                    .tag(shift as Shift?)
            }
        }
    }
    
    var shiftSelectionSection: some View {
        Group {
            if needsShiftSelection {
                Section {
                    shiftPicker
                } header: {
                    Text("Which shift is this for?")
                }
                .listRowBackground(Color.clear)
            }
        }
    }
    
    var plannedShiftSection: some View {
        Group {
            if let shift = (selectedShift ?? availableShifts.first) {
                Section {
                    HStack {
                        Text("Expected Hours:")
                        Spacer()
                        Text("\(shift.expected_hours, specifier: "%.1f")h")
                            .foregroundColor(.secondary)
                    }
                    
                    if let employer = employers.first(where: { $0.id == shift.employer_id }) {
                        HStack {
                            Text("Employer:")
                            Spacer()
                            Text(employer.name)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let startTime = shift.start_time, let endTime = shift.end_time {
                        HStack {
                            Text("Planned Time:")
                            Spacer()
                            Text("\(startTime) - \(endTime)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Planned Shift")
                }
                .listRowBackground(Color.clear)
            }
        }
    }
    
    var quickShiftCreationSection: some View {
        Group {
            if availableShifts.isEmpty {
                Section {
                    TextField("Expected Hours", text: $expectedHours)
                        .keyboardType(.decimalPad)
                    
                    HStack {
                        Text("Lunch Break")
                        Spacer()
                        TextField("0", text: $lunchBreakMinutes)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                        Text("min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Toggle(useEmployerLabel, isOn: $useEmployer)
                        .toggleStyle(IOSStandardToggleStyle())
                    
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
                    Text("Create Shift")
                }
                .listRowBackground(Color.clear)
            }
        }
    }
    
    var earningsSectionView: some View {
        Group {
            if !isSelectedDateTodayOrFuture {
                Section {
                    TextField("Actual Hours Worked", text: $actualHours)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(WhiteBackgroundTextFieldStyle())
                    
                    TextField(salesLabel, text: $sales)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(WhiteBackgroundTextFieldStyle())
                    
                    TextField(tipsLabel, text: $tips)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(WhiteBackgroundTextFieldStyle())
                    
                    TextField(cashOutLabel, text: $cashOut)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(WhiteBackgroundTextFieldStyle())
                    
                    TextField("Other Income ($)", text: $other)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(WhiteBackgroundTextFieldStyle())
                } header: {
                    Text(earningsSection)
                }
                .listRowBackground(Color.clear)
            }
        }
    }
    
    var notesSectionView: some View {
        Section {
            TextField(notesPlaceholder, text: $notes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text(notesSection)
        }
        .listRowBackground(Color.clear)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                dateSectionView
                shiftSelectionSection
                plannedShiftSection  
                quickShiftCreationSection
                earningsSectionView
                notesSectionView
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(addShiftTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        if hasUnsavedChanges {
                            showUnsavedChangesAlert = true
                        } else {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        saveShift()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .disabled(isSelectedDateTodayOrFuture ? 
                             (availableShifts.isEmpty && expectedHours.isEmpty) : 
                             (actualHours.isEmpty || tips.isEmpty))
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
        }
        .task {
            await loadEmployers()
            await loadExistingShifts()
            await loadDefaults()
        }
        .alert(unsavedChangesTitle, isPresented: $showUnsavedChangesAlert) {
            Button(saveButton) {
                saveShift()
            }
            Button(discardChangesButton, role: .destructive) {
                isPresented = false
            }
            Button(cancelButton, role: .cancel) { }
        } message: {
            Text(unsavedChangesMessage)
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
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
    
    func loadExistingShifts() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let shifts: [Shift] = try await SupabaseManager.shared.client
                .from("shifts")
                .select()
                .eq("user_id", value: userId)
                .eq("shift_date", value: dateFormatter.string(from: selectedDate))
                .execute()
                .value
            
            await MainActor.run {
                availableShifts = shifts
                // Auto-select if only one shift exists
                if shifts.count == 1 {
                    selectedShift = shifts.first
                }
            }
        } catch {
            print("Error loading existing shifts: \(error)")
        }
    }
    
    func loadDefaults() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct Profile: Decodable {
                let default_hourly_rate: Double
                let default_employer_id: String?
                let use_multiple_employers: Bool?
            }
            
            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("default_hourly_rate, default_employer_id, use_multiple_employers")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let userProfile = profiles.first {
                await MainActor.run {
                    hourlyRate = String(format: "%.2f", userProfile.default_hourly_rate)
                    
                    // Set default employer if multiple employers is enabled AND there are employers available
                    if let useMultiple = userProfile.use_multiple_employers, useMultiple, !employers.isEmpty {
                        useEmployer = true
                        
                        // If a default employer is set, select it
                        if let defaultEmployerIdString = userProfile.default_employer_id,
                           let defaultEmployerId = UUID(uuidString: defaultEmployerIdString),
                           let employerIndex = employers.firstIndex(where: { $0.id == defaultEmployerId }) {
                            selectedEmployerIndex = employerIndex + 1  // +1 because index 0 is "None"
                        } else {
                            // No default set, but employers are available - select the first one
                            selectedEmployerIndex = 1  // First employer (index 0 is "None")
                        }
                    }
                }
            }
        } catch {
            print("Error loading defaults: \(error)")
        }
    }
    
    func saveShift() {
        isLoading = true
        
        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                var targetShift: Shift?
                
                // Step 1: Ensure we have a shift to link to
                if let existingShift = (selectedShift ?? availableShifts.first) {
                    targetShift = existingShift
                } else {
                    // Create new shift first
                    var selectedEmployer: Employer? = nil
                    if useEmployer && selectedEmployerIndex > 0 && selectedEmployerIndex <= employers.count {
                        selectedEmployer = employers[selectedEmployerIndex - 1]
                    }
                    
                    struct NewShift: Encodable {
                        let user_id: String
                        let shift_date: String
                        let expected_hours: Double
                        let lunch_break_minutes: Int
                        let hourly_rate: Double
                        let employer_id: String?
                        let start_time: String?
                        let end_time: String?
                        let status: String
                    }
                    
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm:ss"
                    
                    let newShiftData = NewShift(
                        user_id: userId.uuidString,
                        shift_date: dateFormatter.string(from: selectedDate),
                        expected_hours: Double(expectedHours) ?? 0,
                        lunch_break_minutes: Int(lunchBreakMinutes) ?? 0,
                        hourly_rate: selectedEmployer?.hourly_rate ?? (Double(hourlyRate) ?? 15.00),
                        employer_id: selectedEmployer?.id.uuidString,
                        start_time: nil,
                        end_time: nil,
                        status: isSelectedDateTodayOrFuture ? "planned" : "completed"
                    )
                    
                    let createdShifts: [Shift] = try await SupabaseManager.shared.client
                        .from("shifts")
                        .insert(newShiftData)
                        .select()
                        .execute()
                        .value
                    
                    targetShift = createdShifts.first
                }
                
                // Step 2: Create earnings data (only for past dates)
                if !isSelectedDateTodayOrFuture, let shift = targetShift {
                    struct ShiftIncomeEntry: Encodable {
                        let shift_id: String
                        let user_id: String
                        let actual_hours: Double
                        let sales: Double
                        let tips: Double
                        let cash_out: Double
                        let other: Double
                        let notes: String
                    }
                    
                    let incomeData = ShiftIncomeEntry(
                        shift_id: shift.id?.uuidString ?? "",
                        user_id: userId.uuidString,
                        actual_hours: Double(actualHours) ?? 0,
                        sales: Double(sales) ?? 0,
                        tips: Double(tips) ?? 0,
                        cash_out: Double(cashOut) ?? 0,
                        other: Double(other) ?? 0,
                        notes: notes
                    )
                    
                    try await SupabaseManager.shared.client
                        .from("shift_income")
                        .insert(incomeData)
                        .execute()
                }
                
                await MainActor.run {
                    onSave()
                    isPresented = false
                }
            } catch {
                print("Error saving shift: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    // Localization
    var addShiftTitle: String {
        switch language {
        case "fr": return "Ajouter un quart"
        case "es": return "Agregar turno"
        default: return "Add Shift"
        }
    }
    
    var dateSection: String {
        switch language {
        case "fr": return "Date"
        case "es": return "Fecha"
        default: return "Date"
        }
    }
    
    var workDetailsSection: String {
        switch language {
        case "fr": return "Détails du travail"
        case "es": return "Detalles del trabajo"
        default: return "Work Details"
        }
    }
    
    var hoursLabel: String {
        switch language {
        case "fr": return "Heures travaillées"
        case "es": return "Horas trabajadas"
        default: return "Hours worked"
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
    
    var cancelButton: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
    
    var saveButton: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save"
        }
    }
    
    var unsavedChangesTitle: String {
        switch language {
        case "fr": return "Modifications non sauvegardées"
        case "es": return "Cambios no guardados"
        default: return "Unsaved Changes"
        }
    }
    
    var unsavedChangesMessage: String {
        switch language {
        case "fr": return "Voulez-vous sauvegarder vos modifications ou les abandonner?"
        case "es": return "¿Quieres guardar tus cambios o descartarlos?"
        default: return "Do you want to save your changes or discard them?"
        }
    }
    
    var discardChangesButton: String {
        switch language {
        case "fr": return "Abandonner"
        case "es": return "Descartar"
        default: return "Discard"
        }
    }
}
