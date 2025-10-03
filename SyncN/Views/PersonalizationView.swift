import SwiftUI
import SwiftData
import TelemetryDeck

// MARK: - Timeout Helper
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    let message = "Operation timed out"
}

extension Notification.Name {
    static let presentWeeklyPlanEditor = Notification.Name("presentWeeklyPlanEditor")
}

struct PersonalizationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]
    @Query private var personalizationData: [PersonalizationData]
    
    @State private var currentStep = 0
    @State private var showingFitnessPersonalization = false
    @State private var showingNutritionPersonalization = false
    @State private var showingHealthPersonalization = false
    @State private var showingBraceletInfo = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var userPersonalization: PersonalizationData? {
        personalizationData.first { $0.userId == userProfile?.id }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "star")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                        
                        Text("Personalize Your Experience")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("Complete the steps below to get recommendations tailored to your unique cycle.")
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Personalization Options
                VStack(spacing: 20) {
                    // Track Your Cycle Card
                    PersonalizationOverviewCard(
                        icon: "calendar",
                        title: "Track Your Cycle",
                        description: "Update your cycle information to get phase-specific recommendations",
                        action: { 
                            NotificationCenter.default.post(name: .showOnboarding, object: nil)
                        },
                        buttonText: "Get Started"
                    )
                    
                    // Create Your Fitness Plan Card
                    PersonalizationOverviewCard(
                        icon: "heart.fill",
                        title: "Create Your Fitness Plan",
                        description: "Set your fitness goals and get a customized training plan",
                        action: { 
                            showingFitnessPersonalization = true 
                        },
                        buttonText: "Get Started"
                    )
                    
                    // Personalize Your Nutrition Card
                    PersonalizationOverviewCard(
                        icon: "leaf.fill",
                        title: "Personalize Your Nutrition",
                        description: "Get nutrition habits tailored to your cycle and goals",
                        action: { 
                            showingNutritionPersonalization = true 
                        },
                        buttonText: "Get Started"
                    )
                    
                    // Build Your Cycle Bracelet Card
                    PersonalizationOverviewCard(
                        icon: "circle.grid.cross",
                        title: "Build Your Cycle Bracelet",
                        description: "Track your daily progress and earn beads for completing habits",
                        action: { 
                            TelemetryDeck.signal("Button.Clicked", parameters: [
                                "buttonType": "personalization_card",
                                "cardTitle": "Build Your Cycle Bracelet",
                                "buttonText": "Learn More"
                            ])
                            // This will show the bracelet info popup
                            showingBraceletInfo = true
                        },
                        buttonText: "Learn More"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                Spacer()
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFitnessPersonalization) {
            FitnessPersonalizationView(
                onComplete: {
                    // Close the fitness sheet; Dashboard will present the editor on notification
                    showingFitnessPersonalization = false
                }
            )
        }
        .sheet(isPresented: $showingNutritionPersonalization) {
            NutritionPersonalizationView(
                onComplete: {
                    showingNutritionPersonalization = false
                }
            )
        }
        .sheet(isPresented: $showingHealthPersonalization) {
            HealthPersonalizationView()
        }
        .sheet(isPresented: $showingBraceletInfo) {
            BraceletInfoView()
                .onAppear {
                    TelemetryDeck.signal("Bracelet.InfoViewed", parameters: [
                        "source": "personalization_page"
                    ])
                }
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "Personalization",
                "pageType": "onboarding_feature"
            ])
        }
        .onAppear {
            ensurePersonalizationDataExists()
        }

    }
    
    private func ensurePersonalizationDataExists() {
        guard let userProfile = userProfile,
              userPersonalization == nil else { return }
        
        let personalization = PersonalizationData(userId: userProfile.id)
        modelContext.insert(personalization)
        
        do {
            try modelContext.save()
        } catch {
            print("Error creating personalization data: \(error)")
        }
    }
}

// MARK: - Fitness Personalization View
struct FitnessPersonalizationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var personalizationData: [PersonalizationData]
    @Query private var userProfiles: [UserProfile]
    
    @State private var currentStep = 0
    @State private var fitnessGoals: Set<PersonalizationFitnessGoal> = []
    @State private var fitnessLevel: PersonalizationFitnessLevel?
    @State private var workoutFrequency: WorkoutFrequency?
    @State private var desiredWorkoutFrequency: DesiredWorkoutFrequency?
    @State private var favoriteWorkouts: Set<PersonalizationWorkoutType> = []
    @State private var dislikedWorkouts: Set<PersonalizationWorkoutType> = []
    @State private var injuryEntries: [InjuryEntry] = []
    @State private var syncNSupport: SyncNSupport?
    @State private var existingWorkouts = ""
    @State private var customWorkoutEntries: [CustomWorkoutEntry] = []
    @State private var preferredRestDays: Set<WeekDay> = []
    @State private var planStartChoice: PlanStartChoice?
    
    private let totalSteps = 12
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        if currentStep > 0 {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(currentStep == 0)
                    .opacity(currentStep == 0 ? 0.3 : 1.0)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Progress bar
                PersonalizationProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // Content
                TabView(selection: $currentStep) {
                    FitnessGoalStepView(fitnessGoals: $fitnessGoals)
                        .tag(0)
                    
                    FitnessLevelStepView(fitnessLevel: $fitnessLevel)
                        .tag(1)
                        .onChange(of: fitnessLevel) { _, newValue in
                            if newValue != nil && currentStep == 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                    
                    WorkoutFrequencyStepView(workoutFrequency: $workoutFrequency)
                        .tag(2)
                        .onChange(of: workoutFrequency) { _, newValue in
<<<<<<< HEAD
                            if newValue != nil && currentStep == 2 {
                                withAnimation {
                                    currentStep += 1
=======
                            if let frequency = newValue {
                                // Auto-set desiredWorkoutFrequency based on workoutFrequency selection
                                desiredWorkoutFrequency = mapWorkoutFrequencyToDesired(frequency)
                                print("🔍 PersonalizationView: Auto-mapped workoutFrequency '\(frequency.rawValue)' to desiredWorkoutFrequency '\(desiredWorkoutFrequency?.rawValue ?? "nil")'")
                                
                                if currentStep == 2 {
                                    withAnimation {
                                        currentStep += 1
                                    }
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
                                }
                            }
                        }
                    
                    DesiredWorkoutFrequencyStepView(desiredWorkoutFrequency: $desiredWorkoutFrequency)
                        .tag(3)
                        .onChange(of: desiredWorkoutFrequency) { _, newValue in
                            if newValue != nil && currentStep == 3 {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                    
                    RestDaysStepView(preferredRestDays: $preferredRestDays)
                        .tag(4)
                    
                    WorkoutMotivationStepView()
                        .tag(5)
                    
                    FavoriteWorkoutsStepView(favoriteWorkouts: $favoriteWorkouts)
                        .tag(6)
                    
                    DislikedWorkoutsStepView(dislikedWorkouts: $dislikedWorkouts, favoriteWorkouts: favoriteWorkouts)
                        .tag(7)
                    
                    InjuryFormStepView(injuryEntries: $injuryEntries)
                        .tag(8)
                    
                    SyncNSupportStepView(syncNSupport: $syncNSupport)
                        .tag(9)
                        .onChange(of: syncNSupport) { _, newValue in
                            if newValue != nil && currentStep == 9 {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                    
                    CustomWorkoutEntriesStepView(customWorkoutEntries: $customWorkoutEntries)
                        .tag(10)
                    
                    PlanStartChoiceStepView(planStartChoice: $planStartChoice)
                        .tag(11)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                PersonalizationNavigationButtons(
                    currentStep: $currentStep,
                    totalSteps: totalSteps,
                    canProceed: canProceedToNextStep,
                    onComplete: completeFitnessPersonalization
                )
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationBarHidden(true)
            .onAppear {
                print("🔍 FitnessPersonalizationView: View appeared")
                print("🔍 FitnessPersonalizationView: Starting at step \(currentStep) of \(totalSteps)")
                print("🔍 FitnessPersonalizationView: personalizationData.count = \(personalizationData.count)")
                print("🔍 FitnessPersonalizationView: userProfiles.count = \(userProfiles.count)")
                
                // Track fitness personalization started
                TelemetryDeck.signal("FitnessPersonalization.Started", parameters: [
                    "totalSteps": String(totalSteps)
                ])
                
                // Load existing data if available
                if let personalization = personalizationData.first {
                    customWorkoutEntries = personalization.customWorkoutEntries
                    injuryEntries = personalization.injuryEntries
                    desiredWorkoutFrequency = personalization.desiredWorkoutFrequency
                }
            }
            .onChange(of: currentStep) { _, newStep in
                TelemetryDeck.signal("FitnessPersonalization.Step.Changed", parameters: [
                    "newStep": String(newStep),
                    "stepName": getStepName(for: newStep)
                ])
            }
        }
    }
    
    private var canProceedToNextStep: Bool {
        let canProceed: Bool
        switch currentStep {
        case 0: canProceed = !fitnessGoals.isEmpty
        case 1: canProceed = fitnessLevel != nil
        case 2: canProceed = workoutFrequency != nil
        case 3: canProceed = desiredWorkoutFrequency != nil
        case 4: canProceed = true // Rest days is optional - user can proceed without selecting any
        case 5: canProceed = true // Workout motivation page - informational, always allow proceed
        case 6: canProceed = true // Favorite workouts is optional
        case 7: canProceed = true // Disliked workouts is optional
        case 8: canProceed = true // Past injuries is optional
        case 9: canProceed = syncNSupport != nil
        case 10: canProceed = true // Custom workout entries is optional
        case 11: canProceed = planStartChoice != nil // Plan start choice is required
        default: canProceed = true
        }
        
        print("🔍 PersonalizationView: Step \(currentStep) canProceed = \(canProceed)")
        print("🔍 PersonalizationView: fitnessGoals = \(Array(fitnessGoals).map { $0.rawValue })")
        print("🔍 PersonalizationView: fitnessLevel = \(fitnessLevel?.rawValue ?? "nil")")
        print("🔍 PersonalizationView: workoutFrequency = \(workoutFrequency?.rawValue ?? "nil")")
<<<<<<< HEAD
=======
        print("🔍 PersonalizationView: desiredWorkoutFrequency = \(desiredWorkoutFrequency?.rawValue ?? "nil")")
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
        print("🔍 PersonalizationView: favoriteWorkouts.count = \(favoriteWorkouts.count)")
        print("🔍 PersonalizationView: syncNSupport = \(syncNSupport?.rawValue ?? "nil")")
        print("🔍 PersonalizationView: preferredRestDays.count = \(preferredRestDays.count)")
        print("🔍 PersonalizationView: planStartChoice = \(planStartChoice?.rawValue ?? "nil")")
        
        return canProceed
    }
    
<<<<<<< HEAD
=======
    // Helper function to map WorkoutFrequency to DesiredWorkoutFrequency
    private func mapWorkoutFrequencyToDesired(_ frequency: WorkoutFrequency) -> DesiredWorkoutFrequency {
        switch frequency {
        case .zeroToOne:
            return .one      // "0-1 times" -> "1 day"
        case .twoToThree:
            return .three    // "2-3 times" -> "3 days" (use higher end)
        case .fourToFive:
            return .five     // "4-5 times" -> "5 days" (use higher end)
        case .sixToSeven:
            return .six      // "6-7 times" -> "6 days" (cap at 6 for rest days)
        case .eightPlus:
            return .six      // "8+" -> "6 days" (cap for safety)
        }
    }
    
>>>>>>> 34c6b149dd078a3388481570398d8fb3d1d86e0d
    private func completeFitnessPersonalization() {
        print("🎯 PERSONALIZATION COMPLETION TRIGGERED!")
        print("🎯 Starting fitness personalization completion...")
        
        // Provide haptic feedback for completion
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("🎯 Checking personalization data...")
        print("🎯 personalizationData.count: \(personalizationData.count)")
        print("🎯 userProfiles.count: \(userProfiles.count)")
        
        guard let personalization = personalizationData.first,
              let userProfile = userProfiles.first else { 
            print("❌ PERSONALIZATION COMPLETION FAILED: Missing personalization data or user profile")
            return 
        }
        
        print("🎯 Found personalization data and user profile, proceeding...")
        
        // Track fitness personalization completion
        TelemetryDeck.signal("FitnessPersonalization.Completed", parameters: [
            "fitnessGoals": Array(fitnessGoals).map { $0.rawValue }.joined(separator: ","),
            "fitnessLevel": fitnessLevel?.rawValue ?? "none",
            "workoutFrequency": workoutFrequency?.rawValue ?? "none",
            "desiredWorkoutFrequency": desiredWorkoutFrequency?.rawValue ?? "none",
            "favoriteWorkouts": Array(favoriteWorkouts).map { $0.rawValue }.joined(separator: ","),
            "dislikedWorkouts": Array(dislikedWorkouts).map { $0.rawValue }.joined(separator: ","),
            "injuryCount": String(injuryEntries.count),
            "syncNSupport": syncNSupport?.rawValue ?? "none",
            "customWorkoutCount": String(customWorkoutEntries.count),
            "preferredRestDays": Array(preferredRestDays).map { $0.rawValue }.joined(separator: ","),
            "planStartChoice": planStartChoice?.rawValue ?? "none"
        ])
        
        personalization.fitnessGoalsString = Array(fitnessGoals).map { $0.rawValue }.joined(separator: ",")
        personalization.fitnessLevel = fitnessLevel
        personalization.workoutFrequency = workoutFrequency
        personalization.desiredWorkoutFrequency = desiredWorkoutFrequency
        personalization.favoriteWorkoutsString = Array(favoriteWorkouts).map { $0.rawValue }.joined(separator: ",")
        personalization.dislikedWorkoutsString = Array(dislikedWorkouts).map { $0.rawValue }.joined(separator: ",")
        personalization.injuryEntries = injuryEntries
        personalization.syncNSupport = syncNSupport
        personalization.existingWorkouts = existingWorkouts.isEmpty ? nil : existingWorkouts
        personalization.customWorkoutEntries = customWorkoutEntries
        personalization.preferredRestDaysString = Array(preferredRestDays).map { $0.rawValue }.joined(separator: ",")
        personalization.planStartChoice = planStartChoice
        personalization.fitnessCompleted = true
        personalization.updatedAt = Date()
        
        do {
            try modelContext.save()
            
            // Convert custom workout entries to CustomWorkout objects and save to user profile
            saveCustomWorkoutEntriesToUserProfile()
            
            // Only generate fitness plan if BOTH cycle tracking AND fitness personalization are completed
            print("🔍 DEBUG: Checking fitness plan generation conditions...")
            print("🔍 DEBUG: cycleCompleted = \(personalization.cycleCompleted ?? false)")
            print("🔍 DEBUG: fitnessCompleted = \(personalization.fitnessCompleted ?? false)")
            
            if personalization.cycleCompleted == true && personalization.fitnessCompleted == true {
                print("🎯 Both cycle tracking and fitness personalization completed - generating fitness plan...")
                
                Task {
                    do {
                        print("🎯 Generating 14-day fitness plan after both personalizations are complete...")
                        
                        // Use user's choice for when to start the plan
                        let calendar = Calendar.current
                        let now = Date()
                        let startOfDay = calendar.startOfDay(for: now)
                        
                        let planStartDate: Date
                        if planStartChoice == .tomorrow {
                            planStartDate = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
                            print("🎯 User chose to start plan tomorrow: \(planStartDate)")
                        } else {
                            planStartDate = startOfDay
                            print("🎯 User chose to start plan today: \(planStartDate)")
                        }
                        
                        print("🔍 DEBUG: About to call fetchWeeklyFitnessPlan...")
                        
                        // Add timeout to prevent infinite freeze
                        let weeklyPlan = try await withTimeout(seconds: 30) {
                            let userPreferences = UserPreferences(from: personalization)
                            // The operation needs to be async to be used with withTimeout
                            return await Task {
                                SwiftFitnessRecommendationEngine.shared.generateWeeklyFitnessPlan(for: userProfile, startDate: planStartDate, userPreferences: userPreferences)
                            }.value
                        }
                        print("🔍 DEBUG: fetchWeeklyFitnessPlan returned \(weeklyPlan.count) entries")
                        
                        await MainActor.run {
                            print("🔍 PersonalizationView: Received \(weeklyPlan.count) workout entries from API")
                            
                            // Debug: Show what we received
                            for (index, entry) in weeklyPlan.enumerated() {
                                print("🔍 PersonalizationView: Entry \(index): \(entry.workoutTitle) - \(entry.workoutType.rawValue) - Date: \(entry.date)")
                            }
                            
                            // Replace the existing fitness plan with the new one
                            userProfile.weeklyFitnessPlan = weeklyPlan
                            
                            print("🔍 PersonalizationView: User now has \(userProfile.weeklyFitnessPlan.count) total workout entries")
                            print("🔍 PersonalizationView: First few entries:")
                            for (index, entry) in userProfile.weeklyFitnessPlan.prefix(5).enumerated() {
                                print("🔍 PersonalizationView: Saved Entry \(index): \(entry.workoutTitle) on \(entry.date)")
                            }
                            
                            do {
                                try modelContext.save()
                                print("✅ 14-day fitness plan generated and saved successfully!")
                                
                                // Notify Dashboard to present the editor
                                NotificationCenter.default.post(name: .presentWeeklyPlanEditor, object: nil)
                                
                                // Ask parent to dismiss this sheet
                                onComplete()
                            } catch {
                                print("❌ Error saving generated fitness plan: \(error)")
                            }
                        }
                    } catch {
                        await MainActor.run {
                            print("❌ Error generating fitness plan: \(error)")
                            if let _ = error as? TimeoutError {
                                print("❌ Fitness plan generation timed out after 30 seconds")
                            } else {
                                print("❌ Fitness plan generation failed with error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            } else {
                print("🔍 DEBUG: Fitness plan generation skipped - conditions not met")
                print("🔍 DEBUG: cycleCompleted = \(personalization.cycleCompleted ?? false)")
                print("🔍 DEBUG: fitnessCompleted = \(personalization.fitnessCompleted ?? false)")
                print("🎯 Fitness personalization completed, but cycle tracking not yet completed. Fitness plan will be generated when both are done.")
            }
            
            // Do not dismiss here; parent will handle presentation of the editor via notification/onComplete
        } catch {
            print("Error saving fitness personalization: \(error)")
        }
    }
    
    private func saveCustomWorkoutEntriesToUserProfile() {
        guard let userProfile = userProfiles.first else {
            print("❌ No user profile found to save custom workout entries")
            return
        }
        
        print("🎯 Converting \(customWorkoutEntries.count) custom workout entries to CustomWorkout objects...")
        
        for entry in customWorkoutEntries {
            // Only save entries that have a name (user has filled out at least the name)
            if !entry.name.isEmpty {
                let customWorkout = CustomWorkout(
                    name: entry.name,
                    activityType: entry.activityType,
                    intensity: entry.intensity,
                    duration: entry.duration
                )
                
                // Add to user profile's custom workouts
                userProfile.customWorkouts.append(customWorkout)
                
                print("✅ Added custom workout: \(entry.name) (\(entry.activityType), \(entry.intensity), \(entry.duration))")
            }
        }
        
        // Save the updated user profile
        do {
            try modelContext.save()
            print("✅ Successfully saved \(userProfile.customWorkouts.count) custom workouts to user profile")
        } catch {
            print("❌ Failed to save custom workouts to user profile: \(error)")
        }
    }
    
    private func getStepName(for step: Int) -> String {
        switch step {
        case 0: return "fitness_goals"
        case 1: return "fitness_level"
        case 2: return "workout_frequency"
        case 3: return "desired_workout_frequency"
        case 4: return "rest_days"
        case 5: return "workout_motivation"
        case 6: return "favorite_workouts"
        case 7: return "disliked_workouts"
        case 8: return "injury_form"
        case 9: return "syncn_support"
        case 10: return "custom_workout_entries"
        case 11: return "plan_start_choice"
        default: return "unknown"
        }
    }
}

// MARK: - Progress Bar
struct PersonalizationProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(Color(red: 0.608, green: 0.431, blue: 0.953))
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                    .cornerRadius(2)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Navigation Buttons
struct PersonalizationNavigationButtons: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    let canProceed: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Continue/Complete button
            Button(currentStep == totalSteps - 1 ? "Complete" : "Continue") {
                print("🔘 PersonalizationNavigationButtons: Button pressed!")
                print("🔘 Current step: \(currentStep), Total steps: \(totalSteps)")
                print("🔘 Can proceed: \(canProceed)")
                
                if currentStep == totalSteps - 1 {
                    print("🔘 Calling onComplete() function...")
                    // No animation for completion to prevent scrolling
                    onComplete()
                } else {
                    print("🔘 Moving to next step...")
                    withAnimation {
                        currentStep += 1
                    }
                }
            }
            .font(.sofiaProHeadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canProceed ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color.gray)
            .cornerRadius(12)
            .disabled(!canProceed)
            

        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Nutrition Personalization View
struct NutritionPersonalizationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var personalizationData: [PersonalizationData]
    
    @State private var currentStep = 0
    @State private var nutritionGoals: Set<NutritionGoal> = []
    @State private var eatingApproaches: Set<EatingApproach> = []
    @State private var breakfastFrequency: MealFrequency?
    @State private var lunchFrequency: MealFrequency?
    @State private var dinnerFrequency: MealFrequency?
    @State private var snacksFrequency: MealFrequency?
    @State private var dessertFrequency: MealFrequency?
    @State private var weightChange: WeightChange?
    @State private var eatingDisorderHistory: EatingDisorderHistory?
    @State private var weight: Double?
    @State private var heightFeet: Int?
    @State private var heightInches: Int?
    
    private let totalSteps = 7
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        if currentStep > 0 {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(currentStep == 0)
                    .opacity(currentStep == 0 ? 0.3 : 1.0)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Progress bar
                PersonalizationProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // Content
                TabView(selection: $currentStep) {
                    NutritionGoalsStepView(nutritionGoals: $nutritionGoals)
                        .tag(0)
                    
                    EatingApproachStepView(eatingApproaches: $eatingApproaches)
                        .tag(1)
                    
                    MealFrequencyStepView(
                        breakfastFrequency: $breakfastFrequency,
                        lunchFrequency: $lunchFrequency,
                        dinnerFrequency: $dinnerFrequency,
                        snacksFrequency: $snacksFrequency,
                        dessertFrequency: $dessertFrequency
                    )
                    .tag(2)
                    
                    MetabolismInfoStepView()
                        .tag(3)
                    
                    WeightChangeStepView(weightChange: $weightChange)
                        .tag(4)
                    
                    EatingDisorderHistoryStepView(eatingDisorderHistory: $eatingDisorderHistory)
                        .tag(5)
                    
                    HeightWeightStepView(
                        heightFeet: $heightFeet,
                        heightInches: $heightInches,
                        weight: $weight
                    )
                    .tag(6)
                    
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                PersonalizationNavigationButtons(
                    currentStep: $currentStep,
                    totalSteps: totalSteps,
                    canProceed: canProceedToNextStep,
                    onComplete: completeNutritionPersonalization
                )
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationBarHidden(true)
        }
    }
    
    private var canProceedToNextStep: Bool {
        // All nutrition personalization fields are optional
        return true
    }
    
    private func completeNutritionPersonalization() {
        // Provide haptic feedback for completion
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        guard let personalization = personalizationData.first else { return }
        
        personalization.nutritionGoalsString = Array(nutritionGoals).map { $0.rawValue }.joined(separator: ",")
        personalization.eatingApproachesString = Array(eatingApproaches).map { $0.rawValue }.joined(separator: ",")
        personalization.breakfastFrequency = breakfastFrequency
        personalization.lunchFrequency = lunchFrequency
        personalization.dinnerFrequency = dinnerFrequency
        personalization.snacksFrequency = snacksFrequency
        personalization.dessertFrequency = dessertFrequency
        personalization.weightChange = weightChange
        personalization.eatingDisorderHistory = eatingDisorderHistory
        personalization.weight = weight
        personalization.heightFeet = heightFeet
        personalization.heightInches = heightInches
        personalization.nutritionCompleted = true
        personalization.updatedAt = Date()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving nutrition personalization: \(error)")
        }
    }
}


struct HealthPersonalizationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Health Personalization")
                    .font(.sofiaProTitle2)
                    .foregroundColor(.white)
                
                Text("Coming soon...")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Button("Close") {
                    dismiss()
                }
                .padding()
                .background(Color(red: 0.608, green: 0.431, blue: 0.953))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Workout Motivation Step View
struct WorkoutMotivationStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("There's no 'bad' workout.")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("By telling us what you love (and what you don't), we can build a plan that feels energizing, not draining, for each phase of your cycle.")
                    .font(.sofiaProBody)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}