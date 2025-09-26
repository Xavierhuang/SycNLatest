import Foundation

struct WeeklyPlanDay: Identifiable {
    let id = UUID()
    let day: String
    let date: Date
    var workouts: [String] // Changed from single workout to array of workouts
    var status: WorkoutStatus
    
    // Computed property for backward compatibility
    var workout: String {
        get { workouts.first ?? "Rest Day" }
        set { workouts = [newValue] }
    }
}
