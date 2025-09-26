import Foundation
import UserNotifications
import SwiftUI
import SwiftData

class LocalNotificationManager: ObservableObject {
    static let shared = LocalNotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
                self.checkAuthorizationStatus()
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Fitness Class Notifications
    
    func scheduleFitnessClassReminder(
        workoutTitle: String,
        instructor: String?,
        scheduledTime: Date,
        reminderMinutes: Int = 15
    ) {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule notification - not authorized")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder"
        content.body = "\(workoutTitle)\(instructor != nil ? " with \(instructor!)" : "") starts in \(reminderMinutes) minutes!"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "workoutTitle": workoutTitle,
            "instructor": instructor ?? "",
            "type": "fitness_reminder"
        ]
        
        // Create trigger for the reminder time
        let reminderDate = scheduledTime.addingTimeInterval(-TimeInterval(reminderMinutes * 60))
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create unique identifier
        let identifier = "fitness_reminder_\(workoutTitle.replacingOccurrences(of: " ", with: "_"))_\(scheduledTime.timeIntervalSince1970)"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling fitness reminder: \(error.localizedDescription)")
            } else {
                print("✅ Fitness reminder scheduled for \(workoutTitle) at \(reminderDate)")
            }
        }
    }
    
    func scheduleWorkoutStartNotification(
        workoutTitle: String,
        instructor: String?,
        scheduledTime: Date
    ) {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule notification - not authorized")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Work Out!"
        content.body = "\(workoutTitle)\(instructor != nil ? " with \(instructor!)" : "") is starting now!"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "workoutTitle": workoutTitle,
            "instructor": instructor ?? "",
            "type": "workout_start"
        ]
        
        // Create trigger for the exact time
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create unique identifier
        let identifier = "workout_start_\(workoutTitle.replacingOccurrences(of: " ", with: "_"))_\(scheduledTime.timeIntervalSince1970)"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling workout start notification: \(error.localizedDescription)")
            } else {
                print("✅ Workout start notification scheduled for \(workoutTitle) at \(scheduledTime)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled notification: \(identifier)")
    }
    
    func cancelAllFitnessNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let fitnessIdentifiers = requests.compactMap { request in
                if let userInfo = request.content.userInfo as? [String: Any],
                   let type = userInfo["type"] as? String,
                   type.contains("fitness") || type.contains("workout") {
                    return request.identifier
                }
                return nil
            }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: fitnessIdentifiers)
            print("🗑️ Cancelled \(fitnessIdentifiers.count) fitness notifications")
        }
    }
    
    func getPendingFitnessNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let fitnessRequests = requests.filter { request in
                if let userInfo = request.content.userInfo as? [String: Any],
                   let type = userInfo["type"] as? String {
                    return type.contains("fitness") || type.contains("workout")
                }
                return false
            }
            completion(fitnessRequests)
        }
    }
    
    // MARK: - Daily Workout Notifications
    
    func scheduleDailyWorkoutNotification() {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule daily notification - not authorized")
            return
        }
        
        // Cancel any existing daily notifications first
        cancelDailyWorkoutNotification()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "SyncN with your Body"
        content.body = "today's [workout title]" // This will be updated dynamically
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "type": "daily_workout_reminder"
        ]
        
        // Create trigger for 4:00 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 16 // 4 PM
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create unique identifier
        let identifier = "daily_workout_reminder_4pm"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling daily workout notification: \(error.localizedDescription)")
            } else {
                print("✅ Daily workout notification scheduled for 4:00 PM")
            }
        }
    }
    
    func cancelDailyWorkoutNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_workout_reminder_4pm"])
        print("🗑️ Cancelled daily workout notification")
    }
    
    func scheduleDailyWorkoutReminder() {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule daily notification - not authorized")
            return
        }
        
        // Cancel any existing daily notifications first
        cancelDailyWorkoutNotification()
        
        // Create notification content with conditional body
        let content = UNMutableNotificationContent()
        content.title = "SyncN with your Body"
        content.body = getDailyWorkoutMessage()
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "type": "daily_workout_reminder"
        ]
        
        // Create trigger for 4:00 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 16 // 4 PM
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create unique identifier
        let identifier = "daily_workout_reminder_4pm"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling daily workout notification: \(error.localizedDescription)")
            } else {
                print("✅ Daily workout notification scheduled for 4:00 PM")
            }
        }
    }
    
    private func getDailyWorkoutMessage() -> String {
        // This will be called at notification time, so we need to check current workout status
        // For now, return a generic message that will be updated dynamically
        return "today's workout"
    }
    
    // MARK: - Workout Completion Check
    
    func checkAndScheduleDailyNotification(modelContext: ModelContext) {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule daily notification - not authorized")
            return
        }
        
        // Get today's workouts and check completion status
        let todaysIncompleteWorkouts = getTodaysIncompleteWorkouts(modelContext: modelContext)
        
        // Only schedule notification if there are incomplete workouts
        if !todaysIncompleteWorkouts.isEmpty {
            scheduleConditionalDailyNotification(incompleteWorkouts: todaysIncompleteWorkouts)
        } else {
            // Cancel any existing daily notification if all workouts are complete
            cancelDailyWorkoutNotification()
            print("✅ All workouts completed today - no notification needed")
        }
    }
    
    private func getTodaysIncompleteWorkouts(modelContext: ModelContext) -> [WeeklyFitnessPlanEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get start and end of today for date range comparison
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Create a fetch request for today's workouts using date range
        let descriptor = FetchDescriptor<WeeklyFitnessPlanEntry>(
            predicate: #Predicate<WeeklyFitnessPlanEntry> { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        
        do {
            let todaysWorkouts = try modelContext.fetch(descriptor)
            // Filter out completed workouts (status == .confirmed)
            return todaysWorkouts.filter { $0.status != WorkoutStatus.confirmed }
        } catch {
            print("❌ Error fetching today's workouts: \(error)")
            return []
        }
    }
    
    private func scheduleConditionalDailyNotification(incompleteWorkouts: [WeeklyFitnessPlanEntry]) {
        // Cancel any existing daily notifications first
        cancelDailyWorkoutNotification()
        
        // Create notification content based on incomplete workouts
        let content = UNMutableNotificationContent()
        content.title = "SyncN with your Body"
        content.body = createNotificationBody(for: incompleteWorkouts)
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "type": "daily_workout_reminder",
            "incompleteCount": incompleteWorkouts.count
        ]
        
        // Create trigger for 4:00 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 16 // 4 PM
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create unique identifier
        let identifier = "daily_workout_reminder_4pm"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling conditional daily notification: \(error.localizedDescription)")
            } else {
                print("✅ Conditional daily notification scheduled for 4:00 PM with \(incompleteWorkouts.count) incomplete workouts")
            }
        }
    }
    
    private func createNotificationBody(for incompleteWorkouts: [WeeklyFitnessPlanEntry]) -> String {
        if incompleteWorkouts.isEmpty {
            return "Great job! All workouts completed today."
        } else if incompleteWorkouts.count == 1 {
            return "today's \(incompleteWorkouts[0].workoutTitle)"
        } else {
            // Multiple incomplete workouts - mention the first one
            return "today's \(incompleteWorkouts[0].workoutTitle) and \(incompleteWorkouts.count - 1) more"
        }
    }
    
    // MARK: - Time Zone Helper
    
    func getCurrentTimeZone() -> TimeZone {
        return TimeZone.current
    }
    
    func getNotificationTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = getCurrentTimeZone()
        
        // Create a date for 4:00 PM today
        var dateComponents = DateComponents()
        dateComponents.hour = 16
        dateComponents.minute = 0
        let calendar = Calendar.current
        if let date = calendar.date(from: dateComponents) {
            return formatter.string(from: date)
        }
        return "4:00 PM"
    }
    
    func getTimeZoneDisplayName() -> String {
        let timeZone = getCurrentTimeZone()
        return timeZone.localizedName(for: .standard, locale: Locale.current) ?? timeZone.identifier
    }
    
    // MARK: - Testing Functions
    
    func sendTestNotification() {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot send test notification - not authorized")
            return
        }
        
        // Create test notification content
        let content = UNMutableNotificationContent()
        content.title = "SyncN Test"
        content.body = "This is a test notification to verify the system is working!"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "type": "test_notification"
        ]
        
        // Create trigger for 3 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        
        // Create unique identifier
        let identifier = "test_notification_\(Date().timeIntervalSince1970)"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("✅ Test notification scheduled - should appear in 3 seconds!")
            }
        }
    }
    
    func startMinutelyTestNotifications() {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot start minutely notifications - not authorized")
            return
        }
        
        // Cancel any existing test notifications first
        cancelMinutelyTestNotifications()
        
        // Schedule notifications for the next 10 minutes (for testing)
        for i in 1...10 {
            let content = UNMutableNotificationContent()
            content.title = "SyncN Test #\(i)"
            content.body = "Minutely test notification - \(Date().formatted(date: .omitted, time: .shortened))"
            content.sound = .default
            content.badge = NSNumber(value: i)
            
            content.userInfo = [
                "type": "minutely_test_notification",
                "sequence": i
            ]
            
            // Create trigger for i minutes from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(i * 60), repeats: false)
            
            let identifier = "minutely_test_\(i)_\(Date().timeIntervalSince1970)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling minutely test notification #\(i): \(error.localizedDescription)")
                } else {
                    print("✅ Minutely test notification #\(i) scheduled for \(i) minute(s) from now")
                }
            }
        }
        
        print("🔔 Started 10 minutely test notifications - they will fire every minute for the next 10 minutes")
    }
    
    func cancelMinutelyTestNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let testIdentifiers = requests.compactMap { request in
                if let userInfo = request.content.userInfo as? [String: Any],
                   let type = userInfo["type"] as? String,
                   type == "minutely_test_notification" {
                    return request.identifier
                }
                return nil
            }
            
            if !testIdentifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: testIdentifiers)
                print("🗑️ Cancelled \(testIdentifiers.count) minutely test notifications")
            } else {
                print("ℹ️ No minutely test notifications to cancel")
            }
        }
    }
    
    func getTestNotificationStatus() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let testNotifications = requests.filter { request in
                if let userInfo = request.content.userInfo as? [String: Any],
                   let type = userInfo["type"] as? String {
                    return type.contains("test")
                }
                return false
            }
            
            print("📊 Test Notification Status:")
            print("   - Pending test notifications: \(testNotifications.count)")
            print("   - Authorization status: \(self.authorizationStatus)")
            
            for notification in testNotifications.prefix(5) {
                if let trigger = notification.trigger as? UNTimeIntervalNotificationTrigger {
                    let timeRemaining = trigger.nextTriggerDate()?.timeIntervalSinceNow ?? 0
                    print("   - \(notification.content.title): \(Int(timeRemaining)) seconds remaining")
                }
            }
        }
        
        // Also check delivered notifications
        UNUserNotificationCenter.current().getDeliveredNotifications { deliveredNotifications in
            let testDelivered = deliveredNotifications.filter { notification in
                if let userInfo = notification.request.content.userInfo as? [String: Any],
                   let type = userInfo["type"] as? String {
                    return type.contains("test")
                }
                return false
            }
            print("📬 Delivered test notifications: \(testDelivered.count)")
        }
    }
    
    func sendImmediateTestNotification() {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot send immediate test notification - not authorized")
            return
        }
        
        // First, let's check the current notification settings
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔍 Detailed Notification Settings:")
            print("   - Authorization Status: \(settings.authorizationStatus.rawValue)")
            print("   - Alert Setting: \(settings.alertSetting.rawValue)")
            print("   - Badge Setting: \(settings.badgeSetting.rawValue)")
            print("   - Sound Setting: \(settings.soundSetting.rawValue)")
            print("   - Notification Center Setting: \(settings.notificationCenterSetting.rawValue)")
            print("   - Lock Screen Setting: \(settings.lockScreenSetting.rawValue)")
            print("   - Car Play Setting: \(settings.carPlaySetting.rawValue)")
            
            // Create test notification content
            let content = UNMutableNotificationContent()
            content.title = "🔔 SyncN Test Alert"
            content.body = "Testing notifications on device! Time: \(Date().formatted(date: .omitted, time: .shortened))"
            content.sound = .default
            content.badge = NSNumber(value: 1)
            
            // Add custom data
            content.userInfo = [
                "type": "immediate_test_notification",
                "timestamp": Date().timeIntervalSince1970
            ]
            
            // Create trigger for immediate delivery (1 second)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            // Create unique identifier
            let identifier = "immediate_test_\(Date().timeIntervalSince1970)"
            
            // Create request
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling immediate test notification: \(error.localizedDescription)")
                } else {
                    print("✅ Immediate test notification scheduled - should appear in 1 second!")
                    print("🔍 Notification ID: \(identifier)")
                    
                    // Check if it was actually added
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                            let matchingRequest = requests.first { $0.identifier == identifier }
                            if matchingRequest != nil {
                                print("✅ Notification confirmed in pending queue")
                            } else {
                                print("❌ Notification NOT found in pending queue")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func sendTestDailyNotification() {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot send test daily notification - not authorized")
            return
        }
        
        // Create test daily notification content
        let content = UNMutableNotificationContent()
        content.title = "SyncN with your Body"
        content.body = "today's Morning Yoga" // Test workout title
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "type": "test_daily_workout_reminder"
        ]
        
        // Create trigger for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create unique identifier
        let identifier = "test_daily_notification_\(Date().timeIntervalSince1970)"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling test daily notification: \(error.localizedDescription)")
            } else {
                print("✅ Test daily notification scheduled - should appear in 5 seconds!")
            }
        }
    }
    
    // MARK: - Phase Change Notifications
    
    func schedulePhaseChangeNotification(userProfile: UserProfile, newPhase: CyclePhase, date: Date = Date()) {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule phase change notification - not authorized")
            return
        }
        
        // Cancel any existing phase change notifications first
        cancelPhaseChangeNotification()
        
        // Get phase-specific message
        let phaseMessage = getPhaseChangeMessage(for: newPhase)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = phaseMessage.header
        content.body = phaseMessage.body
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "type": "phase_change_notification",
            "phase": newPhase.rawValue
        ]
        
        // Create trigger for 8:08 AM on the specific date (first day of new phase)
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 8
        dateComponents.minute = 8
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let identifier = "phase_change_\(newPhase.rawValue)_\(Int(date.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling phase change notification: \(error.localizedDescription)")
            } else {
                print("✅ Phase change notification scheduled for \(newPhase.rawValue) on \(date) at 8:08 AM")
            }
        }
    }
    
    func cancelPhaseChangeNotification() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let phaseChangeIdentifiers = requests.compactMap { request in
                request.content.userInfo["type"] as? String == "phase_change_notification" ? request.identifier : nil
            }
            
            if !phaseChangeIdentifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: phaseChangeIdentifiers)
                print("🗑️ Cancelled \(phaseChangeIdentifiers.count) phase change notifications")
            }
        }
    }
    
    private func getPhaseChangeMessage(for phase: CyclePhase) -> NotificationMessage {
        switch phase {
        case .menstrual:
            return NotificationMessage(
                header: "Welcome to your Menstrual Phase",
                body: "Estrogen and progesterone are at their lowest. Your body is shedding and resetting. Focus on gentle movement, yoga, and restorative activities.",
                phase: .menstrual
            )
        case .follicular:
            return NotificationMessage(
                header: "Welcome to your Follicular Phase",
                body: "Estrogen is rising, boosting your energy and mood. This is your prime time for building strength, trying new workouts, and high-intensity training.",
                phase: .follicular
            )
        case .ovulatory:
            return NotificationMessage(
                header: "Welcome to your Ovulatory Phase",
                body: "Estrogen peaks and testosterone rises. You're at your strongest and most energetic. Perfect time for your most challenging workouts and peak performance.",
                phase: .ovulatory
            )
        case .luteal:
            return NotificationMessage(
                header: "Welcome to your Luteal Phase",
                body: "Progesterone dominates as your body prepares for potential pregnancy. Energy may fluctuate. Focus on moderate exercise, strength training, and listening to your body.",
                phase: .luteal
            )
        case .menstrualMoon:
            return NotificationMessage(
                header: "Welcome to your Moon-based Rest Phase",
                body: "Your body is in its natural rest and recovery mode. Hormones are resetting. Focus on gentle movement, yoga, and restorative activities.",
                phase: .menstrualMoon
            )
        case .follicularMoon:
            return NotificationMessage(
                header: "Welcome to your Moon-based Building Phase",
                body: "Your energy is rising with the moon's waxing phase. This is your prime time for building strength, trying new workouts, and high-intensity training.",
                phase: .follicularMoon
            )
        case .ovulatoryMoon:
            return NotificationMessage(
                header: "Welcome to your Moon-based Peak Phase",
                body: "You're at your peak energy with the full moon. Perfect time for your most challenging workouts and peak performance activities.",
                phase: .ovulatoryMoon
            )
        case .lutealMoon:
            return NotificationMessage(
                header: "Welcome to your Moon-based Winding Down Phase",
                body: "As the moon wanes, your energy naturally decreases. Focus on moderate exercise, strength training, and listening to your body's needs.",
                phase: .lutealMoon
            )
        }
    }
    
    // MARK: - Nutrition Habit Notifications
    
    func scheduleDailyNutritionReminder(userProfile: UserProfile? = nil) {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule daily nutrition notification - not authorized")
            return
        }
        
        // Cancel any existing nutrition notifications first
        cancelDailyNutritionNotification()
        
        // Only send notification if user has nutrition habits
        guard let userProfile = userProfile else {
            print("❌ Cannot schedule nutrition notification - no user profile")
            return
        }
        
        // Get nutrition habits for today
        let recommendation = NutritionRecommendationEngine.generateRecommendations(for: userProfile)
        
        // Only send notification if user has nutrition habits
        guard !recommendation.habits.isEmpty else {
            print("ℹ️ No nutrition habits found for user - skipping nutrition notification")
            return
        }
        
        // Get nutrition message based on user's habits for today
        let nutritionMessage = getNutritionMessageForHabits(userProfile: userProfile)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = nutritionMessage.header
        content.body = nutritionMessage.body
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "type": "daily_nutrition_reminder"
        ]
        
        // Create trigger for 11:00 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 11 // 11 AM
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create unique identifier
        let identifier = "daily_nutrition_reminder_11am"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling daily nutrition notification: \(error.localizedDescription)")
            } else {
                print("✅ Daily nutrition notification scheduled for 11:00 AM")
            }
        }
    }
    
    func cancelDailyNutritionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_nutrition_reminder_11am"])
        print("🗑️ Cancelled daily nutrition notification")
    }
    
    func scheduleNutritionHabitReminder(habitName: String, scheduledTime: Date) {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule nutrition habit notification - not authorized")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Nutrition Reminder"
        content.body = "Time to focus on \(habitName)!"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "type": "nutrition_habit_reminder",
            "habitName": habitName
        ]
        
        // Create trigger for the scheduled time
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: scheduledTime),
            repeats: true
        )
        
        // Create unique identifier
        let identifier = "nutrition_habit_\(habitName.replacingOccurrences(of: " ", with: "_"))"
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling nutrition habit notification: \(error.localizedDescription)")
            } else {
                print("✅ Nutrition habit notification scheduled for \(habitName)")
            }
        }
    }
    
    func cancelNutritionHabitReminder(habitName: String) {
        let identifier = "nutrition_habit_\(habitName.replacingOccurrences(of: " ", with: "_"))"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled nutrition habit notification: \(habitName)")
    }
    
    func cancelAllNutritionNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let nutritionIdentifiers = requests.compactMap { request in
                if let userInfo = request.content.userInfo as? [String: Any],
                   let type = userInfo["type"] as? String,
                   type.contains("nutrition") {
                    return request.identifier
                }
                return nil
            }
            
            if !nutritionIdentifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: nutritionIdentifiers)
                print("🗑️ Cancelled \(nutritionIdentifiers.count) nutrition notifications")
            }
        }
    }
    
    // MARK: - Nutrition Message Helper
    
    private func getRandomNutritionMessage() -> NotificationMessage {
        // Get all nutrition messages
        let allMessages = NotificationMessagesData.allMessages
        
        // For now, return a random message (in the future, this could be based on user's current cycle phase)
        return allMessages.randomElement() ?? NotificationMessage(
            header: "SyncN with your Body",
            body: "Don't forget to log your nutrition habits today!",
            phase: .follicular
        )
    }
    
    func getNutritionMessageForHabits(userProfile: UserProfile, date: Date = Date()) -> NotificationMessage {
        // Get nutrition habits for the specific date using the same logic as DashboardView
        let recommendation = NutritionRecommendationEngine.generateRecommendations(for: userProfile)
        
        // Ensure we have exactly 2 habits (as mentioned, there are always 2 habits given)
        guard recommendation.habits.count >= 2 else {
            // Fallback to random message if not exactly 2 habits
            return getRandomNutritionMessage()
        }
        
        // Calculate which habit to use based on the date (alternate daily)
        let calendar = Calendar.current
        let daysSinceEpoch = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: date).day ?? 0
        let habitIndex = daysSinceEpoch % 2 // This will alternate between 0 and 1
        
        let selectedHabit = recommendation.habits[habitIndex]
        
        // Find a matching message based on the selected habit name
        let matchingMessages = NotificationMessagesData.allMessages.filter { message in
            // Check if the habit name matches any part of the message header or body
            let habitNameLower = selectedHabit.name.lowercased()
            let headerLower = message.header.lowercased()
            let bodyLower = message.body.lowercased()
            
            return headerLower.contains(habitNameLower) || 
                   bodyLower.contains(habitNameLower) ||
                   habitNameLower.contains(headerLower) ||
                   habitNameLower.contains(bodyLower)
        }
        
        // Return the first matching message, or a random one if no match
        if let matchingMessage = matchingMessages.first {
            return matchingMessage
        }
        
        // Fallback to a random message if no specific match found
        return getRandomNutritionMessage()
    }
    
    // MARK: - Phase Change Detection
    
    func checkAndSchedulePhaseChangeNotification(userProfile: UserProfile, modelContext: ModelContext) {
        // Check if notifications are authorized
        guard authorizationStatus == .authorized else {
            print("❌ Cannot check for phase changes - notifications not authorized")
            return
        }
        
        // Get current phase
        guard let currentPhase = userProfile.currentCyclePhase else {
            print("❌ No current cycle phase found")
            return
        }
        
        // Check if we need to schedule a phase change notification
        // This would typically be called when the app launches or when phase data is updated
        schedulePhaseChangeNotification(userProfile: userProfile, newPhase: currentPhase)
    }
    
    // MARK: - Helper Methods
    
    func scheduleMultipleReminders(
        workoutTitle: String,
        instructor: String?,
        scheduledTime: Date,
        reminderMinutes: [Int] = [60, 15, 5] // 1 hour, 15 minutes, 5 minutes before
    ) {
        for minutes in reminderMinutes {
            scheduleFitnessClassReminder(
                workoutTitle: workoutTitle,
                instructor: instructor,
                scheduledTime: scheduledTime,
                reminderMinutes: minutes
            )
        }
        
        // Also schedule a notification for when the workout starts
        scheduleWorkoutStartNotification(
            workoutTitle: workoutTitle,
            instructor: instructor,
            scheduledTime: scheduledTime
        )
    }
}

// MARK: - SwiftUI Integration

struct NotificationPermissionView: View {
    @StateObject private var notificationManager = LocalNotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            // Title
            Text("Enable Notifications")
                .font(.custom("Sofia Pro", size: 24))
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Description
            Text("Get reminded about your scheduled workouts and stay on track with your fitness goals.")
                .font(.custom("Sofia Pro", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                NotificationBenefitRow(
                    icon: "clock",
                    title: "Workout Reminders",
                    description: "Get notified before your scheduled classes"
                )
                
                NotificationBenefitRow(
                    icon: "bell",
                    title: "Stay Consistent",
                    description: "Never miss a workout with timely notifications"
                )
                
                NotificationBenefitRow(
                    icon: "heart",
                    title: "Health Goals",
                    description: "Stay motivated and achieve your fitness targets"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    notificationManager.requestNotificationPermission()
                    dismiss()
                }) {
                    Text("Enable Notifications")
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Not Now")
                        .font(.custom("Sofia Pro", size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding(.top, 40)
    }
}

struct NotificationBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Sofia Pro", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.custom("Sofia Pro", size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NotificationPermissionView()
}