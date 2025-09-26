import SwiftUI
import SwiftData
import TelemetryDeck

// Environment key for scroll to today trigger
private struct ScrollToTodayTriggerKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var scrollToTodayTrigger: Bool {
        get { self[ScrollToTodayTriggerKey.self] }
        set { self[ScrollToTodayTriggerKey.self] = newValue }
    }
}

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var selectedDate = Date()
    @State private var visuallySelectedDate: Date? = nil // Only for visual indicator
    @State private var showingEditPeriodDates = false
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var showingYearPicker = false
    @State private var scrollToTodayTrigger = false
    @State private var isLoadingWideningWindow = false
    @State private var backendDataUpdated = false
    @State private var wideningWindowDataLoaded = false
    @State private var showingDateDetailSheet = false
    @State private var showingLegend = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    // Function to fetch cycle data from backend
    private func fetchWideningWindowData() {
        guard let userProfile = userProfile else { 
            print("🔍 No user profile available for widening window fetch")
            return 
        }
        
        // Check cache first
        if let cachedPredictions = CacheManager.shared.getCachedCyclePredictions() {
            print("🔍 Using cached cycle predictions (\(cachedPredictions.count) dates)")
            return
        }
        
        print("🔍 Starting fetchWideningWindowData")
        print("🔍 User cycle type: \(userProfile.cycleType?.rawValue ?? "nil")")
        print("🔍 User cycle flow: \(userProfile.cycleFlow?.rawValue ?? "nil")")
        print("🔍 User has recurring symptoms: \(userProfile.hasRecurringSymptoms ?? false)")
        print("🔍 User has moon cycles: \(userProfile.hasMoonCycles)")
        print("🔍 User has irregular cycles: \(userProfile.hasIrregularCycles)")
        print("🔍 User has regular cycles: \(userProfile.hasRegularMenstrualCycles)")
        print("🔍 User cycle type display: \(userProfile.cycleTypeDisplayName)")
        print("🔍 User has lastPeriodStart: \(userProfile.lastPeriodStart != nil)")
        print("🔍 User cycleLength: \(userProfile.cycleLength ?? 0)")
        print("🔍 User averagePeriodLength: \(userProfile.averagePeriodLength ?? 0)")
        print("🔍 Personalization wideningWindow: \(userProfile.personalizationData?.wideningWindow ?? false)")
        print("🔍 Personalization useMoonCycle: \(userProfile.personalizationData?.useMoonCycle ?? false)")
        
        // Fetch backend data for all users to get cycle phases
        guard let _ = userProfile.personalizationData else {
            print("🔍 Skipping backend fetch - no personalization data")
            return
        }
        
        // Always fetch backend data to get cycle phases, regardless of cycle type
        print("🔍 Fetching backend data for user with cycle type: \(userProfile.cycleType?.rawValue ?? "nil")")
        
        isLoadingWideningWindow = true
        
        Task {
            do {
                print("🔍 Calling backend for cycle predictions...")
                let wideningWindowDays = try await CyclePredictionService.shared.fetchCyclePredictions(for: userProfile)
                
                await MainActor.run {
                    print("🔍 Fetched \(wideningWindowDays.count) widening window days")
                    
                    // Cache the cycle predictions
                    CacheManager.shared.setCachedCyclePredictions(wideningWindowDays)
                    
                    // Check if we got backend data
                    if CyclePredictionService.shared.hasBackendData() {
                        print("🔍 ✅ Backend data is now available")
                        print("🔍 ✅ Backend data is now available - cycle predictions fetched")
                        
                        // Widening window data processed successfully
                        
                        // Mark that widening window data is now loaded
                        self.wideningWindowDataLoaded = true
                        print("🔍 ✅ Widening window data loaded flag set to true")
                        
                        // Update the calendar view
                        self.backendDataUpdated.toggle()
                        print("🔍 ✅ Calendar updated with backend data")
                        
                        // Send notification to force calendar refresh
                        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
                        print("🔍 ✅ User profile updated notification sent")
                    } else {
                        print("🔍 ❌ No backend data received")
                    }
                    
                    isLoadingWideningWindow = false
                }
            } catch {
                await MainActor.run {
                    print("❌ Error fetching backend data: \(error)")
                    isLoadingWideningWindow = false
                }
            }
        }
    }
    

    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background with plant leaves effect
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.9),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // New navigation bar
                    CalendarNavigationBar(
                        currentYear: $currentYear,
                        showingYearPicker: $showingYearPicker,
                        showingLegend: $showingLegend,
                        onTodayTapped: {
                            selectedDate = Date()
                            scrollToTodayTrigger = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Days of week header
                    DaysOfWeekHeader()
                    
                    // Cycle type indicator (only for symptomatic and moon cycles)
                    if let userProfile = userProfile, shouldShowCycleTypeIndicator(for: userProfile) {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: cycleTypeIcon(for: userProfile))
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                
                                Text(userProfile.cycleTypeDisplayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.4))
                            .cornerRadius(15)
                            
                            Text(userProfile.cycleTypeDescription)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Calendar content
                    ContinuousCalendarScrollView(
                        selectedDate: $visuallySelectedDate,
                        currentYear: currentYear,
                        userProfile: userProfile,
                        onDateSelected: { date in
                            selectedDate = date
                            visuallySelectedDate = date // Set visual selection
                            showingDateDetailSheet = true
                        },
                        scrollToTodayTrigger: $scrollToTodayTrigger,
                        wideningWindowDataLoaded: wideningWindowDataLoaded
                    )
                    
                    Spacer()
                }
                
                // Floating Edit Period Dates button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        
                        Button(action: {
                            TelemetryDeck.signal("Button.Clicked", parameters: [
                                "buttonType": "edit_period_dates",
                                "location": "calendar"
                            ])
                            showingEditPeriodDates = true
                        }) {
                            Text("Edit Period Dates")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.purple.opacity(0.8))
                                .cornerRadius(25)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingYearPicker) {
            YearPickerView(currentYear: $currentYear, isPresented: $showingYearPicker)
        }
        .sheet(isPresented: $showingEditPeriodDates) {
            EditPeriodDatesView()
        }
        .sheet(isPresented: $showingDateDetailSheet, onDismiss: {
            // Clear visual selection when sheet is dismissed
            visuallySelectedDate = nil
        }) {
            DateDetailBottomSheet(
                selectedDate: selectedDate,
                userProfile: userProfile
            )
        }
        .sheet(isPresented: $showingLegend) {
            CalendarLegendView()
        }
        .onAppear {
            print("🔍 Calendar view appeared - calling fetchWideningWindowData")
            print("🔍 Current user profile: \(userProfile?.id.uuidString ?? "nil")")
            print("🔍 Current personalization data: \(userProfile?.personalizationData?.wideningWindow ?? false)")
            print("🔍 Current widening window flag: \(userProfile?.personalizationData?.wideningWindow ?? false)")
            
            // Check if we already have data
            let hasExistingData = CyclePredictionService.shared.hasBackendData()
            print("🔍 Has existing backend data: \(hasExistingData)")
            
            // Always fetch cycle data when calendar appears to ensure it's up to date
            fetchWideningWindowData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileUpdated)) { _ in
            print("📅 Calendar: Received userProfileUpdated notification")
            backendDataUpdated.toggle() // Force view refresh
        }
    }
}

// MARK: - Calendar Navigation Bar
struct CalendarNavigationBar: View {
    @Binding var currentYear: Int
    @Binding var showingYearPicker: Bool
    @Binding var showingLegend: Bool
    let onTodayTapped: () -> Void
    
    var body: some View {
        HStack {
            // Legend button
            Button(action: {
                TelemetryDeck.signal("Button.Clicked", parameters: [
                    "buttonType": "calendar_legend",
                    "location": "navigation_bar"
                ])
                showingLegend = true
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(20)
            }
            
            Spacer()
            
            // Year dropdown button
            Button(action: {
                TelemetryDeck.signal("Button.Clicked", parameters: [
                    "buttonType": "year_picker",
                    "location": "navigation_bar"
                ])
                showingYearPicker = true
            }) {
                HStack(spacing: 8) {
                    Text(String(currentYear))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.3))
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Today button
            Button(action: {
                TelemetryDeck.signal("Button.Clicked", parameters: [
                    "buttonType": "today_button",
                    "location": "navigation_bar"
                ])
                onTodayTapped()
            }) {
                Text("TODAY")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.pink)
                    .cornerRadius(20)
            }
        }
    }
}

// MARK: - Days of Week Header
struct DaysOfWeekHeader: View {
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Continuous Calendar Scroll View
struct ContinuousCalendarScrollView: View {
    @Binding var selectedDate: Date?
    let currentYear: Int
    let userProfile: UserProfile?
    let onDateSelected: (Date) -> Void
    @Binding var scrollToTodayTrigger: Bool
    let wideningWindowDataLoaded: Bool
    
    private let calendar = Calendar.current
    
    // Computed property to show only 3 months (current + next 2)
    private var monthsToShow: [Int] {
        let currentMonth = calendar.component(.month, from: Date())
        // Show current month and next 2 months (3 months total)
        var months: [Int] = []
        for i in 0..<3 {
            let month = currentMonth + i
            if month <= 12 {
                months.append(month)
            } else {
                // Handle year rollover (e.g., if current month is December, show Dec, Jan, Feb)
                months.append(month - 12)
            }
        }
        return months
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(monthsToShow, id: \.self) { month in
                        MonthCalendarView(
                            month: month,
                            year: currentYear,
                            selectedDate: $selectedDate,
                            userProfile: userProfile,
                            onDateSelected: onDateSelected,
                            wideningWindowDataLoaded: wideningWindowDataLoaded
                        )
                        .id("month-\(month)")
                    }
                }
                .padding(.bottom, 100)
            }
            .onChange(of: scrollToTodayTrigger) { _, newValue in
                if newValue {
                    let today = Date()
                    let month = calendar.component(.month, from: today)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo("month-\(month)", anchor: .center)
                    }
                    scrollToTodayTrigger = false
                }
            }
            .onAppear {
                // Immediately position calendar at current month without animation
                let today = Date()
                let month = calendar.component(.month, from: today)
                proxy.scrollTo("month-\(month)", anchor: .top)
            }
        }
    }
}

// MARK: - Month Calendar View
struct MonthCalendarView: View {
    let month: Int
    let year: Int
    @Binding var selectedDate: Date?
    let userProfile: UserProfile?
    let onDateSelected: (Date) -> Void
    let wideningWindowDataLoaded: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 16) {
            // Month header
            Text(monthName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            // Calendar grid with proper week structure
            VStack(spacing: 8) {
                ForEach(0..<numberOfWeeks, id: \.self) { weekIndex in
                    WeekRowView(
                        weekDates: weekDates(for: weekIndex),
                        selectedDate: $selectedDate,
                        userProfile: userProfile,
                        onDateSelected: onDateSelected,
                        wideningWindowDataLoaded: wideningWindowDataLoaded
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }
    
    private var numberOfWeeks: Int {
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let startOfMonth = calendar.date(from: dateComponents) ?? Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: startOfMonth)?.end ?? startOfMonth
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: endOfMonth)?.end ?? endOfMonth
        
        let weeks = calendar.dateComponents([.weekOfYear], from: startOfWeek, to: endOfWeek).weekOfYear ?? 0
        return max(weeks, 5) // Ensure at least 5 weeks
    }
    
    private func weekDates(for weekIndex: Int) -> [Date?] {
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let startOfMonth = calendar.date(from: dateComponents) ?? Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: startOfWeek) else {
            return Array(repeating: nil, count: 7)
        }
        
        var weekDates: [Date?] = []
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                // Only include dates that are in the current month or adjacent days
                let monthStart = calendar.dateInterval(of: .month, for: startOfMonth)?.start ?? startOfMonth
                let monthEnd = calendar.dateInterval(of: .month, for: startOfMonth)?.end ?? startOfMonth
                
                if date >= monthStart && date < monthEnd {
                    weekDates.append(date)
                } else {
                    weekDates.append(nil)
                }
            } else {
                weekDates.append(nil)
            }
        }
        
        return weekDates
    }
}

// MARK: - Week Row View
struct WeekRowView: View {
    let weekDates: [Date?]
    @Binding var selectedDate: Date?
    let userProfile: UserProfile?
    let onDateSelected: (Date) -> Void
    let wideningWindowDataLoaded: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            // Connecting line
            Path { path in
                let centerY = 10.0 // Center of the circles
                let spacing = UIScreen.main.bounds.width / 7
                
                // Find consecutive valid dates and draw lines between them
                var lastValidIndex: Int?
                for i in 0..<7 {
                    if weekDates[i] != nil {
                        if let lastIndex = lastValidIndex {
                            // Draw line from last valid circle to current circle
                            let startX = spacing * (Double(lastIndex) + 0.5)
                            let endX = spacing * (Double(i) + 0.5)
                            path.move(to: CGPoint(x: startX, y: centerY))
                            path.addLine(to: CGPoint(x: endX, y: centerY))
                        }
                        lastValidIndex = i
                    }
                }
            }
            .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1) // Light grey connecting lines
            
            // Day circles
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    if let date = weekDates[index] {
                        CalendarDayView(
                            date: date,
                            isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!),
                            isToday: calendar.isDateInToday(date),
                            cyclePhase: cyclePhaseForDate(date),
                            hasWorkout: hasWorkoutOnDate(date),
                            weekColor: weekColor,
                            userProfile: userProfile,
                            wideningWindowDataLoaded: wideningWindowDataLoaded
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onDateSelected(date)
                            }
                        }
                    } else {
                        Color.clear
                            .frame(width: UIScreen.main.bounds.width / 7, height: 50)
                    }
                }
            }
            .alignmentGuide(.firstTextBaseline) { d in
                d[VerticalAlignment.center]
            }
        }
    }
    
    private var weekColor: Color? {
        let validDates = weekDates.compactMap { $0 }
        guard !validDates.isEmpty else { return nil }
        
        // Determine color based on the first date's cycle phase
        if let phase = cyclePhaseForDate(validDates[0]) {
            switch phase {
            case .menstrual:
                return Color(red: 0.9, green: 0.7, blue: 0.9) // Light pink
            case .follicular:
                return Color(red: 0.7, green: 0.9, blue: 0.7) // Light green
            case .ovulatory:
                return Color(red: 0.8, green: 0.7, blue: 0.9) // Light purple
            case .luteal:
                return Color(red: 0.8, green: 0.6, blue: 0.9) // Light lavender
            case .menstrualMoon:
                return Color(red: 0.9, green: 0.7, blue: 0.9) // Light pink (same as menstrual)
            case .follicularMoon:
                return Color(red: 0.7, green: 0.9, blue: 0.7) // Light green (same as follicular)
            case .ovulatoryMoon:
                return Color(red: 0.8, green: 0.7, blue: 0.9) // Light purple (same as ovulatory)
            case .lutealMoon:
                return Color(red: 0.8, green: 0.6, blue: 0.9) // Light lavender (same as luteal)
            }
        }
        
        return Color(red: 0.8, green: 0.8, blue: 0.8) // Light gray
    }
    
    private func cyclePhaseForDate(_ date: Date) -> CyclePhase? {
        guard let userProfile = userProfile else { 
            print("📅 Calendar: No user profile available")
            return nil 
        }
        
        // Return nil (no phase/color) for dates before the user's last period start
        let calendar = Calendar.current
        if let lastPeriodStart = userProfile.lastPeriodStart {
            if date < calendar.startOfDay(for: lastPeriodStart) {
                return nil
            }
        }
        
        // Debug: Check user profile data
        if calendar.component(.month, from: date) == 9 && calendar.component(.day, from: date) == 7 {
            print("📅 🎯 CALENDAR SEPTEMBER 7TH DEBUG:")
            print("📅 🎯 UserProfile lastPeriodStart: \(userProfile.lastPeriodStart?.description ?? "nil")")
            print("📅 🎯 UserProfile cycleLength: \(userProfile.cycleLength ?? 0)")
            print("📅 🎯 UserProfile periodLength: \(userProfile.averagePeriodLength ?? 0)")
        }
        
        // Get the phase from Swift-only cycle detection
        if CyclePredictionService.shared.hasBackendData() {
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                print("📅 Calendar: Swift cycle data available for \(userProfile.cycleTypeDisplayName)")
            }
            if let swiftPhase = CyclePredictionService.shared.getPhaseForDate(date, userProfile: userProfile) {
                // Debug logging for Swift phase detection
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    let phaseType = swiftPhase.isMoonBased ? "MOON" : "MENSTRUAL"
                    print("📅 Calendar: Using SWIFT \(phaseType) phase for today: \(swiftPhase)")
                    print("📅 Calendar: Phase displayName: \(swiftPhase.displayName)")
                    print("📅 Calendar: Phase rawValue: \(swiftPhase.rawValue)")
                }
                return swiftPhase
            } else {
                // Debug logging when Swift data exists but no phase found for this date
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    print("📅 Calendar: Swift data exists but no phase found for today")
                }
            }
        } else {
            // Debug logging when no Swift data
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                print("📅 Calendar: No Swift cycle data available for \(userProfile.cycleTypeDisplayName)")
            }
        }
        
        // Fallback to user profile current phase if no backend data
        guard let phase = userProfile.currentCyclePhase else {
            return .follicular // Default fallback
        }
        
        // Debug logging for fallback
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            let phaseType = phase.isMoonBased ? "MOON" : "MENSTRUAL"
            print("📅 Calendar: Using FALLBACK \(phaseType) phase for \(userProfile.cycleTypeDisplayName): \(phase)")
            print("📅 Calendar: Phase displayName: \(phase.displayName)")
            print("📅 Calendar: Phase rawValue: \(phase.rawValue)")
        }
        
        return phase
    }
    
    private func hasWorkoutOnDate(_ date: Date) -> Bool {
        guard let userProfile = userProfile else { return false }
        
        return userProfile.weeklyFitnessPlan.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date) && 
            entry.workoutTitle != "Rest Day"
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let cyclePhase: CyclePhase?
    let hasWorkout: Bool
    let weekColor: Color?
    let userProfile: UserProfile?
    let wideningWindowDataLoaded: Bool
    
    // Check if this date is in the widening window (potential bleed day)
    private var isInWideningWindow: Bool {
        
        guard let userProfile = userProfile else { 
            print("🔍 No user profile for widening window check")
            return false 
        }
        
        // Ensure we have loaded the widening window data
        guard wideningWindowDataLoaded else {
            let shouldLog = Calendar.current.component(.day, from: date) <= 5
            if shouldLog {
                print("🔍 Widening window data not yet loaded for date \(date)")
            }
            return false
        }
        
        // Check if user has irregular cycles
        guard let personalizationData = userProfile.personalizationData else {
            print("🔍 No personalization data for widening window check")
            return false
        }
        
        // Show widening windows ONLY for irregular cycles (NOT symptomatic cycles)
        guard userProfile.hasIrregularCycles else {
            let shouldLog = Calendar.current.component(.day, from: date) <= 5
            if shouldLog {
                print("🔍 User does not have irregular cycles - cycleType: \(userProfile.cycleType?.rawValue ?? "nil"), wideningWindow: \(personalizationData.wideningWindow ?? false), hasRecurringSymptoms: \(userProfile.hasRecurringSymptoms ?? false)")
            }
            return false
        }
        
        // Check if widening window data is available
        let hasWideningWindowData = CyclePredictionService.shared.hasBackendData()
        
        // Only log for a few dates to avoid spam
        let shouldLog = Calendar.current.component(.day, from: date) <= 5
        
        if shouldLog {
            print("🔍 Checking widening window for date \(date)")
            print("🔍 User has irregular cycles: \(userProfile.hasIrregularCycles)")
            print("🔍 User has symptomatic cycles: \(userProfile.cycleType == .noPeriod && userProfile.hasRecurringSymptoms == true)")
            print("🔍 User has recurring symptoms: \(userProfile.hasRecurringSymptoms ?? false)")
            print("🔍 Has widening window data: \(hasWideningWindowData)")
            print("🔍 NOTE: Widening windows are ONLY for irregular cycles, NOT symptomatic cycles")
        }
        
        // Get the widening window days from the cycle prediction service
        let wideningWindowDays = CyclePredictionService.shared.getWideningWindowDays()
        
        // Check if this date is in the widening window
        let isInWindow = wideningWindowDays.contains { wideningDate in
            Calendar.current.isDate(date, inSameDayAs: wideningDate)
        }
        
        // Debug logging for widening window days
        if isInWindow {
            print("🔍 ✅ Date \(date) is in widening window - WILL SHOW ORANGE DASHED BORDER")
        } else if shouldLog {
            print("🔍 ❌ Date \(date) is NOT in widening window")
            print("🔍 Available widening window days: \(wideningWindowDays.count) days")
        }
        
        return isInWindow
    }
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            // Circle with phase icon - fixed position
            ZStack {
                // Background circle - always filled
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 23, height: 23)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
                    .overlay(
                        // Today indicator - white border (thicker and more prominent)
                        Circle()
                            .stroke(isToday ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        // Selected day indicator - different visual treatment
                        Circle()
                            .stroke(isSelected && !isToday ? Color.yellow : Color.clear, lineWidth: 2)
                            .background(
                                Circle()
                                    .fill(isSelected && !isToday ? Color.yellow.opacity(0.3) : Color.clear)
                            )
                    )
                    .overlay(
                        // Widening window indicator - dashed border for potential bleed days
                        Circle()
                            .stroke(
                                isInWideningWindow ? Color.orange : Color.clear,
                                // A thinner line with a pattern calculated for exactly 8 dashes
                                style: StrokeStyle(lineWidth: 2.0, dash: [9.5, 4.25])
                            )
                            // Made the frame significantly wider for a more spacious look
                            .frame(width: 35, height: 35) // 12px larger than the 23px date circle
                    )

                
                // Phase icon for each day
                if let cyclePhase = cyclePhase {
                    Image(cyclePhase.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundColor(.white)
                } else {
                    // Fallback icon for days without phase
                    Image(systemName: "circle")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 23) // Fixed height for circle
            
            // Completion dot indicator - fixed position
            if hasWorkout {
                Circle()
                    .fill(isCompleted ? Color.green : Color.clear)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke(isCompleted ? Color.green : Color.blue, lineWidth: 1)
                    )
            } else {
                // Spacer to maintain alignment when no dot
                Color.clear
                    .frame(width: 6, height: 6)
            }
            
            // Date text below circle - fixed position
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: textSize, weight: textWeight))
                .foregroundColor(textColor)
                .frame(height: 14) // Fixed height for text
        }
        .frame(width: UIScreen.main.bounds.width / 7, height: 50)
        .alignmentGuide(.firstTextBaseline) { d in
            d[VerticalAlignment.center]
        }
    }
    
    private var isCompleted: Bool {
        // Check if any workouts are completed for this date
        guard let userProfile = userProfile else { return false }
        
        // Check for completed workouts in weekly fitness plan
        let hasCompletedWorkouts = userProfile.weeklyFitnessPlan.contains(where: { entry in
            calendar.isDate(entry.date, inSameDayAs: date) && entry.status == WorkoutStatus.confirmed
        })
        
        return hasCompletedWorkouts
    }
    
    private var textSize: CGFloat {
        if isToday {
            return 14
        } else if isSelected {
            return 13
        } else {
            return 12
        }
    }
    
    private var textWeight: Font.Weight {
        if isToday {
            return .black
        } else if isSelected {
            return .bold
        } else {
            return .medium
        }
    }
    
    private var textColor: Color {
        if isToday {
            return .white
        } else if isSelected {
            return .yellow
        } else {
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        // Use phase-specific colors if available, otherwise use light grey
        if let cyclePhase = cyclePhase {
            return cyclePhaseColor(for: cyclePhase)
        } else {
            return Color(red: 0.9, green: 0.9, blue: 0.9) // Light grey fallback
        }
    }
    
    private func cyclePhaseColor(for phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual:
            return Color(red: 0.957, green: 0.408, blue: 0.573) // #F46892 - Pink
        case .follicular:
            return Color(red: 0.976, green: 0.851, blue: 0.157) // #F9D928 - Yellow
        case .ovulatory:
            return Color(red: 0.157, green: 0.851, blue: 0.851) // #28D9D9 - Teal
        case .luteal:
            return Color(red: 0.557, green: 0.671, blue: 0.557) // #8EAB8E - Sage green
        case .menstrualMoon:
            return Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.8) // #F46892 - Pink (muted)
        case .follicularMoon:
            return Color(red: 0.976, green: 0.851, blue: 0.157).opacity(0.8) // #F9D928 - Yellow (muted)
        case .ovulatoryMoon:
            return Color(red: 0.157, green: 0.851, blue: 0.851).opacity(0.8) // #28D9D9 - Teal (muted)
        case .lutealMoon:
            return Color(red: 0.557, green: 0.671, blue: 0.557).opacity(0.8) // #8EAB8E - Sage green (muted)
        }
    }
    
    private var borderColor: Color {
        if isToday {
            return .clear
        } else if isCompleted {
            return .clear
        } else {
            return weekColor ?? .gray
        }
    }
    
    private var borderWidth: CGFloat {
        if isToday {
            return 0
        } else if isCompleted {
            return 0
        } else {
            return 1
        }
    }
    
    private var shadowColor: Color {
        if isToday {
            return .black.opacity(0.3)
        } else {
            return .clear
        }
    }
    
    private var shadowRadius: CGFloat {
        if isToday {
            return 4
        } else {
            return 0
        }
    }
}

// MARK: - Year Picker View
struct YearPickerView: View {
    @Binding var currentYear: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Select Year")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                            ForEach(2020...2030, id: \.self) { year in
                                Button(action: {
                                    currentYear = year
                                    isPresented = false
                                }) {
                                    Text(String(year))
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(year == currentYear ? .white : .gray)
                                        .frame(width: 80, height: 50)
                                        .background(year == currentYear ? Color.purple : Color.gray.opacity(0.3))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}


// MARK: - CalendarView Extension
extension CalendarView {
    // Function to determine if cycle type indicator should be shown
    private func shouldShowCycleTypeIndicator(for userProfile: UserProfile) -> Bool {
        switch userProfile.cycleType {
        case .regular, .irregular:
            return false // Hide for regular and irregular cycles
        case .noPeriod:
            return true // Show for symptomatic and moon cycles
        case .none:
            return false // Hide when not set
        }
    }
    
    // Function to get appropriate icon for cycle type
    private func cycleTypeIcon(for userProfile: UserProfile) -> String {
        switch userProfile.cycleType {
        case .regular:
            return "drop.circle.fill"
        case .irregular:
            return "drop.circle"
        case .noPeriod:
            if userProfile.hasMoonCycles {
                return "moon.circle.fill"
            } else {
                return "heart.circle.fill"
            }
        case .none:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Date Detail Bottom Sheet
struct DateDetailBottomSheet: View {
    let selectedDate: Date
    let userProfile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var notes: String = ""
    @State private var showingLogSymptom = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    private var cyclePhase: String {
        guard let userProfile = userProfile else { return "Unknown Phase" }
        return CyclePredictionService.shared.getPhaseForDate(selectedDate, userProfile: userProfile)?.rawValue.capitalized ?? "Unknown Phase"
    }
    
    private var periodPrediction: String {
        guard let userProfile = userProfile else { return "" }
        
        let calendar = Calendar.current
        guard let lastPeriod = userProfile.lastPeriodStart else { 
            return "Period in \(daysUntilPeriod) days" 
        }
        
        let daysSincePeriod = calendar.dateComponents([.day], from: lastPeriod, to: selectedDate).day ?? 0
        let cycleDay = (daysSincePeriod % (userProfile.cycleLength ?? 0)) + 1
        
        if cycleDay <= (userProfile.averagePeriodLength ?? 0) {
            return "Day \(cycleDay) of period"
        } else {
            return "Period in \(daysUntilPeriod) days"
        }
    }
    
    private var daysUntilPeriod: Int {
        guard let userProfile = userProfile,
              let lastPeriod = userProfile.lastPeriodStart else { return 0 }
        let calendar = Calendar.current
        let nextPeriod = calendar.date(byAdding: .day, value: (userProfile.cycleLength ?? 0), to: lastPeriod) ?? Date()
        let daysUntil = calendar.dateComponents([.day], from: selectedDate, to: nextPeriod).day ?? 0
        return max(0, daysUntil)
    }
    
    private var isDateInFuture: Bool {
        let calendar = Calendar.current
        return selectedDate > calendar.startOfDay(for: Date())
    }
    
    private var recommendedActivities: [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Get workout for this date (only if fitness plan has been set up)
        if let userProfile = userProfile, !userProfile.weeklyFitnessPlan.isEmpty {
            let workoutEntries = userProfile.weeklyFitnessPlan.filter { entry in
                Calendar.current.isDate(entry.date, inSameDayAs: selectedDate)
            }
            
            for entry in workoutEntries {
                if entry.workoutTitle != "Rest Day" {
                    activities.append(ActivityItem(
                        title: entry.workoutTitle,
                        isCompleted: entry.status == .confirmed,
                        type: .workout
                    ))
                }
            }
        }
        
        // Add nutrition habits (only if nutrition personalization has been completed)
        if let userProfile = userProfile,
           let personalizationData = userProfile.personalizationData,
           personalizationData.nutritionCompleted == true {
            
            // Use the same nutrition recommendation engine as DashboardView
            let recommendation = NutritionRecommendationEngine.generateRecommendations(for: userProfile)
            
            for habit in recommendation.habits {
                // Check if this habit was completed on this date
                let isCompleted = isNutritionHabitCompleted(habit.name)
                
                activities.append(ActivityItem(
                    title: habit.name,
                    isCompleted: isCompleted,
                    type: .nutrition
                ))
            }
        }
        
        return activities
    }
    
    private func isNutritionHabitCompleted(_ habitName: String) -> Bool {
        guard let userProfile = userProfile else { return false }
        
        // Find the daily habit entry for this date
        let selectedDateHabit = userProfile.dailyHabits.first { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: selectedDate)
        }
        
        let completedHabits = selectedDateHabit?.completedNutritionHabitsString?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        return completedHabits.contains(habitName)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with gradient background
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dateFormatter.string(from: selectedDate))
                                .font(.custom("Sofia Pro", size: 28))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(cyclePhase)
                                .font(.custom("Sofia Pro", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            if !periodPrediction.isEmpty {
                                Text(periodPrediction)
                                    .font(.custom("Sofia Pro", size: 14))
                                    .fontWeight(.regular)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingLogSymptom = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Log")
                                    .font(.custom("Sofia Pro", size: 16))
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.8), Color.purple.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Activities Section
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(spacing: 12) {
                                ForEach(recommendedActivities, id: \.title) { activity in
                                    ActivityCard(activity: activity, isDateInFuture: isDateInFuture)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notes")
                                .font(.custom("Sofia Pro", size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            TextField("Add notes about your day...", text: $notes, axis: .vertical)
                                .font(.custom("Sofia Pro", size: 16))
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(16)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .lineLimit(3...6)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingLogSymptom) {
            DetailedSymptomLogView(selectedDate: selectedDate)
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "Calendar",
                "pageType": "main_feature"
            ])
        }
    }
}

// MARK: - Activity Item Model
struct ActivityItem {
    let title: String
    let isCompleted: Bool
    let type: ActivityType
}

enum ActivityType {
    case workout
    case nutrition
    case meditation
    case social
    case rest
}

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: ActivityItem
    let isDateInFuture: Bool
    @State private var isCompleted: Bool
    
    init(activity: ActivityItem, isDateInFuture: Bool) {
        self.activity = activity
        self.isDateInFuture = isDateInFuture
        self._isCompleted = State(initialValue: activity.isCompleted)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(activity.title)
                .font(.custom("Sofia Pro", size: 16))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .strikethrough(isCompleted)
                .opacity(isCompleted ? 0.6 : 1.0)
            
            Spacer()
            
            if !isDateInFuture {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCompleted.toggle()
                    }
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isCompleted ? .green : .gray.opacity(0.4))
                }
            } else {
                // Show disabled checkbox for future dates
                Image(systemName: "circle")
                    .font(.system(size: 20))
                    .foregroundColor(.gray.opacity(0.2))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

