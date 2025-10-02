import Foundation

// MARK: - Core Models

struct Employer: Codable, Identifiable, Hashable {
    let id: UUID
    let user_id: UUID
    let name: String
    let hourly_rate: Double
    let active: Bool
    let created_at: Date
}

// MARK: - New Simplified Models for Clean Database Structure

// Expected/Planned shift (scheduling data only)
struct ExpectedShift: Codable, Identifiable, Hashable {
    let id: UUID
    let user_id: UUID
    let employer_id: UUID?

    // Scheduling information
    let shift_date: String  // yyyy-MM-dd format
    let start_time: String  // HH:mm:ss format
    let end_time: String    // HH:mm:ss format
    let expected_hours: Double
    let hourly_rate: Double

    // Break time (only minutes, no hours field)
    let lunch_break_minutes: Int

    // Custom sales target for this shift (overrides default)
    let sales_target: Double? // NULL means use default target from settings

    // Status and metadata
    let status: String      // "planned", "completed", "missed"
    let alert_minutes: Int? // For notifications
    let notes: String?      // Planning notes

    let created_at: Date
    let updated_at: Date

    // Computed property for display
    var employer_name: String? {
        // This will need to be joined with employers table or passed separately
        return nil
    }
}

// Actual work performed and earnings
struct ShiftEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let shift_id: UUID      // Links to ExpectedShift.id
    let user_id: UUID

    // What actually happened
    let actual_start_time: String  // HH:mm:ss format
    let actual_end_time: String    // HH:mm:ss format
    let actual_hours: Double

    // Financial data (ONLY here, nowhere else)
    let sales: Double
    let tips: Double
    let cash_out: Double
    let other: Double

    // Snapshot fields - preserve financial calculation at time of entry
    let hourly_rate: Double?              // Snapshot of hourly rate
    let gross_income: Double?             // Calculated: actual_hours × hourly_rate
    let total_income: Double?             // Calculated: gross_income + tips + other - cash_out
    let net_income: Double?               // Calculated: total_income × (1 - deduction_percentage/100)
    let deduction_percentage: Double?     // Snapshot of average deduction percentage

    // Entry-specific notes
    let notes: String?

    let created_at: Date
    let updated_at: Date

    // Computed properties for convenience
    var net_tips: Double {
        return tips - cash_out
    }

    var total_earnings: Double {
        // Note: We'll need hourly_rate from the ExpectedShift to calculate base income
        // This will be calculated when we have both models together
        return tips + other - cash_out
    }

    var tip_percentage: Double {
        guard sales > 0 else { return 0 }
        return (tips / sales) * 100
    }
}

// Combined model for display purposes (replaces the old complex ShiftIncome)
struct ShiftWithEntry: Codable, Identifiable {
    let expected_shift: ExpectedShift
    let entry: ShiftEntry?
    let employer_name: String?

    var id: UUID { expected_shift.id }

    // Computed properties for UI compatibility
    var shift_date: String { expected_shift.shift_date }
    var status: String { expected_shift.status }
    var expected_hours: Double { expected_shift.expected_hours }
    var actual_hours: Double? { entry?.actual_hours }
    var tips: Double? { entry?.tips }
    var sales: Double? { entry?.sales }
    var cash_out: Double? { entry?.cash_out }
    var other: Double? { entry?.other }
    var hourly_rate: Double { expected_shift.hourly_rate }
    var lunch_break_minutes: Int { expected_shift.lunch_break_minutes }
    var total_income: Double? {
        guard let entry = entry else { return nil }
        let base_income = (entry.actual_hours * expected_shift.hourly_rate)
        return base_income + entry.tips + entry.other - entry.cash_out
    }

    // Time display helpers
    var display_start_time: String {
        return entry?.actual_start_time ?? expected_shift.start_time
    }

    var display_end_time: String {
        return entry?.actual_end_time ?? expected_shift.end_time
    }

    var has_entry: Bool {
        return entry != nil
    }

    // Compatibility properties for existing UI
    var hours: Double? { actual_hours }
    var employer_id: UUID? { expected_shift.employer_id }
    var notes: String? { entry?.notes ?? expected_shift.notes }

    // Memberwise initializer
    init(expected_shift: ExpectedShift, entry: ShiftEntry?, employer_name: String?) {
        self.expected_shift = expected_shift
        self.entry = entry
        self.employer_name = employer_name
    }

    // Constructor from ShiftIncome (temporary compatibility)
    init(from shiftIncome: ShiftIncome) {
        // Create ExpectedShift from ShiftIncome data
        self.expected_shift = ExpectedShift(
            id: shiftIncome.shift_id ?? UUID(),
            user_id: shiftIncome.user_id,
            employer_id: shiftIncome.employer_id,
            shift_date: shiftIncome.shift_date,
            start_time: shiftIncome.start_time ?? "00:00:00",
            end_time: shiftIncome.end_time ?? "23:59:59",
            expected_hours: shiftIncome.expected_hours ?? 8.0,
            hourly_rate: shiftIncome.hourly_rate,
            lunch_break_minutes: shiftIncome.lunch_break_minutes ?? 0,
            sales_target: nil, // Not available in ShiftIncome view
            status: shiftIncome.shift_status ?? "completed",
            alert_minutes: nil,
            notes: shiftIncome.notes,
            created_at: Date(),
            updated_at: Date()
        )

        // Create ShiftEntry if we have earnings data
        if shiftIncome.has_earnings {
            self.entry = ShiftEntry(
                id: UUID(),
                shift_id: shiftIncome.shift_id ?? UUID(),
                user_id: shiftIncome.user_id,
                actual_start_time: shiftIncome.start_time ?? "00:00:00",
                actual_end_time: shiftIncome.end_time ?? "23:59:59",
                actual_hours: shiftIncome.hours ?? 0.0,
                sales: shiftIncome.sales ?? 0.0,
                tips: shiftIncome.tips ?? 0.0,
                cash_out: shiftIncome.cash_out ?? 0.0,
                other: shiftIncome.other ?? 0.0,
                hourly_rate: nil,  // Legacy data doesn't have snapshots
                gross_income: shiftIncome.base_income,  // Use from view if available
                total_income: shiftIncome.total_income,  // Use from view if available
                net_income: nil,  // Not available in legacy data
                deduction_percentage: nil,  // Not available in legacy data
                notes: shiftIncome.notes,
                created_at: Date(),
                updated_at: Date()
            )
        } else {
            self.entry = nil
        }

        self.employer_name = shiftIncome.employer_name
    }
}

// MARK: - Temporary Compatibility Layer
// These models are kept temporarily to maintain compatibility with existing code
// They should be gradually replaced with the new models above

struct Shift: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let employer_id: UUID?
    let shift_date: String
    let expected_hours: Double
    let hours: Double
    let lunch_break_minutes: Int
    let hourly_rate: Double
    let sales: Double
    let tips: Double
    let cash_out: Double
    let other: Double
    let notes: String?
    let start_time: String?
    let end_time: String?
    let status: String?
    let alert_minutes: Int?
    let created_at: Date
}

struct ShiftIncome: Codable, Identifiable {
    // Primary fields
    let income_id: UUID?
    let shift_id: UUID?
    let user_id: UUID
    let employer_id: UUID?
    let employer_name: String?
    let shift_date: String
    let expected_hours: Double?
    let lunch_break_minutes: Int?
    let net_expected_hours: Double?
    let hours: Double?
    let hourly_rate: Double

    // Financial fields
    let sales: Double?
    let tips: Double?
    let cash_out: Double?
    let other: Double?
    let base_income: Double?
    let net_tips: Double?
    let total_income: Double?
    let tip_percentage: Double?

    // Target fields
    let sales_target: Double?  // Custom sales target for this shift

    // Time fields
    let start_time: String?
    let end_time: String?
    let actual_start_time: String?
    let actual_end_time: String?

    // Status and metadata
    let shift_status: String?
    let shift_created_at: Date?
    let earnings_created_at: Date?
    let notes: String?

    var id: UUID {
        return income_id ?? shift_id ?? UUID()
    }

    var has_earnings: Bool {
        return (sales ?? 0) > 0 || (tips ?? 0) > 0 || (cash_out ?? 0) > 0 || (other ?? 0) > 0
    }
}

struct ShiftIncomeData: Codable {
    let shift_id: UUID?
    let actual_hours: Double?
    let sales: Double
    let tips: Double
    let cash_out: Double
    let other: Double
    let notes: String?
}

// MARK: - SupabaseManager Extension for New Models

extension SupabaseManager {

    // MARK: - Expected Shifts

    func fetchExpectedShifts(from startDate: Date, to endDate: Date) async throws -> [ExpectedShift] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let userId = try await client.auth.session.user.id

        return try await client
            .from("expected_shifts")
            .select()
            .eq("user_id", value: userId)
            .gte("shift_date", value: dateFormatter.string(from: startDate))
            .lte("shift_date", value: dateFormatter.string(from: endDate))
            .order("shift_date", ascending: false)
            .execute()
            .value
    }

    func createExpectedShift(_ shift: ExpectedShift) async throws -> ExpectedShift {
        let response: [ExpectedShift] = try await client
            .from("expected_shifts")
            .insert(shift)
            .select()
            .execute()
            .value

        guard let createdShift = response.first else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create expected shift"])
        }

        return createdShift
    }

    func updateExpectedShift(_ shift: ExpectedShift) async throws -> ExpectedShift {
        let response: [ExpectedShift] = try await client
            .from("expected_shifts")
            .update(shift)
            .eq("id", value: shift.id)
            .select()
            .execute()
            .value

        guard let updatedShift = response.first else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update expected shift"])
        }

        return updatedShift
    }

    func deleteExpectedShift(id: UUID) async throws {
        try await client
            .from("expected_shifts")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Shift Entries

    func fetchShiftEntry(for shiftId: UUID) async throws -> ShiftEntry? {
        let userId = try await client.auth.session.user.id

        let response: [ShiftEntry] = try await client
            .from("shift_entries")
            .select()
            .eq("shift_id", value: shiftId)
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.first
    }

    func createShiftEntry(_ entry: ShiftEntry) async throws -> ShiftEntry {
        let response: [ShiftEntry] = try await client
            .from("shift_entries")
            .insert(entry)
            .select()
            .execute()
            .value

        guard let createdEntry = response.first else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create shift entry"])
        }

        return createdEntry
    }

    func updateShiftEntry(_ entry: ShiftEntry) async throws -> ShiftEntry {
        let response: [ShiftEntry] = try await client
            .from("shift_entries")
            .update(entry)
            .eq("id", value: entry.id)
            .execute()
            .value

        guard let updatedEntry = response.first else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update shift entry"])
        }

        return updatedEntry
    }

    func deleteShiftEntry(id: UUID) async throws {
        try await client
            .from("shift_entries")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Combined Queries

    func fetchShiftsWithEntries(from startDate: Date, to endDate: Date) async throws -> [ShiftWithEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)

        let userId = try await client.auth.session.user.id

        print("🚀 Optimized query: Loading shifts from \(startDateString) to \(endDateString)")

        // PERFORMANCE OPTIMIZATION: Single query with join-like behavior
        async let expectedShiftsTask: [ExpectedShift] = client
            .from("expected_shifts")
            .select()
            .eq("user_id", value: userId)
            .gte("shift_date", value: startDateString)
            .lte("shift_date", value: endDateString)
            .order("shift_date", ascending: false)
            .execute()
            .value

        // Load only entries that could be related to shifts in date range
        // Since entries link via shift_id, we need all entries for performance
        async let entriesTask: [ShiftEntry] = client
            .from("shift_entries")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        async let employersTask: [Employer] = fetchEmployers()

        // Execute all queries concurrently
        let (expectedShifts, allEntries, employers) = try await (expectedShiftsTask, entriesTask, employersTask)

        // Create lookup dictionaries for O(1) performance
        let entriesDict = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.shift_id, $0) })
        let employerDict = Dictionary(uniqueKeysWithValues: employers.map { ($0.id, $0.name) })

        // Combine the data efficiently
        let result = expectedShifts.map { shift in
            let entry = entriesDict[shift.id]
            let employerName = shift.employer_id.flatMap { employerDict[$0] }

            return ShiftWithEntry(
                expected_shift: shift,
                entry: entry,
                employer_name: employerName
            )
        }

        print("🚀 Optimized query completed: \(result.count) shifts loaded")
        return result
    }
}

struct UserProfile: Codable {
    let user_id: UUID
    let default_hourly_rate: Double
    let week_start: Int
    let tip_target_percentage: Double?
    let name: String?  // Changed from user_name to name
    let default_employer_id: UUID?
    let default_alert_minutes: Int? // Default alert time for new shifts
}

// Database Alert Model
struct DatabaseAlert: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let alert_type: String
    let title: String
    let message: String
    let is_read: Bool
    let action: String?
    let data: String? // jsonb data as string
    let created_at: Date
    let read_at: Date?

    // Helper to decode jsonb data
    func getDataDictionary() -> [String: Any]? {
        guard let data = data,
              let jsonData = data.data(using: .utf8) else { return nil }

        return try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    }

    // Helper to get shift ID from data
    func getShiftId() -> UUID? {
        guard let dataDict = getDataDictionary(),
              let shiftIdString = dataDict["shiftId"] as? String else { return nil }
        return UUID(uuidString: shiftIdString)
    }
}
