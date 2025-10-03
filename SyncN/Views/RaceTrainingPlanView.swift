import SwiftUI
import SwiftData

struct RaceTrainingPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var personalizationData: [PersonalizationData]
    @State private var showingRaceTrainingSetup = false
    
    private var personalization: PersonalizationData? {
        personalizationData.first
    }
    
    private var trainingPlan: RaceTrainingPlan? {
        guard let personalization = personalization,
              personalization.raceTrainingEnabled == true,
              let raceType = personalization.raceType,
              let raceDate = personalization.raceDate,
              let trainingStartDate = personalization.trainingStartDate,
              let runnerLevel = personalization.runnerLevel,
              let runDaysPerWeek = personalization.runDaysPerWeek,
              let crossTrainDaysPerWeek = personalization.crossTrainDaysPerWeek,
              let restDaysPerWeek = personalization.restDaysPerWeek,
              let raceGoal = personalization.raceGoal else {
            return nil
        }
        
        return RaceTrainingEngine.shared.generateRaceTrainingPlan(
            raceType: raceType,
            raceDate: raceDate,
            trainingStartDate: trainingStartDate,
            runnerLevel: runnerLevel,
            runDaysPerWeek: runDaysPerWeek,
            crossTrainDaysPerWeek: crossTrainDaysPerWeek,
            restDaysPerWeek: restDaysPerWeek,
            raceGoal: raceGoal
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Your Race Training Plan")
                            .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if let plan = trainingPlan {
                            Text("\(plan.raceType) • \(plan.totalWeeks) weeks • \(plan.runDaysPerWeek) runs/week")
                                .font(.custom("Sofia Pro", size: 16, relativeTo: .body))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Training Plan Content
                    if let plan = trainingPlan {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(plan.weeklyPlans.enumerated()), id: \.offset) { weekIndex, weekPlan in
                                WeeklyPlanCard(
                                    weekPlan: weekPlan,
                                    weekNumber: weekIndex + 1,
                                    totalWeeks: plan.totalWeeks
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // No training plan available
                        VStack(spacing: 16) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("No Training Plan Available")
                                .font(.custom("Sofia Pro", size: 18, relativeTo: .headline))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Please complete your race training setup to generate your personalized plan.")
                                .font(.custom("Sofia Pro", size: 14, relativeTo: .body))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 60)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationTitle("Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit Plan") {
                        showingRaceTrainingSetup = true
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingRaceTrainingSetup) {
                RaceTrainingSetupView()
            }
        }
    }
}

struct WeeklyPlanCard: View {
    let weekPlan: WeeklyTrainingPlan
    let weekNumber: Int
    let totalWeeks: Int
    
    private var phaseColor: Color {
        switch weekPlan.phase {
        case .baseBuilding:
            return .blue
        case .intervalWorkouts:
            return .orange
        case .speedStrength:
            return .red
        case .taper:
            return .green
        }
    }
    
    private var phaseDescription: String {
        switch weekPlan.phase {
        case .baseBuilding:
            return "Build your aerobic base with steady, comfortable runs"
        case .intervalWorkouts:
            return "Improve speed and endurance with structured intervals"
        case .speedStrength:
            return "Focus on speed work and strength training"
        case .taper:
            return "Reduce volume and intensity to peak for race day"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Week Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(weekNumber) of \(totalWeeks)")
                        .font(.custom("Sofia Pro", size: 18, relativeTo: .headline))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(weekPlan.phase.rawValue)
                        .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                        .foregroundColor(phaseColor)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Phase indicator
                Circle()
                    .fill(phaseColor)
                    .frame(width: 12, height: 12)
            }
            
            // Phase description
            Text(phaseDescription)
                .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            
            // Daily workouts
            VStack(spacing: 8) {
                ForEach(Array(weekPlan.dailyPlans.enumerated()), id: \.offset) { dayIndex, dailyPlan in
                    DailyWorkoutRow(
                        dailyPlan: dailyPlan,
                        dayIndex: dayIndex
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(phaseColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DailyWorkoutRow: View {
    let dailyPlan: DailyTrainingPlan
    let dayIndex: Int
    
    private var dayName: String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[dayIndex]
    }
    
    private var workoutColor: Color {
        guard let workout = dailyPlan.workout else { return .gray }
        switch workout.type {
        case .easyRun:
            return .green
        case .tempoRun:
            return .orange
        case .intervalRun:
            return .red
        case .longRun:
            return .blue
        case .crossTraining:
            return .purple
        case .strengthTraining:
            return .pink
        case .rest:
            return .gray
        case .recovery:
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Day indicator
            Text(dayName)
                .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 30, alignment: .leading)
            
            // Workout type icon
            Image(systemName: workoutIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(workoutColor)
                .frame(width: 20)
            
            // Workout details
            VStack(alignment: .leading, spacing: 2) {
                if let workout = dailyPlan.workout {
                    Text(workout.type.rawValue)
                        .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if !workout.description.isEmpty {
                        Text(workout.description)
                            .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                } else {
                    Text("Rest Day")
                        .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Workout duration/distance
            if let workout = dailyPlan.workout, let duration = workout.duration {
                Text("\(duration) min")
                    .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                    .fontWeight(.medium)
                    .foregroundColor(workoutColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var workoutIcon: String {
        guard let workout = dailyPlan.workout else { return "moon" }
        switch workout.type {
        case .easyRun:
            return "figure.walk"
        case .tempoRun:
            return "figure.run"
        case .intervalRun:
            return "timer"
        case .longRun:
            return "figure.run"
        case .crossTraining:
            return "bicycle"
        case .strengthTraining:
            return "dumbbell"
        case .rest:
            return "moon"
        case .recovery:
            return "leaf"
        }
    }
}

#Preview {
    RaceTrainingPlanView()
        .modelContainer(for: [PersonalizationData.self], inMemory: true)
}
