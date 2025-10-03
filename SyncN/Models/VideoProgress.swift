import Foundation
import SwiftData

@Model
final class VideoProgress {
    var id: UUID
    var userId: UUID
    var videoId: UUID
    var videoTitle: String
    var isCompleted: Bool = false
    var watchedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(userId: UUID, videoId: UUID, videoTitle: String) {
        self.id = UUID()
        self.userId = userId
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func markAsCompleted() {
        isCompleted = true
        watchedAt = Date()
        updatedAt = Date()
    }
}
