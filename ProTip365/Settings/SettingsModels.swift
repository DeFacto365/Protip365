import Foundation
import SwiftUI

// MARK: - Settings Data Models

struct OriginalSettings {
    var hourlyRate: String
    var tipTarget: String
    var targetTipDaily: String
    var targetTipWeekly: String
    var targetTipMonthly: String
    var targetSalesDaily: String
    var targetSalesWeekly: String
    var targetSalesMonthly: String
    var targetHoursDaily: String
    var targetHoursWeekly: String
    var targetHoursMonthly: String
    var weekStartDay: Int
    var useMultipleEmployers: Bool
    var defaultEmployerId: UUID?
}

// MARK: - API Models

struct Profile: Decodable {
    let user_id: UUID
    let default_hourly_rate: Double
    let tip_target_percentage: Double?
    let target_tip_daily: Double?
    let target_tip_weekly: Double?
    let target_tip_monthly: Double?
    let target_sales_daily: Double?
    let target_sales_weekly: Double?
    let target_sales_monthly: Double?
    let target_hours_daily: Double?
    let target_hours_weekly: Double?
    let target_hours_monthly: Double?
    let week_start: Int?
    let use_multiple_employers: Bool?
    let default_employer_id: UUID?
}

struct ProfileUpdate: Encodable {
    let default_hourly_rate: Double
    let tip_target_percentage: Double?
    let target_tip_daily: Double?
    let target_tip_weekly: Double?
    let target_tip_monthly: Double?
    let target_sales_daily: Double?
    let target_sales_weekly: Double?
    let target_sales_monthly: Double?
    let target_hours_daily: Double?
    let target_hours_weekly: Double?
    let target_hours_monthly: Double?
    let week_start: Int
    let use_multiple_employers: Bool
    let default_employer_id: UUID?
}

struct ErrorResponse: Decodable {
    let message: String
}

// MARK: - Settings Sections Enum

enum SettingsSection: CaseIterable, Identifiable {
    case profile
    case targets
    case security
    case support
    case account

    var id: Self { self }

    func title(language: String) -> String {
        switch self {
        case .profile:
            switch language {
            case "fr": return "Profil"
            case "es": return "Perfil"
            default: return "Profile"
            }
        case .targets:
            switch language {
            case "fr": return "Objectifs"
            case "es": return "Objetivos"
            default: return "Targets"
            }
        case .security:
            switch language {
            case "fr": return "Sécurité"
            case "es": return "Seguridad"
            default: return "Security"
            }
        case .support:
            switch language {
            case "fr": return "Support"
            case "es": return "Soporte"
            default: return "Support"
            }
        case .account:
            switch language {
            case "fr": return "Compte"
            case "es": return "Cuenta"
            default: return "Account"
            }
        }
    }
}

// MARK: - Week Start Days

enum WeekStartDay: Int, CaseIterable, Identifiable {
    case sunday = 0
    case monday = 1

    var id: Int { rawValue }

    func name(language: String) -> String {
        switch self {
        case .sunday:
            switch language {
            case "fr": return "Dimanche"
            case "es": return "Domingo"
            default: return "Sunday"
            }
        case .monday:
            switch language {
            case "fr": return "Lundi"
            case "es": return "Lunes"
            default: return "Monday"
            }
        }
    }
}