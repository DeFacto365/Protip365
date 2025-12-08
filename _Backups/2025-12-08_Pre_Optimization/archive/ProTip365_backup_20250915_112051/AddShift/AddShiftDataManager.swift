import SwiftUI

// MARK: - AddShift Data Manager
@MainActor
class AddShiftDataManager: ObservableObject {
    @Published var selectedDate = Date()
    @Published var selectedEmployer: Employer?
    @Published var startTime = Date()
    @Published var endTime = Date()
    @Published var selectedLunchBreak = "None"
    @Published var comments = ""
    @Published var employers: [Employer] = []
    @Published var isLoading = false
    @Published var isInitializing = true
    @Published var errorMessage = ""
    @Published var showErrorAlert = false

    private let editingShift: ShiftIncome?
    private let initialDate: Date?

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

        return Double(totalMinutes) / 60.0
    }

    // MARK: - Initialization Functions
    func initializeView() async {
        // First load employers
        await loadEmployers()

        // Then setup default times (which may depend on employers being loaded)
        await setupDefaultTimes()

        // Finally, mark initialization as complete
        isInitializing = false
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

            // Set end time to 5:00 PM on the selected date
            var endComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            endComponents.hour = 17
            endComponents.minute = 0
            endTime = calendar.date(from: endComponents) ?? baseDate
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
                comments = notes
                print("📝 Loaded notes: \(notes)")
            } else {
                print("📝 No notes found for shift")
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }

    // MARK: - Save Function
    func saveShift() async -> Bool {
        guard let employer = selectedEmployer else {
            print("❌ No employer selected")
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