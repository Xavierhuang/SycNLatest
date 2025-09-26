import SwiftUI
import Foundation

struct FitnessPlanDebugView: View {
    @State private var generatedPlan: FitnessPlanExport?
    @State private var savedPlans: [URL] = []
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Fitness Plan Debug Tool")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    Button("Generate New Fitness Plan") {
                        generateFitnessPlan()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Button("List Saved Plans") {
                        listSavedPlans()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Load Latest Plan") {
                        loadLatestPlan()
                    }
                    .buttonStyle(.bordered)
                    .disabled(savedPlans.isEmpty)
                }
                
                if isLoading {
                    ProgressView("Generating plan...")
                        .padding()
                }
                
                if let plan = generatedPlan {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Generated Plan Summary")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Text("Generated: \(plan.generatedAt, formatter: dateFormatter)")
                            Text("Start Date: \(plan.startDate, formatter: dateFormatter)")
                            Text("Workout Frequency: \(plan.userPreferences.workoutFrequency) days/week")
                            Text("Favorite Workouts: \(plan.userPreferences.favoriteWorkouts.joined(separator: ", "))")
                            Text("Disliked Workouts: \(plan.userPreferences.dislikedWorkouts.joined(separator: ", "))")
                            
                            Divider()
                            
                            Text("14-Day Plan:")
                                .font(.headline)
                                .padding(.top, 10)
                            
                            ForEach(Array(plan.plan.enumerated()), id: \.offset) { index, entry in
                                HStack {
                                    Text("Day \(index + 1):")
                                        .fontWeight(.medium)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.workoutTitle)
                                            .fontWeight(.semibold)
                                        Text("\(entry.workoutType) • \(entry.duration)min • \(entry.cyclePhase)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding()
                    }
                }
                
                if !savedPlans.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Saved Plans:")
                            .font(.headline)
                        
                        ForEach(savedPlans, id: \.self) { url in
                            HStack {
                                Text(url.lastPathComponent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("Load") {
                                    loadPlan(from: url)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug")
            .alert("Debug Info", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func generateFitnessPlan() {
        isLoading = true
        
        // Create a sample user profile for testing
        let userProfile = createSampleUserProfile()
        let userPreferences = UserPreferences(from: userProfile.personalizationData!)
        
        // Use the same logic as the main app to determine start date
        let actualStartDate = CyclePredictionService.shared.getUserPlanStartDate(for: userProfile)
        
        // Generate the plan
        let plan = SwiftFitnessRecommendationEngine.shared.generateWeeklyFitnessPlan(
            for: userProfile,
            startDate: actualStartDate,
            userPreferences: userPreferences
        )
        
        // Convert to export format
        let planExport = FitnessPlanExport(
            generatedAt: Date(),
            startDate: actualStartDate,
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
        
        generatedPlan = planExport
        isLoading = false
        
        alertMessage = "Fitness plan generated and saved to JSON file!"
        showingAlert = true
        
        // Refresh saved plans list
        listSavedPlans()
    }
    
    private func listSavedPlans() {
        savedPlans = SwiftFitnessRecommendationEngine.getSavedFitnessPlans()
        SwiftFitnessRecommendationEngine.printSavedPlansList()
    }
    
    private func loadLatestPlan() {
        if let plan = SwiftFitnessRecommendationEngine.getLatestFitnessPlan() {
            generatedPlan = plan
            alertMessage = "Latest plan loaded successfully!"
            showingAlert = true
        } else {
            alertMessage = "Failed to load latest plan"
            showingAlert = true
        }
    }
    
    private func loadPlan(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let plan = try JSONDecoder().decode(FitnessPlanExport.self, from: data)
            generatedPlan = plan
            alertMessage = "Plan loaded from \(url.lastPathComponent)"
            showingAlert = true
        } catch {
            alertMessage = "Failed to load plan: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func createSampleUserProfile() -> UserProfile {
        let personalizationData = PersonalizationData(userId: UUID())
        personalizationData.fitnessLevel = .intermediate
        personalizationData.fitnessGoal = .improveFitness
        personalizationData.desiredWorkoutFrequency = .four
        personalizationData.favoriteWorkoutsString = "Strength, Yoga"
        personalizationData.dislikedWorkoutsString = "HIIT"
        personalizationData.pastInjuries = "knee"
        personalizationData.preferredRestDaysString = "Sunday"
        personalizationData.planStartChoice = .today
        
        let userProfile = UserProfile(
            name: "Test User",
            birthDate: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
            cycleLength: 28,
            averagePeriodLength: 5,
            fitnessLevel: .intermediate
        )
        userProfile.personalizationData = personalizationData
        userProfile.lastPeriodStart = Calendar.current.date(byAdding: .day, value: -14, to: Date())
        userProfile.cycleType = .regular
        userProfile.currentCyclePhase = .follicular
        
        return userProfile
    }
}

#Preview {
    FitnessPlanDebugView()
}
