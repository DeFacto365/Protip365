import SwiftUI

// MARK: - Onboarding Models

enum OnboardingStep: Int, CaseIterable {
    case welcome = 1
    case setup = 2
    case completion = 3

    var totalSteps: Int {
        return OnboardingStep.allCases.count
    }
}

enum Field {
    case tipPercentage, averageDeductionPercentage, dailySales, weeklySales, monthlySales, dailyHours, weeklyHours, monthlyHours
}

// SecurityType is already defined in SecurityManager.swift

// MARK: - Onboarding State

class OnboardingState: ObservableObject {
    @Published var currentStep = 1
    @Published var selectedLanguage = "en"
    @Published var userName = ""
    @Published var useMultipleEmployers = false
    @Published var singleEmployerName = ""
    @Published var showEmployersPage = false
    @Published var defaultEmployerId: UUID? = nil
    @Published var employers: [Employer] = []
    @Published var weekStartDay = 0
    @Published var selectedSecurityType = SecurityType.none
    @Published var hasVariableSchedule = false
    @Published var tipTargetPercentage = "15"
    @Published var targetSalesDaily = "100" // Smart Default
    @Published var targetSalesWeekly = "500" // Smart Default
    @Published var targetSalesMonthly = "2000" // Smart Default
    @Published var targetHoursDaily = "8" // Smart Default
    @Published var targetHoursWeekly = "40" // Smart Default
    @Published var targetHoursMonthly = "160" // Smart Default
    @Published var averageDeductionPercentage = "30"
    @Published var showPINSetup = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let totalSteps = 3
    let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var isStepValid: Bool {
        switch currentStep {
        case 1: return true // Welcome/Language
        case 2: return true // Setup (Week Start + Security)
        case 3: return true // Completion
        default: return false
        }
    }

    func resetToDefaults() {
        currentStep = 1
        selectedLanguage = "en"
        useMultipleEmployers = false
        singleEmployerName = ""
        showEmployersPage = false
        defaultEmployerId = nil
        employers = []
        weekStartDay = 0
        selectedSecurityType = .none
        hasVariableSchedule = false
        tipTargetPercentage = "15"
        targetSalesDaily = ""
        targetSalesWeekly = ""
        targetSalesMonthly = ""
        targetHoursDaily = ""
        targetHoursWeekly = ""
        targetHoursMonthly = ""
        averageDeductionPercentage = "30"
        showPINSetup = false
        isLoading = false
        showError = false
        errorMessage = ""
    }
}

// MARK: - Onboarding Profile Update Model

struct OnboardingProfileUpdate: Encodable {
    let preferred_language: String
    let name: String?
    let use_multiple_employers: Bool
    let week_start: Int
    let has_variable_schedule: Bool
    let tip_target_percentage: Double
    let target_sales_daily: Double
    let target_sales_weekly: Double
    let target_sales_monthly: Double
    let target_hours_daily: Double
    let target_hours_weekly: Double
    let target_hours_monthly: Double
    let average_deduction_percentage: Double
    let default_employer_id: String?
    let onboarding_completed: Bool
}