import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    // Called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Notification received while app is in foreground:")
        print("   - Title: \(notification.request.content.title)")
        print("   - Body: \(notification.request.content.body)")
        print("   - Identifier: \(notification.request.identifier)")
        
        // Show the notification even when the app is in the foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // Called when the user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 User tapped notification:")
        print("   - Title: \(response.notification.request.content.title)")
        print("   - Body: \(response.notification.request.content.body)")
        print("   - Identifier: \(response.notification.request.identifier)")
        print("   - Action Identifier: \(response.actionIdentifier)")
        
        // Handle the notification tap here
        handleNotificationTap(response: response)
        
        completionHandler()
    }
    
    private func handleNotificationTap(response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "test_notification", "immediate_test_notification", "minutely_test_notification":
                print("🧪 Test notification tapped - type: \(type)")
                // You could navigate to a specific screen or show an alert here
                
            case "daily_workout_reminder":
                print("💪 Daily workout reminder tapped")
                // Navigate to workout screen
                
            case "fitness_reminder":
                print("🏃‍♀️ Fitness reminder tapped")
                // Navigate to specific workout
                
            case "phase_change_notification":
                print("🌙 Phase change notification tapped")
                // Navigate to cycle information
                
            case "daily_nutrition_reminder":
                print("🥗 Nutrition reminder tapped")
                // Navigate to nutrition tracking
                
            default:
                print("❓ Unknown notification type: \(type)")
            }
        }
    }
}
