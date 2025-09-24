import SwiftUI
import Supabase

struct CalendarShiftsView: View {
    @State private var selectedDate = Date()
    @State private var allShifts: [Shift] = []
    @State private var employers: [UUID: Employer] = [:]
    @State private var showingAddShift = false
    @State private var showingAddEntry = false
    @State private var selectedShiftForEdit: Shift?
    @State private var showingEditSheet = false
    @State private var selectedShiftForAction: Shift?
    @State private var showingActionDialog = false
    @State private var shiftToDelete: Shift?
    @State private var showingDeleteConfirmation = false
    @State private var selectedDateForEntry: Date?
    @State private var selectedShiftForEntry: ShiftIncome?
    @AppStorage("language") private var language = "en"

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
                .background(Color(UIColor.systemBackground))
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
                // Convert Shift to ShiftIncome for editing
                AddShiftView(
                    editingShift: convertShiftToShiftIncome(shift),
                    initialDate: nil
                )
                .onDisappear {
                    Task {
                        await loadAllShifts()
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
                Button(addEntryText) {
                    let shiftIncome = convertShiftToShiftIncome(shift)
                    selectedDateForEntry = dateFromString(shift.shift_date)
                    selectedShiftForEntry = shiftIncome
                    showingAddEntry = true
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
            HStack {
                Text(selectedDateTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatDate(selectedDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ForEach(shiftsForDate(selectedDate), id: \.id) { shift in
                Button(action: {
                    selectedShiftForAction = shift
                    showingActionDialog = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Employer name
                            if let employerId = shift.employer_id,
                               let employer = employers[employerId] {
                                Text(employer.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            } else {
                                Text(noEmployerText)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }

                            // Time range
                            if let startTime = shift.start_time, let endTime = shift.end_time {
                                Text("\(startTime) - \(endTime)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Expected hours
                            if let hours = shift.expected_hours {
                                Text("\(String(format: "%.1f", hours)) \(hoursText)")
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
                            Text(localizedStatus(shift.status ?? "planned"))
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
            // Add Entry Button (only enabled for past dates)
            Button(action: {
                print("📅 Opening AddEntryView with selected date: \(selectedDate)")
                showingAddEntry = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text(addEntryText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(isPastDate ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .disabled(!isPastDate)
            
            // Add Shift Button (disabled for past dates)
            Button(action: {
                showingAddShift = true
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                    Text(addShiftText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(isPastDate ? .secondary : .blue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .disabled(isPastDate)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    private func convertShiftToShiftIncome(_ shift: Shift) -> ShiftIncome {
        // Convert Shift to ShiftIncome for compatibility with AddShiftView
        return ShiftIncome(
            income_id: nil,
            shift_id: shift.id,
            user_id: shift.user_id,
            employer_id: shift.employer_id,
            employer_name: shift.employer_id.flatMap { employers[$0]?.name },
            shift_date: shift.shift_date,
            expected_hours: shift.expected_hours,
            lunch_break_minutes: shift.lunch_break_minutes,
            net_expected_hours: shift.expected_hours,
            hours: 0,
            hourly_rate: shift.hourly_rate,
            sales: 0,
            tips: 0,
            cash_out: nil,
            other: nil,
            base_income: nil,
            net_tips: nil,
            total_income: nil,
            tip_percentage: nil,
            start_time: shift.start_time,
            end_time: shift.end_time,
            shift_status: shift.status,
            has_earnings: false,
            shift_created_at: nil,
            earnings_created_at: nil,
            notes: shift.notes
        )
    }

    private func deleteShift(_ shift: Shift) async {
        guard let shiftId = shift.id else { return }

        do {
            try await SupabaseManager.shared.client
                .from("shifts")
                .delete()
                .eq("id", value: shiftId)
                .execute()

            // Reload shifts after deletion
            await loadAllShifts()
            print("✅ Shift deleted successfully")
        } catch {
            print("❌ Error deleting shift: \(error)")
        }
    }

    private func colorForStatus(_ status: String?) -> Color {
        switch status?.lowercased() {
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

    private func shiftsForDate(_ date: Date) -> [Shift] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let shifts = allShifts.filter { $0.shift_date == dateString }

        if !shifts.isEmpty {
            print("📅 Found \(shifts.count) shifts for date: \(dateString)")
            for shift in shifts {
                print("  - Shift ID: \(shift.id ?? UUID()), Employer: \(shift.employer_id?.uuidString ?? "Unknown")")
            }
        }

        return shifts
    }
    
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
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            // Load shifts for a broader range to cover the calendar view
            let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
            let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

            print("📅 Loading shifts from \(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate))")

            // Load shifts directly from shifts table
            allShifts = try await SupabaseManager.shared.client
                .from("shifts")
                .select()
                .eq("user_id", value: userId)
                .gte("shift_date", value: dateFormatter.string(from: startDate))
                .lte("shift_date", value: dateFormatter.string(from: endDate))
                .order("shift_date", ascending: false)
                .execute()
                .value

            print("✅ Loaded \(allShifts.count) shifts from database")
            if !allShifts.isEmpty {
                print("First few shifts:")
                for (index, shift) in allShifts.prefix(5).enumerated() {
                    print("  \(index + 1). Date: \(shift.shift_date), Status: '\(shift.status ?? "nil")', Hours: \(shift.expected_hours ?? 0)")

                    // Check if date is in future and status should be planned
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    if let shiftDate = dateFormatter.date(from: shift.shift_date) {
                        let today = Calendar.current.startOfDay(for: Date())
                        let shiftDay = Calendar.current.startOfDay(for: shiftDate)
                        if shiftDay > today && shift.status != "planned" {
                            print("    ⚠️ WARNING: Future shift has status '\(shift.status ?? "nil")' but should be 'planned'")
                        }
                    }
                }
            }

            // Load employers for names
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
            switch language {
            case "fr": return status.capitalized
            case "es": return status.capitalized
            default: return status.capitalized
            }
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

    private func deleteMessageText(for shift: Shift) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateStr = dateFormatter.date(from: shift.shift_date).map { dateFormatter.string(from: $0) } ?? shift.shift_date

        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer le quart du \(dateStr)?"
        case "es": return "¿Está seguro de que desea eliminar el turno del \(dateStr)?"
        default: return "Are you sure you want to delete the shift for \(dateStr)?"
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

    private func actionDialogMessage(for shift: Shift) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateStr = dateFormatter.date(from: shift.shift_date).map { dateFormatter.string(from: $0) } ?? shift.shift_date

        switch language {
        case "fr": return "Quart du \(dateStr)"
        case "es": return "Turno del \(dateStr)"
        default: return "Shift for \(dateStr)"
        }
    }

    private func canDeleteShift(_ shift: Shift) -> Bool {
        // Allow deletion if shift is in the future or today
        let today = Calendar.current.startOfDay(for: Date())
        let shiftDate = dateFromString(shift.shift_date)
        return shiftDate >= today
    }

    private func canAddEntry(_ shift: Shift) -> Bool {
        // Allow adding entry for past shifts and today's shifts
        let today = Calendar.current.startOfDay(for: Date())
        let shiftDate = dateFromString(shift.shift_date)
        return shiftDate <= today
    }

    private func dateFromString(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
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
