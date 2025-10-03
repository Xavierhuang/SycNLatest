import Foundation
import SwiftData

@Model
final class CustomWorkout {
    var id: UUID
    var name: String
    var activityType: String
    var intensity: String
    var duration: String
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, activityType: String, intensity: String, duration: String) {
        self.id = UUID()
        self.name = name
        self.activityType = activityType
        self.intensity = intensity
        self.duration = duration
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
