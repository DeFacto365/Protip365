import SwiftUI

// MARK: - AddShift Data Manager
@MainActor
class AddShiftDataManager: ObservableObject {
    @Published var selectedDate = Date() {
        didSet {
            // Re-validate end time when date changes
            validateEndTime()
        }
    }
    @Published var selectedEmployer: Employer?
    @Published var startTime = Date() {
        didSet {
            // Ensure end time is at least equal to or after start time
            validateEndTime()
        }
    }
    @Published var endTime = Date()
    @Published var selectedLunchBreak = "None"
    @Published var selectedAlert = "60 minutes"
    @Published var comments = ""
    @Published var employers: [Employer] = []
    @Published var isLoading = false
    @Published var isInitializing = true
    @Published var errorMessage = ""
    @Published var showErrorAlert = false
    @Published var defaultAlertMinutes: Int = 60
    @AppStorage("language") private var language = "en"

    private let editingShift: ShiftIncome?
    private let initialDate: Date?
    private var localization: AddShiftLocalization {
        AddShiftLocalization(language: language)
    }

    init(editingShift: ShiftIncome? = nil, initialDate: Date? = nil) {
        self.editingShift = editingShift
        self.initialDate = initialDate
    }

    // MARK: - Computed Properties
    var lunchBreakMinutes: Int {
        switch selectedLunchBreak {
        case "15 min": return 15
        case "30 min": return 30
        case "45 min": return 45
        case "60 min": return 60
        default: return 0
        }
    }

    var alertMinutes: Int? {
        switch selectedAlert {
        case "15 minutes": return 15
        case "30 minutes": return 30
        case "60 minutes": return 60
        case "1 day before": return 1440
        case "None": return nil
        default: return nil
        }
    }

    var expectedHours: Double {
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

        return max(0, Double(totalMinutes) / 60.0) // Ensure non-negative
    }

    // MARK: - Validation
    private func validateEndTime() {
        let calendar = Calendar.current

        // Create full date-time objects for proper comparison
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        // Use the selected date as the base for both start and end times
        var startDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        var endDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        startDateComponents.hour = startComponents.hour
        startDateComponents.minute = startComponents.minute
        endDateComponents.hour = endComponents.hour
        endDateComponents.minute = endComponents.minute

        guard let startDateTime = calendar.date(from: startDateComponents),
              let endDateTime = calendar.date(from: endDateComponents) else {
            return
        }

        // If end time is before or equal to start time, adjust it
        if endDateTime <= startDateTime {
            // Set end time to start time + 8 hours (typical shift duration)
            if let newEndTime = calendar.date(byAdding: .hour, value: 8, to: startTime) {
                endTime = newEndTime
                print("🔄 Adjusted end time to: \(newEndTime)")
            } else {
                // Fallback: set to start time + 1 hour
                if let fallbackEndTime = calendar.date(byAdding: .hour, value: 1, to: startTime) {
                    endTime = fallbackEndTime
                    print("🔄 Fallback end time to: \(fallbackEndTime)")
                }
            }
        }
    }

    // MARK: - Initialization Functions
    func initializeView() async {
        // First load employers
        await loadEmployers()

        // Load user's default alert preference
        await loadUserDefaults()

        // Then setup default times (which may depend on employers being loaded)
        await setupDefaultTimes()

        // Finally, mark initialization as complete
        isInitializing = false
    }

    private func loadUserDefaults() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            struct ProfileDefaults: Decodable {
                let default_alert_minutes: Int?
            }

            let profiles: [ProfileDefaults] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("default_alert_minutes")
                .eq("user_id", value: userId)
                .execute()
                .value

            if let profile = profiles.first, let defaultMinutes = profile.default_alert_minutes {
                defaultAlertMinutes = defaultMinutes
                // Set the selected alert based on default
                switch defaultMinutes {
                case 15: selectedAlert = "15 minutes"
                case 30: selectedAlert = "30 minutes"
                case 60: selectedAlert = "60 minutes"
                case 1440: selectedAlert = "1 day before"
                default: selectedAlert = "60 minutes"
                }
            }
        } catch {
            print("Error loading user defaults: \(error)")
            // Default to 60 minutes if error
            selectedAlert = "60 minutes"
        }
    }

    private func loadEmployers() async {
        do {
            let fetchedEmployers = try await SupabaseManager.shared.fetchEmployers()

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
        } catch {
            print("Error loading employers: \(error)")
            // Even on error, mark as not initializing to show the UI
            isInitializing = false
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

            selectedDate = shiftDate

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
                        startTime = combinedDate
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
                        endTime = combinedDate
                    }
                }
            }

            // Set lunch break
            if let lunchMinutes = shift.lunch_break_minutes {
                switch lunchMinutes {
                case 15: selectedLunchBreak = "15 min"
                case 30: selectedLunchBreak = "30 min"
                case 45: selectedLunchBreak = "45 min"
                case 60: selectedLunchBreak = "60 min"
                default: selectedLunchBreak = "None"
                }
            }

            // Set employer - now employers should be loaded
            if let employerId = shift.employer_id {
                selectedEmployer = employers.first { $0.id == employerId }
                print("📝 Selected employer: \(selectedEmployer?.name ?? "not found")")
            }

            // Load notes separately from shifts table since they're not in ShiftIncome view
            if let shiftId = shift.shift_id {
                await loadNotesForShift(shiftId: shiftId)
            }
        } else {
            // Default times for new shift
            // Use initialDate if provided, otherwise use today
            let baseDate = initialDate ?? now
            selectedDate = baseDate

            // Set start time to 8:00 AM on the selected date
            var startComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            startComponents.hour = 8
            startComponents.minute = 0
            startTime = calendar.date(from: startComponents) ?? baseDate

            // Set end time to 8 hours after start time (typical shift duration)
            // This will be 4:00 PM if start is 8:00 AM
            if let defaultEndTime = calendar.date(byAdding: .hour, value: 8, to: startTime) {
                endTime = defaultEndTime
            } else {
                // Fallback to 5:00 PM
                var endComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
                endComponents.hour = 16
                endComponents.minute = 0
                endTime = calendar.date(from: endComponents) ?? baseDate
            }
        }
    }

    private func loadNotesForShift(shiftId: UUID) async {
        do {
            print("📝 Loading notes and alert for shift ID: \(shiftId)")

            // Create a simple struct for notes and alert
            struct ShiftDetails: Decodable {
                let notes: String?
                let alert_minutes: Int?
            }

            let result: ShiftDetails = try await SupabaseManager.shared.client
                .from("shifts")
                .select("notes, alert_minutes")
                .eq("id", value: shiftId)
                .single()
                .execute()
                .value

            if let notes = result.notes {
                comments = notes
                print("📝 Loaded notes: \(notes)")
            } else {
                print("📝 No notes found for shift")
            }

            // Set alert minutes if exists, otherwise keep default
            if let alertMins = result.alert_minutes {
                switch alertMins {
                case 15: selectedAlert = "15 minutes"
                case 30: selectedAlert = "30 minutes"
                case 60: selectedAlert = "60 minutes"
                case 1440: selectedAlert = "1 day before"
                default: selectedAlert = "None"
                }
                print("📝 Loaded alert: \(selectedAlert)")
            }
        } catch {
            print("Error loading shift details: \(error)")
        }
    }

    // MARK: - Overlap Detection
    func checkForOverlappingShifts() async -> Bool {
        do {
            // Get current user ID
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id

            // Format date for database query
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let shiftDateString = dateFormatter.string(from: selectedDate)

            // Format times for comparison
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let newStartTime = timeFormatter.string(from: startTime)
            let newEndTime = timeFormatter.string(from: endTime)

            print("🔍 Checking for overlapping shifts on \(shiftDateString)")
            print("🔍 New shift time: \(newStartTime) - \(newEndTime)")

            // Fetch all shifts for the same date
            let existingShifts: [Shift] = try await SupabaseManager.shared.client
                .from("shifts")
                .select()
                .eq("user_id", value: userId)
                .eq("shift_date", value: shiftDateString)
                .execute()
                .value

            // Check each existing shift for overlap
            for shift in existingShifts {
                // Skip if this is the same shift being edited
                if let editingShift = editingShift,
                   shift.id == editingShift.shift_id {
                    continue
                }

                guard let existingStartTime = shift.start_time,
                      let existingEndTime = shift.end_time else {
                    continue
                }

                print("🔍 Existing shift: \(existingStartTime) - \(existingEndTime)")

                // Convert times to minutes for easier comparison
                let newStart = timeToMinutes(newStartTime)
                let newEnd = timeToMinutes(newEndTime)
                let existingStart = timeToMinutes(existingStartTime)
                let existingEnd = timeToMinutes(existingEndTime)

                // Check for overlap
                // Shifts overlap if:
                // 1. New shift starts during existing shift
                // 2. New shift ends during existing shift
                // 3. New shift completely contains existing shift
                // 4. Existing shift completely contains new shift

                let hasOverlap = (newStart >= existingStart && newStart < existingEnd) ||
                                (newEnd > existingStart && newEnd <= existingEnd) ||
                                (newStart <= existingStart && newEnd >= existingEnd) ||
                                (existingStart <= newStart && existingEnd >= newEnd)

                if hasOverlap {
                    print("❌ Overlap detected with shift: \(existingStartTime) - \(existingEndTime)")

                    // Get employer name for better error message
                    var employerName = "another employer"
                    if let employerId = shift.employer_id {
                        let employers = try await SupabaseManager.shared.fetchEmployers()
                        if let employer = employers.first(where: { $0.id == employerId }) {
                            employerName = employer.name
                        }
                    }

                    errorMessage = localization.overlapErrorMessage(employerName: employerName, startTime: existingStartTime, endTime: existingEndTime)
                    showErrorAlert = true
                    return true // Overlap found
                }
            }

            print("✅ No overlapping shifts found")
            return false // No overlap

        } catch {
            print("❌ Error checking for overlapping shifts: \(error)")
            // On error, allow the save to proceed
            return false
        }
    }

    private func timeToMinutes(_ timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        guard components.count >= 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else {
            return 0
        }
        return hours * 60 + minutes
    }

    // MARK: - Save Function
    func saveShift(subscriptionManager: SubscriptionManager) async -> Bool {
        guard let employer = selectedEmployer else {
            print("❌ No employer selected")
            errorMessage = localization.selectEmployerError
            showErrorAlert = true
            return false
        }

        // Check for overlapping shifts before saving
        let hasOverlap = await checkForOverlappingShifts()
        if hasOverlap {
            print("❌ Cannot save shift due to overlap")
            return false
        }

        // Check subscription limits for part-time tier
        if subscriptionManager.currentTier == .partTime && editingShift == nil {
            // Only check for new shifts, not edits
            if !subscriptionManager.canAddShift() {
                print("❌ Part-time shift limit reached")
                if let remaining = subscriptionManager.getRemainingShifts() {
                    errorMessage = "You've reached your weekly limit of 3 shifts. \(remaining) shifts remaining this week."
                } else {
                    errorMessage = "You've reached your weekly shift limit."
                }
                showErrorAlert = true
                return false
            }
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

                // Determine status based on actual shift start date/time
                let calendar = Calendar.current

                // Combine shift date with start time for accurate comparison
                let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                var shiftDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                shiftDateComponents.hour = startComponents.hour
                shiftDateComponents.minute = startComponents.minute

                let shiftStartDateTime = calendar.date(from: shiftDateComponents) ?? selectedDate
                let now = Date()

                // If shift starts in the future, it should be "planned"
                let shiftStatus = shiftStartDateTime > now ? "planned" : (existingShift.shift_status ?? "completed")

                let updatedShift = Shift(
                    id: shiftId,  // Use the shift_id from the ShiftIncome model
                    user_id: userId,
                    employer_id: employer.id,
                    shift_date: dateFormatter.string(from: selectedDate),
                    expected_hours: expectedHours,
                    hours: expectedHours,
                    lunch_break_minutes: lunchBreakMinutes,
                    hourly_rate: employer.hourly_rate,
                    sales: existingShift.sales ?? 0, // Keep existing sales
                    tips: existingShift.tips ?? 0, // Keep existing tips
                    cash_out: existingShift.cash_out, // Keep existing cash_out
                    other: existingShift.other, // Keep existing other
                    notes: comments.isEmpty ? nil : comments,
                    start_time: timeFormatter.string(from: startTime),
                    end_time: timeFormatter.string(from: endTime),
                    status: shiftStatus,
                    alert_minutes: alertMinutes,
                    created_at: nil
                )

                print("📦 Updating shift with ID: \(shiftId)")
                print("📦 Shift details: \(updatedShift)")

                // Update in Supabase
                try await SupabaseManager.shared.updateShift(updatedShift)
                print("✅ Shift updated successfully!")

                // Update notification if alert is set
                if let alertMins = alertMinutes {
                    try await NotificationManager.shared.updateShiftAlert(
                        shiftId: shiftId,
                        shiftDate: selectedDate,
                        startTime: startTime,
                        employerName: employer.name,
                        alertMinutes: alertMins
                    )
                } else {
                    // Cancel notification if alert was removed
                    NotificationManager.shared.cancelShiftAlert(shiftId: shiftId)
                }
            } else {
                // Create new shift
                // Determine status based on actual shift start date/time
                let calendar = Calendar.current

                // Combine shift date with start time for accurate comparison
                let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                var shiftDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                shiftDateComponents.hour = startComponents.hour
                shiftDateComponents.minute = startComponents.minute

                let shiftStartDateTime = calendar.date(from: shiftDateComponents) ?? selectedDate
                let now = Date()

                // If shift starts in the future, it should be "planned"
                let shiftStatus = shiftStartDateTime > now ? "planned" : "completed"

                let newShift = Shift(
                    id: UUID(),
                    user_id: userId,
                    employer_id: employer.id,
                    shift_date: dateFormatter.string(from: selectedDate),
                    expected_hours: expectedHours,
                    hours: expectedHours,
                    lunch_break_minutes: lunchBreakMinutes,
                    hourly_rate: employer.hourly_rate,
                    sales: 0, // Default to 0 for planned shifts
                    tips: 0,
                    cash_out: 0,
                    other: 0,
                    notes: comments.isEmpty ? nil : comments,
                    start_time: timeFormatter.string(from: startTime),
                    end_time: timeFormatter.string(from: endTime),
                    status: shiftStatus,
                    alert_minutes: alertMinutes,
                    created_at: Date()
                )

                print("📦 Created shift object: \(newShift)")

                // Save to Supabase
                let savedShift = try await SupabaseManager.shared.saveShift(newShift)
                print("✅ Shift saved successfully!")

                // Schedule notification if alert is set
                if let alertMins = alertMinutes, let shiftId = savedShift.id {
                    try await NotificationManager.shared.scheduleShiftAlert(
                        shiftId: shiftId,
                        shiftDate: selectedDate,
                        startTime: startTime,
                        employerName: employer.name,
                        alertMinutes: alertMins
                    )
                }

                // Increment shift count for part-time tier
                if subscriptionManager.currentTier == .partTime {
                    subscriptionManager.incrementShiftCount()
                }
            }

            isLoading = false
            return true
        } catch {
            print("❌ Error saving shift: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            isLoading = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
            return false
        }
    }
}