import Foundation
import SwiftData

@Model
final class UserRewardsData {
    var id: UUID
    var userId: UUID
    var totalPoints: Int
    var currentStreak: Int
    var longestStreak: Int
    var workoutsCompleted: Int
    var achievements: [String]
    var lastWorkoutDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.totalPoints = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.workoutsCompleted = 0
        self.achievements = []
        self.lastWorkoutDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
