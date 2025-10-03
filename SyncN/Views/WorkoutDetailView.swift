import SwiftUI
import SwiftData
import AVKit
import TelemetryDeck

struct WeeklyWorkoutDetailView: View {
    let workout: WeeklyFitnessPlanEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var videoPlayerData: (url: String, isPresented: Bool)? = nil
    @State private var rewardsManager: RewardsManager?
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    // Check if this is a custom workout
    private var isCustomWorkout: Bool {
        return workout.workoutDescription.hasPrefix("Custom workout:") || workout.instructor == "You"
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Header with workout icon and title
                    HStack(spacing: 16) {
                        // Workout type icon
                        Image(systemName: iconForWorkoutType(workout.workoutType))
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                            .frame(width: 50, height: 50)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.workoutTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(workout.workoutType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(workout.workoutDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    // Key details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            DetailRow(icon: "clock", title: "Duration", value: "\(workout.duration) min")
                            DetailRow(icon: "calendar", title: "Phase", value: workout.cyclePhase.displayName)
                            if let instructor = workout.instructor {
                                DetailRow(icon: "person", title: "Instructor", value: instructor)
                            }
                            DetailRow(icon: workout.isVideo ? "video" : "waveform", title: "Format", value: workout.isVideo ? "Video" : "Audio")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Benefits
                    if !workout.benefits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Benefits")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(workout.benefits, id: \.self) { benefit in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.subheadline)
                                        
                                        Text(benefit)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Equipment
                    if !workout.equipment.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Equipment")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            Text(workout.equipment.joined(separator: ", "))
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Action button - Different states for custom workouts
                    if isCustomWorkout {
                        if workout.status == .confirmed {
                            // Completed state - show as completed
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.headline)
                                
                                Text("Completed")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                        } else {
                            // Not completed state - faded green
                            Button(action: {
                                TelemetryDeck.signal("Button.Clicked", parameters: [
                                    "buttonType": "workout_complete",
                                    "workoutTitle": workout.workoutTitle,
                                    "workoutType": "custom"
                                ])
                                markWorkoutAsCompleted()
                                // Dismiss the view after marking as completed
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.headline)
                                    
                                    Text("Mark as Complete")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.7))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                        }
                    } else {
                        // SyncN workout - start button
                        Button(action: {
                            TelemetryDeck.signal("Button.Clicked", parameters: [
                                "buttonType": "workout_start",
                                "workoutTitle": workout.workoutTitle,
                                "workoutType": "syncn"
                            ])
                            startWorkout()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.headline)
                                
                                Text("Start Workout")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
        .fullScreenCover(isPresented: Binding(
            get: { videoPlayerData?.isPresented ?? false },
            set: { newValue in
                if !newValue {
                    videoPlayerData = nil
                }
            }
        )) {
            if let videoPlayerData = videoPlayerData, let videoURL = URL(string: videoPlayerData.url) {
                WeeklyVideoPlayerView(
                    videoURL: videoURL, 
                    workoutTitle: workout.workoutTitle,
                    workout: workout,
                    onWorkoutCompleted: { completed in
                        if completed {
                            markWorkoutAsCompleted()
                        }
                    },
                    onNavigateToMain: {
                        // Post notification to navigate to main page with workout info for rating
                        NotificationCenter.default.post(
                            name: .navigateToMainPage, 
                            object: nil,
                            userInfo: [
                                "workoutTitle": workout.workoutTitle,
                                "instructor": workout.instructor ?? "",
                                "workoutId": workout.id.uuidString,
                                "workoutDate": workout.date
                            ]
                        )
                        // Also dismiss the current view
                        dismiss()
                    }
                )
            } else {
                // Fallback view if no media URL is available
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("No Media Available")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("This workout doesn't have video or audio content available.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Close") {
                        self.videoPlayerData = nil
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .onAppear {
            // Initialize rewards manager
            rewardsManager = RewardsManager(modelContext: modelContext)
            
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "WorkoutDetail",
                "pageType": "workout_feature",
                "workoutTitle": workout.workoutTitle
            ])
        }
    }
    
    private func startWorkout() {
        print("🎬 Start Workout clicked for: \(workout.workoutTitle)")
        print("🎬 Workout videoURL: \(workout.videoURL ?? "nil")")
        print("🎬 Workout audioURL: \(workout.audioURL ?? "nil")")
        print("🎬 Workout isVideo: \(workout.isVideo)")
        print("🎬 Current videoPlayerData state: \(videoPlayerData?.url ?? "nil")")
        
        // Track workout start engagement
        TelemetryDeck.signal("Workout.Started", parameters: [
            "workoutTitle": workout.workoutTitle,
            "workoutType": workout.workoutType.rawValue,
            "duration": "\(workout.duration)",
            "cyclePhase": workout.cyclePhase.rawValue,
            "instructor": workout.instructor ?? "Unknown",
            "hasVideo": workout.isVideo ? "true" : "false",
            "hasAudio": (workout.audioURL != nil) ? "true" : "false",
            "isCustomWorkout": isCustomWorkout ? "true" : "false"
        ])
        
        // Check if workout has a video URL or audio URL
        var mediaURLString: String?
        
        // TEMPORARY FIX: Check for incorrect video URLs and fix them
        if workout.workoutTitle.contains("Dance Cardio") && 
           (workout.videoURL == nil || workout.videoURL == "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Dance%20Cardio.mp4") {
            // Use the correct existing Dance Cardio video name
            mediaURLString = "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//im%20Dance%20Cardio%20Affirmations%20Blast.mp4"
            print("🎬 TEMP FIX: Fixed incorrect Dance Cardio video URL")
            
            // Update the workout entry in the database
            workout.videoURL = mediaURLString
            workout.isVideo = true
            try? modelContext.save()
            print("🎬 TEMP FIX: Updated workout in database with correct URL")
        } else if let videoURLString = workout.videoURL, !videoURLString.isEmpty {
            mediaURLString = videoURLString
            print("🎬 Found video URL string: \(videoURLString)")
        } else if let audioURLString = workout.audioURL, !audioURLString.isEmpty {
            mediaURLString = audioURLString
            print("🎬 Found audio URL string: \(audioURLString)")
        }
        
        if let mediaURL = mediaURLString {
            // Set both URL and presentation state atomically
            self.videoPlayerData = (url: mediaURL, isPresented: true)
            print("🎬 Set videoPlayerData to: \(self.videoPlayerData?.url ?? "nil")")
        } else {
            // No media URL available
            print("🎬 No media URL available for workout: \(workout.workoutTitle)")
            print("🎬 This workout has no video or audio content")
            // You could show an alert here if needed
        }
    }
    
    private func markWorkoutAsCompleted() {
        print("✅ Marking workout as completed: \(workout.workoutTitle)")
        
        // Track workout completion engagement
        TelemetryDeck.signal("Workout.Completed", parameters: [
            "workoutTitle": workout.workoutTitle,
            "workoutType": workout.workoutType.rawValue,
            "duration": "\(workout.duration)",
            "cyclePhase": workout.cyclePhase.rawValue,
            "instructor": workout.instructor ?? "Unknown",
            "isCustomWorkout": isCustomWorkout ? "true" : "false",
            "completionMethod": "manual_mark_complete"
        ])
        
        // Update the workout status to completed
        workout.status = .confirmed
        
        // Save to SwiftData context
        do {
            try modelContext.save()
            print("✅ Workout completion saved to SwiftData")
            
            // Track weekly plan acceptance for charm system
            if let userProfile = userProfile {
                CharmManager.shared.markWeeklyPlanAccepted(for: userProfile, in: modelContext)
            }
            
            // Update rewards and stats
            if let rewardsManager = rewardsManager {
                rewardsManager.completeWorkout()
                rewardsManager.addPoints(10) // Award 10 points per workout
            }
            
            // For custom workouts, trigger rating popup after completion
            if isCustomWorkout {
                // Post notification to show rating popup
                NotificationCenter.default.post(
                    name: .navigateToMainPage, 
                    object: nil,
                    userInfo: [
                        "workoutTitle": workout.workoutTitle,
                        "instructor": workout.instructor ?? "You",
                        "workoutId": workout.id.uuidString,
                        "workoutDate": workout.date
                    ]
                )
            }
        } catch {
            print("❌ Failed to save workout completion: \(error)")
        }
    }
    
    private func iconForWorkoutType(_ type: WorkoutType) -> String {
        switch type {
        case .yoga:
            return "figure.mind.and.body"
        case .pilates:
            return "figure.core.training"
        case .hiit:
            return "figure.highintensity.intervaltraining"
        case .strength:
            return "dumbbell.fill"
        case .cardio:
            return "heart.circle.fill"
        case .dance:
            return "music.note"
        case .meditation:
            return "brain.head.profile"
        case .stretching:
            return "figure.flexibility"
        case .boxing:
            return "figure.boxing"
        case .walking:
            return "figure.walk"
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct WeeklyVideoPlayerView: View {
    let videoURL: URL
    let workoutTitle: String
    let workout: WeeklyFitnessPlanEntry
    let onWorkoutCompleted: (Bool) -> Void
    let onNavigateToMain: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var videoPlayer = WeeklyVideoPlayerViewModel()
    @State private var showingCompletionDialog = false
    
    init(videoURL: URL, workoutTitle: String, workout: WeeklyFitnessPlanEntry, onWorkoutCompleted: @escaping (Bool) -> Void, onNavigateToMain: (() -> Void)? = nil) {
        self.videoURL = videoURL
        self.workoutTitle = workoutTitle
        self.workout = workout
        self.onWorkoutCompleted = onWorkoutCompleted
        self.onNavigateToMain = onNavigateToMain
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let player = videoPlayer.player, !videoPlayer.isLoading {
                    VideoPlayer(player: player)
                        .onAppear {
                            print("🎬 VideoPlayer appeared, starting playback")
                            player.play()
                        }
                        .onDisappear {
                            print("🎬 VideoPlayer disappeared, pausing playback")
                            player.pause()
                        }
                } else if let error = videoPlayer.errorMessage {
                    // Error state
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        
                        Text(workout.isVideo ? "Video Failed to Load" : "Audio Failed to Load")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("URL: \(videoURL.absoluteString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            TelemetryDeck.signal("Button.Clicked", parameters: [
                                "buttonType": "video_retry",
                                "workoutTitle": workoutTitle
                            ])
                            videoPlayer.setupVideoPlayer(url: videoURL.absoluteString)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Loading state
                    VStack(spacing: 20) {
                        Image(systemName: "video")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        Text(workout.isVideo ? "Loading Video..." : "Loading Audio...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(workout.isVideo ? "Setting up video player..." : "Setting up audio player...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("URL: \(videoURL.absoluteString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(workout.isVideo ? workoutTitle : "\(workoutTitle) (Audio)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .overlay(alignment: .topTrailing) {
                Button("Done") {
                    TelemetryDeck.signal("Button.Clicked", parameters: [
                        "buttonType": "video_done",
                        "workoutTitle": workoutTitle
                    ])
                    videoPlayer.player?.pause()
                    showingCompletionDialog = true
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
        }
        .onAppear {
            print("🎬 WeeklyVideoPlayerView appeared")
            videoPlayer.setupVideoPlayer(url: videoURL.absoluteString)
        }
        .onDisappear {
            print("🎬 WeeklyVideoPlayerView disappeared")
            videoPlayer.cleanup()
        }
        .alert("Workout Complete?", isPresented: $showingCompletionDialog) {
            Button("Yes, I finished") {
                TelemetryDeck.signal("Button.Clicked", parameters: [
                    "buttonType": "workout_completion_dialog",
                    "action": "finished",
                    "workoutTitle": workoutTitle
                ])
                
                // Track workout completion from video player
                TelemetryDeck.signal("Workout.Completed", parameters: [
                    "workoutTitle": workoutTitle,
                    "workoutType": workout.workoutType.rawValue,
                    "duration": "\(workout.duration)",
                    "cyclePhase": workout.cyclePhase.rawValue,
                    "instructor": workout.instructor ?? "Unknown",
                    "isCustomWorkout": (workout.workoutDescription.hasPrefix("Custom workout:") || workout.instructor == "You") ? "true" : "false",
                    "completionMethod": "video_player_finished"
                ])
                
                onWorkoutCompleted(true)
                if let onNavigateToMain = onNavigateToMain {
                    onNavigateToMain()
                } else {
                    dismiss()
                }
            }
            Button("No, not yet") {
                TelemetryDeck.signal("Button.Clicked", parameters: [
                    "buttonType": "workout_completion_dialog",
                    "action": "not_finished",
                    "workoutTitle": workoutTitle
                ])
                
                // Track workout abandonment
                TelemetryDeck.signal("Workout.Abandoned", parameters: [
                    "workoutTitle": workoutTitle,
                    "workoutType": workout.workoutType.rawValue,
                    "duration": "\(workout.duration)",
                    "cyclePhase": workout.cyclePhase.rawValue,
                    "instructor": workout.instructor ?? "Unknown",
                    "isCustomWorkout": (workout.workoutDescription.hasPrefix("Custom workout:") || workout.instructor == "You") ? "true" : "false",
                    "abandonmentPoint": "video_player_dialog"
                ])
                
                onWorkoutCompleted(false)
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                TelemetryDeck.signal("Button.Clicked", parameters: [
                    "buttonType": "workout_completion_dialog",
                    "action": "cancel",
                    "workoutTitle": workoutTitle
                ])
                
                // Track workout abandonment
                TelemetryDeck.signal("Workout.Abandoned", parameters: [
                    "workoutTitle": workoutTitle,
                    "workoutType": workout.workoutType.rawValue,
                    "duration": "\(workout.duration)",
                    "cyclePhase": workout.cyclePhase.rawValue,
                    "instructor": workout.instructor ?? "Unknown",
                    "isCustomWorkout": (workout.workoutDescription.hasPrefix("Custom workout:") || workout.instructor == "You") ? "true" : "false",
                    "abandonmentPoint": "video_player_cancel"
                ])
                
                // Do nothing, stay in video player
            }
        } message: {
            Text("Did you complete the \(workoutTitle) workout?")
        }
    }
}

// MARK: - Weekly Video Player View Model
class WeeklyVideoPlayerViewModel: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    func setupVideoPlayer(url: String) {
        isLoading = true
        errorMessage = nil
        
        print("🎥 Setting up video player for URL: \(url)")
        
        // Check if we have a preloaded player for this URL
        if let preloadedPlayer = CacheManager.shared.getPreloadedPlayer(for: url) {
            print("✅ Using preloaded video player for faster loading")
            self.player = preloadedPlayer
            self.isLoading = false
            // Remove from preload cache since we're now using it
            CacheManager.shared.removePreloadedPlayer(for: url)
            return
        }
        
        guard let videoURL = URL(string: url) else {
            errorMessage = "Invalid video URL"
            isLoading = false
            print("❌ Invalid video URL: \(url)")
            return
        }
        
        print("✅ Video URL is valid: \(videoURL)")
        
        // Test URL accessibility first
        testURLAccessibility(url: videoURL) { [weak self] isAccessible in
            DispatchQueue.main.async {
                if isAccessible {
                    self?.createVideoPlayer(url: videoURL)
                } else {
                    self?.errorMessage = "Video file not accessible. Please check the URL."
                    self?.isLoading = false
                    print("❌ Video URL not accessible: \(videoURL)")
                }
            }
        }
    }
    
    private func testURLAccessibility(url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                let isAccessible = httpResponse.statusCode == 200
                print("🌐 Video URL accessibility test: \(isAccessible ? "✅" : "❌") Status: \(httpResponse.statusCode)")
                completion(isAccessible)
            } else {
                print("❌ Video URL accessibility test failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }.resume()
    }
    
    private func createVideoPlayer(url: URL) {
        // Create player item with optimized settings for faster loading
        let playerItem = AVPlayerItem(url: url)
        
        // Optimize for faster streaming and loading
        playerItem.preferredForwardBufferDuration = 5.0 // Buffer 5 seconds ahead
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        playerItem.preferredPeakBitRate = 0 // Let AVPlayer choose optimal bitrate
        
        // Enable automatic quality adjustment for faster startup
        if #available(iOS 15.0, *) {
            playerItem.startsOnFirstEligibleVariant = true
        }
        
        player = AVPlayer(playerItem: playerItem)
        
        // Optimize player settings for faster loading
        player?.automaticallyWaitsToMinimizeStalling = false // Start playing ASAP
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        
        // Start loading the video content for faster playback
        player?.seek(to: .zero) { [weak self] finished in
            DispatchQueue.main.async {
                if finished {
                    print("✅ Video loading initiated successfully")
                } else {
                    print("⚠️ Video loading was interrupted")
                }
                self?.isLoading = false
            }
        }
        
        // Add status observation
        playerItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        
        // Simple retry logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🎬 Attempting to play video...")
            self.player?.play()
            self.isLoading = false
            print("✅ Video play command sent")
        }
    }
    
    func cleanup() {
        player?.pause()
        player = nil
    }
    
    // Add KVO observation for video
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                print("📊 Video player status changed: \(playerItem.status.rawValue)")
                switch playerItem.status {
                case .readyToPlay:
                    print("✅ Video is ready to play")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        // Auto-start playback when ready
                        self.player?.play()
                        print("🎬 Auto-started video playback")
                    }
                case .failed:
                    print("❌ Video failed to load: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    errorMessage = "Failed to load video: \(playerItem.error?.localizedDescription ?? "Unknown error")"
                    isLoading = false
                case .unknown:
                    print("❓ Video status unknown")
                @unknown default:
                    print("❓ Unknown video status")
                }
            }
        }
    }
}
