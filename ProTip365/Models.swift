import Foundation

struct Employer: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let name: String
    let hourly_rate: Double
    let active: Bool
    let created_at: Date
}

// Expected/Planned shift (no earnings data)
struct Shift: Codable, Identifiable, Hashable {
    let id: UUID?
    let user_id: UUID
    let employer_id: UUID?
    let shift_date: String
    let expected_hours: Double
    let lunch_break_minutes: Int?
    let hourly_rate: Double?
    let notes: String?
    let start_time: String?
    let end_time: String?
    let status: String? // planned, completed, missed
    let created_at: Date?
}

// Actual earnings data for a completed shift
struct ShiftIncomeData: Codable, Identifiable {
    let id: UUID?
    let shift_id: UUID
    let user_id: UUID
    let actual_hours: Double
    let sales: Double
    let tips: Double
    let cash_out: Double?
    let other: Double?
    let actual_start_time: String?
    let actual_end_time: String?
    let notes: String?
    let created_at: Date?
}

// Combined view model that includes both planned shift and actual earnings
struct ShiftIncome: Codable, Identifiable, Equatable {
    let income_id: UUID? // ID from shift_income table (null if no earnings recorded)
    let shift_id: UUID?  // ID from shifts table (should always be present, but making optional for safety)
    var id: UUID { shift_id ?? income_id ?? UUID() } // Identifiable requirement - use shift_id or fallback
    let user_id: UUID
    let employer_id: UUID?
    let employer_name: String?
    let shift_date: String
    let expected_hours: Double
    let lunch_break_minutes: Int?
    let net_expected_hours: Double? // expected_hours minus lunch break
    let hours: Double // actual hours (0 if no earnings recorded)
    let hourly_rate: Double?
    let sales: Double
    let tips: Double
    let cash_out: Double?
    let other: Double?
    let base_income: Double?
    let net_tips: Double?
    let total_income: Double?
    let tip_percentage: Double?
    let start_time: String?
    let end_time: String?
    let shift_status: String? // planned, completed, missed
    let has_earnings: Bool // true if earnings data exists
    let shift_created_at: String?
    let earnings_created_at: String?
}

struct UserProfile: Codable {
    let user_id: UUID
    let default_hourly_rate: Double
    let week_start: Int
    let target_tip_daily: Double
    let target_tip_weekly: Double
    let target_tip_monthly: Double
    let name: String?  // Changed from user_name to name
    let default_employer_id: UUID?
}
