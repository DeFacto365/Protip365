import SwiftUI

// MARK: - Onboarding Models

enum OnboardingStep: Int, CaseIterable {
    case language = 1
    case multipleEmployers = 2
    case weekStart = 3
    case security = 4
    case variableSchedule = 5
    case salesAndTipTargets = 6
    case howToUse = 7

    var totalSteps: Int {
        return OnboardingStep.allCases.count
    }
}

enum Field {
    case tipPercentage, dailySales, weeklySales, monthlySales, dailyHours, weeklyHours, monthlyHours
}

// SecurityType is already defined in SecurityManager.swift

// MARK: - Onboarding State

class OnboardingState: ObservableObject {
    @Published var currentStep = 1
    @Published var selectedLanguage = "en"
    @Published var useMultipleEmployers = false
    @Published var weekStartDay = 0
    @Published var selectedSecurityType = SecurityType.none
    @Published var hasVariableSchedule = false
    @Published var tipTargetPercentage = "15"
    @Published var targetSalesDaily = ""
    @Published var targetSalesWeekly = ""
    @Published var targetSalesMonthly = ""
    @Published var targetHoursDaily = ""
    @Published var targetHoursWeekly = ""
    @Published var targetHoursMonthly = ""
    @Published var showPINSetup = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let totalSteps = 7
    let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var isStepValid: Bool {
        switch currentStep {
        case 1: return true // Language selection always valid
        case 2: return true // Multiple employers always valid (boolean)
        case 3: return true // Week start always valid
        case 4: return true // Security always valid
        case 5: return true // Variable schedule always valid (boolean)
        case 6: return !tipTargetPercentage.isEmpty && !targetSalesDaily.isEmpty && !targetHoursDaily.isEmpty // All targets required
        case 7: return true // How to use page always valid
        default: return false
        }
    }

    func resetToDefaults() {
        currentStep = 1
        selectedLanguage = "en"
        useMultipleEmployers = false
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
        showPINSetup = false
        isLoading = false
        showError = false
        errorMessage = ""
    }
}

// MARK: - Onboarding Profile Update Model

struct OnboardingProfileUpdate: Encodable {
    let language: String
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
}