import SwiftUI
import SwiftData
import TelemetryDeck

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = LocalNotificationManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                    
                    Text("Fitness Reminders")
                        .font(.sofiaProTitle2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Stay on track with your fitness goals")
                        .font(.sofiaProSubheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Notification Status
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: notificationManager.authorizationStatus == .authorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(notificationManager.authorizationStatus == .authorized ? .green : .orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notification Status")
                                .font(.sofiaProHeadline)
                                .foregroundColor(.white)
                            
                            Text(statusText)
                                .font(.sofiaProSubheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Daily Reminder Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Workout Reminder")
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Every day at \(notificationManager.getNotificationTimeString())")
                                .font(.sofiaProSubheadline)
                                .foregroundColor(.white)
                            
                            Text("Only when you have incomplete workouts")
                                .font(.sofiaProCaption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Phase Change Notification Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Phase Change Notifications")
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("First day of each new cycle phase at 8:08 AM")
                                .font(.sofiaProSubheadline)
                                .foregroundColor(.white)
                            
                            Text("Welcome to your new phase with personalized tips")
                                .font(.sofiaProCaption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Daily Nutrition Reminder Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Nutrition Reminder")
                        .font(.sofiaProHeadline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color(red: 0.157, green: 0.851, blue: 0.851))
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Every day at 11:00 AM")
                                .font(.sofiaProSubheadline)
                                .foregroundColor(.white)
                            
                            Text("Reminds you to track your daily nutrition habits")
                                .font(.sofiaProCaption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if notificationManager.authorizationStatus != .authorized {
                        Button(action: {
                            TelemetryDeck.signal("Button.Clicked", parameters: [
                                "buttonType": "enable_notifications",
                                "location": "notification_settings"
                            ])
                            enableNotifications()
                        }) {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text("Enable Notifications")
                            }
                            .font(.sofiaProHeadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.957, green: 0.408, blue: 0.573))
                            .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        TelemetryDeck.signal("Button.Clicked", parameters: [
                            "buttonType": "done_button",
                            "location": "notification_settings"
                        ])
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.sofiaProHeadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .background(Color.black)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        TelemetryDeck.signal("Button.Clicked", parameters: [
                            "buttonType": "done_button",
                            "location": "notification_settings_toolbar"
                        ])
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "NotificationSettings",
                "pageType": "settings_feature"
            ])
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
    }
    
    private var statusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "Notifications are enabled"
        case .denied:
            return "Notifications are disabled. Enable in Settings."
        case .notDetermined:
            return "Tap 'Enable Notifications' to get started"
        case .provisional:
            return "Provisional notifications enabled"
        case .ephemeral:
            return "Ephemeral notifications enabled"
        @unknown default:
            return "Unknown status"
        }
    }
    
    private func enableNotifications() {
        notificationManager.requestNotificationPermission()
        notificationManager.checkAndScheduleDailyNotification(modelContext: modelContext)
        
        // Get user profile for notifications
        let userProfile = userProfiles.first
        if let userProfile = userProfile {
            // Schedule nutrition reminder
            notificationManager.scheduleDailyNutritionReminder(userProfile: userProfile)
            
            // Schedule phase change notification
            notificationManager.checkAndSchedulePhaseChangeNotification(userProfile: userProfile, modelContext: modelContext)
        }
    }
}

#Preview {
    NotificationSettingsView()
}
