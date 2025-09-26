import SwiftUI
import SwiftData

struct CyclePhaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var selectedPhase: CyclePhase = .follicular
    @State private var showingPhaseDetails = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Phase Navigation Tabs
                        PhaseNavigationTabs(selectedPhase: $selectedPhase)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Hormone Graph
                        HormoneGraphView(selectedPhase: selectedPhase)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        // Phase Details
                        PhaseDetailsView(selectedPhase: selectedPhase, userProfile: userProfile)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        // Hormones & Energy Card
                        HormonesEnergyCard()
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Cycle Phases")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct PhaseNavigationTabs: View {
    @Binding var selectedPhase: CyclePhase
    
    private let phases: [CyclePhase] = [.menstrual, .follicular, .ovulatory, .luteal]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(phases, id: \.self) { phase in
                Button(action: {
                    selectedPhase = phase
                }) {
                    Text(phase.rawValue)
                        .font(.sofiaProSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedPhase == phase ? .purple : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPhase == phase ? Color.white : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct HormoneGraphView: View {
    let selectedPhase: CyclePhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Graph container
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.3))
                    .frame(height: 200)
                
                // Phase highlight
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: phaseWidth, height: 200)
                    .offset(x: phaseOffset)
                
                // Graph lines
                VStack {
                    // Energy level (white line)
                    Path { path in
                        path.move(to: CGPoint(x: 20, y: 160))
                        path.addCurve(
                            to: CGPoint(x: 100, y: 40),
                            control1: CGPoint(x: 50, y: 120),
                            control2: CGPoint(x: 80, y: 60)
                        )
                        path.addCurve(
                            to: CGPoint(x: 180, y: 80),
                            control1: CGPoint(x: 120, y: 20),
                            control2: CGPoint(x: 150, y: 40)
                        )
                        path.addCurve(
                            to: CGPoint(x: 260, y: 140),
                            control1: CGPoint(x: 210, y: 120),
                            control2: CGPoint(x: 240, y: 100)
                        )
                        path.addCurve(
                            to: CGPoint(x: 340, y: 160),
                            control1: CGPoint(x: 280, y: 180),
                            control2: CGPoint(x: 320, y: 180)
                        )
                    }
                    .stroke(Color.white, lineWidth: 3)
                    
                    // Progesterone (light blue line)
                    Path { path in
                        path.move(to: CGPoint(x: 20, y: 180))
                        path.addCurve(
                            to: CGPoint(x: 100, y: 120),
                            control1: CGPoint(x: 50, y: 160),
                            control2: CGPoint(x: 80, y: 140)
                        )
                        path.addCurve(
                            to: CGPoint(x: 180, y: 60),
                            control1: CGPoint(x: 120, y: 100),
                            control2: CGPoint(x: 150, y: 80)
                        )
                        path.addCurve(
                            to: CGPoint(x: 260, y: 40),
                            control1: CGPoint(x: 210, y: 40),
                            control2: CGPoint(x: 240, y: 30)
                        )
                        path.addCurve(
                            to: CGPoint(x: 340, y: 80),
                            control1: CGPoint(x: 280, y: 50),
                            control2: CGPoint(x: 320, y: 60)
                        )
                    }
                    .stroke(Color.blue.opacity(0.7), lineWidth: 2)
                    
                    // Estrogen (darker blue line)
                    Path { path in
                        path.move(to: CGPoint(x: 20, y: 190))
                        path.addCurve(
                            to: CGPoint(x: 100, y: 180),
                            control1: CGPoint(x: 50, y: 185),
                            control2: CGPoint(x: 80, y: 182)
                        )
                        path.addCurve(
                            to: CGPoint(x: 180, y: 170),
                            control1: CGPoint(x: 120, y: 178),
                            control2: CGPoint(x: 150, y: 175)
                        )
                        path.addCurve(
                            to: CGPoint(x: 260, y: 175),
                            control1: CGPoint(x: 210, y: 165),
                            control2: CGPoint(x: 240, y: 170)
                        )
                        path.addCurve(
                            to: CGPoint(x: 340, y: 180),
                            control1: CGPoint(x: 280, y: 180),
                            control2: CGPoint(x: 320, y: 182)
                        )
                    }
                    .stroke(Color.blue, lineWidth: 2)
                    
                    // Testosterone (orange line)
                    Path { path in
                        path.move(to: CGPoint(x: 20, y: 170))
                        path.addCurve(
                            to: CGPoint(x: 100, y: 100),
                            control1: CGPoint(x: 50, y: 140),
                            control2: CGPoint(x: 80, y: 120)
                        )
                        path.addCurve(
                            to: CGPoint(x: 180, y: 80),
                            control1: CGPoint(x: 120, y: 80),
                            control2: CGPoint(x: 150, y: 70)
                        )
                        path.addCurve(
                            to: CGPoint(x: 260, y: 120),
                            control1: CGPoint(x: 210, y: 90),
                            control2: CGPoint(x: 240, y: 100)
                        )
                        path.addCurve(
                            to: CGPoint(x: 340, y: 140),
                            control1: CGPoint(x: 280, y: 140),
                            control2: CGPoint(x: 320, y: 150)
                        )
                    }
                    .stroke(Color.orange, lineWidth: 2)
                }
                .frame(height: 200)
                
                // Current point indicator
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .offset(x: currentPointOffset, y: currentPointY)
            }
        }
    }
    
    private var phaseWidth: CGFloat {
        switch selectedPhase {
        case .menstrual: return 80
        case .follicular: return 80
        case .ovulatory: return 80
        case .luteal: return 80
        case .menstrualMoon: return 80
        case .follicularMoon: return 80
        case .ovulatoryMoon: return 80
        case .lutealMoon: return 80
        }
    }
    
    private var phaseOffset: CGFloat {
        switch selectedPhase {
        case .menstrual: return -120
        case .follicular: return -40
        case .ovulatory: return 40
        case .luteal: return 120
        case .menstrualMoon: return -120
        case .follicularMoon: return -40
        case .ovulatoryMoon: return 40
        case .lutealMoon: return 120
        }
    }
    
    private var currentPointOffset: CGFloat {
        switch selectedPhase {
        case .menstrual: return -120
        case .follicular: return -40
        case .ovulatory: return 40
        case .luteal: return 120
        case .menstrualMoon: return -120
        case .follicularMoon: return -40
        case .ovulatoryMoon: return 40
        case .lutealMoon: return 120
        }
    }
    
    private var currentPointY: CGFloat {
        switch selectedPhase {
        case .menstrual: return 60
        case .follicular: return 40
        case .ovulatory: return 80
        case .luteal: return 140
        case .menstrualMoon: return 60
        case .follicularMoon: return 40
        case .ovulatoryMoon: return 80
        case .lutealMoon: return 140
        }
    }
}

struct PhaseDetailsView: View {
    let selectedPhase: CyclePhase
    let userProfile: UserProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(phaseDateRange)
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(selectedPhase.rawValue)
                        .font(.sofiaProTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Navigation arrows
                HStack(spacing: 12) {
                    Button(action: {
                        // Navigate to previous phase
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.sofiaProTitle2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        // Navigate to next phase
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.sofiaProTitle2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    private var phaseDateRange: String {
        guard let userProfile = userProfile else { return "Phase dates" }
        
        let _ = Calendar.current
        let _ = Date()
        let _ = userProfile.cycleDay
        
        switch selectedPhase {
        case .menstrual:
            return "1st phase (Days 1-5)"
        case .follicular:
            return "2nd phase (Days 6-14)"
        case .ovulatory:
            return "3rd phase (Days 15-17)"
        case .luteal:
            return "4th phase (Days 18-28)"
        case .menstrualMoon:
            return "1st phase (Days 1-5)"
        case .follicularMoon:
            return "2nd phase (Days 6-14)"
        case .ovulatoryMoon:
            return "3rd phase (Days 15-17)"
        case .lutealMoon:
            return "4th phase (Days 18-28)"
        }
    }
}

struct HormonesEnergyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Hormones & energy")
                    .font(.sofiaProHeadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        // Show information
                    }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Expand view
                    }) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            
            VStack(spacing: 12) {
                HormoneLegendItem(color: .white, name: "Energy level")
                HormoneLegendItem(color: .blue.opacity(0.7), name: "Progesterone")
                HormoneLegendItem(color: .blue, name: "Estrogen")
                HormoneLegendItem(color: .orange, name: "Testosterone")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.4))
        )
    }
}

struct HormoneLegendItem: View {
    let color: Color
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "triangle.fill")
                .font(.sofiaProCaption)
                .foregroundColor(color)
            
            Text(name)
                .font(.sofiaProSubheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    CyclePhaseView()
        .modelContainer(for: [UserProfile.self, Workout.self, Progress.self, Exercise.self, WeeklyFitnessPlanEntry.self, DailyHabitEntry.self], inMemory: true)
}