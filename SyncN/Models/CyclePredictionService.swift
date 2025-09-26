import Foundation
import SwiftData
import TinyMoon
// MARK: - Notification Names
// Note: userProfileUpdated is already defined in MainTabView.swift

// MARK: - Cycle Prediction Service
public class CyclePredictionService {
    public static let shared = CyclePredictionService()
    
    private let baseURL = "http://localhost:8000" // Use localhost for iOS Simulator (runs on same Mac)
    
    // Store the latest backend data for calendar views to use
    private var latestBackendData: [String: Any]?
    private var latestDailyData: [[String: Any]] = []
    
    private init() {}
    
    // MARK: - Backend Data Management
    func hasBackendData() -> Bool {
        // Always return true since we now have Swift-only data
        return true
    }
    
    // MARK: - Fetch Cycle Predictions with Widening Window
    func fetchCyclePredictions(for userProfile: UserProfile) async throws -> [Date] {
        
        // Check if this is a moon cycle that should use the backend API
        let isMoonCycle = userProfile.cycleType == .noPeriod && 
                         userProfile.hasRecurringSymptoms != true &&
                         userProfile.personalizationData?.useMoonCycle == true
        
        if isMoonCycle {
            // For moon cycles, use TinyMoon for accurate real-time moon phase calculation
            let predictions = generateMoonCyclePredictions(for: userProfile)
            let dailyData = generateMoonCycleDailyData(for: userProfile, predictions: predictions)
            
            // Store the predictions and daily data for calendar views to use
            latestBackendData = ["predictions": predictions.map { ["date": ISO8601DateFormatter().string(from: $0)] }]
            latestDailyData = dailyData
            
            print("✅ Generated \(predictions.count) moon cycle prediction dates and \(dailyData.count) daily entries")
            return predictions
        } else {
            // For regular and symptomatic cycles, use Swift logic
            let predictions = generateCyclePredictions(for: userProfile)
            let dailyData = generateDailyCycleData(for: userProfile, predictions: predictions)
            
            // Store the predictions and daily data for calendar views to use
            latestBackendData = ["predictions": predictions.map { ["date": ISO8601DateFormatter().string(from: $0)] }]
            latestDailyData = dailyData
            
            print("✅ Generated \(predictions.count) cycle prediction dates and \(dailyData.count) daily entries locally")
            
            return predictions
        }
    }
    
    // MARK: - Moon Cycle Prediction Generation (Using TinyMoon)
    private func generateMoonCyclePredictions(for userProfile: UserProfile) -> [Date] {
        let calendar = Calendar.current
        var predictions: [Date] = []
        
        // Find the next 3 New Moon dates (actual lunar calendar)
        let currentDate = Date()
        var searchDate = currentDate
        
        // Search for the next 3 New Moons
        for _ in 0..<3 {
            // Look ahead up to 30 days to find the next New Moon
            for dayOffset in 0..<30 {
                let testDate = calendar.date(byAdding: .day, value: dayOffset, to: searchDate) ?? searchDate
                let moon = TinyMoon.calculateMoonPhase(testDate)
                
                if moon.name == "New Moon" {
                    predictions.append(testDate)
                    searchDate = calendar.date(byAdding: .day, value: 1, to: testDate) ?? testDate
                    break
                }
            }
        }
        
        return predictions
    }
    
    private func generateMoonCycleDailyData(for userProfile: UserProfile, predictions: [Date]) -> [[String: Any]] {
        let calendar = Calendar.current
        var dailyData: [[String: Any]] = []
        let formatter = ISO8601DateFormatter()
        
        // Generate daily data for the next 3 months
        let startDate = Date()
        let endDate = calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        var currentDate = startDate
        
        while currentDate < endDate {
            // Use TinyMoon to get the actual moon phase for this date
            let moonPhase = calculateMoonPhaseForDate(currentDate)
            
            dailyData.append([
                "date": formatter.string(from: currentDate),
                "phase": moonPhase.rawValue,
                "isWideningWindow": false // Moon cycles don't have widening windows
            ])
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dailyData
    }
    
    // MARK: - Swift Daily Cycle Data Generation (Based on Backend Logic)
    private func generateDailyCycleData(for userProfile: UserProfile, predictions: [Date]) -> [[String: Any]] {
        let calendar = Calendar.current
        var dailyData: [[String: Any]] = []
        
        // Get user cycle parameters
        let isMoonCycle = userProfile.cycleType == .noPeriod && 
                         userProfile.hasRecurringSymptoms != true &&
                         userProfile.personalizationData?.useMoonCycle == true
        
        let cycleLength = isMoonCycle ? 29 : (userProfile.cycleLength ?? 28) // Use 29 days for moon cycles
        let isIrregular = userProfile.hasIrregularCycles
        
        // For symptomatic cycles, use symptom data instead of period data
        let isSymptomaticCycle = userProfile.cycleType == .noPeriod && userProfile.hasRecurringSymptoms == true
        
        let lastCycleStart: Date?
        
        if isSymptomaticCycle {
            lastCycleStart = userProfile.lastSymptomsStart
        } else if isMoonCycle {
            lastCycleStart = nil // Moon cycles don't have a "last start" date
        } else {
            lastCycleStart = userProfile.lastPeriodStart
        }
        
        // Generate widening window days for irregular cycles
        var wideningWindowDays: [Date] = []
        if isIrregular, let lastStart = lastCycleStart {
            wideningWindowDays = calculateWideningWindowDays(
                menstrualStart: lastStart,
                avgCycleLength: cycleLength,
                numCycles: 3
            )
        }
        
        // Generate daily data for the next 3 months (as requested)
        let startDate = Date()
        let endDate = calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        var currentDate = startDate
        
        while currentDate < endDate {
            // Calculate phase for this date
            let phase = calculateCyclePhaseForDate(currentDate, userProfile: userProfile)
            let phaseName = phase?.rawValue ?? "follicular"
            
            // Check if this date is in the widening window (for irregular cycles)
            let isWideningWindow = isIrregular && wideningWindowDays.contains { wideningDate in
                calendar.isDate(currentDate, inSameDayAs: wideningDate)
            }
            
            // Create daily entry
            let formatter = ISO8601DateFormatter()
            dailyData.append([
                "date": formatter.string(from: currentDate),
                "phase": phaseName,
                "isWideningWindow": isWideningWindow
            ])
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dailyData
    }
    
    // MARK: - Swift Cycle Prediction Logic
    private func generateCyclePredictions(for userProfile: UserProfile) -> [Date] {
        var predictions: [Date] = []
        let calendar = Calendar.current
        
        // Get cycle parameters
        let isMoonCycle = userProfile.cycleType == .noPeriod && 
                         userProfile.hasRecurringSymptoms != true &&
                         userProfile.personalizationData?.useMoonCycle == true
        
        let cycleLength = isMoonCycle ? 29 : (userProfile.cycleLength ?? 28) // Use 29 days for moon cycles
        
        // For symptomatic cycles (no periods but recurring symptoms), use symptom data
        let isSymptomaticCycle = userProfile.cycleType == .noPeriod && userProfile.hasRecurringSymptoms == true
        
        let periodLength: Int
        let startDate: Date
        
        if isSymptomaticCycle {
            // Use symptom data for symptomatic cycles
            periodLength = userProfile.averageSymptomDays ?? 3
            if let lastSymptomsStart = userProfile.lastSymptomsStart {
                startDate = lastSymptomsStart
            } else {
                startDate = Date()
            }
        } else if isMoonCycle {
            // For moon cycles, use a 29.5 day cycle with 3-day "period" equivalent
            periodLength = 3
            startDate = Date() // Moon cycles don't have a "last start" date
        } else {
            // Use period data for regular/irregular cycles
            periodLength = userProfile.averagePeriodLength ?? 5
            if let lastPeriodStart = userProfile.lastPeriodStart {
                startDate = lastPeriodStart
            } else {
                startDate = Date()
            }
        }
        
        // Generate predictions for next 3 cycles
        for cycle in 0..<3 {
            let nextCycleStart = calendar.date(byAdding: .day, value: cycleLength * (cycle + 1), to: startDate) ?? startDate
            predictions.append(nextCycleStart)
            
            // Add cycle end date (symptom end for symptomatic cycles, period end for menstrual cycles)
            let cycleEnd = calendar.date(byAdding: .day, value: periodLength, to: nextCycleStart) ?? nextCycleStart
            predictions.append(cycleEnd)
        }
        
        return predictions
    }
    
    // MARK: - Fetch Weekly Fitness Plan (Swift Implementation)
    func fetchWeeklyFitnessPlan(for userProfile: UserProfile, startDate: Date) async throws -> [WeeklyFitnessPlanEntry] {
        
        // Get user preferences from personalization data
        let userPreferences: UserPreferences
        if let personalizationData = userProfile.personalizationData {
            print("🔍 CyclePredictionService: Using personalization data")
            print("🔍 CyclePredictionService: desiredWorkoutFrequency = \(personalizationData.desiredWorkoutFrequency?.rawValue ?? "nil")")
            userPreferences = UserPreferences(from: personalizationData)
            print("🔍 CyclePredictionService: Generated UserPreferences with workoutFrequency = \(userPreferences.workoutFrequency)")
        } else {
            print("🔍 CyclePredictionService: No personalization data, using defaults")
            // Create default preferences if no personalization data exists
            userPreferences = UserPreferences(
                fitnessLevel: "Beginner",
                fitnessGoal: "General fitness",
                workoutFrequency: 4,
                favoriteWorkouts: [],
                dislikedWorkouts: [],
                pastInjuries: [],
                preferredRestDays: []
            )
        }
        
        // Determine the actual start date based on user's plan start choice
        let actualStartDate: Date
        if let personalizationData = userProfile.personalizationData,
           let planStartChoice = personalizationData.planStartChoice {
            
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            if planStartChoice == .tomorrow {
                actualStartDate = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
                print("🎯 CyclePredictionService: User chose to start plan tomorrow: \(actualStartDate)")
            } else {
                actualStartDate = startOfDay
                print("🎯 CyclePredictionService: User chose to start plan today: \(actualStartDate)")
            }
        } else {
            // Fallback to the provided startDate if no plan start choice is set
            actualStartDate = startDate
            print("🎯 CyclePredictionService: No plan start choice, using provided startDate: \(actualStartDate)")
        }
        
        // Generate the fitness plan using the Swift engine with the correct start date
        let weeklyPlan = SwiftFitnessRecommendationEngine.shared.generateWeeklyFitnessPlan(
            for: userProfile,
            startDate: actualStartDate,
            userPreferences: userPreferences
        )
        
        return weeklyPlan
    }
    
    // MARK: - Get User's Plan Start Date
    func getUserPlanStartDate(for userProfile: UserProfile) -> Date {
        if let personalizationData = userProfile.personalizationData,
           let planStartChoice = personalizationData.planStartChoice {
            
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            if planStartChoice == .tomorrow {
                let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
                print("🎯 CyclePredictionService: User's plan starts tomorrow: \(tomorrowStart)")
                return tomorrowStart
            } else {
                print("🎯 CyclePredictionService: User's plan starts today: \(startOfDay)")
                return startOfDay
            }
        } else {
            // Fallback to current date if no plan start choice is set
            let fallbackDate = Calendar.current.startOfDay(for: Date())
            print("🎯 CyclePredictionService: No plan start choice, using fallback date: \(fallbackDate)")
            return fallbackDate
        }
    }
    
    // MARK: - Log Period Start
    func logPeriodStart(date: Date, bleedDuration: Int, for userProfile: UserProfile) async throws {
        // Note: This endpoint doesn't exist in the new backend yet
        // You may need to implement this functionality differently
        print("⚠️ Log period endpoint not implemented in new backend")
        
        // For now, just update the local user profile
        // This is a placeholder until you implement the backend endpoint
        userProfile.lastPeriodStart = date
        userProfile.averagePeriodLength = bleedDuration
    }
    
    // MARK: - Calendar Data Access
    func getPhaseForDate(_ date: Date, userProfile: UserProfile? = nil) -> CyclePhase? {
        // Check if this is a moon cycle
        if let profile = userProfile,
           profile.cycleType == .noPeriod,
           profile.hasRecurringSymptoms != true,
           profile.personalizationData?.useMoonCycle == true {
            
            // For moon cycles, use TinyMoon for real-time accurate calculation
            return calculateMoonPhaseForDate(date)
        }
        
        // For regular and symptomatic cycles, use local calculation
        return calculateCyclePhaseForDate(date, userProfile: userProfile)
    }
    
    // MARK: - Swift Cycle Phase Calculation (Based on Backend Logic)
    private func calculateCyclePhaseForDate(_ date: Date, userProfile: UserProfile? = nil) -> CyclePhase? {
        let calendar = Calendar.current
        
        // Use user's actual cycle data if available
        if let profile = userProfile,
           let cycleLength = profile.cycleLength {
            
            // For symptomatic cycles, use symptom data instead of period data
            let isSymptomaticCycle = profile.cycleType == .noPeriod && profile.hasRecurringSymptoms == true
            let lastCycleStart: Date?
            let cycleDuration: Int
            
            if isSymptomaticCycle {
                lastCycleStart = profile.lastSymptomsStart
                cycleDuration = profile.averageSymptomDays ?? 3
            } else {
                lastCycleStart = profile.lastPeriodStart
                cycleDuration = profile.averagePeriodLength ?? 5
            }
            
            if let lastStart = lastCycleStart {
                // Normalize dates to start of day for accurate comparison
                let normalizedDate = calendar.startOfDay(for: date)
                let normalizedLastCycleStart = calendar.startOfDay(for: lastStart)
                
                // Calculate phase boundaries using the same logic as backend phase_finder
                let _ = calculatePhaseBoundaries(
                    lastPeriodStart: normalizedLastCycleStart,
                    cycleLength: cycleLength,
                    periodLength: cycleDuration
                )
                
                // Calculate which cycle this date falls into and determine the phase within that cycle
                let daysSinceLastCycle = calendar.dateComponents([.day], from: normalizedLastCycleStart, to: normalizedDate).day ?? 0
                let cycleDay = (daysSinceLastCycle % cycleLength) + 1
                
                // Calculate phase durations (same as phase boundaries calculation)
                let lutealDuration: Int
                if cycleLength < 21 {
                    lutealDuration = 10
                } else if 24 <= cycleLength && cycleLength <= 26 {
                    lutealDuration = 11
                } else if 28 <= cycleLength && cycleLength <= 30 {
                    lutealDuration = 12
                } else if 31 <= cycleLength && cycleLength <= 34 {
                    lutealDuration = 13
                } else {
                    lutealDuration = 14
                }
                
                let ovulationDuration = 3
                let follicularDuration = cycleLength - (cycleDuration + ovulationDuration + lutealDuration)
                
                // Determine phase based on cycle day
                if cycleDay <= cycleDuration {
                    return .menstrual
                } else if cycleDay <= (cycleDuration + follicularDuration) {
                    return .follicular
                } else if cycleDay <= (cycleDuration + follicularDuration + ovulationDuration) {
                    return .ovulatory
                } else {
                    return .luteal
                }
            }
        }
        
        // Check if user should use moon cycles (no period, no recurring symptoms, but moon cycle enabled)
        if let profile = userProfile,
           profile.cycleType == .noPeriod,
           profile.hasRecurringSymptoms != true,
           let personalizationData = profile.personalizationData,
           personalizationData.useMoonCycle == true {
            return calculateMoonPhaseForDate(date)
        }
        
        // Fallback to default calculation if no user data
        return .follicular
    }
    
    // MARK: - Moon Phase Calculation
    private func calculateMoonPhaseForDate(_ date: Date) -> CyclePhase {
        let calendar = Calendar.current
        
        // Find the nearest New Moon and Full Moon dates
        var nearestNewMoon: Date?
        var nearestFullMoon: Date?
        
        // Search for New Moon and Full Moon within ±30 days to find the closest ones
        for dayOffset in -30...30 {
            let testDate = calendar.date(byAdding: .day, value: dayOffset, to: date) ?? date
            let moon = TinyMoon.calculateMoonPhase(testDate)
            
            if moon.name == "New Moon" {
                if nearestNewMoon == nil || abs(calendar.dateComponents([.day], from: testDate, to: date).day ?? 0) < abs(calendar.dateComponents([.day], from: nearestNewMoon!, to: date).day ?? 0) {
                    nearestNewMoon = testDate
                }
            }
            if moon.name == "Full Moon" {
                if nearestFullMoon == nil || abs(calendar.dateComponents([.day], from: testDate, to: date).day ?? 0) < abs(calendar.dateComponents([.day], from: nearestFullMoon!, to: date).day ?? 0) {
                    nearestFullMoon = testDate
                }
            }
        }
        
        guard let newMoonDate = nearestNewMoon, let fullMoonDate = nearestFullMoon else {
            return .follicularMoon // Fallback
        }
        
        // Calculate days from New Moon and Full Moon
        let daysFromNewMoon = calendar.dateComponents([.day], from: newMoonDate, to: date).day ?? 0
        let daysFromFullMoon = calendar.dateComponents([.day], from: fullMoonDate, to: date).day ?? 0
        
        // Menstrual* (New Moon): 3 days before and 3 days after New Moon (7 days total)
        if abs(daysFromNewMoon) <= 3 {
            return .menstrualMoon
        }
        
        // Ovulatory* (Full Moon): 3 days before and 3 days after Full Moon (7 days total)
        if abs(daysFromFullMoon) <= 3 {
            return .ovulatoryMoon
        }
        
        // Determine if we're in the waxing (follicular) or waning (luteal) phase
        // Waxing: between New Moon period and Full Moon period
        // Waning: between Full Moon period and next New Moon period
        
        if daysFromNewMoon > 3 && daysFromFullMoon < -3 {
            // We're in the waxing phase (between New Moon and Full Moon)
            return .follicularMoon
        } else {
            // We're in the waning phase (between Full Moon and next New Moon)
            return .lutealMoon
        }
    }
    
    // MARK: - Phase Boundary Calculation (Based on Backend phase_finder)
    private func calculatePhaseBoundaries(lastPeriodStart: Date, cycleLength: Int, periodLength: Int) -> (menstrualEnd: Date, follicularEnd: Date, ovulationEnd: Date) {
        let calendar = Calendar.current
        
        // Calculate luteal duration based on cycle length (same logic as backend)
        let lutealDuration: Int
        if cycleLength < 21 {
            lutealDuration = 10
        } else if 24 <= cycleLength && cycleLength <= 26 {
            lutealDuration = 11
        } else if 28 <= cycleLength && cycleLength <= 30 {
            lutealDuration = 12
        } else if 31 <= cycleLength && cycleLength <= 34 {
            lutealDuration = 13
        } else {
            lutealDuration = 14
        }
        
        let ovulationDuration = 3 // OVULATION_DURATION from backend
        
        // Calculate follicular duration
        let follicularDuration = cycleLength - (periodLength + ovulationDuration + lutealDuration)
        
        // Calculate phase end dates
        let menstrualEnd = calendar.date(byAdding: .day, value: periodLength, to: lastPeriodStart) ?? lastPeriodStart
        let follicularEnd = calendar.date(byAdding: .day, value: follicularDuration, to: menstrualEnd) ?? menstrualEnd
        let ovulationEnd = calendar.date(byAdding: .day, value: ovulationDuration, to: follicularEnd) ?? follicularEnd
        
        return (menstrualEnd: menstrualEnd, follicularEnd: follicularEnd, ovulationEnd: ovulationEnd)
    }
    
    // MARK: - Backend Data Phase Lookup
    private func getPhaseFromBackendData(for date: Date) -> CyclePhase? {
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        
        // Look for the date in the backend daily data
        for dayData in latestDailyData {
            if let backendDateString = dayData["date"] as? String,
               backendDateString == dateString,
               let phaseString = dayData["phase"] as? String {
                
                // Map backend moon phase to Swift CyclePhase
                return mapBackendPhaseToSwiftPhase(phaseString)
            }
        }
        
        return nil
    }
    
    func getRawBackendPhaseForDate(_ date: Date, userProfile: UserProfile? = nil) -> String? {
        // Get the calculated phase and return its raw value
        if let phase = calculateCyclePhaseForDate(date, userProfile: userProfile) {
            return phase.rawValue
        }
        
        return "Follicular"
    }
    
    func getLatestDailyData(userProfile: UserProfile? = nil) -> [[String: Any]] {
        // Return the 3-month data that was generated by fetchCyclePredictions
        if !latestDailyData.isEmpty {
            return latestDailyData
        }
        
        // If no data exists, generate basic data for the current month as fallback
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let endOfMonth = calendar.dateInterval(of: .month, for: today)?.end ?? today
        
        var dailyData: [[String: Any]] = []
        var currentDate = startOfMonth
        
        while currentDate < endOfMonth {
            let formatter = ISO8601DateFormatter()
            let phase = calculateCyclePhaseForDate(currentDate, userProfile: userProfile)
            dailyData.append([
                "date": formatter.string(from: currentDate),
                "phase": phase?.rawValue ?? "Follicular"
            ])
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dailyData
    }
    
    func getWideningWindowDays() -> [Date] {
        // First try to get from existing data
        var wideningWindowDates: [Date] = []
        
        for dayData in latestDailyData {
            if let dateString = dayData["date"] as? String,
               let isWideningWindow = dayData["isWideningWindow"] as? Bool,
               isWideningWindow {
                
                let dateFormatter = ISO8601DateFormatter()
                if let date = dateFormatter.date(from: dateString) {
                    wideningWindowDates.append(date)
                }
            }
        }
        
        return wideningWindowDates
    }
    
    // MARK: - Swift Widening Window Calculation (Based on Backend Logic)
    private func calculateWideningWindowDays(menstrualStart: Date, avgCycleLength: Int, numCycles: Int = 3) -> [Date] {
        let calendar = Calendar.current
        let wideningWindowRadiusDays = 4 // WIDENING_WINDOW_RADIUS_DAYS from backend
        
        var wideningWindowDays: [Date] = []
        
        for cycle in 0..<numCycles {
            // Calculate the predicted start date for this cycle
            let predictedStart = calendar.date(byAdding: .day, value: cycle * avgCycleLength, to: menstrualStart) ?? menstrualStart
            
            // Add days before and after the predicted start (widening window)
            for offset in -wideningWindowRadiusDays...wideningWindowRadiusDays {
                if let potentialDate = calendar.date(byAdding: .day, value: offset, to: predictedStart) {
                    wideningWindowDays.append(potentialDate)
                }
            }
        }
        
        return wideningWindowDays
    }
    
    // MARK: - Phase Mapping
    private func mapBackendPhaseToSwiftPhase(_ backendPhase: String) -> CyclePhase? {
        switch backendPhase.lowercased() {
        case "menstrual":
            return .menstrual
        case "symptomatic":
            // For users without periods but with symptoms, symptomatic phase maps to menstrual
            return .menstrual
        case "follicular":
            return .follicular
        case "ovulation":
            return .ovulatory
        case "luteal":
            return .luteal
        // Moon-based phases
        case "new_moon":
            return .menstrualMoon
        case "waxing_moon":
            return .follicularMoon
        case "full_moon":
            return .ovulatoryMoon
        case "waning_moon":
            return .lutealMoon
        default:
            print("⚠️ Warning: Unknown backend phase: '\(backendPhase)'")
            return nil
        }
    }
}

// MARK: - Errors
enum CyclePredictionError: Error, LocalizedError {
    case serverError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Server error occurred"
        case .networkError:
            return "Network error occurred"
        }
    }
}
