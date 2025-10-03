import SwiftUI
import TelemetryDeck

// MARK: - Simple Symptom Log Button
struct SimpleSymptomLogButton: View {
    let selectedDate: Date
    @State private var showingSymptomLog = false
    
    var body: some View {
        Button(action: {
            TelemetryDeck.signal("Button.Clicked", parameters: [
                "buttonType": "symptom_log_button",
                "location": "dashboard"
            ])
            showingSymptomLog = true
        }) {
            HStack(spacing: 12) {
                // Plus icon in white circle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.957, green: 0.408, blue: 0.573))
                }
                
                Text("Log a symptom")
                    .font(.custom("Sofia Pro", size: 16, relativeTo: .subheadline))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.957, green: 0.408, blue: 0.573).opacity(0.4))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingSymptomLog) {
            DetailedSymptomLogView(selectedDate: selectedDate)
        }
    }
}
