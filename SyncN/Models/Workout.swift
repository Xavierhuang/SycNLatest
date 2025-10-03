import Foundation
import SwiftData
import SwiftUI

@Model
final class Workout {
    var id: UUID
    var title: String
    var workoutDescription: String
    var duration: Int // in minutes
    var caloriesBurned: Int?
    var workoutType: WorkoutType
    var cyclePhase: CyclePhase
    var difficulty: WorkoutDifficulty
    var exercises: [Exercise]
    var completedAt: Date?
    var createdAt: Date
    var userProfile: UserProfile?
    var instructor: String?
    var videoURL: String?
    var audioURL: String?
    var isVideo: Bool = false
    var injuries: [String]?
    
    init(title: String, description: String, duration: Int, workoutType: WorkoutType, cyclePhase: CyclePhase, difficulty: WorkoutDifficulty, instructor: String? = nil, videoURL: String? = nil, audioURL: String? = nil, isVideo: Bool = false, injuries: [String]? = nil) {
        self.id = UUID()
        self.title = title
        self.workoutDescription = description
        self.duration = duration
        self.workoutType = workoutType
        self.cyclePhase = cyclePhase
        self.difficulty = difficulty
        self.exercises = []
        self.createdAt = Date()
        self.instructor = instructor
        self.videoURL = videoURL
        self.audioURL = audioURL
        self.isVideo = isVideo
        self.injuries = injuries
    }
    
    var isCompleted: Bool {
        return completedAt != nil
    }
    
    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    case yoga = "Yoga"
    case strength = "Strength Training"
    case cardio = "Cardio"
    case pilates = "Pilates"
    case dance = "Dance"
    case walking = "Walking"
    case stretching = "Stretching"
    case meditation = "Meditation"
    case hiit = "HIIT"
    case boxing = "Boxing"
    
    var icon: String {
        switch self {
        case .yoga: return "figure.mind.and.body"
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.circle.fill"
        case .pilates: return "figure.core.training"
        case .dance: return "music.note"
        case .walking: return "figure.walk"
        case .stretching: return "figure.flexibility"
        case .meditation: return "brain.head.profile"
        case .hiit: return "hare.fill"
        case .boxing: return "figure.boxing"
        }
    }
    
    var color: Color {
        switch self {
        case .yoga: return .purple
        case .strength: return .blue
        case .cardio: return .red
        case .pilates: return .green
        case .dance: return .pink
        case .walking: return .orange
        case .stretching: return .yellow
        case .meditation: return .indigo
        case .hiit: return .cyan
        case .boxing: return .red
        }
    }
}

enum WorkoutDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var multiplier: Double {
        switch self {
        case .beginner: return 0.8
        case .intermediate: return 1.0
        case .advanced: return 1.2
        }
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var exerciseDescription: String
    var duration: Int // in seconds
    var sets: Int?
    var reps: Int?
    var restTime: Int // in seconds
    var videoURL: String?
    var instructions: [String]
    var muscleGroups: [MuscleGroup]
    
    init(name: String, description: String, duration: Int, restTime: Int = 30) {
        self.id = UUID()
        self.name = name
        self.exerciseDescription = description
        self.duration = duration
        self.restTime = restTime
        self.instructions = []
        self.muscleGroups = []
    }
}

enum MuscleGroup: String, CaseIterable, Codable {
    case core = "Core"
    case legs = "Legs"
    case arms = "Arms"
    case back = "Back"
    case chest = "Chest"
    case shoulders = "Shoulders"
    case glutes = "Glutes"
    case fullBody = "Full Body"
    
    var icon: String {
        switch self {
        case .core: return "figure.core.training"
        case .legs: return "figure.walk"
        case .arms: return "figure.strengthtraining.traditional"
        case .back: return "figure.mixed.cardio"
        case .chest: return "figure.strengthtraining.traditional"
        case .shoulders: return "figure.strengthtraining.traditional"
        case .glutes: return "figure.strengthtraining.traditional"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}