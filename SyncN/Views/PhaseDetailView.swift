import SwiftUI
import SwiftData
import AVKit
import TelemetryDeck

struct PhaseDetailView: View {
    let phaseInfo: PhaseInfo
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var showingVideo = false
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    init(phaseInfo: PhaseInfo) {
        self.phaseInfo = phaseInfo
    }
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Phase Title and Season
                        VStack(spacing: 8) {
                            Text(phaseInfo.name.capitalized)
                                .font(.custom("Sofia Pro", size: 32))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text(phaseInfo.season.capitalized)
                                    .font(.custom("Sofia Pro", size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text(phaseInfo.phaseDurationDays)
                                    .font(.custom("Sofia Pro", size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        // Affirmation
                        VStack(spacing: 8) {
                            Text("Daily Affirmation")
                                .font(.custom("Sofia Pro", size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            Text(phaseInfo.affirmation)
                                .font(.custom("Sofia Pro", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .italic()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Video Section
                    VStack(spacing: 12) {
                        Button(action: {
                            showingVideo = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(
                                        colors: [phaseColor.opacity(0.8), phaseColor.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(height: 200)
                                
                                VStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.white.opacity(0.9))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "play.fill")
                                                .font(.title)
                                                .foregroundColor(phaseColor)
                                        )
                                    
                                    Text("Watch Phase Video")
                                        .font(.custom("Sofia Pro", size: 16))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Hormone Chart Section
                    if let userProfile = userProfile {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Your Cycle Phase", icon: "waveform.path.ecg")
                            
                            HormoneChartView(
                                currentPhase: cyclePhaseForPhaseInfo,
                                userProfile: userProfile
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Energy & Intensity Section
                    VStack(spacing: 16) {
                        InfoCard(
                            title: "Energy Level",
                            content: phaseInfo.energy.capitalized,
                            icon: "bolt.fill",
                            color: .yellow
                        )
                        
                        InfoCard(
                            title: "Workout Intensity",
                            content: phaseInfo.intensity,
                            icon: "figure.strengthtraining.traditional",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Movement Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Movement & Exercise", icon: "figure.run")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(phaseInfo.movementDescription)
                                .font(.custom("Sofia Pro", size: 16))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Nutrition Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Nutrition Recommendations", icon: "leaf.fill")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(phaseInfo.foodRec, id: \.self) { food in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 8)
                                    
                                    Text(food)
                                        .font(.custom("Sofia Pro", size: 16))
                                        .foregroundColor(.white)
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Body & Emotions Section
                    VStack(spacing: 16) {
                        InfoSection(
                            title: "How Your Body Feels",
                            items: phaseInfo.bodyFeel.filter { !$0.isEmpty },
                            icon: "heart.fill",
                            color: .red
                        )
                        
                        InfoSection(
                            title: "Emotional State",
                            items: phaseInfo.emotions,
                            icon: "brain.head.profile",
                            color: .purple
                        )
                        
                        InfoSection(
                            title: "Hormonal Changes",
                            items: phaseInfo.hormones,
                            icon: "waveform.path.ecg",
                            color: .blue
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Tips Section (if available)
                    if !phaseInfo.tips.isEmpty && phaseInfo.tips != "thing" {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Pro Tips", icon: "lightbulb.fill")
                            
                            Text(phaseInfo.tips)
                                .font(.custom("Sofia Pro", size: 16))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Bottom spacing
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingVideo) {
            EducationVideoPlayerView(
                educationClass: EducationClass(
                    title: "\(phaseInfo.name.capitalized) Phase Video",
                    duration: "2-3 min",
                    order: 1,
                    section: "Phase Video",
                    videoURL: phaseInfo.mediaVideo
                )
            )
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "PhaseDetail",
                "pageType": "cycle_feature",
                "phase": phaseInfo.name
            ])
        }
    }
    
    private var phaseColor: Color {
        switch phaseInfo.name.lowercased() {
        case "menstrual":
            return .red
        case "follicular":
            return .blue
        case "ovulation":
            return .purple
        case "luteal":
            return .orange
        default:
            return .gray
        }
    }
    
    private var cyclePhaseForPhaseInfo: CyclePhase {
        switch phaseInfo.name.lowercased() {
        case "menstrual":
            return .menstrual
        case "follicular":
            return .follicular
        case "ovulation":
            return .ovulatory
        case "luteal":
            return .luteal
        default:
            return .follicular
        }
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Text(title)
                .font(.custom("Sofia Pro", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

struct InfoCard: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Sofia Pro", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(content)
                    .font(.custom("Sofia Pro", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct InfoSection: View {
    let title: String
    let items: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, icon: icon)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        
                        Text(item)
                            .font(.custom("Sofia Pro", size: 16))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

#Preview {
    PhaseDetailView(
        phaseInfo: PhaseInfoData.shared.getAllPhases().first!
    )
}
