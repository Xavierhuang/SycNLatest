//
//  SyncNApp.swift
//  SyncN
//
//  Created by Weijia Huang on 8/29/25.
//

import SwiftUI
import SwiftData
import TelemetryDeck
import UserNotifications

@main
struct SyncNApp: App {
    init() {
        // Initialize TelemetryDeck for analytics
        let config = TelemetryDeck.Config(appID: TelemetryDeckConfig.appID)
        TelemetryDeck.initialize(config: config)
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Register Sofia Pro fonts
        registerSofiaProFonts()
        
        // Preload critical data for faster app performance
        CacheManager.shared.preloadCriticalData()
        
        // Setup memory management
        setupMemoryManagement()
    }
    
    private func registerSofiaProFonts() {
        // Note: In a real app, you would need to add the Sofia Pro font files to your bundle
        // and register them here. For now, we'll use system fonts as fallback
        // The custom font extension will handle the font names
    }
    
    private func setupMemoryManagement() {
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Clear caches on memory warning
            CacheManager.shared.clearAllCaches()
            ImageCache.shared.clearCache()
        }
        
        // Clear caches when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Clear non-essential caches to free memory
            ImageCache.shared.clearCache()
        }
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Workout.self,
            Progress.self,
            DailySymptomEntry.self,
            WeeklyFitnessPlanEntry.self,
            DailyHabitEntry.self,
            PersonalizationData.self,
            WorkoutRating.self,
            CustomWorkout.self,
            UserRewardsData.self,
            CharmProgress.self,
            VideoProgress.self,
            // Authentication models
            AuthUser.self,
            AuthSession.self,
            PasswordResetToken.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // For development, just delete the store and start fresh
            print("SwiftData error, deleting store and starting fresh: \(error)")
            
            // Delete the existing store
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            AuthenticationWrapper {
                SplashScreenView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
