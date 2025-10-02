import SwiftUI
import Supabase
import UIKit

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    // MARK: - Parameters
    let editingShift: ShiftWithEntry?
    let initialDate: Date?
    let preselectedShift: ShiftWithEntry?

    // MARK: - State
    @State private var state = AddEntryState()
    @State private var employers: [Employer] = []
    @State private var showDeleteConfirmation = false
    @State private var preselectedShiftId: UUID? = nil

    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 15.00
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false
    @AppStorage("language") private var language = "en"
    
    // MARK: - Computed Properties
    private var localizedStrings: AddEntryLocalizedStrings {
        AddEntryLocalizedStrings(language: language)
    }
    
    // MARK: - Initializer
    init(editingShift: ShiftWithEntry? = nil, initialDate: Date? = nil, preselectedShift: ShiftWithEntry? = nil) {
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
            totalEarnings: computeTotalEarnings(),
            defaultHourlyRate: defaultHourlyRate,
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
        let tipsAmount = state.tips.toLocaleDouble() ?? 0
        let tipOutAmount = state.tipOut.toLocaleDouble() ?? 0
        let otherAmount = state.other.toLocaleDouble() ?? 0
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
    
    private func populateFieldsForEditing(shift: ShiftWithEntry) {
        // Set the date
        state.selectedDate = dateStringToDate(shift.shift_date) ?? Date()
        state.selectedEndDate = state.selectedDate  // Default to same date initially

        // Parse times - Use ACTUAL times if available (from shift_entry), otherwise use expected times
        let startTimeToUse = shift.entry?.actual_start_time ?? shift.expected_shift.start_time
        let endTimeToUse = shift.entry?.actual_end_time ?? shift.expected_shift.end_time

        let startTimeStr = startTimeToUse
        let endTimeStr = endTimeToUse
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

        // Set the values from the entry (if it exists)
        if let entry = shift.entry {
            state.sales = entry.sales > 0 ? String(format: "%.2f", entry.sales) : ""
            state.tips = entry.tips > 0 ? String(format: "%.2f", entry.tips) : ""
            state.tipOut = entry.cash_out > 0 ? String(format: "%.2f", entry.cash_out) : ""
            state.other = entry.other > 0 ? String(format: "%.2f", entry.other) : ""
            state.comments = entry.notes ?? ""
        }

        // Set lunch break from expected shift data
        state.selectedLunchBreak = AddEntryConstants.lunchBreakSelection(from: shift.lunch_break_minutes)

        // Find employer - this will be set after employers are loaded
        if let employerId = shift.employer_id {
            state.selectedEmployer = employers.first { $0.id == employerId }
        }
    }

    private func populateFieldsForPreselectedShift(shift: ShiftWithEntry) {
        // Similar to populateFieldsForEditing but for new entries with preselected shift
        // Store the shift ID so we can update its status later
        preselectedShiftId = shift.id

        // Set the date
        state.selectedDate = dateStringToDate(shift.shift_date) ?? Date()
        state.selectedEndDate = state.selectedDate

        // Set shift info from expected shift - use expected times for preselected shift
        let startTimeStr = shift.expected_shift.start_time
        let endTimeStr = shift.expected_shift.end_time
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

        // Set lunch break from expected shift
        state.selectedLunchBreak = AddEntryConstants.lunchBreakSelection(from: shift.lunch_break_minutes)

        // Find employer - this will be set after employers are loaded
        if let employerId = shift.employer_id {
            state.selectedEmployer = employers.first { $0.id == employerId }
        }

        // For preselected shift, we're adding entry data to an existing shift
        // Leave financial fields empty for user to fill
    }

    
    private func dateStringToDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func saveEntry() {
        // Check subscription status (only for new entries)
        if !subscriptionManager.hasFullAccess() && editingShift == nil {
            state.errorMessage = "Please subscribe to ProTip365 Premium to add entries."
            state.showErrorAlert = true
            return
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

                let shiftId: UUID

                // If we're editing an existing shift
                if let editingShift = editingShift {
                    shiftId = editingShift.id

                    // Update the expected shift if date changed
                    let updatedExpectedShift = ExpectedShift(
                        id: editingShift.id,
                        user_id: userId,
                        employer_id: state.selectedEmployer?.id,
                        shift_date: shiftDate,
                        start_time: editingShift.expected_shift.start_time, // Keep original expected times
                        end_time: editingShift.expected_shift.end_time,
                        expected_hours: editingShift.expected_hours, // Keep original expected hours
                        hourly_rate: state.selectedEmployer?.hourly_rate ?? defaultHourlyRate,
                        lunch_break_minutes: AddEntryConstants.lunchBreakMinutes(from: state.selectedLunchBreak),
                        sales_target: editingShift.expected_shift.sales_target, // Preserve existing target
                        status: state.didntWork ? "missed" : "completed",
                        alert_minutes: editingShift.expected_shift.alert_minutes,
                        notes: state.didntWork ? state.missedReason : editingShift.expected_shift.notes,
                        created_at: editingShift.expected_shift.created_at,
                        updated_at: Date()
                    )

                    _ = try await SupabaseManager.shared.updateExpectedShift(updatedExpectedShift)

                } else if let preselectedId = preselectedShiftId {
                    // We're adding entry data to a preselected shift
                    shiftId = preselectedId

                    // Update the expected shift status to completed
                    if let preselectedShift = try await SupabaseManager.shared.fetchExpectedShifts(
                        from: state.selectedDate,
                        to: state.selectedDate
                    ).first(where: { $0.id == preselectedId }) {

                        let updatedShift = ExpectedShift(
                            id: preselectedShift.id,
                            user_id: preselectedShift.user_id,
                            employer_id: preselectedShift.employer_id,
                            shift_date: preselectedShift.shift_date,
                            start_time: preselectedShift.start_time,
                            end_time: preselectedShift.end_time,
                            expected_hours: preselectedShift.expected_hours,
                            hourly_rate: preselectedShift.hourly_rate,
                            lunch_break_minutes: preselectedShift.lunch_break_minutes,
                            sales_target: preselectedShift.sales_target, // Preserve target
                            status: "completed",
                            alert_minutes: preselectedShift.alert_minutes,
                            notes: preselectedShift.notes,
                            created_at: preselectedShift.created_at,
                            updated_at: Date()
                        )

                        _ = try await SupabaseManager.shared.updateExpectedShift(updatedShift)
                    }

                } else {
                    // Create new expected shift for this entry
                    let newExpectedShift = ExpectedShift(
                        id: UUID(),
                        user_id: userId,
                        employer_id: state.selectedEmployer?.id,
                        shift_date: shiftDate,
                        start_time: startTimeStr, // Use actual times as expected for ad-hoc entries
                        end_time: endTimeStr,
                        expected_hours: state.calculatedHours,
                        hourly_rate: state.selectedEmployer?.hourly_rate ?? defaultHourlyRate,
                        lunch_break_minutes: AddEntryConstants.lunchBreakMinutes(from: state.selectedLunchBreak),
                        sales_target: nil, // No custom target for ad-hoc entries
                        status: state.didntWork ? "missed" : "completed",
                        alert_minutes: nil,
                        notes: state.didntWork ? state.missedReason : nil,
                        created_at: Date(),
                        updated_at: Date()
                    )

                    let createdShift = try await SupabaseManager.shared.createExpectedShift(newExpectedShift)
                    shiftId = createdShift.id
                }

                // Handle shift entry (actual work data) - only if worked
                if !state.didntWork {
                    // Calculate snapshot values
                    let hourlyRate = state.selectedEmployer?.hourly_rate ?? defaultHourlyRate
                    let grossIncome = state.calculatedHours * hourlyRate
                    let tipsAmount = state.tips.toLocaleDouble() ?? 0
                    let tipOutAmount = state.tipOut.toLocaleDouble() ?? 0
                    let otherAmount = state.other.toLocaleDouble() ?? 0
                    let totalIncome = grossIncome + tipsAmount + otherAmount - tipOutAmount

                    // Get deduction percentage from AppStorage
                    let deductionPct = UserDefaults.standard.double(forKey: "averageDeductionPercentage")
                    let finalDeductionPct = deductionPct > 0 ? deductionPct : 30.0 // Default to 30% if not set
                    let netIncome = totalIncome * (1.0 - finalDeductionPct / 100.0)

                    if let existingEntry = editingShift?.entry {
                        // Update existing entry
                        let updatedEntry = ShiftEntry(
                            id: existingEntry.id,
                            shift_id: shiftId,
                            user_id: userId,
                            actual_start_time: startTimeStr,
                            actual_end_time: endTimeStr,
                            actual_hours: state.calculatedHours,
                            sales: state.sales.toLocaleDouble() ?? 0,
                            tips: tipsAmount,
                            cash_out: tipOutAmount,
                            other: otherAmount,
                            hourly_rate: hourlyRate,
                            gross_income: grossIncome,
                            total_income: totalIncome,
                            net_income: netIncome,
                            deduction_percentage: finalDeductionPct,
                            notes: state.comments.isEmpty ? nil : state.comments,
                            created_at: existingEntry.created_at,
                            updated_at: Date()
                        )

                        _ = try await SupabaseManager.shared.updateShiftEntry(updatedEntry)

                        // Invalidate dashboard cache when entry is updated
                        DashboardCharts.invalidateCache()

                    } else {
                        // Create new entry
                        let newEntry = ShiftEntry(
                            id: UUID(),
                            shift_id: shiftId,
                            user_id: userId,
                            actual_start_time: startTimeStr,
                            actual_end_time: endTimeStr,
                            actual_hours: state.calculatedHours,
                            sales: state.sales.toLocaleDouble() ?? 0,
                            tips: tipsAmount,
                            cash_out: tipOutAmount,
                            other: otherAmount,
                            hourly_rate: hourlyRate,
                            gross_income: grossIncome,
                            total_income: totalIncome,
                            net_income: netIncome,
                            deduction_percentage: finalDeductionPct,
                            notes: state.comments.isEmpty ? nil : state.comments,
                            created_at: Date(),
                            updated_at: Date()
                        )

                        _ = try await SupabaseManager.shared.createShiftEntry(newEntry)

                        // Invalidate dashboard cache when new entry is added
                        DashboardCharts.invalidateCache()
                    }
                }

                // Entry saved successfully

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
                // Delete shift entry if it exists
                if let entry = shiftToDelete.entry {
                    try await SupabaseManager.shared.deleteShiftEntry(id: entry.id)

                    // Invalidate dashboard cache when entry is deleted
                    DashboardCharts.invalidateCache()
                }

                // Delete expected shift
                try await SupabaseManager.shared.deleteExpectedShift(id: shiftToDelete.id)

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

