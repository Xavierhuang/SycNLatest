import Foundation
import SwiftData
import SwiftUI

@Model
final class Progress {
    var id: UUID
    var date: Date
    var weight: Double?
    var bodyFatPercentage: Double?
    var measurements: [BodyMeasurement]
    var mood: Mood
    var energy: EnergyLevel
    var sleepHours: Double?
    var waterIntake: Double // in liters
    var notes: String?
    var userProfile: UserProfile?
    var createdAt: Date
    
    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.measurements = []
        self.mood = .neutral
        self.energy = .medium
        self.waterIntake = 0.0
        self.createdAt = Date()
    }
    
    var totalWorkoutsThisWeek: Int {
        // This would be calculated from workout completion data
        return 0
    }
    
    var weeklyGoalProgress: Double {
        // This would be calculated based on user's weekly goals
        return 0.0
    }
}

@Model
final class BodyMeasurement {
    var id: UUID
    var type: MeasurementType
    var value: Double
    var unit: String
    var date: Date
    
    init(type: MeasurementType, value: Double, unit: String = "cm") {
        self.id = UUID()
        self.type = type
        self.value = value
        self.unit = unit
        self.date = Date()
    }
}

enum MeasurementType: String, CaseIterable, Codable {
    case chest = "Chest"
    case waist = "Waist"
    case hips = "Hips"
    case arms = "Arms"
    case thighs = "Thighs"
    case calves = "Calves"
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .waist: return "figure.core.training"
        case .hips: return "figure.strengthtraining.traditional"
        case .arms: return "figure.strengthtraining.traditional"
        case .thighs: return "figure.walk"
        case .calves: return "figure.walk"
        }
    }
}

enum Mood: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case neutral = "Neutral"
    case low = "Low"
    case poor = "Poor"
    
    var emoji: String {
        switch self {
        case .excellent: return "😄"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .low: return "😔"
        case .poor: return "😢"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .neutral: return .yellow
        case .low: return .orange
        case .poor: return .red
        }
    }
}

enum EnergyLevel: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var icon: String {
        switch self {
        case .high: return "bolt.fill"
        case .medium: return "bolt"
        case .low: return "bolt.slash"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .yellow
        case .medium: return .orange
        case .low: return .red
        }
    }
}

@Model
final class Goal {
    var id: UUID
    var title: String
    var goalDescription: String
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var deadline: Date?
    var isCompleted: Bool
    var goalType: GoalType
    var createdAt: Date
    var userProfile: UserProfile?
    
    init(title: String, description: String, targetValue: Double, unit: String, goalType: GoalType) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.targetValue = targetValue
        self.currentValue = 0.0
        self.unit = unit
        self.isCompleted = false
        self.goalType = goalType
        self.createdAt = Date()
    }
    
    var progress: Double {
        return min(currentValue / targetValue, 1.0)
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
}

enum GoalType: String, CaseIterable, Codable {
    case weightLoss = "Weight Loss"
    case strengthGain = "Strength Gain"
    case endurance = "Endurance"
    case flexibility = "Flexibility"
    case consistency = "Consistency"
    
    var icon: String {
        switch self {
        case .weightLoss: return "scalemass"
        case .strengthGain: return "dumbbell.fill"
        case .endurance: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .consistency: return "calendar"
        }
    }
}
