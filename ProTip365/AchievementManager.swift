import Foundation
import SwiftUI

// Define AchievementType enum at the top level
enum AchievementType: String, Codable, CaseIterable {
    case tipMaster = "tip_master"
    case consistencyKing = "consistency_king"
    case tipTargetCrusher = "tip_target_crusher"
    case highEarner = "high_earner"
    
    var title: String {
        switch self {
        case .tipMaster: return "Tip Master"
        case .consistencyKing: return "Consistency King"
        case .tipTargetCrusher: return "Target Crusher"
        case .highEarner: return "High Earner"
        }
    }
    
    var description: String {
        switch self {
        case .tipMaster: return "Achieve 20%+ tip average"
        case .consistencyKing: return "Enter data for 7 consecutive days"
        case .tipTargetCrusher: return "Exceed tip target by 50%"
        case .highEarner: return "Earn $30+/hour average"
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
            unlockAchievement(.tipMaster, message: "Achieved 20%+ tip average!")
        }
        
        // Tip Target Crusher
        if targets.dailyTips > 0 && currentStats.tips >= targets.dailyTips * 1.5 {
            unlockAchievement(.tipTargetCrusher, message: "Exceeded daily tip target by 50%!")
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
            unlockAchievement(.consistencyKing, message: "7-day entry streak achieved!")
        }
        
        // Update current streak
        currentStreaks[.entryStreak] = entryStreak
    }
    
    private func checkPerformanceAchievements(currentStats: DashboardView.Stats) {
        // High Hourly Rate
        if currentStats.hours > 0 {
            let hourlyRate = currentStats.totalRevenue / currentStats.hours
            if hourlyRate >= 30 {
                unlockAchievement(.highEarner, message: "Achieved $30+/hour average!")
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
            title: type.title,
            description: type.description,
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
