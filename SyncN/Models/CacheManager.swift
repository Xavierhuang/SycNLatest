import Foundation
import SwiftUI
import AVFoundation

class CacheManager: NSObject, ObservableObject {
    static let shared = CacheManager()
    
    // KVO context for preloading
    private var preloadContext = 0
    
    // Cache storage
    private var educationClassesCache: [EducationClass]?
    private var workoutDataCache: [Workout]?
    private var userProfileCache: UserProfile?
    private var videoProgressCache: [String: Bool] = [:]
    private var charmProgressCache: CharmProgress?
    private var calendarDataCache: [String: Any]?
    private var cyclePredictionCache: [Date]?
    private var dailyOverviewCache: [String: Any]?
    private var weeklyFitnessPlanCache: [WeeklyFitnessPlanEntry]?
    private var personalizationCache: PersonalizationData?
    private var videoURLCache: [String: String] = [:]  // workoutId -> videoURL
    private var preloadedPlayers: [String: AVPlayer] = [:]  // videoURL -> preloaded player
    
    // Cache timestamps
    private var educationClassesCacheTime: Date?
    private var workoutDataCacheTime: Date?
    private var userProfileCacheTime: Date?
    private var videoProgressCacheTime: Date?
    private var charmProgressCacheTime: Date?
    private var calendarDataCacheTime: Date?
    private var cyclePredictionCacheTime: Date?
    private var dailyOverviewCacheTime: Date?
    private var weeklyFitnessPlanCacheTime: Date?
    private var personalizationCacheTime: Date?
    
    // Cache expiry times (in seconds)
    private let shortCacheExpiry: TimeInterval = 300 // 5 minutes
    private let mediumCacheExpiry: TimeInterval = 1800 // 30 minutes
    private let longCacheExpiry: TimeInterval = 3600 // 1 hour
    
    private override init() {}
    
    // MARK: - KVO Implementation
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &preloadContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == "status", let playerItem = object as? AVPlayerItem {
            DispatchQueue.main.async {
                switch playerItem.status {
                case .readyToPlay:
                    print("✅ AVPlayerItem ready to play: \(playerItem.asset)")
                case .failed:
                    print("❌ AVPlayerItem failed to load: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                case .unknown:
                    print("⏳ AVPlayerItem status unknown")
                @unknown default:
                    print("🔍 AVPlayerItem unknown status: \(playerItem.status.rawValue)")
                }
            }
        }
    }
    
    deinit {
        // Clean up KVO observers
        for (_, player) in preloadedPlayers {
            if let playerItem = player.currentItem {
                playerItem.removeObserver(self, forKeyPath: "status", context: &preloadContext)
            }
        }
    }
    
    // MARK: - Education Classes Cache
    
    func getCachedEducationClasses() -> [EducationClass]? {
        guard let cache = educationClassesCache,
              let cacheTime = educationClassesCacheTime,
              Date().timeIntervalSince(cacheTime) < longCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedEducationClasses(_ classes: [EducationClass]) {
        educationClassesCache = classes
        educationClassesCacheTime = Date()
    }
    
    func getEducationClasses() -> [EducationClass] {
        if let cached = getCachedEducationClasses() {
            return cached
        }
        
        let classes = EducationClassesData.shared.getEducationClasses()
        setCachedEducationClasses(classes)
        return classes
    }
    
    // MARK: - Workout Data Cache
    
    func getCachedWorkoutData() -> [Workout]? {
        guard let cache = workoutDataCache,
              let cacheTime = workoutDataCacheTime,
              Date().timeIntervalSince(cacheTime) < mediumCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedWorkoutData(_ workouts: [Workout]) {
        workoutDataCache = workouts
        workoutDataCacheTime = Date()
    }
    
    // MARK: - User Profile Cache
    
    func getCachedUserProfile() -> UserProfile? {
        guard let cache = userProfileCache,
              let cacheTime = userProfileCacheTime,
              Date().timeIntervalSince(cacheTime) < shortCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedUserProfile(_ profile: UserProfile) {
        userProfileCache = profile
        userProfileCacheTime = Date()
    }
    
    // MARK: - Video Progress Cache
    
    func getCachedVideoProgress(for videoTitle: String) -> Bool? {
        guard let cacheTime = videoProgressCacheTime,
              Date().timeIntervalSince(cacheTime) < shortCacheExpiry else {
            return nil
        }
        return videoProgressCache[videoTitle]
    }
    
    func setCachedVideoProgress(_ title: String, isCompleted: Bool) {
        videoProgressCache[title] = isCompleted
        videoProgressCacheTime = Date()
    }
    
    func invalidateVideoProgressCache() {
        videoProgressCache.removeAll()
        videoProgressCacheTime = nil
    }
    
    // MARK: - Charm Progress Cache
    
    func getCachedCharmProgress() -> CharmProgress? {
        guard let cache = charmProgressCache,
              let cacheTime = charmProgressCacheTime,
              Date().timeIntervalSince(cacheTime) < shortCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedCharmProgress(_ progress: CharmProgress) {
        charmProgressCache = progress
        charmProgressCacheTime = Date()
    }
    
    func invalidateCharmProgressCache() {
        charmProgressCache = nil
        charmProgressCacheTime = nil
    }
    
    // MARK: - Calendar Data Cache
    
    func getCachedCalendarData() -> [String: Any]? {
        guard let cache = calendarDataCache,
              let cacheTime = calendarDataCacheTime,
              Date().timeIntervalSince(cacheTime) < mediumCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedCalendarData(_ data: [String: Any]) {
        calendarDataCache = data
        calendarDataCacheTime = Date()
    }
    
    func getCachedCyclePredictions() -> [Date]? {
        guard let cache = cyclePredictionCache,
              let cacheTime = cyclePredictionCacheTime,
              Date().timeIntervalSince(cacheTime) < mediumCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedCyclePredictions(_ predictions: [Date]) {
        cyclePredictionCache = predictions
        cyclePredictionCacheTime = Date()
    }
    
    func invalidateCalendarCache() {
        calendarDataCache = nil
        cyclePredictionCache = nil
        calendarDataCacheTime = nil
        cyclePredictionCacheTime = nil
    }
    
    // MARK: - Dashboard Cache
    
    func getCachedDailyOverview() -> [String: Any]? {
        guard let cache = dailyOverviewCache,
              let cacheTime = dailyOverviewCacheTime,
              Date().timeIntervalSince(cacheTime) < shortCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedDailyOverview(_ data: [String: Any]) {
        dailyOverviewCache = data
        dailyOverviewCacheTime = Date()
    }
    
    func getCachedPersonalizationData() -> PersonalizationData? {
        guard let cache = personalizationCache,
              let cacheTime = personalizationCacheTime,
              Date().timeIntervalSince(cacheTime) < shortCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedPersonalizationData(_ data: PersonalizationData) {
        personalizationCache = data
        personalizationCacheTime = Date()
    }
    
    // MARK: - Fitness Plan Cache
    
    func getCachedWeeklyFitnessPlan() -> [WeeklyFitnessPlanEntry]? {
        guard let cache = weeklyFitnessPlanCache,
              let cacheTime = weeklyFitnessPlanCacheTime,
              Date().timeIntervalSince(cacheTime) < mediumCacheExpiry else {
            return nil
        }
        return cache
    }
    
    func setCachedWeeklyFitnessPlan(_ plan: [WeeklyFitnessPlanEntry]) {
        weeklyFitnessPlanCache = plan
        weeklyFitnessPlanCacheTime = Date()
    }
    
    func invalidateDashboardCache() {
        dailyOverviewCache = nil
        personalizationCache = nil
        dailyOverviewCacheTime = nil
        personalizationCacheTime = nil
    }
    
    func invalidateFitnessPlanCache() {
        weeklyFitnessPlanCache = nil
        weeklyFitnessPlanCacheTime = nil
    }
    
    // MARK: - Video Preloading Cache
    
    func cacheVideoURL(_ url: String, for workoutId: String) {
        videoURLCache[workoutId] = url
    }
    
    func getCachedVideoURL(for workoutId: String) -> String? {
        return videoURLCache[workoutId]
    }
    
    func preloadVideo(url: String, completion: @escaping (AVPlayer?) -> Void) {
        // Check if already preloaded
        if let existingPlayer = preloadedPlayers[url] {
            completion(existingPlayer)
            return
        }
        
        guard let videoURL = URL(string: url) else {
            completion(nil)
            return
        }
        
        // Create optimized player item for preloading
        let playerItem = AVPlayerItem(url: videoURL)
        playerItem.preferredForwardBufferDuration = 10.0 // Buffer more for preloading
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        playerItem.preferredPeakBitRate = 0
        
        if #available(iOS 15.0, *) {
            playerItem.startsOnFirstEligibleVariant = true
        }
        
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        
        // Store the preloaded player immediately and let it buffer naturally
        preloadedPlayers[url] = player
        
        // Observe player status to know when it's ready
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: &preloadContext)
        
        // Start loading the video content by seeking to beginning
        player.seek(to: .zero) { [weak self] finished in
            DispatchQueue.main.async {
                if finished {
                    print("✅ Successfully preloaded video: \(url)")
                    completion(player)
                } else {
                    print("⚠️ Failed to preload video: \(url)")
                    completion(nil)
                }
            }
        }
    }
    
    func getPreloadedPlayer(for url: String) -> AVPlayer? {
        return preloadedPlayers[url]
    }
    
    func removePreloadedPlayer(for url: String) {
        if let player = preloadedPlayers[url] {
            player.pause()
            // Remove KVO observer before removing the player
            if let playerItem = player.currentItem {
                playerItem.removeObserver(self, forKeyPath: "status", context: &preloadContext)
            }
        }
        preloadedPlayers.removeValue(forKey: url)
    }
    
    func preloadUpcomingWorkoutVideos(_ workouts: [WeeklyFitnessPlanEntry]) {
        // Preload videos for today and tomorrow's workouts
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        
        let upcomingWorkouts = workouts.filter { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: today) ||
            Calendar.current.isDate(workout.date, inSameDayAs: tomorrow)
        }
        
        for workout in upcomingWorkouts {
            if let videoURL = workout.videoURL, !videoURL.isEmpty {
                preloadVideo(url: videoURL) { player in
                    if player != nil {
                        print("✅ Preloaded upcoming workout video: \(workout.workoutTitle)")
                    }
                }
            }
        }
    }
    
    // MARK: - Cache Management
    
    func clearAllCaches() {
        educationClassesCache = nil
        workoutDataCache = nil
        userProfileCache = nil
        videoProgressCache.removeAll()
        charmProgressCache = nil
        calendarDataCache = nil
        cyclePredictionCache = nil
        dailyOverviewCache = nil
        weeklyFitnessPlanCache = nil
        personalizationCache = nil
        videoURLCache.removeAll()
        
        // Clean up preloaded players
        for (_, player) in preloadedPlayers {
            player.pause()
            // Remove KVO observer before removing the player
            if let playerItem = player.currentItem {
                playerItem.removeObserver(self, forKeyPath: "status", context: &preloadContext)
            }
        }
        preloadedPlayers.removeAll()
        
        educationClassesCacheTime = nil
        workoutDataCacheTime = nil
        userProfileCacheTime = nil
        videoProgressCacheTime = nil
        charmProgressCacheTime = nil
        calendarDataCacheTime = nil
        cyclePredictionCacheTime = nil
        dailyOverviewCacheTime = nil
        weeklyFitnessPlanCacheTime = nil
        personalizationCacheTime = nil
    }
    
    func preloadCriticalData() {
        // Preload frequently accessed data
        _ = getEducationClasses()
        
        // Preload workout data if needed
        Task {
            await preloadWorkoutData()
        }
    }
    
    private func preloadWorkoutData() async {
        // This could be used to preload workout data from a remote source
        // For now, it's local data so no async loading needed
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStatistics() -> [String: Any] {
        return [
            "educationClassesCached": educationClassesCache != nil,
            "workoutDataCached": workoutDataCache != nil,
            "userProfileCached": userProfileCache != nil,
            "videoProgressCacheSize": videoProgressCache.count,
            "charmProgressCached": charmProgressCache != nil,
            "educationClassesCacheAge": educationClassesCacheTime?.timeIntervalSinceNow ?? 0,
            "workoutDataCacheAge": workoutDataCacheTime?.timeIntervalSinceNow ?? 0,
            "userProfileCacheAge": userProfileCacheTime?.timeIntervalSinceNow ?? 0
        ]
    }
}
