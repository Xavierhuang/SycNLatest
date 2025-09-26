import SwiftUI
import SwiftData

struct FitnessPreferencesOnePagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var personalizationData: [PersonalizationData]
    
    @State private var isEditing = false
    @State private var fitnessGoal: PersonalizationFitnessGoal?
    @State private var fitnessLevel: PersonalizationFitnessLevel?
    @State private var workoutFrequency: WorkoutFrequency?
    @State private var desiredWorkoutFrequency: DesiredWorkoutFrequency?
    @State private var favoriteWorkouts: Set<PersonalizationWorkoutType> = []
    @State private var dislikedWorkouts: Set<PersonalizationWorkoutType> = []
    @State private var syncNSupport: SyncNSupport?
    @State private var planStartChoice: PlanStartChoice?
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var personalization: PersonalizationData? {
        personalizationData.first { $0.userId == userProfile?.id }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Fitness Preferences")
                            .font(.custom("Sofia Pro", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Your fitness goals and preferences")
                            .font(.custom("Sofia Pro", size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Current Fitness Plan Status
                    if let profile = userProfile, !profile.weeklyFitnessPlan.isEmpty {
                        VStack(spacing: 16) {
                            Text("Current Fitness Plan")
                                .font(.custom("Sofia Pro", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 20) {
                                FitnessStatusCard(
                                    title: "Workouts This Week",
                                    value: "\(workoutsThisWeek)",
                                    icon: "dumbbell.fill",
                                    color: .blue
                                )
                                
                                FitnessStatusCard(
                                    title: "Rest Days",
                                    value: "\(restDaysThisWeek)",
                                    icon: "bed.double.fill",
                                    color: .purple
                                )
                            }
                            
                            HStack(spacing: 20) {
                                FitnessStatusCard(
                                    title: "Meditations",
                                    value: "\(meditationsThisWeek)",
                                    icon: "brain.head.profile",
                                    color: .orange
                                )
                                
                                FitnessStatusCard(
                                    title: "Plan Duration",
                                    value: "14 days",
                                    icon: "calendar",
                                    color: .green
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                    }
                    
                    // Fitness Goals Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Fitness Goals")
                                .font(.custom("Sofia Pro", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(isEditing ? "Save" : "Edit") {
                                if isEditing {
                                    saveFitnessPreferences()
                                }
                                isEditing.toggle()
                            }
                            .font(.custom("Sofia Pro", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 16) {
                            FitnessDetailRow(
                                title: "Primary Goal",
                                value: fitnessGoal?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(PersonalizationFitnessGoal.allCases, id: \.self) { goal in
                                            Button(action: {
                                                fitnessGoal = goal
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: fitnessGoal == goal ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(fitnessGoal == goal ? .blue : .gray)
                                                    
                                                    Text(goal.rawValue)
                                                        .font(.custom("Sofia Pro", size: 14))
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(nil)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(fitnessGoal == goal ? Color.blue.opacity(0.1) : Color.clear)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            )
                            
                            FitnessDetailRow(
                                title: "Fitness Level",
                                value: fitnessLevel?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(PersonalizationFitnessLevel.allCases, id: \.self) { level in
                                            Button(action: {
                                                fitnessLevel = level
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: fitnessLevel == level ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(fitnessLevel == level ? .blue : .gray)
                                                    
                                                    Text(level.rawValue)
                                                        .font(.custom("Sofia Pro", size: 14))
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(nil)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(fitnessLevel == level ? Color.blue.opacity(0.1) : Color.clear)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            )
                            
                            FitnessDetailRow(
                                title: "Workout Frequency",
                                value: workoutFrequency?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(WorkoutFrequency.allCases, id: \.self) { frequency in
                                            Button(action: {
                                                workoutFrequency = frequency
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: workoutFrequency == frequency ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(workoutFrequency == frequency ? .blue : .gray)
                                                    
                                                    Text(frequency.rawValue)
                                                        .font(.custom("Sofia Pro", size: 14))
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(nil)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(workoutFrequency == frequency ? Color.blue.opacity(0.1) : Color.clear)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            )
                            
                            FitnessDetailRow(
                                title: "Desired Workout Frequency",
                                value: desiredWorkoutFrequency?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(DesiredWorkoutFrequency.allCases, id: \.self) { frequency in
                                            Button(action: {
                                                desiredWorkoutFrequency = frequency
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: desiredWorkoutFrequency == frequency ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(desiredWorkoutFrequency == frequency ? .blue : .gray)
                                                    
                                                    Text(frequency.rawValue)
                                                        .font(.custom("Sofia Pro", size: 14))
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(nil)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(desiredWorkoutFrequency == frequency ? Color.blue.opacity(0.1) : Color.clear)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            )
                            
                            FitnessDetailRow(
                                title: "SyncN Support",
                                value: syncNSupport?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(SyncNSupport.allCases, id: \.self) { support in
                                            Button(action: {
                                                syncNSupport = support
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: syncNSupport == support ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(syncNSupport == support ? .blue : .gray)
                                                    
                                                    Text(support.rawValue)
                                                        .font(.custom("Sofia Pro", size: 14))
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(nil)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(syncNSupport == support ? Color.blue.opacity(0.1) : Color.clear)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    
                    // Favorite Workouts Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Favorite Workouts")
                            .font(.custom("Sofia Pro", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if favoriteWorkouts.isEmpty {
                            Text("No favorite workouts selected")
                                .font(.custom("Sofia Pro", size: 14))
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(favoriteWorkouts), id: \.self) { workout in
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                        
                                        Text(workout.rawValue)
                                            .font(.custom("Sofia Pro", size: 12))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        if isEditing {
                            Button("Edit Favorites") {
                                // This would open a multi-select view
                            }
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    
                    // Custom Workouts Section
                    if let profile = userProfile, !profile.customWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Custom Workouts")
                                .font(.custom("Sofia Pro", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ForEach(profile.customWorkouts.prefix(3), id: \.id) { workout in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(workout.name)
                                            .font(.custom("Sofia Pro", size: 14))
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(workout.activityType) • \(workout.duration)")
                                            .font(.custom("Sofia Pro", size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(workout.intensity.capitalized)
                                        .font(.custom("Sofia Pro", size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                if workout.id != profile.customWorkouts.prefix(3).last?.id {
                                    Divider()
                                }
                            }
                            
                            if profile.customWorkouts.count > 3 {
                                Text("+ \(profile.customWorkouts.count - 3) more workouts")
                                    .font(.custom("Sofia Pro", size: 12))
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Fitness Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                }
            }
        }
        .onAppear {
            loadCurrentData()
        }
    }
    
    // MARK: - Computed Properties
    
    private var workoutsThisWeek: Int {
        guard let profile = userProfile else { return 0 }
        
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        return profile.weeklyFitnessPlan.filter { entry in
            entry.date >= startOfWeek && entry.date < endOfWeek && entry.workoutTitle != "Rest Day"
        }.count
    }
    
    private var restDaysThisWeek: Int {
        guard let profile = userProfile else { return 0 }
        
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        return profile.weeklyFitnessPlan.filter { entry in
            entry.date >= startOfWeek && entry.date < endOfWeek && entry.workoutTitle == "Rest Day"
        }.count
    }
    
    private var meditationsThisWeek: Int {
        guard let profile = userProfile else { return 0 }
        
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        return profile.weeklyFitnessPlan.filter { entry in
            entry.date >= startOfWeek && entry.date < endOfWeek && entry.workoutTitle.lowercased().contains("meditation")
        }.count
    }
    
    // MARK: - Methods
    
    private func loadCurrentData() {
        guard let personalization = personalization else { return }
        
        fitnessGoal = personalization.fitnessGoal
        fitnessLevel = personalization.fitnessLevel
        workoutFrequency = personalization.workoutFrequency
        desiredWorkoutFrequency = personalization.desiredWorkoutFrequency
        syncNSupport = personalization.syncNSupport
        planStartChoice = personalization.planStartChoice
        
        // Load favorite workouts
        if let favoritesString = personalization.favoriteWorkoutsString {
            let favorites = favoritesString.components(separatedBy: ",").compactMap { PersonalizationWorkoutType(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
            favoriteWorkouts = Set(favorites)
        }
        
        // Load disliked workouts
        if let dislikedString = personalization.dislikedWorkoutsString {
            let disliked = dislikedString.components(separatedBy: ",").compactMap { PersonalizationWorkoutType(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
            dislikedWorkouts = Set(disliked)
        }
    }
    
    private func saveFitnessPreferences() {
        guard let personalization = personalization else { return }
        
        personalization.fitnessGoal = fitnessGoal
        personalization.fitnessLevel = fitnessLevel
        personalization.workoutFrequency = workoutFrequency
        personalization.desiredWorkoutFrequency = desiredWorkoutFrequency
        personalization.syncNSupport = syncNSupport
        personalization.planStartChoice = planStartChoice
        personalization.favoriteWorkoutsString = favoriteWorkouts.isEmpty ? nil : favoriteWorkouts.map { $0.rawValue }.joined(separator: ",")
        personalization.dislikedWorkoutsString = dislikedWorkouts.isEmpty ? nil : dislikedWorkouts.map { $0.rawValue }.joined(separator: ",")
        personalization.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving fitness preferences: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct FitnessStatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.custom("Sofia Pro", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.custom("Sofia Pro", size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FitnessDetailRow<EditContent: View>: View {
    let title: String
    let value: String
    let isEditing: Bool
    @ViewBuilder let editContent: () -> EditContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Sofia Pro", size: 16))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isEditing {
                editContent()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(value)
                    .font(.custom("Sofia Pro", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FitnessPreferencesOnePagerView()
        .modelContainer(for: [UserProfile.self, PersonalizationData.self], inMemory: true)
}
