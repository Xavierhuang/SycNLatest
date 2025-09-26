import SwiftUI
import TelemetryDeck

// MARK: - Fitness Goal Step
struct FitnessGoalStepView: View {
    @Binding var fitnessGoals: Set<PersonalizationFitnessGoal>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What are your fitness goals?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply to you")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(PersonalizationFitnessGoal.allCases, id: \.self) { goal in
                    SelectionButton(
                        title: goal.rawValue,
                        isSelected: fitnessGoals.contains(goal)
                    ) {
                        if fitnessGoals.contains(goal) {
                            fitnessGoals.remove(goal)
                            TelemetryDeck.signal("FitnessPersonalization.Goal.Deselected", parameters: [
                                "goal": goal.rawValue,
                                "step": "fitness_goals"
                            ])
                        } else {
                            fitnessGoals.insert(goal)
                            TelemetryDeck.signal("FitnessPersonalization.Goal.Selected", parameters: [
                                "goal": goal.rawValue,
                                "step": "fitness_goals"
                            ])
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "fitness_goals",
                "stepNumber": "0"
            ])
        }
    }
}

// MARK: - Fitness Level Step
struct FitnessLevelStepView: View {
    @Binding var fitnessLevel: PersonalizationFitnessLevel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How would you describe your current fitness level?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                ForEach(PersonalizationFitnessLevel.allCases, id: \.self) { level in
                    SelectionButton(
                        title: level.rawValue,
                        isSelected: fitnessLevel == level
                    ) {
                        fitnessLevel = level
                        TelemetryDeck.signal("FitnessPersonalization.FitnessLevel.Selected", parameters: [
                            "fitnessLevel": level.rawValue,
                            "step": "fitness_level"
                        ])
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "fitness_level",
                "stepNumber": "1"
            ])
        }
    }
}

// MARK: - Workout Frequency Step
struct WorkoutFrequencyStepView: View {
    @Binding var workoutFrequency: WorkoutFrequency?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("About how many times a week do you workout?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                ForEach(WorkoutFrequency.allCases, id: \.self) { frequency in
                    SelectionButton(
                        title: frequency.rawValue,
                        isSelected: workoutFrequency == frequency
                    ) {
                        workoutFrequency = frequency
                        TelemetryDeck.signal("FitnessPersonalization.WorkoutFrequency.Selected", parameters: [
                            "workoutFrequency": frequency.rawValue,
                            "step": "workout_frequency"
                        ])
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "workout_frequency",
                "stepNumber": "2"
            ])
        }
    }
}

// MARK: - Desired Workout Frequency Step
struct DesiredWorkoutFrequencyStepView: View {
    @Binding var desiredWorkoutFrequency: DesiredWorkoutFrequency?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How many days a week do you DESIRE to workout?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select your ideal weekly workout frequency")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(DesiredWorkoutFrequency.allCases, id: \.self) { frequency in
                    SelectionButton(
                        title: frequency.rawValue,
                        isSelected: desiredWorkoutFrequency == frequency
                    ) {
                        desiredWorkoutFrequency = frequency
                        TelemetryDeck.signal("FitnessPersonalization.DesiredWorkoutFrequency.Selected", parameters: [
                            "desiredWorkoutFrequency": frequency.rawValue,
                            "step": "desired_workout_frequency"
                        ])
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "desired_workout_frequency",
                "stepNumber": "3"
            ])
        }
    }
}

// MARK: - Favorite Workouts Step
struct FavoriteWorkoutsStepView: View {
    @Binding var favoriteWorkouts: Set<PersonalizationWorkoutType>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What are your FAVORITE ways to move your body?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(PersonalizationWorkoutType.allCases, id: \.self) { workout in
                    SelectionButton(
                        title: workout.rawValue,
                        isSelected: favoriteWorkouts.contains(workout)
                    ) {
                        if favoriteWorkouts.contains(workout) {
                            favoriteWorkouts.remove(workout)
                            TelemetryDeck.signal("FitnessPersonalization.FavoriteWorkout.Deselected", parameters: [
                                "workout": workout.rawValue,
                                "step": "favorite_workouts"
                            ])
                        } else {
                            favoriteWorkouts.insert(workout)
                            TelemetryDeck.signal("FitnessPersonalization.FavoriteWorkout.Selected", parameters: [
                                "workout": workout.rawValue,
                                "step": "favorite_workouts"
                            ])
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "favorite_workouts",
                "stepNumber": "6"
            ])
        }
    }
}

// MARK: - Disliked Workouts Step
struct DislikedWorkoutsStepView: View {
    @Binding var dislikedWorkouts: Set<PersonalizationWorkoutType>
    let favoriteWorkouts: Set<PersonalizationWorkoutType>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What ways do you NOT ENJOY to move your body?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(PersonalizationWorkoutType.allCases, id: \.self) { workout in
                    let isFavorite = favoriteWorkouts.contains(workout)
                    
                    SelectionButton(
                        title: workout.rawValue,
                        isSelected: dislikedWorkouts.contains(workout),
                        isDisabled: isFavorite
                    ) {
                        if !isFavorite {
                            if dislikedWorkouts.contains(workout) {
                                dislikedWorkouts.remove(workout)
                                TelemetryDeck.signal("FitnessPersonalization.DislikedWorkout.Deselected", parameters: [
                                    "workout": workout.rawValue,
                                    "step": "disliked_workouts"
                                ])
                            } else {
                                dislikedWorkouts.insert(workout)
                                TelemetryDeck.signal("FitnessPersonalization.DislikedWorkout.Selected", parameters: [
                                    "workout": workout.rawValue,
                                    "step": "disliked_workouts"
                                ])
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "disliked_workouts",
                "stepNumber": "7"
            ])
        }
    }
}

// MARK: - Injury Form Step
struct InjuryFormStepView: View {
    @Binding var injuryEntries: [InjuryEntry]
    @State private var showingAddInjury = false
    @State private var editingInjury: InjuryEntry?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Any past or current injuries?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Help us understand your physical needs to create a safe workout plan")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(injuryEntries) { injury in
                    InjuryEntryCard(
                        injury: injury,
                        onEdit: { editingInjury = injury },
                        onDelete: { 
                            injuryEntries.removeAll { $0.id == injury.id }
                            TelemetryDeck.signal("FitnessPersonalization.Injury.Deleted", parameters: [
                                "bodyPart": injury.bodyPart,
                                "step": "injury_form"
                            ])
                        }
                    )
                }
                
                Button(action: { 
                    showingAddInjury = true
                    TelemetryDeck.signal("FitnessPersonalization.Injury.AddClicked", parameters: [
                        "step": "injury_form"
                    ])
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.title3)
                        Text("Add Injury")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.608, green: 0.431, blue: 0.953))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .sheet(isPresented: $showingAddInjury) {
            AddEditInjuryView(
                injury: nil,
                onSave: { newInjury in
                    injuryEntries.append(newInjury)
                    TelemetryDeck.signal("FitnessPersonalization.Injury.Added", parameters: [
                        "bodyPart": newInjury.bodyPart,
                        "status": newInjury.status.rawValue,
                        "severity": newInjury.severity.rawValue,
                        "step": "injury_form"
                    ])
                }
            )
        }
        .sheet(item: $editingInjury) { injury in
            AddEditInjuryView(
                injury: injury,
                onSave: { updatedInjury in
                    if let index = injuryEntries.firstIndex(where: { $0.id == injury.id }) {
                        injuryEntries[index] = updatedInjury
                        TelemetryDeck.signal("FitnessPersonalization.Injury.Edited", parameters: [
                            "bodyPart": updatedInjury.bodyPart,
                            "status": updatedInjury.status.rawValue,
                            "severity": updatedInjury.severity.rawValue,
                            "step": "injury_form"
                        ])
                    }
                }
            )
        }
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "injury_form",
                "stepNumber": "8"
            ])
        }
    }
}

// MARK: - Injury Entry Card
struct InjuryEntryCard: View {
    let injury: InjuryEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(injury.bodyPart)
                        .font(.sofiaProHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(injury.status.rawValue)
                        .font(.sofiaProCaption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            
            HStack {
                Text("Severity:")
                    .font(.sofiaProCaption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(injury.severity.rawValue)
                    .font(.sofiaProCaption)
                    .fontWeight(.medium)
                    .foregroundColor(severityColor)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.12, blue: 0.18))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var severityColor: Color {
        switch injury.severity {
        case .none:
            return .green
        case .mild:
            return .orange
        case .severe:
            return .red
        }
    }
}

// MARK: - Add/Edit Injury View
struct AddEditInjuryView: View {
    let injury: InjuryEntry?
    let onSave: (InjuryEntry) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var bodyPart = ""
    @State private var status: InjuryStatus?
    @State private var severity: InjurySeverity?
    
    private var canSave: Bool {
        !bodyPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        status != nil && 
        severity != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Body part or muscle group")
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                    
                    TextField("e.g., Lower back, Right knee, Left shoulder", text: $bodyPart)
                        .font(.sofiaProBody)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Past injury or current?")
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(InjuryStatus.allCases, id: \.self) { statusOption in
                            SelectionButton(
                                title: statusOption.rawValue,
                                isSelected: status == statusOption
                            ) {
                                status = statusOption
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Level of severity you feel today")
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(InjurySeverity.allCases, id: \.self) { severityOption in
                            SelectionButton(
                                title: severityOption.rawValue,
                                isSelected: severity == severityOption
                            ) {
                                severity = severityOption
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationTitle(injury == nil ? "Add Injury" : "Edit Injury")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.08, green: 0.11, blue: 0.17), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let status = status, let severity = severity else { return }
                        let newInjury = InjuryEntry(
                            bodyPart: bodyPart,
                            status: status,
                            severity: severity
                        )
                        onSave(newInjury)
                        dismiss()
                    }
                    .foregroundColor(canSave ? .white : .white.opacity(0.3))
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            if let injury = injury {
                bodyPart = injury.bodyPart
                status = injury.status
                severity = injury.severity
            } else {
                // Reset to nil for new injury
                status = nil
                severity = nil
            }
        }
    }
}

// MARK: - SyncN Support Step
struct SyncNSupportStepView: View {
    @Binding var syncNSupport: SyncNSupport?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How are you most interested in SyncN supporting your fitness?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                ForEach(SyncNSupport.allCases, id: \.self) { support in
                    SelectionButton(
                        title: support.rawValue,
                        isSelected: syncNSupport == support
                    ) {
                        syncNSupport = support
                        TelemetryDeck.signal("FitnessPersonalization.SyncNSupport.Selected", parameters: [
                            "syncNSupport": support.rawValue,
                            "step": "syncn_support"
                        ])
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "syncn_support",
                "stepNumber": "9"
            ])
        }
    }
}

// MARK: - Custom Workout Entries Step
struct CustomWorkoutEntriesStepView: View {
    @Binding var customWorkoutEntries: [CustomWorkoutEntry]
    @State private var showingAddWorkoutModal = false
    @State private var editingEntry: CustomWorkoutEntry?
    @State private var editingIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What workouts do you already love and want to keep in your fitness routine?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Add your favorite workouts with details about where and how often you do them. We'll build your plan around what you enjoy!")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(customWorkoutEntries.indices, id: \.self) { index in
                        CustomWorkoutSummaryCard(
                            entry: customWorkoutEntries[index],
                            onEdit: {
                                editingEntry = customWorkoutEntries[index]
                                editingIndex = index
                                showingAddWorkoutModal = true
                            },
                            onDelete: {
                                let deletedEntry = customWorkoutEntries[index]
                                customWorkoutEntries.remove(at: index)
                                TelemetryDeck.signal("FitnessPersonalization.CustomWorkout.Deleted", parameters: [
                                    "workoutName": deletedEntry.name,
                                    "step": "custom_workout_entries"
                                ])
                            }
                        )
                    }
                    
                    // Add new workout button
                    Button(action: {
                        editingEntry = nil
                        editingIndex = nil
                        showingAddWorkoutModal = true
                        TelemetryDeck.signal("FitnessPersonalization.CustomWorkout.AddClicked", parameters: [
                            "step": "custom_workout_entries"
                        ])
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text(customWorkoutEntries.isEmpty ? "Add Workout" : "Add Another Workout")
                                .font(.sofiaProHeadline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .sheet(isPresented: $showingAddWorkoutModal) {
            CustomWorkoutModalView(
                entry: editingEntry ?? CustomWorkoutEntry(),
                isEditing: editingEntry != nil,
                onSave: { newEntry in
                    if let index = editingIndex {
                        customWorkoutEntries[index] = newEntry
                        TelemetryDeck.signal("FitnessPersonalization.CustomWorkout.Edited", parameters: [
                            "workoutName": newEntry.name,
                            "activityType": newEntry.activityType,
                            "intensity": newEntry.intensity,
                            "step": "custom_workout_entries"
                        ])
                    } else {
                        customWorkoutEntries.append(newEntry)
                        TelemetryDeck.signal("FitnessPersonalization.CustomWorkout.Added", parameters: [
                            "workoutName": newEntry.name,
                            "activityType": newEntry.activityType,
                            "intensity": newEntry.intensity,
                            "step": "custom_workout_entries"
                        ])
                    }
                    showingAddWorkoutModal = false
                },
                onCancel: {
                    showingAddWorkoutModal = false
                }
            )
        }
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "custom_workout_entries",
                "stepNumber": "10"
            ])
        }
    }
}

// MARK: - Custom Workout Summary Card
struct CustomWorkoutSummaryCard: View {
    let entry: CustomWorkoutEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name.isEmpty ? "Untitled Workout" : entry.name)
                    .font(.sofiaProHeadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    if !entry.activityType.isEmpty {
                        Text(entry.activityType)
                            .font(.sofiaProCaption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if !entry.intensity.isEmpty {
                        Text(entry.intensity)
                            .font(.sofiaProCaption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if let location = entry.location {
                        Text(location.rawValue)
                            .font(.sofiaProCaption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.12, blue: 0.18))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Custom Workout Modal View
struct CustomWorkoutModalView: View {
    @State private var entry: CustomWorkoutEntry
    let isEditing: Bool
    let onSave: (CustomWorkoutEntry) -> Void
    let onCancel: () -> Void
    
    @FocusState private var focusedField: Field?
    @State private var showingActivityTypePicker = false
    
    enum Field: Hashable {
        case workoutName
    }
    
    init(entry: CustomWorkoutEntry, isEditing: Bool, onSave: @escaping (CustomWorkoutEntry) -> Void, onCancel: @escaping () -> Void) {
        self._entry = State(initialValue: entry)
        self.isEditing = isEditing
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    private var canSave: Bool {
        !entry.name.isEmpty && 
        !entry.activityType.isEmpty && 
        !entry.intensity.isEmpty && 
        !entry.duration.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name *")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Enter workout name", text: $entry.name)
                            .font(.sofiaProBody)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .focused($focusedField, equals: .workoutName)
                    }
                    
                    // Activity Type dropdown (many options, keep as dropdown)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity Type *")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button(action: { 
                            focusedField = nil
                            showingActivityTypePicker = true 
                        }) {
                            HStack {
                                Text(entry.activityType.isEmpty ? "Select" : entry.activityType)
                                    .font(.sofiaProBody)
                                    .foregroundColor(entry.activityType.isEmpty ? .white.opacity(0.6) : .white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(12)
                            .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Intensity choice chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity *")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(intensityOptions, id: \.self) { intensity in
                                Button(action: {
                                    focusedField = nil
                                    entry.intensity = intensity
                                }) {
                                    Text(intensity)
                                        .font(.sofiaProBody)
                                        .foregroundColor(entry.intensity == intensity ? .black : .white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(entry.intensity == intensity ? Color.white : Color.clear)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Duration choice chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration *")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(durationOptions, id: \.self) { duration in
                                Button(action: {
                                    focusedField = nil
                                    entry.duration = duration
                                }) {
                                    Text(duration)
                                        .font(.sofiaProBody)
                                        .foregroundColor(entry.duration == duration ? .black : .white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(entry.duration == duration ? Color.white : Color.clear)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Location choice chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(WorkoutLocation.allCases, id: \.self) { location in
                                Button(action: {
                                    focusedField = nil
                                    entry.location = location
                                }) {
                                    Text(location.rawValue)
                                        .font(.sofiaProBody)
                                        .foregroundColor(entry.location == location ? .black : .white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(entry.location == location ? Color.white : Color.clear)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Frequency choice chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How Often")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(CustomWorkoutFrequency.allCases, id: \.self) { frequency in
                                Button(action: {
                                    focusedField = nil
                                    entry.frequency = frequency
                                }) {
                                    Text(frequency.rawValue)
                                        .font(.sofiaProBody)
                                        .foregroundColor(entry.frequency == frequency ? .black : .white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(entry.frequency == frequency ? Color.white : Color.clear)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Days of week picker (only show if frequency is weekly or daily)
                    if let frequency = entry.frequency, (frequency == .weekly || frequency == .daily) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Days of Week")
                                .font(.sofiaProSubheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(WeekDay.allCases.filter { $0 != .noPreference }, id: \.self) { day in
                                    Button(action: {
                                        focusedField = nil
                                        if entry.daysOfWeek.contains(day) {
                                            entry.daysOfWeek.remove(day)
                                        } else {
                                            entry.daysOfWeek.insert(day)
                                        }
                                    }) {
                                        Text(day.rawValue.prefix(3))
                                            .font(.sofiaProCaption)
                                            .foregroundColor(entry.daysOfWeek.contains(day) ? .black : .white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(entry.daysOfWeek.contains(day) ? Color.white : Color.clear)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.black)
            .navigationTitle(isEditing ? "Edit Workout" : "Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(entry)
                    }
                    .foregroundColor(canSave ? .white : .white.opacity(0.5))
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onTapGesture {
                focusedField = nil
            }
        }
        .confirmationDialog("Select Activity Type", isPresented: $showingActivityTypePicker) {
            ForEach(activityTypeOptions, id: \.self) { option in
                Button(option) {
                    entry.activityType = option
                }
            }
        }
    }
    
    // MARK: - Dropdown Options
    private let activityTypeOptions = [
        "HIIT", "Yoga", "Pilates", "Strength", "Run", "Cycle", 
        "Dance", "Walk", "Free Weights", "Sport", "Swim", "Circuit", "Row", "Other"
    ]
    
    private let intensityOptions = [
        "Low", "Mid", "Mid-High", "High"
    ]
    
    private let durationOptions = [
        "5 min", "15 min", "30 min", "45 min", "1 hour", "Over 1 hour"
    ]
}

// MARK: - Rest Days Step
struct RestDaysStepView: View {
    @Binding var preferredRestDays: Set<WeekDay>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Which are your preferred rest days?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("We won't schedule workouts on these days for you")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    SelectionButton(
                        title: day.rawValue,
                        isSelected: preferredRestDays.contains(day)
                    ) {
                        if preferredRestDays.contains(day) {
                            preferredRestDays.remove(day)
                            TelemetryDeck.signal("FitnessPersonalization.RestDay.Deselected", parameters: [
                                "day": day.rawValue,
                                "step": "rest_days"
                            ])
                        } else {
                            preferredRestDays.insert(day)
                            TelemetryDeck.signal("FitnessPersonalization.RestDay.Selected", parameters: [
                                "day": day.rawValue,
                                "step": "rest_days"
                            ])
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "rest_days",
                "stepNumber": "4"
            ])
        }
    }
}

// MARK: - Plan Start Choice Step
struct PlanStartChoiceStepView: View {
    @Binding var planStartChoice: PlanStartChoice?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ready for your plan to start today or tomorrow?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Choose when you'd like to begin your personalized fitness journey")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(PlanStartChoice.allCases, id: \.self) { choice in
                    SelectionButton(
                        title: choice.rawValue,
                        isSelected: planStartChoice == choice
                    ) {
                        planStartChoice = choice
                        TelemetryDeck.signal("FitnessPersonalization.PlanStartChoice.Selected", parameters: [
                            "planStartChoice": choice.rawValue,
                            "step": "plan_start_choice"
                        ])
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            TelemetryDeck.signal("FitnessPersonalization.Step.Started", parameters: [
                "step": "plan_start_choice",
                "stepNumber": "11"
            ])
        }
    }
}

// MARK: - Nutrition Personalization Steps
struct NutritionGoalsStepView: View {
    @Binding var nutritionGoals: Set<NutritionGoal>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What are your nutrition goals?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(NutritionGoal.allCases, id: \.self) { goal in
                    SelectionButton(
                        title: goal.rawValue,
                        isSelected: nutritionGoals.contains(goal)
                    ) {
                        if nutritionGoals.contains(goal) {
                            nutritionGoals.remove(goal)
                        } else {
                            nutritionGoals.insert(goal)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct EatingApproachStepView: View {
    @Binding var eatingApproaches: Set<EatingApproach>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Which best describes your current approach to eating?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(EatingApproach.allCases, id: \.self) { approach in
                    SelectionButton(
                        title: approach.rawValue,
                        isSelected: eatingApproaches.contains(approach)
                    ) {
                        if eatingApproaches.contains(approach) {
                            eatingApproaches.remove(approach)
                        } else {
                            eatingApproaches.insert(approach)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct MealFrequencyStepView: View {
    @Binding var breakfastFrequency: MealFrequency?
    @Binding var lunchFrequency: MealFrequency?
    @Binding var dinnerFrequency: MealFrequency?
    @Binding var snacksFrequency: MealFrequency?
    @Binding var dessertFrequency: MealFrequency?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How often do you have these meals?")
                    .font(.sofiaProTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select the frequency that best describes your eating habits")
                    .font(.sofiaProCaption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                MealFrequencyRow(
                    title: "Breakfast",
                    frequency: $breakfastFrequency
                )
                
                MealFrequencyRow(
                    title: "Lunch",
                    frequency: $lunchFrequency
                )
                
                MealFrequencyRow(
                    title: "Dinner",
                    frequency: $dinnerFrequency
                )
                
                MealFrequencyRow(
                    title: "Snacks",
                    frequency: $snacksFrequency
                )
                
                MealFrequencyRow(
                    title: "Dessert",
                    frequency: $dessertFrequency
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

struct MealFrequencyRow: View {
    let title: String
    @Binding var frequency: MealFrequency?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.sofiaProSubheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                ForEach(MealFrequency.allCases, id: \.self) { mealFreq in
                    MealFrequencyButton(
                        title: mealFreq.rawValue,
                        isSelected: frequency == mealFreq
                    ) {
                        frequency = mealFreq
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(red: 0.1, green: 0.12, blue: 0.18))
        .cornerRadius(10)
    }
}

struct MealFrequencyButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.sofiaProSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.sofiaProCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    // Invisible spacer to maintain consistent width
                    Image(systemName: "checkmark")
                        .font(.sofiaProCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.clear)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color(red: 0.1, green: 0.12, blue: 0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetabolismInfoStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your metabolism can speed up by 5-10% in your luteal phase (the 10-14 days before your period). This is why you might feel hungrier—and it's completely normal!")
                    .font(.sofiaProBody)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct BirthYearStepView: View {
    @Binding var birthYear: Int?
    
    private var birthYearRange: [Int] {
        return Array(1925...2015).reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What year were you born?")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
            
            VStack(spacing: 16) {
                HStack {
                    Text("Birth Year")
                        .font(.sofiaProHeadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                // Scrollable year picker with grid layout
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(birthYearRange, id: \.self) { year in
                            Button(action: {
                                birthYear = year
                            }) {
                                Text(String(year))
                                    .font(.sofiaProHeadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(birthYear == year ? .white : .white.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(birthYear == year ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color(red: 0.1, green: 0.12, blue: 0.18))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(birthYear == year ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 400)
                .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct PeriodSymptomsStepView: View {
    @Binding var periodSymptoms: Set<PeriodSymptom>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Do you experience any of these symptoms around your period?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(PeriodSymptom.allCases, id: \.self) { symptom in
                    SelectionButton(
                        title: symptom.rawValue,
                        isSelected: periodSymptoms.contains(symptom)
                    ) {
                        if periodSymptoms.contains(symptom) {
                            periodSymptoms.remove(symptom)
                        } else {
                            periodSymptoms.insert(symptom)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct WeightChangeStepView: View {
    @Binding var weightChange: WeightChange?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Have you had any recent weight loss or gain?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                ForEach(WeightChange.allCases, id: \.self) { change in
                    SelectionButton(
                        title: change.rawValue,
                        isSelected: weightChange == change
                    ) {
                        weightChange = change
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct EatingDisorderHistoryStepView: View {
    @Binding var eatingDisorderHistory: EatingDisorderHistory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Do you have a history of an eating disorder or disordered eating?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                ForEach(EatingDisorderHistory.allCases, id: \.self) { history in
                    SelectionButton(
                        title: history.rawValue,
                        isSelected: eatingDisorderHistory == history
                    ) {
                        eatingDisorderHistory = history
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct BirthDateWeightStepView: View {
    @Binding var birthDate: Date?
    @Binding var weight: Double?
    @State private var selectedBirthYear: Int = Calendar.current.component(.year, from: Date()) - 25
    @State private var weightString = ""
    
    private var birthYearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 100)...(currentYear - 13)).reversed()
    }
    
    private let yearFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Birth Year & Weight")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birth Year")
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                    
                    Menu {
                        ForEach(birthYearRange, id: \.self) { year in
                            Button(yearFormatter.string(from: NSNumber(value: year)) ?? "\(year)") {
                                selectedBirthYear = year
                                var components = DateComponents()
                                components.year = year
                                components.month = 1
                                components.day = 1
                                birthDate = Calendar.current.date(from: components)
                            }
                        }
                    } label: {
                        HStack {
                            Text(yearFormatter.string(from: NSNumber(value: selectedBirthYear)) ?? "\(selectedBirthYear)")
                                .font(.sofiaProBody)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(12)
                        .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (lbs)")
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                    
                    TextField("Enter weight", text: $weightString)
                        .font(.sofiaProBody)
                        .foregroundColor(.white)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: weightString) { _, newValue in
                            weight = Double(newValue)
                        }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct HeightWeightStepView: View {
    @Binding var heightFeet: Int?
    @Binding var heightInches: Int?
    @Binding var weight: Double?
    
    @State private var heightFeetString = ""
    @State private var heightInchesString = ""
    @State private var weightString = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your height and weight?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("This helps us provide personalized nutrition recommendations")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 20) {
                // Height section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Height")
                        .font(.sofiaProHeadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feet")
                                .font(.sofiaProSubheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("", text: $heightFeetString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: heightFeetString) { _, newValue in
                                    heightFeet = Int(newValue)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Inches")
                                .font(.sofiaProSubheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("", text: $heightInchesString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: heightInchesString) { _, newValue in
                                    heightInches = Int(newValue)
                                }
                        }
                    }
                }
                
                // Weight section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weight")
                        .font(.sofiaProHeadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    TextField("Enter weight in lbs", text: $weightString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .onChange(of: weightString) { _, newValue in
                            weight = Double(newValue)
                        }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
