import Foundation
import SwiftData

// MARK: - Day Type Enum
enum DayType {
    case workout
    case meditation
    case rest
}

// MARK: - Swift Fitness Recommendation Engine
class SwiftFitnessRecommendationEngine {
    static let shared = SwiftFitnessRecommendationEngine()
    
    private let fitnessClassesManager = FitnessClassesManager.shared
    private let workoutData = WorkoutData.getSampleWorkouts()
    
    private init() {
        print("🔍 SwiftFitnessRecommendationEngine initialized")
        print("🔍 FitnessClassesManager has \(fitnessClassesManager.getAllClasses().count) classes")
    }
    
    // MARK: - Main Fitness Plan Generation
    func generateWeeklyFitnessPlan(
        for userProfile: UserProfile,
        startDate: Date,
        userPreferences: UserPreferences
    ) -> [WeeklyFitnessPlanEntry] {
        
        
        let calendar = Calendar.current
        var weeklyPlan: [WeeklyFitnessPlanEntry] = []
        
        // Check if fitness classes are loaded
        let allClasses = fitnessClassesManager.getAllClasses()
        print("🎯 SwiftFitnessEngine: Loaded \(allClasses.count) fitness classes")
        
        if allClasses.isEmpty {
            print("❌ SwiftFitnessEngine: No fitness classes loaded - this will cause issues!")
            return []
        }
        
        // NEW LOGIC: Use max workouts per week, ensure at least 1 rest day per week
        // MEDITATIONS REPLACE REST DAYS - they don't count as workouts
        let maxWorkoutsPerWeek = userPreferences.workoutFrequency
        let adjustedWorkoutsPerWeek = min(maxWorkoutsPerWeek, 6) // Max 6, ensure 1 rest day minimum
        let totalWorkoutDays = adjustedWorkoutsPerWeek * 2 // 2 weeks
        let totalMeditationDays = 2 // 1 meditation per week = 2 for 2 weeks (replaces rest days)
        let totalRestDays = 14 - totalWorkoutDays - totalMeditationDays
        
        
        // Calculate day type positions with user preferences
        let dayTypePositions = calculateDayTypePositions(
            workoutDays: totalWorkoutDays,
            meditationDays: totalMeditationDays,
            restDays: totalRestDays,
            userPreferences: userPreferences,
            startDate: startDate
        )
        print("🎯 Day type distribution: \(dayTypePositions)")
        
        // Track used classes to avoid duplicates within a week
        var usedClassesThisWeek: [String] = []
        var currentWeek = 0
        
        // Track favorite workouts to ensure at least one per week
        var favoriteWorkoutsUsedThisWeek: [String] = []
        
        // Generate plan for each day
        for dayOffset in 0..<14 {
            print("🎯 SwiftFitnessEngine: Processing day \(dayOffset) of 14...")
            
            let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
            let dayType = dayTypePositions[dayOffset] ?? .rest
            
            // Reset used classes for new week
            if dayOffset == 7 {
                usedClassesThisWeek = []
                favoriteWorkoutsUsedThisWeek = []
                currentWeek += 1
                print("🎯 SwiftFitnessEngine: Starting week 2, reset used classes and favorite workouts")
            }
            
            print("🎯 Day \(dayOffset): \(currentDate) - Day type: \(dayType)")
            
            // Get current cycle phase for this date
            let currentPhase = getCurrentCyclePhase(for: userProfile, date: currentDate)
            print("🎯 Day \(dayOffset): Current phase: \(currentPhase)")
            
            switch dayType {
            case .workout:
                // Generate workout for this day
                if let workout = generateWorkoutForDay(
                    dayOffset: dayOffset,
                    phase: currentPhase,
                    userPreferences: userPreferences,
                    availableClasses: fitnessClassesManager.getAllClasses(),
                    usedClasses: usedClassesThisWeek,
                    favoriteWorkoutsUsed: favoriteWorkoutsUsedThisWeek
                ) {
                    // Track this class as used
                    usedClassesThisWeek.append(workout.className)
                    
                    // Track if this is a favorite workout
                    if isFavoriteWorkout(workout, userPreferences: userPreferences) {
                        favoriteWorkoutsUsedThisWeek.append(workout.className)
                        print("🎯 Day \(dayOffset): Added favorite workout: \(workout.className)")
                    }
                    
                    // Find matching workout data with media URLs
                    let matchingWorkout = self.findMatchingWorkoutData(for: workout.className)
                    
                    let planEntry = WeeklyFitnessPlanEntry(
                        date: currentDate,
                        workoutTitle: workout.className,
                        workoutDescription: matchingWorkout?.workoutDescription ?? "Recommended workout for \(currentPhase) phase",
                        duration: parseDuration(workout.duration),
                        workoutType: mapWorkoutType(workout.types.first ?? "Cardio"),
                        cyclePhase: mapCyclePhase(currentPhase),
                        difficulty: mapDifficulty(workout.intensity),
                        equipment: workout.equipment ?? [],
                        benefits: workout.benefits ?? [],
                        instructor: workout.instructor,
                        audioURL: matchingWorkout?.audioURL,
                        videoURL: matchingWorkout?.videoURL,
                        isVideo: matchingWorkout?.isVideo ?? false,
                        injuries: nil,
                        status: WorkoutStatus.suggested
                    )
                    weeklyPlan.append(planEntry)
                    print("🎯 Day \(dayOffset): Added workout: \(workout.className)")
                } else {
<<<<<<< HEAD
                    // Fallback to rest day if no workout found
                    let restEntry = createRestDayEntry(date: currentDate, phase: currentPhase)
                    weeklyPlan.append(restEntry)
                    print("🎯 Day \(dayOffset): No workout found, added rest day")
=======
                    // Try to find a workout by relaxing restrictions
                    print("🎯 Day \(dayOffset): No workout found with current restrictions, trying fallback options")
                    
                    // Try to get any available class for this phase (ignoring used classes)
                    let allPhaseClasses = fitnessClassesManager.getClassesForPhase(currentPhase).filter { !$0.types.contains("Meditation") }
                    
                    if let fallbackClass = allPhaseClasses.first {
                        // Create a workout entry from the first available class
                        let planEntry = WeeklyFitnessPlanEntry(
                            date: currentDate,
                            workoutTitle: fallbackClass.className,
                            workoutDescription: "Workout for \(currentPhase) phase",
                            duration: Int(fallbackClass.duration) ?? 30,
                            workoutType: mapWorkoutType(fallbackClass.types.first ?? "Workout"),
                            cyclePhase: mapCyclePhase(currentPhase),
                            difficulty: mapDifficulty(fallbackClass.intensity),
                            equipment: fallbackClass.equipment ?? [],
                            benefits: fallbackClass.benefits ?? [],
                            instructor: fallbackClass.instructor,
                            audioURL: nil,
                            videoURL: nil,
                            isVideo: false,
                            injuries: nil,
                            status: WorkoutStatus.suggested
                        )
                        weeklyPlan.append(planEntry)
                        print("🎯 Day \(dayOffset): Added fallback workout (reusing class): \(fallbackClass.className)")
                    } else {
                        // Final fallback to rest day if absolutely no workout found
                        let restEntry = createRestDayEntry(date: currentDate, phase: currentPhase)
                        weeklyPlan.append(restEntry)
                        print("🎯 Day \(dayOffset): No workout found even with fallback, added rest day")
                    }
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
                }
                
            case .meditation:
                // Generate meditation for this day
                if let meditation = generateMeditationForDay(
                    dayOffset: dayOffset,
                    phase: currentPhase,
                    userPreferences: userPreferences
                ) {
                    // Find matching workout data with media URLs
                    let matchingWorkout = self.findMatchingWorkoutData(for: meditation.className)
                    
                    let planEntry = WeeklyFitnessPlanEntry(
                        date: currentDate,
                        workoutTitle: meditation.className,
                        workoutDescription: matchingWorkout?.workoutDescription ?? "Recommended meditation for \(currentPhase) phase",
                        duration: parseDuration(meditation.duration),
                        workoutType: .meditation,
                        cyclePhase: mapCyclePhase(currentPhase),
                        difficulty: mapDifficulty(meditation.intensity),
                        equipment: meditation.equipment ?? [],
                        benefits: meditation.benefits ?? [],
                        instructor: meditation.instructor,
                        audioURL: matchingWorkout?.audioURL,
                        videoURL: matchingWorkout?.videoURL,
                        isVideo: matchingWorkout?.isVideo ?? false,
                        injuries: nil,
                        status: WorkoutStatus.suggested
                    )
                    weeklyPlan.append(planEntry)
                    print("🎯 Day \(dayOffset): Added meditation: \(meditation.className)")
                } else {
                    // Fallback to rest day if no meditation found
                    let restEntry = createRestDayEntry(date: currentDate, phase: currentPhase)
                    weeklyPlan.append(restEntry)
                    print("🎯 Day \(dayOffset): No meditation found, added rest day")
                }
                
            case .rest:
                // Scheduled rest day
                let restEntry = createRestDayEntry(date: currentDate, phase: currentPhase)
                weeklyPlan.append(restEntry)
                print("🎯 Day \(dayOffset): Scheduled rest day")
            }
        }
        
        print("🎯 SwiftFitnessEngine: Generated \(weeklyPlan.count) entries for 14-day plan")
        print("🎯 SwiftFitnessEngine: Fitness plan generation completed successfully!")
<<<<<<< HEAD
=======
        
        // Save the plan to JSON file for debugging
        savePlanToJSON(weeklyPlan, userProfile: userProfile, userPreferences: userPreferences, startDate: startDate)
        
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
        return weeklyPlan
    }
    
    // MARK: - Day Type Distribution
    private func calculateDayTypePositions(
        workoutDays: Int,
        meditationDays: Int,
        restDays: Int,
        userPreferences: UserPreferences,
        startDate: Date
    ) -> [Int: DayType] {
<<<<<<< HEAD
=======
        print("🎯 STARTING DAY TYPE DISTRIBUTION:")
        print("🎯 Target: \(workoutDays) workouts, \(meditationDays) meditations, \(restDays) rest days")
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
        var dayTypes: [Int: DayType] = [:]
        
        // Create arrays for each day type
        var workoutPositions: [Int] = []
        var meditationPositions: [Int] = []
        var restPositions: [Int] = []
        
        // Get preferred rest days and convert to day offsets
        let preferredRestDayOffsets = getPreferredRestDayOffsets(
            preferredRestDays: userPreferences.preferredRestDays,
            startDate: startDate
        )
        
        print("🎯 User preferred rest days: \(userPreferences.preferredRestDays)")
        print("🎯 Preferred rest day offsets: \(preferredRestDayOffsets)")
        print("🎯 Plan start choice: \(userPreferences.planStartChoice ?? "nil")")
        
        // STEP 1: Handle plan start choice FIRST (highest priority)
        var targetStartDay: Int? = nil
        if let planStartChoice = userPreferences.planStartChoice {
            switch planStartChoice {
            case "Today":
                targetStartDay = 0
            case "Tomorrow":
                targetStartDay = 1
            default:
                targetStartDay = 0 // Default to today
            }
            print("🎯 Plan start choice: \(planStartChoice) -> Target day: \(targetStartDay!)")
        }
        
<<<<<<< HEAD
        // STEP 2: Distribute workout days evenly, but avoid preferred rest days and target start day
        if workoutDays > 0 {
            let workoutSpacing = 14.0 / Double(workoutDays)
            for i in 0..<workoutDays {
                let position = Int(Double(i) * workoutSpacing)
                workoutPositions.append(position)
            }
=======
        // STEP 2: Distribute workout days evenly across BOTH weeks (3 per week for 6 total)
        if workoutDays > 0 {
            // For even distribution, aim for exactly 3 workouts per week
            let targetWorkoutsPerWeek = 3
            
            // Week 1: days 0-6 (aim for 3 workouts)
            let week1Positions = [0, 2, 4] // Spread evenly: Fri, Sun, Tue
            for position in week1Positions {
                if position >= 0 && position < 7 && workoutPositions.count < workoutDays {
                    workoutPositions.append(position)
                }
            }
            
            // Week 2: days 7-13 (aim for 3 workouts)  
            let week2Positions = [7, 9, 11] // Spread evenly: Fri, Sun, Tue (7 days later)
            for position in week2Positions {
                if position >= 7 && position < 14 && workoutPositions.count < workoutDays {
                    workoutPositions.append(position)
                }
            }
            
            print("🎯 Initial workout positions (Week 1: 3, Week 2: 3): \(workoutPositions)")
            print("🎯 Week 1 workouts: days \(workoutPositions.filter { $0 < 7 })")
            print("🎯 Week 2 workouts: days \(workoutPositions.filter { $0 >= 7 })")
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
        }
        
        // STEP 3: Distribute meditation days evenly, but avoid preferred rest days and target start day
        if meditationDays > 0 {
            let meditationSpacing = 14.0 / Double(meditationDays)
            print("🎯 Meditation distribution: \(meditationDays) meditations, spacing: \(meditationSpacing)")
            for i in 0..<meditationDays {
                let position = Int(Double(i) * meditationSpacing)
                meditationPositions.append(position)
                print("🎯 Added meditation to day \(position)")
            }
            print("🎯 Initial meditation positions: \(meditationPositions)")
        }
        
        // STEP 4: Fill remaining positions with rest days
        for day in 0..<14 {
            if !workoutPositions.contains(day) && !meditationPositions.contains(day) {
                restPositions.append(day)
            }
        }
        
<<<<<<< HEAD
        // STEP 5: Ensure preferred rest days are actually rest days
        for preferredDay in preferredRestDayOffsets {
            if preferredDay < 14 {
=======
        // STEP 5: Ensure preferred rest days are actually rest days (but maintain workout count)
        for preferredDay in preferredRestDayOffsets {
            if preferredDay < 14 {
                let wouldRemoveWorkout = workoutPositions.contains(preferredDay)
                let currentWorkoutCount = workoutPositions.count
                
                // Only enforce rest day if we can maintain the target workout count
                if wouldRemoveWorkout && currentWorkoutCount <= workoutDays {
                    print("🎯 Skipping preferred rest day \(preferredDay) to maintain workout target (\(currentWorkoutCount) workouts needed)")
                    continue
                }
                
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
                // Remove from workout/meditation positions if present
                workoutPositions.removeAll { $0 == preferredDay }
                meditationPositions.removeAll { $0 == preferredDay }
                
                // Add to rest positions if not already there
                if !restPositions.contains(preferredDay) {
                    restPositions.append(preferredDay)
                }
                
                print("🎯 Ensured day \(preferredDay) is a rest day (user preference)")
            }
        }
        
<<<<<<< HEAD
=======
        // STEP 5.5: Add missing workouts if we don't have enough
        let currentWorkoutCount = workoutPositions.count
        if currentWorkoutCount < workoutDays {
            let missingWorkouts = workoutDays - currentWorkoutCount
            print("🎯 Need to add \(missingWorkouts) more workouts to reach target of \(workoutDays)")
            
            // Find available days that are not meditation days, prioritizing non-preferred rest days
            var availableDays: [Int] = []
            var preferredRestDays: [Int] = []
            
            for day in 0..<14 {
                if !workoutPositions.contains(day) && !meditationPositions.contains(day) {
                    if preferredRestDayOffsets.contains(day) {
                        preferredRestDays.append(day)
                    } else {
                        availableDays.append(day)
                    }
                }
            }
            
            // First, try to add workouts to non-preferred rest days
            var workoutsAdded = 0
            for i in 0..<min(missingWorkouts, availableDays.count) {
                let newWorkoutDay = availableDays[i]
                workoutPositions.append(newWorkoutDay)
                restPositions.removeAll { $0 == newWorkoutDay }
                print("🎯 Added workout to day \(newWorkoutDay) to reach target count")
                workoutsAdded += 1
            }
            
            // If we still need more workouts, override preferred rest days
            let stillMissing = missingWorkouts - workoutsAdded
            if stillMissing > 0 {
                print("🎯 Still need \(stillMissing) more workouts, overriding preferred rest days")
                for i in 0..<min(stillMissing, preferredRestDays.count) {
                    let newWorkoutDay = preferredRestDays[i]
                    workoutPositions.append(newWorkoutDay)
                    restPositions.removeAll { $0 == newWorkoutDay }
                    print("🎯 Added workout to preferred rest day \(newWorkoutDay) to reach target count")
                }
            }
        }
        
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
        // STEP 6: Ensure target start day is a workout (highest priority)
        if let targetDay = targetStartDay, workoutDays > 0 {
            print("🎯 FORCING day \(targetDay) to be a workout (start choice: \(userPreferences.planStartChoice ?? "nil"))")
            
            // Check if target day was originally a meditation
            let wasMeditationDay = meditationPositions.contains(targetDay)
            
            // Remove target day from any other category
            workoutPositions.removeAll { $0 == targetDay }
            meditationPositions.removeAll { $0 == targetDay }
            restPositions.removeAll { $0 == targetDay }
            
            // Add target day as workout
            workoutPositions.append(targetDay)
            
<<<<<<< HEAD
            // If we removed a meditation day, we need to add it back elsewhere to maintain 1 meditation per week
            if wasMeditationDay && meditationPositions.count < meditationDays {
                print("🎯 Target day \(targetDay) was a meditation day, need to re-add meditation elsewhere")
                
                // Try to find a suitable day for meditation (preferably in the same week)
                let targetWeek = targetDay < 7 ? 0 : 1
                let weekStart = targetWeek * 7
                let weekEnd = weekStart + 7
                
                // First, try to find a day in the same week
                var foundMeditationDay = false
                for day in weekStart..<weekEnd {
                    if !workoutPositions.contains(day) && 
                       !preferredRestDayOffsets.contains(day) && 
                       !meditationPositions.contains(day) {
                        meditationPositions.append(day)
                        print("🎯 Added meditation to day \(day) in same week to maintain 1 meditation per week")
=======
            // If we removed a meditation day, we need to add it back elsewhere to maintain correct meditation count
            if wasMeditationDay && meditationPositions.count < meditationDays {
                print("🎯 Target day \(targetDay) was a meditation day, need to re-add meditation elsewhere")
                
                // Find a suitable day for meditation that's not a preferred rest day or workout day
                var foundMeditationDay = false
                for day in 0..<14 {
                    if !workoutPositions.contains(day) && 
                       !preferredRestDayOffsets.contains(day) && 
                       !meditationPositions.contains(day) &&
                       !restPositions.contains(day) {
                        meditationPositions.append(day)
                        // Remove from rest positions if it was there
                        restPositions.removeAll { $0 == day }
                        print("🎯 Added meditation to day \(day) to maintain correct meditation count")
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
                        foundMeditationDay = true
                        break
                    }
                }
                
<<<<<<< HEAD
                // If no suitable day in same week, try the other week
                if !foundMeditationDay {
                    let otherWeekStart = targetWeek == 0 ? 7 : 0
                    let otherWeekEnd = otherWeekStart + 7
                    for day in otherWeekStart..<otherWeekEnd {
                        if !workoutPositions.contains(day) && 
                           !preferredRestDayOffsets.contains(day) && 
                           !meditationPositions.contains(day) {
                            meditationPositions.append(day)
                            print("🎯 Added meditation to day \(day) in other week to maintain 1 meditation per week")
=======
                // If no suitable day found, try to replace a rest day that's not preferred
                if !foundMeditationDay {
                    for day in 0..<14 {
                        if restPositions.contains(day) && !preferredRestDayOffsets.contains(day) {
                            restPositions.removeAll { $0 == day }
                            meditationPositions.append(day)
                            print("🎯 Replaced rest day \(day) with meditation to maintain correct count")
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
                            break
                        }
                    }
                }
            }
            
            // If we now have too many workouts, remove one and make it rest
            if workoutPositions.count > workoutDays {
<<<<<<< HEAD
                if let extraWorkoutDay = workoutPositions.first(where: { $0 != targetDay }) {
=======
                if let extraWorkoutDay = workoutPositions.first(where: { $0 != targetDay && !preferredRestDayOffsets.contains($0) }) {
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
                    workoutPositions.removeAll { $0 == extraWorkoutDay }
                    if !restPositions.contains(extraWorkoutDay) {
                        restPositions.append(extraWorkoutDay)
                    }
                    print("🎯 Moved day \(extraWorkoutDay) to rest to make room for target start day \(targetDay)")
                }
            }
            
            print("🎯 Ensured day \(targetDay) is a workout (start choice preference)")
        }
        
        // Assign day types
        for position in workoutPositions {
            dayTypes[position] = .workout
        }
        for position in meditationPositions {
            dayTypes[position] = .meditation
        }
        for position in restPositions {
            dayTypes[position] = .rest
        }
        
        // DEBUG: Print final day type distribution
        print("🎯 FINAL DAY TYPE DISTRIBUTION:")
        var workoutCount = 0
        var meditationCount = 0
        var restCount = 0
        for day in 0..<14 {
            let dayType = dayTypes[day] ?? .rest
            print("🎯   Day \(day): \(dayType)")
            switch dayType {
            case .workout: workoutCount += 1
            case .meditation: meditationCount += 1
            case .rest: restCount += 1
            }
        }
        print("🎯 FINAL COUNTS: \(workoutCount) workouts, \(meditationCount) meditations, \(restCount) rest days")
        print("🎯 EXPECTED: \(workoutDays) workouts, \(meditationDays) meditations, \(restDays) rest days")
        
<<<<<<< HEAD
=======
        // DEBUG: Show exact comparison
        print("🎯 RECOVERY CHECK: workoutCount (\(workoutCount)) < workoutDays (\(workoutDays)) = \(workoutCount < workoutDays)")
        
        // FINAL RECOVERY: Ensure we have the correct workout count AND even distribution
        if workoutCount < workoutDays {
            let missingWorkouts = workoutDays - workoutCount
            print("🎯 FINAL RECOVERY: Need to add \(missingWorkouts) more workouts to reach target")
            
            // Count current workouts per week
            var week1Workouts = 0
            var week2Workouts = 0
            for day in 0..<14 {
                if dayTypes[day] == .workout {
                    if day < 7 {
                        week1Workouts += 1
                    } else {
                        week2Workouts += 1
                    }
                }
            }
            
            print("🎯 FINAL RECOVERY: Current distribution - Week 1: \(week1Workouts), Week 2: \(week2Workouts)")
            
            // Find rest days that can be converted, prioritizing the week with fewer workouts
            var week1RestDays: [Int] = []
            var week2RestDays: [Int] = []
            
            for day in 0..<14 {
                if dayTypes[day] == .rest {
                    if day < 7 {
                        week1RestDays.append(day)
                    } else {
                        week2RestDays.append(day)
                    }
                }
            }
            
            // Convert rest days to workouts, prioritizing even distribution
            var workoutsToAdd = missingWorkouts
            
            // If week 2 has fewer workouts, prioritize adding to week 2
            if week2Workouts < week1Workouts && workoutsToAdd > 0 {
                if let dayToConvert = week2RestDays.first {
                    dayTypes[dayToConvert] = .workout
                    print("🎯 FINAL RECOVERY: Converted rest day \(dayToConvert) to workout (Week 2 balance)")
                    workoutsToAdd -= 1
                    week2Workouts += 1
                    // Remove from available rest days to avoid double-conversion
                    week2RestDays.removeFirst()
                }
            }
            
            // Add remaining workouts to any available rest days
            let allRestDays = week1RestDays + week2RestDays
            var remainingRestDays = allRestDays
            
            for _ in 0..<min(workoutsToAdd, remainingRestDays.count) {
                if let dayToConvert = remainingRestDays.first {
                    if dayTypes[dayToConvert] == .rest { // Double-check it's still a rest day
                        dayTypes[dayToConvert] = .workout
                        print("🎯 FINAL RECOVERY: Converted rest day \(dayToConvert) to workout")
                        remainingRestDays.removeFirst() // Remove to avoid double-conversion
                    }
                }
            }
            
            // Update the final counts
            workoutCount = 0
            meditationCount = 0
            restCount = 0
            for day in 0..<14 {
                let dayType = dayTypes[day] ?? .rest
                switch dayType {
                case .workout: workoutCount += 1
                case .meditation: meditationCount += 1
                case .rest: restCount += 1
                }
            }
            print("🎯 CORRECTED FINAL COUNTS: \(workoutCount) workouts, \(meditationCount) meditations, \(restCount) rest days")
        }
        
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
        return dayTypes
    }
    
    // MARK: - Helper Methods for Day Calculation
    private func getPreferredRestDayOffsets(
        preferredRestDays: [String],
        startDate: Date
    ) -> [Int] {
        let calendar = Calendar.current
        var offsets: [Int] = []
        
        for dayName in preferredRestDays {
            let dayOfWeek = getDayOfWeek(from: dayName)
            if let dayOfWeek = dayOfWeek {
                // Find the first occurrence of this day in the 14-day period
                for dayOffset in 0..<14 {
                    let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
                    let weekday = calendar.component(.weekday, from: date)
                    
                    // Convert weekday to our day format (1=Sunday, 2=Monday, etc.)
                    if weekday == dayOfWeek {
                        offsets.append(dayOffset)
                        break // Only take the first occurrence in the first week
                    }
                }
                
                // Also find the second occurrence in the second week
                for dayOffset in 7..<14 {
                    let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
                    let weekday = calendar.component(.weekday, from: date)
                    
                    if weekday == dayOfWeek {
                        offsets.append(dayOffset)
                        break
                    }
                }
            }
        }
        
        return offsets
    }
    
    private func getDayOfWeek(from dayName: String) -> Int? {
        switch dayName.lowercased() {
        case "sunday", "sun":
            return 1
        case "monday", "mon":
            return 2
        case "tuesday", "tue", "tues":
            return 3
        case "wednesday", "wed":
            return 4
        case "thursday", "thu", "thur", "thurs":
            return 5
        case "friday", "fri":
            return 6
        case "saturday", "sat":
            return 7
        default:
            return nil
        }
    }
    
    // MARK: - Meditation Generation
    private func generateMeditationForDay(
        dayOffset: Int,
        phase: String,
        userPreferences: UserPreferences
    ) -> FitnessClassData? {
        
        // Filter classes to only meditation types
        let meditationClasses = fitnessClassesManager.getAllClasses().filter { fitnessClass in
            fitnessClass.types.contains { $0.lowercased().contains("meditation") }
        }
        
        print("🎯 Day \(dayOffset): Found \(meditationClasses.count) meditation classes")
        print("🎯 Day \(dayOffset): Looking for meditations for phase: '\(phase)'")
        
        // STRICT PHASE FILTERING: Only use phase-specific meditations
        var filteredClasses = meditationClasses.filter { fitnessClass in
            // Check if this meditation is specifically for the current phase
            fitnessClass.phases.contains { $0.lowercased() == phase.lowercased() }
        }
        
        print("🎯 Day \(dayOffset): Phase-specific meditations found: \(filteredClasses.count)")
        for meditation in filteredClasses {
            print("🎯   - \(meditation.className) (phases: \(meditation.phases))")
        }
        
        // If no phase-specific meditations, fall back to "all" meditations
        if filteredClasses.isEmpty {
            print("🎯 Day \(dayOffset): No phase-specific meditations, falling back to 'all' meditations")
            filteredClasses = meditationClasses.filter { fitnessClass in
                fitnessClass.phases.contains { $0.lowercased() == "all" }
            }
            print("🎯 Day \(dayOffset): 'All' meditations found: \(filteredClasses.count)")
        }
        
        // Apply user preference filtering (remove disliked)
        if !userPreferences.dislikedWorkouts.isEmpty {
            filteredClasses = filteredClasses.filter { fitnessClass in
                !userPreferences.dislikedWorkouts.contains { disliked in
                    fitnessClass.types.contains { type in
                        type.lowercased().contains(disliked.lowercased()) ||
                        disliked.lowercased().contains(type.lowercased())
                    }
                }
            }
        }
        
        print("🎯 Day \(dayOffset): After preference filtering: \(filteredClasses.count) meditation classes")
        
        // Select meditation with variety
        return selectMeditationWithVariety(
            classes: filteredClasses,
            dayOffset: dayOffset,
            userPreferences: userPreferences,
            phase: phase
        )
    }
    
    private func selectMeditationWithVariety(
        classes: [FitnessClassData],
        dayOffset: Int,
        userPreferences: UserPreferences,
        phase: String
    ) -> FitnessClassData? {
        
        guard !classes.isEmpty else { 
            print("🎯 No meditation classes available for selection")
            return nil 
        }
        
        print("🎯 Selecting meditation from \(classes.count) available classes:")
        for (index, meditation) in classes.enumerated() {
            print("🎯   \(index + 1). \(meditation.className) (phases: \(meditation.phases))")
        }
        
        // For meditation, use simpler selection - weighted random with phase preference
        let scoredClasses = scoreMeditationClasses(classes, userPreferences: userPreferences, phase: phase)
        
        print("🎯 Meditation scores:")
        for (meditation, score) in scoredClasses {
            print("🎯   \(meditation.className): \(score) points")
        }
        
        // Create weighted selection pool
        var weightedPool: [FitnessClassData] = []
        
        for (fitnessClass, score) in scoredClasses {
            let weight = max(1, score + 1)
            for _ in 0..<weight {
                weightedPool.append(fitnessClass)
            }
        }
        
        // Random selection from weighted pool
        let randomIndex = Int.random(in: 0..<weightedPool.count)
        let selectedClass = weightedPool[randomIndex]
        print("🎯 Selected meditation: \(selectedClass.className) (phases: \(selectedClass.phases))")
        
        return selectedClass
    }
    
    private func scoreMeditationClasses(
        _ classes: [FitnessClassData],
        userPreferences: UserPreferences,
        phase: String
    ) -> [(fitnessClass: FitnessClassData, score: Int)] {
        
        return classes.map { fitnessClass in
            var score = 1 // Base score
            
            // HIGH PRIORITY: Bonus for phase-appropriate meditation
            if fitnessClass.phases.contains(where: { $0.lowercased() == phase.lowercased() }) {
                score += 5 // Much higher score for phase-specific meditations
            }
            
            // Bonus for favorite meditation types
            if !userPreferences.favoriteWorkouts.isEmpty {
                for favorite in userPreferences.favoriteWorkouts {
                    if favorite.lowercased().contains("meditation") || favorite.lowercased().contains("yoga") {
                        score += 1
                    }
                }
            }
            
            return (fitnessClass: fitnessClass, score: score)
        }
    }
    
    // MARK: - Workout Generation Logic
    private func generateWorkoutForDay(
        dayOffset: Int,
        phase: String,
        userPreferences: UserPreferences,
        availableClasses: [FitnessClassData],
        usedClasses: [String],
        favoriteWorkoutsUsed: [String]
    ) -> FitnessClassData? {
        
        // Step 1: Filter by cycle phase and exclude meditation classes
        var filteredClasses = fitnessClassesManager.getClassesForPhase(phase).filter { fitnessClass in
            // Exclude meditation classes from workout selection
            !fitnessClass.types.contains { $0.lowercased().contains("meditation") }
        }
        print("🎯 Day \(dayOffset): Found \(filteredClasses.count) classes for phase '\(phase)' (excluding meditations)")
        
        // Step 2: Apply user preference filtering
        filteredClasses = applyUserPreferenceFiltering(
            classes: filteredClasses,
            userPreferences: userPreferences
        )
        print("🎯 Day \(dayOffset): After preference filtering: \(filteredClasses.count) classes")
        
        // Step 3: Apply injury restrictions
        filteredClasses = applyInjuryRestrictions(
            classes: filteredClasses,
            userPreferences: userPreferences
        )
        print("🎯 Day \(dayOffset): After injury filtering: \(filteredClasses.count) classes")
        
<<<<<<< HEAD
        // Step 4: Apply intensity rules based on cycle phase
        filteredClasses = applyIntensityRules(
            classes: filteredClasses,
            phase: phase
        )
        print("🎯 Day \(dayOffset): After intensity filtering: \(filteredClasses.count) classes")
=======
        // Step 4: Apply phase-based scoring (preference, not strict filtering)
        // Instead of strict intensity rules, we'll score phase-appropriate workouts higher
        // but still allow all phase-specific workouts to be available
        print("🎯 Day \(dayOffset): Phase '\(phase)' workouts available: \(filteredClasses.count) classes")
        print("🎯 Day \(dayOffset): Using phase-specific workouts (no strict intensity filtering)")
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
        
        // Step 5: Remove classes already used this week
        filteredClasses = filteredClasses.filter { fitnessClass in
            !usedClasses.contains(fitnessClass.className)
        }
        print("🎯 Day \(dayOffset): After removing used classes: \(filteredClasses.count) classes")
        
        // Step 5.5: Prevent both dance cardio classes in the same week
        filteredClasses = preventMultipleDanceCardioInWeek(
            classes: filteredClasses,
            usedClasses: usedClasses
        )
        print("🎯 Day \(dayOffset): After dance cardio filtering: \(filteredClasses.count) classes")
        
        // Step 5.6: Ensure at least one favorite workout per week
        filteredClasses = ensureFavoriteWorkoutPerWeek(
            classes: filteredClasses,
            dayOffset: dayOffset,
            userPreferences: userPreferences,
            favoriteWorkoutsUsed: favoriteWorkoutsUsed
        )
        print("🎯 Day \(dayOffset): After favorite workout enforcement: \(filteredClasses.count) classes")
        
        // Step 6: Select workout with variety and preferences
        return selectWorkoutWithVariety(
            classes: filteredClasses,
            dayOffset: dayOffset,
            userPreferences: userPreferences,
            phase: phase
        )
    }
    
    // MARK: - Filtering Methods
    private func applyUserPreferenceFiltering(
        classes: [FitnessClassData],
        userPreferences: UserPreferences
    ) -> [FitnessClassData] {
        
        var filteredClasses = classes
        
        // Filter out disliked workouts - only filter if ALL types are disliked
        if !userPreferences.dislikedWorkouts.isEmpty {
            filteredClasses = filteredClasses.filter { fitnessClass in
                // Only filter out if ALL class types are disliked
                !fitnessClass.types.allSatisfy { type in
                    userPreferences.dislikedWorkouts.contains { disliked in
                        type.lowercased().contains(disliked.lowercased()) ||
                        disliked.lowercased().contains(type.lowercased())
                    }
                }
            }
        }
        
        return filteredClasses
    }
    
    private func applyInjuryRestrictions(
        classes: [FitnessClassData],
        userPreferences: UserPreferences
    ) -> [FitnessClassData] {
        
        var filteredClasses = classes
        
        // Apply injury-based restrictions
        for injury in userPreferences.pastInjuries {
            let restrictedMovements = getRestrictedMovements(for: injury)
            
            filteredClasses = filteredClasses.filter { fitnessClass in
                !restrictedMovements.contains { movement in
                    fitnessClass.types.contains { type in
                        type.lowercased().contains(movement.lowercased())
                    }
                }
            }
        }
        
        return filteredClasses
    }
    
<<<<<<< HEAD
=======
    // DEPRECATED: This function is no longer used for strict filtering
    // Instead, we use phase-specific workouts and scoring-based preferences
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
    private func applyIntensityRules(
        classes: [FitnessClassData],
        phase: String
    ) -> [FitnessClassData] {
        
<<<<<<< HEAD
        let preferredIntensities = getPreferredIntensities(for: phase)
        print("🎯 Phase '\(phase)' prefers intensities: \(preferredIntensities)")
        
        return classes.filter { fitnessClass in
            let intensity = fitnessClass.intensity.lowercased().trimmingCharacters(in: .whitespaces)
            return preferredIntensities.contains(intensity)
        }
=======
        // Return all classes - no longer apply strict intensity filtering
        // Phase-appropriate scoring is handled in the scoreClasses function instead
        print("🎯 Phase '\(phase)': Allowing all phase-specific workouts (no intensity filtering)")
        return classes
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
    }
    
    private func preventMultipleDanceCardioInWeek(
        classes: [FitnessClassData],
        usedClasses: [String]
    ) -> [FitnessClassData] {
        
        // Check if any dance cardio class has already been used this week
        let danceCardioClasses = ["Dance Cardio, Affirmations Blast", "Dance Cardio - the short one, Affirmations Blast"]
        let usedDanceCardio = usedClasses.first { className in
            danceCardioClasses.contains(className)
        }
        
        // If a dance cardio class has been used, filter out the other dance cardio class
        if let usedDance = usedDanceCardio {
            print("🎯 Dance cardio class '\(usedDance)' already used this week, filtering out other dance cardio classes")
            return classes.filter { fitnessClass in
                !danceCardioClasses.contains(fitnessClass.className) || fitnessClass.className == usedDance
            }
        }
        
        return classes
    }
    
    private func ensureFavoriteWorkoutPerWeek(
        classes: [FitnessClassData],
        dayOffset: Int,
        userPreferences: UserPreferences,
        favoriteWorkoutsUsed: [String]
    ) -> [FitnessClassData] {
        
        // Only enforce this rule if user has favorite workouts
        guard !userPreferences.favoriteWorkouts.isEmpty else {
            return classes
        }
        
        // Check if we're in the second half of the week (day 4-6 or day 11-13) and no favorite workout has been used yet
        let isSecondHalfOfWeek = (dayOffset >= 4 && dayOffset <= 6) || (dayOffset >= 11 && dayOffset <= 13)
        let noFavoriteWorkoutUsed = favoriteWorkoutsUsed.isEmpty
        
        if isSecondHalfOfWeek && noFavoriteWorkoutUsed {
            print("🎯 Day \(dayOffset): No favorite workout used this week yet, prioritizing favorite workouts")
            
            // Filter to only include favorite workouts
            let favoriteClasses = classes.filter { fitnessClass in
                isFavoriteWorkout(fitnessClass, userPreferences: userPreferences)
            }
            
            // If we have favorite classes available, use only those
            if !favoriteClasses.isEmpty {
                print("🎯 Day \(dayOffset): Found \(favoriteClasses.count) favorite workout classes available")
                return favoriteClasses
            } else {
                print("🎯 Day \(dayOffset): No favorite workout classes available, using all classes")
            }
        }
        
        return classes
    }
    
    private func isFavoriteWorkout(
        _ fitnessClass: FitnessClassData,
        userPreferences: UserPreferences
    ) -> Bool {
        return userPreferences.favoriteWorkouts.contains { favorite in
            fitnessClass.types.contains { type in
                type.lowercased().contains(favorite.lowercased()) ||
                favorite.lowercased().contains(type.lowercased())
            }
        }
    }
    
    
    // MARK: - Workout Selection with Variety
    private func selectWorkoutWithVariety(
        classes: [FitnessClassData],
        dayOffset: Int,
        userPreferences: UserPreferences,
        phase: String
    ) -> FitnessClassData? {
        
        guard !classes.isEmpty else { return nil }
        
        // Strategy 1: Weighted Random Selection (70% of the time)
        if dayOffset % 10 < 7 {
            return selectWithWeightedRandom(classes: classes, userPreferences: userPreferences, phase: phase)
        }
        
        // Strategy 2: Favorite Rotation (20% of the time)
        if dayOffset % 10 < 9 {
            return selectFromFavorites(classes: classes, dayOffset: dayOffset, userPreferences: userPreferences)
        }
        
        // Strategy 3: Exploration (10% of the time) - try something new
        return selectForExploration(classes: classes, dayOffset: dayOffset, userPreferences: userPreferences)
    }
    
    // MARK: - Selection Strategies
    private func selectWithWeightedRandom(
        classes: [FitnessClassData],
        userPreferences: UserPreferences,
        phase: String? = nil
    ) -> FitnessClassData? {
        
        let scoredClasses = scoreClasses(classes, userPreferences: userPreferences, phase: phase)
        
        // Create weighted selection pool
        var weightedPool: [FitnessClassData] = []
        
        for (fitnessClass, score) in scoredClasses {
            // Add class multiple times based on score (higher score = more chances)
            let weight = max(1, score + 1) // Ensure at least 1 chance
            for _ in 0..<weight {
                weightedPool.append(fitnessClass)
            }
        }
        
        // Random selection from weighted pool
        let randomIndex = Int.random(in: 0..<weightedPool.count)
        let selectedClass = weightedPool[randomIndex]
        print("🎯 Selected workout by weighted random: \(selectedClass.className)")
        
        return selectedClass
    }
    
    private func selectFromFavorites(
        classes: [FitnessClassData],
        dayOffset: Int,
        userPreferences: UserPreferences
    ) -> FitnessClassData? {
        
        guard !userPreferences.favoriteWorkouts.isEmpty else { 
            print("🎯 No favorite workouts specified, falling back to weighted random")
            return selectWithWeightedRandom(classes: classes, userPreferences: userPreferences, phase: nil)
        }
        
        let favoriteClasses = classes.filter { fitnessClass in
            userPreferences.favoriteWorkouts.contains { favorite in
                fitnessClass.types.contains { type in
                    type.lowercased().contains(favorite.lowercased()) ||
                    favorite.lowercased().contains(type.lowercased())
                }
            }
        }
        
        guard !favoriteClasses.isEmpty else { 
            print("🎯 No favorite classes available in current selection, falling back to weighted random")
            return selectWithWeightedRandom(classes: classes, userPreferences: userPreferences, phase: nil)
        }
        
        // Use rotation to ensure variety among favorites
        let selectedIndex = dayOffset % favoriteClasses.count
        let selectedClass = favoriteClasses[selectedIndex]
        print("🎯 Selected favorite workout: \(selectedClass.className) (index: \(selectedIndex))")
        
        return selectedClass
    }
    
    private func selectForExploration(
        classes: [FitnessClassData],
        dayOffset: Int,
        userPreferences: UserPreferences
    ) -> FitnessClassData? {
        
        // Find classes that are NOT favorites (exploration)
        let explorationClasses = classes.filter { fitnessClass in
            !userPreferences.favoriteWorkouts.contains { favorite in
                fitnessClass.types.contains { type in
                    type.lowercased().contains(favorite.lowercased()) ||
                    favorite.lowercased().contains(type.lowercased())
                }
            }
        }
        
        // If no exploration classes, fall back to all classes
        let classesToExplore = explorationClasses.isEmpty ? classes : explorationClasses
        
        guard !classesToExplore.isEmpty else {
            print("🎯 No classes available for exploration, falling back to weighted random")
            return selectWithWeightedRandom(classes: classes, userPreferences: userPreferences, phase: nil)
        }
        
        // Random selection for exploration
        let randomIndex = Int.random(in: 0..<classesToExplore.count)
        let selectedClass = classesToExplore[randomIndex]
        print("🎯 Selected workout for exploration: \(selectedClass.className)")
        
        return selectedClass
    }
    
    // MARK: - Scoring System
    private func scoreClasses(
        _ classes: [FitnessClassData],
        userPreferences: UserPreferences,
        phase: String? = nil
    ) -> [(fitnessClass: FitnessClassData, score: Int)] {
        
        return classes.map { fitnessClass in
            var score = 1 // Base score for all classes
            
            // Bonus for favorite workout types (reduced weight)
            if !userPreferences.favoriteWorkouts.isEmpty {
                for favorite in userPreferences.favoriteWorkouts {
                    if fitnessClass.types.contains(where: { type in
                        type.lowercased().contains(favorite.lowercased()) ||
                        favorite.lowercased().contains(type.lowercased())
                    }) {
                        score += 2 // Reduced from 3 to 2
                    }
                }
            }
            
            // Bonus for matching fitness goal (reduced weight)
            if let goal = userPreferences.fitnessGoal {
                if fitnessClass.types.contains(where: { type in
                    type.lowercased().contains(goal.lowercased()) ||
                    goal.lowercased().contains(type.lowercased())
                }) {
                    score += 1 // Reduced from 2 to 1
                }
            }
            
            
<<<<<<< HEAD
            // Bonus for appropriate intensity for fitness level
            let fitnessLevel = userPreferences.fitnessLevel.lowercased()
            let intensity = fitnessClass.intensity.lowercased().trimmingCharacters(in: .whitespaces)
            
=======
            // PHASE-BASED SCORING: Bonus for phase-appropriate intensity (preference, not strict rule)
            let fitnessLevel = userPreferences.fitnessLevel.lowercased()
            let intensity = fitnessClass.intensity.lowercased().trimmingCharacters(in: .whitespaces)
            
            // Give higher scores to phase-appropriate intensities, but don't exclude others
            if let currentPhase = phase {
                switch currentPhase.lowercased() {
                case "menstrual":
                    if intensity == "low" { score += 2 } // Prefer low intensity
                    else { score += 0 } // But don't exclude others
                case "follicular":
                    if intensity == "mid" || intensity == "high" { score += 2 } // Prefer building energy
                    else { score += 0 }
                case "ovulatory", "ovulation":
                    if intensity == "high" { score += 2 } // Prefer high intensity
                    else { score += 0 }
                case "luteal":
                    if intensity == "mid" || intensity == "low" { score += 2 } // Prefer moderate
                    else { score += 0 }
                default:
                    score += 0
                }
            }
            
            // Additional bonus for appropriate intensity for fitness level
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
            if fitnessLevel.contains("beginner") && intensity == "low" {
                score += 1
            } else if fitnessLevel.contains("intermediate") && (intensity == "mid" || intensity == "low") {
                score += 1
            } else if fitnessLevel.contains("advanced") {
                score += 1 // Advanced users can handle any intensity
            }
            
            // Small bonus for variety (shorter duration classes get slight preference)
            let duration = parseDuration(fitnessClass.duration)
            if duration <= 20 {
                score += 1
            }
            
            // HIGH PRIORITY: Bonus for dance cardio during ovulation phase
            if let currentPhase = phase, currentPhase.lowercased() == "ovulation" {
                if fitnessClass.types.contains(where: { type in
                    type.lowercased().contains("dance")
                }) {
                    score += 3 // High bonus for dance cardio during ovulation
                    print("🎯 Dance cardio bonus applied for ovulation phase: \(fitnessClass.className)")
                }
            }
            
<<<<<<< HEAD
=======
            // HIGHEST PRIORITY: Bonus for phase-specific workouts (designed for this phase)
            if let currentPhase = phase {
                if fitnessClass.phases.contains(where: { $0.lowercased() == currentPhase.lowercased() }) {
                    score += 4 // High bonus for workouts specifically designed for this phase
                    print("🎯 Phase-specific workout bonus applied: \(fitnessClass.className) for \(currentPhase) phase")
                }
            }
            
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
            return (fitnessClass: fitnessClass, score: score)
        }
    }
    
    // MARK: - Helper Methods
    private func getCurrentCyclePhase(for userProfile: UserProfile, date: Date) -> String {
        // Use the existing cycle phase calculation logic
        if CyclePredictionService.shared.hasBackendData() {
            if let backendPhase = CyclePredictionService.shared.getPhaseForDate(date, userProfile: userProfile) {
                let phaseString = mapCyclePhaseToString(backendPhase)
                print("🎯 Cycle phase for \(date): \(phaseString) (from backend)")
                return phaseString
            }
        }
        
        // Fallback to current cycle phase
        let fallbackPhase = mapCyclePhaseToString(userProfile.currentCyclePhase ?? .follicular)
        print("🎯 Cycle phase for \(date): \(fallbackPhase) (fallback)")
        return fallbackPhase
    }
    
    private func getPreferredIntensities(for phase: String) -> [String] {
        switch phase.lowercased() {
        case "menstrual":
            return ["low"]
        case "follicular":
            return ["mid", "high"]
        case "ovulatory", "ovulation":
            return ["high"]
        case "luteal":
            return ["mid", "low"]
        default:
            return ["low", "mid", "high"]
        }
    }
    
    
    private func getRestrictedMovements(for injury: String) -> [String] {
        switch injury.lowercased() {
        case "ankle", "knee":
            return ["jumping", "impact", "run"]
        case "wrist", "shoulder":
            return ["weight-bearing", "push", "strength"]
        case "back":
            return ["twisting", "bending", "strength"]
        default:
            return []
        }
    }
    
    private func createRestDayEntry(date: Date, phase: String) -> WeeklyFitnessPlanEntry {
        return WeeklyFitnessPlanEntry(
            date: date,
            workoutTitle: "Rest Day",
            workoutDescription: "Scheduled rest day for recovery",
            duration: 0,
<<<<<<< HEAD
            workoutType: .meditation,
=======
            workoutType: .yoga, // Use yoga instead of meditation for rest days
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
            cyclePhase: mapCyclePhase(phase),
            difficulty: .beginner,
            equipment: [],
            benefits: ["Recovery", "Rest", "Restoration"],
            instructor: nil,
            audioURL: nil,
            videoURL: nil,
            isVideo: false,
            injuries: nil,
            status: WorkoutStatus.suggested
        )
    }
    
    // MARK: - Mapping Methods
    private func parseDuration(_ durationString: String) -> Int {
        let numbers = durationString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.first ?? 30
    }
    
    private func mapWorkoutType(_ type: String) -> WorkoutType {
        switch type.lowercased() {
        case "strength":
            return .strength
        case "cardio", "run", "cycle", "walk":
            return .cardio
        case "yoga":
            return .yoga
        case "pilates":
            return .pilates
        case "meditation":
            return .meditation
        case "dance":
            return .dance
        case "hiit":
            return .hiit
        case "boxing":
            return .boxing
        default:
            return .cardio
        }
    }
    
    private func mapCyclePhase(_ phase: String) -> CyclePhase {
        switch phase.lowercased() {
        case "menstrual":
            return .menstrual
        case "follicular":
            return .follicular
        case "ovulatory", "ovulation":
            return .ovulatory
        case "luteal":
            return .luteal
        case "menstrual moon":
            return .menstrualMoon
        case "follicular moon":
            return .follicularMoon
        case "ovulatory moon", "ovulation moon":
            return .ovulatoryMoon
        case "luteal moon":
            return .lutealMoon
        default:
            return .follicular
        }
    }
    
    private func mapCyclePhaseToString(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual:
            return "menstrual"
        case .follicular:
            return "follicular"
        case .ovulatory:
            return "ovulation"  // FIXED: Changed from "ovulatory" to "ovulation" to match JSON
        case .luteal:
            return "luteal"
        case .menstrualMoon:
            return "menstrual"
        case .follicularMoon:
            return "follicular"
        case .ovulatoryMoon:
            return "ovulation"
        case .lutealMoon:
            return "luteal"
        }
    }
    
    private func mapDifficulty(_ intensity: String) -> WorkoutDifficulty {
        switch intensity.lowercased().trimmingCharacters(in: .whitespaces) {
        case "low":
            return .beginner
        case "mid", "mid-high":
            return .intermediate
        case "high":
            return .advanced
        default:
            return .intermediate
        }
    }
    
    // MARK: - Workout Data Matching
    private func findMatchingWorkoutData(for className: String) -> Workout? {
        return self.workoutData.first { workout in
            workout.title == className
        }
    }
<<<<<<< HEAD
=======
    
    // MARK: - JSON Export for Debugging
    private func savePlanToJSON(_ plan: [WeeklyFitnessPlanEntry], userProfile: UserProfile, userPreferences: UserPreferences, startDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        // Create a comprehensive plan object for JSON export
        let planExport = FitnessPlanExport(
            generatedAt: Date(),
            startDate: startDate,
            userProfile: UserProfileExport(from: userProfile),
            userPreferences: UserPreferencesExport(from: userPreferences),
            plan: plan.map { entry in
                FitnessPlanEntryExport(
                    date: entry.date,
                    workoutTitle: entry.workoutTitle,
                    workoutDescription: entry.workoutDescription,
                    duration: entry.duration,
                    workoutType: entry.workoutType.rawValue,
                    cyclePhase: entry.cyclePhase.rawValue,
                    difficulty: entry.difficulty.rawValue,
                    equipment: entry.equipment,
                    benefits: entry.benefits,
                    instructor: entry.instructor,
                    audioURL: entry.audioURL,
                    videoURL: entry.videoURL,
                    isVideo: entry.isVideo,
                    status: entry.status.rawValue
                )
            }
        )
        
        do {
            let jsonData = try JSONEncoder().encode(planExport)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Failed to convert to string"
            
            // Save to Documents directory
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("❌ Could not access Documents directory")
                return
            }
            let fileName = "fitness_plan_\(timestamp).json"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("🎯 Fitness plan saved to: \(fileURL.path)")
            print("🎯 File name: \(fileName)")
            
            // Also print a summary to console
            printPlanSummary(plan, userPreferences: userPreferences, startDate: startDate)
            
        } catch {
            print("❌ Failed to save fitness plan to JSON: \(error)")
        }
    }
    
    private func printPlanSummary(_ plan: [WeeklyFitnessPlanEntry], userPreferences: UserPreferences, startDate: Date) {
        print("\n🎯 ===== FITNESS PLAN SUMMARY =====")
        print("🎯 Start Date: \(startDate)")
        print("🎯 Workout Frequency: \(userPreferences.workoutFrequency) days/week")
        print("🎯 Favorite Workouts: \(userPreferences.favoriteWorkouts)")
        print("🎯 Disliked Workouts: \(userPreferences.dislikedWorkouts)")
        print("🎯 Preferred Rest Days: \(userPreferences.preferredRestDays)")
        print("🎯 Plan Start Choice: \(userPreferences.planStartChoice ?? "nil")")
        print("🎯 ===== 14-DAY PLAN =====")
        
        for (index, entry) in plan.enumerated() {
            let dayType = entry.workoutTitle == "Rest Day" ? "REST" : 
                         entry.workoutType == .meditation ? "MEDITATION" : "WORKOUT"
            print("🎯 Day \(index + 1): \(dayType) - \(entry.workoutTitle) (\(entry.duration)min)")
        }
        
        let workoutCount = plan.filter { $0.workoutTitle != "Rest Day" && $0.workoutType != .meditation }.count
        let meditationCount = plan.filter { $0.workoutType == .meditation && $0.workoutTitle != "Rest Day" }.count
        let restCount = plan.filter { $0.workoutTitle == "Rest Day" }.count
        
        print("🎯 ===== TOTALS =====")
        print("🎯 Workouts: \(workoutCount)")
        print("🎯 Meditations: \(meditationCount)")
        print("🎯 Rest Days: \(restCount)")
        print("🎯 ===================\n")
    }
    
    // MARK: - JSON File Management
    static func getSavedFitnessPlans() -> [URL] {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not access Documents directory")
            return []
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            return files.filter { $0.lastPathComponent.hasPrefix("fitness_plan_") && $0.pathExtension == "json" }
                .sorted { $0.lastPathComponent > $1.lastPathComponent } // Most recent first
        } catch {
            print("❌ Failed to list fitness plan files: \(error)")
            return []
        }
    }
    
    static func getLatestFitnessPlan() -> FitnessPlanExport? {
        let files = getSavedFitnessPlans()
        guard let latestFile = files.first else {
            print("❌ No fitness plan files found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: latestFile)
            let plan = try JSONDecoder().decode(FitnessPlanExport.self, from: data)
            print("✅ Loaded latest fitness plan from: \(latestFile.lastPathComponent)")
            return plan
        } catch {
            print("❌ Failed to load fitness plan from \(latestFile.lastPathComponent): \(error)")
            return nil
        }
    }
    
    static func printSavedPlansList() {
        let files = getSavedFitnessPlans()
        print("\n🎯 ===== SAVED FITNESS PLANS =====")
        if files.isEmpty {
            print("🎯 No saved fitness plans found")
        } else {
            for (index, file) in files.enumerated() {
                print("🎯 \(index + 1). \(file.lastPathComponent)")
            }
        }
        print("🎯 ================================\n")
    }
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
}

// MARK: - User Preferences Model
struct UserPreferences {
    let fitnessLevel: String
    let fitnessGoal: String?
    let workoutFrequency: Int
    let favoriteWorkouts: [String]
    let dislikedWorkouts: [String]
    let pastInjuries: [String]
    let preferredRestDays: [String]
    let planStartChoice: String?
    
    init(from personalizationData: PersonalizationData) {
        self.fitnessLevel = personalizationData.fitnessLevel?.rawValue ?? "Beginner"
        self.fitnessGoal = personalizationData.fitnessGoal?.rawValue
        
        // DEBUG: Log the desired workout frequency
        let desiredFrequencyString = personalizationData.desiredWorkoutFrequency?.rawValue ?? "4 days"
        print("🔍 UserPreferences: desiredWorkoutFrequency raw value: '\(desiredFrequencyString)'")
        
        // Use DESIRED workout frequency instead of current frequency
        self.workoutFrequency = Self.parseDesiredWorkoutFrequency(desiredFrequencyString)
        print("🔍 UserPreferences: parsed workout frequency: \(self.workoutFrequency)")
        
        self.favoriteWorkouts = Self.parseCommaSeparated(personalizationData.favoriteWorkoutsString)
        self.dislikedWorkouts = Self.parseCommaSeparated(personalizationData.dislikedWorkoutsString)
        self.pastInjuries = Self.parseCommaSeparated(personalizationData.pastInjuries)
        self.preferredRestDays = Self.parseCommaSeparated(personalizationData.preferredRestDaysString)
        self.planStartChoice = personalizationData.planStartChoice?.rawValue
    }
    
    // Default initializer for when no personalization data exists
    init(
        fitnessLevel: String = "Beginner",
        fitnessGoal: String? = "General fitness",
        workoutFrequency: Int = 4,
        favoriteWorkouts: [String] = [],
        dislikedWorkouts: [String] = [],
        pastInjuries: [String] = [],
        preferredRestDays: [String] = [],
        planStartChoice: String? = nil
    ) {
        self.fitnessLevel = fitnessLevel
        self.fitnessGoal = fitnessGoal
        self.workoutFrequency = workoutFrequency
        self.favoriteWorkouts = favoriteWorkouts
        self.dislikedWorkouts = dislikedWorkouts
        self.pastInjuries = pastInjuries
        self.preferredRestDays = preferredRestDays
        self.planStartChoice = planStartChoice
    }
    
    private static func parseWorkoutFrequency(_ frequency: String) -> Int {
        let numbers = frequency.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        // FIXED: Use the maximum number instead of the first number
        // For "2-3 times" -> use 3, for "4-5 times" -> use 5, etc.
        return numbers.max() ?? 4
    }
    
    private static func parseDesiredWorkoutFrequency(_ frequency: String) -> Int {
        // Parse desired workout frequency (e.g., "4 days" -> 4, "6 days" -> 6)
        let numbers = frequency.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.first ?? 4
    }
    
    private static func parseCommaSeparated(_ string: String?) -> [String] {
        guard let string = string, !string.isEmpty else { return [] }
        return string.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
<<<<<<< HEAD
=======
}

// MARK: - JSON Export Data Structures
struct FitnessPlanExport: Codable {
    let generatedAt: Date
    let startDate: Date
    let userProfile: UserProfileExport
    let userPreferences: UserPreferencesExport
    let plan: [FitnessPlanEntryExport]
}

struct UserProfileExport: Codable {
    let cycleLength: Int?
    let lastPeriodStart: Date?
    let averagePeriodLength: Int?
    let cycleType: String?
    let currentCyclePhase: String?
    let hasRecurringSymptoms: Bool?
    let lastSymptomsStart: Date?
    let averageSymptomDays: Int?
    let useMoonCycle: Bool?
    
    init(from userProfile: UserProfile) {
        self.cycleLength = userProfile.cycleLength
        self.lastPeriodStart = userProfile.lastPeriodStart
        self.averagePeriodLength = userProfile.averagePeriodLength
        self.cycleType = userProfile.cycleType?.rawValue
        self.currentCyclePhase = userProfile.currentCyclePhase?.rawValue
        self.hasRecurringSymptoms = userProfile.hasRecurringSymptoms
        self.lastSymptomsStart = userProfile.lastSymptomsStart
        self.averageSymptomDays = userProfile.averageSymptomDays
        self.useMoonCycle = userProfile.personalizationData?.useMoonCycle
    }
}

struct UserPreferencesExport: Codable {
    let fitnessLevel: String
    let fitnessGoal: String?
    let workoutFrequency: Int
    let favoriteWorkouts: [String]
    let dislikedWorkouts: [String]
    let pastInjuries: [String]
    let preferredRestDays: [String]
    let planStartChoice: String?
    
    init(from userPreferences: UserPreferences) {
        self.fitnessLevel = userPreferences.fitnessLevel
        self.fitnessGoal = userPreferences.fitnessGoal
        self.workoutFrequency = userPreferences.workoutFrequency
        self.favoriteWorkouts = userPreferences.favoriteWorkouts
        self.dislikedWorkouts = userPreferences.dislikedWorkouts
        self.pastInjuries = userPreferences.pastInjuries
        self.preferredRestDays = userPreferences.preferredRestDays
        self.planStartChoice = userPreferences.planStartChoice
    }
}

struct FitnessPlanEntryExport: Codable {
    let date: Date
    let workoutTitle: String
    let workoutDescription: String
    let duration: Int
    let workoutType: String
    let cyclePhase: String
    let difficulty: String
    let equipment: [String]
    let benefits: [String]
    let instructor: String?
    let audioURL: String?
    let videoURL: String?
    let isVideo: Bool
    let status: String
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
}