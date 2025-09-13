import SwiftUI
import Supabase

struct CalendarShiftsView: View {
    @State private var selectedDate = Date()
    @State private var allShifts: [ShiftIncome] = []
    @State private var shiftToEditAsEntry: ShiftIncome? = nil
    @State private var shiftToEditAsShift: ShiftIncome? = nil
    @State private var shiftToDelete: ShiftIncome? = nil
    @State private var showDeleteAlert = false
    @State private var targetSalesDaily: Double = 0
    @State private var targetTipsDaily: Double = 0
    @AppStorage("language") private var language = "en"
    
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
                VStack(spacing: 12) {
                    // Custom Calendar Grid
                    CustomCalendarView(
                        selectedDate: $selectedDate,
                        shiftsForDate: shiftsForDate,
                        onDateTapped: { date in
                            selectedDate = date
                        }
                    )
                    .frame(height: 320)
                    .liquidGlassCard()
                    .padding(.horizontal)

                    // Color legend
                    calendarLegendView
                        .padding(.horizontal)
                        .padding(.top, -10)

                    // Action buttons directly under calendar
                    actionButtonsView
                        .padding(.horizontal)
                    
                    // Selected date info (this will push buttons down when shown)
                    if !shiftsForDate(selectedDate).isEmpty {
                        selectedDateShiftsView
                    }
                    
                    // Bottom padding for tab bar
                    Color.clear
                        .frame(height: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(calendarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadUserTargets()
                await loadAllShifts()
            }
            .refreshable {
                await loadUserTargets()
                await loadAllShifts()
            }
        }
        .sheet(item: $shiftToEditAsEntry) { shift in
            let _ = print("🟡 CalendarShiftsView - Presenting AddEntryView with shift: \(shift.id)")
            AddEntryView(editingShift: shift)
                .environmentObject(SupabaseManager.shared)
                .onDisappear {
                    Task {
                        await loadAllShifts()
                    }
                }
        }
        .sheet(item: $shiftToEditAsShift) { shift in
            let _ = print("🟡 CalendarShiftsView - Presenting AddShiftView with shift: \(shift.id)")
            AddShiftView(editingShift: shift)
                .onDisappear {
                    Task {
                        await loadAllShifts()
                    }
                }
        }
        .alert(deleteShiftTitle, isPresented: $showDeleteAlert) {
            Button(cancelText, role: .cancel) { }
            Button(deleteText, role: .destructive) {
                if let shift = shiftToDelete {
                    Task {
                        await deleteShift(shift)
                    }
                }
            }
        } message: {
            Text(deleteConfirmationMessage)
        }
    }
    
    // MARK: - Selected Date Shifts View
    private var selectedDateShiftsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date as the header (smaller since user already selected it)
            Text(formatDate(selectedDate))
                .font(.caption)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(shiftsForDate(selectedDate), id: \.id) { shift in
                ShiftRowView(
                    shift: shift,
                    targetSalesDaily: targetSalesDaily,
                    targetTipsDaily: targetTipsDaily,
                    onEdit: {
                        handleEditShift(shift)
                    },
                    onDelete: {
                        shiftToDelete = shift
                        showDeleteAlert = true
                    }
                )
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Calendar Legend
    private var calendarLegendView: some View {
        HStack(spacing: 16) {
            // Completed with earnings
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Completed")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Planned/Scheduled
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 8, height: 8)
                Text("Scheduled")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Missed
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Missed")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Action Buttons (iOS 26 style same as Dashboard)
    private var actionButtonsView: some View {
        VStack(spacing: 0) {
            // Single button logic based on date
            if isPastDateOrToday {
                // For past/today: Show "Add Entry" button (for actual data)
                NavigationLink(destination: AddEntryView(initialDate: selectedDate)) {
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
            } else {
                // For future dates: Show "Add Shift" button (for expected/planned shifts)
                NavigationLink(destination: AddShiftView(initialDate: selectedDate)) {
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
        }
    }
    
    // MARK: - Helper Functions
    private func shiftsForDate(_ date: Date) -> [ShiftIncome] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return allShifts.filter { $0.shift_date == dateString }
    }
    
    private var isPastDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected < today
    }
    
    private var isPastDateOrToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected <= today
    }
    
    private var isTodayOrFuture: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected >= today
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func loadUserTargets() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            struct ProfileTargets: Decodable {
                let target_sales_daily: Double?
                let target_tip_daily: Double?
            }

            let profile: ProfileTargets = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("target_sales_daily, target_tip_daily")
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value

            targetSalesDaily = profile.target_sales_daily ?? 0
            targetTipsDaily = profile.target_tip_daily ?? 0

            print("📊 Loaded targets - Sales: \(targetSalesDaily), Tips: \(targetTipsDaily)")
        } catch {
            print("Error loading user targets: \(error)")
        }
    }

    private func loadAllShifts() async {
        print("📅 CalendarShiftsView - Starting to load all shifts...")
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            // Load shifts for a broader range to cover the calendar view
            let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
            let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

            allShifts = try await SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId)
                .gte("shift_date", value: dateFormatter.string(from: startDate))
                .lte("shift_date", value: dateFormatter.string(from: endDate))
                .execute()
                .value

            print("📅 CalendarShiftsView - Loaded \(allShifts.count) shifts")

            // Load notes for all shifts
            await loadNotesForShifts()
        } catch {
            print("Error loading shifts: \(error)")
        }
    }

    private func loadNotesForShifts() async {
        // Create a simple struct for notes
        struct ShiftNote: Decodable {
            let id: UUID
            let notes: String?
        }

        do {
            // Use shift_id instead of id since that's the actual shifts table ID
            let shiftIds = allShifts.compactMap { $0.shift_id ?? $0.id }
            print("📝 CalendarShiftsView - Loading notes for \(shiftIds.count) shifts")

            if !shiftIds.isEmpty {
                let notes: [ShiftNote] = try await SupabaseManager.shared.client
                    .from("shifts")
                    .select("id, notes")
                    .in("id", values: shiftIds)
                    .execute()
                    .value

                print("📝 CalendarShiftsView - Loaded \(notes.count) notes from database")

                // Update shifts with notes
                for i in 0..<allShifts.count {
                    let shiftId = allShifts[i].shift_id ?? allShifts[i].id
                    if let note = notes.first(where: { $0.id == shiftId }) {
                        print("📝 CalendarShiftsView - Found note for shift: \(note.notes ?? "nil")")
                        // Create a new ShiftIncome with notes
                        let updatedShift = allShifts[i]
                        allShifts[i] = ShiftIncome(
                            income_id: updatedShift.income_id,
                            shift_id: updatedShift.shift_id,
                            user_id: updatedShift.user_id,
                            employer_id: updatedShift.employer_id,
                            employer_name: updatedShift.employer_name,
                            shift_date: updatedShift.shift_date,
                            expected_hours: updatedShift.expected_hours,
                            lunch_break_minutes: updatedShift.lunch_break_minutes,
                            net_expected_hours: updatedShift.net_expected_hours,
                            hours: updatedShift.hours,
                            hourly_rate: updatedShift.hourly_rate,
                            sales: updatedShift.sales,
                            tips: updatedShift.tips,
                            cash_out: updatedShift.cash_out,
                            other: updatedShift.other,
                            base_income: updatedShift.base_income,
                            net_tips: updatedShift.net_tips,
                            total_income: updatedShift.total_income,
                            tip_percentage: updatedShift.tip_percentage,
                            start_time: updatedShift.start_time,
                            end_time: updatedShift.end_time,
                            shift_status: updatedShift.shift_status,
                            has_earnings: updatedShift.has_earnings,
                            shift_created_at: updatedShift.shift_created_at,
                            earnings_created_at: updatedShift.earnings_created_at,
                            notes: note.notes
                        )
                    }
                }
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }
    
    private func handleEditShift(_ shift: ShiftIncome) {
        print("🟡 CalendarShiftsView - handleEditShift called")
        print("🟡 CalendarShiftsView - Shift ID: \(shift.id)")
        print("🟡 CalendarShiftsView - Shift Date: \(shift.shift_date)")
        print("🟡 CalendarShiftsView - Has Earnings: \(shift.has_earnings)")
        print("🟡 CalendarShiftsView - Sales: \(shift.sales), Tips: \(shift.tips)")

        // Parse the shift date to determine if it's past/today or future
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let shiftDate = dateFormatter.date(from: shift.shift_date) ?? Date()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let shiftDay = calendar.startOfDay(for: shiftDate)

        // Use same logic as buttons: past/today opens AddEntryView, future opens AddShiftView
        if shiftDay <= today {
            // Past or today: Always open AddEntryView for entering/editing actual data
            print("🟡 CalendarShiftsView - Opening AddEntryView (past/today date)")
            shiftToEditAsEntry = shift
        } else {
            // Future: Open AddShiftView for editing expected shift
            print("🟡 CalendarShiftsView - Opening AddShiftView (future date)")
            shiftToEditAsShift = shift
        }
    }
    
    private func deleteShift(_ shift: ShiftIncome) async {
        do {
            let shiftId = shift.id
            
            try await SupabaseManager.shared.client
                .from("shifts")
                .delete()
                .eq("id", value: shiftId)
                .execute()
            
            // Reload shifts after deletion
            await loadAllShifts()
            HapticFeedback.success()
        } catch {
            print("Error deleting shift: \(error)")
            HapticFeedback.error()
        }
    }
    
    // MARK: - Localization
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

    private var deleteShiftTitle: String {
        switch language {
        case "fr": return "Supprimer le quart"
        case "es": return "Eliminar turno"
        default: return "Delete Shift"
        }
    }

    private var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    private var deleteText: String {
        switch language {
        case "fr": return "Supprimer"
        case "es": return "Eliminar"
        default: return "Delete"
        }
    }

    private var deleteConfirmationMessage: String {
        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer ce quart?"
        case "es": return "¿Está seguro de que desea eliminar este turno?"
        default: return "Are you sure you want to delete this shift?"
        }
    }

}

// MARK: - Calendar Date View (iOS 26 Style)
struct CalendarDateView: View {
    let date: Date
    let shifts: [ShiftIncome]
    
    var body: some View {
        VStack(spacing: 4) {
            // Date number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 17, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .white : .primary)
            
            // iOS 26 style colored dots for events
            if !shifts.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(shifts.enumerated()), id: \.offset) { index, shift in
                        if index < 3 { // Show max 3 dots
                            Circle()
                                .fill(colorForShift(shift, index: index))
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    // Show "+N" if more than 3 shifts
                    if shifts.count > 3 {
                        Text("+\(shifts.count - 3)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Empty space to maintain consistent height
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(width: 44, height: 44)
        .background(
            Circle()
                .fill(isToday ? Color(.systemGray4) : Color.clear)
        )
        .contentShape(Rectangle())
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    private func colorForShift(_ shift: ShiftIncome, index: Int) -> Color {
        // Use different colors based on shift status and earnings
        if shift.has_earnings {
            // Completed shifts with earnings
            if let total = shift.total_income, total > 0 {
                return [Color.green, Color.blue, Color.purple][index % 3]
            } else {
                return Color.orange // Completed but no earnings
            }
        } else {
            // Planned shifts (no earnings yet)
            switch shift.shift_status {
            case "planned":
                return [Color.cyan, Color.mint, Color.indigo][index % 3]
            case "missed":
                return Color.red
            default:
                return [Color.gray, Color.secondary, Color.primary][index % 3]
            }
        }
    }
}

// MARK: - Shift Row View
struct ShiftRowView: View {
    let shift: ShiftIncome
    let targetSalesDaily: Double
    let targetTipsDaily: Double
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let _ = print("🎯 ShiftRowView - Sales Target: \(targetSalesDaily), Tips Target: \(targetTipsDaily)")
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Left side - Employer and Hours
                VStack(alignment: .leading, spacing: 6) {
                    // Employer name at the top (smaller to fit on one line)
                    if let employer = shift.employer_name {
                        Text(employer)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    // Hours display (actual/expected format)
                    HStack(spacing: 4) {
                        if shift.has_earnings {
                            // Show actual hours / expected hours
                            Text("\(shift.hours, specifier: "%.1f")")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            if let expectedHours = shift.expected_hours {
                                Text("/ \(expectedHours, specifier: "%.1f") hrs")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("hrs")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            // Check if "didn't work"
                            let didntWorkReasons = [
                                "Sick", "Shift Cancelled", "Personal Day", "Holiday", "No-Show", "Other",
                                "Malade", "Quart annulé", "Jour personnel", "Jour férié", "Absence", "Autre",
                                "Enfermo", "Turno cancelado", "Día personal", "Día festivo", "Ausencia", "Otro"
                            ]
                            let isDidntWork = shift.notes.map { didntWorkReasons.contains($0) } ?? false

                            if isDidntWork {
                                Text("0")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            } else if let expectedHours = shift.expected_hours {
                                Text("\(expectedHours, specifier: "%.1f")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }

                            Text("hrs")
                                .font(.subheadline)
                                .foregroundColor(isDidntWork ? .red : .blue)
                        }
                    }

                    // Notes if available (but don't show if it's a "didn't work" reason)
                    if let notes = shift.notes, !notes.isEmpty {
                        let didntWorkReasons = [
                            "Sick", "Shift Cancelled", "Personal Day", "Holiday", "No-Show", "Other",
                            "Malade", "Quart annulé", "Jour personnel", "Jour férié", "Absence", "Autre",
                            "Enfermo", "Turno cancelado", "Día personal", "Día festivo", "Ausencia", "Otro"
                        ]

                        if !didntWorkReasons.contains(notes) {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(.top, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right side - Financial Breakdown with 3 column alignment
                if shift.has_earnings {
                    VStack(spacing: 3) {
                        // Sales with budget comparison
                        if shift.sales > 0 || targetSalesDaily > 0 {
                            HStack(spacing: 8) {
                                Text("Sales")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .leading)

                                Text(formatCurrency(shift.sales))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .frame(width: 55, alignment: .trailing)

                                Text(targetSalesDaily > 0 ? "/\(Int(targetSalesDaily))" : "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 35, alignment: .trailing)
                            }

                            Divider()
                                .padding(.vertical, 1)
                        }

                        // Salary with expected calculation
                        if let baseIncome = shift.base_income, baseIncome > 0 {
                            let expectedSalary = (shift.expected_hours ?? 0) * (shift.hourly_rate ?? 0)
                            HStack(spacing: 8) {
                                Text("Salary")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .leading)

                                Text(formatCurrency(baseIncome))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .frame(width: 55, alignment: .trailing)

                                Text(expectedSalary > 0 ? "/\(Int(expectedSalary))" : "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 35, alignment: .trailing)
                            }
                        }

                        // Tips with budget comparison
                        if shift.tips > 0 || targetTipsDaily > 0 {
                            HStack(spacing: 8) {
                                Text("Tips")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .leading)

                                Text(formatCurrency(shift.tips))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .frame(width: 55, alignment: .trailing)

                                Text(targetTipsDaily > 0 ? "/\(Int(targetTipsDaily))" : "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 35, alignment: .trailing)
                            }
                        }

                        // Other (no budget)
                        if let other = shift.other, other > 0 {
                            HStack(spacing: 8) {
                                Text("Other")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .leading)

                                Text(formatCurrency(other))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .frame(width: 55, alignment: .trailing)

                                Text("")  // Empty space for alignment
                                    .frame(width: 35, alignment: .trailing)
                            }
                        }

                        // Tip Out (no budget, negative value)
                        if let tipOut = shift.cash_out, tipOut > 0 {
                            HStack(spacing: 8) {
                                Text("Tip Out")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .leading)

                                Text("-\(formatCurrency(tipOut))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(width: 55, alignment: .trailing)

                                Text("")  // Empty space for alignment
                                    .frame(width: 35, alignment: .trailing)
                            }
                        }

                        // Total - spans two columns for more space
                        Divider()
                            .padding(.vertical, 1)

                        HStack(spacing: 8) {
                            Text("TOTAL")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .leading)

                            // Total spans both actual and budget columns
                            Text(formatCurrency(shift.total_income ?? 0))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .frame(width: 90, alignment: .trailing)  // 55 + 35 = 90
                        }
                    }
                    .padding(.leading, -5)  // Shift entire section slightly left
                } else {
                    // Show expected label for future shifts or missed work
                    VStack(alignment: .trailing, spacing: 4) {
                        // Check if this is a "didn't work" entry by checking the notes field for known reasons
                        let didntWorkReasons = [
                            "Sick", "Shift Cancelled", "Personal Day", "Holiday", "No-Show", "Other",
                            "Malade", "Quart annulé", "Jour personnel", "Jour férié", "Absence", "Autre",
                            "Enfermo", "Turno cancelado", "Día personal", "Día festivo", "Ausencia", "Otro"
                        ]

                        let isDidntWork = shift.notes.map { didntWorkReasons.contains($0) } ?? false

                        if isDidntWork, let reason = shift.notes {
                            // Show the reason code for "didn't work" entries
                            Text(reason.uppercased())
                                .font(.caption)
                                .textCase(.uppercase)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        } else {
                            // Show "SCHEDULED" for regular future shifts
                            Text("SCHEDULED")
                                .font(.caption)
                                .textCase(.uppercase)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)

            // Action buttons at the bottom
            HStack(spacing: 12) {
                Button(action: {
                    HapticFeedback.light()
                    onEdit()
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                        Text("Edit")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: {
                    HapticFeedback.light()
                    onDelete()
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Delete")
                            .font(.caption)
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .padding(.top, 4)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatTimeRange(_ startTime: String, _ endTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        
        if let start = formatter.date(from: startTime),
           let end = formatter.date(from: endTime) {
            return "\(displayFormatter.string(from: start)) - \(displayFormatter.string(from: end))"
        }
        return ""
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
}

// MARK: - Custom Calendar View
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let shiftsForDate: (Date) -> [ShiftIncome]
    let onDateTapped: (Date) -> Void
    
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 16) {
            // Month header with navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            // iOS 26 style calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(monthDates, id: \.self) { date in
                    CalendarDateView(date: date, shifts: shiftsForDate(date))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDate = date
                            onDateTapped(date)
                        }
                        .opacity(calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? 1.0 : 0.3)
                        .overlay(
                            // iOS 26 style selection indicator
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.blue, lineWidth: calendar.isDate(date, inSameDayAs: selectedDate) ? 2 : 0)
                        )
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var monthDates: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = (firstWeekday - 1)
        
        let startDate = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: firstOfMonth) ?? firstOfMonth
        
        var dates: [Date] = []
        var current = startDate
        
        // Generate 35 days (5 weeks) to fill the calendar grid
        for _ in 0..<35 {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return dates
    }
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

