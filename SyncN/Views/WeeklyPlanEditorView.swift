import SwiftUI
import SwiftData

// MARK: - Weekly Plan Editor (Full Featured)
struct WeeklyPlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var weeklyPlan: [WeeklyPlanDay] = []
    @State private var originalWeeklyPlan: [WeeklyPlanDay] = []
    @State private var draggedItem: WeeklyPlanDay?
    @State private var draggedWorkout: String? = nil
    @State private var draggedWorkoutIndex: Int? = nil
    @State private var showingTrash = false
    @State private var hoveredDayIndex: Int? = nil
    @State private var hoveringOverTrash = false
    @State private var hoveredDayId: UUID? = nil
    @State private var showingLogCustomWorkout = false
    
    let initialWeek: Date?

    var userProfile: UserProfile? {
        userProfiles.first
    }

    @State private var currentWeek: Date = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Week navigation header - compact
                VStack(spacing: 4) {
                    Text("Weekly Fitness Plan")
                        .font(.sofiaProTitle2)
                        .fontWeight(.bold)
                    
                    // Week navigation
                    HStack {
                        Button(action: previousWeek) {
                            Image(systemName: "chevron.left")
                                .font(.sofiaProTitle2)
                                .foregroundColor(canGoToPreviousWeek ? .blue : .gray)
                        }
                        .disabled(!canGoToPreviousWeek)
                        
                        Spacer()
                        
                        Text(weekRangeString)
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: nextWeek) {
                            Image(systemName: "chevron.right")
                                .font(.sofiaProTitle2)
                                .foregroundColor(canGoToNextWeek ? .blue : .gray)
                        }
                        .disabled(!canGoToNextWeek)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal, 16)
                .padding(.top, -22)
                .padding(.bottom, 8)
                
                // Weekly plan content
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(weeklyPlan.enumerated()), id: \.element.id) { index, planDay in
                            VStack(spacing: 0) {
                                // Show phase information before phase changes
                                if shouldShowPhaseHeader(for: index) {
                                    PhaseHeaderView(
                                        phase: getPhaseForDay(planDay),
                                        colorForPhase: colorForPhase
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                                
                                WeeklyPlanDayRow(
                                    planDay: $weeklyPlan[index],
                                    draggedItem: $draggedItem,
                                    draggedWorkout: $draggedWorkout,
                                    draggedWorkoutIndex: $draggedWorkoutIndex,
                                    showingTrash: $showingTrash,
                                    hoveredDayIndex: $hoveredDayIndex,
                                    hoveredDayId: $hoveredDayId,
                                    weeklyPlan: $weeklyPlan,
                                    currentWeek: currentWeek
                                )
                                .padding(.horizontal, 16)
                                
                                // Add divider between days (except for the last one)
                                if index < weeklyPlan.count - 1 {
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Bottom area with trash and Log Custom Workout button
                VStack(spacing: 12) {
                    // Trash zone when dragging
                    if showingTrash {
                        VStack {
                            Image(systemName: "trash")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(hoveringOverTrash ? .red : .gray)
                            Text("Drop here to remove")
                                .font(.sofiaProCaption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(hoveringOverTrash ? Color.red.opacity(0.1) : Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(hoveringOverTrash ? Color.red : Color.clear, lineWidth: 2)
                                )
                        )
                        .onDrop(of: [.text], delegate: TrashDropDelegate(
                            weeklyPlan: $weeklyPlan,
                            draggedItem: $draggedItem,
                            draggedWorkout: $draggedWorkout,
                            draggedWorkoutIndex: $draggedWorkoutIndex,
                            showingTrash: $showingTrash,
                            hoveringOverTrash: $hoveringOverTrash
                        ))
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom))
                    }
                    
                    // Log Custom Workout Button
                    Button(action: {
                        showingLogCustomWorkout = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.sofiaProTitle2)
                                .foregroundColor(.blue)
                            
                            Text("Log Custom Workout")
                                .font(.sofiaProSubheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWeeklyPlan()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            initializeCurrentWeek()
            loadWeeklyPlan()
        }
        .onChange(of: draggedItem != nil) { _, isDragging in
            // Show trash when dragging starts, hide when dragging ends
            showingTrash = isDragging
            
            // Additional safety check - if not dragging, ensure all states are reset
            if !isDragging {
                draggedItem = nil
                draggedWorkout = nil
                draggedWorkoutIndex = nil
                hoveredDayIndex = nil
                hoveredDayId = nil
                hoveringOverTrash = false
            }
        }
        .sheet(isPresented: $showingLogCustomWorkout) {
            LogCustomWorkoutView()
        }
    }
    
    private func initializeCurrentWeek() {
        if let userProfile = userProfile {
            currentWeek = CyclePredictionService.shared.getUserPlanStartDate(for: userProfile)
            print("📋 WeeklyPlanEditor: Initialized with user's plan start date: \(currentWeek)")
        } else {
            currentWeek = Date()
            print("📋 WeeklyPlanEditor: No user profile, using today's date")
        }
    }
    
    private func loadWeeklyPlan() {
        guard let userProfile = userProfile else {
            print("📋 WeeklyPlanEditor: No user profile found")
            return
        }
        
        let calendar = Calendar.current
        let userPlanStartDate = CyclePredictionService.shared.getUserPlanStartDate(for: userProfile)
        
        // Calculate which week of the plan we're viewing
        let daysBetweenPlanStartAndCurrentWeek = calendar.dateComponents([.day], from: userPlanStartDate, to: currentWeek).day ?? 0
        let weeksFromPlanStart = daysBetweenPlanStartAndCurrentWeek / 7
        
        // Start of the week we're viewing in the context of the user's plan
        let startOfWeek = calendar.date(byAdding: .day, value: weeksFromPlanStart * 7, to: userPlanStartDate) ?? userPlanStartDate
        
        // Create weekly plan from saved data
        var loadedPlan: [WeeklyPlanDay] = []
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        for index in 0..<7 {
            let date = calendar.date(byAdding: .day, value: index, to: startOfWeek) ?? currentWeek
            let actualDayName = dayFormatter.string(from: date)
            
            // Find workouts for this exact date
            let savedWorkouts = userProfile.weeklyFitnessPlan.filter { entry in
                calendar.isDate(entry.date, inSameDayAs: date)
            }
            
            if !savedWorkouts.isEmpty {
                let workoutTitles = savedWorkouts.map { $0.workoutTitle }
                loadedPlan.append(WeeklyPlanDay(day: actualDayName, date: date, workouts: workoutTitles, status: .confirmed))
            } else {
                loadedPlan.append(WeeklyPlanDay(day: actualDayName, date: date, workouts: [], status: .suggested))
            }
        }
        
        weeklyPlan = loadedPlan
        originalWeeklyPlan = loadedPlan // Store original plan for comparison
    }
    
    private func saveWeeklyPlan() {
        guard let userProfile = userProfile else {
            print("🔧 SAVE: No user profile found!")
            return
        }
        
        // Check if any changes have been made
        let hasChanges = !weeklyPlan.elementsEqual(originalWeeklyPlan) { day1, day2 in
            day1.day == day2.day && day1.workouts == day2.workouts
        }
        
        print("🔧 SAVE: Has changes: \(hasChanges)")
        
        if !hasChanges {
            print("🔧 SAVE: No changes detected, skipping save")
            return
        }
        
        // Save logic would go here
        try? modelContext.save()
    }
    
    // MARK: - Week Navigation
    private var weekRangeString: String {
        let calendar = Calendar.current
        
        // Use the same logic as loadWeeklyPlan to get the correct week range
        guard let userProfile = userProfile else {
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentWeek)?.start ?? currentWeek
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? currentWeek
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            
            return "\(startString) - \(endString)"
        }
        
        // Calculate the week range based on user's plan start date
        let userPlanStartDate = CyclePredictionService.shared.getUserPlanStartDate(for: userProfile)
        let daysBetweenPlanStartAndCurrentWeek = calendar.dateComponents([.day], from: userPlanStartDate, to: currentWeek).day ?? 0
        let weeksFromPlanStart = daysBetweenPlanStartAndCurrentWeek / 7
        let startOfWeek = calendar.date(byAdding: .day, value: weeksFromPlanStart * 7, to: userPlanStartDate) ?? userPlanStartDate
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? currentWeek
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: startOfWeek)
        let endString = formatter.string(from: endOfWeek)
        
        return "\(startString) - \(endString)"
    }
    
    private var canGoToPreviousWeek: Bool {
        let today = Date()
        let currentWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let currentWeekStartOfDisplayedWeek = Calendar.current.dateInterval(of: .weekOfYear, for: currentWeek)?.start ?? currentWeek
        
        // Can go back only if we're not already at the current week
        return currentWeekStartOfDisplayedWeek > currentWeekStart
    }
    
    private var canGoToNextWeek: Bool {
        // Always allow forward navigation - no restrictions
        return true
    }
    
    private func previousWeek() {
        withAnimation {
            let previousWeekDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
            let today = Date()
            let currentWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            
            // Only allow navigation back to the current week, no further back
            if previousWeekDate >= currentWeekStart {
                currentWeek = previousWeekDate
                loadWeeklyPlan()
            }
        }
    }
    
    private func nextWeek() {
        withAnimation {
            let nextWeekDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
            currentWeek = nextWeekDate
            loadWeeklyPlan()
        }
    }
    
    // MARK: - Phase Logic
    private func shouldShowPhaseHeader(for index: Int) -> Bool {
        guard index < weeklyPlan.count else { return false }
        
        if index == 0 { return true }
        
        guard index > 0 && (index - 1) < weeklyPlan.count else { return false }
        
        let currentDay = weeklyPlan[index]
        let previousDay = weeklyPlan[index - 1]
        
        return getPhaseForDay(currentDay) != getPhaseForDay(previousDay)
    }
    
    private func getPhaseForDay(_ day: WeeklyPlanDay) -> CyclePhase {
        guard let profile = userProfile else { return .follicular }
        return profile.calculateCyclePhaseForDate(day.date)
    }
    
    // Phase color matching CalendarView
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



// MARK: - Date Formatter Extension
extension DateFormatter {
    static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}
