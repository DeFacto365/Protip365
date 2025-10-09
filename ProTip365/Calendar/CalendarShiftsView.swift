import SwiftUI
import Supabase

struct CalendarShiftsView: View {
    @State private var selectedDate = Date()
    @State private var allShifts: [ShiftWithEntry] = []
    @State private var employers: [UUID: Employer] = [:]
    @State private var showingAddShift = false
    @State private var showingAddEntry = false
    @State private var selectedShiftForEdit: ShiftWithEntry?
    @State private var showingEditSheet = false
    @State private var selectedShiftForAction: ShiftWithEntry?
    @State private var showingActionDialog = false
    @State private var shiftToDelete: ShiftWithEntry?
    @State private var showingDeleteConfirmation = false
    @State private var selectedDateForEntry: Date?
    @State private var selectedShiftForEntry: ShiftWithEntry?
    @State private var selectedShiftIncomeForEdit: ShiftWithEntry?
    @State private var showingAddShiftDialog = false
    @State private var showingAddEntryDialog = false
    @State private var showingSelectShiftDialog = false
    @AppStorage("language") private var language = "en"
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var navigateToShiftId: UUID?

    // Calendar date range - show current month plus/minus 2 months
    private var calendarInterval: DateInterval {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let startDate = calendar.date(byAdding: .month, value: -2, to: startOfMonth) ?? Date()
        let endDate = calendar.date(byAdding: .month, value: 3, to: startOfMonth) ?? Date()
        return DateInterval(start: startDate, end: endDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                // Custom Calendar Grid
                CustomCalendarView(
                    selectedDate: $selectedDate,
                    shiftsForDate: shiftsForDate,
                    onDateTapped: { date in
                        selectedDate = date
                    },
                    language: language
                )
                .frame(height: 400)
                .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal)

                // Legend for shift colors
                legendView

                // Action buttons (like dashboard) - moved above entries for visibility
                actionButtonsView

                // Selected date info
                if !shiftsForDate(selectedDate).isEmpty {
                    selectedDateShiftsView
                }

                    Spacer()
                        .frame(height: 100) // Add space to prevent buttons from going under tab bar
                }
                .padding(.bottom, 50) // Additional padding from bottom
            }
            .navigationTitle(calendarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground))
            .task {
                await loadAllShifts()
                // Check if we need to navigate to a specific shift on initial load
                if let shiftId = navigateToShiftId {
                    print("🚀 CalendarShiftsView: Initial navigation to shift ID: \(shiftId)")
                    // Small delay to ensure shifts are loaded
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    navigateToSpecificShift(shiftId: shiftId)
                    navigateToShiftId = nil
                }
            }
            .sheet(isPresented: $showingAddShift) {
                AddShiftView(
                    editingShift: nil,
                    initialDate: selectedDate
                )
                .onDisappear {
                    Task {
                        await loadAllShifts()
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(
                    initialDate: selectedDateForEntry ?? selectedDate,
                    preselectedShift: selectedShiftForEntry
                )
                .onDisappear {
                    Task {
                        await loadAllShifts()
                    }
                    // Clear the selected shift after dismissal
                    selectedDateForEntry = nil
                    selectedShiftForEntry = nil
                }
            }
            .sheet(item: $selectedShiftIncomeForEdit) { shiftWithEntry in
                AddEntryView(
                    editingShift: shiftWithEntry,
                    initialDate: nil
                )
                .onDisappear {
                    Task {
                        await loadAllShifts()
                        // Clear the selection after dismiss
                        selectedShiftIncomeForEdit = nil
                    }
                }
            }
            .refreshable {
                await loadAllShifts()
            }
            .onChange(of: navigateToShiftId) { _, newShiftId in
                print("🔄 CalendarShiftsView: navigateToShiftId changed to: \(newShiftId?.description ?? "nil")")
                if let shiftId = newShiftId {
                    print("📍 CalendarShiftsView: Navigating to shift with ID: \(shiftId)")
                    navigateToSpecificShift(shiftId: shiftId)
                    navigateToShiftId = nil // Reset after navigation
                } else {
                    print("⚠️ CalendarShiftsView: No shift ID provided")
                }
            }
            .alert(deleteAlertTitle, isPresented: $showingDeleteConfirmation, presenting: shiftToDelete) { shift in
                Button(deleteConfirmText, role: .destructive) {
                    Task {
                        await deleteShift(shift)
                    }
                }
                Button(cancelText, role: .cancel) { }
            } message: { shift in
                Text(deleteMessageText(for: shift))
            }
            .sheet(item: $selectedShiftForEdit) { shift in
                AddShiftView(
                    editingShift: shift,
                    initialDate: nil
                )
                .onDisappear {
                    Task {
                        await loadAllShifts()
                        // Also clear the selection to force refresh
                        selectedShiftForEdit = nil
                    }
                }
            }
            .confirmationDialog(
                "What would you like to do?",
                isPresented: $showingActionDialog,
                presenting: selectedShiftForAction
            ) { shift in
                Button(modifyShiftText) {
                    selectedShiftForEdit = shift
                }
                // Show "Modify Entry" for completed shifts, "Add Entry" for others
                if shift.has_entry {
                    Button(modifyEntryText) {
                        selectedShiftIncomeForEdit = shift
                    }
                } else {
                    Button(addEntryText) {
                        selectedDateForEntry = dateFromString(shift.shift_date)
                        selectedShiftForEntry = shift
                        showingAddEntry = true
                    }
                }
                if canDeleteShift(shift) {
                    Button(deleteText, role: .destructive) {
                        shiftToDelete = shift
                        showingDeleteConfirmation = true
                    }
                }
                Button(cancelText, role: .cancel) { }
            } message: { shift in
                Text(actionDialogMessage(for: shift))
            }
            .confirmationDialog(
                addShiftDialogTitle,
                isPresented: $showingAddShiftDialog,
                presenting: shiftsForDate(selectedDate).first
            ) { existingShift in
                Button(modifyExistingShiftText) {
                    selectedShiftForEdit = existingShift
                }
                Button(addNewShiftText) {
                    showingAddShift = true
                }
                Button(cancelText, role: .cancel) { }
            } message: { _ in
                Text(addShiftDialogMessage)
            }
            .confirmationDialog(
                addEntryDialogTitle,
                isPresented: $showingAddEntryDialog,
                presenting: shiftsForDate(selectedDate).first
            ) { existingShift in
                if existingShift.has_entry {
                    // Scenario 2: Shift WITH entry
                    Button(editExistingEntryText) {
                        let shiftsOnDate = shiftsForDate(selectedDate)
                        if shiftsOnDate.count > 1 {
                            // Multiple shifts - show selection dialog
                            showingSelectShiftDialog = true
                            showingAddEntryDialog = false
                        } else {
                            // Single shift - edit directly
                            selectedShiftIncomeForEdit = existingShift
                        }
                    }
                    Button(createNewShiftAndEntryText) {
                        showingAddEntry = true
                    }
                } else {
                    // Scenario 1: Shift WITHOUT entry
                    Button(addEntryToExistingShiftText) {
                        let shiftsOnDate = shiftsForDate(selectedDate)
                        if shiftsOnDate.count > 1 {
                            // Multiple shifts - show selection dialog
                            showingSelectShiftDialog = true
                            showingAddEntryDialog = false
                        } else {
                            // Single shift - add entry directly
                            selectedDateForEntry = selectedDate
                            selectedShiftForEntry = existingShift
                            showingAddEntry = true
                        }
                    }
                    Button(createNewShiftAndEntryText) {
                        showingAddEntry = true
                    }
                }
                Button(cancelText, role: .cancel) { }
            } message: { shift in
                Text(shift.has_entry ? addEntryDialogMessageWithEntry : addEntryDialogMessageNoEntry)
            }
            .confirmationDialog(
                selectShiftDialogTitle,
                isPresented: $showingSelectShiftDialog
            ) {
                ForEach(shiftsForDate(selectedDate), id: \.id) { shift in
                    Button(shiftDisplayName(for: shift)) {
                        if shift.has_entry {
                            // Edit existing entry
                            selectedShiftIncomeForEdit = shift
                        } else {
                            // Add entry to this shift
                            selectedDateForEntry = selectedDate
                            selectedShiftForEntry = shift
                            showingAddEntry = true
                        }
                    }
                }
                Button(cancelText, role: .cancel) { }
            } message: {
                Text(selectShiftDialogMessage)
            }
        }
    }

    // MARK: - Legend View
    private var legendView: some View {
        HStack(spacing: 20) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
                Text(plannedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text(completedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text(missedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // MARK: - Selected Date Shifts View
    private var selectedDateShiftsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(shiftsForDate(selectedDate), id: \.id) { shift in
                Button(action: {
                    selectedShiftForAction = shift
                    showingActionDialog = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Employer name
                            Text(shift.employer_name ?? noEmployerText)
                                .font(.headline)
                                .foregroundColor(.primary)

                            // Show expected vs actual for completed shifts
                            if shift.status == "completed" && shift.has_entry {
                                VStack(alignment: .leading, spacing: 2) {
                                    // Expected section
                                    Text(expectedText + ":")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)

                                    Text("\(formatTimeWithoutSeconds(shift.expected_shift.start_time)) - \(formatTimeWithoutSeconds(shift.expected_shift.end_time))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text("\(String(format: "%.1f", shift.expected_hours)) \(hoursText)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    // Actual section
                                    Text(actualText + ":")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                        .padding(.top, 4)

                                    if let actualStart = shift.entry?.actual_start_time,
                                       let actualEnd = shift.entry?.actual_end_time {
                                        Text("\(formatTimeWithoutSeconds(actualStart)) - \(formatTimeWithoutSeconds(actualEnd))")
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }

                                    if let actualHours = shift.actual_hours {
                                        Text("\(String(format: "%.1f", actualHours)) \(hoursText)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(getHoursVarianceColor(expected: shift.expected_hours, actual: actualHours))
                                    }
                                }
                            } else {
                                // For non-completed shifts, show as before
                                Text("\(formatTimeWithoutSeconds(shift.expected_shift.start_time)) - \(formatTimeWithoutSeconds(shift.expected_shift.end_time))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                // Expected hours
                                Text("\(String(format: "%.1f", shift.expected_hours)) \(hoursText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Notes
                            if let notes = shift.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .padding(.top, 2)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            // Status badge
                            Text(localizedStatus(shift.status))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(colorForStatus(shift.status))
                                )
                                .foregroundColor(.white)

                            // Edit indicator
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        shiftToDelete = shift
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        selectedShiftForEdit = shift
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Action Buttons (like Dashboard)
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Add Entry Button (enabled for today OR past)
            Button(action: {
                handleAddEntryTapped()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text(addEntryText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(canAddEntry ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .disabled(!canAddEntry)

            // Add Shift Button (enabled for today OR future)
            Button(action: {
                handleAddShiftTapped()
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                    Text(addShiftText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(canAddShift ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .disabled(!canAddShift)
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Functions

    private func handleAddShiftTapped() {
        let existingShifts = shiftsForDate(selectedDate)

        if !existingShifts.isEmpty {
            // Show dialog if shifts already exist on this date
            showingAddShiftDialog = true
        } else {
            // No existing shifts, open add shift directly
            showingAddShift = true
        }
    }

    private func handleAddEntryTapped() {
        let existingShifts = shiftsForDate(selectedDate)

        if !existingShifts.isEmpty {
            // Show dialog if shifts already exist on this date
            showingAddEntryDialog = true
        } else {
            // No existing shifts, open add entry directly (will create both shift and entry)
            print("📅 Opening AddEntryView with selected date: \(selectedDate)")
            showingAddEntry = true
        }
    }

    private func deleteShift(_ shift: ShiftWithEntry) async {
        do {
            _ = try await SupabaseManager.shared.client.auth.session.user.id

            // First, delete the entry if it exists
            if let entry = shift.entry {
                try await SupabaseManager.shared.deleteShiftEntry(id: entry.id)
                print("✅ Shift entry deleted")
            }

            // Then delete the expected shift
            try await SupabaseManager.shared.deleteExpectedShift(id: shift.id)

            // Reload shifts after deletion
            await loadAllShifts()
            print("✅ Shift deleted successfully")
        } catch {
            print("❌ Error deleting shift: \(error)")
        }
    }

    private func colorForStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "planned":
            return .purple
        case "missed":
            return .red
        default:
            return .orange
        }
    }

    private func shiftsForDate(_ date: Date) -> [ShiftWithEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let shifts = allShifts.filter { $0.shift_date == dateString }

        if !shifts.isEmpty {
            print("📅 Found \(shifts.count) shifts for date: \(dateString)")
            for shift in shifts {
                print("  - Shift ID: \(shift.id), Employer: \(shift.employer_id?.uuidString ?? "Unknown")")
            }
        }

        return shifts
    }

    // Add Entry: Available for today OR past
    private var canAddEntry: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected <= today
    }

    // Add Shift: Available for today OR future
    private var canAddShift: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected >= today
    }

    // Legacy helper for other uses
    private var isPastDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected < today
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long

        // Set locale based on language
        switch language {
        case "fr":
            formatter.locale = Locale(identifier: "fr_FR")
        case "es":
            formatter.locale = Locale(identifier: "es_ES")
        default:
            formatter.locale = Locale(identifier: "en_US")
        }

        return formatter.string(from: date)
    }

    private func loadAllShifts() async {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            // Load shifts for a broader range to cover the calendar view
            let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
            let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

            print("📅 Loading shifts from \(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate))")

            // Use new simplified method
            allShifts = try await SupabaseManager.shared.fetchShiftsWithEntries(from: startDate, to: endDate)

            print("✅ Loaded \(allShifts.count) shifts with entries from database")

            if !allShifts.isEmpty {
                print("First few shifts:")
                for (index, shift) in allShifts.prefix(5).enumerated() {
                    let entryStatus = shift.has_entry ? "with entry" : "no entry"
                    print("  \(index + 1). Date: \(shift.shift_date), Status: '\(shift.status)', Hours: \(shift.expected_hours), \(entryStatus)")
                }
            }

            // Load employers for names (already included in ShiftWithEntry, but keep for compatibility)
            let employersList = try await SupabaseManager.shared.fetchEmployers()
            employers = Dictionary(uniqueKeysWithValues: employersList.map { ($0.id, $0) })
            print("✅ Loaded \(employers.count) employers")
        } catch {
            print("❌ Error loading shifts: \(error)")
        }
    }

    // MARK: - Localization
    private func localizedStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "planned":
            return plannedText
        case "completed":
            return completedText
        case "missed":
            return missedText
        default:
            return status.capitalized
        }
    }

    private var hoursText: String {
        switch language {
        case "fr": return "heures"
        case "es": return "horas"
        default: return "hours"
        }
    }

    private var plannedText: String {
        switch language {
        case "fr": return "Planifié"
        case "es": return "Planificado"
        default: return "Planned"
        }
    }

    private var completedText: String {
        switch language {
        case "fr": return "Complété"
        case "es": return "Completado"
        default: return "Completed"
        }
    }

    private var missedText: String {
        switch language {
        case "fr": return "Manqué"
        case "es": return "Perdido"
        default: return "Missed"
        }
    }

    private var noEmployerText: String {
        switch language {
        case "fr": return "Aucun employeur"
        case "es": return "Sin empleador"
        default: return "No Employer"
        }
    }

    private var deleteAlertTitle: String {
        switch language {
        case "fr": return "Supprimer le quart"
        case "es": return "Eliminar turno"
        default: return "Delete Shift"
        }
    }

    private var deleteConfirmText: String {
        switch language {
        case "fr": return "Supprimer"
        case "es": return "Eliminar"
        default: return "Delete"
        }
    }

    private var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    private func deleteMessageText(for shift: ShiftWithEntry) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateStr = dateFormatter.date(from: shift.shift_date).map { dateFormatter.string(from: $0) } ?? shift.shift_date

        if shift.has_entry {
            switch language {
            case "fr": return "Ce quart contient des données d'entrée. Le quart ET l'entrée seront supprimés."
            case "es": return "Este turno contiene datos de entrada. El turno Y la entrada se eliminarán."
            default: return "This shift contains entry data. Both the shift AND the entry will be deleted."
            }
        } else {
            switch language {
            case "fr": return "Êtes-vous sûr de vouloir supprimer le quart du \(dateStr)?"
            case "es": return "¿Está seguro de que desea eliminar el turno del \(dateStr)?"
            default: return "Are you sure you want to delete the shift for \(dateStr)?"
            }
        }
    }

    private var calendarTitle: String {
        switch language {
        case "fr": return "Calendrier des quarts"
        case "es": return "Calendario de turnos"
        default: return "Shift Calendar"
        }
    }

    private var selectedDateTitle: String {
        switch language {
        case "fr": return "Quarts sélectionnés"
        case "es": return "Turnos seleccionados"
        default: return "Selected Date Shifts"
        }
    }

    private var addEntryText: String {
        switch language {
        case "fr": return "Ajouter entrée"
        case "es": return "Agregar entrada"
        default: return "Add Entry"
        }
    }

    private var modifyEntryText: String {
        switch language {
        case "fr": return "Modifier l'entrée"
        case "es": return "Modificar entrada"
        default: return "Modify Entry"
        }
    }

    private var expectedText: String {
        switch language {
        case "fr": return "Prévu"
        case "es": return "Esperado"
        default: return "Expected"
        }
    }

    private var actualText: String {
        switch language {
        case "fr": return "Réel"
        case "es": return "Real"
        default: return "Actual"
        }
    }

    private var addShiftText: String {
        switch language {
        case "fr": return "Ajouter quart"
        case "es": return "Agregar turno"
        default: return "Add Shift"
        }
    }

    private var modifyShiftText: String {
        switch language {
        case "fr": return "Modifier le quart"
        case "es": return "Modificar turno"
        default: return "Modify Shift"
        }
    }

    private var deleteText: String {
        switch language {
        case "fr": return "Supprimer"
        case "es": return "Eliminar"
        default: return "Delete"
        }
    }

    private func actionDialogMessage(for shift: ShiftWithEntry) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateStr = dateFormatter.date(from: shift.shift_date).map { dateFormatter.string(from: $0) } ?? shift.shift_date

        switch language {
        case "fr": return "Quart du \(dateStr)"
        case "es": return "Turno del \(dateStr)"
        default: return "Shift for \(dateStr)"
        }
    }

    private var addShiftDialogTitle: String {
        switch language {
        case "fr": return "Quart existant trouvé"
        case "es": return "Turno existente encontrado"
        default: return "Existing Shift Found"
        }
    }

    private var addShiftDialogMessage: String {
        switch language {
        case "fr": return "Un quart existe déjà pour cette date. Que souhaitez-vous faire?"
        case "es": return "Ya existe un turno para esta fecha. ¿Qué te gustaría hacer?"
        default: return "A shift already exists for this date. What would you like to do?"
        }
    }

    private var modifyExistingShiftText: String {
        switch language {
        case "fr": return "Modifier le quart existant"
        case "es": return "Modificar turno existente"
        default: return "Modify Existing Shift"
        }
    }

    private var addNewShiftText: String {
        switch language {
        case "fr": return "Ajouter un nouveau quart"
        case "es": return "Agregar nuevo turno"
        default: return "Add New Shift"
        }
    }

    private var addEntryDialogTitle: String {
        switch language {
        case "fr": return "Quart existant trouvé"
        case "es": return "Turno existente encontrado"
        default: return "Existing Shift Found"
        }
    }

    private var addEntryDialogMessageNoEntry: String {
        switch language {
        case "fr": return "Un quart sans entrée existe pour cette date. Que souhaitez-vous faire?"
        case "es": return "Existe un turno sin entrada para esta fecha. ¿Qué te gustaría hacer?"
        default: return "A shift without an entry exists for this date. What would you like to do?"
        }
    }

    private var addEntryDialogMessageWithEntry: String {
        switch language {
        case "fr": return "Un quart avec entrée existe pour cette date. Que souhaitez-vous faire?"
        case "es": return "Existe un turno con entrada para esta fecha. ¿Qué te gustaría hacer?"
        default: return "A shift with an entry exists for this date. What would you like to do?"
        }
    }

    private var addEntryToExistingShiftText: String {
        switch language {
        case "fr": return "Ajouter entrée au quart existant"
        case "es": return "Agregar entrada al turno existente"
        default: return "Add Entry to Existing Shift"
        }
    }

    private var editExistingEntryText: String {
        switch language {
        case "fr": return "Modifier l'entrée existante"
        case "es": return "Editar entrada existente"
        default: return "Edit Existing Entry"
        }
    }

    private var createNewShiftAndEntryText: String {
        switch language {
        case "fr": return "Créer nouveau quart et entrée"
        case "es": return "Crear nuevo turno y entrada"
        default: return "Create New Shift & Entry"
        }
    }

    private var selectShiftDialogTitle: String {
        switch language {
        case "fr": return "Sélectionner un quart"
        case "es": return "Seleccionar turno"
        default: return "Select Shift"
        }
    }

    private var selectShiftDialogMessage: String {
        switch language {
        case "fr": return "Plusieurs quarts existent pour cette date. Lequel souhaitez-vous utiliser?"
        case "es": return "Existen varios turnos para esta fecha. ¿Cuál desea usar?"
        default: return "Multiple shifts exist for this date. Which one would you like to use?"
        }
    }

    private func shiftDisplayName(for shift: ShiftWithEntry) -> String {
        let employer = shift.employer_name ?? noEmployerText
        let startTime = formatTimeWithoutSeconds(shift.expected_shift.start_time)
        let endTime = formatTimeWithoutSeconds(shift.expected_shift.end_time)
        return "\(employer) (\(startTime) - \(endTime))"
    }

    private func canDeleteShift(_ shift: ShiftWithEntry) -> Bool {
        // Allow deletion if shift is in the future or today
        let today = Calendar.current.startOfDay(for: Date())
        let shiftDate = dateFromString(shift.shift_date)
        return shiftDate >= today
    }

    private func dateFromString(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
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

    // Helper function to get color based on hours variance
    private func getHoursVarianceColor(expected: Double, actual: Double) -> Color {
        let variance = actual - expected

        if variance > 0.5 {
            // Worked more than expected by 30+ minutes
            return .green
        } else if variance < -0.5 {
            // Worked less than expected by 30+ minutes
            return .orange
        } else {
            // Close to expected
            return .primary
        }
    }

    private func navigateToSpecificShift(shiftId: UUID) {
        // Find the shift in our loaded shifts
        guard let shift = allShifts.first(where: { $0.id == shiftId }) else {
            print("❌ Shift with ID \(shiftId) not found in loaded shifts")
            return
        }

        print("✅ Found shift to navigate to: \(shift.shift_date)")

        // Set the selected date to the shift's date
        let shiftDate = dateFromString(shift.shift_date)
        selectedDate = shiftDate

        // Open the edit sheet for this specific shift
        selectedShiftForEdit = shift
        showingEditSheet = true

        print("📅 Navigated to shift on \(shift.shift_date) and opened edit sheet")
    }
}
