import Foundation
import SwiftData
import SwiftUI

class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    @Published var cachedUserProfile: UserProfile?
    @Published var cachedCharmProgress: CharmProgress?
    @Published var cachedVideoProgress: [VideoProgress] = []
    @Published var cachedUserRewards: UserRewardsData?
    
    private var lastUpdateTime: Date?
    private let cacheExpiry: TimeInterval = 60 // 1 minute cache
    
    private init() {}
    
    func loadUserData(from modelContext: ModelContext) {
        // Check if cache is still valid
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < cacheExpiry {
            return // Use cached data
        }
        
        Task {
            await refreshUserData(from: modelContext)
        }
    }
    
    private func refreshUserData(from modelContext: ModelContext) async {
        do {
            // Load user profile
            let profileDescriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(profileDescriptor)
            cachedUserProfile = profiles.first
            
            // Load charm progress
            if let userProfile = cachedUserProfile {
                let charmDescriptor = FetchDescriptor<CharmProgress>()
                let charmData = try modelContext.fetch(charmDescriptor)
                cachedCharmProgress = charmData.first { $0.userId == userProfile.id }
                
                // Load video progress
                let videoDescriptor = FetchDescriptor<VideoProgress>()
                let videoData = try modelContext.fetch(videoDescriptor)
                cachedVideoProgress = videoData.filter { $0.userId == userProfile.id }
                
                // Load user rewards
                let rewardsDescriptor = FetchDescriptor<UserRewardsData>()
                let rewardsData = try modelContext.fetch(rewardsDescriptor)
                cachedUserRewards = rewardsData.first { $0.userId == userProfile.id }
            }
            
            lastUpdateTime = Date()
            
        } catch {
            print("Error loading user data: \(error)")
        }
    }
    
    func invalidateCache() {
        lastUpdateTime = nil
        cachedUserProfile = nil
        cachedCharmProgress = nil
        cachedVideoProgress.removeAll()
        cachedUserRewards = nil
    }
    
    func updateVideoProgress(_ videoTitle: String, isCompleted: Bool) {
        // Update cache immediately for responsive UI
        if let index = cachedVideoProgress.firstIndex(where: { $0.videoTitle == videoTitle }) {
            cachedVideoProgress[index].isCompleted = isCompleted
        }
        
        // Invalidate cache to force refresh on next load
        CacheManager.shared.invalidateVideoProgressCache()
    }
    
    func updateCharmProgress(_ progress: CharmProgress) {
        cachedCharmProgress = progress
        CacheManager.shared.setCachedCharmProgress(progress)
    }
}
