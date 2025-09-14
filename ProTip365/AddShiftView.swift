import SwiftUI

struct AddShiftView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Parameters
    let editingShift: ShiftIncome?
    let initialDate: Date?

    // MARK: - Initializer
    init(editingShift: ShiftIncome? = nil, initialDate: Date? = nil) {
        self.editingShift = editingShift
        self.initialDate = initialDate
    }

    // MARK: - State Variables
    @State private var selectedDate = Date()
    @State private var selectedEmployer: Employer?
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedLunchBreak = "None"
    @State private var comments = ""
    @State private var employers: [Employer] = []
    @State private var isLoading = false
    @State private var isInitializing = true
    @State private var showDatePicker = false
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var showEmployerPicker = false
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
    @State private var showLunchBreakPicker = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @AppStorage("language") private var language = "en"
    
    // MARK: - Computed Properties
    private var lunchBreakOptions = ["None", "15 min", "30 min", "45 min", "60 min"]
    
    private var expectedHours: Double {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        var totalMinutes = endMinutes - startMinutes
        if totalMinutes < 0 {
            totalMinutes += 24 * 60 // Add 24 hours if end time is next day
        }
        
        // Subtract lunch break
        let lunchMinutes = lunchBreakMinutes
        totalMinutes -= lunchMinutes
        
        return Double(totalMinutes) / 60.0
    }
    
    private var lunchBreakMinutes: Int {
        switch selectedLunchBreak {
        case "15 min": return 15
        case "30 min": return 30
        case "45 min": return 45
        case "60 min": return 60
        default: return 0
        }
    }

    // MARK: - Translation Properties
    private var loadingText: String {
        switch language {
        case "fr": return "Chargement..."
        case "es": return "Cargando..."
        default: return "Loading..."
        }
    }

    private var errorSavingShiftText: String {
        switch language {
        case "fr": return "Erreur lors de l'enregistrement"
        case "es": return "Error al guardar"
        default: return "Error Saving Shift"
        }
    }

    private var okButtonText: String {
        switch language {
        case "fr": return "OK"
        case "es": return "OK"
        default: return "OK"
        }
    }

    private var editShiftText: String {
        switch language {
        case "fr": return "Modifier le quart"
        case "es": return "Editar turno"
        default: return "Edit Shift"
        }
    }

    private var newShiftText: String {
        switch language {
        case "fr": return "Nouveau quart"
        case "es": return "Nuevo turno"
        default: return "New Shift"
        }
    }

    private var employerText: String {
        switch language {
        case "fr": return "Employeur"
        case "es": return "Empleador"
        default: return "Employer"
        }
    }

    private var selectEmployerText: String {
        switch language {
        case "fr": return "Sélectionner un employeur"
        case "es": return "Seleccionar empleador"
        default: return "Select Employer"
        }
    }

    private var startsText: String {
        switch language {
        case "fr": return "Début"
        case "es": return "Inicio"
        default: return "Starts"
        }
    }

    private var endsText: String {
        switch language {
        case "fr": return "Fin"
        case "es": return "Fin"
        default: return "Ends"
        }
    }

    private var lunchBreakText: String {
        switch language {
        case "fr": return "Pause déjeuner"
        case "es": return "Descanso para almorzar"
        default: return "Lunch Break"
        }
    }

    private var selectLunchBreakText: String {
        switch language {
        case "fr": return "Sélectionner la pause déjeuner"
        case "es": return "Seleccionar descanso"
        default: return "Select Lunch Break"
        }
    }

    private var shiftExpectedHoursText: String {
        switch language {
        case "fr": return "Heures prévues du quart"
        case "es": return "Horas esperadas del turno"
        default: return "Shift Expected Hours"
        }
    }

    private var hoursText: String {
        switch language {
        case "fr": return "heures"
        case "es": return "horas"
        default: return "hours"
        }
    }

    private var commentsText: String {
        switch language {
        case "fr": return "Commentaires"
        case "es": return "Comentarios"
        default: return "Comments"
        }
    }

    private var addNotesText: String {
        switch language {
        case "fr": return "Ajouter des notes..."
        case "es": return "Agregar notas..."
        default: return "Add notes..."
        }
    }

    private var selectDateText: String {
        switch language {
        case "fr": return "Sélectionner la date"
        case "es": return "Seleccionar fecha"
        default: return "Select Date"
        }
    }
    
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
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if isInitializing {
                // Show loading state while initializing
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text(loadingText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 0) {
                    // iOS 26 Style Header
                    headerView
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Main Form Card - iOS 26 Style
                            mainFormCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await initializeView()
            }
        }
        .alert(errorSavingShiftText, isPresented: $showErrorAlert) {
            Button(okButtonText) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - iOS 26 Style Header
    private var headerView: some View {
        HStack {
            // Cancel Button with iOS 26 style
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(editingShift != nil ? editShiftText : newShiftText)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Save Button with iOS 26 style
            Button(action: {
                saveShift()
            }) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
            }
            .background(Color(.systemGray5))
            .clipShape(Circle())
            .disabled(isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Main Form Card - iOS 26 Style
    private var mainFormCard: some View {
        VStack(spacing: 0) {
            // Employer Row (moved to top)
            HStack {
                Text(employerText)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showEmployerPicker.toggle()
                        // Close other pickers when opening employer picker
                        showStartDatePicker = false
                        showEndDatePicker = false
                        showStartTimePicker = false
                        showEndTimePicker = false
                        showLunchBreakPicker = false
                    }
                }) {
                    Text(selectedEmployer?.name ?? selectEmployerText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Inline Employer Picker
            if showEmployerPicker {
                Picker(selectEmployerText, selection: $selectedEmployer) {
                    ForEach(employers, id: \.id) { employer in
                        Text(employer.name)
                            .tag(employer as Employer?)
                    }
                }
                .pickerStyle(.wheel)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .onChange(of: selectedEmployer) {
                    // Auto-close picker after selection with iOS-like delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEmployerPicker = false
                        }
                    }
                }
            }
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Starts Row
            HStack {
                Text(startsText)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Date Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showStartDatePicker.toggle()
                            // Close other pickers when opening date picker
                            showEndDatePicker = false
                            showStartTimePicker = false
                            showEndTimePicker = false
                            showEmployerPicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Time Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showStartTimePicker.toggle()
                            // Close other pickers when opening time picker
                            showStartDatePicker = false
                            showEndDatePicker = false
                            showEndTimePicker = false
                            showEmployerPicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(timeFormatter.string(from: startTime))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Inline Date Picker
            if showStartDatePicker {
                DatePicker(selectDateText, selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Inline Start Time Picker
            if showStartTimePicker {
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Ends Row
            HStack {
                Text(endsText)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Date Button (same as start date)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEndDatePicker.toggle()
                            // Close other pickers when opening date picker
                            showStartDatePicker = false
                            showStartTimePicker = false
                            showEndTimePicker = false
                            showEmployerPicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Time Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEndTimePicker.toggle()
                            // Close other pickers when opening time picker
                            showStartDatePicker = false
                            showEndDatePicker = false
                            showStartTimePicker = false
                            showEmployerPicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(timeFormatter.string(from: endTime))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Inline End Time Picker
            if showEndTimePicker {
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Inline End Date Picker
            if showEndDatePicker {
                DatePicker(selectDateText, selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Lunch Break Row
            HStack {
                Text(lunchBreakText)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLunchBreakPicker.toggle()
                        // Close other pickers when opening lunch break picker
                        showStartDatePicker = false
                        showEndDatePicker = false
                        showStartTimePicker = false
                        showEndTimePicker = false
                        showEmployerPicker = false
                    }
                }) {
                    Text(selectedLunchBreak)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Inline Lunch Break Picker
            if showLunchBreakPicker {
                Picker(selectLunchBreakText, selection: $selectedLunchBreak) {
                    ForEach(lunchBreakOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .onChange(of: selectedLunchBreak) {
                    // Auto-close picker after selection with iOS-like delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLunchBreakPicker = false
                        }
                    }
                }
            }
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Shift Expected Hours Row - BOLD
            HStack {
                Text(shiftExpectedHoursText)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(String(format: "%.1f \(hoursText)", expectedHours))
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Comments Row
            VStack(alignment: .leading, spacing: 8) {
                Text(commentsText)
                    .font(.body)
                    .foregroundColor(.primary)
                
                TextField(addNotesText, text: $comments, axis: .vertical)
                    .font(.body)
                    .textFieldStyle(.plain)
                    .lineLimit(2...2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Helper Functions
    private func initializeView() async {
        // First load employers
        await loadEmployers()

        // Then setup default times (which may depend on employers being loaded)
        await setupDefaultTimes()

        // Finally, mark initialization as complete
        await MainActor.run {
            isInitializing = false
        }
    }
    
    private func loadEmployers() async {
        do {
            let fetchedEmployers = try await SupabaseManager.shared.fetchEmployers()
            
            await MainActor.run {
                self.employers = fetchedEmployers
                
                // If editing, set the employer from the shift
                if let shift = editingShift,
                   let employerId = shift.employer_id {
                    selectedEmployer = fetchedEmployers.first { $0.id == employerId }
                }
                // Set default employer if none selected
                else if selectedEmployer == nil && !fetchedEmployers.isEmpty {
                    // Just use first employer as default for now
                    selectedEmployer = fetchedEmployers.first
                }
            }
        } catch {
            print("Error loading employers: \(error)")
            // Even on error, mark as not initializing to show the UI
            await MainActor.run {
                isInitializing = false
            }
        }
    }
    
    private func setupDefaultTimes() async {
        let calendar = Calendar.current
        let now = Date()

        // If editing, populate with existing shift data
        if let shift = editingShift {
            print("📝 Setting up edit mode for shift ID: \(shift.shift_id ?? UUID())")
            print("📝 Shift date: \(shift.shift_date)")
            print("📝 Employer ID: \(shift.employer_id?.uuidString ?? "none")")
            print("📝 Start time: \(shift.start_time ?? "none")")
            print("📝 End time: \(shift.end_time ?? "none")")

            // Parse shift date first
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let shiftDate = dateFormatter.date(from: shift.shift_date) ?? Date()

            await MainActor.run {
                selectedDate = shiftDate
            }

            // Parse start and end times
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            // Also try HH:mm format if HH:mm:ss fails
            let timeFormatterShort = DateFormatter()
            timeFormatterShort.dateFormat = "HH:mm"

            if let startTimeString = shift.start_time {
                var startDateParsed = timeFormatter.date(from: startTimeString)
                if startDateParsed == nil {
                    startDateParsed = timeFormatterShort.date(from: startTimeString)
                }

                if let startDateParsed = startDateParsed {
                    // Combine with selected date
                    let startComponents = calendar.dateComponents([.hour, .minute], from: startDateParsed)
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: shiftDate)
                    dateComponents.hour = startComponents.hour
                    dateComponents.minute = startComponents.minute
                    if let combinedDate = calendar.date(from: dateComponents) {
                        await MainActor.run {
                            startTime = combinedDate
                        }
                    }
                }
            }

            if let endTimeString = shift.end_time {
                var endDateParsed = timeFormatter.date(from: endTimeString)
                if endDateParsed == nil {
                    endDateParsed = timeFormatterShort.date(from: endTimeString)
                }

                if let endDateParsed = endDateParsed {
                    // Combine with selected date
                    let endComponents = calendar.dateComponents([.hour, .minute], from: endDateParsed)
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: shiftDate)
                    dateComponents.hour = endComponents.hour
                    dateComponents.minute = endComponents.minute
                    if let combinedDate = calendar.date(from: dateComponents) {
                        await MainActor.run {
                            endTime = combinedDate
                        }
                    }
                }
            }

            // Set lunch break
            if let lunchMinutes = shift.lunch_break_minutes {
                await MainActor.run {
                    switch lunchMinutes {
                    case 15: selectedLunchBreak = "15 min"
                    case 30: selectedLunchBreak = "30 min"
                    case 45: selectedLunchBreak = "45 min"
                    case 60: selectedLunchBreak = "60 min"
                    default: selectedLunchBreak = "None"
                    }
                }
            }

            // Set employer - now employers should be loaded
            if let employerId = shift.employer_id {
                await MainActor.run {
                    selectedEmployer = employers.first { $0.id == employerId }
                    print("📝 Selected employer: \(selectedEmployer?.name ?? "not found")")
                }
            }

            // Load notes separately from shifts table since they're not in ShiftIncome view
            if let shiftId = shift.shift_id {
                await loadNotesForShift(shiftId: shiftId)
            }
        } else {
            // Default times for new shift
            await MainActor.run {
                // Use initialDate if provided, otherwise use today
                let baseDate = initialDate ?? now
                selectedDate = baseDate

                // Set start time to 8:00 AM on the selected date
                var startComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
                startComponents.hour = 8
                startComponents.minute = 0
                startTime = calendar.date(from: startComponents) ?? baseDate

                // Set end time to 5:00 PM on the selected date
                var endComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
                endComponents.hour = 17
                endComponents.minute = 0
                endTime = calendar.date(from: endComponents) ?? baseDate
            }
        }
    }
    
    private func loadNotesForShift(shiftId: UUID) async {
        do {
            print("📝 Loading notes for shift ID: \(shiftId)")

            // Create a simple struct just for notes
            struct NoteOnly: Decodable {
                let notes: String?
            }

            let result: NoteOnly = try await SupabaseManager.shared.client
                .from("shifts")
                .select("notes")
                .eq("id", value: shiftId)
                .single()
                .execute()
                .value

            if let notes = result.notes {
                await MainActor.run {
                    comments = notes
                    print("📝 Loaded notes: \(notes)")
                }
            } else {
                print("📝 No notes found for shift")
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }

    private func saveShift() {
        guard let employer = selectedEmployer else {
            print("❌ No employer selected")
            return
        }
        
        print("💾 Starting to save shift...")
        print("📅 Date: \(selectedDate)")
        print("👤 Employer: \(employer.name)")
        print("⏰ Start: \(startTime)")
        print("⏰ End: \(endTime)")
        print("🍽️ Lunch Break: \(selectedLunchBreak)")
        print("📝 Comments: \(comments)")
        print("⏱️ Expected Hours: \(expectedHours)")
        
        isLoading = true
        
        Task {
            do {
                // Get current user ID
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id
                print("👤 User ID: \(userId)")
                
                // Format dates as strings
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                
                if let existingShift = editingShift {
                    // Update existing shift - use shift_id which is the ID from shifts table
                    guard let shiftId = existingShift.shift_id else {
                        throw NSError(domain: "AddShiftView", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid shift ID"])
                    }

                    let updatedShift = Shift(
                        id: shiftId,  // Use the shift_id from the ShiftIncome model
                        user_id: userId,
                        employer_id: employer.id,
                        shift_date: dateFormatter.string(from: selectedDate),
                        expected_hours: expectedHours,
                        hours: expectedHours,
                        lunch_break_minutes: lunchBreakMinutes,
                        hourly_rate: employer.hourly_rate,
                        notes: comments.isEmpty ? nil : comments,
                        start_time: timeFormatter.string(from: startTime),
                        end_time: timeFormatter.string(from: endTime),
                        status: "planned",
                        created_at: nil
                    )

                    print("📦 Updating shift with ID: \(shiftId)")
                    print("📦 Shift details: \(updatedShift)")

                    // Update in Supabase
                    try await SupabaseManager.shared.updateShift(updatedShift)
                    print("✅ Shift updated successfully!")
                } else {
                    // Create new shift
                    let newShift = Shift(
                        id: UUID(),
                        user_id: userId,
                        employer_id: employer.id,
                        shift_date: dateFormatter.string(from: selectedDate),
                        expected_hours: expectedHours,
                        hours: expectedHours,
                        lunch_break_minutes: lunchBreakMinutes,
                        hourly_rate: employer.hourly_rate,
                        notes: comments.isEmpty ? nil : comments,
                        start_time: timeFormatter.string(from: startTime),
                        end_time: timeFormatter.string(from: endTime),
                        status: "planned",
                        created_at: Date()
                    )
                    
                    print("📦 Created shift object: \(newShift)")
                    
                    // Save to Supabase
                    try await SupabaseManager.shared.saveShift(newShift)
                    print("✅ Shift saved successfully!")
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("❌ Error saving shift: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    AddShiftView()
}