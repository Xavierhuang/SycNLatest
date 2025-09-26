import Foundation
import SwiftData
import SwiftUI
import TelemetryDeck

@MainActor
class CharmManager: ObservableObject {
    static let shared = CharmManager()
    
    private init() {}
    
    // Mark a task as completed and track analytics
    func markTaskCompleted(_ task: CharmTask, for userProfile: UserProfile, in modelContext: ModelContext) {
        do {
            // Find existing charm progress
            let descriptor = FetchDescriptor<CharmProgress>()
            let allProgress = try modelContext.fetch(descriptor)
            let existingProgress = allProgress.first { $0.userId == userProfile.id }
            
            let charmProgress = existingProgress ?? CharmProgress(userId: userProfile.id)
            
            if existingProgress == nil {
                modelContext.insert(charmProgress)
            }
            
            // Track if this is a new completion
            let wasAlreadyCompleted = isTaskCompleted(task, in: charmProgress)
            let wasAllCompleted = charmProgress.allTasksCompleted
            
            if !wasAlreadyCompleted {
                charmProgress.markTaskCompleted(task)
                try modelContext.save()
                
                // Track analytics
                TelemetryDeck.signal("Charm.TaskCompleted", parameters: [
                    "task": task.rawValue,
                    "taskTitle": task.title,
                    "completedTasksCount": "\(charmProgress.completedTasksCount)",
                    "allTasksCompleted": "\(charmProgress.allTasksCompleted)",
                    "userCyclePhase": userProfile.calculateCyclePhaseForDate(Date()).rawValue
                ])
                
                // If just earned the charm, track that too
                if !wasAllCompleted && charmProgress.allTasksCompleted {
                    TelemetryDeck.signal("Charm.Earned", parameters: [
                        "userId": userProfile.id.uuidString,
                        "earnedDate": ISO8601DateFormatter().string(from: Date()),
                        "userCyclePhase": userProfile.calculateCyclePhaseForDate(Date()).rawValue
                    ])
                }
            }
        } catch {
            print("Error marking charm task as completed: \(error)")
        }
    }
    
    // Get charm progress for a user
    func getCharmProgress(for userProfile: UserProfile, in modelContext: ModelContext) -> CharmProgress? {
        do {
            let descriptor = FetchDescriptor<CharmProgress>()
            let allProgress = try modelContext.fetch(descriptor)
            return allProgress.first { $0.userId == userProfile.id }
        } catch {
            print("Error fetching charm progress: \(error)")
            return nil
        }
    }
    
    private func isTaskCompleted(_ task: CharmTask, in progress: CharmProgress) -> Bool {
        switch task {
        case .watchPhaseVideos:
            return progress.hasWatchedPhaseVideos
        case .watchHormoneVideos:
            return progress.hasWatchedHormoneVideos
        case .writeNote:
            return progress.hasWrittenNote
        case .reviewApp:
            return progress.hasReviewedApp
        case .acceptWeeklyPlan:
            return progress.hasAcceptedWeeklyPlan
        case .joinSubstack:
            return progress.hasJoinedSubstack
        }
    }
    
    // Convenience methods for specific task completions
    
    func checkAndMarkPhaseVideosComplete(for userProfile: UserProfile, in modelContext: ModelContext) {
        let completedPhaseVideos = getCompletedVideoCount(for: userProfile, section: "phase", in: modelContext)
        let totalPhaseVideos = 4 // Total phase videos
        
        if completedPhaseVideos >= totalPhaseVideos {
            markTaskCompleted(.watchPhaseVideos, for: userProfile, in: modelContext)
        }
    }
    
    func checkAndMarkHormoneVideosComplete(for userProfile: UserProfile, in modelContext: ModelContext) {
        let completedHormoneVideos = getCompletedVideoCount(for: userProfile, section: "hormone", in: modelContext)
        let totalHormoneVideos = 6 // Total hormone videos
        
        if completedHormoneVideos >= totalHormoneVideos {
            markTaskCompleted(.watchHormoneVideos, for: userProfile, in: modelContext)
        }
    }
    
    private func getCompletedVideoCount(for userProfile: UserProfile, section: String, in modelContext: ModelContext) -> Int {
        do {
            let descriptor = FetchDescriptor<VideoProgress>()
            let allProgress = try modelContext.fetch(descriptor)
            
            return allProgress.filter { progress in
                progress.userId == userProfile.id && 
                progress.isCompleted &&
                (section == "hormone" ? 
                 progress.videoTitle.contains("Estrogen") || 
                 progress.videoTitle.contains("Progesterone") || 
                 progress.videoTitle.contains("Testosterone") || 
                 progress.videoTitle.contains("Menstrual Cycle") || 
                 progress.videoTitle.contains("FSH") || 
                 progress.videoTitle.contains("LH") :
                 progress.videoTitle.contains("Phase"))
            }.count
        } catch {
            return 0
        }
    }
    
    func getVideoProgress(for userProfile: UserProfile, section: String, in modelContext: ModelContext) -> (completed: Int, total: Int) {
        let completed = getCompletedVideoCount(for: userProfile, section: section, in: modelContext)
        let total = section == "hormone" ? 6 : 4
        return (completed, total)
    }
    
    func markNoteWritten(for userProfile: UserProfile, in modelContext: ModelContext) {
        markTaskCompleted(.writeNote, for: userProfile, in: modelContext)
    }
    
    func markAppReviewed(for userProfile: UserProfile, in modelContext: ModelContext) {
        markTaskCompleted(.reviewApp, for: userProfile, in: modelContext)
    }
    
    func markWeeklyPlanAccepted(for userProfile: UserProfile, in modelContext: ModelContext) {
        markTaskCompleted(.acceptWeeklyPlan, for: userProfile, in: modelContext)
    }
    
    func markSubstackJoined(for userProfile: UserProfile, in modelContext: ModelContext) {
        markTaskCompleted(.joinSubstack, for: userProfile, in: modelContext)
    }
}

// Extension to add charm tracking methods to existing views
extension View {
    func trackCharmTaskCompletion(_ task: CharmTask, userProfile: UserProfile?, modelContext: ModelContext) {
        guard let userProfile = userProfile else { return }
        CharmManager.shared.markTaskCompleted(task, for: userProfile, in: modelContext)
    }
}
