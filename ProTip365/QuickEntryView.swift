import SwiftUI
import Supabase

struct QuickEntryView: View {
    @Binding var entryDate: Date
    @Binding var entrySales: String
    @Binding var entryTips: String
    @Binding var entryTipOut: String
    @Binding var entryOther: String
    @Binding var entryHours: String
    @Binding var isSaving: Bool
    var editingShift: ShiftIncome?
    var userTargets: DashboardView.UserTargets
    var currentPeriod: Int
    var hourlyRate: Double
    var useEmployers: Bool = false
    var employerName: String? = nil
    var employerHourlyRate: Double? = nil
    var isShiftMode: Bool = false
    var onSave: (String?, String?) -> Void
    var onCancel: () -> Void
    var onDelete: (() -> Void)? = nil
    
    // Time picker states
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var lunchBreakMinutes = ""
    @State private var selectedEmployerId: UUID? = nil
    @State private var employers: [Employer] = []
    @State private var showDeleteAlert = false
    @State private var showUnsavedChangesAlert = false
    @State private var originalValues: (sales: String, tips: String, tipOut: String, other: String, hours: String, lunchBreak: String) = ("", "", "", "", "", "")
    @FocusState private var focusedTimePicker: TimePickerField?
    
    enum TimePickerField {
        case start, end
    }
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    
    enum Field {
        case sales, tips, tipOut, other, hours, lunchBreak
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
        let other = Double(entryOther) ?? 0
        let salary = calculatedSalary
        
        // Prevent NaN values
        guard !tips.isNaN && !tipOut.isNaN && !other.isNaN && !salary.isNaN else { return 0 }
        
        return salary + tips + other - tipOut
    }
    
    var hasUnsavedChanges: Bool {
        return entrySales != originalValues.sales ||
               entryTips != originalValues.tips ||
               entryTipOut != originalValues.tipOut ||
               entryOther != originalValues.other ||
               entryHours != originalValues.hours ||
               lunchBreakMinutes != originalValues.lunchBreak
    }
    
    var isFutureDate: Bool {
        entryDate > Date()
    }
    
    func calculateHours() {
        let totalHours = endTime.timeIntervalSince(startTime) / 3600
        let lunchBreakHours = (Double(lunchBreakMinutes) ?? 0) / 60.0
        let netHours = max(0, totalHours - lunchBreakHours)
        
        if totalHours > 0 {
            entryHours = String(format: "%.1f", netHours)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date and Employer Selection Combined
                    VStack(alignment: .leading, spacing: 12) {
                        // Date Selection
                        dateSelectionHeader
                        dateSelectionContent
                        
                        // Employer Selection (only if useEmployers is enabled)
                        if useEmployers {
                            if let employerName = employerName {
                                HStack {
                                    Text(employerLabel)
                                    Spacer()
                                    Text(employerName)
                                        .foregroundStyle(.blue)
                                        .fontWeight(.medium)
                                }
                            } else {
                                HStack {
                                    Text(employerLabel)
                                    Spacer()
                                    Picker("", selection: $selectedEmployerId) {
                                        Text("None").tag(nil as UUID?)
                                        ForEach(employers) { employer in
                                            Text(employer.name).tag(employer.id as UUID?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .liquidGlassForm(material: .ultraThin)
                                    .onChange(of: selectedEmployerId) { _, _ in
                                        HapticFeedback.selection()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .liquidGlassCard()
                    .padding(.horizontal)
                
                    // Time Selection with Liquid Glass
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Work Schedule", systemImage: "clock")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            Text(startsText)
                            Spacer()
                            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .focused($focusedTimePicker, equals: .start)
                                .liquidGlassForm(material: .ultraThin, isFocused: focusedTimePicker == .start)
                                .onChange(of: startTime) { _, _ in
                                    HapticFeedback.selection()
                                    calculateHours()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        focusedTimePicker = nil
                                    }
                                }
                        }
                        
                        HStack {
                            Text(endsText)
                            Spacer()
                            DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .focused($focusedTimePicker, equals: .end)
                                .liquidGlassForm(material: .ultraThin, isFocused: focusedTimePicker == .end)
                                .onChange(of: endTime) { _, _ in
                                    HapticFeedback.selection()
                                    calculateHours()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        focusedTimePicker = nil
                                    }
                                }
                        }
                        
                        HStack {
                            Text(lunchBreakText)
                            Spacer()
                            TextField("0", text: $lunchBreakMinutes)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .lunchBreak)
                                .liquidGlassForm(material: .ultraThin, isFocused: focusedField == .lunchBreak)
                                .frame(width: 60)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: lunchBreakMinutes) { _, _ in
                                    calculateHours()
                                }
                            Text("min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text(isShiftMode ? shiftExpectedHoursText : hoursText)
                                .fontWeight(isShiftMode ? .bold : .regular)
                            Spacer()
                            Text(entryHours.isEmpty ? "0.0" : entryHours)
                                .foregroundStyle(.secondary)
                                .fontWeight(isShiftMode ? .bold : .regular)
                            if getHoursTarget() > 0 && !isShiftMode {
                                Text("/ \(String(format: "%.0f", getHoursTarget()))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .liquidGlassCard()
                    .padding(.horizontal)
                
                    if !isFutureDate {
                        // Sales Section with Liquid Glass
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Sales", systemImage: "chart.bar")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            HStack {
                                Text(salesLabel)
                                Spacer()
                                TextField(formatCurrency(0), text: $entrySales)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .liquidGlassForm(material: .ultraThin, isFocused: focusedField == .sales)
                                    .focused($focusedField, equals: .sales)
                                    .frame(width: 100)
                                    .onChange(of: entrySales) { _, _ in
                                        HapticFeedback.selection()
                                    }
                                if getSalesTarget() > 0 {
                                    Text("/ \(formatCurrency(getSalesTarget()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .liquidGlassCard()
                        .padding(.horizontal)
                        
                        // Earnings Section with Liquid Glass
                        VStack(alignment: .leading, spacing: 16) {
                            Label(earningsSection, systemImage: "dollarsign.circle")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            // Salary (calculated)
                            HStack {
                                Text(salaryLabel)
                                Spacer()
                                Text(formatCurrency(calculatedSalary))
                                    .foregroundStyle(.secondary)
                            }
                        
                            HStack {
                                Text(tipsLabel)
                                Spacer()
                                TextField(formatCurrency(0), text: $entryTips)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .liquidGlassForm(material: .ultraThin, isFocused: focusedField == .tips)
                                    .focused($focusedField, equals: .tips)
                                    .frame(width: 100)
                                    .onChange(of: entryTips) { _, _ in
                                        HapticFeedback.selection()
                                    }
                                if getTipsTarget() > 0 {
                                    Text("/ \(formatCurrency(getTipsTarget()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        
                            HStack {
                                Text(otherLabel)
                                Spacer()
                                TextField(formatCurrency(0), text: $entryOther)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .liquidGlassForm(material: .ultraThin, isFocused: focusedField == .other)
                                    .focused($focusedField, equals: .other)
                                    .frame(width: 100)
                                    .onChange(of: entryOther) { _, _ in
                                        HapticFeedback.selection()
                                    }
                            }
                        
                            HStack {
                                Text(tipOutLabel)
                                Spacer()
                                TextField(formatCurrency(0), text: $entryTipOut)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .liquidGlassForm(material: .ultraThin, isFocused: focusedField == .tipOut)
                                    .focused($focusedField, equals: .tipOut)
                                    .frame(width: 100)
                                    .onChange(of: entryTipOut) { _, _ in
                                        HapticFeedback.selection()
                                    }
                            }
                        
                            // Total (calculated)
                            Rectangle()
                                .fill(.white.opacity(0.2))
                                .frame(height: 0.5)
                                .padding(.horizontal)
                            
                            HStack {
                                Text(totalLabel)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(formatCurrency(calculatedTotal))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(hex: "0288FF"))
                            }
                        }
                        .padding()
                        .liquidGlassCard()
                        .padding(.horizontal)
                    }
                    
                    // Delete Button (only when editing)
                    if editingShift != nil, onDelete != nil {
                        Button(action: {
                            HapticFeedback.error()
                            showDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(deleteButton)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .liquidGlassButton(material: .regular)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.vertical)
            }
            .background(pageBackground)
            .navigationTitle(editingShift != nil ? editShiftTitle : (isShiftMode ? newShiftTitle : newEntryTitle))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadEmployers()
                initializeEditingData()
            }
            .onAppear {
                initializeEditingData()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelToolbarButton
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    saveToolbarButton
                }
            }
        }
        .alert(deleteShiftTitle, isPresented: $showDeleteAlert) {
            Button(deleteButton, role: .destructive) {
                onDelete?()
            }
            Button(cancelButton, role: .cancel) { }
        } message: {
            Text(deleteConfirmMessage)
        }
        .alert(unsavedChangesTitle, isPresented: $showUnsavedChangesAlert) {
            Button(saveButton, role: .none) {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let startTimeString = timeFormatter.string(from: startTime)
                let endTimeString = timeFormatter.string(from: endTime)
                onSave(startTimeString, endTimeString)
            }
            Button(discardChangesButton, role: .destructive) {
                onCancel()
            }
            Button(cancelButton, role: .cancel) { }
        } message: {
            Text(unsavedChangesMessage)
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
    
    func loadEmployers() async {
        guard useEmployers else { return }
        
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            let employers: [Employer] = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .order("name")
                .execute()
                .value
            
            await MainActor.run {
                self.employers = employers
            }
            
            // Load default employer
            await loadDefaultEmployer()
        } catch {
            print("Error loading employers: \(error)")
        }
    }
    
    func loadDefaultEmployer() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct Profile: Decodable {
                let default_employer_id: String?
            }
            
            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("default_employer_id")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let userProfile = profiles.first,
               let defaultEmployerIdString = userProfile.default_employer_id,
               let defaultEmployerId = UUID(uuidString: defaultEmployerIdString) {
                
                await MainActor.run {
                    // Set the default employer as selected
                    selectedEmployerId = defaultEmployerId
                }
            }
        } catch {
            print("Error loading default employer: \(error)")
        }
    }
    
    // Localization
    var newEntryTitle: String {
        switch language {
        case "fr": return "Nouvelle entrée"
        case "es": return "Nueva entrada"
        default: return "New Entry"
        }
    }
    
    var newShiftTitle: String {
        switch language {
        case "fr": return "Nouveau quart"
        case "es": return "Nuevo turno"
        default: return "New Shift"
        }
    }
    
    var editShiftTitle: String {
        switch language {
        case "fr": return "Modifier l'entrée"
        case "es": return "Editar entrada"
        default: return "Edit Entry"
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
    
    var startsText: String {
        switch language {
        case "fr": return "Début"
        case "es": return "Inicio"
        default: return "Starts"
        }
    }
    
    var endsText: String {
        switch language {
        case "fr": return "Fin"
        case "es": return "Fin"
        default: return "Ends"
        }
    }
    
    var lunchBreakText: String {
        switch language {
        case "fr": return "Pause déjeuner"
        case "es": return "Pausa almuerzo"
        default: return "Lunch Break"
        }
    }
    
    var hoursText: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }
    
    var shiftExpectedHoursText: String {
        switch language {
        case "fr": return "Heures prévues du quart"
        case "es": return "Horas esperadas del turno"
        default: return "Shift expected hours"
        }
    }
    
    @ViewBuilder
    private var pageBackground: some View {
        if isShiftMode {
            Color.clear.background(.ultraThinMaterial)
        } else {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(.ultraThinMaterial)
        }
    }
    
    @ViewBuilder
    private var dateSelectionHeader: some View {
        if isShiftMode {
            Label(dateLabel, systemImage: "calendar")
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
    
    @ViewBuilder
    private var dateSelectionContent: some View {
        HStack {
            if !isShiftMode {
                Text(dateLabel)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
            DatePicker("", selection: $entryDate, displayedComponents: .date)
                .labelsHidden()
                .disabled(editingShift != nil)
                .onChange(of: entryDate) { _, _ in
                    HapticFeedback.selection()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedField = nil
                    }
                }
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
    
    var otherLabel: String {
        switch language {
        case "fr": return "Autre"
        case "es": return "Otro"
        default: return "Other"
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
    
    func initializeEditingData() {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        if let editingShift = editingShift {
            // Parse the shift's date to use as the base date
            let shiftDateFormatter = DateFormatter()
            shiftDateFormatter.dateFormat = "yyyy-MM-dd"
            let shiftDate = shiftDateFormatter.date(from: editingShift.shift_date) ?? entryDate
            
            // Initialize start time from existing shift
            if let startTimeString = editingShift.start_time, !startTimeString.isEmpty {
                if let startTimeDate = timeFormatter.date(from: startTimeString) {
                    // Create a date with the shift date and the parsed time
                    let shiftDateComponents = calendar.dateComponents([.year, .month, .day], from: shiftDate)
                    let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTimeDate)
                    
                    var combinedComponents = shiftDateComponents
                    combinedComponents.hour = startTimeComponents.hour
                    combinedComponents.minute = startTimeComponents.minute
                    
                    if let combinedDate = calendar.date(from: combinedComponents) {
                        startTime = combinedDate
                    }
                }
            }
            
            // Initialize end time from existing shift
            if let endTimeString = editingShift.end_time, !endTimeString.isEmpty {
                if let endTimeDate = timeFormatter.date(from: endTimeString) {
                    // Create a date with the shift date and the parsed time
                    let shiftDateComponents = calendar.dateComponents([.year, .month, .day], from: shiftDate)
                    let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTimeDate)
                    
                    var combinedComponents = shiftDateComponents
                    combinedComponents.hour = endTimeComponents.hour
                    combinedComponents.minute = endTimeComponents.minute
                    
                    if let combinedDate = calendar.date(from: combinedComponents) {
                        endTime = combinedDate
                        
                        // Handle case where end time is next day (shift crosses midnight)
                        if endTime < startTime {
                            endTime = calendar.date(byAdding: .day, value: 1, to: endTime) ?? endTime
                        }
                        
                        // Calculate hours after setting times
                        calculateHours()
                    }
                }
            }
        } else {
            // Set default times for new entries: 8:00 AM start, 5:00 PM end
            let entryDateComponents = calendar.dateComponents([.year, .month, .day], from: entryDate)
            
            // Default start time: 8:00 AM
            var startComponents = entryDateComponents
            startComponents.hour = 8
            startComponents.minute = 0
            if let defaultStartTime = calendar.date(from: startComponents) {
                startTime = defaultStartTime
            }
            
            // Default end time: 5:00 PM (17:00)
            var endComponents = entryDateComponents
            endComponents.hour = 17
            endComponents.minute = 0
            if let defaultEndTime = calendar.date(from: endComponents) {
                endTime = defaultEndTime
            }
            
            // Calculate hours with default times
            calculateHours()
        }
        
        // Capture original values after initialization for unsaved changes detection
        captureOriginalValues()
    }
    
    func captureOriginalValues() {
        originalValues = (
            sales: entrySales,
            tips: entryTips,
            tipOut: entryTipOut,
            other: entryOther,
            hours: entryHours,
            lunchBreak: lunchBreakMinutes
        )
    }
    
    var cancelButton: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
    
    var deleteShiftTitle: String {
        switch language {
        case "fr": return "Supprimer l'entrée"
        case "es": return "Eliminar entrada"
        default: return "Delete Entry"
        }
    }
    
    var deleteButton: String {
        switch language {
        case "fr": return "Supprimer"
        case "es": return "Eliminar"
        default: return "Delete"
        }
    }
    
    var deleteConfirmMessage: String {
        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer cette entrée ? Cette action ne peut pas être annulée."
        case "es": return "¿Está seguro de que desea eliminar esta entrada? Esta acción no se puede deshacer."
        default: return "Are you sure you want to delete this entry? This action cannot be undone."
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
    
    private var cancelToolbarButton: some View {
        Button(action: {
            HapticFeedback.selection()
            if hasUnsavedChanges {
                showUnsavedChangesAlert = true
            } else {
                onCancel()
            }
        }) {
            Image(systemName: "xmark")
                .font(.body)
                .fontWeight(.medium)
        }
    }
    
    private var deleteToolbarButton: some View {
        Button(action: {
            HapticFeedback.error()
            showDeleteAlert = true
        }) {
            Image(systemName: "trash")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.red)
        }
    }
    
    private var saveToolbarButton: some View {
        Button(action: {
            HapticFeedback.medium()
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            let startTimeString = timeFormatter.string(from: startTime)
            let endTimeString = timeFormatter.string(from: endTime)
            
            onSave(startTimeString, endTimeString)
        }) {
            if isSaving {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "checkmark")
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
        .disabled(entryHours.isEmpty || (isShiftMode ? false : entryTips.isEmpty))
    }
}
