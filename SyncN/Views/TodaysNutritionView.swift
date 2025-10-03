import SwiftUI
import SwiftData

// MARK: - Today's Nutrition View
struct TodaysNutritionView: View {
    @Query private var userProfiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    let selectedDate: Date
    let rewardsManager: RewardsManager
    let onNutritionHabitsTap: () -> Void
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    private var dateTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today's"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday's"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow's"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "\(formatter.string(from: selectedDate))'s"
        }
    }
    
    private func cyclePhaseForDate(_ date: Date) -> CyclePhase {
        return userProfile?.currentCyclePhase ?? .follicular
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("\(dateTitle) Nutrition")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(cyclePhaseForDate(selectedDate).headerColor)
                
                Spacer()
                
                Button("See More") {
                    onNutritionHabitsTap()
                }
                .font(.sofiaProSubheadline)
                .foregroundColor(.blue)
            }
            
            // Placeholder nutrition content
            VStack(alignment: .leading, spacing: 12) {
                Text("Personalized nutrition recommendations for your cycle phase")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                // Sample nutrition habits
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Iron-rich foods")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("Stay hydrated")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.15, green: 0.18, blue: 0.25))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
}
