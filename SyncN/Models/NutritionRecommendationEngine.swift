import Foundation
import SwiftUI

// MARK: - Nutrition Habit from CSV
struct NutritionHabit: Identifiable {
    let id = UUID()
    let title: String
    let examples: String
    let whyBehind: String
    let phases: [CyclePhase]
    let symptoms: [PeriodSymptom]
    let nutritionGoals: [NutritionGoal]
    let eatingDisorderSafe: Bool
    let icon: String
    let color: Color
    
    // Convert to legacy Habit format
    var toLegacyHabit: Habit {
        return Habit(
            name: title,
            icon: icon,
            color: color,
            completed: false,
            foods: examples.components(separatedBy: ", "),
            benefits: whyBehind
        )
    }
}

struct NutritionRecommendationEngine {
    
    // MARK: - All Nutrition Habits from CSV
    static let allHabits: [NutritionHabit] = [
        // Follicular Phase Habits
        NutritionHabit(
            title: "Nutrient-rich foods",
            examples: "Fruits, vegetables, whole grains, lean protein, healthy fats",
            whyBehind: "Provide essential nutrients and fiber, promoting satiety and reducing cravings",
            phases: [.follicular],
            symptoms: [.foodCravings],
            nutritionGoals: [.reduceCravings, .increaseEnergy, .loseWeight],
            eatingDisorderSafe: true,
            icon: "leaf.fill",
            color: .green
        ),
        
        NutritionHabit(
            title: "Omega-3 fatty acids",
            examples: "Fatty fish (salmon, tuna), flaxseeds, chia seeds, walnuts",
            whyBehind: "Reduce inflammation, support healthy estrogen rise",
            phases: [.follicular],
            symptoms: [.moodswings],
            nutritionGoals: [.balanceHormones],
            eatingDisorderSafe: true,
            icon: "fish.fill",
            color: .blue
        ),
        
        // Ovulation Phase Habits
        NutritionHabit(
            title: "Antioxidant-rich foods",
            examples: "Berries, dark leafy greens, pomegranate, dark chocolate",
            whyBehind: "Protect egg quality, support reproductive health",
            phases: [.ovulatory],
            symptoms: [.cramps],
            nutritionGoals: [.balanceHormones],
            eatingDisorderSafe: true,
            icon: "heart.fill",
            color: .red
        ),
        
        NutritionHabit(
            title: "Protein for energy",
            examples: "Lean meats, eggs, Greek yogurt, tofu, beans",
            whyBehind: "Muscle repair and growth for increased activity",
            phases: [.ovulatory],
            symptoms: [.foodCravings],
            nutritionGoals: [.reduceCravings, .increaseEnergy],
            eatingDisorderSafe: true,
            icon: "dumbbell.fill",
            color: .purple
        ),
        
        // Luteal Phase Habits
        NutritionHabit(
            title: "Complex carbohydrates",
            examples: "Whole grains (brown rice, quinoa), sweet potatoes, legumes",
            whyBehind: "Stabilize blood sugar, mood, and provide sustained energy",
            phases: [.luteal],
            symptoms: [.anxiety],
            nutritionGoals: [.balanceHormones, .increaseEnergy],
            eatingDisorderSafe: true,
            icon: "grain.fill",
            color: .brown
        ),
        
        NutritionHabit(
            title: "Magnesium-rich foods",
            examples: "Dark chocolate, nuts, seeds, leafy greens, avocado",
            whyBehind: "Ease cramps, mood swings, and anxiety",
            phases: [.luteal],
            symptoms: [.anxiety, .cramps, .headaches, .insomnia],
            nutritionGoals: [.balanceHormones],
            eatingDisorderSafe: true,
            icon: "bolt.fill",
            color: .orange
        ),
        
        // Menstrual Phase Habits
        NutritionHabit(
            title: "Iron-rich foods",
            examples: "Red meat, leafy greens, beans, lentils, dried fruits",
            whyBehind: "Replenish iron, boost energy",
            phases: [.menstrual],
            symptoms: [],
            nutritionGoals: [.increaseEnergy],
            eatingDisorderSafe: true,
            icon: "heart.fill",
            color: .red
        ),
        
        NutritionHabit(
            title: "Extra water",
            examples: "Increase water intake, herbal teas, electrolyte drinks",
            whyBehind: "Replenish fluids, reduce bloating",
            phases: [.menstrual],
            symptoms: [.headaches, .bloating],
            nutritionGoals: [.increaseEnergy, .loseWeight],
            eatingDisorderSafe: true,
            icon: "drop.fill",
            color: .blue
        ),
        
        // Foods to Avoid
        NutritionHabit(
            title: "Reduce alcohol intake",
            examples: "Limit or avoid alcohol consumption",
            whyBehind: "Lessen PMS symptoms, improve sleep",
            phases: [.luteal, .menstrual],
            symptoms: [.insomnia],
            nutritionGoals: [.loseWeight],
            eatingDisorderSafe: false,
            icon: "xmark.circle.fill",
            color: .red
        ),
        
        NutritionHabit(
            title: "Avoid sugary drinks",
            examples: "Choose water, unsweetened tea, or sparkling water",
            whyBehind: "Prevent blood sugar spikes and crashes",
            phases: [.follicular, .ovulatory, .luteal, .menstrual],
            symptoms: [.headaches, .bloating],
            nutritionGoals: [.reduceCravings, .increaseEnergy, .loseWeight],
            eatingDisorderSafe: false,
            icon: "xmark.circle.fill",
            color: .red
        ),
        
        // General Habits
        NutritionHabit(
            title: "Don't skip meals",
            examples: "Eat regular meals and snacks throughout the day",
            whyBehind: "Prevent blood sugar fluctuations",
            phases: [.follicular, .ovulatory, .luteal, .menstrual],
            symptoms: [],
            nutritionGoals: [.reduceCravings, .increaseEnergy, .loseWeight, .improveFoodRelationship],
            eatingDisorderSafe: true,
            icon: "clock.fill",
            color: .orange
        ),
        
        NutritionHabit(
            title: "Combine protein and fiber",
            examples: "Apple with almond butter, salad with grilled chicken",
            whyBehind: "Stabilize blood sugar and provide sustained energy",
            phases: [.follicular, .ovulatory, .luteal, .menstrual],
            symptoms: [],
            nutritionGoals: [.reduceCravings, .increaseEnergy, .loseWeight, .improveFoodRelationship],
            eatingDisorderSafe: true,
            icon: "link.circle.fill",
            color: .purple
        ),
        
        NutritionHabit(
            title: "Choose whole grains",
            examples: "Brown rice instead of white, whole-wheat bread",
            whyBehind: "Provide sustained energy and stabilize blood sugar",
            phases: [.follicular, .ovulatory, .luteal, .menstrual],
            symptoms: [],
            nutritionGoals: [.reduceCravings, .increaseEnergy, .loseWeight, .improveFoodRelationship],
            eatingDisorderSafe: true,
            icon: "grain.fill",
            color: .brown
        ),
        
        NutritionHabit(
            title: "Mindful eating",
            examples: "Pay attention to hunger cues, eat slowly, savor food",
            whyBehind: "Tune in to your body's signals and avoid overeating",
            phases: [.follicular, .ovulatory, .luteal, .menstrual],
            symptoms: [],
            nutritionGoals: [.loseWeight, .improveFoodRelationship],
            eatingDisorderSafe: true,
            icon: "brain.head.profile",
            color: .purple
        ),
        
        NutritionHabit(
            title: "Sleep well",
            examples: "Aim for 7-9 hours of quality sleep per night",
            whyBehind: "Sleep is essential for restoring energy and hormone balance",
            phases: [.follicular, .ovulatory, .luteal, .menstrual],
            symptoms: [],
            nutritionGoals: [.increaseEnergy, .balanceHormones],
            eatingDisorderSafe: true,
            icon: "moon.fill",
            color: .indigo
        )
    ]
    
    // MARK: - Generate 2 Habits for Today Page
    static func generateTodayRecommendations(for userProfile: UserProfile) -> [NutritionHabit] {
        let currentPhase = userProfile.calculateCyclePhaseForDate(Date())
        
        // Get user's nutrition data from PersonalizationData
        let personalization = userProfile.personalizationData
        let nutritionGoals = getNutritionGoals(from: personalization)
        let symptoms = getPeriodSymptoms(from: personalization)
        let hasEatingDisorder = getEatingDisorderHistory(from: personalization)
        
        // Filter habits based on user data
        var filteredHabits = allHabits.filter { habit in
            // Priority 1: Eating disorder safety
            if hasEatingDisorder && !habit.eatingDisorderSafe {
                return false
            }
            
            // Priority 2: Current cycle phase
            if habit.phases.contains(currentPhase) {
                return true
            }
            
            // Priority 3: User's symptoms
            if !habit.symptoms.isEmpty && !Set(habit.symptoms).intersection(Set(symptoms)).isEmpty {
                return true
            }
            
            // Priority 4: User's nutrition goals
            if !habit.nutritionGoals.isEmpty && !Set(habit.nutritionGoals).intersection(Set(nutritionGoals)).isEmpty {
                return true
            }
            
            // Priority 5: General habits (no specific phase)
            if habit.phases.isEmpty {
                return true
            }
            
            return false
        }
        
        // Sort by priority
        filteredHabits.sort { habit1, habit2 in
            let priority1 = calculatePriority(for: habit1, currentPhase: currentPhase, symptoms: symptoms, goals: nutritionGoals, hasEatingDisorder: hasEatingDisorder)
            let priority2 = calculatePriority(for: habit2, currentPhase: currentPhase, symptoms: symptoms, goals: nutritionGoals, hasEatingDisorder: hasEatingDisorder)
            return priority1 > priority2
        }
        
        // Return top 2 habits
        return Array(filteredHabits.prefix(2))
    }
    
    // MARK: - Helper Methods
    
    private static func getNutritionGoals(from personalization: PersonalizationData?) -> [NutritionGoal] {
        guard let personalization = personalization,
              let goalsString = personalization.nutritionGoalsString else {
            return []
        }
        
        return goalsString.components(separatedBy: ",")
            .compactMap { NutritionGoal(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
    }
    
    private static func getPeriodSymptoms(from personalization: PersonalizationData?) -> [PeriodSymptom] {
        guard let personalization = personalization,
              let symptomsString = personalization.periodSymptomsString else {
            return []
        }
        
        return symptomsString.components(separatedBy: ",")
            .compactMap { PeriodSymptom(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
    }
    
    private static func getEatingDisorderHistory(from personalization: PersonalizationData?) -> Bool {
        guard let personalization = personalization,
              let history = personalization.eatingDisorderHistory else {
            return false
        }
        
        return history == .yes
    }
    
    private static func calculatePriority(for habit: NutritionHabit, currentPhase: CyclePhase, symptoms: [PeriodSymptom], goals: [NutritionGoal], hasEatingDisorder: Bool) -> Int {
        var priority = 0
        
        // Eating disorder safety (highest priority)
        if hasEatingDisorder && habit.eatingDisorderSafe {
            priority += 100
        }
        
        // Current phase match
        if habit.phases.contains(currentPhase) {
            priority += 50
        }
        
        // Symptom match
        if !habit.symptoms.isEmpty && !Set(habit.symptoms).intersection(Set(symptoms)).isEmpty {
            priority += 25
        }
        
        // Goal match
        if !habit.nutritionGoals.isEmpty && !Set(habit.nutritionGoals).intersection(Set(goals)).isEmpty {
            priority += 10
        }
        
        return priority
    }
    
    // MARK: - Legacy Support
    static func generateRecommendations(for userProfile: UserProfile) -> (habits: [Habit], recipes: [Recipe], foodsToLimit: [String]) {
        // Generate 2 habits for current phase (for today's display)
        let todayHabits = generateTodayRecommendations(for: userProfile)
        
        let legacyHabits = todayHabits.map { $0.toLegacyHabit }
        
        let sampleRecipes = [
            Recipe(name: "Green Smoothie"),
            Recipe(name: "Quinoa Salad")
        ]
        
        let foodsToLimit = [
            "Processed foods",
            "Excessive caffeine",
            "High sugar snacks",
            "Alcohol"
        ]
        
        return (habits: legacyHabits, recipes: sampleRecipes, foodsToLimit: foodsToLimit)
    }
    
    // MARK: - Monthly Recommendations (2 per phase as specified)
    static func generateMonthlyRecommendations(for userProfile: UserProfile) -> [CyclePhase: [NutritionHabit]] {
        let personalization = userProfile.personalizationData
        let nutritionGoals = getNutritionGoals(from: personalization)
        let symptoms = getPeriodSymptoms(from: personalization)
        let hasEatingDisorder = getEatingDisorderHistory(from: personalization)
        
        var monthlyRecommendations: [CyclePhase: [NutritionHabit]] = [:]
        
        // Generate 2 habits for each cycle phase
        let phases: [CyclePhase] = [.follicular, .ovulatory, .luteal, .menstrual]
        
        for phase in phases {
            // Filter habits for this specific phase
            var phaseHabits = allHabits.filter { habit in
                // Priority 1: Eating disorder safety
                if hasEatingDisorder && !habit.eatingDisorderSafe {
                    return false
                }
                
                // Must match the specific phase
                return habit.phases.contains(phase)
            }
            
            // Sort by priority for this phase
            phaseHabits.sort { habit1, habit2 in
                let priority1 = calculatePriority(for: habit1, currentPhase: phase, symptoms: symptoms, goals: nutritionGoals, hasEatingDisorder: hasEatingDisorder)
                let priority2 = calculatePriority(for: habit2, currentPhase: phase, symptoms: symptoms, goals: nutritionGoals, hasEatingDisorder: hasEatingDisorder)
                return priority1 > priority2
            }
            
            // Take top 2 habits for this phase
            monthlyRecommendations[phase] = Array(phaseHabits.prefix(2))
        }
        
        return monthlyRecommendations
    }
}

struct Habit: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    var completed: Bool
    let foods: [String]
    let benefits: String
}

struct Recipe {
    let name: String
}