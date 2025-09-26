import SwiftUI
import SwiftData

struct SplashScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var isActive = false
    @State private var showOnboarding = false
    
    var body: some View {
        if isActive {
            if showOnboarding {
                NewOnboardingFlowView(onComplete: {
                    print("🔍 SplashScreenView: onComplete callback received")
                    withAnimation(.easeInOut(duration: 0.5)) {
                        print("🔍 SplashScreenView: Setting showOnboarding to false")
                        showOnboarding = false
                    }
                })
            } else {
                MainTabView()
            }
        } else {
            ZStack {
                // Dark background color for extra space around centered logo
                Color.black
                    .ignoresSafeArea()
                
                // Splash image - centered both horizontally and vertically
                Image(splashImageNameForPhase(cyclePhaseForUser()))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .onAppear {
                // Show splash screen for 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        // Check if user needs onboarding
                        let needsOnboarding = shouldShowOnboarding()
                        showOnboarding = needsOnboarding
                        isActive = true
                    }
                }
            }
        }
    }
    
    private func shouldShowOnboarding() -> Bool {
        // Check if user has seen the welcome screen before
        let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        print("🔍 SplashScreenView: hasSeenWelcome = \(hasSeenWelcome)")
        let shouldShow = !hasSeenWelcome
        print("🔍 SplashScreenView: shouldShowOnboarding = \(shouldShow)")
        return shouldShow
    }
    
    private func cyclePhaseForUser() -> CyclePhase {
        guard let userProfile = userProfiles.first else {
            return .follicular // Default phase
        }
        return userProfile.currentCyclePhase ?? .follicular
    }
    
    private func splashImageNameForPhase(_ phase: CyclePhase) -> String {
        switch phase {
        case .follicular:
            return "follicular splash"
        case .ovulatory:
            return "ovulation splash"
        case .luteal:
            return "luteal splash"
        case .menstrual:
            return "menstrual splash"
        case .follicularMoon:
            return "follicular splash"
        case .ovulatoryMoon:
            return "ovulation splash"
        case .lutealMoon:
            return "luteal splash"
        case .menstrualMoon:
            return "menstrual splash"
        }
    }
}

extension CyclePhase {
    var backgroundColor: UIColor {
        switch self {
        case .follicular:
            return UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0) // Blue
        case .ovulatory:
            return UIColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1.0) // Pink
        case .luteal:
            return UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0) // Purple
        case .menstrual:
            return UIColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1.0) // Red
        case .follicularMoon:
            return UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0) // Blue (same as follicular)
        case .ovulatoryMoon:
            return UIColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1.0) // Pink (same as ovulatory)
        case .lutealMoon:
            return UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0) // Purple (same as luteal)
        case .menstrualMoon:
            return UIColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1.0) // Red (same as menstrual)
        }
    }
}

#Preview {
    SplashScreenView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}