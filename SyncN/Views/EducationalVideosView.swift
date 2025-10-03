import SwiftUI
import SwiftData
import TelemetryDeck

struct EducationalVideosView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \VideoProgress.updatedAt, order: .reverse) private var videoProgress: [VideoProgress]
    @State private var selectedEducationClass: EducationClass?
    @State private var showingVideoPlayer = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    private var hormoneEducationClasses: [EducationClass] {
        return EducationClassesData.shared.getHormoneClasses().sorted(by: { $0.order < $1.order })
    }
    
    private var phaseEducationClasses: [EducationClass] {
        return EducationClassesData.shared.getPhaseVideoClasses().sorted(by: { $0.order < $1.order })
    }
    
    private func isVideoCompleted(_ educationClass: EducationClass) -> Bool {
        guard let userProfile = userProfile else { return false }
        
        // Check cache first
        if let cached = CacheManager.shared.getCachedVideoProgress(for: educationClass.title) {
            return cached
        }
        
        // Check database
        let isCompleted = videoProgress.contains { progress in
            progress.userId == userProfile.id && 
            progress.videoTitle == educationClass.title && 
            progress.isCompleted
        }
        
        // Cache the result
        CacheManager.shared.setCachedVideoProgress(educationClass.title, isCompleted: isCompleted)
        
        return isCompleted
    }
    

    var body: some View {
        NavigationView {
            ZStack {
                // Dark navy background
                Color(red: 0.08, green: 0.12, blue: 0.18)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Educational Videos")
                                .font(.custom("Sofia Pro", size: 28, relativeTo: .largeTitle))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Learn about your hormones and cycle phases")
                                .font(.custom("Sofia Pro", size: 16, relativeTo: .subheadline))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Meet Your Hormones Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Meet Your Hormones")
                                .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                ForEach(hormoneEducationClasses, id: \.id) { educationClass in
                                    EducationVideoRow(
                                        educationClass: educationClass,
                                        isCompleted: isVideoCompleted(educationClass)
                                    ) {
                                        TelemetryDeck.signal("Button.Clicked", parameters: [
                                            "buttonType": "education_video",
                                            "videoTitle": educationClass.title,
                                            "location": "educational_videos_view"
                                        ])
                                        selectedEducationClass = educationClass
                                        showingVideoPlayer = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Phase Videos Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Cycle Phase Videos")
                                .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                ForEach(phaseEducationClasses, id: \.id) { educationClass in
                                    EducationVideoRow(
                                        educationClass: educationClass,
                                        isCompleted: isVideoCompleted(educationClass)
                                    ) {
                                        TelemetryDeck.signal("Button.Clicked", parameters: [
                                            "buttonType": "education_video",
                                            "videoTitle": educationClass.title,
                                            "location": "educational_videos_view"
                                        ])
                                        selectedEducationClass = educationClass
                                        showingVideoPlayer = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
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
        .sheet(isPresented: $showingVideoPlayer) {
            if let educationClass = selectedEducationClass {
                EducationVideoPlayerView(educationClass: educationClass)
            }
        }
        .onChange(of: showingVideoPlayer) { _, newValue in
            if !newValue {
                selectedEducationClass = nil
                // Force a refresh of the view to update completion indicators
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This will trigger a view refresh
                    print("🔄 Refreshing video completion status")
                }
            }
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "EducationalVideos",
                "pageType": "education",
                "source": "dashboard"
            ])
        }
    }
}

struct EducationVideoRow: View {
    let educationClass: EducationClass
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Play icon or completion indicator
                ZStack {
                    if isCompleted {
                        // Completed state - checkmark with green background
                        Circle()
                            .fill(Color.green)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        // Not completed - play icon
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(educationClass.title)
                        .font(.custom("Sofia Pro", size: 16, relativeTo: .headline))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text(educationClass.duration)
                            .font(.custom("Sofia Pro", size: 14, relativeTo: .subheadline))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(educationClass.section)
                            .font(.custom("Sofia Pro", size: 12, relativeTo: .caption))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                // Arrow icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(isCompleted ? 
                       Color.green.opacity(0.1) : 
                       Color(red: 0.1, green: 0.12, blue: 0.18))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? 
                           Color.green.opacity(0.3) : 
                           Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EducationalVideosView()
}
