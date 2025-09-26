import SwiftUI
import SwiftData

struct NewOnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    @State private var currentStep = 0
    @State private var hasSeenWelcome = false
    @State private var hasCompletedPersonalization = false
    @State private var hasCompletedCycleOnboarding = false
    
    let onComplete: () -> Void
    private let totalSteps = 1 // Welcome only
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.11, blue: 0.17)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                if currentStep > 0 {
                    HStack {
                        ForEach(0..<totalSteps, id: \.self) { step in
                            Circle()
                                .fill(step <= currentStep ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                            
                            if step < totalSteps - 1 {
                                Rectangle()
                                    .fill(step < currentStep ? Color(red: 0.608, green: 0.431, blue: 0.953) : Color.white.opacity(0.3))
                                    .frame(height: 2)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                
                // Content
                TabView(selection: $currentStep) {
                    // Step 0: Welcome/Privacy Screen
                    WelcomeView(onGetStarted: {
                        print("🔍 NewOnboardingFlowView: onGetStarted callback received")
                        // Go directly to main app after welcome screen
                        print("🔍 NewOnboardingFlowView: Calling onComplete callback")
                        onComplete()
                    })
                    .tag(0)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .onAppear {
            // Always go to main app - no need to check completion status
            // The main dashboard will handle showing the appropriate personalization steps
        }
    }
}

#Preview {
    NewOnboardingFlowView(onComplete: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
}
