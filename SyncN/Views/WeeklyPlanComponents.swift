import SwiftUI
import SwiftData

// MARK: - Phase Header View
struct PhaseHeaderView: View {
    let phase: CyclePhase
    let colorForPhase: (CyclePhase) -> Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Phase name - smaller font
            Text(phase.displayName)
                .font(.sofiaProCaption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            // Workout intensity
            HStack(spacing: 3) {
                Image(systemName: getWorkoutIntensityIcon(for: phase))
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                Text(getWorkoutIntensity(for: phase))
                    .font(.sofiaProCaption2)
                    .foregroundColor(.secondary)
            }
            
            // Hormone status
            HStack(spacing: 3) {
                Image(systemName: getHormoneStatusIcon(for: phase))
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                Text(getHormoneStatus(for: phase))
                    .font(.sofiaProCaption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(colorForPhase(phase).opacity(0.08))
        .cornerRadius(8)
    }
    
    // Get workout intensity description for a phase
    private func getWorkoutIntensity(for phase: CyclePhase) -> String {
        switch phase {
        case .luteal, .lutealMoon:
            return "Compassionate workouts"
        case .follicular, .follicularMoon:
            return "Mid to high intensity workouts"
        case .ovulatory, .ovulatoryMoon:
            return "High intensity and social workouts"
        case .menstrual, .menstrualMoon:
            return "Restorative movements and self care"
        }
    }
    
    // Get hormone status description for a phase
    private func getHormoneStatus(for phase: CyclePhase) -> String {
        switch phase {
        case .luteal, .lutealMoon:
            return "Hormones are declining"
        case .follicular, .follicularMoon:
            return "Hormones are rising"
        case .ovulatory, .ovulatoryMoon:
            return "Hormones are at their peak"
        case .menstrual, .menstrualMoon:
            return "Hormones are at their lowest"
        }
    }
    
    // Get appropriate icon for workout intensity
    private func getWorkoutIntensityIcon(for phase: CyclePhase) -> String {
        switch phase {
        case .luteal, .lutealMoon:
            return "heart.fill" // Compassionate workouts
        case .follicular, .follicularMoon:
            return "bolt.fill" // Mid to high intensity
        case .ovulatory, .ovulatoryMoon:
            return "flame.fill" // High intensity and social
        case .menstrual, .menstrualMoon:
            return "leaf.fill" // Restorative movements
        }
    }
    
    // Get appropriate icon for hormone status
    private func getHormoneStatusIcon(for phase: CyclePhase) -> String {
        switch phase {
        case .luteal, .lutealMoon:
            return "arrow.down.right.circle" // Hormones declining - swoop down
        case .follicular, .follicularMoon:
            return "arrow.up.right.circle" // Hormones rising - swoop up
        case .ovulatory, .ovulatoryMoon:
            return "arrow.up.to.line" // Hormones at peak
        case .menstrual, .menstrualMoon:
            return "minus" // Hormones at lowest
        }
    }
}

// MARK: - Weekly Plan Day Row
struct WeeklyPlanDayRow: View {
    @Binding var planDay: WeeklyPlanDay
    @Binding var draggedItem: WeeklyPlanDay?
    @Binding var draggedWorkout: String?
    @Binding var draggedWorkoutIndex: Int?
    @Binding var showingTrash: Bool
    @Binding var hoveredDayIndex: Int?
    @Binding var hoveredDayId: UUID?
    @Binding var weeklyPlan: [WeeklyPlanDay]
    @State private var showingWorkoutPicker = false
    let currentWeek: Date
    
    @Query private var userProfiles: [UserProfile]
    
    private let calendar = Calendar.current
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(planDay.date)
    }
    
    // Get cycle phase for this day's date
    private var cyclePhase: CyclePhase? {
        guard let profile = userProfile else { return nil }
        return profile.calculateCyclePhaseForDate(planDay.date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Day label with cycle phase circle
            DayLabelWithPhaseView(
                dayName: planDay.day,
                isToday: isToday,
                phase: cyclePhase
            )
            
            // Workouts display with consistent spacing
            HStack {
                WorkoutDisplayView(
                    planDay: $planDay,
                    currentWeek: currentWeek,
                    showingWorkoutPicker: $showingWorkoutPicker,
                    draggedItem: $draggedItem,
                    draggedWorkout: $draggedWorkout,
                    draggedWorkoutIndex: $draggedWorkoutIndex
                )
                
                Spacer()
                
                // Plus button
                Button(action: {
                    showingWorkoutPicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.sofiaProTitle2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hoveredDayId == planDay.id ? Color.blue.opacity(0.1) : Color.clear)
        )
        .onDrop(of: [.text], delegate: DayRowDropDelegate(
            planDay: $planDay,
            draggedItem: $draggedItem,
            draggedWorkout: $draggedWorkout,
            draggedWorkoutIndex: $draggedWorkoutIndex,
            hoveredDayId: $hoveredDayId,
            weeklyPlan: $weeklyPlan,
            showingTrash: $showingTrash
        ))
        .sheet(isPresented: $showingWorkoutPicker) {
            WorkoutPickerForWeeklyPlan(planDay: $planDay)
        }
    }
}

// MARK: - Day Label with Phase View
struct DayLabelWithPhaseView: View {
    let dayName: String
    let isToday: Bool
    let phase: CyclePhase?
    
    var body: some View {
        HStack(spacing: 8) {
            // Day label
            Text(dayName.prefix(3).uppercased())
                .font(.system(size: 14))
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(isToday ? .blue : .secondary)
                .frame(width: 45, alignment: .leading)
            
            // Cycle phase circle
            if let phase = phase {
                ZStack {
                    Circle()
                        .fill(colorForPhase(phase))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isToday ? Color.white : Color.clear, lineWidth: 2)
                        )
                    
                    // Try to load custom image with explicit debugging
                    Group {
                        if let uiImage = UIImage(named: phase.icon) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                        } else {
                            // Fallback to SF Symbol if custom image fails
                            Image(systemName: phase.systemIcon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
        }
        .frame(width: 80, alignment: .leading)
    }
    
    private func colorForPhase(_ phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual, .menstrualMoon:
            return Color(red: 0.957, green: 0.408, blue: 0.573)
        case .follicular, .follicularMoon:
            return Color(red: 0.976, green: 0.851, blue: 0.157)
        case .ovulatory, .ovulatoryMoon:
            return Color(red: 0.157, green: 0.851, blue: 0.851)
        case .luteal, .lutealMoon:
            return Color(red: 0.557, green: 0.671, blue: 0.557)
        }
    }
}

// MARK: - Workout Display View
struct WorkoutDisplayView: View {
    @Binding var planDay: WeeklyPlanDay
    let currentWeek: Date
    @Binding var showingWorkoutPicker: Bool
    @Binding var draggedItem: WeeklyPlanDay?
    @Binding var draggedWorkout: String?
    @Binding var draggedWorkoutIndex: Int?
    
    var body: some View {
        if planDay.workouts.isEmpty {
            Text("Rest Day")
                .font(.system(size: 14))
                .fontWeight(.regular)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(25)
                .onTapGesture {
                    showingWorkoutPicker = true
                }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(planDay.workouts.enumerated()), id: \.offset) { index, workout in
                        Text(workout)
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(25)
                            .onTapGesture {
                                showingWorkoutPicker = true
                            }
                            .onDrag {
                                draggedItem = planDay
                                draggedWorkout = workout
                                draggedWorkoutIndex = index
                                return NSItemProvider(object: workout as NSString)
                            }
                    }
                }
            }
            .frame(height: 36)
        }
    }
}

// MARK: - Drop Delegates
struct DayRowDropDelegate: DropDelegate {
    @Binding var planDay: WeeklyPlanDay
    @Binding var draggedItem: WeeklyPlanDay?
    @Binding var draggedWorkout: String?
    @Binding var draggedWorkoutIndex: Int?
    @Binding var hoveredDayId: UUID?
    @Binding var weeklyPlan: [WeeklyPlanDay]
    @Binding var showingTrash: Bool
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem,
              let workout = draggedWorkout,
              let workoutIndex = draggedWorkoutIndex else {
            return false
        }
        
        // Find the source day index
        guard let sourceIndex = weeklyPlan.firstIndex(where: { $0.id == draggedItem.id }),
              workoutIndex < weeklyPlan[sourceIndex].workouts.count else {
            return false
        }
        
        // Find the target day index
        guard let targetIndex = weeklyPlan.firstIndex(where: { $0.id == planDay.id }) else {
            return false
        }
        
        // Don't drop on the same day
        if sourceIndex == targetIndex {
            return false
        }
        
        // Clear drag state first
        self.draggedItem = nil
        self.draggedWorkout = nil
        self.draggedWorkoutIndex = nil
        self.hoveredDayId = nil
        showingTrash = false
        
        // Move the workout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if weeklyPlan[targetIndex].workouts.contains("Rest Day") {
                weeklyPlan[targetIndex].workouts.removeAll { $0 == "Rest Day" }
            }
            
            weeklyPlan[targetIndex].workouts.append(workout)
            weeklyPlan[targetIndex].status = .suggested
            
            weeklyPlan[sourceIndex].workouts.remove(at: workoutIndex)
            if weeklyPlan[sourceIndex].workouts.isEmpty {
                weeklyPlan[sourceIndex].status = .suggested
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        hoveredDayId = planDay.id
    }
    
    func dropExited(info: DropInfo) {
        hoveredDayId = nil
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Trash Drop Delegate
struct TrashDropDelegate: DropDelegate {
    @Binding var weeklyPlan: [WeeklyPlanDay]
    @Binding var draggedItem: WeeklyPlanDay?
    @Binding var draggedWorkout: String?
    @Binding var draggedWorkoutIndex: Int?
    @Binding var showingTrash: Bool
    @Binding var hoveringOverTrash: Bool
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem,
              let workoutIndex = draggedWorkoutIndex else {
            return false
        }
        
        // Find the source day index
        guard let sourceIndex = weeklyPlan.firstIndex(where: { $0.id == draggedItem.id }),
              workoutIndex < weeklyPlan[sourceIndex].workouts.count else {
            return false
        }
        
        // Clear drag state and hide trash first
        self.draggedItem = nil
        self.draggedWorkout = nil
        self.draggedWorkoutIndex = nil
        showingTrash = false
        hoveringOverTrash = false
        
        // Remove the workout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            weeklyPlan[sourceIndex].workouts.remove(at: workoutIndex)
            
            if weeklyPlan[sourceIndex].workouts.isEmpty {
                weeklyPlan[sourceIndex].status = .suggested
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            hoveringOverTrash = true
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            hoveringOverTrash = false
        }
    }
}
