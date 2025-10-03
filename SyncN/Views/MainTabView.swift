import SwiftUI
import SwiftData
import TelemetryDeck



struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var workoutRatings: [WorkoutRating]
    @Query private var userRewards: [UserRewardsData]
    @State private var selectedTab = 0
    @State private var showingFAB = false
    @State private var showingOnboarding = false
    @State private var showingFitnessPersonalization = false
    @State private var showingNutritionPersonalization = false
    @State private var showingSymptomLog = false
    @State private var showingEditPeriodDates = false
    @State private var showingWorkoutRating = false
    @State private var showingWorkoutPicker = false
    @State private var showingFitnessReflections = false
    @State private var completedWorkoutInfo: (title: String, instructor: String, id: String, date: Date)?
    @State private var showingHabitCompletionPopup = false
    @State private var habitCompletionMessage = ""
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var userRewardsData: UserRewardsData? {
        userRewards.first
    }
    
    // Function to show habit completion popup with conditional messaging
    private func showHabitCompletionPopup() {
        let today = Date()
        let calendar = Calendar.current
        
        let completedFitness = userProfile?.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: today) && entry.status == .confirmed
        } == true ? 1 : 0
        
        let completedNutrition = userProfile?.dailyHabits.first { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }?.completedNutritionHabitsString?.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count ?? 0
        
        let totalCompleted = completedFitness + completedNutrition
        
        // Set conditional message based on number of habits completed
        switch totalCompleted {
        case 1:
            habitCompletionMessage = "A new bead has been added to your cycle bracelet!"
        case 2:
            habitCompletionMessage = "One more habit until a gold bead!"
        case 3...:
            habitCompletionMessage = "Upgrade to a gold bead!"
        default:
            habitCompletionMessage = "A new bead has been added to your cycle bracelet!"
        }
        
        showingHabitCompletionPopup = true
        
        // Track habit completion analytics
        TelemetryDeck.signal("Habit.Completion", parameters: [
            "totalHabitsCompleted": "\(totalCompleted)",
            "fitnessHabits": "\(completedFitness)",
            "nutritionHabits": "\(completedNutrition)"
        ])
        
        // Track bracelet bead progression
        let beadType: String
        let beadColor: String
        
        switch totalCompleted {
        case 0:
            beadType = "Clear"
            beadColor = "clear"
        case 1...2:
            beadType = "Pearl"
            beadColor = "pearl"
        case 3...:
            beadType = "Gold"
            beadColor = "gold"
        default:
            beadType = "Clear"
            beadColor = "clear"
        }
        
        TelemetryDeck.signal("Bracelet.BeadEarned", parameters: [
            "beadType": beadType,
            "beadColor": beadColor,
            "totalHabitsCompleted": "\(totalCompleted)",
            "fitnessHabits": "\(completedFitness)",
            "nutritionHabits": "\(completedNutrition)",
            "currentStreak": "\(userRewardsData?.currentStreak ?? 0)",
            "cyclePhase": userProfile?.calculateCyclePhaseForDate(Date()).rawValue ?? "unknown"
        ])
    }
    
    private func saveWorkoutRating(workoutId: String, workoutTitle: String, instructor: String, rating: Int, dateCompleted: Date, notes: String? = nil) {
        // Get cycle phase for the workout completion date
        let currentPhase = userProfile?.calculateCyclePhaseForDate(dateCompleted) ?? .follicular
        
        // Create workout rating
        let workoutRating = WorkoutRating(
            workoutId: workoutId,
            workoutTitle: workoutTitle,
            instructor: instructor.isEmpty ? nil : instructor,
            rating: rating,
            notes: notes,
            dateCompleted: dateCompleted,
            cyclePhase: currentPhase
        )
        
        // Save to SwiftData
        modelContext.insert(workoutRating)
        
        do {
            try modelContext.save()
            print("✅ Workout rating saved: \(workoutTitle) - \(rating) stars, Notes: \(notes ?? "none")")
            
            // Track workout rating analytics
            TelemetryDeck.signal("Workout.Rated", parameters: [
                "workoutTitle": workoutTitle,
                "rating": "\(rating)",
                "instructor": instructor,
                "cyclePhase": currentPhase.rawValue,
                "hasNotes": notes != nil ? "true" : "false",
                "ratingDate": ISO8601DateFormatter().string(from: dateCompleted)
            ])
            
            // Track bracelet progress after workout completion
            let today = Date()
            let calendar = Calendar.current
            
            let completedFitness = userProfile?.weeklyFitnessPlan.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: today) && entry.status == .confirmed
            } == true ? 1 : 0
            
            let completedNutrition = userProfile?.dailyHabits.first { entry in
                calendar.isDate(entry.date, inSameDayAs: today)
            }?.completedNutritionHabitsString?.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count ?? 0
            
            let totalCompleted = completedFitness + completedNutrition
            
            TelemetryDeck.signal("Bracelet.ProgressUpdated", parameters: [
                "trigger": "workout_completion",
                "workoutTitle": workoutTitle,
                "todaysHabitsCompleted": "\(totalCompleted)",
                "fitnessHabits": "\(completedFitness)",
                "nutritionHabits": "\(completedNutrition)",
                "currentStreak": "\(userRewardsData?.currentStreak ?? 0)",
                "cyclePhase": currentPhase.rawValue
            ])
        } catch {
            print("❌ Failed to save workout rating: \(error)")
        }
    }
    
    private func createTodayPlanDay() -> WeeklyPlanDay {
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayName = dayFormatter.string(from: today)
        
        return WeeklyPlanDay(
            day: dayName,
            date: startOfDay,
            workouts: [],
            status: .suggested
        )
    }
    
    var body: some View {
        ZStack {
            // Main content
            TabView(selection: $selectedTab) {
                // First tab - Today/Dashboard
                DashboardView()
                    .tag(0)
                
                // Calendar tab - lazy load
                if selectedTab == 1 {
                    CalendarView()
                        .tag(1)
                } else {
                    Color.clear.tag(1)
                }
                
                // Placeholder for Log tab (center button)
                Color.clear
                    .tag(2)
                
                // Explore tab - lazy load
                if selectedTab == 3 {
                    ExploreView()
                        .tag(3)
                } else {
                    Color.clear.tag(3)
                }
                
                // Profile tab - lazy load
                if selectedTab == 4 {
                    ProfileView()
                        .tag(4)
                } else {
                    Color.clear.tag(4)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: selectedTab) { oldValue, newValue in
                // Track tab navigation analytics
                let tabNames = ["Today", "Calendar", "Log", "Explore", "Profile"]
                if newValue < tabNames.count {
                    TelemetryDeck.signal("Tab.Navigation", parameters: [
                        "tabName": tabNames[newValue],
                        "fromTab": oldValue < tabNames.count ? tabNames[oldValue] : "Unknown"
                    ])
                }
            }
            
            // Custom tab bar overlay
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, showingFAB: $showingFAB)
            }
            
            // FAB overlay
            if showingFAB {
                FABOverlay(showingFAB: $showingFAB, onSymptomLog: {
                    showingSymptomLog = true
                }, onPeriodLog: {
                    showingEditPeriodDates = true
                }, onWorkoutLog: {
                    showingWorkoutPicker = true
                }, onReflection: {
                    showingFitnessReflections = true
                })
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showingFitnessPersonalization) {
            FitnessPersonalizationView(onComplete: {
                showingFitnessPersonalization = false
            })
        }
        .sheet(isPresented: $showingNutritionPersonalization) {
            NutritionPersonalizationView(onComplete: {
                showingNutritionPersonalization = false
            })
        }
        .fullScreenCover(isPresented: $showingSymptomLog) {
            DetailedSymptomLogView(selectedDate: Date())
        }
        .sheet(isPresented: $showingEditPeriodDates) {
            EditPeriodDatesView()
        }
        .sheet(isPresented: $showingWorkoutPicker) {
            WorkoutPickerForWeeklyPlan(planDay: .constant(createTodayPlanDay()))
        }
        .sheet(isPresented: $showingFitnessReflections) {
            FitnessReflectionsView()
        }
        .overlay(
            // Snackbar overlay for habit completion
            showingHabitCompletionPopup ? 
            HabitCompletionSnackbar(message: habitCompletionMessage) {
                showingHabitCompletionPopup = false
            } : nil
        )
        .onReceive(NotificationCenter.default.publisher(for: .navigateToMainPage)) { notification in
            selectedTab = 0 // Navigate to Dashboard (main page)
            
            // Check if we should show workout rating popup
            if !UserDefaults.standard.bool(forKey: "muteWorkoutRatings"),
               let userInfo = notification.userInfo,
               let workoutTitle = userInfo["workoutTitle"] as? String,
               let instructor = userInfo["instructor"] as? String,
               let workoutId = userInfo["workoutId"] as? String,
               let workoutDate = userInfo["workoutDate"] as? Date {
                
                // Store workout info for rating popup
                completedWorkoutInfo = (title: workoutTitle, instructor: instructor, id: workoutId, date: workoutDate)
                
                // Show rating popup after a short delay to ensure navigation is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingWorkoutRating = true
                }
            }
        }
        .overlay(
            // Workout rating popup
            Group {
                if showingWorkoutRating, let workoutInfo = completedWorkoutInfo {
                    WorkoutRatingView(
                        workoutTitle: workoutInfo.title,
                        instructor: workoutInfo.instructor.isEmpty ? nil : workoutInfo.instructor,
                        onRatingSubmitted: { rating, notes in
                            saveWorkoutRating(
                                workoutId: workoutInfo.id,
                                workoutTitle: workoutInfo.title,
                                instructor: workoutInfo.instructor,
                                rating: rating,
                                dateCompleted: workoutInfo.date,
                                notes: notes
                            )
                            showingWorkoutRating = false
                            completedWorkoutInfo = nil
                            
                            // Show habit completion popup after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showHabitCompletionPopup()
                            }
                        },
                        onDismiss: {
                            showingWorkoutRating = false
                            completedWorkoutInfo = nil
                        }
                    )
                }
            }
        )
    }
}

// Personalization Overview Content
struct PersonalizationOverviewView: View {
    let onTrackCycle: () -> Void
    let onFitnessPlan: () -> Void
    let onNutrition: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "star")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                        
                        Text("Personalize Your Experience")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("Complete the steps below to get recommendations tailored to your unique cycle.")
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)
                
                // Personalization Cards
                VStack(spacing: 20) {
                    // Track Your Cycle Card
                    PersonalizationOverviewCard(
                        icon: "calendar",
                        title: "Track Your Cycle",
                        description: "Update your cycle information to get phase-specific recommendations",
                        action: onTrackCycle,
                        buttonText: "Get Started"
                    )
                    
                    // Create Your Fitness Plan Card
                    PersonalizationOverviewCard(
                        icon: "heart.fill",
                        title: "Create Your Fitness Plan",
                        description: "Set your fitness goals and get a customized training plan",
                        action: onFitnessPlan,
                        buttonText: "Get Started"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                
                Spacer()
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationBarHidden(true)
        }
    }
}

struct PersonalizationOverviewCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    let buttonText: String
    
    var body: some View {
        Button(action: {
            TelemetryDeck.signal("Button.Clicked", parameters: [
                "buttonType": "personalization_card",
                "cardTitle": title,
                "buttonText": buttonText
            ])
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.sofiaProHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.sofiaProCaption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Action Button
                HStack(spacing: 4) {
                    Text(buttonText)
                        .font(.sofiaProCaption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(red: 0.1, green: 0.12, blue: 0.18))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Notification extension to trigger onboarding
extension Notification.Name {
    static let showOnboarding = Notification.Name("showOnboarding")
    static let navigateToMainPage = Notification.Name("navigateToMainPage")
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showingFAB: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Today tab
            TabBarButton(
                icon: "sun.max.fill",
                title: "Today",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            // Calendar tab
            TabBarButton(
                icon: "calendar",
                title: "Calendar",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            // Center FAB button
            FABButton(showingFAB: $showingFAB)
            
            // Explore tab
            TabBarButton(
                icon: "square.grid.2x2",
                title: "Explore",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
            
            // Profile tab
            ProfileTabButton(
                isSelected: selectedTab == 4,
                hasNotification: false,
                action: { selectedTab = 4 }
            )
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

struct FABButton: View {
    @Binding var showingFAB: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                TelemetryDeck.signal("Button.Clicked", parameters: [
                    "buttonType": "fab_toggle",
                    "action": showingFAB ? "close" : "open"
                ])
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingFAB.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(showingFAB ? Color.white : Color.gray.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .shadow(radius: showingFAB ? 8 : 4)
                    
                    Image(systemName: showingFAB ? "xmark" : "plus")
                        .font(.sofiaProTitle2)
                        .fontWeight(.bold)
                        .foregroundColor(showingFAB ? .black : .gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Log")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .offset(y: -8)
    }
}

struct FABOverlay: View {
    @Binding var showingFAB: Bool
    @State private var selectedOption: FABOption?
    let onSymptomLog: () -> Void
    let onPeriodLog: () -> Void
    let onWorkoutLog: () -> Void
    let onReflection: () -> Void
    
    enum FABOption: CaseIterable {
        case period, workout, symptom, reflection
        
        var icon: String {
            switch self {
            case .period: return "drop.fill"
            case .workout: return "dumbbell.fill"
            case .symptom: return "thermometer"
            case .reflection: return "pencil"
            }
        }
        
        var title: String {
            switch self {
            case .period: return "Period"
            case .workout: return "Workout"
            case .symptom: return "Symptom"
            case .reflection: return "Reflection"
            }
        }
        
        var color: Color {
            switch self {
            case .period: return .red
            case .workout: return .blue
            case .symptom: return .orange
            case .reflection: return .purple
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Darker background for better text readability
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFAB = false
                    }
                }
            
            VStack {
                Spacer()
                
                // Arc-shaped line of FAB buttons
                HStack(spacing: 20) {
                    ForEach(Array(FABOption.allCases.enumerated()), id: \.element) { index, option in
                        FABOptionButton(option: option) {
                            selectedOption = option
                            print("🔵 Button tapped: \(option.title)")
                            
                            // Track FAB option selection
                            TelemetryDeck.signal("Button.Clicked", parameters: [
                                "buttonType": "fab_option",
                                "option": option.title.lowercased(),
                                "icon": option.icon
                            ])
                            
                            if option == .symptom {
                                print("🟠 SYMPTOM BUTTON TAPPED!")
                                onSymptomLog()
                                showingFAB = false
                            } else if option == .reflection {
                                print("🟣 REFLECTION BUTTON TAPPED!")
                                onReflection()
                                showingFAB = false
                            } else if option == .period {
                                print("🔴 PERIOD BUTTON TAPPED!")
                                onPeriodLog()
                                showingFAB = false
                            } else if option == .workout {
                                print("🔵 WORKOUT BUTTON TAPPED!")
                                onWorkoutLog()
                                showingFAB = false
                            } else {
                                print("⚪ Other button tapped: \(option.title)")
                                showingFAB = false
                            }
                        }
                        .offset(y: getArcOffset(for: index))
                    }
                }
                .offset(y: -100) // Position above the FAB
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .transition(.opacity)
    }
    
    private func getArcOffset(for index: Int) -> CGFloat {
        switch index {
        case 0: return 80  // Left button - much lower
        case 1: return 20  // Left-center button - lower
        case 2: return 20  // Right-center button - lower
        case 3: return 80  // Right button - much lower
        default: return 0
        }
    }
}

struct FABOptionButton: View {
    let option: FABOverlay.FABOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: option.icon)
                        .font(.sofiaProTitle2)
                        .foregroundColor(option.color)
                }
                
                Text(option.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.orange : Color.gray)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? Color.orange : Color.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CenterLogButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            TelemetryDeck.signal("Button.Clicked", parameters: [
                "buttonType": "center_log_button"
            ])
            action()
        }) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .offset(y: -8) // Move up to overlap content
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileTabButton: View {
    let isSelected: Bool
    let hasNotification: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            TelemetryDeck.signal("Button.Clicked", parameters: [
                "buttonType": "tab_button",
                "tabName": "profile",
                "hasNotification": hasNotification ? "true" : "false"
            ])
            action()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? Color.orange : Color.gray)
                    
                    // Notification indicator
                    if hasNotification {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }
                
                Text("Profile")
                    .font(.caption2)
                    .foregroundColor(isSelected ? Color.orange : Color.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProgressTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var showingAddProgress = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile = userProfile {
                        // Progress summary
                        ProgressSummaryCard(profile: profile)
                        
                        // Weekly overview
                        WeeklyProgressView()
                        
                        // Goals
                        GoalsView()
                        
                        // Recent entries
                        RecentProgressEntriesView()
                    } else {
                        Text("Please complete your profile setup")
                            .font(.sofiaProHeadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProgress = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddProgress) {
            AddProgressView()
        }
    }
}

struct ProgressSummaryCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Phase")
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                    
                    Text(profile.currentCyclePhase?.displayName ?? "Unknown Phase")
                        .font(.sofiaProTitle2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Image(systemName: profile.currentCyclePhase?.icon ?? "questionmark.circle")
                    .font(.sofiaProTitle)
                    .foregroundColor(profile.currentCyclePhase?.color ?? .gray)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                ProgressMetric(title: "Cycle Day", value: "\(profile.cycleDay ?? 0)")
                ProgressMetric(title: "Days Left", value: "\(profile.cycleLength ?? 0) - \(profile.cycleDay ?? 0)")
                ProgressMetric(title: "Phase Progress", value: "75%")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct ProgressMetric: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.sofiaProCaption)
                .foregroundColor(.secondary)
        }
    }
}

struct WeeklyProgressView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.sofiaProHeadline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 8) {
                        Text("\(day + 1)")
                            .font(.sofiaProCaption)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(day < 3 ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: day < 3 ? "checkmark" : "")
                                    .font(.sofiaProCaption)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            
            HStack {
                Text("3/7 workouts completed")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("42%")
                    .font(.sofiaProSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct GoalsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Goals")
                    .font(.sofiaProHeadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to goals
                }
                .font(.sofiaProCaption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                GoalProgressCard(
                    title: "Weekly Workouts",
                    current: 3,
                    target: 5,
                    icon: "dumbbell.fill"
                )
                
                GoalProgressCard(
                    title: "Weight Goal",
                    current: 65.5,
                    target: 63.0,
                    icon: "scalemass",
                    isWeight: true
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct GoalProgressCard: View {
    let title: String
    let current: Double
    let target: Double
    let icon: String
    var isWeight: Bool = false
    
    var progress: Double {
        return min(current / target, 1.0)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.sofiaProTitle2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.sofiaProSubheadline)
                    .fontWeight(.medium)
                
                if isWeight {
                    Text("\(current, specifier: "%.1f") kg / \(target, specifier: "%.1f") kg")
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(Int(current)) / \(Int(target))")
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.sofiaProSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                ProgressBar(progress: progress)
                    .frame(width: 60, height: 4)
            }
        }
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .cornerRadius(2)
    }
}

struct RecentProgressEntriesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Entries")
                    .font(.sofiaProHeadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all entries
                }
                .font(.sofiaProCaption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                ProgressEntryRow(
                    date: "Today",
                    title: "Morning Yoga",
                    duration: "30 min",
                    mood: .good
                )
                
                ProgressEntryRow(
                    date: "Yesterday",
                    title: "Strength Training",
                    duration: "45 min",
                    mood: .excellent
                )
                
                ProgressEntryRow(
                    date: "2 days ago",
                    title: "Walking",
                    duration: "60 min",
                    mood: .neutral
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct ProgressEntryRow: View {
    let date: String
    let title: String
    let duration: String
    let mood: Mood
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.sofiaProSubheadline)
                    .fontWeight(.medium)
                
                Text(date)
                    .font(.sofiaProCaption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(duration)
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.blue)
                
                Text(mood.emoji)
                    .font(.sofiaProCaption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var workoutTitle = ""
    @State private var duration = 30
    @State private var mood = Mood.good
    @State private var energy = EnergyLevel.medium
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Workout Details") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    TextField("Workout Title", text: $workoutTitle)
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Stepper("\(duration) min", value: $duration, in: 5...180, step: 5)
                    }
                }
                
                Section("How are you feeling?") {
                    Picker("Mood", selection: $mood) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            HStack {
                                Text(mood.emoji)
                                Text(mood.rawValue)
                            }
                            .tag(mood)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Energy Level", selection: $energy) {
                        ForEach(EnergyLevel.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProgress()
                    }
                    .disabled(workoutTitle.isEmpty)
                }
            }
        }
    }
    
    private func saveProgress() {
        let progress = Progress(date: selectedDate)
        progress.notes = notes.isEmpty ? nil : notes
        
        // This would save the workout details
        // For now, just dismiss
        dismiss()
    }
}

// CalendarView is now defined in CalendarView.swift

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var userRewards: [UserRewardsData]
    @State private var debugTapCount = 0
    @State private var showingDebugView = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var userRewardsData: UserRewardsData? {
        userRewards.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // User Stats Section (always show, even if empty)
                    UserStatsSection(userRewards: userRewardsData)
                    
                    // Charm Progress Section
                    CharmProgressSection(userProfile: userProfile)
                    
                    // Settings sections (always show)
                    ProfileSettingsView()
                    
                    // App info (always show)
                    AppInfoView()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onTapGesture(count: 3) {
                // Triple tap on the navigation title to show debug view
                showingDebugView = true
            }
        }
        .sheet(isPresented: $showingDebugView) {
            FitnessPlanDebugView()
        }
    }
    
}


struct ProfileSettingsView: View {
    @Query private var personalizationData: [PersonalizationData]
    @State private var showingCyclePersonalization = false
    @State private var showingFitnessPersonalization = false
    @State private var showingNutritionPersonalization = false
    @State private var showingPrivacyPolicy = false
    @State private var showingNotificationSettings = false
    @State private var showingRaceTrainingSetup = false
    @State private var showingRaceTrainingPlan = false
    @State private var showingAccountSettings = false
    @State private var showingCreateAccount = false

    
    var personalization: PersonalizationData? {
        personalizationData.first
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsSection(title: "Personalization") {
                PersonalizationSettingsRow(
                    icon: "calendar",
                    title: "Cycle Info",
                    isCompleted: personalization?.cycleCompleted == true,
                    action: { showingCyclePersonalization = true }
                )
                PersonalizationSettingsRow(
                    icon: "figure.run",
                    title: "Fitness Preferences",
                    isCompleted: personalization?.fitnessCompleted == true,
                    action: { showingFitnessPersonalization = true }
                )
                PersonalizationSettingsRow(
                    icon: "leaf",
                    title: "Nutrition Preferences",
                    isCompleted: personalization?.nutritionCompleted == true,
                    action: { showingNutritionPersonalization = true }
                )
                
                // Race Training (show if enabled, or show setup option if not)
                if personalization?.raceTrainingEnabled == true {
                    RaceTrainingSettingsRow(
                        personalization: personalization,
                        action: { 
                            showingRaceTrainingPlan = true
                        }
                    )
                } else {
                    PersonalizationSettingsRow(
                        icon: "figure.run",
                        title: "Set up Race Training",
                        isCompleted: false,
                        action: { 
                            showingRaceTrainingSetup = true
                        }
                    )
                }
            }
            
            SettingsSection(title: "Account") {
                if AuthenticationManager.shared.isAuthenticated {
                    SettingsRow(icon: "person.circle", title: "Account Settings", action: {
                        showingAccountSettings = true
                    })
                    SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", action: {
                        AuthenticationManager.shared.logout()
                    })
                } else {
                    SettingsRow(icon: "person.badge.plus", title: "Create Account", action: {
                        showingCreateAccount = true
                    })
                }
                SettingsRow(icon: "bell", title: "Notifications", action: {
                    showingNotificationSettings = true
                })
                SettingsRow(icon: "lock", title: "Privacy", action: {
                    showingPrivacyPolicy = true
                })
            }
            
            SettingsSection(title: "Support") {
                SettingsRow(icon: "envelope", title: "Contact Us", action: {
                    openEmailApp()
                })
            }
        }
        .sheet(isPresented: $showingCyclePersonalization) {
            CycleInfoOnePagerView()
        }
        .sheet(isPresented: $showingFitnessPersonalization) {
            FitnessPreferencesOnePagerView()
        }
        .sheet(isPresented: $showingNutritionPersonalization) {
            NutritionPreferencesOnePagerView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingRaceTrainingSetup) {
            RaceTrainingSetupView()
        }
        .sheet(isPresented: $showingRaceTrainingPlan) {
            RaceTrainingPlanView()
        }
        .sheet(isPresented: $showingAccountSettings) {
            UserProfileView()
        }
        .sheet(isPresented: $showingCreateAccount) {
            AuthenticationView(
                onAuthenticationComplete: {
                    showingCreateAccount = false
                },
                onSkipAuthentication: {
                    showingCreateAccount = false
                }
            )
        }
    }
    
    private func openEmailApp() {
        let email = "lizzy@syncnapp.com"
        let subject = "SyncN App Support"
        let body = "Hi Lizzy,\n\nI need help with the SyncN app.\n\n"
        
        let emailString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let emailURL = URL(string: emailString) {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
            } else {
                // Fallback: copy email to clipboard
                UIPasteboard.general.string = email
                // You could show an alert here to inform the user
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.sofiaProHeadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 1)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.sofiaProCaption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PersonalizationSettingsRow: View {
    let icon: String
    let title: String
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.sofiaProSubheadline)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UserStatsSection: View {
    let userRewards: UserRewardsData?
    @Query private var userProfiles: [UserProfile]
    @Query private var userRewardsData: [UserRewardsData]
    @State private var showingBraceletInfo = false
    @State private var showingHabitCompletionPopup = false
    @State private var habitCompletionMessage = ""
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var userRewardsDataFirst: UserRewardsData? {
        userRewardsData.first
    }
    
    var daysSinceAppDownload: Int {
        guard let userProfile = userProfile else { return 1 }
        
        let calendar = Calendar.current
        let today = Date()
        let appDownloadDate = userProfile.createdAt
        
        let daysDifference = calendar.dateComponents([.day], from: appDownloadDate, to: today).day ?? 0
        let days = daysDifference + 1 // +1 to include the download day
        
        return max(1, days) // Always show at least 1 bead
    }
    
    // Function to show habit completion popup with conditional messaging
    public func showHabitCompletionPopup() {
        let today = Date()
        let calendar = Calendar.current
        
        let completedFitness = userProfile?.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: today) && entry.status == .confirmed
        } == true ? 1 : 0
        
        let completedNutrition = userProfile?.dailyHabits.first { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }?.completedNutritionHabitsString?.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count ?? 0
        
        let totalCompleted = completedFitness + completedNutrition
        
        // Set conditional message based on number of habits completed
        switch totalCompleted {
        case 1:
            habitCompletionMessage = "A new bead has been added to your cycle bracelet!"
        case 2:
            habitCompletionMessage = "One more habit until a gold bead!"
        case 3...:
            habitCompletionMessage = "Upgrade to a gold bead!"
        default:
            habitCompletionMessage = "A new bead has been added to your cycle bracelet!"
        }
        
        showingHabitCompletionPopup = true
    }
    
    // Calculate today's bead based on completed recommendations
    private var todaysBead: String {
        let today = Date()
        let calendar = Calendar.current
        
        // Count completed fitness recommendations (1 fitness rec)
        let completedFitness = userProfile?.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: today) && entry.status == .confirmed
        } == true ? 1 : 0
        
        // Count completed nutrition recommendations (2 nutrition recs)
        let completedNutrition = userProfile?.dailyHabits.first { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }?.completedNutritionHabitsString?.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count ?? 0
        
        let totalCompleted = completedFitness + completedNutrition
        
        switch totalCompleted {
        case 0:
            return "Clear"
        case 1...2:
            return "Pearl"
        case 3...:
            return "Gold"
        default:
            return "Clear"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Bracelet")
                    .font(.sofiaProHeadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    TelemetryDeck.signal("Button.Clicked", parameters: [
                        "buttonType": "bracelet_info",
                        "location": "profile_bracelet_section"
                    ])
                    showingBraceletInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Bracelet string with beads in a straight line
            VStack(spacing: 0) {
                ZStack {
                    // Full-width string background
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(height: 3)
                    
                    // Beads positioned on top of the string
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { index in
                            if index < daysSinceAppDownload {
                                RealisticBeadView(color: beadColorForDay(index))
                            } else {
                                // Empty space for future days - invisible placeholder
                                Spacer()
                                    .frame(width: 32, height: 32)
                            }
                        }
                        
                        // Push beads to the left, string continues to the right
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.bottom, 8)
            
            // Today's Bead section
            VStack(alignment: .leading, spacing: 8) {
                Text("Day \(daysSinceAppDownload) Bead")
                    .font(.sofiaProSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(todaysBead)
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(beadColor)
            }
            .padding(.bottom, 8)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Current Streak",
                    value: "\(userRewards?.currentStreak ?? 0) days",
                    color: .orange
                )
                
                StatCard(
                    title: "Best Streak",
                    value: "\(userRewards?.longestStreak ?? 0) days",
                    color: .purple
                )
                
                StatCard(
                    title: "Classes Taken",
                    value: "\(userRewards?.workoutsCompleted ?? 0)",
                    color: .green
                )
                
                StatCard(
                    title: "Total Points",
                    value: "\(userRewards?.totalPoints ?? 0)",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(red: 0.1, green: 0.12, blue: 0.18))
        .cornerRadius(16)
        .sheet(isPresented: $showingBraceletInfo) {
            BraceletInfoView()
        }
        .onAppear {
            // Track bracelet view with current progress
            let today = Date()
            let calendar = Calendar.current
            
            let completedFitness = userProfile?.weeklyFitnessPlan.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: today) && entry.status == .confirmed
            } == true ? 1 : 0
            
            let completedNutrition = userProfile?.dailyHabits.first { entry in
                calendar.isDate(entry.date, inSameDayAs: today)
            }?.completedNutritionHabitsString?.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count ?? 0
            
            let totalCompleted = completedFitness + completedNutrition
            let beadType = todaysBead
            
            // Count beads for the week
            var weeklyBeadCount = 0
            var pearlBeadCount = 0
            var goldBeadCount = 0
            var clearBeadCount = 0
            
            for dayIndex in 0..<7 {
                let beadColor = beadColorForDay(dayIndex)
                if beadColor != .clear {
                    weeklyBeadCount += 1
                    if beadColor == .white {
                        pearlBeadCount += 1
                    } else if beadColor == .yellow {
                        goldBeadCount += 1
                    }
                } else {
                    clearBeadCount += 1
                }
            }
            
            TelemetryDeck.signal("Bracelet.Viewed", parameters: [
                "todaysBead": beadType,
                "todaysHabitsCompleted": "\(totalCompleted)",
                "weeklyBeadCount": "\(weeklyBeadCount)",
                "pearlBeads": "\(pearlBeadCount)",
                "goldBeads": "\(goldBeadCount)",
                "clearBeads": "\(clearBeadCount)",
                "currentStreak": "\(userRewardsDataFirst?.currentStreak ?? 0)",
                "longestStreak": "\(userRewardsDataFirst?.longestStreak ?? 0)",
                "totalWorkouts": "\(userRewardsDataFirst?.workoutsCompleted ?? 0)",
                "totalPoints": "\(userRewardsDataFirst?.totalPoints ?? 0)",
                "cyclePhase": userProfile?.calculateCyclePhaseForDate(Date()).rawValue ?? "unknown"
            ])
        }
        .overlay(
            // Snackbar overlay for habit completion
            showingHabitCompletionPopup ? 
            HabitCompletionSnackbar(message: habitCompletionMessage) {
                showingHabitCompletionPopup = false
            } : nil
        )
    }
    
    // Determine bead color for each day based on completed recommendations
    private func beadColorForDay(_ dayIndex: Int) -> Color {
        guard let userProfile = userProfile else { return .clear }
        
        let calendar = Calendar.current
        let today = Date()
        let appDownloadDate = userProfile.createdAt
        
        // Calculate the target date for this bead (dayIndex days since app download)
        let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: appDownloadDate) ?? appDownloadDate
        
        // Only show beads for today and past days, not future dates
        if targetDate > today {
            return .clear // No bead for future dates
        }
        
        // Count completed recommendations for this specific day
        let completedFitness = userProfile.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: targetDate) && entry.status == .confirmed
        } ? 1 : 0
        
        let completedNutrition = userProfile.dailyHabits.first { entry in
            calendar.isDate(entry.date, inSameDayAs: targetDate)
        }?.completedNutritionHabitsString?.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count ?? 0
        
        let totalCompleted = completedFitness + completedNutrition
        
        // Return appropriate bead color based on daily activity
        switch totalCompleted {
        case 0:
            return .clear // Clear bead for days with no activity
        case 1...2:
            return .white // Pearl bead for some activity
        case 3...:
            return .yellow // Gold bead for high activity
        default:
            return .clear // Clear bead for empty days
        }
    }
    
    
    private var beadColor: Color {
        switch todaysBead {
        case "Clear":
            return .gray
        case "Pearl":
            return .white
        case "Gold":
            return .yellow
        default:
            return .gray
        }
    }
}


struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.sofiaProTitle2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.sofiaProCaption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AppInfoView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("v1.0.0")
                .font(.sofiaProSubheadline)
                .foregroundColor(.secondary)
            
            Text("Fitness that flows with your cycle")
                .font(.sofiaProCaption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct EditProfileView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var cycleLength: Int?
    @State private var periodLength: Int?
    @State private var fitnessLevel: FitnessLevel?
    
    init(profile: UserProfile) {
        self.profile = profile
        self._name = State(initialValue: profile.name)
        self._cycleLength = State(initialValue: profile.cycleLength)
        self._periodLength = State(initialValue: profile.averagePeriodLength)
        self._fitnessLevel = State(initialValue: profile.fitnessLevel)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                }
                
                Section("Cycle Information") {
                    HStack {
                        Text("Cycle Length")
                        Spacer()
                        Stepper("\(cycleLength ?? 0) days", value: Binding(
                            get: { cycleLength ?? 0 },
                            set: { cycleLength = $0 }
                        ), in: 21...35)
                    }
                    
                    HStack {
                        Text("Period Length")
                        Spacer()
                        Stepper("\(periodLength ?? 0) days", value: Binding(
                            get: { periodLength ?? 0 },
                            set: { periodLength = $0 }
                        ), in: 3...10)
                    }
                }
                
                Section("Fitness Level") {
                    Picker("Level", selection: $fitnessLevel) {
                        Text("Not set").tag(nil as FitnessLevel?)
                        ForEach(FitnessLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level as FitnessLevel?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        profile.name = name
        profile.cycleLength = cycleLength
        profile.averagePeriodLength = periodLength
        profile.fitnessLevel = fitnessLevel
        profile.updatedAt = Date()
        
        dismiss()
    }
}

struct FitnessReflectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var workoutRatings: [WorkoutRating]
    @State private var selectedDate = Date()
    @State private var editingRating: WorkoutRating?
    
    private var todaysRatings: [WorkoutRating] {
        let calendar = Calendar.current
        return workoutRatings.filter { rating in
            calendar.isDate(rating.dateCompleted, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                    
                    Spacer()
                    
                    Text("Fitness Reflections")
                        .font(.custom("Sofia Pro", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Date picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Content
                if todaysRatings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No reflections yet")
                            .font(.custom("Sofia Pro", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("Complete a workout to see your reflections here")
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(todaysRatings, id: \.id) { rating in
                                WorkoutReflectionCard(rating: rating) {
                                    editingRating = rating
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .sheet(item: $editingRating) { rating in
            EditWorkoutReflectionView(rating: rating)
        }
    }
}

struct WorkoutReflectionCard: View {
    let rating: WorkoutRating
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rating.workoutTitle)
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let instructor = rating.instructor, instructor != "You" {
                        Text("by \(instructor)")
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }
            
            // Star rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating.rating ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(star <= rating.rating ? .yellow : .gray.opacity(0.3))
                }
                
                Spacer()
                
                Text(rating.cyclePhase.rawValue.capitalized)
                    .font(.custom("Sofia Pro", size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Notes
            if let notes = rating.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.custom("Sofia Pro", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.custom("Sofia Pro", size: 14))
                        .foregroundColor(.primary)
                        .lineSpacing(2)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct EditWorkoutReflectionView: View {
    let rating: WorkoutRating
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedRating: Int
    @State private var notes: String
    
    init(rating: WorkoutRating) {
        self.rating = rating
        self._selectedRating = State(initialValue: rating.rating)
        self._notes = State(initialValue: rating.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Edit Reflection")
                        .font(.custom("Sofia Pro", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(rating.workoutTitle)
                        .font(.custom("Sofia Pro", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Star rating
                VStack(spacing: 12) {
                    Text("Rating")
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                selectedRating = star
                            }) {
                                ZStack {
                                    Image(systemName: "star.fill")
                                        .font(.title)
                                        .foregroundColor(selectedRating >= star ? Color.yellow : Color.gray.opacity(0.3))
                                    
                                    Text("\(star)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            .scaleEffect(selectedRating >= star ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: selectedRating)
                        }
                    }
                }
                
                // Notes section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Add any notes about this workout...", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                // Save button
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .navigationBarHidden(true)
        }
    }
    
    private func saveChanges() {
        rating.rating = selectedRating
        rating.notes = notes.isEmpty ? nil : notes
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving workout rating: \(error)")
        }
    }
}
struct RealisticBeadView: View {
    let color: Color
    
    var body: some View {
        if color == Color.red.opacity(0.0) {
            // Show nothing for future dates - just maintain spacing
            Color.clear
                .frame(width: 32, height: 32)
        } else if color == .clear {
            // Show cylindrical clear bead for empty days (0 habits completed)
            ZStack {
                // Main cylindrical body
                RoundedRectangle(cornerRadius: 3)
                    .fill(clearBeadGradient)
                    .frame(width: 32, height: 12)
                
                // Highlight for solid rectangular appearance
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 12)
                
                // Rim for definition
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    .frame(width: 32, height: 12)
            }
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 2)
        } else {
            ZStack {
                // Main bead body with realistic gradient
                Circle()
                    .fill(beadGradient)
                    .frame(width: 32, height: 32)
                
                // Secondary highlight for more depth
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.clear
                            ]),
                            center: UnitPoint(x: 0.2, y: 0.2),
                            startRadius: 1,
                            endRadius: 8
                        )
                    )
                    .frame(width: 32, height: 32)
                
                // Main highlight for metallic shine
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            center: UnitPoint(x: 0.25, y: 0.25),
                            startRadius: 1,
                            endRadius: 6
                        )
                    )
                    .frame(width: 32, height: 32)
                
                // Inner rim for depth
                Circle()
                    .stroke(rimColor, lineWidth: 1)
                    .frame(width: 32, height: 32)
                
                // Outer rim for more definition
                Circle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    .frame(width: 32, height: 32)
            }
            .shadow(color: shadowColor, radius: 3, x: 2, y: 2)
        }
    }
    
    private var clearBeadGradient: LinearGradient {
        // Clear bead - solid rectangular appearance like reference image
        return LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.95, green: 0.95, blue: 0.95),   // Light gray/white
                Color(red: 0.85, green: 0.85, blue: 0.85),   // Medium light gray
                Color(red: 0.75, green: 0.75, blue: 0.75),   // Medium gray
                Color(red: 0.65, green: 0.65, blue: 0.65)    // Darker gray
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var beadGradient: RadialGradient {
        // Use the existing color logic but enhance it with gradients
        if color == .yellow {
            // Gold bead - more realistic metallic look
            return RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.3),  // Bright gold
                    Color(red: 0.9, green: 0.7, blue: 0.1),  // Medium gold
                    Color(red: 0.7, green: 0.5, blue: 0.0),  // Dark gold
                    Color(red: 0.5, green: 0.3, blue: 0.0)   // Deep shadow
                ]),
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadius: 1,
                endRadius: 16
            )
        } else if color == .white {
            // Pearl bead - realistic pearl/white look
            return RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 1.0, blue: 1.0),   // Pure white
                    Color(red: 0.95, green: 0.95, blue: 0.95), // Light pearl
                    Color(red: 0.85, green: 0.85, blue: 0.85), // Medium pearl
                    Color(red: 0.7, green: 0.7, blue: 0.7)    // Pearl shadow
                ]),
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadius: 1,
                endRadius: 16
            )
        } else {
            // Clear bead (gray) - more realistic glass/crystal look
            return RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.9, green: 0.9, blue: 0.9),   // Light gray
                    Color(red: 0.7, green: 0.7, blue: 0.7),   // Medium gray
                    Color(red: 0.5, green: 0.5, blue: 0.5),   // Dark gray
                    Color(red: 0.3, green: 0.3, blue: 0.3)    // Deep shadow
                ]),
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadius: 1,
                endRadius: 16
            )
        }
    }
    
    private var rimColor: Color {
        if color == .yellow {
            return Color(red: 0.6, green: 0.4, blue: 0.0)
        } else if color == .white {
            return Color.gray.opacity(0.6)
        } else {
            return Color.gray.opacity(0.7)
        }
    }
    
    private var shadowColor: Color {
        if color == .yellow {
            return Color.black.opacity(0.4)
        } else if color == .white {
            return Color.black.opacity(0.2)
        } else {
            return Color.black.opacity(0.3)
        }
    }
}

struct BraceletInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Build Your Cycle Bracelet")
                        .font(.sofiaProTitle2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Every day of your cycle, you earn a bead that reflects your habit progress:")
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Bead explanations
                VStack(spacing: 16) {
                    BeadExplanationRow(
                        beadType: "Clear bead",
                        description: "0 habits completed",
                        beadColor: .clear,
                        isCylindrical: true
                    )
                    
                    BeadExplanationRow(
                        beadType: "Pearl bead",
                        description: "1–2 habits completed",
                        beadColor: .white,
                        isCylindrical: false
                    )
                    
                    BeadExplanationRow(
                        beadType: "Gold bead",
                        description: "3+ habits completed",
                        beadColor: .yellow,
                        isCylindrical: false
                    )
                }
                .padding(.horizontal, 20)
                
                // Additional info
                VStack(spacing: 12) {
                    Text("By the end of your cycle, you'll see a bracelet that shows your full month of progress.")
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Stay consistent—after completing 3 full cycle bracelets, we'll send you a real bracelet in the mail as a gift 🎁.")
                        .font(.sofiaProSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Bracelet Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            TelemetryDeck.signal("Bracelet.InfoViewed", parameters: [
                "source": "profile_bracelet_section"
            ])
        }
    }
}

struct BeadExplanationRow: View {
    let beadType: String
    let description: String
    let beadColor: Color
    let isCylindrical: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Bead visual
            if beadColor == .clear {
                // Clear cylindrical bead
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.gray.opacity(0.05),
                                    Color.white.opacity(0.08),
                                    Color.gray.opacity(0.03)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        .frame(width: 40, height: 16)
                }
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 1, y: 1)
            } else {
                // Spherical bead
                ZStack {
                    Circle()
                        .fill(beadColor == .white ? pearlGradient : goldGradient)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                center: UnitPoint(x: 0.2, y: 0.2),
                                startRadius: 1,
                                endRadius: 8
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                center: UnitPoint(x: 0.25, y: 0.25),
                                startRadius: 1,
                                endRadius: 6
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .stroke(beadColor == .white ? Color.gray.opacity(0.6) : Color(red: 0.6, green: 0.4, blue: 0.0), lineWidth: 1)
                        .frame(width: 40, height: 40)
                }
                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 2)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(beadType)
                    .font(.sofiaProSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.sofiaProCaption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var pearlGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 1.0, blue: 1.0),
                Color(red: 0.95, green: 0.95, blue: 0.95),
                Color(red: 0.85, green: 0.85, blue: 0.85),
                Color(red: 0.7, green: 0.7, blue: 0.7)
            ]),
            center: UnitPoint(x: 0.3, y: 0.3),
            startRadius: 1,
            endRadius: 16
        )
    }
    
    private var goldGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.9, blue: 0.3),
                Color(red: 0.9, green: 0.7, blue: 0.1),
                Color(red: 0.7, green: 0.5, blue: 0.0),
                Color(red: 0.5, green: 0.3, blue: 0.0)
            ]),
            center: UnitPoint(x: 0.3, y: 0.3),
            startRadius: 1,
            endRadius: 16
        )
    }
}

struct HabitCompletionSnackbar: View {
    let message: String
    @State private var isVisible = false
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            if isVisible {
                HStack(spacing: 12) {
                    // Small bead icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.9, blue: 0.3),  // Bright gold
                                        Color(red: 0.9, green: 0.7, blue: 0.1),  // Medium gold
                                        Color(red: 0.7, green: 0.5, blue: 0.0)   // Dark gold
                                    ]),
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: 1,
                                    endRadius: 10
                                )
                            )
                            .frame(width: 30, height: 30)
                        
                        Circle()
                            .stroke(Color(red: 0.6, green: 0.4, blue: 0.0), lineWidth: 1.5)
                            .frame(width: 30, height: 30)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Great Job!")
                            .font(.sofiaProSubheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(message)
                            .font(.sofiaProCaption)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Account for tab bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .allowsHitTesting(false) // Don't block touches
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeIn(duration: 0.3)) {
                    isVisible = false
                }
                
                // Call dismiss callback after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}

struct CharmProgressSection: View {
    let userProfile: UserProfile?
    @Environment(\.modelContext) private var modelContext
    @Query private var charmProgress: [CharmProgress]
    @State private var showingCharmDetails = false
    @State private var showingCharmEarnedPopup = false
    @State private var showingNoteWriting = false
    @State private var showingEducationalVideos = false
    
    var userCharmProgress: CharmProgress? {
        charmProgress.first { $0.userId == userProfile?.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Earn Your Charm")
                    .font(.sofiaProHeadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showingCharmDetails = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Progress Overview
            VStack(spacing: 12) {
                // Charm Display
                HStack(spacing: 16) {
                    // Charm icon
                    ZStack {
                        Circle()
                            .fill(userCharmProgress?.hasEarnedCharm == true ? 
                                  AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)) :
                                  AnyShapeStyle(Color.white.opacity(0.2)))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: userCharmProgress?.hasEarnedCharm == true ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundColor(userCharmProgress?.hasEarnedCharm == true ? .white : .white.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userCharmProgress?.hasEarnedCharm == true ? "Charm Earned!" : "Complete 6 Tasks")
                            .font(.sofiaProTitle3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(userCharmProgress?.completedTasksCount ?? 0) of 6 completed")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * (Double(userCharmProgress?.completedTasksCount ?? 0) / 6.0), height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
                
                // Task List (show first 3, with expand option)
                VStack(spacing: 8) {
                    ForEach(Array(CharmTask.allCases.prefix(3).enumerated()), id: \.element) { index, task in
                        CharmTaskRowWithProgress(
                            task: task,
                            isCompleted: isTaskCompleted(task),
                            progressText: getTaskProgressText(task),
                            onTap: { handleTaskTap(task) }
                        )
                    }
                    
                    if CharmTask.allCases.count > 3 {
                        Button(action: {
                            showingCharmDetails = true
                        }) {
                            HStack {
                                Text("View All Tasks (\(CharmTask.allCases.count - 3) more)")
                                    .font(.sofiaProCaption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .onAppear {
            createCharmProgressIfNeeded()
        }
        .sheet(isPresented: $showingCharmDetails) {
            CharmDetailsView(charmProgress: userCharmProgress)
        }
        .sheet(isPresented: $showingNoteWriting) {
            NoteWritingView()
        }
        .sheet(isPresented: $showingEducationalVideos) {
            EducationalVideosView()
        }
        .alert("Charm Earned! 🌟", isPresented: $showingCharmEarnedPopup) {
            Button("Amazing!") { }
        } message: {
            Text("Congratulations! You've completed all 6 tasks and earned your special charm!")
        }
    }
    
    private func createCharmProgressIfNeeded() {
        guard let userProfile = userProfile,
              userCharmProgress == nil else { return }
        
        let newCharmProgress = CharmProgress(userId: userProfile.id)
        modelContext.insert(newCharmProgress)
        try? modelContext.save()
    }
    
    private func isTaskCompleted(_ task: CharmTask) -> Bool {
        guard let progress = userCharmProgress,
              let userProfile = userProfile else { return false }
        
        switch task {
        case .watchPhaseVideos:
            // Only complete when all 4 phase videos are watched
            let videoProgress = CharmManager.shared.getVideoProgress(for: userProfile, section: "phase", in: modelContext)
            return videoProgress.completed >= videoProgress.total
        case .watchHormoneVideos:
            // Only complete when all 6 hormone videos are watched
            let videoProgress = CharmManager.shared.getVideoProgress(for: userProfile, section: "hormone", in: modelContext)
            return videoProgress.completed >= videoProgress.total
        case .writeNote:
            return progress.hasWrittenNote
        case .reviewApp:
            return progress.hasReviewedApp
        case .acceptWeeklyPlan:
            return progress.hasAcceptedWeeklyPlan
        case .joinSubstack:
            return false // Force to show as incomplete for now
        }
    }
    
    private func getTaskProgressText(_ task: CharmTask) -> String {
        guard let userProfile = userProfile else { return "" }
        
        switch task {
        case .watchHormoneVideos:
            let progress = CharmManager.shared.getVideoProgress(for: userProfile, section: "hormone", in: modelContext)
            return "\(progress.completed)/\(progress.total) videos"
        case .watchPhaseVideos:
            let progress = CharmManager.shared.getVideoProgress(for: userProfile, section: "phase", in: modelContext)
            return "\(progress.completed)/\(progress.total) videos"
        default:
            return ""
        }
    }
    
    private func handleTaskTap(_ task: CharmTask) {
        guard let userProfile = userProfile else { return }
        
        // Navigate to appropriate screens for each task
        switch task {
        case .watchPhaseVideos:
            // Navigate to educational videos (shows both hormone and phase videos)
            showingEducationalVideos = true
        case .watchHormoneVideos:
            // Navigate to educational videos (shows both hormone and phase videos)
            showingEducationalVideos = true
        case .writeNote:
            // Open note writing interface
            showingNoteWriting = true
        case .reviewApp:
            // Open App Store review
            openAppStoreReview()
        case .acceptWeeklyPlan:
            // Navigate to fitness plan acceptance
            // This would typically be handled when user accepts a plan
            break
        case .joinSubstack:
            // Open Substack link
            openSubstack()
        }
    }
    
    private func openAppStoreReview() {
        guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id6736627297?action=write-review") else { return }
        
        if UIApplication.shared.canOpenURL(writeReviewURL) {
            UIApplication.shared.open(writeReviewURL)
            
            // Mark task as completed after opening review
            if let userProfile = userProfile {
                CharmManager.shared.markAppReviewed(for: userProfile, in: modelContext)
            }
        }
    }
    
    private func openSubstack() {
        guard let substackURL = URL(string: "https://syncn.substack.com/s/beta-testers") else { return }
        
        if UIApplication.shared.canOpenURL(substackURL) {
            UIApplication.shared.open(substackURL)
            
            // Mark task as completed after opening Substack
            if let userProfile = userProfile {
                CharmManager.shared.markSubstackJoined(for: userProfile, in: modelContext)
            }
        }
    }
}

struct CharmTaskRowWithProgress: View {
    let task: CharmTask
    let isCompleted: Bool
    let progressText: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: task.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isCompleted ? .green : Color(red: 0.2, green: 0.4, blue: 0.8))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.sofiaProSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text(task.description)
                            .font(.sofiaProCaption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if !progressText.isEmpty {
                            Spacer()
                            Text(progressText)
                                .font(.sofiaProCaption)
                                .fontWeight(.medium)
                                .foregroundColor(isCompleted ? .green : .white.opacity(0.9))
                        }
                    }
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(isCompleted ? 0.1 : 0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CharmTaskRow: View {
    let task: CharmTask
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: task.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isCompleted ? .green : .white.opacity(0.7))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.sofiaProSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(task.description)
                        .font(.sofiaProCaption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(isCompleted ? 0.1 : 0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CharmDetailsView: View {
    let charmProgress: CharmProgress?
    @Environment(\.dismiss) private var dismiss
    @State private var showingEducationalVideos = false
    @State private var showingNoteWriting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(charmProgress?.hasEarnedCharm == true ? 
                                      AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)) :
                                      AnyShapeStyle(Color.gray.opacity(0.3)))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: charmProgress?.hasEarnedCharm == true ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundColor(charmProgress?.hasEarnedCharm == true ? .white : .gray)
                        }
                        
                        Text(charmProgress?.hasEarnedCharm == true ? "Charm Earned!" : "Earn Your Charm")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Complete all 6 tasks to earn your special bracelet charm")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // All Tasks
                    VStack(spacing: 12) {
                        ForEach(CharmTask.allCases, id: \.self) { task in
                            CharmTaskDetailRow(
                                task: task,
                                isCompleted: isTaskCompleted(task),
                                onTap: { handleTaskTap(task) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Charm Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEducationalVideos) {
            EducationalVideosView()
        }
        .sheet(isPresented: $showingNoteWriting) {
            NoteWritingView()
        }
    }
    
    private func handleTaskTap(_ task: CharmTask) {
        switch task {
        case .watchPhaseVideos, .watchHormoneVideos:
            showingEducationalVideos = true
        case .writeNote:
            showingNoteWriting = true
        case .reviewApp:
            openAppStoreReview()
        case .acceptWeeklyPlan:
            // This is handled automatically when workouts are completed
            break
        case .joinSubstack:
            openSubstack()
        }
    }
    
    private func openAppStoreReview() {
        guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id6736627297?action=write-review") else { return }
        
        if UIApplication.shared.canOpenURL(writeReviewURL) {
            UIApplication.shared.open(writeReviewURL)
        }
    }
    
    private func openSubstack() {
        guard let substackURL = URL(string: "https://syncn.substack.com/s/beta-testers") else { return }
        
        if UIApplication.shared.canOpenURL(substackURL) {
            UIApplication.shared.open(substackURL)
        }
    }
    
    private func isTaskCompleted(_ task: CharmTask) -> Bool {
        guard let progress = charmProgress else { return false }
        
        switch task {
        case .watchPhaseVideos:
            return progress.hasWatchedPhaseVideos
        case .watchHormoneVideos:
            return progress.hasWatchedHormoneVideos
        case .writeNote:
            return progress.hasWrittenNote
        case .reviewApp:
            return progress.hasReviewedApp
        case .acceptWeeklyPlan:
            return progress.hasAcceptedWeeklyPlan
        case .joinSubstack:
            return progress.hasJoinedSubstack
        }
    }
}

struct CharmTaskDetailRow: View {
    let task: CharmTask
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCompleted ? AnyShapeStyle(Color.green) : AnyShapeStyle(Color.gray.opacity(0.2)))
                    .frame(width: 40, height: 40)
                
                Image(systemName: task.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isCompleted ? .white : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
        }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Race Training Settings Row
struct RaceTrainingSettingsRow: View {
    let personalization: PersonalizationData?
    let action: () -> Void
    
    private var raceDetailsText: String? {
        guard let raceType = personalization?.raceType,
              let raceDate = personalization?.raceDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(raceType) on \(formatter.string(from: raceDate))"
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Race training icon
                Image(systemName: "figure.run")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.purple)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Race Training")
                        .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    // Show race details if available
                    if let raceDetails = raceDetailsText {
                        Text(raceDetails)
                            .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Completion indicator
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserProfile.self, Workout.self, Progress.self, Exercise.self, WeeklyFitnessPlanEntry.self, DailyHabitEntry.self, WorkoutRating.self, CharmProgress.self, VideoProgress.self], inMemory: true)
}

