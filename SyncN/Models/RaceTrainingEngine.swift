import Foundation

// MARK: - Race Training Data Models

struct RaceTrainingPlan {
    let raceType: String
    let raceDate: Date
    let trainingStartDate: Date
    let totalWeeks: Int
    let runnerLevel: String
    let runDaysPerWeek: Int
    let crossTrainDaysPerWeek: Int
    let restDaysPerWeek: Int
    let raceGoal: String
    let weeklyPlans: [WeeklyTrainingPlan]
}

struct WeeklyTrainingPlan {
    let weekNumber: Int
    let phase: TrainingPhase
    let isDownWeek: Bool
    let dailyPlans: [DailyTrainingPlan]
}

struct DailyTrainingPlan {
    let date: Date
    let workoutType: RaceWorkoutType
    let workout: RaceWorkout?
    let cyclePhase: CyclePhase?
    let cycleAdaptations: [String]
}

struct RaceWorkout {
    let type: RaceWorkoutType
    let distance: Double? // in miles
    let duration: Int? // in minutes
    let intensity: WorkoutIntensity
    let description: String
    let instructions: [String]
    let cycleAdaptations: [String]
}

enum TrainingPhase: String, CaseIterable {
    case baseBuilding = "Base Building"
    case intervalWorkouts = "Interval Workouts"
    case speedStrength = "Speed & Strength"
    case taper = "Taper"
    
    var description: String {
        switch self {
        case .baseBuilding:
            return "Build aerobic base with easy runs and cross-training"
        case .intervalWorkouts:
            return "Introduce speed work and tempo runs"
        case .speedStrength:
            return "Focus on race pace and strength training"
        case .taper:
            return "Reduce volume, maintain intensity for race day"
        }
    }
}

enum RaceWorkoutType: String, CaseIterable {
    case easyRun = "Easy Run"
    case tempoRun = "Tempo Run"
    case intervalRun = "Interval Run"
    case longRun = "Long Run"
    case crossTraining = "Cross Training"
    case strengthTraining = "Strength Training"
    case rest = "Rest"
    case recovery = "Recovery"
}

enum WorkoutIntensity: String, CaseIterable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    case veryHard = "Very Hard"
    
    var description: String {
        switch self {
        case .easy:
            return "Conversational pace, 60-70% max heart rate"
        case .moderate:
            return "Comfortable pace, 70-80% max heart rate"
        case .hard:
            return "Challenging pace, 80-90% max heart rate"
        case .veryHard:
            return "Race pace or faster, 90-100% max heart rate"
        }
    }
}

// MARK: - Race Training Engine

class RaceTrainingEngine: ObservableObject {
    static let shared = RaceTrainingEngine()
    
    private var currentTrainingStartDate: Date?
    
    private init() {}
    
    // MARK: - Main Plan Generation
    
    func generateRaceTrainingPlan(
        raceType: String,
        raceDate: Date,
        trainingStartDate: Date,
        runnerLevel: String,
        runDaysPerWeek: Int,
        crossTrainDaysPerWeek: Int,
        restDaysPerWeek: Int,
        raceGoal: String
    ) -> RaceTrainingPlan {
        
        // Store training start date for cycle phase calculations
        self.currentTrainingStartDate = trainingStartDate
        
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: trainingStartDate, to: raceDate).day ?? 0
        let totalWeeks = max(1, daysBetween / 7)
        
        print("🏃‍♀️ GENERATING RACE TRAINING PLAN:")
        print("   Total Weeks: \(totalWeeks)")
        print("   Race Type: \(raceType)")
        print("   Runner Level: \(runnerLevel)")
        
        let weeklyPlans = generateWeeklyPlans(
            totalWeeks: totalWeeks,
            raceType: raceType,
            runnerLevel: runnerLevel,
            runDaysPerWeek: runDaysPerWeek,
            crossTrainDaysPerWeek: crossTrainDaysPerWeek,
            restDaysPerWeek: restDaysPerWeek,
            raceGoal: raceGoal,
            startDate: trainingStartDate
        )
        
        return RaceTrainingPlan(
            raceType: raceType,
            raceDate: raceDate,
            trainingStartDate: trainingStartDate,
            totalWeeks: totalWeeks,
            runnerLevel: runnerLevel,
            runDaysPerWeek: runDaysPerWeek,
            crossTrainDaysPerWeek: crossTrainDaysPerWeek,
            restDaysPerWeek: restDaysPerWeek,
            raceGoal: raceGoal,
            weeklyPlans: weeklyPlans
        )
    }
    
    // MARK: - Weekly Plan Generation
    
    private func generateWeeklyPlans(
        totalWeeks: Int,
        raceType: String,
        runnerLevel: String,
        runDaysPerWeek: Int,
        crossTrainDaysPerWeek: Int,
        restDaysPerWeek: Int,
        raceGoal: String,
        startDate: Date
    ) -> [WeeklyTrainingPlan] {
        
        var weeklyPlans: [WeeklyTrainingPlan] = []
        let calendar = Calendar.current
        
        for week in 1...totalWeeks {
            let phase = determineTrainingPhase(week: week, totalWeeks: totalWeeks)
            let isDownWeek = (week % 4 == 0) // Every 4th week is a down week
            let weekStartDate = calendar.date(byAdding: .weekOfYear, value: week - 1, to: startDate) ?? startDate
            
            let dailyPlans = generateDailyPlans(
                week: week,
                phase: phase,
                isDownWeek: isDownWeek,
                raceType: raceType,
                runnerLevel: runnerLevel,
                runDaysPerWeek: runDaysPerWeek,
                crossTrainDaysPerWeek: crossTrainDaysPerWeek,
                restDaysPerWeek: restDaysPerWeek,
                weekStartDate: weekStartDate
            )
            
            let weeklyPlan = WeeklyTrainingPlan(
                weekNumber: week,
                phase: phase,
                isDownWeek: isDownWeek,
                dailyPlans: dailyPlans
            )
            
            weeklyPlans.append(weeklyPlan)
        }
        
        return weeklyPlans
    }
    
    // MARK: - Phase Determination
    
    private func determineTrainingPhase(week: Int, totalWeeks: Int) -> TrainingPhase {
        let phasePercentage = Double(week) / Double(totalWeeks)
        
        switch phasePercentage {
        case 0.0..<0.4:
            return .baseBuilding
        case 0.4..<0.7:
            return .intervalWorkouts
        case 0.7..<0.9:
            return .speedStrength
        default:
            return .taper
        }
    }
    
    // MARK: - Daily Plan Generation
    
    private func generateDailyPlans(
        week: Int,
        phase: TrainingPhase,
        isDownWeek: Bool,
        raceType: String,
        runnerLevel: String,
        runDaysPerWeek: Int,
        crossTrainDaysPerWeek: Int,
        restDaysPerWeek: Int,
        weekStartDate: Date
    ) -> [DailyTrainingPlan] {
        
        var dailyPlans: [DailyTrainingPlan] = []
        let calendar = Calendar.current
        
        // Create 7 days for the week
        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: day, to: weekStartDate) ?? weekStartDate
            let cyclePhase = determineCyclePhase(for: date)
            
            // Determine workout type for this day
            let workoutType = determineWorkoutType(
                day: day,
                week: week,
                phase: phase,
                isDownWeek: isDownWeek,
                runDaysPerWeek: runDaysPerWeek,
                crossTrainDaysPerWeek: crossTrainDaysPerWeek,
                restDaysPerWeek: restDaysPerWeek
            )
            
            // Generate specific workout
            let workout = generateWorkout(
                type: workoutType,
                week: week,
                phase: phase,
                isDownWeek: isDownWeek,
                raceType: raceType,
                runnerLevel: runnerLevel,
                cyclePhase: cyclePhase
            )
            
            // Generate cycle adaptations
            let cycleAdaptations = generateCycleAdaptations(
                cyclePhase: cyclePhase,
                workoutType: workoutType,
                phase: phase
            )
            
            let dailyPlan = DailyTrainingPlan(
                date: date,
                workoutType: workoutType,
                workout: workout,
                cyclePhase: cyclePhase,
                cycleAdaptations: cycleAdaptations
            )
            
            dailyPlans.append(dailyPlan)
        }
        
        return dailyPlans
    }
    
    // MARK: - Workout Type Determination
    
    private func determineWorkoutType(
        day: Int,
        week: Int,
        phase: TrainingPhase,
        isDownWeek: Bool,
        runDaysPerWeek: Int,
        crossTrainDaysPerWeek: Int,
        restDaysPerWeek: Int
    ) -> RaceWorkoutType {
        
        // Down week: reduce intensity
        if isDownWeek {
            switch day {
            case 0, 2, 4: return .easyRun
            case 1, 3: return .crossTraining
            case 5: return .rest
            default: return .recovery
            }
        }
        
        // Normal week distribution
        let totalWorkouts = runDaysPerWeek + crossTrainDaysPerWeek + restDaysPerWeek
        
        // Validate that we have enough days for the requested workouts
        guard totalWorkouts <= 7 else {
            return .rest // Fallback to rest if too many workouts requested
        }
        
        if day < runDaysPerWeek {
            return .easyRun // Will be modified based on phase
        } else if day < runDaysPerWeek + crossTrainDaysPerWeek {
            return .crossTraining
        } else {
            return .rest
        }
    }
    
    // MARK: - Workout Generation
    
    private func generateWorkout(
        type: RaceWorkoutType,
        week: Int,
        phase: TrainingPhase,
        isDownWeek: Bool,
        raceType: String,
        runnerLevel: String,
        cyclePhase: CyclePhase
    ) -> RaceWorkout? {
        
        switch type {
        case .easyRun:
            return generateEasyRun(week: week, phase: phase, isDownWeek: isDownWeek, raceType: raceType, runnerLevel: runnerLevel, cyclePhase: cyclePhase)
        case .tempoRun:
            return generateTempoRun(week: week, phase: phase, isDownWeek: isDownWeek, raceType: raceType, runnerLevel: runnerLevel, cyclePhase: cyclePhase)
        case .intervalRun:
            return generateIntervalRun(week: week, phase: phase, isDownWeek: isDownWeek, raceType: raceType, runnerLevel: runnerLevel, cyclePhase: cyclePhase)
        case .longRun:
            return generateLongRun(week: week, phase: phase, isDownWeek: isDownWeek, raceType: raceType, runnerLevel: runnerLevel, cyclePhase: cyclePhase)
        case .crossTraining:
            return generateCrossTraining(week: week, phase: phase, isDownWeek: isDownWeek, cyclePhase: cyclePhase)
        case .strengthTraining:
            return generateStrengthTraining(week: week, phase: phase, isDownWeek: isDownWeek, cyclePhase: cyclePhase)
        case .rest:
            return generateRestDay(cyclePhase: cyclePhase)
        case .recovery:
            return generateRecoveryDay(cyclePhase: cyclePhase)
        }
    }
    
    // MARK: - Specific Workout Generators
    
    private func generateEasyRun(week: Int, phase: TrainingPhase, isDownWeek: Bool, raceType: String, runnerLevel: String, cyclePhase: CyclePhase) -> RaceWorkout {
        let baseDistance = getBaseDistance(for: raceType, runnerLevel: runnerLevel)
        let distance = isDownWeek ? baseDistance * 0.8 : baseDistance
        let duration = Int(distance * 10) // 10 minutes per mile average
        
        return RaceWorkout(
            type: .easyRun,
            distance: distance,
            duration: duration,
            intensity: .easy,
            description: "Easy pace run",
            instructions: [
                "Warm up with 5 minutes of easy jogging",
                "Maintain conversational pace throughout",
                "Cool down with 5 minutes of easy jogging"
            ],
            cycleAdaptations: getCycleAdaptations(for: cyclePhase, workoutType: .easyRun)
        )
    }
    
    private func generateTempoRun(week: Int, phase: TrainingPhase, isDownWeek: Bool, raceType: String, runnerLevel: String, cyclePhase: CyclePhase) -> RaceWorkout {
        let baseDistance = getBaseDistance(for: raceType, runnerLevel: runnerLevel)
        let distance = isDownWeek ? baseDistance * 0.8 : baseDistance * 0.7
        let duration = Int(distance * 8) // 8 minutes per mile for tempo
        
        return RaceWorkout(
            type: .tempoRun,
            distance: distance,
            duration: duration,
            intensity: .hard,
            description: "Tempo pace run",
            instructions: [
                "Warm up with 10 minutes of easy jogging",
                "Run at comfortably hard pace (80-85% effort)",
                "Cool down with 10 minutes of easy jogging"
            ],
            cycleAdaptations: getCycleAdaptations(for: cyclePhase, workoutType: .tempoRun)
        )
    }
    
    private func generateIntervalRun(week: Int, phase: TrainingPhase, isDownWeek: Bool, raceType: String, runnerLevel: String, cyclePhase: CyclePhase) -> RaceWorkout {
        let intervals = getIntervalWorkout(for: raceType, week: week, isDownWeek: isDownWeek)
        
        return RaceWorkout(
            type: .intervalRun,
            distance: nil,
            duration: intervals.totalDuration,
            intensity: .veryHard,
            description: "Interval training",
            instructions: intervals.instructions,
            cycleAdaptations: getCycleAdaptations(for: cyclePhase, workoutType: .intervalRun)
        )
    }
    
    private func generateLongRun(week: Int, phase: TrainingPhase, isDownWeek: Bool, raceType: String, runnerLevel: String, cyclePhase: CyclePhase) -> RaceWorkout {
        let baseDistance = getBaseDistance(for: raceType, runnerLevel: runnerLevel)
        let longRunDistance = baseDistance * 1.5
        let distance = isDownWeek ? longRunDistance * 0.8 : longRunDistance
        let duration = Int(distance * 10) // 10 minutes per mile average
        
        return RaceWorkout(
            type: .longRun,
            distance: distance,
            duration: duration,
            intensity: .easy,
            description: "Long endurance run",
            instructions: [
                "Warm up with 10 minutes of easy jogging",
                "Run at easy, conversational pace",
                "Focus on building endurance",
                "Cool down with 10 minutes of easy jogging"
            ],
            cycleAdaptations: getCycleAdaptations(for: cyclePhase, workoutType: .longRun)
        )
    }
    
    private func generateCrossTraining(week: Int, phase: TrainingPhase, isDownWeek: Bool, cyclePhase: CyclePhase) -> RaceWorkout {
        let activities = ["Cycling", "Swimming", "Elliptical", "Rowing"]
        let activity = activities.randomElement() ?? "Cycling"
        let duration = isDownWeek ? 30 : 45
        
        return RaceWorkout(
            type: .crossTraining,
            distance: nil,
            duration: duration,
            intensity: .moderate,
            description: "\(activity) cross-training session",
            instructions: [
                "Warm up with 5 minutes of easy movement",
                "Maintain moderate intensity throughout",
                "Focus on different muscle groups than running",
                "Cool down with 5 minutes of easy movement"
            ],
            cycleAdaptations: getCycleAdaptations(for: cyclePhase, workoutType: .crossTraining)
        )
    }
    
    private func generateStrengthTraining(week: Int, phase: TrainingPhase, isDownWeek: Bool, cyclePhase: CyclePhase) -> RaceWorkout {
        let duration = isDownWeek ? 20 : 30
        
        return RaceWorkout(
            type: .strengthTraining,
            distance: nil,
            duration: duration,
            intensity: .moderate,
            description: "Strength training session",
            instructions: [
                "Warm up with 5 minutes of dynamic stretching",
                "Focus on functional movements",
                "Include core strengthening exercises",
                "Cool down with 5 minutes of stretching"
            ],
            cycleAdaptations: getCycleAdaptations(for: cyclePhase, workoutType: .strengthTraining)
        )
    }
    
    private func generateRestDay(cyclePhase: CyclePhase) -> RaceWorkout {
        return RaceWorkout(
            type: .rest,
            distance: nil,
            duration: nil,
            intensity: .easy,
            description: "Complete rest day",
            instructions: [
                "Take a complete rest from exercise",
                "Focus on recovery and nutrition",
                "Light stretching if desired"
            ],
            cycleAdaptations: getCycleAdaptations(for: cyclePhase, workoutType: .rest)
        )
    }
    
    private func generateRecoveryDay(cyclePhase: CyclePhase) -> RaceWorkout {
        return RaceWorkout(
            type: .recovery,
            distance: nil,
            duration: 20,
            intensity: .easy,
            description: "Active recovery day",
            instructions: [
                "Light movement and stretching",
                "Focus on mobility and flexibility",
                "Gentle yoga or walking if desired"
            ],
            cycleAdaptations: getCycleAdaptations(for: cyclePhase, workoutType: .recovery)
        )
    }
    
    // MARK: - Helper Methods
    
    private func getBaseDistance(for raceType: String, runnerLevel: String) -> Double {
        switch raceType {
        case "5K":
            return runnerLevel == "Beginner" ? 2.0 : 3.0
        case "10K":
            return runnerLevel == "Beginner" ? 3.0 : 5.0
        case "Half Marathon":
            return runnerLevel == "Beginner" ? 4.0 : 6.0
        case "Marathon":
            return runnerLevel == "Beginner" ? 6.0 : 8.0
        default:
            return 3.0
        }
    }
    
    private func getIntervalWorkout(for raceType: String, week: Int, isDownWeek: Bool) -> (totalDuration: Int, instructions: [String]) {
        let baseIntervals = isDownWeek ? 4 : 6
        let intervalDuration = 3 // minutes
        let restDuration = 2 // minutes
        
        let totalDuration = (baseIntervals * intervalDuration) + ((baseIntervals - 1) * restDuration) + 20 // warm up + cool down
        
        let instructions = [
            "Warm up with 10 minutes of easy jogging",
            "Run \(baseIntervals) x \(intervalDuration) minutes at 5K pace",
            "Rest \(restDuration) minutes between intervals",
            "Cool down with 10 minutes of easy jogging"
        ]
        
        return (totalDuration, instructions)
    }
    
    private func determineCyclePhase(for date: Date) -> CyclePhase {
        // This should integrate with the user's actual cycle data
        // For now, we'll use a simple calculation based on the training start date
        // In a real implementation, this would query the user's cycle data
        
        guard let trainingStartDate = currentTrainingStartDate else {
            return .follicular
        }
        
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: trainingStartDate, to: date).day ?? 0
        
        // Simple cycle simulation (28-day cycle)
        let cycleDay = (daysSinceStart % 28) + 1
        
        switch cycleDay {
        case 1...5:
            return .menstrual
        case 6...13:
            return .follicular
        case 14...16:
            return .ovulatory
        case 17...28:
            return .luteal
        default:
            return .follicular
        }
    }
    
    private func generateCycleAdaptations(cyclePhase: CyclePhase, workoutType: RaceWorkoutType, phase: TrainingPhase) -> [String] {
        var adaptations: [String] = []
        
        switch cyclePhase {
        case .menstrual:
            adaptations.append("Reduce intensity by 10-20%")
            adaptations.append("Focus on gentle movement and recovery")
            adaptations.append("Increase hydration and iron-rich foods")
            adaptations.append("Ideal time for rest weeks - plan down weeks during menstrual phase")
        case .follicular:
            adaptations.append("Great time for high-intensity workouts")
            adaptations.append("Focus on building strength and speed")
            adaptations.append("Optimal time for new training challenges")
        case .ovulatory:
            adaptations.append("Peak performance phase")
            adaptations.append("Ideal for race pace workouts")
            adaptations.append("Focus on technique and form")
        case .luteal:
            adaptations.append("Reduce intensity during second half")
            adaptations.append("Focus on endurance and base building")
            adaptations.append("Increase recovery time between sessions")
            adaptations.append("Consider scheduling rest weeks during late luteal phase")
        case .menstrualMoon:
            adaptations.append("Reduce intensity by 10-20%")
            adaptations.append("Focus on gentle movement and recovery")
            adaptations.append("Increase hydration and iron-rich foods")
            adaptations.append("Ideal time for rest weeks and recovery")
        case .follicularMoon:
            adaptations.append("Great time for high-intensity workouts")
            adaptations.append("Focus on building strength and speed")
            adaptations.append("Optimal time for new training challenges")
        case .ovulatoryMoon:
            adaptations.append("Peak performance phase")
            adaptations.append("Ideal for race pace workouts")
            adaptations.append("Focus on technique and form")
        case .lutealMoon:
            adaptations.append("Reduce intensity during second half")
            adaptations.append("Focus on endurance and base building")
            adaptations.append("Increase recovery time between sessions")
            adaptations.append("Consider rest weeks during this phase")
        }
        
        return adaptations
    }
    
    private func getCycleAdaptations(for cyclePhase: CyclePhase, workoutType: RaceWorkoutType) -> [String] {
        return generateCycleAdaptations(cyclePhase: cyclePhase, workoutType: workoutType, phase: .baseBuilding)
    }
}

