import Foundation
import SwiftUI

// Define AchievementType enum at the top level
enum AchievementType: String, Codable, CaseIterable {
    case tipMaster = "tip_master"
    case consistencyKing = "consistency_king"
    case tipTargetCrusher = "tip_target_crusher"
    case highEarner = "high_earner"

    func title(language: String) -> String {
        switch self {
        case .tipMaster:
            switch language {
            case "fr": return "Maître des pourboires"
            case "es": return "Maestro de propinas"
            default: return "Tip Master"
            }
        case .consistencyKing:
            switch language {
            case "fr": return "Roi de la constance"
            case "es": return "Rey de la constancia"
            default: return "Consistency King"
            }
        case .tipTargetCrusher:
            switch language {
            case "fr": return "Destructeur d'objectifs"
            case "es": return "Destructor de objetivos"
            default: return "Target Crusher"
            }
        case .highEarner:
            switch language {
            case "fr": return "Gros salaire"
            case "es": return "Alto ingreso"
            default: return "High Earner"
            }
        }
    }

    func description(language: String) -> String {
        switch self {
        case .tipMaster:
            switch language {
            case "fr": return "Atteindre 20%+ de moyenne de pourboires"
            case "es": return "Lograr un promedio de propinas del 20%+"
            default: return "Achieve 20%+ tip average"
            }
        case .consistencyKing:
            switch language {
            case "fr": return "Entrer des données pendant 7 jours consécutifs"
            case "es": return "Ingresar datos durante 7 días consecutivos"
            default: return "Enter data for 7 consecutive days"
            }
        case .tipTargetCrusher:
            switch language {
            case "fr": return "Dépasser l'objectif de pourboires de 50%"
            case "es": return "Superar el objetivo de propinas en un 50%"
            default: return "Exceed tip target by 50%"
            }
        case .highEarner:
            switch language {
            case "fr": return "Gagner 30$/heure en moyenne"
            case "es": return "Ganar $30+/hora en promedio"
            default: return "Earn $30+/hour average"
            }
        }
    }
    
    var icon: String {
        switch self {
        case .tipMaster: return "star.fill"
        case .consistencyKing: return "crown.fill"
        case .tipTargetCrusher: return "target"
        case .highEarner: return "dollarsign.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .tipMaster: return .yellow
        case .consistencyKing: return .purple
        case .tipTargetCrusher: return .orange
        case .highEarner: return .green
        }
    }
}

enum StreakType: String, CaseIterable {
    case entryStreak = "entry_streak"
    case tipTargetStreak = "tip_target_streak"
    case salesTargetStreak = "sales_target_streak"
    case hoursTargetStreak = "hours_target_streak"
}

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var currentStreaks: [StreakType: Int] = [:]
    @Published var showAchievement = false
    @Published var currentAchievement: Achievement?

    private var language: String {
        UserDefaults.standard.string(forKey: "language") ?? "en"
    }
    
    init() {
        loadAchievements()
    }
    
    func checkForAchievements(shifts: [ShiftIncome], currentStats: DashboardView.Stats, targets: DashboardView.UserTargets) {
        checkTipAchievements(currentStats: currentStats, targets: targets)
        checkConsistencyAchievements(shifts: shifts)
        checkPerformanceAchievements(currentStats: currentStats)
        checkStreakAchievements(shifts: shifts)
    }
    
    private func checkTipAchievements(currentStats: DashboardView.Stats, targets: DashboardView.UserTargets) {
        // Tip Master Achievement
        if currentStats.tipPercentage >= 20 {
            let message = switch language {
            case "fr": "20%+ de moyenne de pourboires atteinte!"
            case "es": "¡Promedio de propinas del 20%+ alcanzado!"
            default: "Achieved 20%+ tip average!"
            }
            unlockAchievement(.tipMaster, message: message)
        }

        // Tip Target Crusher - now based on percentage of sales
        if targets.tipTargetPercentage > 0 && currentStats.sales > 0 {
            let targetTipAmount = currentStats.sales * (targets.tipTargetPercentage / 100.0)
            if currentStats.tips >= targetTipAmount * 1.5 {
                let message = switch language {
                case "fr": "Objectif de pourboires dépassé de 50%!"
                case "es": "¡Objetivo de propinas superado en un 50%!"
                default: "Exceeded tip target by 50%!"
                }
                unlockAchievement(.tipTargetCrusher, message: message)
            }
        }
    }
    
    private func checkConsistencyAchievements(shifts: [ShiftIncome]) {
        let calendar = Calendar.current
        let today = Date()
        
        // Check for 7-day entry streak
        var entryStreak = 0
        for dayOffset in 1...7 {
            guard let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: checkDate)
            
            let dayShifts = shifts.filter { $0.shift_date == dateString }
            if !dayShifts.isEmpty {
                entryStreak += 1
            } else {
                break
            }
        }
        
        if entryStreak >= 7 {
            let message = switch language {
            case "fr": "Série de 7 jours atteinte!"
            case "es": "¡Racha de 7 días alcanzada!"
            default: "7-day entry streak achieved!"
            }
            unlockAchievement(.consistencyKing, message: message)
        }
        
        // Update current streak
        currentStreaks[.entryStreak] = entryStreak
    }
    
    private func checkPerformanceAchievements(currentStats: DashboardView.Stats) {
        // High Hourly Rate
        if currentStats.hours > 0 {
            let hourlyRate = currentStats.totalRevenue / currentStats.hours
            if hourlyRate >= 30 {
                let message = switch language {
                case "fr": "Moyenne de 30$/heure atteinte!"
                case "es": "¡Promedio de $30+/hora alcanzado!"
                default: "Achieved $30+/hour average!"
                }
                unlockAchievement(.highEarner, message: message)
            }
        }
        
        // Perfect Day (all targets met)
        // This would need to be enhanced with target checking logic
    }
    
    private func checkStreakAchievements(shifts: [ShiftIncome]) {
        // Check for consecutive days hitting tip targets
        // Check for consecutive weeks hitting weekly targets
        // This would need more sophisticated tracking
    }
    
    private func unlockAchievement(_ type: AchievementType, message: String) {
        let achievement = Achievement(
            type: type,
            title: type.title(language: language),
            description: type.description(language: language),
            message: message,
            dateUnlocked: Date(),
            isUnlocked: true
        )
        
        // Check if already unlocked
        if !achievements.contains(where: { $0.type == type && $0.isUnlocked }) {
            achievements.append(achievement)
            currentAchievement = achievement
            showAchievement = true
            
            // Save to UserDefaults
            saveAchievements()
        }
    }
    
    private func loadAchievements() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }
    
    func getAchievementProgress(_ type: AchievementType) -> Double {
        // Calculate progress for each achievement type
        switch type {
        case .tipMaster:
            return 0.0 // Would need current tip percentage
        case .consistencyKing:
            return Double(currentStreaks[.entryStreak] ?? 0) / 7.0
        case .tipTargetCrusher:
            return 0.0 // Would need target vs actual comparison
        case .highEarner:
            return 0.0 // Would need current hourly rate
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: UUID
    let type: AchievementType
    let title: String
    let description: String
    let message: String
    let dateUnlocked: Date
    var isUnlocked: Bool
    
    init(type: AchievementType, title: String, description: String, message: String, dateUnlocked: Date, isUnlocked: Bool) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.message = message
        self.dateUnlocked = dateUnlocked
        self.isUnlocked = isUnlocked
    }
}
