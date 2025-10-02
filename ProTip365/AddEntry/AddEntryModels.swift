import Foundation

// MARK: - AddEntry State Models
struct AddEntryState {
    // Date and time properties
    var selectedDate = Date()
    var selectedEndDate = Date()
    var startTime = Date()
    var endTime = Date()
    var selectedLunchBreak = "None"

    // Work info properties
    var selectedEmployer: Employer?
    var didntWork = false
    var missedReason = ""

    // Earnings properties
    var sales = ""
    var tips = ""
    var tipOut = ""
    var other = ""
    var comments = ""

    // UI state properties
    var showDatePicker = false
    var showEndDatePicker = false
    var showStartTimePicker = false
    var showEndTimePicker = false
    var showEmployerPicker = false
    var showLunchBreakPicker = false
    var showReasonPicker = false
    var isLoading = false
    var showErrorAlert = false
    var errorMessage = ""
}

// MARK: - Constants
struct AddEntryConstants {
    static let lunchBreakOptions = ["None", "15 min", "30 min", "45 min", "60 min"]

    static func lunchBreakMinutes(from selection: String) -> Int {
        switch selection {
        case "15 min": return 15
        case "30 min": return 30
        case "45 min": return 45
        case "60 min": return 60
        default: return 0
        }
    }

    static func lunchBreakSelection(from minutes: Int?) -> String {
        guard let minutes = minutes else { return "None" }
        switch minutes {
        case 15: return "15 min"
        case 30: return "30 min"
        case 45: return "45 min"
        case 60: return "60 min"
        default: return "None"
        }
    }
}

// MARK: - Database Models
struct ShiftInsert: Encodable {
    let user_id: UUID
    let shift_date: String
    let expected_hours: Double
    let hours: Double
    let start_time: String
    let end_time: String
    let hourly_rate: Double
    let employer_id: UUID?
    let status: String
    let notes: String?
}

struct ShiftResponse: Decodable {
    let id: UUID
}

struct ShiftDateUpdate: Encodable {
    let shift_date: String
}

struct ShiftUpdate: Encodable {
    let start_time: String
    let end_time: String
    let lunch_break_minutes: Int
    let expected_hours: Double
    let status: String
    let employer_id: UUID?
    let hourly_rate: Double
    let notes: String?
}

// For updating only the status when adding/editing entry data
struct ShiftStatusUpdate: Encodable {
    let status: String
    let notes: String?
}

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
    let hourly_rate: Double
    let gross_income: Double
    let total_income: Double
    let net_income: Double
    let deduction_percentage: Double
}

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
    let hourly_rate: Double
    let gross_income: Double
    let total_income: Double
    let net_income: Double
    let deduction_percentage: Double
}

struct IncomeCheck: Decodable {
    let id: UUID
}

struct NoteOnly: Decodable {
    let notes: String?
}

// MARK: - Helper Extensions
extension AddEntryState {
    var calculatedHours: Double {
        // Return 0 hours if didn't work
        if didntWork {
            return 0
        }

        let calendar = Calendar.current

        // Combine date and time components for start
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        startComponents.hour = startTimeComponents.hour
        startComponents.minute = startTimeComponents.minute

        // Combine date and time components for end
        var endComponents = calendar.dateComponents([.year, .month, .day], from: selectedEndDate)
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        endComponents.hour = endTimeComponents.hour
        endComponents.minute = endTimeComponents.minute

        let startDateTime = calendar.date(from: startComponents) ?? Date()
        let endDateTime = calendar.date(from: endComponents) ?? Date()

        let duration = endDateTime.timeIntervalSince(startDateTime)
        let hoursWorked = duration / 3600

        // Subtract lunch break
        let netHours = hoursWorked - (Double(AddEntryConstants.lunchBreakMinutes(from: selectedLunchBreak)) / 60.0)
        return max(0, netHours)
    }

    var totalEarnings: Double {
        let tipsAmount = Double(tips) ?? 0
        let tipOutAmount = Double(tipOut) ?? 0
        let otherAmount = Double(other) ?? 0
        let hourlyRate = selectedEmployer?.hourly_rate ?? 15.00 // Default rate
        let salary = calculatedHours * hourlyRate
        return salary + tipsAmount + otherAmount - tipOutAmount
    }

    func hasUnsavedChanges() -> Bool {
        // Only disable dismiss if user has entered data
        return !sales.isEmpty || !tips.isEmpty || !tipOut.isEmpty || !other.isEmpty || calculatedHours > 0
    }
}