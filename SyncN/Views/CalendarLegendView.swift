import SwiftUI
import SwiftData

struct CalendarLegendView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    init() {
        // This initializer is needed for SwiftUI to properly initialize the view
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calendar Legend")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Understanding your cycle phases and calendar symbols")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    // Cycle Phases Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cycle Phases")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            // Menstrual Phase
                            LegendRow(
                                color: Color(red: 0.957, green: 0.408, blue: 0.573),
                                phase: .menstrual,
                                title: "Menstrual",
                                description: "Your period - focus on rest and gentle movement"
                            )
                            
                            // Follicular Phase
                            LegendRow(
                                color: Color(red: 0.976, green: 0.851, blue: 0.157),
                                phase: .follicular,
                                title: "Follicular",
                                description: "Building energy - great time for strength training"
                            )
                            
                            // Ovulatory Phase
                            LegendRow(
                                color: Color(red: 0.157, green: 0.851, blue: 0.851),
                                phase: .ovulatory,
                                title: "Ovulatory",
                                description: "Peak energy - perfect for high-intensity workouts"
                            )
                            
                            // Luteal Phase
                            LegendRow(
                                color: Color(red: 0.557, green: 0.671, blue: 0.557),
                                phase: .luteal,
                                title: "Luteal",
                                description: "Preparing for next cycle - focus on recovery and flexibility"
                            )
                        }
                    }
                    
                    // Cycle Types Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cycle Types & Predictions")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Regular Cycles")
                                        .font(.sofiaProSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("We predict your phases based on your average cycle length and period start date. Phases are calculated using standard medical guidelines.")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                // Orange dashed circle indicator (matches calendar)
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.976, green: 0.851, blue: 0.157)) // Sample phase color
                                        .frame(width: 20, height: 20)
                                    
                                    Circle()
                                        .stroke(
                                            Color.orange,
                                            style: StrokeStyle(lineWidth: 2.0, dash: [3, 2])
                                        )
                                        .frame(width: 24, height: 24)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Irregular Cycles")
                                        .font(.sofiaProSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("For irregular cycles, we show a wider prediction window (dashed orange border) to account for cycle variations. Phase predictions are less precise but still helpful for planning.")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No Period Data")
                                        .font(.sofiaProSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("Dates before your first logged period show no phase colors. Start tracking your period to see personalized phase predictions.")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                    
                    // Fitness Dots Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fitness Indicators")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            // Workout scheduled
                            HStack(spacing: 12) {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Workout Scheduled")
                                        .font(.sofiaProSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("You have a fitness class or workout planned for this day")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                            
                            // Workout completed
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 16, height: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Workout Completed")
                                        .font(.sofiaProSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("You've completed your scheduled workout for this day")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                            
                            // No workout
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 16, height: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("No Workout")
                                        .font(.sofiaProSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("Rest day or no fitness activity scheduled")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Current User Info
                    if let userProfile = userProfile {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Cycle")
                                .font(.sofiaProHeadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Cycle Type:")
                                        .font(.sofiaProSubheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text(userProfile.hasIrregularCycles ? "Irregular" : "Regular")
                                        .font(.sofiaProSubheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(userProfile.hasIrregularCycles ? .orange : .green)
                                }
                                
                                if let cycleLength = userProfile.cycleLength {
                                    HStack {
                                        Text("Average Cycle Length:")
                                            .font(.sofiaProSubheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("\(cycleLength) days")
                                            .font(.sofiaProSubheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                if let periodLength = userProfile.averagePeriodLength {
                                    HStack {
                                        Text("Average Period Length:")
                                            .font(.sofiaProSubheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("\(periodLength) days")
                                            .font(.sofiaProSubheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.black)
            .navigationTitle("Legend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct LegendRow: View {
    let color: Color
    let phase: CyclePhase
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                
                // Try to load custom phase icon first, fallback to SF Symbol
                Group {
                    if let uiImage = UIImage(named: phase.icon) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    } else {
                        // Fallback to SF Symbol if custom image fails
                        Image(systemName: phase.systemIcon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.sofiaProSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.sofiaProCaption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

#Preview {
    CalendarLegendView()
}
