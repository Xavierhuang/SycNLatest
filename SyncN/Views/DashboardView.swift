import SwiftUI
import SwiftData
import UIKit
import TelemetryDeck

// MARK: - PersonalizationCard Component (moved to top for scope)
struct PersonalizationCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    let isEnabled: Bool
    let buttonText: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content row
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Get Started Button (right-aligned, below content)
            HStack {
                Spacer()
                
                Button(action: {
                    if isEnabled {
                        TelemetryDeck.signal("Button.Clicked", parameters: [
                            "buttonType": "personalization_card",
                            "cardTitle": title,
                            "buttonText": buttonText
                        ])
                        action()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(buttonText)
                            .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                            .fontWeight(.medium)
                            .foregroundColor(isEnabled ? Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.8) : Color.gray)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isEnabled ? Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.8) : Color.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(red: 0.1, green: 0.12, blue: 0.18))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Helper Functions
extension UserProfile {
    func calculateCyclePhaseForDate(_ date: Date) -> CyclePhase {
        // Get the phase from Swift-only cycle detection
        if CyclePredictionService.shared.hasBackendData() {
            if let swiftPhase = CyclePredictionService.shared.getPhaseForDate(date, userProfile: self) {
                return swiftPhase
            }
        }
        
        // Fallback to current cycle phase if no Swift data
        return currentCyclePhase ?? .follicular
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var personalizationData: [PersonalizationData]
    @State private var rewardsManager: RewardsManager?
    @State private var showingOnboarding = false
    @State private var showingFitnessPersonalization = false
    @State private var showingNutritionPersonalization = false
    @State private var showingHealthPersonalization = false
    @State private var showingNutritionHabits = false
    @State private var showingBraceletInfo = false
    @State private var selectedDate = Date()
    @State private var showingLogPeriodStart = false
    @State private var showingLogPeriodEnd = false
    @State private var selectedDateWorkout: WeeklyFitnessPlanEntry?
    @State private var showWeeklyPlanEditorFromDashboard = false
    @State private var showingLogCustomWorkout = false
    @State private var showingNotificationPrompt = false
    @State private var showingEducationalVideos = false

    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var userPersonalization: PersonalizationData? {
        // Check cache first
        if let cached = CacheManager.shared.getCachedPersonalizationData(),
           cached.userId == userProfile?.id {
            return cached
        }
        
        // Fallback to query
        let data = personalizationData.first { $0.userId == userProfile?.id }
        if let data = data {
            CacheManager.shared.setCachedPersonalizationData(data)
        }
        return data
    }
    
    
    private func ensurePersonalizationDataExists() {
        guard let userProfile = userProfile,
              userPersonalization == nil else { return }
        
        print("🔄 Creating missing PersonalizationData for user: \(userProfile.id)")
        let personalization = PersonalizationData(userId: userProfile.id)
        modelContext.insert(personalization)
        
        do {
            try modelContext.save()
            print("✅ Successfully created PersonalizationData")
        } catch {
            print("❌ Error creating PersonalizationData: \(error)")
        }
    }
    private func checkIfShouldShowNotificationPrompt() {
    // Check if user has seen the prompt before
    let hasSeenPrompt = UserDefaults.standard.bool(forKey: "hasSeenNotificationPrompt")
    
    // Check if user has fitness plan and hasn't seen prompt
    if !hasSeenPrompt && userPersonalization?.fitnessCompleted == true {
        // Check if user has workouts scheduled
        if let userProfile = userProfile, !userProfile.weeklyFitnessPlan.isEmpty {
            showingNotificationPrompt = true
        }
    }
}
private func enableNotifications() {
    LocalNotificationManager.shared.requestNotificationPermission()
    LocalNotificationManager.shared.checkAndScheduleDailyNotification(modelContext: modelContext)
    UserDefaults.standard.set(true, forKey: "hasSeenNotificationPrompt")
}

    var body: some View {
        NavigationView {
            ZStack {
                // Dark navy background (slightly lighter for better contrast)
                Color(red: 0.08, green: 0.12, blue: 0.18) // Darker navy background
                    .ignoresSafeArea()
                
                ScrollView {
                    mainContentView
                }
                
                // Points notification overlay
                if let rewardsManager = rewardsManager {
                    PointsNotificationOverlay(rewardsManager: rewardsManager)
                }
                
                // Notification prompt overlay
                if showingNotificationPrompt {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingNotificationPrompt = false
                        }
                    
                    VStack(spacing: 20) {
                        Text("Fabulous job setting your plan!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Let's help you stick to it with reminders. Set yourself up for success - we are here as your partner.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 12) {
                            Button("Enable Notifications") {
                                enableNotifications()
                                showingNotificationPrompt = false
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                            
                            Button("Not Now") {
                                UserDefaults.standard.set(true, forKey: "hasSeenNotificationPrompt")
                                showingNotificationPrompt = false
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 14))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingNotificationPrompt)
                }
            }
        }
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
        .sheet(isPresented: $showingHealthPersonalization) {
            HealthPersonalizationView()
        }
        .sheet(isPresented: $showingLogPeriodStart) {
            LogPeriodStartView()
        }
        .sheet(isPresented: $showingLogPeriodEnd) {
            LogPeriodEndView()
        }
        .sheet(isPresented: $showWeeklyPlanEditorFromDashboard) {
            WeeklyPlanEditorView(initialWeek: userProfile != nil ? CyclePredictionService.shared.getUserPlanStartDate(for: userProfile!) : nil)
                .interactiveDismissDisabled(false)
        }
        .sheet(item: $selectedDateWorkout) { workout in
            WeeklyWorkoutDetailView(workout: workout)
        }
        .sheet(isPresented: $showingLogCustomWorkout) {
            LogCustomWorkoutView()
        }
        .sheet(isPresented: $showingEducationalVideos) {
            EducationalVideosView()
        }
        .sheet(isPresented: $showingBraceletInfo) {
            BraceletInfoView()
                .onAppear {
                    TelemetryDeck.signal("Bracelet.InfoViewed", parameters: [
                        "source": "dashboard_learn_more"
                    ])
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .presentWeeklyPlanEditor)) { _ in
            showWeeklyPlanEditorFromDashboard = true
        }
        .onAppear {
            checkIfShouldShowNotificationPrompt()
            ensurePersonalizationDataExists()
            if rewardsManager == nil {
                DispatchQueue.main.async {
                    rewardsManager = RewardsManager(modelContext: modelContext)
                }
            }
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "Dashboard",
                "pageType": "main_feature"
            ])
        }
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        VStack(spacing: 24) {
            if let profile = userProfile {
                            // Daily Overview - Only show after cycle tracking is completed
                            if let personalization = userPersonalization, personalization.cycleCompleted == true {
                                DailyOverviewCard(profile: profile, selectedDate: selectedDate, showingLogPeriodStart: $showingLogPeriodStart, showingLogPeriodEnd: $showingLogPeriodEnd)
                                    .onAppear {
                                    }
                            } else {
                            }
                            
                            // Personalization Cards (only show if there are incomplete sections)
                            if let personalization = userPersonalization {
                                let hasIncompleteSections = (personalization.cycleCompleted != true) || (personalization.fitnessCompleted != true) || (personalization.nutritionCompleted != true)
                                
                                if hasIncompleteSections {
                                    // Header for personalization section
                                    HStack {
                                        // Show app logo if user hasn't started tracking cycle, otherwise show star
                                        if profile.lastPeriodStart == nil {
                                            Image("SyncN logo dark")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                        } else {
                                            Image(systemName: "star")
                                                .font(.title2)
                                                .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                                        }
                                        
                                        Text("Complete These Steps")
                                            .font(.sofiaProTitle2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                    
                                    VStack(spacing: 16) {
                                        // Track Your Cycle Card (always show if not completed)
                                        if personalization.cycleCompleted != true {
                                            PersonalizationCard(
                                                icon: "calendar",
                                                title: "Track Your Cycle",
                                                description: "Update your cycle information to get phase-specific recommendations",
                                                action: { showingOnboarding = true },
                                                isEnabled: true,
                                                buttonText: "Get Started"
                                            )
                                        }
                                        
                                        // Create Your Fitness Plan Card (show if not completed, but grayed out if cycle not completed)
                                        if personalization.fitnessCompleted != true {
                                            PersonalizationCard(
                                                icon: "heart.fill",
                                                title: "Create Your Fitness Plan",
                                                description: "Set your fitness goals and get a customized training plan",
                                                action: { showingFitnessPersonalization = true },
                                                isEnabled: personalization.cycleCompleted == true,
                                                buttonText: "Get Started"
                                            )
                                        }
                                        
                                        // Personalize Your Nutrition Card (show if not completed, but grayed out if previous sections not completed)
                                        if personalization.nutritionCompleted != true {
                                            PersonalizationCard(
                                                icon: "leaf.fill",
                                                title: "Personalize Your Nutrition",
                                                description: "Get nutrition habits tailored to your cycle and goals",
                                                action: { showingNutritionPersonalization = true },
                                                isEnabled: (personalization.cycleCompleted == true) && (personalization.fitnessCompleted == true),
                                                buttonText: "Get Started"
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Build Your Cycle Bracelet Card (only show if user hasn't seen the info yet)
                            if let personalization = userPersonalization, personalization.hasSeenBraceletInfo != true {
                                PersonalizationCard(
                                    icon: "circle.grid.cross",
                                    title: "Build Your Cycle Bracelet",
                                    description: "Track your daily progress",
                                    action: { 
                                        showingBraceletInfo = true
                                        userPersonalization?.hasSeenBraceletInfo = true
                                    },
                                    isEnabled: personalization.cycleCompleted == true && personalization.fitnessCompleted == true && personalization.nutritionCompleted == true,
                                    buttonText: "Learn More"
                                )
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            
                            // Weekly Timeline - Only show after fitness plan is completed
                            if let personalization = userPersonalization, personalization.fitnessCompleted == true {
                                WeeklyTimelineView(profile: profile, selectedDate: $selectedDate)
                            }
                            
                            // Today's Movement - Only show after fitness plan is completed
                            if let personalization = userPersonalization, personalization.fitnessCompleted == true {
                                if let rewardsManager = rewardsManager {
                                    TodaysMovementView(
                                        selectedWorkoutForDetail: $selectedDateWorkout,
                                        selectedDate: selectedDate,
                                        rewardsManager: rewardsManager,
                                        onEditPlan: { showWeeklyPlanEditorFromDashboard = true }
                                    )
                                } else {
                                    TodaysMovementView(
                                        selectedWorkoutForDetail: $selectedDateWorkout,
                                        selectedDate: selectedDate,
                                        rewardsManager: RewardsManager(modelContext: modelContext),
                                        onEditPlan: { showWeeklyPlanEditorFromDashboard = true }
                                    )
                                }
                            }
                            
                            // Today's Nutrition - Only show after nutrition personalization is completed
                            if let personalization = userPersonalization, personalization.nutritionCompleted == true {
                                if let rewardsManager = rewardsManager {
                                    TodaysNutritionView(
                                        selectedDate: selectedDate,
                                        rewardsManager: rewardsManager,
                                        onNutritionHabitsTap: { showingNutritionHabits = true }
                                    )
                                } else {
                                    TodaysNutritionView(
                                        selectedDate: selectedDate,
                                        rewardsManager: RewardsManager(modelContext: modelContext),
                                        onNutritionHabitsTap: { showingNutritionHabits = true }
                                    )
                                }
                            }
                            
                            // Symptoms Tracking - Only show after cycle tracking is completed
                            if let personalization = userPersonalization, personalization.cycleCompleted == true {
                                // Check if user has added specific injuries or symptoms
                                let hasSpecificSymptoms = (personalization.pastInjuries != nil && !personalization.pastInjuries!.isEmpty) || 
                                                         (personalization.periodSymptomsString != nil && !personalization.periodSymptomsString!.isEmpty) ||
                                                         !personalization.currentInjuriesForSymptomTracking.isEmpty
                                
                                if hasSpecificSymptoms {
                                    // Show detailed symptoms tracking if user has specific symptoms
                                    if let rewardsManager = rewardsManager {
                                        SymptomsTrackingView(selectedDate: selectedDate, rewardsManager: rewardsManager)
                                    } else {
                                        SymptomsTrackingView(selectedDate: selectedDate, rewardsManager: RewardsManager(modelContext: modelContext))
                                    }
                                } else {
                                    // Show simple "Log a symptom" button if no specific symptoms
                                    SimpleSymptomLogButton(selectedDate: selectedDate)
                                }
                            }
                            
                            // Cycle Phase - Only show after cycle tracking is completed
                            if let personalization = userPersonalization, personalization.cycleCompleted == true {
                                PhaseDescriptionView(profile: profile, selectedDate: selectedDate)
                            }
                            
                            // Educational Videos Button - Only show after all onboarding is completed
                            if let personalization = userPersonalization, 
                               personalization.cycleCompleted == true && 
                               personalization.fitnessCompleted == true && 
                               personalization.nutritionCompleted == true && 
                               personalization.hasSeenBraceletInfo == true {
                                VStack(alignment: .leading, spacing: 16) {
                                Button(action: {
                                    TelemetryDeck.signal("Button.Clicked", parameters: [
                                        "buttonType": "educational_videos",
                                        "location": "dashboard"
                                    ])
                                    showingEducationalVideos = true
                                }) {
                                    HStack(spacing: 16) {
                                        // Play icon
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Educational Videos")
                                                .font(.sofiaProTitle3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            Text("Learn about hormones and cycle phases")
                                                .font(.sofiaProSubheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        Spacer()
                                        
                                        // Arrow icon
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .padding(20)
                                    .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 20)
                            }
                            
                        } else {
                            // Show personalization cards when no user profile exists
                            VStack(spacing: 24) {
                                // Header for new users
                                HStack {
                                    Image("SyncN logo dark")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                    
                                    Text("Complete These Steps")
                                        .font(.sofiaProTitle2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                
                                VStack(spacing: 8) {
                                    // Track Your Cycle Card
                                    PersonalizationCard(
                                        icon: "calendar",
                                        title: "Track Your Cycle",
                                        description: "Update your cycle information to get phase-specific recommendations",
                                        action: { showingOnboarding = true },
                                        isEnabled: true,
                                        buttonText: "Get Started"
                                    )
                                    
                                    // Create Your Fitness Plan Card (disabled until cycle is completed)
                                    PersonalizationCard(
                                        icon: "heart.fill",
                                        title: "Create Your Fitness Plan",
                                        description: "Set your fitness goals and get a customized training plan",
                                        action: { showingFitnessPersonalization = true },
                                        isEnabled: false,
                                        buttonText: "Get Started"
                                    )
                                    
                                    // Personalize Your Nutrition Card (disabled until previous sections are completed)
                                    PersonalizationCard(
                                        icon: "leaf.fill",
                                        title: "Personalize Your Nutrition",
                                        description: "Get nutrition habits tailored to your cycle and goals",
                                        action: { showingNutritionPersonalization = true },
                                        isEnabled: false,
                                        buttonText: "Get Started"
                                    )
                                    
                                    // Build Your Cycle Bracelet Card (only show if user hasn't seen the info yet)
                                    if userPersonalization?.hasSeenBraceletInfo != true {
                                        PersonalizationCard(
                                            icon: "circle.grid.cross",
                                            title: "Build Your Cycle Bracelet",
                                            description: "Track your daily progress",
                                            action: { 
                                                TelemetryDeck.signal("Button.Clicked", parameters: [
                                                    "buttonType": "personalization_card",
                                                    "cardTitle": "Build Your Cycle Bracelet",
                                                    "buttonText": "Learn More"
                                                ])
                                                showingBraceletInfo = true
                                                userPersonalization?.hasSeenBraceletInfo = true
                                            },
                                            isEnabled: false,
                                            buttonText: "Learn More"
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 80) // Extra bottom padding to account for tab bar
                }
            }

// MARK: - Points Notification Overlay
struct PointsNotificationOverlay: View {
    @ObservedObject var rewardsManager: RewardsManager
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        if rewardsManager.showingPointsNotification {
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.sofiaProSubheadline)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rewardsManager.pointsNotificationMessage)
                            .font(.sofiaProSubheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Completed activity")
                            .font(.sofiaProCaption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        rewardsManager.showingPointsNotification = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.sofiaProCaption)
                    }
                }
                .padding(16)
                .background(Color.orange)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.easeInOut(duration: 0.3), value: rewardsManager.showingPointsNotification)
        }
    }
}

struct DailyOverviewCard: View {
    let profile: UserProfile
    let selectedDate: Date
    @Binding var showingLogPeriodStart: Bool
    @Binding var showingLogPeriodEnd: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(dateTitle)
                    .font(.sofiaProLargeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .fill(Color(red: 0.25, green: 0.28, blue: 0.35)) // Lighter circle background
                        .frame(width: 32, height: 32)
                        .overlay(
                            // Today indicator - white border
                            Circle()
                                .stroke(calendar.isDateInToday(selectedDate) ? Color.white : Color.clear, lineWidth: 2)
                        )
                    
                    Image(cyclePhaseForDate.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                }
                
                Text(cyclePhaseText)
                    .font(.sofiaProTitle3)
                    .foregroundColor(.white)
                    .onAppear {
                    }
                
                Spacer()
            }
            
            Text(formattedDate)
                .font(.sofiaProSubheadline)
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 8) {
                Text(periodStatusText)
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(periodActionText) {
                    if periodActionText == "My Period Started" {
                        showingLogPeriodStart = true
                    } else {
                        showingLogPeriodEnd = true
                    }
                }
                .font(.sofiaProSubheadline)
                .foregroundColor(Color(red: 0.925, green: 0.275, blue: 0.600)) // #EC4899
                .underline()
            }
        }
    }
    
    private var dateTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: selectedDate)
        }
    }
    
    private var cyclePhaseForDate: CyclePhase {
        // Get the phase from Swift-only cycle detection
        if CyclePredictionService.shared.hasBackendData() {
            if let swiftPhase = CyclePredictionService.shared.getPhaseForDate(selectedDate, userProfile: profile) {
                // Debug logging for Swift phase detection
                if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                }
                return swiftPhase
            }
        }
        
        // Fallback to user profile current phase if no Swift data
        guard let phase = profile.currentCyclePhase else {
            return .follicular // Default fallback
        }
        
        // Debug logging for fallback
        if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
        }
        
        return phase
    }
    
    private var cyclePhaseText: String {
        // If we have Swift data, show the raw Swift phase name
        if CyclePredictionService.shared.hasBackendData() {
            if let swiftPhase = CyclePredictionService.shared.getPhaseForDate(selectedDate, userProfile: profile) {
                // Get the Swift phase name
                return swiftPhase.rawValue.lowercased()
            }
        }
        
        // Fallback to the mapped phase name
        return cyclePhaseForDate.rawValue.lowercased()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    private var periodStatusText: String {
        guard let lastPeriod = profile.lastPeriodStart else { 
            return "Period in \(daysUntilPeriod) days" 
        }
        
        let daysSincePeriod = calendar.dateComponents([.day], from: lastPeriod, to: selectedDate).day ?? 0
        let cycleDay = (daysSincePeriod % (profile.cycleLength ?? 0)) + 1
        
        if cycleDay <= (profile.averagePeriodLength ?? 0) {
            return "Day \(cycleDay) of period"
        } else {
            return "Period in \(daysUntilPeriod) days"
        }
    }
    
    private var periodActionText: String {
        guard let lastPeriod = profile.lastPeriodStart else { 
            return "My Period Started" 
        }
        
        let daysSincePeriod = calendar.dateComponents([.day], from: lastPeriod, to: selectedDate).day ?? 0
        let cycleDay = (daysSincePeriod % (profile.cycleLength ?? 0)) + 1
        
        if cycleDay <= (profile.averagePeriodLength ?? 0) {
            return "My Period Ended"
        } else {
            return "My Period Started"
        }
    }
    
    private var daysUntilPeriod: Int {
        guard let lastPeriod = profile.lastPeriodStart else { return 0 }
        let nextPeriod = calendar.date(byAdding: .day, value: (profile.cycleLength ?? 0), to: lastPeriod) ?? Date()
        let daysUntil = calendar.dateComponents([.day], from: selectedDate, to: nextPeriod).day ?? 0
        return max(0, daysUntil)
    }
}

struct WeeklyTimelineView: View {
    let profile: UserProfile
    @Binding var selectedDate: Date

    @State private var showingWeeklyPlanEditor = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Timeline with circles and day labels
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        // Day label above circle
                        Text(String(daysOfWeek[index].prefix(1)))
                            .font(.sofiaProCaption)
                            .fontWeight(.medium)
                            .foregroundColor(isToday(index) ? Color.green : .white.opacity(0.8))
                        
                        // Timeline circle
                        Button(action: {
                            selectedDate = dateForIndex(index)
                            print("Tapped day \(index) - Date: \(dateForIndex(index))")
                        }) {
                            ZStack {
                                let date = dateForIndex(index)
                                let phase = cyclePhaseForDate(date)
                                Circle()
                                    .fill(phase != nil ? colorForPhase(phase!) : Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        // Widening window indicator - dashed orange border
                                        Circle()
                                            .stroke(
                                                isInWideningWindow(date) ? Color.orange : Color.clear,
                                                style: StrokeStyle(lineWidth: 2.0, dash: [9.5, 4.25])
                                            )
                                            .frame(width: 32, height: 32)
                                    )
                                
                                // Icon inside circle
                                if let phase = phase {
                                    // Try to load custom image first, fallback to SF Symbol
                                    Group {
                                        if let uiImage = UIImage(named: phase.icon) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 12, height: 12)
                                                .onAppear {
                                                    print("🔍 ICON DEBUG: Successfully loaded custom image '\(phase.icon)' for phase \(phase.rawValue)")
                                                }
                                        } else {
                                            // Fallback to SF Symbol if custom image fails
                                            Image(systemName: phase.systemIcon)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                                .onAppear {
                                                    print("🔍 ICON DEBUG: Custom image '\(phase.icon)' failed to load, using SF Symbol '\(phase.systemIcon)' for phase \(phase.rawValue)")
                                                }
                                        }
                                    }
                                } else {
                                    // No phase detected - use generic circle
                                    Image(systemName: "circle")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .overlay(
                                // Selection indicator
                                Circle()
                                    .stroke(calendar.isDate(dateForIndex(index), inSameDayAs: selectedDate) ? Color.white : Color.clear, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Bottom indicator dot
                        if hasRestDayOnDay(index) {
                            // Rest day - no dot
                            Color.clear
                                .frame(width: 8, height: 8)
                        } else if hasEventOnDay(index) {
                            // Workout or meditation day - blue dot
                            Circle()
                                .fill(hasCompletedWorkoutOnDay(index) ? Color.green : Color.clear)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(hasCompletedWorkoutOnDay(index) ? Color.green : Color.blue, lineWidth: 2)
                                )
                        } else {
                            // No activity - no dot
                            Color.clear
                                .frame(width: 8, height: 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Connecting line (except for last item)
                    if index < 6 {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                            .offset(y: 4) // Moved down 20px total from original -16
                    }
                }
            }
            
            
            // Selected day details - now handled by main DashboardView
        }

        .sheet(isPresented: $showingWeeklyPlanEditor) {
            WeeklyPlanEditorView(initialWeek: CyclePredictionService.shared.getUserPlanStartDate(for: profile))
        }
    }
    
    // Phase color matching CalendarView
    private func colorForPhase(_ phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual:
            return Color(red: 0.957, green: 0.408, blue: 0.573) // Pink
        case .follicular:
            return Color(red: 0.976, green: 0.851, blue: 0.157) // Yellow
        case .ovulatory:
            return Color(red: 0.157, green: 0.851, blue: 0.851) // Teal
        case .luteal:
            return Color(red: 0.557, green: 0.671, blue: 0.557) // Sage
        case .menstrualMoon:
            return Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.8)
        case .follicularMoon:
            return Color(red: 0.976, green: 0.851, blue: 0.157).opacity(0.8)
        case .ovulatoryMoon:
            return Color(red: 0.157, green: 0.851, blue: 0.851).opacity(0.8)
        case .lutealMoon:
            return Color(red: 0.557, green: 0.671, blue: 0.557).opacity(0.8)
        }
    }
   
    private func isInWideningWindow(_ date: Date) -> Bool {
        // Show only for irregular cycles, consistent with CalendarView
        guard profile.hasIrregularCycles else { 
            print("🔍 TODAY TIMELINE: User does not have irregular cycles - cycleType: \(profile.cycleType?.rawValue ?? "nil"), wideningWindow: \(profile.personalizationData?.wideningWindow ?? false)")
            return false 
        }
        
        // Get the widening window days from the cycle prediction service
        let wideningWindowDays = CyclePredictionService.shared.getWideningWindowDays()
        
        // Check if this date is in the widening window
        let isInWindow = wideningWindowDays.contains { wideningDate in
            Calendar.current.isDate(date, inSameDayAs: wideningDate)
        }
        
        // Debug logging for today timeline
        if Calendar.current.component(.day, from: date) <= 5 {
            print("🔍 TODAY TIMELINE: Checking widening window for date \(date)")
            print("🔍 TODAY TIMELINE: User has irregular cycles: \(profile.hasIrregularCycles)")
            print("🔍 TODAY TIMELINE: Available widening window days: \(wideningWindowDays.count)")
            print("🔍 TODAY TIMELINE: Is in window: \(isInWindow)")
        }
        
        return isInWindow
    }
    
    private func isToday(_ index: Int) -> Bool {
        let today = calendar.component(.weekday, from: selectedDate) - 1
        return index == today
    }
    
    private func dateForIndex(_ index: Int) -> Date {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return calendar.date(byAdding: .day, value: index, to: startOfWeek) ?? selectedDate
    }
    
    private func iconForDay(_ index: Int) -> String {
        // Return the cycle phase icon for this day
        let date = dateForIndex(index)
        let phase = cyclePhaseForDate(date)
        
        // Debug logging for phase detection
        print("🔍 PHASE ICONS: Day \(index) (\(daysOfWeek[index])): Date=\(date), Phase=\(phase?.rawValue ?? "nil"), Icon=\(phase?.icon ?? "circle")")
        
        // Return custom icon with SF Symbol fallback
        if let phase = phase {
            return phase.icon
        } else {
            return "circle" // SF Symbol fallback
        }
    }
    
    private func cyclePhaseForDate(_ date: Date) -> CyclePhase? {
        // Return nil (no phase/color) for dates before the user's last period start
        let calendar = Calendar.current
        if let lastPeriodStart = profile.lastPeriodStart {
            if date < calendar.startOfDay(for: lastPeriodStart) {
                print("🔍 PHASE CALC: Date \(date) is before last period start \(lastPeriodStart), returning nil")
                return nil
            }
        }
        
        if let phase = CyclePredictionService.shared.getPhaseForDate(date, userProfile: profile) {
            return phase
        }
        
        let fallbackPhase = profile.currentCyclePhase ?? .follicular
        return fallbackPhase
    }
    
    private func hasEventOnDay(_ index: Int) -> Bool {
        // Check if there's any activity scheduled for this day in the weekly fitness plan
        let date = dateForIndex(index)
        
        return profile.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    private func hasWorkoutOnDay(_ index: Int) -> Bool {
        // Check if there's a workout (not meditation or rest day) scheduled for this day
        let date = dateForIndex(index)
        
        return profile.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date) && 
            entry.workoutType != .meditation && 
            entry.workoutTitle != "Rest Day"
        }
    }
    
    private func hasRestDayOnDay(_ index: Int) -> Bool {
        // Check if there's a rest day scheduled for this day
        let date = dateForIndex(index)
        
        return profile.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date) && entry.workoutTitle == "Rest Day"
        }
    }
    
    private func hasMeditationOnDay(_ index: Int) -> Bool {
        // Check if there's a meditation scheduled for this day
        let date = dateForIndex(index)
        
        return profile.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date) && entry.workoutType == .meditation
        }
    }
    
    private func hasCompletedWorkoutOnDay(_ index: Int) -> Bool {
        // Check if there's a completed workout for this day
        let date = dateForIndex(index)
        
        return profile.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date) && entry.status == .confirmed
        }
    }
}

struct TodaysRecommendationsView: View {
    let profile: UserProfile
    let selectedDate: Date
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(dateTitle) Recommendations")
                .font(.sofiaProHeadline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(getRecommendedWorkouts(for: cyclePhaseForDate), id: \.id) { workout in
                        WorkoutCard(workout: workout)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var dateTitle: String {
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
    
    private var cyclePhaseForDate: CyclePhase {
        // TODO: Get phase from backend API instead of local calculation
        return profile.currentCyclePhase ?? .follicular
    }
    
    private func getRecommendedWorkouts(for phase: CyclePhase) -> [Workout] {
        // Use the new fitness recommendation engine
        let recommendations = SwiftFitnessRecommendationEngine.shared.generateWeeklyFitnessPlan(for: profile, startDate: selectedDate, userPreferences: UserPreferences(from: profile.personalizationData ?? PersonalizationData(userId: UUID())))
        
        // Convert WeeklyFitnessPlanEntry to Workout format
        return recommendations.map { planEntry in
            Workout(
                title: planEntry.workoutTitle,
                description: planEntry.workoutDescription,
                duration: planEntry.duration,
                workoutType: planEntry.workoutType,
                cyclePhase: planEntry.cyclePhase,
                difficulty: planEntry.difficulty,
                instructor: planEntry.instructor
            )
        }
    }
    
    private func getSampleWorkouts() -> [Workout] {
        return [
            // ===== LIZZY'S WORKOUTS =====
            
            // Ovulatory Phase
            Workout(
                title: "Intervals Guided Cardio",
                description: "High-intensity interval training with guided coaching. Perfect for peak energy during ovulation phase.",
                duration: 30,
                workoutType: .cardio,
                cyclePhase: .ovulatory,
                difficulty: .advanced,
                instructor: "Lizzy",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Run%20Ovulation.%2012.10.m4a",
                isVideo: false
            ),
            Workout(
                title: "Circuit: Form Focus",
                description: "Circuit training with emphasis on proper form and technique. Great for building strength and endurance.",
                duration: 18,
                workoutType: .strength,
                cyclePhase: .ovulatory,
                difficulty: .intermediate,
                instructor: "Lizzy",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Circuit%20form%20focus.mov",
                isVideo: true
            ),
            Workout(
                title: "Fresh Start Guided Cardio",
                description: "Energizing cardio session to kickstart your follicular phase. Perfect for building momentum and energy.",
                duration: 30,
                workoutType: .cardio,
                cyclePhase: .follicular,
                difficulty: .intermediate,
                instructor: "Lizzy",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Follicular%20run%20-%2012_30_23,%209.13%20PM.m4a",
                isVideo: false
            ),
            Workout(
                title: "Endurance Guided Cardio",
                description: "Steady-state cardio focused on building endurance. Ideal for luteal phase when energy is moderate.",
                duration: 30,
                workoutType: .cardio,
                cyclePhase: .luteal,
                difficulty: .intermediate,
                instructor: "Lizzy",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Luteal%20Run%20-%2012_16_23,%203.25%20PM.m4a",
                isVideo: false
            ),
            Workout(
                title: "Reflection Guided Cardio",
                description: "Gentle, reflective cardio session perfect for menstrual phase. Low-impact movement with mindfulness.",
                duration: 20,
                workoutType: .cardio,
                cyclePhase: .menstrual,
                difficulty: .beginner,
                instructor: "Lizzy",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstrual%20run%20-%2012_30_23,%207.54%20PM.m4a",
                isVideo: false
            ),
            Workout(
                title: "Dance Cardio, Affirmations Blast",
                description: "High-energy dance cardio with positive affirmations. Perfect for boosting mood and energy.",
                duration: 20,
                workoutType: .dance,
                cyclePhase: .ovulatory,
                difficulty: .intermediate,
                instructor: "Lizzy",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//im%20Dance%20Cardio%20Affirmations%20Blast.mp4",
                isVideo: true,
                injuries: ["knee", "ankle"]
            ),
            Workout(
                title: "Dance Cardio - the short one, Affirmations Blast",
                description: "Quick dance cardio session with affirmations. Perfect for when you're short on time but need energy.",
                duration: 5,
                workoutType: .dance,
                cyclePhase: .ovulatory,
                difficulty: .intermediate,
                instructor: "Lizzy",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//im%20Dance%20Cardio%20Affirmations%20Blast%20the%20short%20one.mp4",
                isVideo: true,
                injuries: ["knee", "ankle"]
            ),
            
            // ===== CRYSTAL'S WORKOUTS =====
            
            // Follicular Phase
            Workout(
                title: "Follicular Meditation",
                description: "Guided meditation specifically designed for the follicular phase. Set intentions and build energy.",
                duration: 5,
                workoutType: .meditation,
                cyclePhase: .follicular,
                difficulty: .beginner,
                instructor: "Crystal",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Follicular%20Meditation%20(1).m4a",
                isVideo: false
            ),
            Workout(
                title: "Spring Into Life Yoga",
                description: "Dynamic yoga flow to harness the energy of the follicular phase. Build strength and flexibility.",
                duration: 45,
                workoutType: .yoga,
                cyclePhase: .follicular,
                difficulty: .intermediate,
                instructor: "Crystal",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//%20(1).Follicular%20Phase%20Sync%20N%20Official%20(1)",
                isVideo: true
            ),
            
            // Menstrual Phase
            Workout(
                title: "Reflection Yoga",
                description: "Gentle, reflective yoga practice perfect for menstrual phase. Honor your body's need for rest and reflection.",
                duration: 30,
                workoutType: .yoga,
                cyclePhase: .menstrual,
                difficulty: .beginner,
                instructor: "Crystal",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstruation%20Video%20SYNC%20N%20Official.mp4",
                isVideo: true
            ),
            Workout(
                title: "Menstration Meditation",
                description: "Guided meditation to support you during menstruation. Reduce stress and honor this phase of your cycle.",
                duration: 5,
                workoutType: .meditation,
                cyclePhase: .menstrual,
                difficulty: .beginner,
                instructor: "Crystal",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstruation%20Meditation.m4a",
                isVideo: false
            ),
            
            // Ovulatory Phase
            Workout(
                title: "Expansive Yoga",
                description: "Powerful yoga practice to harness peak energy during ovulation. Challenge yourself and expand your limits.",
                duration: 30,
                workoutType: .yoga,
                cyclePhase: .ovulatory,
                difficulty: .advanced,
                instructor: "Crystal",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Ovulation%20Sync%20N.mp4",
                isVideo: true
            ),
            Workout(
                title: "Ovulation Meditation",
                description: "Guided meditation for the ovulatory phase. Connect with your peak energy and creative power.",
                duration: 4,
                workoutType: .meditation,
                cyclePhase: .ovulatory,
                difficulty: .beginner,
                instructor: "Crystal",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Run%20Ovulation.%2012.10.m4a",
                isVideo: false
            ),
            
            // Luteal Phase
            Workout(
                title: "Luteal Meditation",
                description: "Gentle meditation to support emotional balance during the luteal phase. Find peace and stability.",
                duration: 5,
                workoutType: .meditation,
                cyclePhase: .luteal,
                difficulty: .beginner,
                instructor: "Crystal",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstruation%20Meditation.m4a",
                isVideo: false
            ),
            Workout(
                title: "Let Go Yoga",
                description: "Restorative yoga practice for the luteal phase. Release tension and prepare for the next cycle.",
                duration: 30,
                workoutType: .yoga,
                cyclePhase: .luteal,
                difficulty: .beginner,
                instructor: "Crystal",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Luteal%20Phase%20Sync%20N.mp4",
                isVideo: true
            ),
            
            // ===== BRI'S WORKOUTS =====
            
            // Luteal Phase
            Workout(
                title: "Anger Workout",
                description: "High-intensity workout to channel and release energy. Perfect for managing emotions during luteal phase.",
                duration: 15,
                workoutType: .strength,
                cyclePhase: .luteal,
                difficulty: .intermediate,
                instructor: "Bri",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Anger%20Workout.mp4",
                isVideo: true,
                injuries: ["wrist", "knee"]
            ),
            Workout(
                title: "Pilates",
                description: "Classic pilates workout focusing on core strength and body awareness. Suitable for any phase.",
                duration: 30,
                workoutType: .pilates,
                cyclePhase: .luteal,
                difficulty: .intermediate,
                instructor: "Bri",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Pilates.mp4",
                isVideo: true
            ),
            Workout(
                title: "Pilates: Core Focus",
                description: "Targeted pilates session emphasizing core strength and stability. Perfect for building foundational strength.",
                duration: 18,
                workoutType: .pilates,
                cyclePhase: .luteal,
                difficulty: .intermediate,
                instructor: "Bri",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Pilates%20core%20focus.mp4",
                isVideo: true
            ),
            
            
            // Any Phase
            Workout(
                title: "Strength",
                description: "Comprehensive strength training workout. Adapt intensity based on your current cycle phase.",
                duration: 21,
                workoutType: .strength,
                cyclePhase: .follicular,
                difficulty: .intermediate,
                instructor: "Bri",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Strength.mp4",
                isVideo: true
            )
        ]
    }
}

struct WorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: workout.workoutType.icon)
                    .font(.sofiaProTitle2)
                    .foregroundColor(workout.workoutType.color)
                
                Spacer()
                
                Text(workout.formattedDuration)
                    .font(.sofiaProCaption)
                    .foregroundColor(.secondary)
            }
            
            Text(workout.title)
                .font(.sofiaProHeadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(workout.workoutDescription)
                .font(.sofiaProCaption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Button("Start") {
                // Start workout action
            }
            .font(.sofiaProSubheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding(12)
        .frame(width: 180)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.sofiaProHeadline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(title: "Log Workout", icon: "plus.circle", color: .blue) {
                    // Log workout action
                }
                
                QuickActionButton(title: "Track Progress", icon: "chart.line.uptrend.xyaxis", color: .green) {
                    // Track progress action
                }
                
                QuickActionButton(title: "View Calendar", icon: "calendar", color: .purple) {
                    // View calendar action
                }
                
                QuickActionButton(title: "Settings", icon: "gear", color: .gray) {
                    // Settings action
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.15, green: 0.18, blue: 0.25)) // Lighter card background
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.sofiaProTitle2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.sofiaProSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(red: 0.15, green: 0.18, blue: 0.25)) // Lighter card background
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

struct SymptomsTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var symptomEntries: [DailySymptomEntry]
    @Query private var personalizationData: [PersonalizationData]
    @State private var showingDetailedSymptomLog = false
    
    let selectedDate: Date
    let rewardsManager: RewardsManager
    
    init(selectedDate: Date, rewardsManager: RewardsManager) {
        self.selectedDate = selectedDate
        self.rewardsManager = rewardsManager
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        _symptomEntries = Query(filter: #Predicate<DailySymptomEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        })
    }
    
    private var currentSymptomEntry: DailySymptomEntry? {
        symptomEntries.first
    }
    
    @Query private var userProfiles: [UserProfile]
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var personalization: PersonalizationData? {
        personalizationData.first
    }
    
    // Get personalized symptoms from nutrition personalization and current injuries
    private var personalizedSymptoms: [String] {
        var symptoms: [String] = []
        
        // Add period symptoms if available
        if let personalization = personalization,
           let periodSymptomsString = personalization.periodSymptomsString,
           !periodSymptomsString.isEmpty {
            let periodSymptoms = periodSymptomsString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            .filter { !$0.isEmpty }
            symptoms.append(contentsOf: periodSymptoms)
        }
        
        // Add current injuries with mild/severe severity
        if let personalization = personalization {
            let currentInjuries = personalization.currentInjuriesForSymptomTracking
            let injurySymptoms = currentInjuries.map { "\($0.bodyPart) injury" }
            symptoms.append(contentsOf: injurySymptoms)
        }
        
        return symptoms
    }
    

    
    // Dynamic symptom severity binding for personalized symptoms
    private func symptomSeverityBinding(for symptom: String) -> Binding<SymptomSeverity?> {
        Binding(
            get: {
                guard let entry = currentSymptomEntry,
                      let symptoms = entry.selectedPhysicalSymptoms else { 
                    // If no entry exists, return the onboarding severity for injury symptoms
                    if symptom.hasSuffix(" injury") {
                        return getOnboardingSeverityForInjury(symptom: symptom)
                    }
                    return nil 
                }
                
                // Find the symptom and its severity in the format "Symptom:Severity"
                for symptomEntry in symptoms {
                    let parts = symptomEntry.components(separatedBy: ":")
                    if parts.count == 2 && parts[0] == symptom {
                        return SymptomSeverity(rawValue: parts[1])
                    }
                }
                
                // If not found in saved data, return onboarding severity for injury symptoms
                if symptom.hasSuffix(" injury") {
                    return getOnboardingSeverityForInjury(symptom: symptom)
                }
                
                return nil
            },
            set: { newValue in
                if let entry = currentSymptomEntry {
                    updateSymptomSeverity(entry: entry, symptom: symptom, severity: newValue)
                } else {
                    let newEntry = DailySymptomEntry(date: selectedDate)
                    
                    // For injury symptoms, pre-populate with onboarding severity if no user selection yet
                    if symptom.hasSuffix(" injury") && newValue == nil {
                        let onboardingSeverity = getOnboardingSeverityForInjury(symptom: symptom)
                        updateSymptomSeverity(entry: newEntry, symptom: symptom, severity: onboardingSeverity)
                    } else {
                    updateSymptomSeverity(entry: newEntry, symptom: symptom, severity: newValue)
                    }
                    
                    modelContext.insert(newEntry)
                }
            }
        )
    }
    
    private func updateSymptomSeverity(entry: DailySymptomEntry, symptom: String, severity: SymptomSeverity?) {
        var symptoms = entry.selectedPhysicalSymptoms ?? []
        
        // Check if this symptom was already logged
        let wasAlreadyLogged = symptoms.contains { $0.hasPrefix("\(symptom):") }
        
        // Remove existing entry for this symptom
        symptoms.removeAll { $0.hasPrefix("\(symptom):") }
        
        // Add new entry if severity is not nil
        if let severity = severity {
            symptoms.append("\(symptom):\(severity.rawValue)")
        }
        
        entry.selectedPhysicalSymptoms = symptoms
        
        // Update current injuries if this is an injury symptom
        if symptom.hasSuffix(" injury") {
            updateCurrentInjuriesForEntry(entry: entry, symptom: symptom, severity: severity)
        }
        
        try? modelContext.save()
        
        // Track rewards if this is a new symptom being logged
        if !wasAlreadyLogged && severity != nil {
            DispatchQueue.main.async {
                // TODO: Implement symptom tracking in RewardsManager
                print("Symptom logged: \(symptom)")
            }
        }
    }
    
    private func updateCurrentInjuriesForEntry(entry: DailySymptomEntry, symptom: String, severity: SymptomSeverity?) {
        guard let personalization = personalization else { return }
        
        // Extract body part from symptom (e.g., "Shoulder injury" -> "Shoulder")
        let bodyPart = symptom.replacingOccurrences(of: " injury", with: "")
        
        // Find the corresponding injury entry
        let currentInjuries = personalization.currentInjuriesForSymptomTracking
        let matchingInjury = currentInjuries.first { $0.bodyPart == bodyPart }
        
        if let injury = matchingInjury {
            var currentInjuries = entry.currentInjuries
            
            // Remove existing entry for this body part
            currentInjuries.removeAll { $0.bodyPart == bodyPart }
            
            // Add updated entry if severity is not nil
            if let severity = severity {
                let updatedInjury = InjuryEntry(
                    bodyPart: injury.bodyPart,
                    status: injury.status,
                    severity: InjurySeverity(rawValue: severity.rawValue) ?? injury.severity
                )
                currentInjuries.append(updatedInjury)
            }
            
            entry.currentInjuries = currentInjuries
        }
    }
    
    private func getOnboardingSeverityForInjury(symptom: String) -> SymptomSeverity? {
        guard let personalization = personalization else { return nil }
        
        // Extract body part from symptom (e.g., "Ankle injury" -> "Ankle")
        let bodyPart = symptom.replacingOccurrences(of: " injury", with: "")
        
        // Find the corresponding injury entry from onboarding
        let currentInjuries = personalization.currentInjuriesForSymptomTracking
        let matchingInjury = currentInjuries.first { $0.bodyPart == bodyPart }
        
        // Convert InjurySeverity to SymptomSeverity
        if let injury = matchingInjury {
            switch injury.severity {
            case .none:
                return SymptomSeverity.none
            case .mild:
                return .mild
            case .severe:
                return .severe
            }
        }
        
        return nil
    }
    
    private func cyclePhaseForDate(_ date: Date) -> CyclePhase {
        // TODO: Get phase from backend API instead of local calculation
        return userProfile?.currentCyclePhase ?? .follicular
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                            Text("Track Your Symptoms")
                .font(.sofiaProTitle2)
                .fontWeight(.bold)
                .foregroundColor(cyclePhaseForDate(selectedDate).headerColor)
                
                Spacer()
                
                Button("Log More +") {
                    showingDetailedSymptomLog = true
                }
                .font(.sofiaProSubheadline)
                .foregroundColor(.blue)
            }
            
            // Personalized symptoms with severity selector
            if personalizedSymptoms.isEmpty {
                VStack(spacing: 12) {
                    Text("No symptoms selected")
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(personalizedSymptoms, id: \.self) { symptom in
                        SymptomRow(
                            symptom: symptom,
                            severity: symptomSeverityBinding(for: symptom)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.15, green: 0.18, blue: 0.25)) // Dark card background
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingDetailedSymptomLog) {
            DetailedSymptomLogView(selectedDate: selectedDate)
        }
    }
}



struct SymptomRow: View {
    let symptom: String
    @Binding var severity: SymptomSeverity?
    
    var body: some View {
        HStack {
            Text(symptom)
                .font(.sofiaProSubheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            // Enhanced severity selector
            HStack(spacing: 4) {
                ForEach(SymptomSeverity.allCases, id: \.self) { severityOption in
                    Button(action: {
                        if severity == severityOption {
                            severity = nil
                        } else {
                            severity = severityOption
                        }
                    }) {
                        Text(severityOption.rawValue)
                            .font(.sofiaProCaption)
                            .fontWeight(.medium)
                            .foregroundColor(severity == severityOption ? .white : .white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(severity == severityOption ? Color(red: 0.157, green: 0.851, blue: 0.851) : Color(red: 0.1, green: 0.12, blue: 0.18))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(severity == severityOption ? Color(red: 0.157, green: 0.851, blue: 0.851) : Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .frame(minWidth: 80)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddSymptomView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var symptomName = ""
    @State private var symptomDescription = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Symptom Details") {
                    TextField("Symptom name", text: $symptomName)
                    
                    TextField("Description (optional)", text: $symptomDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Common Symptoms") {
                    ForEach(commonSymptoms, id: \.self) { symptom in
                        Button(action: {
                            symptomName = symptom
                        }) {
                            HStack {
                                Text(symptom)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // Add symptom logic here
                            dismiss()
                    }
                    .disabled(symptomName.isEmpty)
                }
            }
        }
    }
    
    private var commonSymptoms: [String] {
        return [
            "Cramps",
            "Bloating",
            "Fatigue",
            "Mood Swings",
            "Breast Tenderness",
            "Acne",
            "Food Cravings",
            "Headaches",
            "Back Pain",
            "Nausea"
        ]
    }
}



// MARK: - Horizontal Card Component (image left, text right)
struct TodaysMovementSmallCard: View {
    let workout: WeeklyFitnessPlanEntry
    @Binding var selectedWorkoutForDetail: WeeklyFitnessPlanEntry?
    
    var body: some View {
        Button(action: {
            print("🎯 TodaysMovementSmallCard: Selected workout: \(workout.workoutTitle)")
            
            // Track workout engagement from dashboard
            TelemetryDeck.signal("Workout.Engaged", parameters: [
                "workoutTitle": workout.workoutTitle,
                "workoutType": workout.workoutType.rawValue,
                "duration": "\(workout.duration)",
                "cyclePhase": workout.cyclePhase.rawValue,
                "instructor": workout.instructor ?? "Unknown",
                "source": "dashboard_todays_movement"
            ])
            
            selectedWorkoutForDetail = workout
        }) {
            ZStack {
                HStack(spacing: 12) {
                    // Left side - phase-specific frame image (SMALL)
                    Image(workout.cyclePhase.frameImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                    
                    // Right side - workout details
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.workoutTitle)
                            .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(workout.instructor ?? "Unknown")
                            .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(workout.duration) min.")
                            .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(workout.workoutType.rawValue)
                            .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                // Completion check mark overlay - bottom right corner of entire card
                if workout.status == .completed || workout.status == .confirmed {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)
                                .background(Color.white.clipShape(Circle()))
                                .offset(x: -8, y: 7)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(red: 0.1, green: 0.12, blue: 0.18))
            .cornerRadius(12)
            .frame(width: 280) // Fixed width for consistent carousel sizing
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TodaysMovementView: View {
    @Query private var userProfiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedWorkoutForDetail: WeeklyFitnessPlanEntry?
    let selectedDate: Date
    let rewardsManager: RewardsManager
    let onEditPlan: () -> Void
    @State private var showingWorkoutLibrary = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var selectedDateWorkouts: [WeeklyFitnessPlanEntry] {
        guard let userProfile = userProfile else { 
            print("🔍 TodaysMovementView: No user profile found")
            return [] 
        }
        let calendar = Calendar.current
        
        
        let filteredWorkouts = userProfile.weeklyFitnessPlan.filter { entry in
            let isSameDay = calendar.isDate(entry.date, inSameDayAs: selectedDate)
            return isSameDay
        }
        
        return filteredWorkouts
    }
    
    var selectedDateHabit: DailyHabitEntry? {
        guard let userProfile = userProfile else { return nil }
        let calendar = Calendar.current
        
        return userProfile.dailyHabits.first { entry in
            calendar.isDate(entry.date, inSameDayAs: selectedDate)
        }
    }
    
    private func isWorkoutCompleted(_ workout: WeeklyFitnessPlanEntry) -> Bool {
        // Check the workout's status directly
        let isCompleted = workout.status == .confirmed
        print("🎯 Checking completion for '\(workout.workoutTitle)': status=\(workout.status), completed=\(isCompleted)")
        return isCompleted
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
        // TODO: Get phase from backend API instead of local calculation
        return userProfile?.currentCyclePhase ?? .follicular
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(dateTitle) Movement")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(cyclePhaseForDate(selectedDate).headerColor)
                
                Spacer()
                
                Button(action: {
                    onEditPlan()
                }) {
                    HStack(spacing: 4) {
                        Text("Edit plan")
                        Image(systemName: "pencil")
                            .font(.sofiaProSubheadline)
                    }
                }
                .font(.sofiaProSubheadline)
                .foregroundColor(.white)
            }
            
            if !selectedDateWorkouts.isEmpty {
                // Horizontal scrollable carousel for multiple workouts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedDateWorkouts, id: \.id) { workout in
                            TodaysMovementSmallCard(workout: workout, selectedWorkoutForDetail: $selectedWorkoutForDetail)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                // No workout scheduled - placeholder card
                VStack(alignment: .leading, spacing: 8) {
                    // Phase-specific workout image placeholder
                    Image(cyclePhaseForDate(selectedDate).frameImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 100)
                        .clipped()
                        .overlay(
                            // Add button overlay
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                ZStack {
                                                    Circle()
                                            .fill(Color.white.opacity(0.9))
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(8)
                            }
                        )
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No workout scheduled")
                            .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text("Add a workout")
                            .font(.custom("Sofia Pro", size: 10, relativeTo: .caption2))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Rest Day")
                            .font(.custom("Sofia Pro", size: 10, relativeTo: .caption2))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(cyclePhaseForDate(selectedDate).color.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                .frame(width: 160)
            }
            
            // More Options button at bottom right of Today's Movement section
            HStack {
                    Spacer()
                    Button(action: {
                    TelemetryDeck.signal("Button.Clicked", parameters: [
                        "buttonType": "more_options_workouts",
                        "location": "dashboard_todays_movement"
                    ])
                    showingWorkoutLibrary = true
                }) {
                    HStack(spacing: 4) {
                        Text("More Options")
                        Image(systemName: "chevron.right")
                            .font(.sofiaProSubheadline)
                    }
                }
                .font(.sofiaProSubheadline)
                .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.8))
            }
            .padding(.top, 2)
            .padding(.bottom, 1)
        }
        .padding(20)
        .background(Color(red: 0.15, green: 0.18, blue: 0.25)) // Lighter card background
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingWorkoutLibrary) {
            WorkoutLibraryView()
        }
    }
    

}





struct KnownSymptomsView: View {
    @State private var headacheSeverity: SymptomSeverity? = nil
    @State private var kneeInjurySeverity: SymptomSeverity? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Track Your Symptoms")
                .font(.sofiaProHeadline)
                    .fontWeight(.semibold)
                
            VStack(spacing: 8) {
                SymptomRow(symptom: "Headaches", severity: $headacheSeverity)
                SymptomRow(symptom: "Knee Injury", severity: $kneeInjurySeverity)
            }
        }
    }
}

struct DetailedSymptomLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var symptomEntries: [DailySymptomEntry]
    @Query private var personalizationData: [PersonalizationData]
    
    let selectedDate: Date
    
    @State private var notes = ""
    @State private var selectedBleed: String? = nil
    @State private var selectedMood: String? = nil
    @State private var selectedEnergy: String? = nil
    @State private var selectedPhysicalSymptoms: Set<String> = []
    @State private var selectedDischarge: String? = nil
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        _symptomEntries = Query(filter: #Predicate<DailySymptomEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        })
    }
    
    private var currentSymptomEntry: DailySymptomEntry? {
        symptomEntries.first
    }
    
    private func loadExistingData() {
        if let entry = currentSymptomEntry {
            notes = entry.notes ?? ""
            selectedBleed = entry.selectedBleed
            selectedMood = entry.selectedMood
            selectedEnergy = entry.selectedEnergy
            let physicalSymptomsArray = entry.selectedPhysicalSymptoms ?? []
            selectedPhysicalSymptoms = Set(physicalSymptomsArray)
            selectedDischarge = entry.selectedDischarge
        }
    }
    
    private func saveSymptomData() {
        if let existingEntry = currentSymptomEntry {
            // Update existing entry
            existingEntry.notes = notes.isEmpty ? nil : notes
            existingEntry.selectedBleed = selectedBleed
            existingEntry.selectedMood = selectedMood
            existingEntry.selectedEnergy = selectedEnergy
            existingEntry.selectedPhysicalSymptoms = selectedPhysicalSymptoms.isEmpty ? nil : Array(selectedPhysicalSymptoms)
            existingEntry.selectedDischarge = selectedDischarge
        } else {
            // Create new entry
            let newEntry = DailySymptomEntry(
                date: selectedDate,
                notes: notes.isEmpty ? nil : notes,
                selectedBleed: selectedBleed,
                selectedMood: selectedMood,
                selectedEnergy: selectedEnergy,
                selectedPhysicalSymptoms: selectedPhysicalSymptoms.isEmpty ? nil : Array(selectedPhysicalSymptoms),
                selectedDischarge: selectedDischarge
            )
            modelContext.insert(newEntry)
        }
        
        try? modelContext.save()
    }
    
    private let bleedOptions = ["Heavy", "Medium", "Light", "Spotting"]
    private let moodOptions = ["Calm", "Happy", "Anxious", "Irritable", "Sensitive", "Sad", "Motivated"]
    private let energyOptions = ["Low", "Medium", "High"]
    private let dischargeOptions = ["None", "Sticky/Creamy", "Egg White"]
    
    var personalization: PersonalizationData? {
        personalizationData.first
    }
    
    // Get personalized symptoms from nutrition personalization
    private var personalizedSymptoms: [String] {
        guard let personalization = personalization,
              let periodSymptomsString = personalization.periodSymptomsString,
              !periodSymptomsString.isEmpty else {
            // If no personalization data or no symptoms selected, return empty array
            return []
        }
        
        return periodSymptomsString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Notes section at the top
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                        
                        TextField("Add any additional notes...", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Bleed Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Bleed")
                            .font(.sofiaProHeadline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), spacing: 8) {
                            ForEach(bleedOptions, id: \.self) { option in
                                SymptomOptionButton(
                                    option: option,
                                    isSelected: selectedBleed == option
                                ) {
                                    if selectedBleed == option {
                                        selectedBleed = nil
                                    } else {
                                        selectedBleed = option
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Mood Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mood")
                            .font(.sofiaProHeadline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), spacing: 8) {
                            ForEach(moodOptions, id: \.self) { option in
                                SymptomOptionButton(
                                    option: option,
                                    isSelected: selectedMood == option
                                ) {
                                    if selectedMood == option {
                                        selectedMood = nil
                                    } else {
                                        selectedMood = option
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Energy Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Energy")
                            .font(.sofiaProHeadline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), spacing: 8) {
                            ForEach(energyOptions, id: \.self) { option in
                                SymptomOptionButton(
                                    option: option,
                                    isSelected: selectedEnergy == option
                                ) {
                                    if selectedEnergy == option {
                                        selectedEnergy = nil
                                    } else {
                                        selectedEnergy = option
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Physical Symptoms Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Physical Symptoms")
                            .font(.sofiaProHeadline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), spacing: 8) {
                            ForEach(personalizedSymptoms, id: \.self) { option in
                                SymptomOptionButton(
                                    option: option,
                                    isSelected: selectedPhysicalSymptoms.contains(option)
                                ) {
                                    if selectedPhysicalSymptoms.contains(option) {
                                        selectedPhysicalSymptoms.remove(option)
                                    } else {
                                        selectedPhysicalSymptoms.insert(option)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Vaginal Discharge Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Vaginal Discharge")
                            .font(.sofiaProHeadline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), spacing: 8) {
                            ForEach(dischargeOptions, id: \.self) { option in
                                SymptomOptionButton(
                                    option: option,
                                    isSelected: selectedDischarge == option
                                ) {
                                    if selectedDischarge == option {
                                        selectedDischarge = nil
                                    } else {
                                        selectedDischarge = option
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(16)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Log Symptom")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadExistingData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSymptomData()
                        dismiss()
                    }
                }
            }
        }
    }
}




struct SymptomOptionButton: View {
    let option: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.sofiaProCaption)
                        .foregroundColor(.purple)
                }
                
                Text(option)
                    .font(.sofiaProSubheadline)
                    .foregroundColor(isSelected ? .purple : .primary)
            }
            .padding(.horizontal, 8)
        .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.purple.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PhaseDescriptionView: View {
    let profile: UserProfile
    let selectedDate: Date
    @State private var showingPhaseDetail = false
    @State private var showingZoomedChart = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with phase name button
            HStack {
            Text("Your Cycle Phase")
                .font(.sofiaProTitle2)
                .fontWeight(.bold)
                .foregroundColor(cyclePhaseForDate.headerColor)
            
                Spacer()
                
                // Phase name button - styled like "See More"
                Button(action: {
                    showingPhaseDetail = true
                }) {
                    Text(cyclePhaseForDate.displayName)
                }
                .font(.sofiaProSubheadline)
                .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
            }
            
            // Hormone Chart - tappable to zoom
            HormoneChartView(currentPhase: cyclePhaseForDate, userProfile: profile)
                .onTapGesture {
                    showingZoomedChart = true
                }
        }
        .padding(20)
        .background(Color(red: 0.15, green: 0.18, blue: 0.25)) // Dark card background
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingPhaseDetail) {
            if let phaseInfo = getPhaseInfo(for: cyclePhaseForDate) {
                PhaseDetailView(phaseInfo: phaseInfo)
            }
        }
        .sheet(isPresented: $showingZoomedChart) {
            ZoomedHormoneChartView(currentPhase: cyclePhaseForDate, userProfile: profile)
        }
    }
    
    private var cyclePhaseForDate: CyclePhase {
        // Get the phase from Swift-only cycle detection (same logic as the main cyclePhaseForDate)
        if CyclePredictionService.shared.hasBackendData() {
            if let swiftPhase = CyclePredictionService.shared.getPhaseForDate(selectedDate, userProfile: profile) {
                // Debug logging for Swift phase detection
                if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                }
                return swiftPhase
            }
        }
        
        // Fallback to user profile current phase if no Swift data
        guard let phase = profile.currentCyclePhase else {
            return .follicular // Default fallback
        }
        
        // Debug logging for fallback
        if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
        }
        
        return phase
    }
    
    // Helper function to get PhaseInfo for the current phase
    private func getPhaseInfo(for phase: CyclePhase) -> PhaseInfo? {
        let phaseName: String
        switch phase {
        case .menstrual, .menstrualMoon:
            phaseName = "menstrual"
        case .follicular, .follicularMoon:
            phaseName = "follicular"
        case .ovulatory, .ovulatoryMoon:
            phaseName = "ovulation"
        case .luteal, .lutealMoon:
            phaseName = "luteal"
        }
        
        return PhaseInfoData.shared.getPhase(by: phaseName)
    }
}

struct ZoomedHormoneChartView: View {
    let currentPhase: CyclePhase
    let userProfile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Large hormone chart
                    HormoneChartView(currentPhase: currentPhase, userProfile: userProfile)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = value
                                }
                                .onEnded { value in
                                    // Limit zoom range
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        scale = max(0.5, min(value, 3.0))
                                    }
                                }
                        )
                        .frame(minHeight: 300)
                    
                    // Reset zoom button
                    if scale != 1.0 {
                        Button("Reset Zoom") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scale = 1.0
                            }
                        }
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.blue)
                        .padding()
                    }
                }
                .padding()
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationTitle("Hormone Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct HormoneChartView: View {
    let currentPhase: CyclePhase
    let userProfile: UserProfile?
    
    // Only show relevant phases based on user's cycle type
    private var relevantPhases: [CyclePhase] {
        guard let userProfile = userProfile,
              let personalizationData = userProfile.personalizationData else {
            // Default to traditional phases if no personalization data
            return [.menstrual, .follicular, .ovulatory, .luteal]
        }
        
        if personalizationData.useMoonCycle == true {
            // Moon cycle user - show moon phases
            return [.menstrualMoon, .follicularMoon, .ovulatoryMoon, .lutealMoon]
        } else {
            // Regular menstruating user - show traditional phases
            return [.menstrual, .follicular, .ovulatory, .luteal]
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Chart Container
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            .cornerRadius(12)
                
                // Chart content
                VStack(spacing: 8) {
                    // Phase tabs - only show relevant phases based on user type
                    HStack(spacing: 0) {
                        ForEach(relevantPhases, id: \.self) { phase in
                            PhaseTabView(
                                phase: phase,
                                isSelected: phase == currentPhase
                            )
                        }
                    }
                    .cornerRadius(8)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    
                    // Hormone lines chart
                    HormoneLinesChart(currentPhase: currentPhase)
                        .frame(height: 120)
                        .padding(.horizontal, 12)
                    
                    // Phase description
                    Text(phaseDescription(for: currentPhase))
                        .font(.sofiaProCaption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemBackground).opacity(0.8))
                        )
                        .padding(.horizontal, 12)
                    
                    // Legend
                    HormoneLegend()
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
            }
        }
    }
    
    private func phaseDescription(for phase: CyclePhase) -> String {
        switch phase {
        case .menstrual:
            return "Focus on gentle movement and recovery"
        case .follicular:
            return "Great time for high-intensity workouts"
        case .ovulatory:
            return "Peak energy and strength"
        case .luteal:
            return "Moderate intensity, focus on recovery"
        case .menstrualMoon:
            return "Focus on gentle movement and recovery (Moon-based)"
        case .follicularMoon:
            return "Great time for high-intensity workouts (Moon-based)"
        case .ovulatoryMoon:
            return "Peak energy and strength (Moon-based)"
        case .lutealMoon:
            return "Moderate intensity, focus on recovery (Moon-based)"
        }
    }
}

struct PhaseTabView: View {
    let phase: CyclePhase
    let isSelected: Bool
    
    var body: some View {
        Text(phase.displayName)
            .font(.sofiaProCaption)
            .fontWeight(isSelected ? .semibold : .medium)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.9)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct HormoneLinesChart: View {
    let currentPhase: CyclePhase
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Phase highlight overlay
                PhaseHighlightOverlay(currentPhase: currentPhase, size: geometry.size)
                
                // Hormone lines
                HormoneLines(size: geometry.size)
            }
        }
    }
}

struct PhaseHighlightOverlay: View {
    let currentPhase: CyclePhase
    let size: CGSize
    
    var body: some View {
        let phaseRange = phaseRange(for: currentPhase)
        let xPosition = size.width * phaseRange.start
        let width = size.width * (phaseRange.end - phaseRange.start)
        
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.15),
                        Color.blue.opacity(0.08),
                        Color.blue.opacity(0.15)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width)
            .position(x: xPosition + width/2, y: size.height/2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    .frame(width: width)
                    .position(x: xPosition + width/2, y: size.height/2)
            )
    }
    
    private func phaseRange(for phase: CyclePhase) -> (start: Double, end: Double) {
        switch phase {
        case .menstrual:
            return (0.0, 0.25)
        case .follicular:
            return (0.25, 0.5)
        case .ovulatory:
            return (0.5, 0.6)
        case .luteal:
            return (0.6, 1.0)
        case .menstrualMoon:
            return (0.0, 0.25)
        case .follicularMoon:
            return (0.25, 0.5)
        case .ovulatoryMoon:
            return (0.5, 0.6)
        case .lutealMoon:
            return (0.6, 1.0)
        }
    }
}

struct HormoneLines: View {
    let size: CGSize
    
    var body: some View {
        // Energy level (white line) - more flowing and elegant
        Path { path in
            path.move(to: CGPoint(x: 0, y: size.height * 0.75))
            path.addCurve(
                to: CGPoint(x: size.width * 0.25, y: size.height * 0.4),
                control1: CGPoint(x: size.width * 0.08, y: size.height * 0.6),
                control2: CGPoint(x: size.width * 0.15, y: size.height * 0.5)
            )
            path.addCurve(
                to: CGPoint(x: size.width * 0.5, y: size.height * 0.25),
                control1: CGPoint(x: size.width * 0.35, y: size.height * 0.3),
                control2: CGPoint(x: size.width * 0.42, y: size.height * 0.2)
            )
            path.addCurve(
                to: CGPoint(x: size.width * 0.75, y: size.height * 0.35),
                control1: CGPoint(x: size.width * 0.58, y: size.height * 0.3),
                control2: CGPoint(x: size.width * 0.65, y: size.height * 0.4)
            )
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.65),
                control1: CGPoint(x: size.width * 0.85, y: size.height * 0.3),
                control2: CGPoint(x: size.width * 0.92, y: size.height * 0.5)
            )
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
        .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
        
        // Estrogen (purple line) - more graceful curves
        Path { path in
            path.move(to: CGPoint(x: 0, y: size.height * 0.85))
            path.addCurve(
                to: CGPoint(x: size.width * 0.3, y: size.height * 0.3),
                control1: CGPoint(x: size.width * 0.1, y: size.height * 0.65),
                control2: CGPoint(x: size.width * 0.2, y: size.height * 0.45)
            )
            path.addCurve(
                to: CGPoint(x: size.width * 0.6, y: size.height * 0.2),
                control1: CGPoint(x: size.width * 0.4, y: size.height * 0.15),
                control2: CGPoint(x: size.width * 0.5, y: size.height * 0.1)
            )
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.7),
                control1: CGPoint(x: size.width * 0.7, y: size.height * 0.3),
                control2: CGPoint(x: size.width * 0.85, y: size.height * 0.55)
            )
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.purple]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
        
        // Progesterone (blue line) - smoother transitions
        Path { path in
            path.move(to: CGPoint(x: 0, y: size.height * 0.9))
            path.addCurve(
                to: CGPoint(x: size.width * 0.4, y: size.height * 0.85),
                control1: CGPoint(x: size.width * 0.15, y: size.height * 0.88),
                control2: CGPoint(x: size.width * 0.25, y: size.height * 0.87)
            )
            path.addCurve(
                to: CGPoint(x: size.width * 0.65, y: size.height * 0.25),
                control1: CGPoint(x: size.width * 0.5, y: size.height * 0.7),
                control2: CGPoint(x: size.width * 0.55, y: size.height * 0.4)
            )
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.5),
                control1: CGPoint(x: size.width * 0.75, y: size.height * 0.1),
                control2: CGPoint(x: size.width * 0.9, y: size.height * 0.3)
            )
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
        
        // Testosterone (orange line) - more subtle and elegant
        Path { path in
            path.move(to: CGPoint(x: 0, y: size.height * 0.8))
            path.addCurve(
                to: CGPoint(x: size.width * 0.3, y: size.height * 0.45),
                control1: CGPoint(x: size.width * 0.1, y: size.height * 0.65),
                control2: CGPoint(x: size.width * 0.2, y: size.height * 0.55)
            )
            path.addCurve(
                to: CGPoint(x: size.width * 0.7, y: size.height * 0.4),
                control1: CGPoint(x: size.width * 0.4, y: size.height * 0.35),
                control2: CGPoint(x: size.width * 0.55, y: size.height * 0.3)
            )
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.55),
                control1: CGPoint(x: size.width * 0.8, y: size.height * 0.5),
                control2: CGPoint(x: size.width * 0.9, y: size.height * 0.6)
            )
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.orange]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }
}

struct CurrentPositionIndicator: View {
    let currentPhase: CyclePhase
    let size: CGSize
    
    var body: some View {
        let xPosition = size.width * currentPhasePosition(for: currentPhase)
        let yPosition = size.height * 0.3 // Approximate position on energy line
        
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 16, height: 16)
                .position(x: xPosition, y: yPosition)
                .blur(radius: 2)
            
            // Main indicator
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.9)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 10)
                .position(x: xPosition, y: yPosition)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
            
            // Inner highlight
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 4, height: 4)
                .position(x: xPosition - 1, y: yPosition - 1)
        }
    }
    
    private func currentPhasePosition(for phase: CyclePhase) -> Double {
        switch phase {
        case .menstrual:
            return 0.125
        case .follicular:
            return 0.375
        case .ovulatory:
            return 0.55
        case .luteal:
            return 0.8
        case .menstrualMoon:
            return 0.125
        case .follicularMoon:
            return 0.375
        case .ovulatoryMoon:
            return 0.55
        case .lutealMoon:
            return 0.8
        }
    }
}

struct HormoneLegend: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                LegendItem(color: .white, label: "Energy level")
                LegendItem(color: .purple, label: "Estrogen")
            }
            
            HStack(spacing: 16) {
                LegendItem(color: .blue, label: "Progesterone")
                LegendItem(color: .orange, label: "Testosterone")
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            // Stylized triangle indicator
            ZStack {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.3), radius: 1, x: 0, y: 0)
                
                Image(systemName: "triangle.fill")
                    .font(.system(size: 4))
                    .foregroundColor(Color.white.opacity(0.8))
                    .offset(x: -0.3, y: -0.3)
            }
            
            Text(label)
                .font(.sofiaProCaption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

// WeeklyPlanLoader moved to separate file: Models/WeeklyPlanLoader.swift
// WeeklyPlanEditorView moved to separate file: Views/WeeklyPlanEditorView.swift

// All weekly plan editor components have been cleaned up.
// The file now contains only the core DashboardView and TodaysMovementView components.
