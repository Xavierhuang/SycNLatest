import Foundation
import SwiftData
import SwiftUI

@MainActor
class RewardsManager: ObservableObject {
    @Published var totalPoints: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var workoutsCompleted: Int = 0
    @Published var achievements: [String] = []
    @Published var showingPointsNotification: Bool = false
    @Published var pointsNotificationMessage: String = ""
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserRewards()
    }
    
    private func loadUserRewards() {
        // Load user rewards data from SwiftData
        let descriptor = FetchDescriptor<UserRewardsData>()
        do {
            let rewardsData = try modelContext.fetch(descriptor)
            if let userRewards = rewardsData.first {
                self.totalPoints = userRewards.totalPoints
                self.currentStreak = userRewards.currentStreak
                self.longestStreak = userRewards.longestStreak
                self.workoutsCompleted = userRewards.workoutsCompleted
                self.achievements = userRewards.achievements
            }
        } catch {
            print("Failed to load user rewards: \(error)")
        }
    }
    
    func addPoints(_ points: Int) {
        totalPoints += points
        saveRewards()
    }
    
    func completeWorkout() {
        workoutsCompleted += 1
        currentStreak += 1
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        saveRewards()
    }
    
    func trackNutritionHabitCompleted(userId: UUID) {
        // TODO: Implement nutrition habit tracking
        print("Nutrition habit completed for user: \(userId)")
    }
    
    func resetStreak() {
        currentStreak = 0
        saveRewards()
    }
    
    func addAchievement(_ achievement: String) {
        if !achievements.contains(achievement) {
            achievements.append(achievement)
            saveRewards()
        }
    }
    
    private func saveRewards() {
        let descriptor = FetchDescriptor<UserRewardsData>()
        do {
            let rewardsData = try modelContext.fetch(descriptor)
            if let userRewards = rewardsData.first {
                userRewards.totalPoints = totalPoints
                userRewards.currentStreak = currentStreak
                userRewards.longestStreak = longestStreak
                userRewards.workoutsCompleted = workoutsCompleted
                userRewards.achievements = achievements
                userRewards.updatedAt = Date()
            } else {
                // Create new rewards data
                let newRewards = UserRewardsData(userId: UUID())
                newRewards.totalPoints = totalPoints
                newRewards.currentStreak = currentStreak
                newRewards.longestStreak = longestStreak
                newRewards.workoutsCompleted = workoutsCompleted
                newRewards.achievements = achievements
                modelContext.insert(newRewards)
            }
            try modelContext.save()
        } catch {
            print("Failed to save rewards: \(error)")
        }
    }
}
