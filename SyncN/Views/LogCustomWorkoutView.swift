import SwiftUI
import SwiftData
import TelemetryDeck

struct LogCustomWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var selectedActivityType: String = ""
    @State private var selectedIntensity: String = ""
    @State private var selectedDuration: String = ""
    @State private var workoutName: String = ""
    
    let activityTypes = ["HIIT", "Yoga", "Pilates", "Strength", "Run", "Cycle", "Dance", "Walk", "Free Weights", "Sport", "Swim", "Circuit", "Row", "Other"]
    let intensities = ["Low", "Mid", "Mid-High", "High"]
    let durations = ["5 min", "15 min", "30 min", "45 min", "1 hour", "Over 1 hour"]
    
    // Computed property to check if all fields are filled
    private var isFormComplete: Bool {
        return !selectedActivityType.isEmpty && 
               !selectedIntensity.isEmpty && 
               !selectedDuration.isEmpty && 
               !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveCustomWorkout() {
        guard let userProfile = userProfiles.first else {
            print("Error: No user profile found")
            return
        }
        
        let customWorkout = CustomWorkout(
            name: workoutName,
            activityType: selectedActivityType,
            intensity: selectedIntensity,
            duration: selectedDuration
        )
        
        // Track custom workout creation
        TelemetryDeck.signal("Workout.CustomCreated", parameters: [
            "workoutName": workoutName,
            "activityType": selectedActivityType,
            "intensity": selectedIntensity,
            "duration": selectedDuration
        ])
        
        // Add to user's custom workouts
        userProfile.customWorkouts.append(customWorkout)
        
        // Save to SwiftData
        do {
            try modelContext.save()
            print("Custom workout saved successfully: \(workoutName)")
            dismiss()
        } catch {
            print("Error saving custom workout: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - Simplified without back button
                HStack {
                    Spacer()
                    
                    Text("ADD ACTIVITY")
                        .font(.custom("Sofia Pro", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
                
                // Form content
                VStack(spacing: 24) {
                    // Activity Type Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity Type")
                            .font(.custom("Sofia Pro", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Menu {
                            ForEach(activityTypes, id: \.self) { type in
                                Button(type) {
                                    selectedActivityType = type
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedActivityType.isEmpty ? "Select" : selectedActivityType)
                                    .font(.custom("Sofia Pro", size: 16))
                                    .foregroundColor(selectedActivityType.isEmpty ? .gray : .black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Intensity Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity")
                            .font(.custom("Sofia Pro", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Menu {
                            ForEach(intensities, id: \.self) { intensity in
                                Button(intensity) {
                                    selectedIntensity = intensity
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedIntensity.isEmpty ? "Select" : selectedIntensity)
                                    .font(.custom("Sofia Pro", size: 16))
                                    .foregroundColor(selectedIntensity.isEmpty ? .gray : .black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Duration Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.custom("Sofia Pro", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Menu {
                            ForEach(durations, id: \.self) { duration in
                                Button(duration) {
                                    selectedDuration = duration
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedDuration.isEmpty ? "Select" : selectedDuration)
                                    .font(.custom("Sofia Pro", size: 16))
                                    .foregroundColor(selectedDuration.isEmpty ? .gray : .black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Name Text Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.custom("Sofia Pro", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        TextField("Enter workout name", text: $workoutName)
                            .font(.custom("Sofia Pro", size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Add to saved workouts button
                Button(action: {
                    saveCustomWorkout()
                }) {
                    Text("Add custom workout")
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormComplete ? Color.purple : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isFormComplete)
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "LogCustomWorkout",
                "pageType": "logging_feature"
            ])
        }
    }
}

#Preview {
    LogCustomWorkoutView()
}
