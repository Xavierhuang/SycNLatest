import Foundation
import SwiftData

@Model
final class WorkoutRating {
    var id: UUID
    var workoutId: String
    var workoutTitle: String
    var instructor: String?
    var rating: Int // 1-5 stars
    var notes: String?
    var dateCompleted: Date
    var cyclePhase: CyclePhase
    var createdAt: Date
    var updatedAt: Date
    
    init(workoutId: String, workoutTitle: String, instructor: String? = nil, rating: Int, notes: String? = nil, dateCompleted: Date, cyclePhase: CyclePhase) {
        self.id = UUID()
        self.workoutId = workoutId
        self.workoutTitle = workoutTitle
        self.instructor = instructor
        self.rating = rating
        self.notes = notes
        self.dateCompleted = dateCompleted
        self.cyclePhase = cyclePhase
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
