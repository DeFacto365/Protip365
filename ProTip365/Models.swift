import Foundation

struct Employer: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let name: String
    let hourly_rate: Double
    let created_at: Date
}

struct Shift: Codable, Identifiable {
    let id: UUID?
    let user_id: UUID
    let employer_id: UUID?
    let shift_date: String
    let hours: Double
    let hourly_rate: Double?
    let sales: Double
    let tips: Double
    let cash_out: Double?
    let cash_out_note: String?
    let notes: String?
    let created_at: Date?
}

struct ShiftIncome: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let employer_id: UUID?
    let employer_name: String?
    let shift_date: String
    let hours: Double
    let hourly_rate: Double?
    let sales: Double
    let tips: Double
    let cash_out: Double?
    let base_income: Double?
    let net_tips: Double?
    let total_income: Double?
    let tip_percentage: Double?
}

struct UserProfile: Codable {
    let user_id: UUID
    let default_hourly_rate: Double
    let week_start: Int
    let target_tip_daily: Double
    let target_tip_weekly: Double
    let target_tip_monthly: Double
}
