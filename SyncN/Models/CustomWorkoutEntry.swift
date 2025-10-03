import Foundation

struct CustomWorkoutEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var activityType: String
    var intensity: String
    var duration: String
    var location: WorkoutLocation?
    var frequency: CustomWorkoutFrequency?
    var daysOfWeek: Set<WeekDay>
    
    init(name: String = "", activityType: String = "", intensity: String = "", duration: String = "", location: WorkoutLocation? = nil, frequency: CustomWorkoutFrequency? = nil, daysOfWeek: Set<WeekDay> = []) {
        self.id = UUID()
        self.name = name
        self.activityType = activityType
        self.intensity = intensity
        self.duration = duration
        self.location = location
        self.frequency = frequency
        self.daysOfWeek = daysOfWeek
    }
}

enum WorkoutLocation: String, CaseIterable, Codable {
    case studio = "Studio"
    case home = "Home"
    case outdoors = "Outdoor"
    case gym = "Gym"
}

enum CustomWorkoutFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
}
