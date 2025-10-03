import SwiftUI
import TelemetryDeck

struct CoachingBookingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTime = "9:00 AM"
    @State private var notes = ""
    @State private var showingContactOptions = false
    
    let coachName = "Lizzy"
    let coachPhone = "760-473-5137"
    
    let timeSlots = [
        "9:00 AM", "10:00 AM", "11:00 AM", "1:00 PM", 
        "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Book 1:1 Coaching")
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                        
                        Text("Get personalized guidance from \(coachName)")
                            .font(.sofiaProBody)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Date Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Date")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                        
                        DatePicker("Appointment Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Time Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Time")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(timeSlots, id: \.self) { time in
                                Button(action: {
                                    selectedTime = time
                                }) {
                                    Text(time)
                                        .font(.sofiaProBody)
                                        .foregroundColor(selectedTime == time ? .white : .primary)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedTime == time ? Color.purple : Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session Goals (Optional)")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                        
                        TextField("What would you like to focus on during this session?", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.sofiaProHeadline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.purple)
                                Text("Coach: \(coachName)")
                                    .font(.sofiaProBody)
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.purple)
                                Text("Phone: \(coachPhone)")
                                    .font(.sofiaProBody)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            .navigationTitle("Book Coaching")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Contact") {
                        showingContactOptions = true
                    }
                    .foregroundColor(.purple)
                }
            }
        }
        .actionSheet(isPresented: $showingContactOptions) {
            ActionSheet(
                title: Text("Contact \(coachName)"),
                message: Text("Choose how you'd like to contact \(coachName) for your 1:1 coaching session"),
                buttons: [
                    .default(Text("Call \(coachPhone)")) {
                        if let url = URL(string: "tel:\(coachPhone)") {
                            UIApplication.shared.open(url)
                        }
                        TelemetryDeck.signal("Coaching.Contact", parameters: [
                            "method": "phone_call",
                            "coach": coachName
                        ])
                    },
                    .default(Text("Send Text Message")) {
                        sendTextMessage()
                        TelemetryDeck.signal("Coaching.Contact", parameters: [
                            "method": "text_message",
                            "coach": coachName
                        ])
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "CoachingBooking",
                "pageType": "feature"
            ])
        }
    }
    
    private func sendTextMessage() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        let formattedDate = dateFormatter.string(from: selectedDate)
        
        let message = """
        Hi Lizzy! I'd like to book a 1:1 coaching session with you.
        
        Preferred Date: \(formattedDate)
        Preferred Time: \(selectedTime)
        
        \(notes.isEmpty ? "" : "Session Goals: \(notes)")
        
        Please let me know if this works for you. Thank you!
        """
        
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let smsURL = "sms:\(coachPhone)&body=\(encodedMessage)"
        
        if let url = URL(string: smsURL) {
            UIApplication.shared.open(url)
        }
    }
}

struct CoachingBookingCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Book 1:1 Coaching")
                        .font(.sofiaProHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Get personalized guidance from Lizzy")
                        .font(.sofiaProBody)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CoachingBookingView()
}

#Preview("Coaching Card") {
    CoachingBookingCard {
        print("Tapped coaching card")
    }
    .padding()
}
