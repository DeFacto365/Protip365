import SwiftUI

// MARK: - AddShift Data Manager
@MainActor
class AddShiftDataManager: ObservableObject {
    @Published var selectedDate = Date() {
        didSet {
            // When start date changes, default end date to same day
            // (user can still manually change it for overnight shifts)
            let calendar = Calendar.current
            if !calendar.isDate(selectedDate, inSameDayAs: endDate) {
                endDate = selectedDate
            }
            // Re-validate end time when date changes
            validateEndTime()
        }
    }
    @Published var endDate = Date() {
        didSet {
            // Re-validate end time when end date changes
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
    @Published var salesTarget: String = "" // Custom sales target (empty means use default)
    @Published var employers: [Employer] = []
    @Published var isLoading = false
    @Published var isInitializing = true
    @Published var errorMessage = ""
    @Published var showErrorAlert = false
    @Published var defaultAlertMinutes: Int = 60
    @AppStorage("language") private var language = "en"
    @AppStorage("dailySales") var defaultDailySalesTarget: Double = 0

    private let editingShift: ShiftWithEntry?
    private let initialDate: Date?
    private var localization: AddShiftLocalization {
        AddShiftLocalization(language: language)
    }

    init(editingShift: ShiftWithEntry? = nil, initialDate: Date? = nil) {
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

        // Create full date-time objects using separate start and end dates
        let startDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let endDateComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        var fullStartComponents = startDateComponents
        fullStartComponents.hour = startTimeComponents.hour
        fullStartComponents.minute = startTimeComponents.minute

        var fullEndComponents = endDateComponents
        fullEndComponents.hour = endTimeComponents.hour
        fullEndComponents.minute = endTimeComponents.minute

        guard let startDateTime = calendar.date(from: fullStartComponents),
              let endDateTime = calendar.date(from: fullEndComponents) else {
            return 0
        }

        // Calculate time difference in minutes
        let timeInterval = endDateTime.timeIntervalSince(startDateTime)
        var totalMinutes = Int(timeInterval / 60)

        // Ensure positive duration (handle edge cases)
        if totalMinutes < 0 {
            totalMinutes += 24 * 60 // Add 24 hours if there's an issue
        }

        // Subtract lunch break
        totalMinutes -= lunchBreakMinutes

        return max(0, Double(totalMinutes) / 60.0) // Ensure non-negative
    }

    // MARK: - Validation
    private func validateEndTime() {
        let calendar = Calendar.current

        // Create full date-time objects using separate start and end dates
        let startDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let endDateComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        var fullStartComponents = startDateComponents
        fullStartComponents.hour = startTimeComponents.hour
        fullStartComponents.minute = startTimeComponents.minute

        var fullEndComponents = endDateComponents
        fullEndComponents.hour = endTimeComponents.hour
        fullEndComponents.minute = endTimeComponents.minute

        guard let startDateTime = calendar.date(from: fullStartComponents),
              let endDateTime = calendar.date(from: fullEndComponents) else {
            return
        }

        // Allow cross-day shifts - only validate if end is significantly in the past
        let timeDifference = endDateTime.timeIntervalSince(startDateTime)

        // If end time is more than 1 hour before start time, adjust it
        if timeDifference < -3600 { // Less than -1 hour
            // For overnight shifts, set end date to next day and adjust time
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                endDate = nextDay
                print("🔄 Adjusted end date to next day for overnight shift")
            }
        } else if timeDifference <= 0 && calendar.isDate(selectedDate, inSameDayAs: endDate) {
            // Same day but end time is before or equal to start time
            // Set end time to start time + 8 hours (typical shift duration)
            if let newEndTime = calendar.date(byAdding: .hour, value: 8, to: startTime) {
                endTime = newEndTime
                print("🔄 Adjusted end time to: \(newEndTime)")
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
                let target_sales_daily: Double?
            }

            let profiles: [ProfileDefaults] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("default_alert_minutes, target_sales_daily")
                .eq("user_id", value: userId)
                .execute()
                .value

            if let profile = profiles.first {
                // Load alert default
                if let defaultMinutes = profile.default_alert_minutes {
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

                // Load sales target default
                if let dailySalesTarget = profile.target_sales_daily {
                    defaultDailySalesTarget = dailySalesTarget
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
            print("📝 Setting up edit mode for shift ID: \(shift.id)")
            print("📝 Shift date: \(shift.expected_shift.shift_date)")
            print("📝 Employer ID: \(shift.expected_shift.employer_id?.uuidString ?? "none")")
            print("📝 Start time: \(shift.expected_shift.start_time)")
            print("📝 End time: \(shift.expected_shift.end_time)")

            // Parse shift date first
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let shiftDate = dateFormatter.date(from: shift.expected_shift.shift_date) ?? Date()

            selectedDate = shiftDate
            endDate = shiftDate // Initialize end date same as start date

            // Parse start and end times
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            // Also try HH:mm format if HH:mm:ss fails
            let timeFormatterShort = DateFormatter()
            timeFormatterShort.dateFormat = "HH:mm"

            var startTimeHour: Int = 8
            var startTimeMinute: Int = 0
            var endTimeHour: Int = 16
            var endTimeMinute: Int = 0

            let startTimeString = shift.expected_shift.start_time
            var startDateParsed = timeFormatter.date(from: startTimeString)
            if startDateParsed == nil {
                startDateParsed = timeFormatterShort.date(from: startTimeString)
            }

            if let startDateParsed = startDateParsed {
                // Combine with selected date
                let startComponents = calendar.dateComponents([.hour, .minute], from: startDateParsed)
                startTimeHour = startComponents.hour ?? 8
                startTimeMinute = startComponents.minute ?? 0

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: shiftDate)
                dateComponents.hour = startTimeHour
                dateComponents.minute = startTimeMinute
                if let combinedDate = calendar.date(from: dateComponents) {
                    startTime = combinedDate
                }
            }

            let endTimeString = shift.expected_shift.end_time
            var endDateParsed = timeFormatter.date(from: endTimeString)
            if endDateParsed == nil {
                endDateParsed = timeFormatterShort.date(from: endTimeString)
            }

            if let endDateParsed = endDateParsed {
                let endComponents = calendar.dateComponents([.hour, .minute], from: endDateParsed)
                endTimeHour = endComponents.hour ?? 16
                endTimeMinute = endComponents.minute ?? 0

                // Check if this is likely a cross-day shift (end time is before start time)
                let endTimeInMinutes = endTimeHour * 60 + endTimeMinute
                let startTimeInMinutes = startTimeHour * 60 + startTimeMinute

                if endTimeInMinutes < startTimeInMinutes {
                    // This is likely a cross-day shift, set end date to next day
                    endDate = calendar.date(byAdding: .day, value: 1, to: shiftDate) ?? shiftDate
                    print("🌙 Detected cross-day shift: start \(startTimeHour):\(startTimeMinute), end \(endTimeHour):\(endTimeMinute)")
                }

                // Combine with end date
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
                dateComponents.hour = endTimeHour
                dateComponents.minute = endTimeMinute
                if let combinedDate = calendar.date(from: dateComponents) {
                    endTime = combinedDate
                }
            }

            // Set lunch break
            let lunchMinutes = shift.expected_shift.lunch_break_minutes
            switch lunchMinutes {
            case 15: selectedLunchBreak = "15 min"
            case 30: selectedLunchBreak = "30 min"
            case 45: selectedLunchBreak = "45 min"
            case 60: selectedLunchBreak = "60 min"
            default: selectedLunchBreak = "None"
            }

            // Set employer - now employers should be loaded
            if let employerId = shift.expected_shift.employer_id {
                selectedEmployer = employers.first { $0.id == employerId }
                print("📝 Selected employer: \(selectedEmployer?.name ?? "not found")")
            }

            // Set notes and alert from expected shift
            comments = shift.expected_shift.notes ?? ""

            // Set alert preference
            if let alertMins = shift.expected_shift.alert_minutes {
                switch alertMins {
                case 15: selectedAlert = "15 minutes"
                case 30: selectedAlert = "30 minutes"
                case 60: selectedAlert = "60 minutes"
                case 1440: selectedAlert = "1 day before"
                default: selectedAlert = "60 minutes"
                }
            }

            // Set sales target (custom or empty for default)
            if let target = shift.expected_shift.sales_target {
                salesTarget = String(format: "%.0f", target)
            } else {
                salesTarget = "" // Empty means use default
            }
        } else {
            // Default times for new shift
            // Use initialDate if provided, otherwise use today
            let baseDate = initialDate ?? now
            selectedDate = baseDate
            endDate = baseDate // Default to same day for new shifts

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

            // Fetch all expected shifts for the same date
            let existingShifts: [ExpectedShift] = try await SupabaseManager.shared.client
                .from("expected_shifts")
                .select()
                .eq("user_id", value: userId)
                .eq("shift_date", value: shiftDateString)
                .execute()
                .value

            // Check each existing shift for overlap
            for shift in existingShifts {
                // Skip if this is the same shift being edited
                if let editingShift = editingShift,
                   shift.id == editingShift.id {
                    continue
                }

                let existingStartTime = shift.start_time
                let existingEndTime = shift.end_time

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

        // Check subscription status
        if !subscriptionManager.hasFullAccess() && editingShift == nil {
            print("❌ Premium subscription required")
            errorMessage = "Please subscribe to ProTip365 Premium to add shifts."
            showErrorAlert = true
            return false
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
            timeFormatter.dateFormat = "HH:mm:ss"  // Database expects HH:mm:ss format

            if let existingShift = editingShift {
                // Update existing expected shift - PRESERVE EXISTING STATUS
                // Don't auto-change status when editing, only user can change it

                // Parse sales target (empty string means use default)
                let customSalesTarget = salesTarget.isEmpty ? nil : Double(salesTarget)

                let updatedShift = ExpectedShift(
                    id: existingShift.id,
                    user_id: userId,
                    employer_id: employer.id,
                    shift_date: dateFormatter.string(from: selectedDate),
                    start_time: timeFormatter.string(from: startTime),
                    end_time: timeFormatter.string(from: endTime),
                    expected_hours: expectedHours,
                    hourly_rate: employer.hourly_rate,
                    lunch_break_minutes: lunchBreakMinutes,
                    sales_target: customSalesTarget,
                    status: existingShift.expected_shift.status, // Preserve existing status
                    alert_minutes: alertMinutes,
                    notes: comments.isEmpty ? nil : comments,
                    created_at: existingShift.expected_shift.created_at,
                    updated_at: Date()
                )

                print("📦 Updating expected shift with ID: \(existingShift.id)")
                _ = try await SupabaseManager.shared.updateExpectedShift(updatedShift)
                print("✅ Expected shift updated successfully!")

                // Update notification if alert is set
                if let alertMins = alertMinutes {
                    try await NotificationManager.shared.updateShiftAlert(
                        shiftId: existingShift.id,
                        shiftDate: selectedDate,
                        startTime: startTime,
                        employerName: employer.name,
                        alertMinutes: alertMins
                    )
                } else {
                    // Cancel notification if alert was removed
                    NotificationManager.shared.cancelShiftAlert(shiftId: existingShift.id)
                }
            } else {
                // Create new expected shift - determine status based on shift DATE only (not time)
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let shiftDate = calendar.startOfDay(for: selectedDate)

                // Compare dates only: today or future = "planned", past = "completed"
                let shiftStatus = shiftDate >= today ? "planned" : "completed"

                // Parse sales target (empty string means use default)
                let customSalesTarget = salesTarget.isEmpty ? nil : Double(salesTarget)

                let newExpectedShift = ExpectedShift(
                    id: UUID(),
                    user_id: userId,
                    employer_id: employer.id,
                    shift_date: dateFormatter.string(from: selectedDate),
                    start_time: timeFormatter.string(from: startTime),
                    end_time: timeFormatter.string(from: endTime),
                    expected_hours: expectedHours,
                    hourly_rate: employer.hourly_rate,
                    lunch_break_minutes: lunchBreakMinutes,
                    sales_target: customSalesTarget,
                    status: shiftStatus,
                    alert_minutes: alertMinutes,
                    notes: comments.isEmpty ? nil : comments,
                    created_at: Date(),
                    updated_at: Date()
                )

                print("📦 Creating new expected shift: \(newExpectedShift)")
                _ = try await SupabaseManager.shared.createExpectedShift(newExpectedShift)
                print("✅ Expected shift created successfully!")

                // Schedule notification if alert is set
                if let alertMins = alertMinutes {
                    try await NotificationManager.shared.scheduleShiftAlert(
                        shiftId: newExpectedShift.id,
                        shiftDate: selectedDate,
                        startTime: startTime,
                        employerName: employer.name,
                        alertMinutes: alertMins
                    )
                }

                // Shift saved successfully
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