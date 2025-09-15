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
    @State private var tipTargetPercentage: Double = 0
    @State private var averageDeductionPercentage: Double = 30
    @State private var showExistingShiftAlert = false
    @State private var showNewEntryView = false
    @State private var existingShiftsForSelectedDate: [ShiftIncome] = []
    @AppStorage("language") private var language = "en"

    // Localization helper
    private var localization: CalendarLocalization {
        CalendarLocalization(language: language)
    }

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
                        },
                        language: language
                    )
                    .frame(height: 340)
                    .background(Color(.systemBackground))  // Changed to white background
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))  // Changed to gray background
            .navigationTitle(localization.calendarTitle)
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
                .presentationDetents([.large])
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
        .alert(localization.deleteShiftTitle, isPresented: $showDeleteAlert) {
            Button(localization.cancelText, role: .cancel) { }
            Button(localization.deleteText, role: .destructive) {
                if let shift = shiftToDelete {
                    Task {
                        await deleteShift(shift)
                    }
                }
            }
        } message: {
            Text(localization.deleteConfirmationMessage)
        }
        .alert("Existing Shift Found", isPresented: $showExistingShiftAlert) {
            Button("Edit Existing Shift") {
                // Edit the first existing shift
                if let firstShift = existingShiftsForSelectedDate.first {
                    shiftToEditAsEntry = firstShift
                }
            }
            Button("Add New Shift") {
                // Create a new shift for the same day
                showNewEntryView = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            let shiftCount = existingShiftsForSelectedDate.count
            let message = shiftCount == 1
                ? "You have 1 shift on this date. Would you like to edit it or add another shift?"
                : "You have \(shiftCount) shifts on this date. Would you like to edit the first one or add another shift?"
            Text(message)
        }
        .sheet(isPresented: $showNewEntryView) {
            NavigationStack {
                AddEntryView(initialDate: selectedDate)
                    .environmentObject(SupabaseManager.shared)
                    .onDisappear {
                        Task {
                            await loadAllShifts()
                        }
                    }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Selected Date Shifts View
    private var selectedDateShiftsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date as the header (smaller since user already selected it)
            Text(formatDate(selectedDate))
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(shiftsForDate(selectedDate), id: \.id) { shift in
                ShiftRowView(
                    shift: shift,
                    targetSalesDaily: targetSalesDaily,
                    targetTipsDaily: targetTipsDaily,
                    tipTargetPercentage: tipTargetPercentage,
                    averageDeductionPercentage: averageDeductionPercentage,
                    onEdit: {
                        handleEditShift(shift)
                    },
                    onDelete: {
                        shiftToDelete = shift
                        showDeleteAlert = true
                    }
                )
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))  // Changed to white background
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
                Text(localization.completedText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            // Planned/Scheduled
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 8, height: 8)
                Text(localization.scheduledText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            // Missed
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text(localization.missedText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
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
                Button(action: {
                    // Check if there are existing shifts for this date
                    existingShiftsForSelectedDate = shiftsForDate(selectedDate)
                    if !existingShiftsForSelectedDate.isEmpty {
                        // Show alert to ask user what they want to do
                        showExistingShiftAlert = true
                    } else {
                        // No existing shifts, create new entry
                        showNewEntryView = true
                    }
                }) {
                    HStack {
                        Image(systemName: IconNames.Actions.add)
                            .font(.body)
                        Text(localization.addEntryText)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // For future dates: Show "Add Shift" button (for expected/planned shifts)
                NavigationLink(destination: AddShiftView(initialDate: selectedDate)) {
                    HStack {
                        Image(systemName: IconNames.Actions.add)
                            .font(.body)
                        Text(localization.addShiftText)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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

        // Set locale based on app language setting
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

    private func loadUserTargets() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            struct ProfileTargets: Decodable {
                let target_sales_daily: Double?
                let tip_target_percentage: Double?
                let average_deduction_percentage: Double?
            }

            let profile: ProfileTargets = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("target_sales_daily, tip_target_percentage, average_deduction_percentage")
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value

            targetSalesDaily = profile.target_sales_daily ?? 0
            tipTargetPercentage = profile.tip_target_percentage ?? 15.0 // Default to 15% if not set
            averageDeductionPercentage = profile.average_deduction_percentage ?? 30 // Default to 30% if not set
            // Calculate daily tip target based on percentage if available
            if tipTargetPercentage > 0 && targetSalesDaily > 0 {
                targetTipsDaily = targetSalesDaily * (tipTargetPercentage / 100.0)
            } else {
                targetTipsDaily = 0
            }

            print("📊 Loaded targets - Sales: \(targetSalesDaily), Tips %: \(tipTargetPercentage), Tips $: \(targetTipsDaily)")
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
}