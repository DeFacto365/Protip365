import SwiftUI
import Supabase
import UIKit

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    // MARK: - Parameters
    let editingShift: ShiftIncome?
    let initialDate: Date?
    let preselectedShift: ShiftIncome?

    // MARK: - State
    @State private var state = AddEntryState()
    @State private var employers: [Employer] = []
    @State private var showDeleteConfirmation = false

    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 15.00
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false
    @AppStorage("language") private var language = "en"
    
    // MARK: - Computed Properties
    private var localizedStrings: AddEntryLocalizedStrings {
        AddEntryLocalizedStrings(language: language)
    }
    
    // MARK: - Initializer
    init(editingShift: ShiftIncome? = nil, initialDate: Date? = nil, preselectedShift: ShiftIncome? = nil) {
        self.editingShift = editingShift
        self.initialDate = initialDate
        self.preselectedShift = preselectedShift
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // iOS 26 Style Header
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Work Info Card - iOS 26 Style
                        workInfoCard

                        // Time Picker Card - Only show if worked
                        if !state.didntWork {
                            timePickerCard
                        }

                        // Earnings Card - iOS 26 Style (only show if worked)
                        if !state.didntWork {
                            earningsCard
                        }

                        // Summary Card - iOS 26 Style
                        summaryCard
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? 40 : 8)
                    .padding(.top, 10)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 900 : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            Task {
                await loadEmployers()
                if let shift = editingShift {
                    populateFieldsForEditing(shift: shift)
                } else if let preselected = preselectedShift {
                    // Pre-populate fields with the selected shift data
                    populateFieldsForPreselectedShift(shift: preselected)
                } else {
                    setupDefaultTimes()
                }
            }
        }
        .alert(localizedStrings.errorSavingEntryText, isPresented: $state.showErrorAlert) {
            Button(localizedStrings.okButtonText) { }
        } message: {
            Text(state.errorMessage)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .interactiveDismissDisabled(state.hasUnsavedChanges())
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
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }

            // Delete Button (only for editing mode)
            if editingShift != nil {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .confirmationDialog(
                    localizedStrings.deleteConfirmationTitle,
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(localizedStrings.deleteButtonText, role: .destructive) {
                        deleteEntry()
                    }
                    Button(localizedStrings.cancelText, role: .cancel) {}
                } message: {
                    Text(localizedStrings.deleteConfirmationMessage)
                }
            }

            Spacer()

            Text(editingShift != nil ? localizedStrings.editEntryText : localizedStrings.newEntryText)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Save Button with iOS 26 style
            Button(action: {
                saveEntry()
            }) {
                if state.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .disabled(state.isLoading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Work Info Card
    private var workInfoCard: some View {
        WorkInfoSection(
            selectedEmployer: Binding(
                get: { state.selectedEmployer },
                set: { state.selectedEmployer = $0 }
            ),
            didntWork: $state.didntWork,
            missedReason: $state.missedReason,
            showEmployerPicker: $state.showEmployerPicker,
            showReasonPicker: $state.showReasonPicker,
            calculatedHours: .constant(state.calculatedHours),
            employers: employers,
            useMultipleEmployers: useMultipleEmployers,
            missedReasonOptions: localizedStrings.missedReasonOptions,
            employerText: localizedStrings.employerText,
            didntWorkText: localizedStrings.didntWorkText,
            reasonText: localizedStrings.reasonText,
            selectReasonText: localizedStrings.selectReasonText,
            statusText: localizedStrings.statusText,
            totalHoursText: localizedStrings.totalHoursText,
            hoursUnit: localizedStrings.hoursUnit,
            showDidntWorkOption: editingShift == nil,  // Only show for new entries
            closeOtherPickers: closeOtherPickers
        )
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Time Picker Card
    private var timePickerCard: some View {
        TimePickerSection(
            selectedDate: $state.selectedDate,
            selectedEndDate: $state.selectedEndDate,
            startTime: $state.startTime,
            endTime: $state.endTime,
            selectedLunchBreak: $state.selectedLunchBreak,
            showDatePicker: $state.showDatePicker,
            showEndDatePicker: $state.showEndDatePicker,
            showStartTimePicker: $state.showStartTimePicker,
            showEndTimePicker: $state.showEndTimePicker,
            showLunchBreakPicker: $state.showLunchBreakPicker,
            editingShift: editingShift,
            lunchBreakOptions: AddEntryConstants.lunchBreakOptions,
            startsText: localizedStrings.startsText,
            endsText: localizedStrings.endsText,
            lunchBreakText: localizedStrings.lunchBreakText
        )
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Earnings Card
    private var earningsCard: some View {
        EarningsSection(
            sales: $state.sales,
            tips: $state.tips,
            tipOut: $state.tipOut,
            other: $state.other,
            comments: $state.comments,
            salesText: localizedStrings.salesText,
            tipsText: localizedStrings.tipsText,
            tipOutText: localizedStrings.tipOutText,
            otherText: localizedStrings.otherText,
            notesText: localizedStrings.notesText,
            optionalNotesText: localizedStrings.optionalNotesText
        )
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        SummarySection(
            didntWork: state.didntWork,
            missedReason: state.missedReason,
            sales: state.sales,
            tips: state.tips,
            tipOut: state.tipOut,
            other: state.other,
            calculatedHours: state.calculatedHours,
            selectedEmployer: state.selectedEmployer,
            defaultHourlyRate: defaultHourlyRate,
            totalEarnings: computeTotalEarnings(),
            summaryText: localizedStrings.summaryText,
            didntWorkText: localizedStrings.didntWorkText,
            reasonText: localizedStrings.reasonText,
            salesText: localizedStrings.salesText,
            grossPayText: localizedStrings.grossPayText,
            tipsText: localizedStrings.tipsText,
            otherText: localizedStrings.otherText,
            tipOutText: localizedStrings.tipOutText,
            totalEarningsText: localizedStrings.totalEarningsText
        )
    }
    
    // MARK: - Helper Functions
    private func closeOtherPickers(except: String? = nil) {
        if except != "date" { state.showDatePicker = false }
        if except != "endDate" { state.showEndDatePicker = false }
        if except != "startTime" { state.showStartTimePicker = false }
        if except != "endTime" { state.showEndTimePicker = false }
        if except != "lunchBreak" { state.showLunchBreakPicker = false }
        if except != "employer" { state.showEmployerPicker = false }
        if except != "reason" { state.showReasonPicker = false }
    }

    private func computeTotalEarnings() -> Double {
        let tipsAmount = Double(state.tips) ?? 0
        let tipOutAmount = Double(state.tipOut) ?? 0
        let otherAmount = Double(state.other) ?? 0
        let hourlyRate = state.selectedEmployer?.hourly_rate ?? defaultHourlyRate
        let salary = state.calculatedHours * hourlyRate
        return salary + tipsAmount + otherAmount - tipOutAmount
    }

    private func setupDefaultTimes() {
        let calendar = Calendar.current
        // Use initialDate if provided, otherwise use today
        let baseDate = initialDate ?? Date()

        print("📅 AddEntryView - setupDefaultTimes")
        print("  Initial date provided: \(initialDate?.description ?? "nil")")
        print("  Using base date: \(baseDate)")

        state.selectedDate = baseDate
        state.selectedEndDate = baseDate  // Default to same date

        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)

        // Set default start time to 5:00 PM on the selected date
        components.hour = 17
        components.minute = 0
        state.startTime = calendar.date(from: components) ?? baseDate

        // Set default end time to 10:00 PM on the selected date
        components.hour = 22
        components.minute = 0
        state.endTime = calendar.date(from: components) ?? baseDate
    }
    
    private func loadEmployers() async {
        do {
            let userId = try await supabaseManager.client.auth.session.user.id
            employers = try await supabaseManager.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .eq("active", value: true)  // Only load active employers
                .execute()
                .value

            // If editing, find and set the employer after loading
            if let shift = editingShift, let employerId = shift.employer_id {
                state.selectedEmployer = employers.first { $0.id == employerId }
            } else if editingShift == nil && !employers.isEmpty {
                // For new entries, set the first employer as default
                state.selectedEmployer = employers.first
            }
        } catch {
            print("Error loading employers: \(error)")
        }
    }
    
    private func populateFieldsForEditing(shift: ShiftIncome) {
        // Set the date
        state.selectedDate = dateStringToDate(shift.shift_date) ?? Date()
        state.selectedEndDate = state.selectedDate  // Default to same date initially

        // Parse times
        if let startTimeStr = shift.start_time,
           let endTimeStr = shift.end_time {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"

            var startHour = 0
            var startMinute = 0
            var endHour = 0
            var endMinute = 0

            if let parsedStartTime = timeFormatter.date(from: startTimeStr) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: parsedStartTime)
                startHour = components.hour ?? 0
                startMinute = components.minute ?? 0
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: state.selectedDate)
                dateComponents.hour = startHour
                dateComponents.minute = startMinute
                state.startTime = calendar.date(from: dateComponents) ?? Date()
            }

            if let parsedEndTime = timeFormatter.date(from: endTimeStr) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: parsedEndTime)
                endHour = components.hour ?? 0
                endMinute = components.minute ?? 0

                // Check if shift crosses midnight (end time is before start time)
                if endHour < startHour || (endHour == startHour && endMinute <= startMinute) {
                    // Shift crosses midnight, set end date to next day
                    state.selectedEndDate = calendar.date(byAdding: .day, value: 1, to: state.selectedDate) ?? state.selectedDate
                }

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: state.selectedEndDate)
                dateComponents.hour = endHour
                dateComponents.minute = endMinute
                state.endTime = calendar.date(from: dateComponents) ?? Date()
            }
        } else {
            // If no times stored, use default times
            setupDefaultTimes()
        }

        // Set the values from the shift
        state.sales = (shift.sales ?? 0) > 0 ? String(format: "%.2f", shift.sales ?? 0) : ""
        state.tips = (shift.tips ?? 0) > 0 ? String(format: "%.2f", shift.tips ?? 0) : ""
        state.tipOut = (shift.cash_out ?? 0) > 0 ? String(format: "%.2f", shift.cash_out ?? 0) : ""
        state.other = (shift.other ?? 0) > 0 ? String(format: "%.2f", shift.other ?? 0) : ""

        // Set lunch break from shift data
        state.selectedLunchBreak = AddEntryConstants.lunchBreakSelection(from: shift.lunch_break_minutes)

        // Load notes separately from shifts table
        Task {
            await loadNotesForShift(shiftId: shift.id)
        }

        // Find employer - this will be set after employers are loaded
        if let employerId = shift.employer_id {
            state.selectedEmployer = employers.first { $0.id == employerId }
        }
    }

    private func populateFieldsForPreselectedShift(shift: ShiftIncome) {
        // Similar to populateFieldsForEditing but for new entries with preselected shift
        // Set the date
        state.selectedDate = dateStringToDate(shift.shift_date) ?? Date()
        state.selectedEndDate = state.selectedDate

        // Set shift info
        if let startTimeStr = shift.start_time,
           let endTimeStr = shift.end_time {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"

            if let parsedStartTime = timeFormatter.date(from: startTimeStr) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: parsedStartTime)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: state.selectedDate)
                dateComponents.hour = components.hour ?? 0
                dateComponents.minute = components.minute ?? 0
                state.startTime = calendar.date(from: dateComponents) ?? Date()
            }

            if let parsedEndTime = timeFormatter.date(from: endTimeStr) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: parsedEndTime)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: state.selectedDate)
                dateComponents.hour = components.hour ?? 0
                dateComponents.minute = components.minute ?? 0
                state.endTime = calendar.date(from: dateComponents) ?? Date()
            }
        }

        // Set lunch break (convert minutes to selection string)
        state.selectedLunchBreak = AddEntryConstants.lunchBreakSelection(from: shift.lunch_break_minutes)

        // Find employer - this will be set after employers are loaded
        if let employerId = shift.employer_id {
            state.selectedEmployer = employers.first { $0.id == employerId }
        }

        // For preselected shift, we want to create a NEW entry, so don't set editingEntry
        // Leave financial fields empty for user to fill
    }

    private func loadNotesForShift(shiftId: UUID) async {
        do {
            // Create a simple struct just for notes
            struct NoteOnly: Decodable {
                let notes: String?
            }

            let result: NoteOnly = try await supabaseManager.client
                .from("shifts")
                .select("notes")
                .eq("id", value: shiftId)
                .single()
                .execute()
                .value

            if let notes = result.notes {
                await MainActor.run {
                    state.comments = notes
                    print("📝 Loaded notes: \(notes)")
                }
            } else {
                print("📝 No notes found for shift")
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }
    
    private func dateStringToDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func saveEntry() {
        // Check subscription limits for part-time tier (only for new entries)
        if subscriptionManager.currentTier == .partTime && editingShift == nil {
            if !subscriptionManager.canAddEntry() {
                state.errorMessage = "You've reached your weekly limit of 3 entries."
                if let remaining = subscriptionManager.getRemainingEntries() {
                    state.errorMessage += " \(remaining) entries remaining this week."
                }
                state.showErrorAlert = true
                return
            }
        }

        Task {
            do {
                state.isLoading = true

                let userId = try await supabaseManager.client.auth.session.user.id

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let shiftDate = dateFormatter.string(from: state.selectedDate)

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                let startTimeStr = timeFormatter.string(from: state.startTime)
                let endTimeStr = timeFormatter.string(from: state.endTime)

                // NEW ARCHITECTURE:
                // 1. Find or create expected shift in 'shifts' table
                // 2. Create/update actual earnings in 'shift_income' table

                let shiftId: UUID

                // If we're editing an existing shift, use its shift_id directly
                if let editingShift = editingShift, let existingShiftId = editingShift.shift_id {
                    shiftId = existingShiftId

                    // Update the shift's date if it has changed
                    struct ShiftDateUpdate: Encodable {
                        let shift_date: String
                    }

                    try await supabaseManager.client
                        .from("shifts")
                        .update(ShiftDateUpdate(shift_date: shiftDate))
                        .eq("id", value: shiftId)
                        .execute()
                } else {
                    // For new entries, ALWAYS create a new shift (don't reuse existing ones)
                    // This allows multiple shifts per day
                    // Create new shift record (this happens when entering actual data without pre-planning)
                    struct ShiftInsert: Encodable {
                        let user_id: UUID
                        let shift_date: String
                        let expected_hours: Double
                        let hours: Double  // Required field
                        let start_time: String
                        let end_time: String
                        let hourly_rate: Double
                        let employer_id: UUID?
                        let sales: Double
                        let tips: Double
                        let cash_out: Double
                        let other: Double
                        let status: String
                        let notes: String?
                    }

                    let shiftData = ShiftInsert(
                        user_id: userId,
                        shift_date: shiftDate,
                        expected_hours: state.calculatedHours, // Use actual as expected since not pre-planned
                        hours: state.calculatedHours,  // Set the required hours field
                        start_time: startTimeStr,
                        end_time: endTimeStr,
                        hourly_rate: state.selectedEmployer?.hourly_rate ?? defaultHourlyRate,
                        employer_id: state.selectedEmployer?.id,
                        sales: Double(state.sales) ?? 0,
                        tips: Double(state.tips) ?? 0,
                        cash_out: Double(state.tipOut) ?? 0,
                        other: Double(state.other) ?? 0,
                        status: "completed",
                        notes: state.comments.isEmpty ? nil : state.comments
                    )

                    struct ShiftResponse: Decodable {
                        let id: UUID
                    }

                    let response: [ShiftResponse] = try await supabaseManager.client
                        .from("shifts")
                        .insert(shiftData)
                        .select("id")
                        .execute()
                        .value

                    guard let newShiftId = response.first?.id else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create shift"])
                    }

                    shiftId = newShiftId
                }

                // Now handle the actual earnings data in shift_income table (only if worked)
                // Skip income record if didn't work
                if !state.didntWork {
                // Check if we already have an income record (when editing)
                let incomeId: UUID?
                if let editingShift = editingShift, let existingIncomeId = editingShift.income_id {
                    // We're editing an existing entry that already has income data
                    incomeId = existingIncomeId
                } else {
                    // Check if income record already exists for this shift
                    struct IncomeCheck: Decodable {
                        let id: UUID
                    }

                    let incomeResults: [IncomeCheck] = try await supabaseManager.client
                        .from("shift_income")
                        .select("id")
                        .eq("shift_id", value: shiftId)
                        .execute()
                        .value
                    incomeId = incomeResults.first?.id
                }

                if let incomeId = incomeId {
                    // Update existing income record
                    struct IncomeUpdate: Encodable {
                        let actual_hours: Double
                        let sales: Double
                        let tips: Double
                        let cash_out: Double
                        let other: Double
                        let actual_start_time: String
                        let actual_end_time: String
                        let notes: String?
                        let updated_at: String
                    }

                    let updateData = IncomeUpdate(
                        actual_hours: state.calculatedHours,
                        sales: Double(state.sales) ?? 0,
                        tips: Double(state.tips) ?? 0,
                        cash_out: Double(state.tipOut) ?? 0,
                        other: Double(state.other) ?? 0,
                        actual_start_time: startTimeStr,
                        actual_end_time: endTimeStr,
                        notes: state.comments.isEmpty ? nil : state.comments,
                        updated_at: ISO8601DateFormatter().string(from: Date())
                    )

                    try await supabaseManager.client
                        .from("shift_income")
                        .update(updateData)
                        .eq("id", value: incomeId)
                        .execute()
                } else {
                    // Create new income record
                    struct IncomeInsert: Encodable {
                        let shift_id: UUID
                        let user_id: UUID
                        let actual_hours: Double
                        let sales: Double
                        let tips: Double
                        let cash_out: Double
                        let other: Double
                        let actual_start_time: String
                        let actual_end_time: String
                        let notes: String?
                    }

                    let incomeData = IncomeInsert(
                        shift_id: shiftId,
                        user_id: userId,
                        actual_hours: state.calculatedHours,
                        sales: Double(state.sales) ?? 0,
                        tips: Double(state.tips) ?? 0,
                        cash_out: Double(state.tipOut) ?? 0,
                        other: Double(state.other) ?? 0,
                        actual_start_time: startTimeStr,
                        actual_end_time: endTimeStr,
                        notes: state.comments.isEmpty ? nil : state.comments
                    )

                    try await supabaseManager.client
                        .from("shift_income")
                        .insert(incomeData)
                        .execute()
                }
                } // End of if !state.didntWork

                // Update shift record with actual times and lunch break
                let shiftUpdate = ShiftUpdate(
                    start_time: startTimeStr,
                    end_time: endTimeStr,
                    lunch_break_minutes: AddEntryConstants.lunchBreakMinutes(from: state.selectedLunchBreak),
                    expected_hours: state.calculatedHours, // Use actual hours as expected for completed shifts
                    status: state.didntWork ? "missed" : "completed",
                    employer_id: state.selectedEmployer?.id,
                    hourly_rate: state.selectedEmployer?.hourly_rate ?? defaultHourlyRate,
                    notes: state.didntWork ? state.missedReason : (state.comments.isEmpty ? nil : state.comments)
                )

                try await supabaseManager.client
                    .from("shifts")
                    .update(shiftUpdate)
                    .eq("id", value: shiftId)
                    .execute()

                // Increment entry count for part-time tier (only for new entries)
                if subscriptionManager.currentTier == .partTime && editingShift == nil {
                    subscriptionManager.incrementEntryCount()
                }

                await MainActor.run {
                    dismiss()
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = error.localizedDescription
                    state.showErrorAlert = true
                    HapticFeedback.error()
                }
            }
        }
    }

    // MARK: - Delete Entry
    private func deleteEntry() {
        guard let shiftToDelete = editingShift else { return }

        state.isLoading = true

        Task {
            do {
                let userId = try await supabaseManager.client.auth.session.user.id

                // Delete from shift_income if it exists
                if let incomeId = shiftToDelete.income_id {
                    try await supabaseManager.client
                        .from("shift_income")
                        .delete()
                        .eq("id", value: incomeId.uuidString)
                        .eq("user_id", value: userId.uuidString)
                        .execute()
                }

                // Delete from shifts table
                if let shiftId = shiftToDelete.shift_id {
                    try await supabaseManager.client
                        .from("shifts")
                        .delete()
                        .eq("id", value: shiftId.uuidString)
                        .eq("user_id", value: userId.uuidString)
                        .execute()
                }

                await MainActor.run {
                    dismiss()
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = "Failed to delete entry: \(error.localizedDescription)"
                    state.showErrorAlert = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

