import SwiftUI
import SwiftData

// MARK: - Workout Picker for Weekly Plan
struct WorkoutPickerForWeeklyPlan: View {
    @Binding var planDay: WeeklyPlanDay
    @Environment(\.dismiss) private var dismiss
    
    private let workoutOptions = [
        "Rest Day",
        "Intervals Guided Cardio",
        "Circuit: Form Focus",
        "Fresh Start Guided Cardio",
        "Endurance Guided Cardio",
        "Reflection Guided Cardio",
        "Dance Cardio, Affirmations Blast",
        "Follicular Meditation",
        "Spring Into Life Yoga",
        "Reflection Yoga",
        "Menstration Meditation",
        "Pilates",
        "Pilates: Core Focus",
        "Strength"
    ]
    
    var body: some View {
        NavigationView {
            List(workoutOptions, id: \.self) { workout in
                Button(action: {
                    selectWorkout(workout)
                }) {
                    HStack {
                        Text(workout)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Select Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func selectWorkout(_ workout: String) {
        if workout == "Rest Day" {
            planDay.workouts = ["Rest Day"]
        } else {
            // Remove "Rest Day" if it exists before adding new workout
            if planDay.workouts.contains("Rest Day") {
                planDay.workouts.removeAll { $0 == "Rest Day" }
            }
            planDay.workouts.append(workout)
        }
        dismiss()
    }
}

// Helper function to create today's plan day
func createTodayPlanDay() -> WeeklyPlanDay {
    let today = Date()
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "EEEE"
    let dayName = dayFormatter.string(from: today)
    
    return WeeklyPlanDay(
        day: dayName,
        date: today,
        workouts: [],
        status: .suggested
    )
}
