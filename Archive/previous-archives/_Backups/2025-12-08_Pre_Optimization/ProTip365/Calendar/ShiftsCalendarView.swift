import SwiftUI
import Supabase

struct ShiftsCalendarView: View {
    @State private var selectedDate = Date()
    @State private var allShifts: [ShiftWithEntry] = []
    @State private var dailyShifts: [ShiftWithEntry] = []
    @State private var showDeleteAlert = false
    @State private var showAddEntryView = false
    @State private var showAddShiftView = false
    @State private var selectedShiftForEditing: ShiftWithEntry? = nil
    @State private var shiftToDelete: ShiftWithEntry? = nil
    
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false
    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 15.00
    @AppStorage("defaultEmployerId") private var defaultEmployerIdString: String?
    
    enum DidntWorkReason: String, CaseIterable {
        case sick = "sick"
        case cancelledByEmployer = "cancelled_by_employer"
        case cancelledByMe = "cancelled_by_me"
        
        func localizedText(for language: String) -> String {
            switch self {
            case .sick:
                switch language {
                case "fr": return "J'étais malade"
                case "es": return "Estaba enfermo"
                default: return "I was sick"
                }
            case .cancelledByEmployer:
                switch language {
                case "fr": return "Mon quart a été annulé par l'employeur"
                case "es": return "Mi turno fue cancelado por el empleador"
                default: return "My shift was cancelled by employer"
                }
            case .cancelledByMe:
                switch language {
                case "fr": return "J'ai dû annuler mon quart"
                case "es": return "Tuve que cancelar mi turno"
                default: return "I had to cancel my shift"
                }
            }
        }
    }
    
    // Check if date is in the future
    var isFutureDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected > today
    }
    
    // Check if date is in the past (not today or future)
    var isPastDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected < today
    }
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Form Section
                ScrollView {
                    VStack(spacing: 20) {
                        // Daily Shifts Section (shown first for consistency with other pages)
                        if !dailyShifts.isEmpty {
                            dailyShiftsView
                        }
                        
                        // Helpful explanation
                        if dailyShifts.isEmpty {
                            VStack(spacing: 8) {
                                Text("📅 Schedule your shifts")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("• Future dates: Schedule expected shifts (no earnings shown)\n• Past dates: Record actual work with earnings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .liquidGlassCard()
                            .padding(.horizontal)
                        }
                        
                        // Quick Actions Section (same as Dashboard)
                        quickActionsSection
                    }
                    .padding(.vertical)
                    .padding(.bottom, 100) // Extra space to avoid bottom tab bar
                }
            }
            .navigationTitle("Shifts")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .alert(deleteShiftText, isPresented: $showDeleteAlert) {
                Button(cancelText, role: .cancel) { }
                Button(deleteText, role: .destructive) {
                    deleteShift()
                }
            } message: {
                Text(confirmDeleteMessageText)
            }
            .sheet(isPresented: $showAddEntryView) {
                AddEntryView(editingShift: selectedShiftForEditing, initialDate: selectedShiftForEditing == nil ? selectedDate : nil)
                    .environmentObject(SupabaseManager.shared)
                    .onDisappear {
                        Task {
                            await loadShifts()
                            loadShiftsForDate(selectedDate)
                        }
                    }
            }
            .sheet(isPresented: $showAddShiftView) {
                AddShiftView(initialDate: selectedDate)
                    .onDisappear {
                        Task {
                            await loadShifts()
                            loadShiftsForDate(selectedDate)
                        }
                    }
            }
        }
        .task {
            print("📱 ShiftsCalendarView appeared - loading shifts...")
            await loadShifts()
            loadShiftsForDate(selectedDate)
        }
        .onAppear {
            print("📱 ShiftsCalendarView onAppear")
        }
    }
    
    // MARK: - Daily Shifts View
    var dailyShiftsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(formatDateLong(selectedDate))
                    .font(.subheadline)  // Made smaller
                    .foregroundColor(.primary)
                Spacer()
                Text("\(dailyShifts.count) \(dailyShifts.count == 1 ? entryText : entriesText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
                    .liquidGlassForm()
            
            Divider()
            
            ForEach(dailyShifts.sorted(by: { $0.expected_shift.start_time < $1.expected_shift.start_time }), id: \.id) { shift in
                shiftRowView(shift: shift)

                if shift.id != dailyShifts.sorted(by: { $0.expected_shift.start_time < $1.expected_shift.start_time }).last?.id {
                    Divider()
                }
            }
        }
        .liquidGlassCard()
                .padding(.horizontal)
    }
    
    // MARK: - Shift Row View
    func shiftRowView(shift: ShiftWithEntry) -> some View {
        let _ = print("📝 Displaying shift \(shift.id) with notes: \(shift.expected_shift.notes ?? "none")")
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Time range - prioritize actual times over expected times
                if let entry = shift.entry {
                    Text(formatTimeRange(entry.actual_start_time, entry.actual_end_time))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                } else {
                    Text(formatTimeRange(shift.expected_shift.start_time, shift.expected_shift.end_time))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Check if this is a future shift (expected vs actual)
                let isFutureShift = isShiftInFuture(shift.expected_shift.shift_date)

                if isFutureShift {
                    // Future shift - show expected hours only
                    Text(expectedText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    // Past/today shift - show actual earnings if entry exists
                    if let entry = shift.entry {
                        let totalIncome = (entry.actual_hours * shift.expected_shift.hourly_rate) + entry.tips + entry.sales - entry.cash_out + entry.other
                        Text(formatCurrency(totalIncome))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    } else {
                        Text("No Entry")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Employer if enabled - made bigger
            if useMultipleEmployers, let employer = shift.employer_name {
                HStack {
                    Image(systemName: "building.2")
                        .font(.subheadline)  // Bigger icon
                        .foregroundColor(.blue)
                    Text(employer)
                        .font(.subheadline)  // Bigger text
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    Spacer()
                }
            }

            // Notes preview if available
            if let notes = shift.expected_shift.notes, !notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .font(.subheadline)  // Made icon bigger
                        .foregroundColor(.orange)
                    Text(String(notes.prefix(20)) + (notes.count > 20 ? "..." : ""))
                        .font(.subheadline)  // Made text bigger
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 2)
            }

            // Details row - only show for actual shifts (past/today)
            let isFutureShift = isShiftInFuture(shift.expected_shift.shift_date)
            
            if !isFutureShift, let entry = shift.entry {
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Sales")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(entry.sales))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    VStack(alignment: .leading) {
                        Text("Tips")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(entry.tips))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    if entry.cash_out > 0 {
                        VStack(alignment: .leading) {
                            Text("Tip Out")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(entry.cash_out))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                    }
                }
            } else if isFutureShift {
                // Future shift - show expected hours only
                HStack {
                    Text(expectedHoursText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(shift.expected_shift.expected_hours, specifier: "%.1f")h")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            // Action buttons - made even bigger
            HStack(spacing: 16) {
                Button(action: {
                    selectedShiftForEditing = shift
                    showAddEntryView = true
                    HapticFeedback.light()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)  // Even bigger
                        Text("Edit")
                            .font(.body)  // Bigger text
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }

                Button(action: {
                    shiftToDelete = shift
                    showDeleteAlert = true
                    HapticFeedback.light()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)  // Even bigger
                        Text("Delete")
                            .font(.body)  // Bigger text
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    
    // MARK: - Helper Functions
    func isShiftInFuture(_ shiftDateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let shiftDate = dateFormatter.date(from: shiftDateString) else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let shiftDay = calendar.startOfDay(for: shiftDate)
        
        return shiftDay > today
    }
    
    func dayOfWeekText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    func isTodayDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let checkDate = calendar.startOfDay(for: date)
        return today == checkDate
    }
    
    func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    func getTotalHoursForDate(_ date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let shiftsForDate = allShifts.filter { $0.shift_date == dateString }
        if !shiftsForDate.isEmpty {
            let totalHours = shiftsForDate.reduce(0) { $0 + ($1.hours ?? 0) }
            return String(format: "%.1fh", totalHours)
        }
        return nil
    }
    
    func getShiftCountForDate(_ date: Date) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return allShifts.filter { $0.shift_date == dateString }.count
    }
    
    func formatDateLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatTimeRange(_ startTimeStr: String, _ endTimeStr: String) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        
        if let startTime = timeFormatter.date(from: startTimeStr),
           let endTime = timeFormatter.date(from: endTimeStr) {
            return "\(displayFormatter.string(from: startTime)) - \(displayFormatter.string(from: endTime))"
        }
        return ""
    }
    
    func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    func formatPositiveNumber(_ input: String) -> String {
        let filtered = input.filter { "0123456789.".contains($0) }
        
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1...].joined()
        }
        
        if components.count == 2 && components[1].count > 2 {
            return components[0] + "." + String(components[1].prefix(2))
        }
        
        return filtered
    }
    
    // MARK: - Load Shifts for Date
    func loadShiftsForDate(_ date: Date) {
        selectedDate = date

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        dailyShifts = allShifts.filter { $0.expected_shift.shift_date == dateString }
        print("📝 Loaded \(dailyShifts.count) shifts for date \(dateString)")
        for shift in dailyShifts {
            print("  - Shift \(shift.id) has notes: \(shift.expected_shift.notes ?? "none")")
        }
    }
    
    // MARK: - Load Shifts
    func loadShifts() async {
        print("🔄 ShiftsCalendarView - Starting to load shifts...")
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            // Load shifts for current month plus/minus 1 month for better coverage
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            let endDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate

            print("🔄 ShiftsCalendarView - Loading shifts from \(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate))")

            allShifts = try await SupabaseManager.shared.fetchShiftsWithEntries(
                from: startDate,
                to: endDate
            )

            print("🔄 ShiftsCalendarView - Loaded \(allShifts.count) shifts from database")

            loadShiftsForDate(selectedDate)
        } catch {
            print("❌ ShiftsCalendarView - Error loading shifts: \(error)")
        }
    }

    
    // MARK: - Delete Shift
    func deleteShift() {
        guard let shift = shiftToDelete else { return }

        Task {
            do {
                // Delete shift entry if it exists
                if let entry = shift.entry {
                    try await SupabaseManager.shared.deleteShiftEntry(id: entry.id)
                    DashboardCharts.invalidateCache()
                }

                // Delete expected shift
                try await SupabaseManager.shared.deleteExpectedShift(id: shift.id)

                await loadShifts()

                await MainActor.run {
                    shiftToDelete = nil
                    HapticFeedback.success()
                }

            } catch {
                print("Error deleting shift: \(error)")
                HapticFeedback.error()
            }
        }
    }
    
    // MARK: - Quick Actions Section (same as Dashboard)
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Add Entry Button (Past/Today) - iOS 26 Liquid Glass Style
            Button(action: {
                HapticFeedback.light()
                showAddEntryView = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Add Entry")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.quaternary, lineWidth: 0.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add Shift Button (Future) - iOS 26 Liquid Glass Style
            Button(action: {
                HapticFeedback.light()
                showAddShiftView = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("Add Shift")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.quaternary, lineWidth: 0.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Localization
    var entriesForDayText: String {
        switch language {
        case "fr": return "Entrées pour ce jour"
        case "es": return "Entradas para este día"
        default: return "Entries for this day"
        }
    }
    
    var entryText: String {
        switch language {
        case "fr": return "entrée"
        case "es": return "entrada"
        default: return "entry"
        }
    }
    
    var entriesText: String {
        switch language {
        case "fr": return "entrées"
        case "es": return "entradas"
        default: return "entries"
        }
    }
    
    var addNewEntryText: String {
        switch language {
        case "fr": return "Ajouter une nouvelle entrée"
        case "es": return "Agregar nueva entrada"
        default: return "Add New Entry"
        }
    }
    
    var expectedText: String {
        switch language {
        case "fr": return "Prévu"
        case "es": return "Previsto"
        default: return "Expected"
        }
    }
    
    var expectedHoursText: String {
        switch language {
        case "fr": return "Heures prévues"
        case "es": return "Horas previstas"
        default: return "Expected Hours"
        }
    }
    
    var hoursText: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }
    
    var startsText: String {
        switch language {
        case "fr": return "Commence"
        case "es": return "Empieza"
        default: return "Starts"
        }
    }
    
    var endsText: String {
        switch language {
        case "fr": return "Termine"
        case "es": return "Termina"
        default: return "Ends"
        }
    }
    
    var employerText: String {
        switch language {
        case "fr": return "Employeur"
        case "es": return "Empleador"
        default: return "Employer"
        }
    }
    
    var deleteShiftText: String {
        switch language {
        case "fr": return "Supprimer le quart"
        case "es": return "Eliminar turno"
        default: return "Delete Shift"
        }
    }
    
    var cannotDeleteText: String {
        switch language {
        case "fr": return "Pour supprimer ce quart, vous devez d'abord supprimer les données (heures, ventes, pourboires)."
        case "es": return "Para eliminar este turno, primero debe eliminar los datos (horas, ventas, propinas)."
        default: return "To delete this shift, you must first delete the data (hours, sales, tips)."
        }
    }
    
    var didntWorkText: String {
        switch language {
        case "fr": return "Je n'ai pas travaillé"
        case "es": return "No trabajé"
        default: return "Didn't work"
        }
    }
    
    var reasonText: String {
        switch language {
        case "fr": return "Raison"
        case "es": return "Razón"
        default: return "Reason"
        }
    }

    var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    var deleteText: String {
        switch language {
        case "fr": return "Supprimer"
        case "es": return "Eliminar"
        default: return "Delete"
        }
    }

    var confirmDeleteMessageText: String {
        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer ce quart?"
        case "es": return "¿Está seguro de que desea eliminar este turno?"
        default: return "Are you sure you want to delete this shift?"
        }
    }
}


