import SwiftUI
import SwiftData
import TelemetryDeck

struct ExploreView: View {
    @State private var showingWorkoutLibrary = false
    @State private var selectedWorkout: Workout?
    @State private var selectedEducationClass: EducationClass?
    @State private var selectedPhase: PhaseInfo?
    @State private var showingRaceTrainingSetup = false
    @State private var selectedRaceType: String?
    
    private var featuredWorkouts: [Workout] {
        let allWorkouts = WorkoutData.getSampleWorkouts()
        // Show a variety of workouts from different phases and types
        return Array(allWorkouts.prefix(6)) // Show first 6 workouts
    }
    
    private var hormoneEducationClasses: [EducationClass] {
        return EducationClassesData.shared.getHormoneClasses()
    }
    
    private var phases: [PhaseInfo] {
        let allPhases = PhaseInfoData.shared.getAllPhases()
        // Return phases in the specified order: follicular, ovulation, luteal, menstrual
        return [
            allPhases.first { $0.name.lowercased() == "follicular" },
            allPhases.first { $0.name.lowercased() == "ovulation" },
            allPhases.first { $0.name.lowercased() == "luteal" },
            allPhases.first { $0.name.lowercased() == "menstrual" }
        ].compactMap { $0 }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Workouts Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Workouts")
                                .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("See more >") {
                                TelemetryDeck.signal("Button.Clicked", parameters: [
                                    "buttonType": "see_more_workouts",
                                    "location": "explore_page"
                                ])
                                showingWorkoutLibrary = true
                            }
                            .font(.custom("Sofia Pro", size: 16, relativeTo: .subheadline))
                            .foregroundColor(Color(red: 0.608, green: 0.431, blue: 0.953))
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(featuredWorkouts, id: \.id) { workout in
                                    ExploreWorkoutCard(workout: workout)
                                        .onTapGesture {
                                            TelemetryDeck.signal("Button.Clicked", parameters: [
                                                "buttonType": "workout_card",
                                                "workoutTitle": workout.title,
                                                "workoutPhase": workout.cyclePhase.rawValue,
                                                "location": "explore_page"
                                            ])
                                            
                                            // Track workout engagement from explore page
                                            TelemetryDeck.signal("Workout.Engaged", parameters: [
                                                "workoutTitle": workout.title,
                                                "workoutType": workout.workoutType.rawValue,
                                                "duration": "\(workout.duration)",
                                                "cyclePhase": workout.cyclePhase.rawValue,
                                                "instructor": workout.instructor ?? "Unknown",
                                                "source": "explore_page"
                                            ])
                                            
                                            selectedWorkout = workout
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Cycle Phases Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cycle Phases")
                            .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(phases, id: \.id) { phase in
                                CyclePhaseCard(
                                    title: phase.name.capitalized,
                                    days: phase.phaseDurationDays,
                                    energy: phase.energy.capitalized,
                                    color: phaseColor(for: phase.name)
                                )
                                .onTapGesture {
                                    TelemetryDeck.signal("Button.Clicked", parameters: [
                                        "buttonType": "phase_card",
                                        "phaseName": phase.name,
                                        "location": "explore_page"
                                    ])
                                    selectedPhase = phase
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Meet Your Hormones Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meet Your Hormones")
                            .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(hormoneEducationClasses, id: \.id) { educationClass in
                                    EducationClassCard(educationClass: educationClass)
                                        .onTapGesture {
                                            TelemetryDeck.signal("Button.Clicked", parameters: [
                                                "buttonType": "education_class_card",
                                                "classTitle": educationClass.title,
                                                "location": "explore_page"
                                            ])
                                            selectedEducationClass = educationClass
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Featured Programs Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Featured Programs")
                            .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        RaceTrainingProgramCard(
                            title: "Race Training Program",
                            subtitle: "Personalized cycle-synced training plans",
                            imageName: "race_training"
                        ) {
                            showingRaceTrainingSetup = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom spacing
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingWorkoutLibrary) {
            WorkoutLibraryView()
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
        .sheet(item: $selectedEducationClass) { educationClass in
            EducationVideoPlayerView(educationClass: educationClass)
        }
        .sheet(item: $selectedPhase) { phase in
            PhaseDetailView(phaseInfo: phase)
        }
        .sheet(isPresented: $showingRaceTrainingSetup) {
            RaceTrainingSetupView()
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "Explore",
                "pageType": "main_feature"
            ])
        }
    }
    
    private func phaseColor(for phaseName: String) -> Color {
        switch phaseName.lowercased() {
        case "menstrual":
            return Color(red: 1.0, green: 0.23, blue: 0.24) // #ff3b3d for menstrual
        case "follicular":
            return Color(red: 1.0, green: 0.85, blue: 0.01) // #ffda03 for follicular
        case "ovulation":
            return Color(red: 0.35, green: 0.86, blue: 0.98) // #5adbf9 for ovulation
        case "luteal":
            return Color(red: 0.75, green: 0.88, blue: 0.70) // #bee0b3 for luteal
        default:
            return .gray
        }
    }
}

// MARK: - Explore Workout Card
struct ExploreWorkoutCard: View {
    let workout: Workout
    
    private var difficultyText: String {
        switch workout.difficulty {
        case .beginner: return "Low"
        case .intermediate: return "Medium"
        case .advanced: return "High"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Phase-specific workout image
            Image(workout.cyclePhase.frameImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 160, height: 100)
                .clipped()
                .overlay(
                    // Phase icon overlay
                    Image(workout.cyclePhase.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                )
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(workout.cyclePhase.displayName.capitalized)
                        .font(.custom("Sofia Pro", size: 10, relativeTo: .caption2))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(workout.cyclePhase.color.opacity(0.2))
                        .cornerRadius(6)
                    
                    Text("\(difficultyText) | \(workout.duration) min")
                        .font(.custom("Sofia Pro", size: 10, relativeTo: .caption2))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(width: 160)
    }
}

// MARK: - Cycle Phase Card
struct CyclePhaseCard: View {
    let title: String
    let days: String
    let energy: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Phase-specific icon with phase color background
            Rectangle()
                .fill(color) // Use full phase color as background
                .frame(height: 100)
                .overlay(
                    Image(phaseIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40) // Made icon smaller again
                        .foregroundColor(.white)
                )
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(days)
                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(energy)
                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var phaseIcon: String {
        switch title.lowercased() {
        case "menstrual":
            return "Menstrual Icon"
        case "follicular":
            return "Follicular Icon"
        case "ovulation":
            return "Ovulation Icon"
        case "luteal":
            return "Luteal Icon"
        default:
            return "figure.mind.and.body"
        }
    }
}

// MARK: - Hormone Card
struct HormoneCard: View {
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Placeholder for hormone image
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 150, height: 100)
                .overlay(
                    VStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 12)
                        
                        Spacer()
                    }
                )
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(description)
                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .frame(width: 150)
    }
}


// MARK: - Education Class Card
struct EducationClassCard: View {
    let educationClass: EducationClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Video thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 200, height: 120)
                
                // Play button
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(educationClass.title)
                    .font(.custom("Sofia Pro", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(educationClass.duration)
                    .font(.custom("Sofia Pro", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 200)
    }
}

// MARK: - Race Training Program Card
struct RaceTrainingProgramCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Runner image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    // Runner icon
                    Image(systemName: "figure.run")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Sofia Pro", size: 18, relativeTo: .headline))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.12, green: 0.15, blue: 0.21))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Race Training Setup View
struct RaceTrainingSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var personalizationData: [PersonalizationData]
    @State private var showingTrainingPlan = false
    
    @State private var selectedRaceType: String = ""
    @State private var raceDate = Date()
    @State private var trainingStartDate = Date()
    @State private var runnerLevel: String = ""
    @State private var runDaysPerWeek: Int = 0
    @State private var crossTrainDaysPerWeek: Int = 0
    @State private var restDaysPerWeek: Int = 0
    @State private var raceGoal: String = ""
    
    // Initialize with existing data if available
    private func initializeWithExistingData() {
        guard let personalization = userPersonalization else { return }
        
        if let existingRaceType = personalization.raceType {
            selectedRaceType = existingRaceType
        }
        if let existingRaceDate = personalization.raceDate {
            raceDate = existingRaceDate
        }
        if let existingTrainingStartDate = personalization.trainingStartDate {
            trainingStartDate = existingTrainingStartDate
        }
        if let existingRunnerLevel = personalization.runnerLevel {
            runnerLevel = existingRunnerLevel
        }
        if let existingRunDays = personalization.runDaysPerWeek {
            runDaysPerWeek = existingRunDays
        }
        if let existingCrossTrainDays = personalization.crossTrainDaysPerWeek {
            crossTrainDaysPerWeek = existingCrossTrainDays
        }
        if let existingRestDays = personalization.restDaysPerWeek {
            restDaysPerWeek = existingRestDays
        }
        if let existingRaceGoal = personalization.raceGoal {
            raceGoal = existingRaceGoal
        }
    }
    
    private let raceTypes = ["5K", "10K", "Half Marathon", "Marathon", "Ultramarathon", "Custom Distance"]
    private let runnerLevels = ["Beginner", "Intermediate", "Advanced"]
    private let goalOptions = ["Just finish", "Set a personal record", "Achieve specific time"]
    private let runDaysOptions = [3, 4, 5, 6]
    private let crossTrainDaysOptions = [1, 2, 3]
    private let restDaysOptions = [1, 2, 3]
    
    var userPersonalization: PersonalizationData? {
        personalizationData.first
    }
    
    private var isFormComplete: Bool {
        return !selectedRaceType.isEmpty && 
               !runnerLevel.isEmpty && 
               runDaysPerWeek > 0 && 
               crossTrainDaysPerWeek > 0 && 
               restDaysPerWeek > 0 && 
               !raceGoal.isEmpty
    }
    
    private func saveRaceTrainingPreferences() {
        guard let personalization = userPersonalization else {
            print("❌ No personalization data found")
            return
        }
        
        // Save race training preferences
        personalization.raceTrainingEnabled = true
        personalization.raceType = selectedRaceType
        personalization.raceDate = raceDate
        personalization.trainingStartDate = trainingStartDate
        personalization.runnerLevel = runnerLevel
        personalization.runDaysPerWeek = runDaysPerWeek
        personalization.crossTrainDaysPerWeek = crossTrainDaysPerWeek
        personalization.restDaysPerWeek = restDaysPerWeek
        personalization.raceGoal = raceGoal
        personalization.updatedAt = Date()
        
        // Save to database
        do {
            try modelContext.save()
            print("✅ Race training preferences saved successfully")
            print("   Race Type: \(selectedRaceType)")
            print("   Race Date: \(raceDate)")
            print("   Training Start: \(trainingStartDate)")
            print("   Runner Level: \(runnerLevel)")
            print("   Run Days/Week: \(runDaysPerWeek)")
            print("   Cross Train Days/Week: \(crossTrainDaysPerWeek)")
            print("   Rest Days/Week: \(restDaysPerWeek)")
            print("   Race Goal: \(raceGoal)")
        } catch {
            print("❌ Failed to save race training preferences: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Race Training Program")
                        .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(userPersonalization?.raceTrainingEnabled == true ? "Update your personalized cycle-synced training plan" : "Let's create your personalized cycle-synced training plan")
                        .font(.custom("Sofia Pro", size: 16, relativeTo: .body))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 20) {
                        // Race Type Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What race are you training for?")
                                .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(raceTypes, id: \.self) { raceType in
                                    Button(action: {
                                        selectedRaceType = raceType
                                    }) {
                                        Text(raceType)
                                            .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedRaceType == raceType ? .white : .white.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedRaceType == raceType ? Color.purple : Color.white.opacity(0.1))
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Race Date Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When is your race?")
                                .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            DatePicker("Race Date", selection: $raceDate, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .colorScheme(.dark)
                                .accentColor(.purple)
                        }
                        
                        // Training Start Date Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When do you want to start training?")
                                .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            DatePicker("Training Start Date", selection: $trainingStartDate, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .colorScheme(.dark)
                                .accentColor(.purple)
                        }
                        
                        // Runner Level Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's your current running level?")
                                .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(runnerLevels, id: \.self) { level in
                                    Button(action: {
                                        runnerLevel = level
                                    }) {
                                        Text(level)
                                            .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                                            .fontWeight(.medium)
                                            .foregroundColor(runnerLevel == level ? .white : .white.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(runnerLevel == level ? Color.purple : Color.white.opacity(0.1))
                                            )
                                    }
                                }
                            }
                        }
                        
                        
                        // Training Schedule Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Training Schedule")
                                .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                // Running Days
                                HStack {
                                    Text("Run days per week:")
                                        .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        ForEach(runDaysOptions, id: \.self) { days in
                                            Button(action: {
                                                runDaysPerWeek = days
                                            }) {
                                                Text("\(days)")
                                                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(runDaysPerWeek == days ? .white : .white.opacity(0.7))
                                                    .frame(width: 32, height: 32)
                                                    .background(
                                                        Circle()
                                                            .fill(runDaysPerWeek == days ? Color.purple : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                Text("We recommend at least 3 runs per week")
                                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Cross Training Days
                                HStack {
                                    Text("Cross train days per week:")
                                        .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        ForEach(crossTrainDaysOptions, id: \.self) { days in
                                            Button(action: {
                                                crossTrainDaysPerWeek = days
                                            }) {
                                                Text("\(days)")
                                                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(crossTrainDaysPerWeek == days ? .white : .white.opacity(0.7))
                                                    .frame(width: 32, height: 32)
                                                    .background(
                                                        Circle()
                                                            .fill(crossTrainDaysPerWeek == days ? Color.purple : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                
                                // Rest Days
                                HStack {
                                    Text("Rest days per week:")
                                        .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        ForEach(restDaysOptions, id: \.self) { days in
                                            Button(action: {
                                                restDaysPerWeek = days
                                            }) {
                                                Text("\(days)")
                                                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(restDaysPerWeek == days ? .white : .white.opacity(0.7))
                                                    .frame(width: 32, height: 32)
                                                    .background(
                                                        Circle()
                                                            .fill(restDaysPerWeek == days ? Color.purple : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                Text("We recommend at least 1 rest day per week")
                                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Race Goal Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's your goal?")
                                .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                ForEach(goalOptions, id: \.self) { goal in
                                    Button(action: {
                                        raceGoal = goal
                                    }) {
                                        HStack {
                                            Text(goal)
                                                .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                                                .fontWeight(.medium)
                                                .foregroundColor(raceGoal == goal ? .white : .white.opacity(0.7))
                                            
                                            Spacer()
                                            
                                            if raceGoal == goal {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(raceGoal == goal ? Color.purple : Color.white.opacity(0.1))
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(userPersonalization?.raceTrainingEnabled == true ? "Update Training Plan" : "Create Training Plan") {
                            // Generate the actual race training plan using your logic
                            let trainingPlan = RaceTrainingEngine.shared.generateRaceTrainingPlan(
                                raceType: selectedRaceType,
                                raceDate: raceDate,
                                trainingStartDate: trainingStartDate,
                                runnerLevel: runnerLevel,
                                runDaysPerWeek: runDaysPerWeek,
                                crossTrainDaysPerWeek: crossTrainDaysPerWeek,
                                restDaysPerWeek: restDaysPerWeek,
                                raceGoal: raceGoal
                            )
                            
                            // Debug logging
                            print("🏃‍♀️ RACE TRAINING PLAN GENERATED:")
                            print("   Total Weeks: \(trainingPlan.totalWeeks)")
                            print("   Weekly Plans: \(trainingPlan.weeklyPlans.count)")
                            
                            // Log first week as example
                            if let firstWeek = trainingPlan.weeklyPlans.first {
                                print("   Week 1 - Phase: \(firstWeek.phase.rawValue)")
                                print("   Week 1 - Down Week: \(firstWeek.isDownWeek)")
                                print("   Week 1 - Daily Plans: \(firstWeek.dailyPlans.count)")
                                
                                for (index, day) in firstWeek.dailyPlans.enumerated() {
                                    let formatter = DateFormatter()
                                    formatter.dateStyle = .short
                                    print("     Day \(index + 1) (\(formatter.string(from: day.date))): \(day.workoutType.rawValue)")
                                    if let workout = day.workout {
                                        print("       - \(workout.description)")
                                        if let distance = workout.distance {
                                            print("       - Distance: \(distance) miles")
                                        }
                                        if let duration = workout.duration {
                                            print("       - Duration: \(duration) minutes")
                                        }
                                        print("       - Intensity: \(workout.intensity.rawValue)")
                                    }
                                }
                            }
                            
                            // Save race training preferences to database
                            saveRaceTrainingPreferences()
                            
                            // Navigate to training plan view
                            showingTrainingPlan = true
                        }
                        .font(.custom("Sofia Pro", size: 18, relativeTo: .headline))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormComplete ? Color.purple : Color.gray)
                        .cornerRadius(12)
                        .disabled(!isFormComplete)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.custom("Sofia Pro", size: 16, relativeTo: .subheadline))
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationTitle("Race Training")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                initializeWithExistingData()
            }
            .sheet(isPresented: $showingTrainingPlan) {
                RaceTrainingPlanView()
            }
        }
    }
}

#Preview {
    ExploreView()
}
