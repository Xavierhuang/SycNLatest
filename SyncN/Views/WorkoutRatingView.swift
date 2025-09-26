import SwiftUI
import SwiftData

struct WorkoutRatingView: View {
    let workoutTitle: String
    let instructor: String?
    let onRatingSubmitted: (Int, String?) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedRating: Int = 0
    @State private var notes: String = ""
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Rating dialog
            VStack(spacing: 20) {
                
                // Main content
                VStack(spacing: 16) {
                    // Question text
                    Text("How would you rate")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(workoutTitle)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if let instructor = instructor, instructor != "You" {
                        Text("by \(instructor)")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                
                // Star rating
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            selectedRating = star
                        }) {
                            ZStack {
                                // Star background
                                Image(systemName: "star.fill")
                                    .font(.title)
                                    .foregroundColor(selectedRating >= star ? Color.blue : Color.gray.opacity(0.3))
                                
                                // Star number
                                Text("\(star)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(selectedRating >= star ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: selectedRating)
                    }
                }
                .padding(.vertical, 8)
                
                // Notes section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Add any notes about this workout...", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Submit button (only show when rating is selected)
                if selectedRating > 0 {
                    Button(action: {
                        onRatingSubmitted(selectedRating, notes.isEmpty ? nil : notes)
                        onDismiss()
                    }) {
                        Text("Submit Rating")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    WorkoutRatingView(
        workoutTitle: "Sculpted Arms Pilates",
        instructor: "Krsna",
        onRatingSubmitted: { rating, notes in
            print("Rating submitted: \(rating), Notes: \(notes ?? "none")")
        },
        onDismiss: {
            print("Rating dismissed")
        }
    )
}
