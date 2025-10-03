import Foundation
import SwiftData

@Model
final class CharmProgress {
    var id: UUID
    var userId: UUID
    
    // Task completion tracking
    var hasWatchedPhaseVideos: Bool = false
    var hasWatchedHormoneVideos: Bool = false
    var hasWrittenNote: Bool = false
    var hasReviewedApp: Bool = false
    var hasAcceptedWeeklyPlan: Bool = false
    var hasJoinedSubstack: Bool = false
    
    // Charm earned status
    var hasEarnedCharm: Bool = false
    var charmEarnedDate: Date?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Computed property to check if all tasks are completed
    var allTasksCompleted: Bool {
        return hasWatchedPhaseVideos && 
               hasWatchedHormoneVideos && 
               hasWrittenNote && 
               hasReviewedApp && 
               hasAcceptedWeeklyPlan && 
               hasJoinedSubstack
    }
    
    // Get completion count
    var completedTasksCount: Int {
        var count = 0
        if hasWatchedPhaseVideos { count += 1 }
        if hasWatchedHormoneVideos { count += 1 }
        if hasWrittenNote { count += 1 }
        if hasReviewedApp { count += 1 }
        if hasAcceptedWeeklyPlan { count += 1 }
        if hasJoinedSubstack { count += 1 }
        return count
    }
    
    // Mark task as completed and update charm status
    func markTaskCompleted(_ task: CharmTask) {
        switch task {
        case .watchPhaseVideos:
            hasWatchedPhaseVideos = true
        case .watchHormoneVideos:
            hasWatchedHormoneVideos = true
        case .writeNote:
            hasWrittenNote = true
        case .reviewApp:
            hasReviewedApp = true
        case .acceptWeeklyPlan:
            hasAcceptedWeeklyPlan = true
        case .joinSubstack:
            hasJoinedSubstack = true
        }
        
        updatedAt = Date()
        
        // Check if charm should be awarded
        if allTasksCompleted && !hasEarnedCharm {
            hasEarnedCharm = true
            charmEarnedDate = Date()
        }
    }
}

enum CharmTask: String, CaseIterable {
    case joinSubstack = "join_substack"
    case watchHormoneVideos = "watch_hormone_videos"
    case watchPhaseVideos = "watch_phase_videos"
    case acceptWeeklyPlan = "accept_weekly_plan"
    case writeNote = "write_note"
    case reviewApp = "review_app"
    
    var title: String {
        switch self {
        case .joinSubstack:
            return "Join Substack"
        case .watchHormoneVideos:
            return "Watch Hormone Videos"
        case .watchPhaseVideos:
            return "Watch Phase Videos"
        case .acceptWeeklyPlan:
            return "Accept Weekly Plan"
        case .writeNote:
            return "Write a Note"
        case .reviewApp:
            return "Review the App"
        }
    }
    
    var icon: String {
        switch self {
        case .joinSubstack:
            return "envelope.fill"
        case .watchHormoneVideos:
            return "play.circle.fill"
        case .watchPhaseVideos:
            return "play.circle.fill"
        case .acceptWeeklyPlan:
            return "checkmark.circle.fill"
        case .writeNote:
            return "pencil.and.outline"
        case .reviewApp:
            return "star.fill"
        }
    }
    
    var description: String {
        switch self {
        case .joinSubstack:
            return "Join our beta testers community"
        case .watchHormoneVideos:
            return "Understand your hormones"
        case .watchPhaseVideos:
            return "Learn about your cycle phases"
        case .acceptWeeklyPlan:
            return "Commit to your fitness plan"
        case .writeNote:
            return "Reflect on your journey"
        case .reviewApp:
            return "Share your experience"
        }
    }
}
