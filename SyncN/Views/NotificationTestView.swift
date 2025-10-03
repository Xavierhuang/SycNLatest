import SwiftUI
import UserNotifications

struct NotificationTestView: View {
    @StateObject private var notificationManager = LocalNotificationManager.shared
    @State private var isTestingActive = false
    @State private var testStatus = "Ready to test"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Notification Testing")
                        .font(.custom("Sofia Pro", size: 28))
                        .fontWeight(.bold)
                    
                    Text("Test your push notification setup")
                        .font(.custom("Sofia Pro", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Status Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Status")
                            .font(.custom("Sofia Pro", size: 18))
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Authorization:")
                                .font(.custom("Sofia Pro", size: 14))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(authorizationStatusText)
                                .font(.custom("Sofia Pro", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(authorizationStatusColor)
                        }
                        
                        HStack {
                            Text("Test Status:")
                                .font(.custom("Sofia Pro", size: 14))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(testStatus)
                                .font(.custom("Sofia Pro", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Test Buttons
                VStack(spacing: 16) {
                    // Immediate Test Notification (better for simulator)
                    Button(action: {
                        testStatus = "Sending immediate test..."
                        notificationManager.sendImmediateTestNotification()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            testStatus = "Immediate test sent (check in 1 second)"
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            testStatus = "Ready to test"
                        }
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Send Immediate Test")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(notificationManager.authorizationStatus != .authorized)
                    
                    // Single Test Notification (3 second delay)
                    Button(action: {
                        testStatus = "Sending test notification..."
                        notificationManager.sendTestNotification()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            testStatus = "Test notification sent (check in 3 seconds)"
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            testStatus = "Ready to test"
                        }
                    }) {
                        HStack {
                            Image(systemName: "bell")
                            Text("Send 3-Second Test")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(notificationManager.authorizationStatus != .authorized)
                    
                    // Minutely Test Notifications
                    Button(action: {
                        if isTestingActive {
                            // Stop testing
                            notificationManager.cancelMinutelyTestNotifications()
                            isTestingActive = false
                            testStatus = "Minutely tests cancelled"
                        } else {
                            // Start testing
                            notificationManager.startMinutelyTestNotifications()
                            isTestingActive = true
                            testStatus = "10 minutely notifications scheduled"
                            
                            // Auto-disable after 11 minutes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 660) {
                                isTestingActive = false
                                testStatus = "Minutely test completed"
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: isTestingActive ? "stop.circle" : "timer")
                            Text(isTestingActive ? "Stop Minutely Tests" : "Start Minutely Tests")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isTestingActive ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(notificationManager.authorizationStatus != .authorized)
                    
                    // Check Status
                    Button(action: {
                        notificationManager.getTestNotificationStatus()
                        testStatus = "Status logged to console"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            testStatus = "Ready to test"
                        }
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                            Text("Check Status")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Troubleshoot Button
                    Button(action: {
                        troubleshootNotifications()
                        testStatus = "Troubleshooting info logged to console"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            testStatus = "Ready to test"
                        }
                    }) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                            Text("Troubleshoot")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                // Simulator Warning
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Simulator Limitations")
                            .font(.custom("Sofia Pro", size: 18))
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ iOS Simulator has known issues with local notifications")
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.primary)
                        
                        Text("✅ For reliable testing, use a physical device")
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.green)
                        
                        Text("🔍 Check console logs to verify notifications are scheduled")
                            .font(.custom("Sofia Pro", size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Testing Steps")
                            .font(.custom("Sofia Pro", size: 18))
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionRow(number: "1", text: "Make sure notifications are authorized")
                        InstructionRow(number: "2", text: "Try 'Send Immediate Test' first (1 second delay)")
                        InstructionRow(number: "3", text: "Background the app to see notifications")
                        InstructionRow(number: "4", text: "Use 'Check Status' to verify scheduling worked")
                        InstructionRow(number: "5", text: "For best results, test on a physical device")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if notificationManager.authorizationStatus != .authorized {
                    Button(action: {
                        notificationManager.requestNotificationPermission()
                    }) {
                        HStack {
                            Image(systemName: "bell.badge")
                            Text("Request Notification Permission")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                }
                .padding()
            }
            .navigationTitle("Notification Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
    }
    
    func troubleshootNotifications() {
        print("🔧 NOTIFICATION TROUBLESHOOTING")
        print(String(repeating: "=", count: 50))
        
        // Check authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 Device Settings:")
            print("   - Authorization: \(settings.authorizationStatus)")
            print("   - Alert Style: \(settings.alertStyle)")
            print("   - Badge: \(settings.badgeSetting)")
            print("   - Sound: \(settings.soundSetting)")
            print("   - Critical Alert: \(settings.criticalAlertSetting)")
            print("   - Provisional: \(settings.providesAppNotificationSettings)")
            print("   - Time Sensitive: \(settings.timeSensitiveSetting)")
            
            // Check pending notifications
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                print("⏳ Pending Notifications: \(requests.count)")
                for request in requests.prefix(3) {
                    print("   - \(request.content.title) (\(request.identifier))")
                }
            }
            
            // Check delivered notifications
            UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
                print("📬 Delivered Notifications: \(delivered.count)")
                for notification in delivered.prefix(3) {
                    print("   - \(notification.request.content.title)")
                }
            }
        }
        
        print("💡 Common Issues:")
        print("   1. Check Settings > Notifications > SyncN")
        print("   2. Ensure 'Allow Notifications' is ON")
        print("   3. Check 'Lock Screen', 'Notification Center', 'Banners' are enabled")
        print("   4. Try restarting the device")
        print("   5. Background the app before testing")
    }
    
    var authorizationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "✅ Authorized"
        case .denied:
            return "❌ Denied"
        case .notDetermined:
            return "⚠️ Not Requested"
        case .provisional:
            return "⚠️ Provisional"
        case .ephemeral:
            return "⚠️ Ephemeral"
        @unknown default:
            return "❓ Unknown"
        }
    }
    
    var authorizationStatusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        default:
            return .orange
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.custom("Sofia Pro", size: 14))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.custom("Sofia Pro", size: 14))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct NotificationTestView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationTestView()
    }
}
