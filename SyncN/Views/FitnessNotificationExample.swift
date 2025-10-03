import SwiftUI

struct FitnessNotificationExample: View {
    @StateObject private var notificationManager = LocalNotificationManager.shared
    @State private var selectedWorkout = "Morning Yoga"
    @State private var selectedInstructor = "Sarah"
    @State private var scheduledTime = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var showingPermissionView = false
    
    let workoutOptions = ["Morning Yoga", "HIIT Workout", "Pilates", "Strength Training", "Dance Cardio"]
    let instructorOptions = ["Sarah", "Mike", "Emma", "David", "Lisa"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Schedule Workout Reminder")
                        .font(.custom("Sofia Pro", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Get notified before your fitness class starts")
                        .font(.custom("Sofia Pro", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Workout Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Workout")
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Picker("Workout", selection: $selectedWorkout) {
                        ForEach(workoutOptions, id: \.self) { workout in
                            Text(workout).tag(workout)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Instructor Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Instructor")
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Picker("Instructor", selection: $selectedInstructor) {
                        ForEach(instructorOptions, id: \.self) { instructor in
                            Text(instructor).tag(instructor)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Scheduled Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scheduled Time")
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    DatePicker("", selection: $scheduledTime, in: Date()...)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: scheduleNotifications) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Schedule Reminders")
                        }
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        notificationManager.cancelAllFitnessNotifications()
                    }) {
                        HStack {
                            Image(systemName: "bell.slash.fill")
                            Text("Cancel All Reminders")
                        }
                        .font(.custom("Sofia Pro", size: 16))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .navigationTitle("Fitness Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            checkNotificationPermission()
        }
        .sheet(isPresented: $showingPermissionView) {
            NotificationPermissionView()
        }
    }
    
    private func checkNotificationPermission() {
        if notificationManager.authorizationStatus == .denied {
            showingPermissionView = true
        }
    }
    
    private func scheduleNotifications() {
        // Check if notifications are authorized
        if notificationManager.authorizationStatus != .authorized {
            showingPermissionView = true
            return
        }
        
        // Schedule multiple reminders
        notificationManager.scheduleMultipleReminders(
            workoutTitle: selectedWorkout,
            instructor: selectedInstructor,
            scheduledTime: scheduledTime,
            reminderMinutes: [60, 15, 5] // 1 hour, 15 minutes, 5 minutes before
        )
        
        // Show confirmation
        print("✅ Scheduled notifications for \(selectedWorkout) with \(selectedInstructor) at \(scheduledTime)")
    }
}

#Preview {
    FitnessNotificationExample()
}
