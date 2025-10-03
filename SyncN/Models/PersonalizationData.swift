import Foundation
import SwiftData

// MARK: - Fitness Personalization Enums
enum PersonalizationFitnessGoal: String, CaseIterable, Codable {
    case loseWeight = "Lose weight/Reach a healthy weight"
    case increaseFlexibility = "Increase flexibility/mobility"
    case increaseStrength = "Increase strength"
    case toneBody = "Tone my body"
    case trainForEvent = "Train for a specific event/race"
    case haveFun = "Have fun and stay active"
    case improveFitness = "Improve my overall fitness"
}

enum PersonalizationFitnessLevel: String, CaseIterable, Codable {
    case beginner = "Beginner (just starting out)"
    case intermediate = "Intermediate (comfortable with basic exercises)"
    case advanced = "Advanced (very active and fit)"
}

enum WorkoutFrequency: String, CaseIterable, Codable {
    case zeroToOne = "0-1 times"
    case twoToThree = "2-3 times"
    case fourToFive = "4-5 times"
    case sixToSeven = "6-7 times"
    case eightPlus = "8+"
}

enum DesiredWorkoutFrequency: String, CaseIterable, Codable {
    case one = "1 day"
    case two = "2 days"
    case three = "3 days"
    case four = "4 days"
    case five = "5 days"
    case six = "6 days"
    case seven = "7 days"
}

enum PersonalizationWorkoutType: String, CaseIterable, Codable {
    case hiit = "HIIT"
    case yoga = "Yoga"
    case pilates = "Pilates"
    case strength = "Strength"
    case run = "Run"
    case cycle = "Cycle"
    case dance = "Dance"
    case walk = "Walk"
    case freeWeights = "Free weights"
    case sports = "Sports"
}

enum SyncNSupport: String, CaseIterable, Codable {
    case allWorkouts = "All workouts – I want SyncN to provide my full workout plan"
    case someWorkouts = "Some workouts – I'll do a mix of SyncN classes and my own routine"
    case noWorkouts = "No workouts – I'm only interested in cycle-based fitness and nutrition guidance"
}

enum PlanStartChoice: String, CaseIterable, Codable {
    case today = "Today"
    case tomorrow = "Tomorrow"
}

enum WeekDay: String, CaseIterable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    case noPreference = "No preference"
}

// MARK: - Nutrition Personalization Enums
enum NutritionGoal: String, CaseIterable, Codable {
    case healthierHabits = "Develop healthier eating habits"
    case balanceHormones = "Balance my hormones"
    case loseWeight = "Lose excess weight"
    case gainWeight = "Gain healthy weight"
    case improveFoodRelationship = "Improve my relationship with food"
    case reduceCravings = "Reduce cravings/binge eating"
    case increaseEnergy = "Increase energy levels"
}

enum EatingApproach: String, CaseIterable, Codable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case pescatarian = "Pescatarian"
    case glutenFree = "Gluten-free"
    case dairyFree = "Dairy-free"
    case lowCarb = "Low carb"
    case keto = "Keto"
    case paleo = "Paleo"
    case intermittentFasting = "Intermittent fasting"
    case intuitiveEating = "Intuitive eating"
    case macroTracking = "Macro tracking"
}

enum PeriodSymptom: String, CaseIterable, Codable {
    case cramps = "Cramps"
    case moodswings = "Moodswings"
    case anxiety = "Anxiety"
    case bloating = "Bloating"
    case insomnia = "Insomnia"
    case headaches = "Headaches"
    case acne = "Acne"
    case foodCravings = "Food cravings"
}

enum WeightChange: String, CaseIterable, Codable {
    case weightGain = "Weight gain"
    case weightLoss = "Weight loss"
    case na = "n/a"
}

enum EatingDisorderHistory: String, CaseIterable, Codable {
    case yes = "Yes"
    case no = "No"
    case preferNotToShare = "Prefer not to share"
}

enum MealFrequency: String, CaseIterable, Codable {
    case rarely = "Rarely"
    case sometimes = "Sometimes"
    case always = "Always"
}

// MARK: - Injury Tracking Enums
enum InjuryStatus: String, CaseIterable, Codable {
    case past = "Past injury"
    case current = "Current injury"
}

enum InjurySeverity: String, CaseIterable, Codable {
    case none = "None"
    case mild = "Mild"
    case severe = "Severe"
}

// MARK: - Injury Entry Model
struct InjuryEntry: Codable, Identifiable {
    let id: UUID
    var bodyPart: String
    var status: InjuryStatus
    var severity: InjurySeverity
    
    init(bodyPart: String, status: InjuryStatus, severity: InjurySeverity) {
        self.id = UUID()
        self.bodyPart = bodyPart
        self.status = status
        self.severity = severity
    }
}

// MARK: - Personalization Data Model
@Model
final class PersonalizationData {
    var id: UUID
    var userId: UUID
    
    // Fitness Personalization
    var fitnessGoal: PersonalizationFitnessGoal?
    var fitnessGoalsString: String?
    var fitnessLevel: PersonalizationFitnessLevel?
    var workoutFrequency: WorkoutFrequency?
    var desiredWorkoutFrequency: DesiredWorkoutFrequency?
    var favoriteWorkoutsString: String?
    var dislikedWorkoutsString: String?
    var pastInjuries: String? // Keep for backward compatibility
    var injuryEntriesString: String? // JSON string of InjuryEntry array
    var syncNSupport: SyncNSupport?
    var existingWorkouts: String?
    var customWorkoutEntriesString: String? // JSON string of CustomWorkoutEntry array
    var preferredRestDaysString: String?
    var planStartChoice: PlanStartChoice?
    
    // Nutrition Personalization
    var nutritionGoalsString: String?
    var eatingApproachesString: String?
    var breakfastFrequency: MealFrequency?
    var lunchFrequency: MealFrequency?
    var dinnerFrequency: MealFrequency?
    var snacksFrequency: MealFrequency?
    var dessertFrequency: MealFrequency?
    var periodSymptomsString: String?
    var weightChange: WeightChange?
    var eatingDisorderHistory: EatingDisorderHistory?
    var birthDate: Date?
    var birthYear: Int?
    var weight: Double?
    var heightFeet: Int?
    var heightInches: Int?
    
    // Personalization Completion Status
    var cycleCompleted: Bool?
    var fitnessCompleted: Bool?
    var nutritionCompleted: Bool?
    var healthCompleted: Bool?
    
    // Cycle Irregularity
    var wideningWindow: Bool?
    
    // Moon Cycle Support
    var useMoonCycle: Bool?
    
    // UI State Tracking
    var hasSeenBraceletInfo: Bool?
    
    // Race Training Properties
    var raceTrainingEnabled: Bool?
    var raceType: String?
    var raceDate: Date?
    var trainingStartDate: Date?
    var runnerLevel: String?
    var runDaysPerWeek: Int?
    var crossTrainDaysPerWeek: Int?
    var restDaysPerWeek: Int?
    var raceGoal: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Initialize all optional properties to nil (no dummy data)
        self.fitnessGoal = nil
        self.fitnessGoalsString = nil
        self.fitnessLevel = nil
        self.workoutFrequency = nil
        self.desiredWorkoutFrequency = nil
        self.favoriteWorkoutsString = nil
        self.dislikedWorkoutsString = nil
        self.pastInjuries = nil
        self.injuryEntriesString = nil
        self.syncNSupport = nil
        self.existingWorkouts = nil
        self.preferredRestDaysString = nil
        self.nutritionGoalsString = nil
        self.eatingApproachesString = nil
        self.breakfastFrequency = nil
        self.lunchFrequency = nil
        self.dinnerFrequency = nil
        self.snacksFrequency = nil
        self.dessertFrequency = nil
        self.periodSymptomsString = nil
        self.weightChange = nil
        self.eatingDisorderHistory = nil
        self.birthDate = nil
        self.birthYear = nil
        self.weight = nil
        self.heightFeet = nil
        self.heightInches = nil
        self.cycleCompleted = nil
        self.fitnessCompleted = nil
        self.nutritionCompleted = nil
        self.healthCompleted = nil
        self.wideningWindow = nil
        self.useMoonCycle = nil
        self.hasSeenBraceletInfo = nil
        
        // Initialize race training properties
        self.raceTrainingEnabled = nil
        self.raceType = nil
        self.raceDate = nil
        self.trainingStartDate = nil
        self.runnerLevel = nil
        self.runDaysPerWeek = nil
        self.crossTrainDaysPerWeek = nil
        self.restDaysPerWeek = nil
        self.raceGoal = nil
    }
    
    var isFullyPersonalized: Bool {
        return fitnessCompleted == true && nutritionCompleted == true
    }
    
    // MARK: - Custom Workout Entries
    var customWorkoutEntries: [CustomWorkoutEntry] {
        get {
            guard let data = customWorkoutEntriesString?.data(using: .utf8) else { return [] }
            do {
                return try JSONDecoder().decode([CustomWorkoutEntry].self, from: data)
            } catch {
                print("❌ Failed to decode custom workout entries: \(error)")
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                customWorkoutEntriesString = String(data: data, encoding: .utf8)
            } catch {
                print("❌ Failed to encode custom workout entries: \(error)")
                customWorkoutEntriesString = nil
            }
        }
    }
    
    // MARK: - Injury Entries
    var injuryEntries: [InjuryEntry] {
        get {
            guard let data = injuryEntriesString?.data(using: .utf8) else { return [] }
            do {
                return try JSONDecoder().decode([InjuryEntry].self, from: data)
            } catch {
                print("❌ Failed to decode injury entries: \(error)")
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                injuryEntriesString = String(data: data, encoding: .utf8)
            } catch {
                print("❌ Failed to encode injury entries: \(error)")
                injuryEntriesString = nil
            }
        }
    }
    
    // MARK: - Current Injuries for Symptom Tracking
    var currentInjuriesForSymptomTracking: [InjuryEntry] {
        return injuryEntries.filter { injury in
            injury.status == .current || (injury.severity == .mild || injury.severity == .severe)
        }
    }
}
