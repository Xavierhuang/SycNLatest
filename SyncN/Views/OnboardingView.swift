import SwiftUI
import SwiftData
import UIKit
import TelemetryDeck

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var hormonalImbalances: Set<HormonalImbalance> = []
    @State private var birthControlMethods: Set<BirthControlMethod> = []
    @State private var birthYear: Int?
    @State private var cycleType: CycleType?
    @State private var cycleFlow: CycleFlow?
    @State private var lastPeriodStart: Date?
    @State private var averageCycleDuration: Int?
    @State private var averageBleedingDays: Int?
    @State private var hasRecurringSymptoms: Bool? = nil
    @State private var lastSymptomsStart: Date?
    @State private var averageSymptomDays: Int?
    @State private var periodSymptoms: Set<PeriodSymptom> = []
    
    // Track user interactions for period details validation
    @State private var hasInteractedWithPeriodDate = false
    @State private var hasInteractedWithCycleDuration = false
    @State private var hasInteractedWithBleedingDays = false
    
    // Track user interactions for symptom tracking validation
    @State private var hasInteractedWithSymptomsStart = false
    @State private var hasInteractedWithSymptomCycleDuration = false
    @State private var hasInteractedWithSymptomDays = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("SyncN")
                            .font(.sofiaProLargeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                        
                        // Progress bar
                        OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        HormonalImbalancesStepView(hormonalImbalances: $hormonalImbalances)
                            .tag(0)
                            .onAppear { 
                                print("🔍 Step 0: Hormonal Imbalances")
                                TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                    "step": "hormonal_imbalances",
                                    "stepNumber": "0"
                                ])
                            }
                        
                        BirthControlStepView(birthControlMethods: $birthControlMethods)
                            .tag(1)
                            .onAppear { 
                                print("🔍 Step 1: Birth Control")
                                TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                    "step": "birth_control",
                                    "stepNumber": "1"
                                ])
                            }
                        
                        BirthYearStepView(birthYear: $birthYear)
                            .tag(2)
                            .onAppear { 
                                print("🔍 Step 2: Birth Year")
                                TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                    "step": "birth_year",
                                    "stepNumber": "2"
                                ])
                            }
                        
                        CycleTypeStepView(cycleType: $cycleType)
                            .tag(3)
                            .onAppear { 
                                print("🔍 Step 3: Cycle Type - current cycleType: \(cycleType?.rawValue ?? "nil")")
                                TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                    "step": "cycle_type",
                                    "stepNumber": "3"
                                ])
                            }
                            .onChange(of: cycleType) { _, newValue in
                                print("🔍 CycleType changed to: \(newValue?.rawValue ?? "nil")")
                                TelemetryDeck.signal("Onboarding.CycleType.Selected", parameters: [
                                    "cycleType": newValue?.rawValue ?? "none"
                                ])
                                if newValue != nil && currentStep == 3 {
                                    // Go to step 4 (hormone explanation or no period info)
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStep += 1
                                    }
                                }
                            }
                        
                        
                        // Step 4: Hormone explanation (periods) OR No period info (no periods)
                        if hasPeriod {
                            HormoneExplanationStepView()
                                .tag(4)
                                .onAppear {
                                    TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                        "step": "hormone_explanation",
                                        "stepNumber": "4"
                                    ])
                                }
                        } else {
                            NoPeriodStepView()
                                .tag(4)
                                .onAppear {
                                    print("🔍 NoPeriodStepView appeared - hasPeriod: \(hasPeriod), currentStep: \(currentStep)")
                                    TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                        "step": "no_period_info",
                                        "stepNumber": "4"
                                    ])
                                }
                        }
                        
                        // Step 5: Period details (periods) OR Standard symptoms page (no periods)
                        if hasPeriod {
                            PeriodDetailsStepView(
                                lastPeriodStart: Binding(
                                    get: { self.lastPeriodStart ?? Date() },
                                    set: { 
                                        self.lastPeriodStart = $0
                                        self.hasInteractedWithPeriodDate = true
                                    }
                                ),
                                averageCycleDuration: Binding(
                                    get: { self.averageCycleDuration ?? 0 },
                                    set: { 
                                        self.averageCycleDuration = $0
                                        self.hasInteractedWithCycleDuration = true
                                    }
                                ),
                                averageBleedingDays: Binding(
                                    get: { self.averageBleedingDays ?? 0 },
                                    set: { 
                                        self.averageBleedingDays = $0
                                        self.hasInteractedWithBleedingDays = true
                                    }
                                ),
                                hasInteractedWithPeriodDate: $hasInteractedWithPeriodDate,
                                hasInteractedWithCycleDuration: $hasInteractedWithCycleDuration,
                                hasInteractedWithBleedingDays: $hasInteractedWithBleedingDays
                            )
                            .tag(5)
                            .onAppear {
                                TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                    "step": "period_details",
                                    "stepNumber": "5"
                                ])
                                // Initialize with current date if nil
                                if self.lastPeriodStart == nil {
                                    self.lastPeriodStart = Date()
                                }
                                // Initialize cycle duration and bleeding days with default values
                                if self.averageCycleDuration == nil {
                                    self.averageCycleDuration = 28 // Default cycle length
                                }
                                if self.averageBleedingDays == nil {
                                    self.averageBleedingDays = 5 // Default bleeding days
                                }
                            }
                        } else {
                            // Standard symptoms page for users without periods
                            PeriodSymptomsOnboardingStepView(periodSymptoms: $periodSymptoms)
                                .tag(5)
                                .onAppear {
                                    TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                        "step": "symptoms_selection",
                                        "stepNumber": "5"
                                    ])
                                }
                        }
                        
                        // Step 6: Symptoms selection (periods) OR Recurring symptoms question (no periods)
                        if hasPeriod {
                            PeriodSymptomsOnboardingStepView(periodSymptoms: $periodSymptoms)
                                .tag(6)
                                .onAppear {
                                    TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                        "step": "symptoms_selection",
                                        "stepNumber": "6"
                                    ])
                                }
                        } else {
                            NoPeriodRecurringSymptomsStepView(hasRecurringSymptoms: $hasRecurringSymptoms)
                                .tag(6)
                                .onAppear {
                                    TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                        "step": "recurring_symptoms_question",
                                        "stepNumber": "6"
                                    ])
                                }
                                .onChange(of: hasRecurringSymptoms) { _, newValue in
                                    print("🔍 hasRecurringSymptoms changed to: \(newValue?.description ?? "nil")")
                                    TelemetryDeck.signal("Onboarding.RecurringSymptoms.Selected", parameters: [
                                        "hasRecurringSymptoms": newValue?.description ?? "none"
                                    ])
                                    if newValue == true && currentStep == 6 {
                                        // User selected "Yes" to recurring symptoms, advance to step 7
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentStep += 1
                                        }
                                    }
                                }
                        }
                        
                        // Step 6: Symptom tracking details (no periods only, if they have recurring symptoms)
                        if !hasPeriod && hasRecurringSymptoms == true {
                            NoPeriodSymptomTrackingStepView(
                                lastSymptomsStart: Binding(
                                    get: { self.lastSymptomsStart ?? Date() },
                                    set: { 
                                        self.lastSymptomsStart = $0
                                        self.hasInteractedWithSymptomsStart = true
                                    }
                                ),
                                averageCycleDuration: Binding(
                                    get: { self.averageCycleDuration ?? 0 },
                                    set: { 
                                        self.averageCycleDuration = $0
                                        self.hasInteractedWithSymptomCycleDuration = true
                                    }
                                ),
                                averageSymptomDays: Binding(
                                    get: { self.averageSymptomDays ?? 0 },
                                    set: { 
                                        self.averageSymptomDays = $0
                                        self.hasInteractedWithSymptomDays = true
                                    }
                                ),
                                hasInteractedWithSymptomsStart: $hasInteractedWithSymptomsStart,
                                hasInteractedWithSymptomCycleDuration: $hasInteractedWithSymptomCycleDuration,
                                hasInteractedWithSymptomDays: $hasInteractedWithSymptomDays
                            )
                            .tag(7)
                            .onAppear {
                                TelemetryDeck.signal("Onboarding.Step.Started", parameters: [
                                    "step": "symptom_tracking_details",
                                    "stepNumber": "7"
                                ])
                            }
                        }
                        
                        
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .gesture(DragGesture().onChanged { _ in }) // Disable TabView swipe gestures while allowing button taps
                    
                    // Navigation buttons
                    NavigationButtonsView(
                        currentStep: $currentStep,
                        totalSteps: totalSteps,
                        canProceed: canProceedToNextStep,
                        onComplete: createUserProfile
                    )
                }
                .background(Color(red: 0.08, green: 0.11, blue: 0.17))
                
                // Back button in top left corner
                VStack {
                    HStack {
                        if currentStep > 0 {
                            Button(action: {
                                TelemetryDeck.signal("Onboarding.Step.Back", parameters: [
                                    "fromStep": String(currentStep),
                                    "toStep": String(currentStep - 1)
                                ])
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep = getPreviousStep()
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            TelemetryDeck.signal("Onboarding.Started", parameters: [
                "totalSteps": String(totalSteps)
            ])
        }

    }
    
    private var totalSteps: Int {
        // Users without periods have more steps
        if cycleType == .noPeriod {
            // Add 1 more step if they have recurring symptoms (symptom tracking details)
            let baseSteps = 8 // Steps: 0, 1, 2, 3 (no period info), 4 (symptoms selection), 5 (recurring symptoms question), 6 (symptom tracking details)
            return hasRecurringSymptoms == true ? baseSteps : baseSteps - 1
        } else {
            return 7 // Steps: 0, 1, 2, 3 (hormone explanation), 4 (period details), 5 (symptoms selection)
        }
    }
    
    private var hasPeriod: Bool {
        print("🔍 hasPeriod check: cycleType = \(cycleType?.rawValue ?? "nil"), cycleFlow = \(cycleFlow?.rawValue ?? "nil")")
        let result = cycleType != .noPeriod
        print("🔍 hasPeriod result: \(result)")
        return result
    }
    
    private func getPreviousStep() -> Int {
        // Normal step-by-step navigation
        return currentStep - 1
    }
    
    private var canProceedToNextStep: Bool {
        let canProceed: Bool
        switch currentStep {
        case 0: canProceed = true // Medical conditions are optional
        case 1: canProceed = true // Birth control is optional
        case 2: canProceed = birthYear != nil // Birth year is required
        case 3: canProceed = cycleType != nil // Cycle type is required
        case 4: 
            // Step 4 is either hormone explanation (if hasPeriod) or no period details (if noPeriod)
            canProceed = true // Both are informational/optional steps
        case 5: 
            // Step 5 is period details (if hasPeriod) or symptoms selection (if noPeriod)
            if hasPeriod {
                canProceed = lastPeriodStart != nil && 
                           (averageCycleDuration ?? 0) >= 21 && 
                           (averageBleedingDays ?? 0) >= 1 &&
                           hasInteractedWithPeriodDate &&
                           hasInteractedWithCycleDuration &&
                           hasInteractedWithBleedingDays
                print("🔍 OnboardingView: Step 5 validation - lastPeriodStart: \(lastPeriodStart != nil), cycleDuration: \(averageCycleDuration ?? 0), bleedingDays: \(averageBleedingDays ?? 0), interacted: date=\(hasInteractedWithPeriodDate), cycle=\(hasInteractedWithCycleDuration), bleeding=\(hasInteractedWithBleedingDays), canProceed: \(canProceed)")
            } else {
                canProceed = true // Symptoms selection doesn't need validation
            }
        case 6:
            // Step 6 is symptoms selection (periods) or recurring symptoms question (no periods)
            if hasPeriod {
                canProceed = true // Symptoms selection doesn't need validation
            } else {
                canProceed = hasRecurringSymptoms != nil // Must answer the recurring symptoms question
            }
        case 7:
            // Step 7 is symptom tracking details (no periods only)
            canProceed = lastSymptomsStart != nil && 
                       (averageCycleDuration ?? 0) >= 21 && 
                       (averageSymptomDays ?? 0) >= 1 &&
                       hasInteractedWithSymptomsStart &&
                       hasInteractedWithSymptomCycleDuration &&
                       hasInteractedWithSymptomDays
        default: canProceed = true
        }
        
        print("🔍 OnboardingView: Step \(currentStep) canProceed = \(canProceed)")
        return canProceed
    }
    
    private func createUserProfile() {
        // Provide haptic feedback for completion
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Track onboarding completion
        TelemetryDeck.signal("Onboarding.Completed", parameters: [
            "cycleType": cycleType?.rawValue ?? "none",
            "hasPeriod": String(hasPeriod),
            "hormonalImbalancesCount": String(hormonalImbalances.count),
            "birthControlMethodsCount": String(birthControlMethods.count),
            "periodSymptomsCount": String(periodSymptoms.count),
            "hasRecurringSymptoms": hasRecurringSymptoms?.description ?? "none"
        ])
        
        // Check if user profile already exists
        let existingProfiles = try? modelContext.fetch(FetchDescriptor<UserProfile>())
        let existingProfile = existingProfiles?.first
        
        if let existingProfile = existingProfile {
            // Update existing profile
            print("🔄 Updating existing user profile")
            existingProfile.cycleLength = averageCycleDuration
            existingProfile.averagePeriodLength = hasPeriod ? averageBleedingDays : nil
            
            if hasPeriod, let lastPeriodStart = lastPeriodStart {
                existingProfile.lastPeriodStart = lastPeriodStart
            }
            
            // Store additional onboarding data
            existingProfile.hormonalImbalances = Array(hormonalImbalances)
            existingProfile.birthControlMethods = Array(birthControlMethods)
            existingProfile.cycleType = cycleType ?? .regular
            existingProfile.cycleFlow = cycleFlow ?? .regular
            existingProfile.hasRecurringSymptoms = hasRecurringSymptoms
            
            // Update birth date with the selected birth year
            let calendar = Calendar.current
            let currentDate = existingProfile.birthDate
            let _ = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let day = calendar.component(.day, from: currentDate)
            
            if let birthYear = birthYear,
               let newBirthDate = calendar.date(from: DateComponents(year: birthYear, month: month, day: day)) {
                existingProfile.birthDate = newBirthDate
            }
            
            // Store period symptoms data
            if hasPeriod {
                existingProfile.currentSymptomsString = Array(periodSymptoms).map { $0.rawValue }.joined(separator: ",")
            }
            
            if !hasPeriod && hasRecurringSymptoms == true {
                // User has recurring symptoms - save the data
                if let lastSymptomsStart = lastSymptomsStart {
                    existingProfile.lastSymptomsStart = lastSymptomsStart
                }
                existingProfile.averageSymptomDays = averageSymptomDays
            } else if !hasPeriod && hasRecurringSymptoms == false {
                // User has no recurring symptoms (moon cycle) - explicitly clear symptom data
                existingProfile.lastSymptomsStart = nil
                existingProfile.averageSymptomDays = nil
                print("🌙 Clearing symptom data for moon cycle user")
            }
            
            // Update PersonalizationData
            if let existingPersonalization = existingProfile.personalizationData {
                print("🔄 Updating existing PersonalizationData")
                existingPersonalization.cycleCompleted = true
                existingPersonalization.wideningWindow = (cycleType == .irregular)
                // Set moon cycle flag if user doesn't get periods and has no recurring symptoms
                let shouldUseMoonCycle = (cycleType == .noPeriod && hasRecurringSymptoms == false)
                existingPersonalization.useMoonCycle = shouldUseMoonCycle
                // Copy symptoms data from UserProfile
                if hasPeriod {
                    existingPersonalization.periodSymptomsString = Array(periodSymptoms).map { $0.rawValue }.joined(separator: ",")
                }
                print("🌙 Setting useMoonCycle: \(shouldUseMoonCycle) (cycleType: \(cycleType?.rawValue ?? "nil"), hasRecurringSymptoms: \(hasRecurringSymptoms ?? false))")
            } else {
                print("🔄 Creating new PersonalizationData for existing profile")
                let personalization = PersonalizationData(userId: existingProfile.id)
                personalization.cycleCompleted = true
                personalization.wideningWindow = (cycleType == .irregular)
                // Set moon cycle flag if user doesn't get periods and has no recurring symptoms
                personalization.useMoonCycle = (cycleType == .noPeriod && hasRecurringSymptoms == false)
                // Copy symptoms data from UserProfile
                if hasPeriod {
                    personalization.periodSymptomsString = Array(periodSymptoms).map { $0.rawValue }.joined(separator: ",")
                }
                existingProfile.personalizationData = personalization
                modelContext.insert(personalization)
            }
            
            do {
                try modelContext.save()
                print("✅ Successfully updated existing UserProfile and PersonalizationData")
                print("📊 cycleCompleted: \(existingProfile.personalizationData?.cycleCompleted ?? false)")
                print("🔍 Debug - Saved values:")
                print("  hasRecurringSymptoms: \(existingProfile.hasRecurringSymptoms ?? false)")
                print("  lastSymptomsStart: \(existingProfile.lastSymptomsStart?.description ?? "nil")")
                print("  averageSymptomDays: \(existingProfile.averageSymptomDays ?? 0)")
                print("  useMoonCycle: \(existingProfile.personalizationData?.useMoonCycle ?? false)")
                
                // Call backend to get cycle predictions
                Task {
                    do {
                        let predictions = try await CyclePredictionService.shared.fetchCyclePredictions(for: existingProfile)
                        print("🔍 Backend predictions received: \(predictions)")
                        
                        // Check if both cycle tracking and fitness personalization are completed
                        if let personalization = existingProfile.personalizationData,
                           personalization.cycleCompleted == true && personalization.fitnessCompleted == true {
                            print("🎯 Both cycle tracking and fitness personalization completed - generating fitness plan...")
                            
                            // Generate fitness plan
                            let weeklyPlan = try await CyclePredictionService.shared.fetchWeeklyFitnessPlan(for: existingProfile, startDate: Date())
                            
                            await MainActor.run {
                                // Replace the existing fitness plan with the new one
                                existingProfile.weeklyFitnessPlan = weeklyPlan
                                
                                do {
                                    try modelContext.save()
                                    print("✅ 14-day fitness plan generated and saved successfully after onboarding completion!")
                                } catch {
                                    print("❌ Error saving generated fitness plan: \(error)")
                                }
                            }
                        } else {
                            print("🎯 Cycle tracking completed, but fitness personalization not yet completed. Fitness plan will be generated when both are done.")
                        }
                    } catch {
                        print("❌ Error fetching backend predictions: \(error)")
                    }
                }
                
                dismiss()
            } catch {
                print("❌ Error updating user profile: \(error)")
            }
        } else {
            // Create new profile (this shouldn't happen in normal flow)
            print("🔄 Creating new user profile (unexpected)")
            
            // Create birth date from selected birth year
            let calendar = Calendar.current
            let currentDate = Date()
            let month = calendar.component(.month, from: currentDate)
            let day = calendar.component(.day, from: currentDate)
            let birthDate = birthYear != nil ? 
                calendar.date(from: DateComponents(year: birthYear!, month: month, day: day)) ?? Date() : 
                Date()
            
            let profile = UserProfile(
                name: "",
                birthDate: birthDate,
                cycleLength: averageCycleDuration,
                averagePeriodLength: hasPeriod ? averageBleedingDays : nil,
                fitnessLevel: nil
            )
            
            if hasPeriod, let lastPeriodStart = lastPeriodStart {
                profile.lastPeriodStart = lastPeriodStart
            }
            
            // Store additional onboarding data
            profile.hormonalImbalances = Array(hormonalImbalances)
            profile.birthControlMethods = Array(birthControlMethods)
            profile.cycleType = cycleType ?? .regular
            profile.cycleFlow = cycleFlow ?? .regular
            profile.hasRecurringSymptoms = hasRecurringSymptoms
            
            // Store period symptoms data
            if hasPeriod {
                profile.currentSymptomsString = Array(periodSymptoms).map { $0.rawValue }.joined(separator: ",")
            }
            
            if !hasPeriod && hasRecurringSymptoms == true {
                // User has recurring symptoms - save the data
                if let lastSymptomsStart = lastSymptomsStart {
                    profile.lastSymptomsStart = lastSymptomsStart
                }
                profile.averageSymptomDays = averageSymptomDays
            } else if !hasPeriod && hasRecurringSymptoms == false {
                // User has no recurring symptoms (moon cycle) - explicitly clear symptom data
                profile.lastSymptomsStart = nil
                profile.averageSymptomDays = nil
                print("🌙 Clearing symptom data for moon cycle user")
            }
            
            modelContext.insert(profile)
            
            // Create PersonalizationData
            let personalization = PersonalizationData(userId: profile.id)
            personalization.cycleCompleted = true
            personalization.wideningWindow = (cycleType == .irregular)
            // Set moon cycle flag if user doesn't get periods and has no recurring symptoms
            let shouldUseMoonCycle = (cycleType == .noPeriod && hasRecurringSymptoms == false)
            personalization.useMoonCycle = shouldUseMoonCycle
            // Copy symptoms data from UserProfile
            if hasPeriod {
                personalization.periodSymptomsString = Array(periodSymptoms).map { $0.rawValue }.joined(separator: ",")
            }
            print("🌙 Setting useMoonCycle: \(shouldUseMoonCycle) (cycleType: \(cycleType?.rawValue ?? "nil"), hasRecurringSymptoms: \(hasRecurringSymptoms ?? false))")
            profile.personalizationData = personalization
            modelContext.insert(personalization)
            
            do {
                try modelContext.save()
                print("✅ Successfully created new UserProfile and PersonalizationData")
                print("📊 cycleCompleted: \(personalization.cycleCompleted)")
                print("🔍 Debug - Saved values:")
                print("  hasRecurringSymptoms: \(profile.hasRecurringSymptoms ?? false)")
                print("  lastSymptomsStart: \(profile.lastSymptomsStart?.description ?? "nil")")
                print("  averageSymptomDays: \(profile.averageSymptomDays ?? 0)")
                print("  useMoonCycle: \(personalization.useMoonCycle ?? false)")
                
                // Call backend to get cycle predictions
                Task {
                    do {
                        let predictions = try await CyclePredictionService.shared.fetchCyclePredictions(for: profile)
                        print("🔍 Backend predictions received: \(predictions)")
                        
                        // Check if both cycle tracking and fitness personalization are completed
                        if let personalization = profile.personalizationData,
                           personalization.cycleCompleted == true && personalization.fitnessCompleted == true {
                            print("🎯 Both cycle tracking and fitness personalization completed - generating fitness plan...")
                            
                            // Generate fitness plan
                            let weeklyPlan = try await CyclePredictionService.shared.fetchWeeklyFitnessPlan(for: profile, startDate: Date())
                            
                            await MainActor.run {
                                // Replace the existing fitness plan with the new one
                                profile.weeklyFitnessPlan = weeklyPlan
                                
                                do {
                                    try modelContext.save()
                                    print("✅ 14-day fitness plan generated and saved successfully after onboarding completion!")
                                } catch {
                                    print("❌ Error saving generated fitness plan: \(error)")
                                }
                            }
                        } else {
                            print("🎯 Cycle tracking completed, but fitness personalization not yet completed. Fitness plan will be generated when both are done.")
                        }
                    } catch {
                        print("❌ Error fetching backend predictions: \(error)")
                    }
                }
                
                dismiss()
            } catch {
                print("❌ Error creating user profile: \(error)")
            }
        }
    }
}

// MARK: - Progress Bar
struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(Color(red: 0.608, green: 0.431, blue: 0.953))
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                    .cornerRadius(2)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Navigation Buttons
struct NavigationButtonsView: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    let canProceed: Bool
    let onComplete: () -> Void
    
    private var buttonText: String {
        if currentStep == totalSteps - 1 {
            return "Complete"
        } else {
            return "Continue"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Continue/Complete button
            Button(action: {
                // Add haptic feedback for better user confirmation
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentStep == totalSteps - 1 {
                        onComplete()
                    } else {
                        currentStep += 1
                    }
                }
            }) {
                Text(buttonText)
                    .font(.sofiaProHeadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50) // Ensure minimum touch target height
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(canProceed ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color.gray)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle for more reliable touch handling
            .disabled(!canProceed)
            .allowsHitTesting(canProceed) // Explicitly enable hit testing when can proceed
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Step Views
struct HormonalImbalancesStepView: View {
    @Binding var hormonalImbalances: Set<HormonalImbalance>
    @State private var showingHormoneGlossary = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Do you struggle with any of these hormonal imbalances?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Text("Select all that apply to you")
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button("What do these mean?") {
                        showingHormoneGlossary = true
                    }
                    .font(.sofiaProSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                    .underline()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(HormonalImbalance.allCases, id: \.self) { imbalance in
                    SelectionButton(
                        title: imbalance.rawValue,
                        isSelected: hormonalImbalances.contains(imbalance)
                    ) {
                        if hormonalImbalances.contains(imbalance) {
                            hormonalImbalances.remove(imbalance)
                            TelemetryDeck.signal("Onboarding.HormonalImbalance.Deselected", parameters: [
                                "imbalance": imbalance.rawValue
                            ])
                        } else {
                            hormonalImbalances.insert(imbalance)
                            TelemetryDeck.signal("Onboarding.HormonalImbalance.Selected", parameters: [
                                "imbalance": imbalance.rawValue
                            ])
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .sheet(isPresented: $showingHormoneGlossary) {
            HormoneGlossaryView()
        }
    }
}

struct BirthControlStepView: View {
    @Binding var birthControlMethods: Set<BirthControlMethod>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Are you on any of these birth control methods?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply to you")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(BirthControlMethod.allCases, id: \.self) { method in
                    SelectionButton(
                        title: method.rawValue,
                        isSelected: birthControlMethods.contains(method)
                    ) {
                        if birthControlMethods.contains(method) {
                            birthControlMethods.remove(method)
                            TelemetryDeck.signal("Onboarding.BirthControl.Deselected", parameters: [
                                "method": method.rawValue
                            ])
                        } else {
                            birthControlMethods.insert(method)
                            TelemetryDeck.signal("Onboarding.BirthControl.Selected", parameters: [
                                "method": method.rawValue
                            ])
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct CycleTypeStepView: View {
    @Binding var cycleType: CycleType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How would you describe your cycle?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                ForEach(CycleType.allCases, id: \.self) { type in
                    SelectionButton(
                        title: type.rawValue,
                        isSelected: cycleType == type
                    ) {
                        cycleType = type
                        TelemetryDeck.signal("Onboarding.CycleType.Selected", parameters: [
                            "cycleType": type.rawValue
                        ])
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}


struct PeriodDetailsStepView: View {
    @Binding var lastPeriodStart: Date
    @Binding var averageCycleDuration: Int
    @Binding var averageBleedingDays: Int
    @Binding var hasInteractedWithPeriodDate: Bool
    @Binding var hasInteractedWithCycleDuration: Bool
    @Binding var hasInteractedWithBleedingDays: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Let's get your cycle details")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("First day of your last period?")
                            .font(.sofiaProHeadline)
                            .foregroundColor(.white)
                        
                        if !hasInteractedWithPeriodDate {
                            Text("Required")
                                .font(.sofiaProCaption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    DatePicker("", selection: Binding(
                        get: { lastPeriodStart },
                        set: { 
                            lastPeriodStart = $0
                            hasInteractedWithPeriodDate = true
                        }
                    ), displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Average Cycle Duration (days)")
                            .font(.sofiaProHeadline)
                            .foregroundColor(.white)
                        
                        if !hasInteractedWithCycleDuration {
                            Text("Required")
                                .font(.sofiaProCaption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(averageCycleDuration)")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("days")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                    
                    Slider(value: Binding(
                        get: { Double(averageCycleDuration) },
                        set: { averageCycleDuration = Int($0) }
                    ), in: 21...45, step: 1)
                    .accentColor(Color(red: 0.608, green: 0.431, blue: 0.953))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Average Days of Bleeding")
                            .font(.sofiaProHeadline)
                            .foregroundColor(.white)
                        
                        if !hasInteractedWithBleedingDays {
                            Text("Required")
                                .font(.sofiaProCaption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(averageBleedingDays)")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("days")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                    
                    Slider(value: Binding(
                        get: { Double(averageBleedingDays) },
                        set: { averageBleedingDays = Int($0) }
                    ), in: 1...10, step: 1)
                    .accentColor(Color(red: 0.608, green: 0.431, blue: 0.953))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            // Reset interaction state when view appears
            hasInteractedWithPeriodDate = false
        }
    }
}

struct NoPeriodStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("No period? Let's find your rhythm.")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Thanks for letting us know. Even without a period, symptoms like cramps, mood shifts, or fatigue can occur in a cycle. We can help you find that pattern.")
                    .font(.sofiaProBody)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

// MARK: - Selection Button
struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.isDisabled = false
        self.action = action
    }
    
    init(title: String, isSelected: Bool, isDisabled: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: isDisabled ? {} : action) {
            HStack {
                Text(title)
                    .font(.sofiaProHeadline)
                    .fontWeight(.medium)
                    .foregroundColor(isDisabled ? .white.opacity(0.4) : (isSelected ? .white : .white.opacity(0.8)))
                
                Spacer()
                
                if isSelected && !isDisabled {
                    Image(systemName: "checkmark")
                        .font(.sofiaProSubheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14) // Increased padding for better touch target
            .frame(minHeight: 48) // Ensure minimum touch target height
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? Color(red: 0.05, green: 0.06, blue: 0.09) : (isSelected ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color(red: 0.1, green: 0.12, blue: 0.18)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDisabled ? Color.white.opacity(0.1) : (isSelected ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color.white.opacity(0.2)), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle()) // Ensure reliable touch handling
        .disabled(isDisabled)
        .allowsHitTesting(!isDisabled) // Explicitly control hit testing
    }
}

struct HormoneGlossaryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Hormone Glossary")
                        .font(.sofiaProLargeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                    
                    // Glossary entries
                    VStack(alignment: .leading, spacing: 16) {
                        GlossaryEntry(
                            title: "PMS (Premenstrual Syndrome)",
                            definition: "A group of physical and mood symptoms that show up in the days before your period (e.g., bloating, cramps, irritability) and improve once bleeding starts."
                        )
                        
                        GlossaryEntry(
                            title: "PMDD (Premenstrual Dysphoric Disorder)",
                            definition: "A severe form of PMS with intense mood symptoms (like sadness, rage, or anxiety) that disrupt daily life and improve after the period starts."
                        )
                        
                        GlossaryEntry(
                            title: "PCOS (Polycystic Ovary Syndrome)",
                            definition: "A hormone condition where ovaries may release eggs less often and make more androgens. Signs can include irregular cycles, acne, hair changes, or ovarian cysts."
                        )
                        
                        GlossaryEntry(
                            title: "Endometriosis",
                            definition: "Tissue similar to the uterine lining grows outside the uterus, often causing pelvic pain, painful periods, pain with sex, or fertility challenges."
                        )
                        
                        GlossaryEntry(
                            title: "Hypothyroidism (Underactive Thyroid)",
                            definition: "The thyroid doesn't make enough hormone. Common signs: fatigue, feeling cold, dry skin, weight changes, and heavier or irregular periods."
                        )
                        
                        GlossaryEntry(
                            title: "Other",
                            definition: "You experience something not listed here (e.g., fibroids, adenomyosis, hyperthyroidism, POI)."
                        )
                    }
                    
                    // Disclaimer
                    Text("This information is educational and not medical advice.")
                        .font(.sofiaProCaption)
                        .italic()
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.sofiaProBody)
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct GlossaryEntry: View {
    let title: String
    let definition: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.sofiaProHeadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(definition)
                .font(.sofiaProBody)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Period Symptoms Onboarding Step View
struct PeriodSymptomsOnboardingStepView: View {
    @Binding var periodSymptoms: Set<PeriodSymptom>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Do you experience any of these symptoms around your period?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PeriodSymptom.allCases, id: \.self) { symptom in
                    SelectionButton(
                        title: symptom.rawValue,
                        isSelected: periodSymptoms.contains(symptom)
                    ) {
                        if periodSymptoms.contains(symptom) {
                            periodSymptoms.remove(symptom)
                            TelemetryDeck.signal("Onboarding.PeriodSymptom.Deselected", parameters: [
                                "symptom": symptom.rawValue
                            ])
                        } else {
                            periodSymptoms.insert(symptom)
                            TelemetryDeck.signal("Onboarding.PeriodSymptom.Selected", parameters: [
                                "symptom": symptom.rawValue
                            ])
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}


// MARK: - Hormone Explanation Step View
struct HormoneExplanationStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your two main hormones, estrogen and progesterone, aren't just for reproduction.")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("They impact your mood, energy, metabolism, and even strength. We'll help you harness their power.")
                    .font(.sofiaProBody)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}


// MARK: - No Period Recurring Symptoms Step View
struct NoPeriodRecurringSymptomsStepView: View {
    @Binding var hasRecurringSymptoms: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Do you have recurring symptoms?")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("If you experience symptoms regularly, we can help you track them to find patterns in your cycle.")
                    .font(.sofiaProBody)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
            }
            
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    SelectionButton(
                        title: "Yes",
                        isSelected: hasRecurringSymptoms == true
                    ) {
                        hasRecurringSymptoms = true
                        TelemetryDeck.signal("Onboarding.RecurringSymptoms.Selected", parameters: [
                            "hasRecurringSymptoms": "true"
                        ])
                    }
                    
                    SelectionButton(
                        title: "No",
                        isSelected: hasRecurringSymptoms == false
                    ) {
                        hasRecurringSymptoms = false
                        TelemetryDeck.signal("Onboarding.RecurringSymptoms.Selected", parameters: [
                            "hasRecurringSymptoms": "false"
                        ])
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}


// MARK: - No Period Symptom Tracking Step View
struct NoPeriodSymptomTrackingStepView: View {
    @Binding var lastSymptomsStart: Date
    @Binding var averageCycleDuration: Int
    @Binding var averageSymptomDays: Int
    @Binding var hasInteractedWithSymptomsStart: Bool
    @Binding var hasInteractedWithSymptomCycleDuration: Bool
    @Binding var hasInteractedWithSymptomDays: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Let's set up your symptom tracking")
                    .font(.sofiaProTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("We'll use this information to help you track patterns in your symptoms.")
                    .font(.sofiaProBody)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Start date of last symptoms")
                            .font(.sofiaProHeadline)
                            .foregroundColor(.white)
                        
                        if !hasInteractedWithSymptomsStart {
                            Text("Required")
                                .font(.sofiaProCaption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    DatePicker("", selection: Binding(
                        get: { lastSymptomsStart },
                        set: { 
                            lastSymptomsStart = $0
                            hasInteractedWithSymptomsStart = true
                        }
                    ), displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Average Cycle Duration (days)")
                            .font(.sofiaProHeadline)
                            .foregroundColor(.white)
                        
                        if !hasInteractedWithSymptomCycleDuration {
                            Text("Required")
                                .font(.sofiaProCaption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack {
                        Text("\(averageCycleDuration)")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("days")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                    
                    Slider(value: Binding(
                        get: { Double(averageCycleDuration) },
                        set: { 
                            averageCycleDuration = Int($0)
                            hasInteractedWithSymptomCycleDuration = true
                        }
                    ), in: 21...45, step: 1)
                    .accentColor(Color(red: 0.608, green: 0.431, blue: 0.953))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Average Days of Symptoms")
                            .font(.sofiaProHeadline)
                            .foregroundColor(.white)
                        
                        if !hasInteractedWithSymptomDays {
                            Text("Required")
                                .font(.sofiaProCaption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack {
                        Text("\(averageSymptomDays)")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("days")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                    
                    Slider(value: Binding(
                        get: { Double(averageSymptomDays) },
                        set: { 
                            averageSymptomDays = Int($0)
                            hasInteractedWithSymptomDays = true
                        }
                    ), in: 1...10, step: 1)
                    .accentColor(Color(red: 0.608, green: 0.431, blue: 0.953))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            // Initialize with current date if nil
            if lastSymptomsStart == Date(timeIntervalSince1970: 0) {
                lastSymptomsStart = Date()
            }
            // Initialize with default values
            if averageCycleDuration == 0 {
                averageCycleDuration = 28 // Default cycle length
            }
            if averageSymptomDays == 0 {
                averageSymptomDays = 5 // Default symptom days
            }
            // Reset interaction state when view appears
            hasInteractedWithSymptomsStart = false
            hasInteractedWithSymptomCycleDuration = false
            hasInteractedWithSymptomDays = false
        }
    }
}
