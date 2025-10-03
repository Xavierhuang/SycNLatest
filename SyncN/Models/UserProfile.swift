import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var birthDate: Date
    var cycleLength: Int? // in days
    var lastPeriodStart: Date?
    var averagePeriodLength: Int? // in days
    var fitnessLevel: FitnessLevel?
    var goals: [FitnessGoal]
    var weeklyFitnessPlan: [WeeklyFitnessPlanEntry]
    var dailyHabits: [DailyHabitEntry]
    var customWorkouts: [CustomWorkout]
    
    // Onboarding data - made optional to avoid migration issues
    var hormonalImbalances: [HormonalImbalance]?
    var birthControlMethods: [BirthControlMethod]?
    var cycleType: CycleType?
    var cycleFlow: CycleFlow?
    var hasRecurringSymptoms: Bool? // Whether user has recurring symptoms
    var lastSymptomsStart: Date?
    var averageSymptomDays: Int?
    
    // Health and nutrition data
    var hasHistoryOfEatingDisorder: Bool = false
    var currentSymptomsString: String?
    
    // Personalization data
    var personalizationData: PersonalizationData?
    
    
    // Cycle phase data from backend
    var currentCyclePhase: CyclePhase?
    var cycleDay: Int?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, birthDate: Date, cycleLength: Int? = nil, averagePeriodLength: Int? = nil, fitnessLevel: FitnessLevel? = nil) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.cycleLength = cycleLength
        self.averagePeriodLength = averagePeriodLength
        self.fitnessLevel = fitnessLevel
        self.goals = []
        self.weeklyFitnessPlan = []
        self.dailyHabits = []
        self.customWorkouts = []
        
        // Initialize onboarding data with no defaults
        self.hormonalImbalances = nil
        self.birthControlMethods = nil
        self.cycleType = nil
        self.cycleFlow = nil
        self.hasRecurringSymptoms = nil
        self.lastSymptomsStart = nil
        self.averageSymptomDays = nil
        
        // Initialize personalization data - will be set after UserProfile is fully initialized
        self.personalizationData = nil
        
        // Initialize cycle phase data with no defaults
        self.currentCyclePhase = nil
        self.cycleDay = nil
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    

    
    // Computed properties for onboarding data with no defaults
    var hormonalImbalancesArray: [HormonalImbalance] {
        return hormonalImbalances ?? []
    }
    
    var birthControlMethodsArray: [BirthControlMethod] {
        return birthControlMethods ?? []
    }
    
    var cycleTypeValue: CycleType? {
        return cycleType
    }
    
    var cycleFlowValue: CycleFlow? {
        return cycleFlow
    }
    
    var averageSymptomDaysValue: Int? {
        return averageSymptomDays
    }
    
    var hasRecurringSymptomsValue: Bool? {
        return hasRecurringSymptoms
    }
    
    // MARK: - Cycle Type Awareness Properties
    
    // Computed property to check if user has moon cycles
    var hasMoonCycles: Bool {
        guard let personalizationData = personalizationData,
              let cycleType = cycleType,
              let useMoonCycle = personalizationData.useMoonCycle else { return false }
        return cycleType == .noPeriod && useMoonCycle
    }
    
    // Computed property to check if user has irregular cycles with widening windows
    var hasIrregularCycles: Bool {
        guard let cycleType = cycleType else { return false }
        return cycleType == .irregular && (personalizationData?.wideningWindow ?? false)
    }
    
    // Computed property to check if user has regular menstrual cycles
    var hasRegularMenstrualCycles: Bool {
        guard let cycleType = cycleType else { return false }
        return cycleType == .regular
    }
    
    // Computed property to get cycle type display name
    var cycleTypeDisplayName: String {
        guard let cycleType = cycleType else { return "Complete onboarding to see your cycle tracking" }
        switch cycleType {
        case .regular: return "Regular Menstrual Cycle"
        case .irregular: return "Irregular Menstrual Cycle"
        case .noPeriod: 
            if hasMoonCycles {
                return "Moon Cycle"
            } else {
                return "Symptomatic Cycle"
            }
        }
    }
    
    // Computed property to get cycle type description
    var cycleTypeDescription: String {
        guard let cycleType = cycleType else { return "Complete onboarding to see your cycle tracking" }
        switch cycleType {
        case .regular: 
            return "Tracking your regular menstrual cycle phases"
        case .irregular: 
            return "Tracking irregular cycles"
        case .noPeriod:
            if hasMoonCycles {
                return "Following the moon cycle for wellness tracking"
            } else {
                return "Tracking symptomatic cycle patterns"
            }
        }
    }
    
    // MARK: - Computed Properties for Array Access
    var currentSymptoms: [String]? {
        get { currentSymptomsString?.isEmpty == true ? nil : currentSymptomsString?.components(separatedBy: ",") }
        set { currentSymptomsString = newValue?.joined(separator: ",") }
    }
}

enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var description: String {
        switch self {
        case .beginner: return "New to fitness or returning after a break"
        case .intermediate: return "Regular exercise routine, comfortable with most activities"
        case .advanced: return "Experienced fitness enthusiast, high intensity workouts"
        }
    }
}

// MARK: - Onboarding Enums
enum HormonalImbalance: String, CaseIterable, Codable {
    case pms = "PMS"
    case pmdd = "PMDD"
    case pcos = "PCOS"
    case endometriosis = "Endometriosis"
    case hypothyroidism = "Hypothyroidism"
    case other = "Other"
    case none = "None"
}

enum BirthControlMethod: String, CaseIterable, Codable {
    case pill = "The pill"
    case copperIUD = "Copper IUD"
    case implant = "Implant"
    case nonHormonal = "Non-hormonal"
    case other = "Other"
    case none = "None"
}

enum CycleType: String, CaseIterable, Codable {
    case regular = "Regular"
    case irregular = "Irregular"
    case noPeriod = "Don't get one"
}

enum CycleFlow: String, CaseIterable, Codable {
    case heavy = "Heavy"
    case regular = "Regular"
    case light = "Light"
    case spotting = "Spotting only"
}

// MARK: - Daily Habit Entry
@Model
final class DailyHabitEntry {
    var id: UUID
    var date: Date
    var completedWorkoutsString: String? // Array of workout titles that were completed
    var completedNutritionHabitsString: String? // Array of nutrition habit names that were completed
    var createdAt: Date
    
    init(date: Date, completedWorkouts: [String]? = nil, completedNutritionHabits: [String]? = nil) {
        self.id = UUID()
        self.date = date
        self.completedWorkoutsString = completedWorkouts?.joined(separator: ",")
        self.completedNutritionHabitsString = completedNutritionHabits?.joined(separator: ",")
        self.createdAt = Date()
    }
    

}

enum FitnessGoal: String, CaseIterable, Codable {
    case weightLoss = "Weight Loss"
    case strengthBuilding = "Strength Building"
    case endurance = "Endurance"
    case flexibility = "Flexibility"
    case stressRelief = "Stress Relief"
    case generalHealth = "General Health"
    
    var icon: String {
        switch self {
        case .weightLoss: return "scalemass"
        case .strengthBuilding: return "dumbbell.fill"
        case .endurance: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .stressRelief: return "brain.head.profile"
        case .generalHealth: return "cross.fill"
        }
    }
}
