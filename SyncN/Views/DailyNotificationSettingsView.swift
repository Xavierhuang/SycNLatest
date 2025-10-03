import SwiftUI
import SwiftData

struct DailyNotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    @State private var dailyWorkoutReminder = true
    @State private var phaseChangeReminder = true
    @State private var nutritionReminder = true
    @State private var workoutReminderTime = Date()
    @State private var nutritionReminderTime = Date()
    
    private let notificationManager = LocalNotificationManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Reminders")
                            .font(.sofiaProLargeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Stay on track with personalized reminders")
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Workout Reminders Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Workout Reminders")
                            .font(.sofiaProTitle2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            // Daily Workout Reminder
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Daily Workout Reminder")
                                        .font(.sofiaProHeadline)
                                        .foregroundColor(.white)
                                    
                                    Text("Get reminded about your scheduled workouts")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $dailyWorkoutReminder)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.608, green: 0.431, blue: 0.953)))
                            }
                            .padding()
                            .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                            .cornerRadius(12)
                            
                            // Workout Reminder Time
                            if dailyWorkoutReminder {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Reminder Time")
                                        .font(.sofiaProSubheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    DatePicker("", selection: $workoutReminderTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(WheelDatePickerStyle())
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                                .padding()
                                .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Phase Change Reminders Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cycle Reminders")
                            .font(.sofiaProTitle2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            // Phase Change Reminder
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Phase Change Reminder")
                                        .font(.sofiaProHeadline)
                                        .foregroundColor(.white)
                                    
                                    Text("Get notified when your cycle phase changes")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $phaseChangeReminder)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.608, green: 0.431, blue: 0.953)))
                            }
                            .padding()
                            .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Nutrition Reminders Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Reminders")
                            .font(.sofiaProTitle2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            // Nutrition Reminder
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Daily Nutrition Reminder")
                                        .font(.sofiaProHeadline)
                                        .foregroundColor(.white)
                                    
                                    Text("Get reminded about your nutrition habits")
                                        .font(.sofiaProCaption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $nutritionReminder)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.608, green: 0.431, blue: 0.953)))
                            }
                            .padding()
                            .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                            .cornerRadius(12)
                            
                            // Nutrition Reminder Time
                            if nutritionReminder {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Reminder Time")
                                        .font(.sofiaProSubheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    DatePicker("", selection: $nutritionReminderTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(WheelDatePickerStyle())
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                                .padding()
                                .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.black)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNotificationSettings()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadNotificationSettings()
        }
    }
    
    private func loadNotificationSettings() {
        // Load current notification settings
        // This would typically load from UserDefaults or a settings model
        workoutReminderTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
        nutritionReminderTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    private func saveNotificationSettings() {
        // Save notification settings
        if dailyWorkoutReminder {
            notificationManager.scheduleDailyWorkoutReminder()
        } else {
            notificationManager.cancelDailyWorkoutNotification()
        }
        
        if phaseChangeReminder {
            // Get the current user profile and phase for phase change notifications
            if let userProfile = userProfiles.first,
               let currentPhase = userProfile.currentCyclePhase {
                notificationManager.schedulePhaseChangeNotification(userProfile: userProfile, newPhase: currentPhase)
            }
        } else {
            notificationManager.cancelPhaseChangeNotification()
        }
        
        if nutritionReminder {
            // Get the current user profile for nutrition notifications
            if let userProfile = userProfiles.first {
                notificationManager.scheduleDailyNutritionReminder(userProfile: userProfile)
            }
        } else {
            notificationManager.cancelDailyNutritionNotification()
        }
        
        dismiss()
    }
}