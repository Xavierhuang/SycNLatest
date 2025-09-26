import SwiftUI
import AVKit
import SwiftData
import AVFoundation

struct EducationVideoPlayerView: View {
    let educationClass: EducationClass
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var videoProgress: [VideoProgress]
    @State private var player: AVPlayer?
    @State private var hasTrackedWatching = false
    @State private var hasTrackedCompletion = false
    @State private var playbackTimer: Timer?
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Video Player
                if let player = player {
                    VideoPlayer(player: player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .onAppear {
                            player.play()
                            setupVideoTracking()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading video...")
                            .font(.custom("Sofia Pro", size: 16))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
                
                // Video Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(educationClass.title)
                        .font(.custom("Sofia Pro", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(educationClass.duration)
                            .font(.custom("Sofia Pro", size: 16))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(educationClass.section)
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
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
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            playbackTimer?.invalidate()
            playbackTimer = nil
            player = nil
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: educationClass.videoURL) else {
            print("❌ Invalid video URL: \(educationClass.videoURL)")
            return
        }
        
        player = AVPlayer(url: url)
        
        // Enable AirPlay for educational videos
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
    }
    
    private func setupVideoTracking() {
        guard let player = player,
              let userProfile = userProfile else { return }
        
        // Start a timer to check playback progress every second
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkPlaybackProgress()
        }
    }
    
    private func checkPlaybackProgress() {
        guard let player = player,
              let userProfile = userProfile else { return }
        
        let currentTime = player.currentTime()
        let currentTimeSeconds = CMTimeGetSeconds(currentTime)
        
        // Track "watching" after 10 seconds (for initial engagement)
        if !hasTrackedWatching && currentTimeSeconds >= 10.0 {
            hasTrackedWatching = true
        }
        
        // Track completion when video is 90% watched or reaches the end
        if let duration = player.currentItem?.duration,
           !hasTrackedCompletion {
            let totalSeconds = CMTimeGetSeconds(duration)
            
            if totalSeconds > 0 {
                let progress = currentTimeSeconds / totalSeconds
                
                // Mark as completed if 90% watched or reached the end
                if progress >= 0.9 || currentTimeSeconds >= (totalSeconds - 1.0) {
                    hasTrackedCompletion = true
                    trackVideoCompletion()
                }
            }
        }
    }
    
    private func trackVideoCompletion() {
        guard let userProfile = userProfile else { return }
        
        // Track individual video completion
        markVideoAsCompleted(userProfile: userProfile)
        
        // Determine if this is a hormone or phase video based on section
        let isHormoneVideo = educationClass.section.lowercased().contains("hormone") || 
                           educationClass.section.lowercased().contains("meet your")
        let isPhaseVideo = educationClass.section.lowercased().contains("phase") ||
                          educationClass.section.lowercased().contains("cycle")
        
        
        if isHormoneVideo {
            CharmManager.shared.checkAndMarkHormoneVideosComplete(for: userProfile, in: modelContext)
        } else if isPhaseVideo {
            CharmManager.shared.checkAndMarkPhaseVideosComplete(for: userProfile, in: modelContext)
        }
    }
    
    private func markVideoAsCompleted(userProfile: UserProfile) {
        // Find existing video progress or create new one
        let existingProgress = videoProgress.first { progress in
            progress.userId == userProfile.id && progress.videoTitle == educationClass.title
        }
        
        if let progress = existingProgress {
            if !progress.isCompleted {
                progress.markAsCompleted()
            }
        } else {
            // Create new video progress
            let newProgress = VideoProgress(
                userId: userProfile.id,
                videoId: educationClass.id,
                videoTitle: educationClass.title
            )
            newProgress.markAsCompleted()
            modelContext.insert(newProgress)
        }
        
        do {
            try modelContext.save()
            
            // Invalidate video progress cache since we updated data
            CacheManager.shared.invalidateVideoProgressCache()
        } catch {
            print("❌ Error saving video progress: \(error)")
        }
    }
}

#Preview {
    EducationVideoPlayerView(
        educationClass: EducationClass(
            title: "Meet Your Menstrual Cycle",
            duration: "2 min",
            order: 1,
            section: "Meet Your Hormones",
            videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Meet%20your%20Menstrual%20Cycle.mp4"
        )
    )
}
