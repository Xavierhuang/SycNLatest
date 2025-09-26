import SwiftUI
import SwiftData
import AVKit
import AVFoundation
import TelemetryDeck

struct WorkoutLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var selectedPhase: CyclePhase?
    @State private var selectedWorkoutType: WorkoutType?
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0 for SyncN, 1 for My workouts
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var filteredWorkouts: [Workout] {
        var workouts = getSampleWorkouts()
        
        if let phase = selectedPhase {
            workouts = workouts.filter { $0.cyclePhase == phase }
        }
        
        if let type = selectedWorkoutType {
            workouts = workouts.filter { $0.workoutType == type }
        }
        
        if !searchText.isEmpty {
            workouts = workouts.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.workoutDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return workouts
    }
    
    var filteredCustomWorkouts: [CustomWorkout] {
        var customWorkouts = userProfile?.customWorkouts ?? []
        
        if !searchText.isEmpty {
            customWorkouts = customWorkouts.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.activityType.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return customWorkouts
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                HStack(spacing: 0) {
                    TabButton(
                        title: "SyncN",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "My workouts",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Filter chips (only show for SyncN tab)
                if selectedTab == 0 {
                    FilterChipsView(
                        selectedPhase: $selectedPhase,
                        selectedWorkoutType: $selectedWorkoutType
                    )
                    .padding(.horizontal)
                }
                
                // Content based on selected tab
                if selectedTab == 0 {
                    // SyncN workouts
                    ScrollView {
                        VStack(spacing: 20) {
                            // Recommended for you section
                            if let userProfile = userProfile {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recommended for You")
                                        .font(.sofiaProHeadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            let recommendations = SwiftFitnessRecommendationEngine.shared.generateWeeklyFitnessPlan(for: userProfile, startDate: Date(), userPreferences: UserPreferences(from: userProfile.personalizationData ?? PersonalizationData(userId: UUID())))
                                            ForEach(recommendations, id: \.id) { planEntry in
                                                let workout = Workout(
                                                    title: planEntry.workoutTitle,
                                                    description: planEntry.workoutDescription,
                                                    duration: planEntry.duration,
                                                    workoutType: planEntry.workoutType,
                                                    cyclePhase: planEntry.cyclePhase,
                                                    difficulty: planEntry.difficulty,
                                                    instructor: planEntry.instructor
                                                )
                                                WorkoutLibraryCard(workout: workout)
                                                    .frame(width: 160)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // All workouts grid
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                ForEach(filteredWorkouts, id: \.id) { workout in
                                    WorkoutLibraryCard(workout: workout)
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    // Your custom workouts
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ForEach(filteredCustomWorkouts, id: \.id) { customWorkout in
                                CustomWorkoutCard(customWorkout: customWorkout)
                            }
                        }
                        .padding()
                        
                        // Empty state
                        if filteredCustomWorkouts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("No custom workouts yet")
                                    .font(.sofiaProHeadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Create your first custom workout to see it here")
                                    .font(.sofiaProCaption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 50)
                        }
                    }
                }
            }
            .navigationTitle("Workout Library")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "WorkoutLibrary",
                "pageType": "workout_feature"
            ])
        }
    }
    
    private func getSampleWorkouts() -> [Workout] {
        var workouts = WorkoutData.getSampleWorkouts()
        
        // Add fitness classes from the recommendation engine
        let fitnessClasses = FitnessClassesManager.shared.getAllClasses()
        let recommendationWorkouts = fitnessClasses.map { fitnessClass in
            Workout(
                title: fitnessClass.className,
                description: "Recommended workout for your current cycle phase",
                duration: parseDuration(fitnessClass.duration),
                workoutType: WorkoutType(rawValue: fitnessClass.types.first ?? "Cardio") ?? .cardio,
                cyclePhase: mapCyclePhase(fitnessClass.phases.first ?? "follicular"),
                difficulty: .intermediate,
                instructor: fitnessClass.instructor
            )
        }
        
        workouts.append(contentsOf: recommendationWorkouts)
        return workouts
    }
    
    private func parseDuration(_ durationString: String) -> Int {
        let numbers = durationString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.first ?? 30
    }
    
    private func mapCyclePhase(_ phase: String) -> CyclePhase {
        switch phase.lowercased() {
        case "menstrual":
            return .menstrual
        case "follicular":
            return .follicular
        case "ovulatory", "ovulation":
            return .ovulatory
        case "luteal":
            return .luteal
        case "menstrual moon":
            return .menstrualMoon
        case "follicular moon":
            return .follicularMoon
        case "ovulatory moon", "ovulation moon":
            return .ovulatoryMoon
        case "luteal moon":
            return .lutealMoon
        default:
            return .follicular
        }
    }
}


struct FilterChipsView: View {
    @Binding var selectedPhase: CyclePhase?
    @Binding var selectedWorkoutType: WorkoutType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Phase filters
                ForEach(CyclePhase.allCases, id: \.self) { phase in
                    FilterChip(
                        title: phase.rawValue,
                        isSelected: selectedPhase == phase,
                        color: phase.color
                    ) {
                        if selectedPhase == phase {
                            selectedPhase = nil
                        } else {
                            selectedPhase = phase
                        }
                    }
                }
                
                Divider()
                    .frame(height: 20)
                
                // Workout type filters
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.rawValue,
                        isSelected: selectedWorkoutType == type,
                        color: type.color
                    ) {
                        if selectedWorkoutType == type {
                            selectedWorkoutType = nil
                        } else {
                            selectedWorkoutType = type
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.sofiaProCaption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct WorkoutLibraryCard: View {
    let workout: Workout
    @State private var showingWorkoutDetail = false
    
    var body: some View {
        Button(action: { showingWorkoutDetail = true }) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with icon and duration
                HStack {
                    Image(systemName: workout.workoutType.icon)
                        .font(.sofiaProTitle2)
                        .foregroundColor(workout.workoutType.color)
                    
                    Spacer()
                    
                    Text(workout.formattedDuration)
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.title)
                        .font(.sofiaProHeadline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(workout.workoutDescription)
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Phase indicator
                HStack {
                    Text(workout.cyclePhase.displayName)
                        .font(.sofiaProCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(workout.cyclePhase.color.opacity(0.1))
                        .foregroundColor(workout.cyclePhase.color)
                        .cornerRadius(4)
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingWorkoutDetail) {
            WorkoutDetailView(workout: workout)
        }
    }
}

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    @State private var isStartingWorkout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                                                    Image(systemName: workout.workoutType.icon)
                            .font(.sofiaProLargeTitle)
                            .foregroundColor(workout.workoutType.color)
                            
                            VStack(alignment: .leading) {
                                Text(workout.title)
                                    .font(.sofiaProTitle)
                                    .fontWeight(.bold)
                                
                                Text(workout.workoutType.rawValue)
                                    .font(.sofiaProSubheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text(workout.workoutDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Workout info
                    VStack(spacing: 16) {
                        InfoRow(icon: "clock", title: "Duration", value: workout.formattedDuration)
                        InfoRow(icon: "calendar", title: "Phase", value: workout.cyclePhase.displayName)
                        if let instructor = workout.instructor {
                            InfoRow(icon: "person", title: "Instructor", value: instructor)
                        }
                        if workout.isVideo {
                            InfoRow(icon: "video", title: "Format", value: "Video")
                        } else {
                            InfoRow(icon: "speaker.wave.2", title: "Format", value: "Audio")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefits")
                            .font(.sofiaProHeadline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BenefitRow(text: "Optimized for your current cycle phase")
                            BenefitRow(text: "Supports hormonal balance")
                            BenefitRow(text: "Improves energy and mood")
                        }
                    }
                    
                    // Injury warnings
                    if let injuries = workout.injuries, !injuries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Injury Considerations")
                                .font(.sofiaProHeadline)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(injuries, id: \.self) { injury in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.sofiaProCaption)
                                        
                                        Text("Modify for \(injury) injuries")
                                            .font(.sofiaProSubheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Start button
                    Button(action: { 
                        // Track workout start from library
                        TelemetryDeck.signal("Workout.Started", parameters: [
                            "workoutTitle": workout.title,
                            "workoutType": workout.workoutType.rawValue,
                            "duration": "\(workout.duration)",
                            "cyclePhase": workout.cyclePhase.rawValue,
                            "instructor": workout.instructor ?? "Unknown",
                            "hasVideo": workout.isVideo ? "true" : "false",
                            "hasAudio": (workout.audioURL != nil) ? "true" : "false",
                            "isCustomWorkout": "false",
                            "source": "workout_library"
                        ])
                        isStartingWorkout = true 
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                        }
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $isStartingWorkout) {
            WorkoutSessionView(workout: workout)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.sofiaProSubheadline)
            
            Spacer()
            
            Text(value)
                .font(.sofiaProSubheadline)
                .fontWeight(.medium)
        }
    }
}

struct BenefitRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.sofiaProCaption)
            
            Text(text)
                .font(.sofiaProSubheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct WorkoutSessionView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    @State private var currentExerciseIndex = 0
    @State private var isWorkoutComplete = false
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    
    var body: some View {
        VStack {
            if isWorkoutComplete {
                WorkoutCompleteView(workout: workout) {
                    dismiss()
                }
            } else {
                // Media player view
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text(workout.title)
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("with \(workout.instructor ?? "Instructor")")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Media player area
                    VStack(spacing: 16) {
                        if let videoURL = workout.videoURL, workout.isVideo {
                            // Video player placeholder
                            VideoPlayerView(url: videoURL)
                                .frame(height: 300)
                                .cornerRadius(12)
                        } else if let audioURL = workout.audioURL {
                            // Audio player
                            AudioPlayerViewUI(url: audioURL, workoutDuration: workout.duration)
                                .frame(height: 200)
                        } else {
                            // No media available
                            VStack(spacing: 12) {
                                Image(systemName: workout.isVideo ? "video.slash" : "speaker.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("Media not available")
                                    .font(.sofiaProHeadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Progress and controls
                    VStack(spacing: 16) {
                        // Progress bar
                        ProgressView(value: duration > 0 ? currentTime / duration : 0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        // Time display
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.sofiaProCaption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatTime(duration))
                                .font(.sofiaProCaption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Control buttons
                        HStack(spacing: 20) {
                            Button(action: { isWorkoutComplete = true }) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("End Workout")
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Button(action: { dismiss() }) {
                                HStack {
                                    Image(systemName: "xmark")
                                    Text("Close")
                                }
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Auto-start the media when view appears
            if workout.videoURL != nil || workout.audioURL != nil {
                isPlaying = true
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct VideoPlayerView: View {
    let url: String
    @StateObject private var videoPlayer = VideoPlayerViewModel()
    
    var body: some View {
        VStack {
            if let player = videoPlayer.player, !videoPlayer.isLoading {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else if let error = videoPlayer.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Video Error")
                        .font(.sofiaProHeadline)
                    
                    Text(error)
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
            } else {
                VStack(spacing: 12) {
                    ProgressView("Loading video...")
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Text("Preparing video player...")
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
            }
        }
        .onAppear {
            videoPlayer.setupVideoPlayer(url: url)
        }
        .onDisappear {
            videoPlayer.cleanup()
        }
    }
}

class VideoPlayerViewModel: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    func setupVideoPlayer(url: String) {
        isLoading = true
        errorMessage = nil
        
        print("🎥 Setting up video player for URL: \(url)")
        
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
    


class AudioPlayerView: NSObject, ObservableObject {
    let url: String
    let workoutDuration: Int
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = true
    @Published var errorMessage: String?
    private var player: AVPlayer?
    
    init(url: String, workoutDuration: Int) {
        self.url = url
        self.workoutDuration = workoutDuration
        super.init()
        setupAudioPlayer()
    }
    
    deinit {
        player?.pause()
        player = nil
        
        // Clean up audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("🔇 Audio session deactivated")
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }
    }
    
    func togglePlayback() {
        guard let player = player else { 
            print("❌ No player available")
            return 
        }
        
        if isPlaying {
            player.pause()
            isPlaying = false
            print("⏸️ Audio paused")
        } else {
            player.play()
            isPlaying = true
            print("▶️ Audio playing")
        }
    }
    
    private func setupAudioPlayer() {
        isLoading = true
        errorMessage = nil
        
        print("🔊 Setting up audio player for URL: \(url)")
        
        guard let audioURL = URL(string: url) else {
            errorMessage = "Invalid audio URL"
            isLoading = false
            print("❌ Invalid URL: \(url)")
            return
        }
        
        print("✅ URL is valid: \(audioURL)")
        
        // Test URL accessibility first
        testURLAccessibility(url: audioURL) { [weak self] isAccessible in
            DispatchQueue.main.async {
                if isAccessible {
                    self?.createAudioPlayer(url: audioURL)
                } else {
                    self?.errorMessage = "Audio file not accessible. Please check the URL."
                    self?.isLoading = false
                    print("❌ Audio URL not accessible: \(audioURL)")
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
                print("🌐 URL accessibility test: \(isAccessible ? "✅" : "❌") Status: \(httpResponse.statusCode)")
                completion(isAccessible)
            } else {
                print("❌ URL accessibility test failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }.resume()
    }
    
    private func createAudioPlayer(url: URL) {
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
        
        // Create player item with better error handling
        let playerItem = AVPlayerItem(url: url)
        
        // Configure for streaming
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        player = AVPlayer(playerItem: playerItem)
        
        // Set duration
        duration = TimeInterval(workoutDuration * 60)
        
        // Set up basic time tracking (simplified to avoid crashes)
        currentTime = 0
        
        // Add status observation
        playerItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        
        // Add periodic time observer for progress tracking
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // Simple retry logic without complex status checking
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🎵 Attempting to play audio...")
            self.player?.play()
            self.isPlaying = true
            self.isLoading = false
            print("✅ Audio play command sent")
        }
    }
    
    // Add KVO observation
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                print("📊 Player status changed: \(playerItem.status.rawValue)")
                switch playerItem.status {
                case .readyToPlay:
                    print("✅ Audio is ready to play")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        // Auto-start playback when ready
                        self.player?.play()
                        self.isPlaying = true
                        print("🎵 Auto-started playback")
                    }
                case .failed:
                    print("❌ Audio failed to load: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    errorMessage = "Failed to load audio: \(playerItem.error?.localizedDescription ?? "Unknown error")"
                    isLoading = false
                case .unknown:
                    print("❓ Audio status unknown")
                @unknown default:
                    print("❓ Unknown audio status")
                }
            }
        }
    }
}

struct AudioPlayerViewUI: View {
    @StateObject private var audioPlayer: AudioPlayerView
    
    init(url: String, workoutDuration: Int) {
        self._audioPlayer = StateObject(wrappedValue: AudioPlayerView(url: url, workoutDuration: workoutDuration))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Audio player interface
            VStack(spacing: 12) {
                if audioPlayer.isLoading {
                    ProgressView("Loading audio...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = audioPlayer.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Audio Error")
                            .font(.sofiaProHeadline)
                        
                        Text(error)
                            .font(.sofiaProCaption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                audioPlayer.togglePlayback()
                            }
                        
                        Text(audioPlayer.isPlaying ? "Playing" : "Paused")
                            .font(.sofiaProHeadline)
                        
                        // Progress indicator
                        if audioPlayer.duration > 0 {
                            ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .padding(.horizontal)
                            
                            HStack {
                                Text(formatTime(audioPlayer.currentTime))
                                    .font(.sofiaProCaption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatTime(audioPlayer.duration))
                                    .font(.sofiaProCaption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        Text("Audio Workout")
                            .font(.sofiaProCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct WorkoutCompleteView: View {
    let workout: Workout
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("Workout Complete!")
                    .font(.sofiaProTitle)
                    .fontWeight(.bold)
                
                Text("Great job completing your \(workout.title) workout")
                    .font(.sofiaProSubheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Text("Duration: \(workout.formattedDuration)")
                Text("Phase: \(workout.cyclePhase.displayName)")
                Text("Type: \(workout.workoutType.rawValue)")
            }
            .font(.sofiaProSubheadline)
            .foregroundColor(.secondary)
            
            Button("Done") {
                onDismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}


struct CustomWorkoutCard: View {
    let customWorkout: CustomWorkout
    @State private var showingWorkoutDetail = false
    
    var body: some View {
        Button(action: { showingWorkoutDetail = true }) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with icon and duration
                HStack {
                    Image(systemName: getActivityIcon(customWorkout.activityType))
                        .font(.sofiaProTitle2)
                        .foregroundColor(getActivityColor(customWorkout.activityType))
                    
                    Spacer()
                    
                    Text(customWorkout.duration)
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(customWorkout.name)
                        .font(.sofiaProHeadline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(customWorkout.activityType)
                        .font(.sofiaProCaption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Intensity indicator
                HStack {
                    Text(customWorkout.intensity)
                        .font(.sofiaProCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(getIntensityColor(customWorkout.intensity).opacity(0.1))
                        .foregroundColor(getIntensityColor(customWorkout.intensity))
                        .cornerRadius(4)
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingWorkoutDetail) {
            CustomWorkoutDetailView(customWorkout: customWorkout)
        }
    }
    
    private func getActivityIcon(_ activityType: String) -> String {
        switch activityType.lowercased() {
        case "hiit": return "bolt.fill"
        case "yoga": return "figure.yoga"
        case "pilates": return "figure.pilates"
        case "strength": return "dumbbell.fill"
        case "run": return "figure.run"
        case "cycle": return "bicycle"
        case "dance": return "figure.dance"
        case "walk": return "figure.walk"
        case "free weights": return "dumbbell"
        case "sport": return "sportscourt"
        case "swim": return "figure.pool.swim"
        case "circuit": return "arrow.triangle.2.circlepath"
        case "row": return "figure.rowing"
        default: return "figure.flexibility"
        }
    }
    
    private func getActivityColor(_ activityType: String) -> Color {
        switch activityType.lowercased() {
        case "hiit": return .orange
        case "yoga": return .purple
        case "pilates": return .pink
        case "strength": return .red
        case "run": return .green
        case "cycle": return .blue
        case "dance": return .purple
        case "walk": return .green
        case "free weights": return .red
        case "sport": return .blue
        case "swim": return .cyan
        case "circuit": return .orange
        case "row": return .blue
        default: return .gray
        }
    }
    
    private func getIntensityColor(_ intensity: String) -> Color {
        switch intensity.lowercased() {
        case "low": return .green
        case "mid": return .yellow
        case "mid-high": return .orange
        case "high": return .red
        default: return .gray
        }
    }
}

struct CustomWorkoutDetailView: View {
    let customWorkout: CustomWorkout
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: getActivityIcon(customWorkout.activityType))
                                .font(.sofiaProLargeTitle)
                                .foregroundColor(getActivityColor(customWorkout.activityType))
                            
                            VStack(alignment: .leading) {
                                Text(customWorkout.name)
                                    .font(.sofiaProTitle)
                                    .fontWeight(.bold)
                                
                                Text(customWorkout.activityType)
                                    .font(.sofiaProSubheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text("Your custom workout")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Workout info
                    VStack(spacing: 16) {
                        InfoRow(icon: "clock", title: "Duration", value: customWorkout.duration)
                        InfoRow(icon: "bolt", title: "Intensity", value: customWorkout.intensity)
                        InfoRow(icon: "figure.flexibility", title: "Type", value: customWorkout.activityType)
                        InfoRow(icon: "calendar", title: "Created", value: DateFormatter.shortDate.string(from: customWorkout.createdAt))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefits")
                            .font(.sofiaProHeadline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BenefitRow(text: "Personalized to your preferences")
                            BenefitRow(text: "Track your custom routines")
                            BenefitRow(text: "Build your own workout library")
                        }
                    }
                    
                    // Start button
                    Button(action: { 
                        // Track custom workout start from library
                        TelemetryDeck.signal("Workout.Started", parameters: [
                            "workoutTitle": customWorkout.name,
                            "workoutType": customWorkout.activityType,
                            "duration": customWorkout.duration,
                            "cyclePhase": "custom",
                            "instructor": "User",
                            "hasVideo": "false",
                            "hasAudio": "false",
                            "isCustomWorkout": "true",
                            "source": "custom_workout_library"
                        ])
                        print("Starting custom workout: \(customWorkout.name)")
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                        }
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Custom Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingEditView = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditCustomWorkoutView(customWorkout: customWorkout)
        }
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteCustomWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(customWorkout.name)\"? This action cannot be undone.")
        }
    }
    
    private func deleteCustomWorkout() {
        modelContext.delete(customWorkout)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting custom workout: \(error)")
        }
    }
    
    private func getActivityIcon(_ activityType: String) -> String {
        switch activityType.lowercased() {
        case "hiit": return "bolt.fill"
        case "yoga": return "figure.yoga"
        case "pilates": return "figure.pilates"
        case "strength": return "dumbbell.fill"
        case "run": return "figure.run"
        case "cycle": return "bicycle"
        case "dance": return "figure.dance"
        case "walk": return "figure.walk"
        case "free weights": return "dumbbell"
        case "sport": return "sportscourt"
        case "swim": return "figure.pool.swim"
        case "circuit": return "arrow.triangle.2.circlepath"
        case "row": return "figure.rowing"
        default: return "figure.flexibility"
        }
    }
    
    private func getActivityColor(_ activityType: String) -> Color {
        switch activityType.lowercased() {
        case "hiit": return .orange
        case "yoga": return .purple
        case "pilates": return .pink
        case "strength": return .red
        case "run": return .green
        case "cycle": return .blue
        case "dance": return .purple
        case "walk": return .green
        case "free weights": return .red
        case "sport": return .blue
        case "swim": return .cyan
        case "circuit": return .orange
        case "row": return .blue
        default: return .gray
        }
    }
}

struct EditCustomWorkoutView: View {
    let customWorkout: CustomWorkout
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String
    @State private var selectedDuration: String
    @State private var selectedIntensity: String
    @State private var selectedActivityType: String
    
    // Dropdown options - matching LogCustomWorkoutView
    private let durationOptions = ["5 min", "15 min", "30 min", "45 min", "1 hour", "Over 1 hour"]
    private let intensityOptions = ["Low", "Mid", "Mid-High", "High"]
    private let activityTypeOptions = ["HIIT", "Yoga", "Pilates", "Strength", "Run", "Cycle", "Dance", "Walk", "Free Weights", "Sport", "Swim", "Circuit", "Row", "Other"]
    
    init(customWorkout: CustomWorkout) {
        self.customWorkout = customWorkout
        self._name = State(initialValue: customWorkout.name)
        self._selectedDuration = State(initialValue: customWorkout.duration)
        self._selectedIntensity = State(initialValue: customWorkout.intensity)
        self._selectedActivityType = State(initialValue: customWorkout.activityType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $name)
                        .font(.custom("Sofia Pro", size: 16))
                    
                    // Duration Dropdown
                    Menu {
                        ForEach(durationOptions, id: \.self) { duration in
                            Button(duration) {
                                selectedDuration = duration
                            }
                        }
                    } label: {
                        HStack {
                            Text("Duration")
                                .font(.custom("Sofia Pro", size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(selectedDuration)
                                .font(.custom("Sofia Pro", size: 16))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Intensity Dropdown
                    Menu {
                        ForEach(intensityOptions, id: \.self) { intensity in
                            Button(intensity) {
                                selectedIntensity = intensity
                            }
                        }
                    } label: {
                        HStack {
                            Text("Intensity")
                                .font(.custom("Sofia Pro", size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(selectedIntensity)
                                .font(.custom("Sofia Pro", size: 16))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Activity Type Dropdown
                    Menu {
                        ForEach(activityTypeOptions, id: \.self) { activityType in
                            Button(activityType) {
                                selectedActivityType = activityType
                            }
                        }
                    } label: {
                        HStack {
                            Text("Activity Type")
                                .font(.custom("Sofia Pro", size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(selectedActivityType)
                                .font(.custom("Sofia Pro", size: 16))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || selectedDuration.isEmpty || selectedIntensity.isEmpty || selectedActivityType.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        customWorkout.name = name
        customWorkout.duration = selectedDuration
        customWorkout.intensity = selectedIntensity
        customWorkout.activityType = selectedActivityType
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving custom workout: \(error)")
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    WorkoutLibraryView()
        .modelContainer(for: [UserProfile.self, Workout.self, Progress.self, Exercise.self, WeeklyFitnessPlanEntry.self, DailyHabitEntry.self, CustomWorkout.self], inMemory: true)
}
