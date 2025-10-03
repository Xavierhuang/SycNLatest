import Foundation
import SwiftData

@Model
final class WeeklyFitnessPlanEntry: @unchecked Sendable {
    var id: UUID
    var date: Date
    var workoutTitle: String
    var workoutDescription: String
    var duration: Int
    var workoutType: WorkoutType
    var cyclePhase: CyclePhase
    var difficulty: WorkoutDifficulty
    var instructor: String?
    var audioURL: String?
    var videoURL: String?
    var isVideo: Bool
    var injuries: [String]?
    var equipment: [String]
    var benefits: [String]
    var status: WorkoutStatus
    
    init(date: Date, workoutTitle: String, workoutDescription: String, duration: Int, workoutType: WorkoutType, cyclePhase: CyclePhase, difficulty: WorkoutDifficulty, equipment: [String] = [], benefits: [String] = [], instructor: String? = nil, audioURL: String? = nil, videoURL: String? = nil, isVideo: Bool = false, injuries: [String]? = nil, status: WorkoutStatus = .suggested) {
        self.id = UUID()
        self.date = date
        self.workoutTitle = workoutTitle
        self.workoutDescription = workoutDescription
        self.duration = duration
        self.workoutType = workoutType
        self.cyclePhase = cyclePhase
        self.difficulty = difficulty
        self.equipment = equipment
        self.benefits = benefits
        self.instructor = instructor
        self.audioURL = audioURL
        self.videoURL = videoURL
        self.isVideo = isVideo
        self.injuries = injuries
        self.status = status
    }
}
