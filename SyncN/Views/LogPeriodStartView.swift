import SwiftUI
import SwiftData
import TelemetryDeck

struct LogPeriodStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    private var dateRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        
        var dates: [Date] = []
        var currentDate = startDate
        
        // Generate dates from 30 days ago to today
        while currentDate <= today {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Return dates in ascending order so today appears on the rightmost side
        // This gives us: [oldest, ..., newest] which displays as oldest on left, today on right
        print("📅 DateRange generated: \(dates.count) dates")
        if let firstDate = dates.first, let lastDate = dates.last {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            print("📅 First date: \(formatter.string(from: firstDate))")
            print("📅 Last date: \(formatter.string(from: lastDate))")
            print("📅 Today: \(formatter.string(from: today))")
        }
        return dates
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Main question
                Text("When did your period start?")
                    .font(.custom("Sofia Pro", size: 28, relativeTo: .title))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                
                // Date picker
                VStack(spacing: 16) {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(dateRange, id: \.self) { date in
                                    DateCard(
                                        date: date,
                                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                        isToday: Calendar.current.isDateInToday(date)
                                    ) {
                                        selectedDate = date
                                    }
                                    .id(date)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .onAppear {
                            // Ensure selectedDate is set to today
                            selectedDate = Calendar.current.startOfDay(for: Date())
                            
                            // Immediately scroll to today, then animate to final position
                            if let lastDate = dateRange.last {
                                proxy.scrollTo(lastDate, anchor: .trailing)
                            }
                            
                            // Animate to final position after a brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    if let lastDate = dateRange.last {
                                        proxy.scrollTo(lastDate, anchor: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Log period button
                Button(action: {
                    logPeriodStart()
                }) {
                    Text("Log period")
                        .font(.custom("Sofia Pro", size: 18, relativeTo: .headline))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "LogPeriodStart",
                "pageType": "logging_feature"
            ])
        }
    }
    
    private func logPeriodStart() {
        guard let userProfile = userProfile else { return }
        
        // Update the user's last period start date
        userProfile.lastPeriodStart = selectedDate
        
        do {
            try modelContext.save()
            print("✅ Period start logged for: \(selectedDate)")
            dismiss()
        } catch {
            print("❌ Error logging period start: \(error)")
        }
    }
}

struct DateCard: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.custom("Sofia Pro", size: 24, relativeTo: .title2))
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .black)
                
                Text(monthName)
                    .font(.custom("Sofia Pro", size: 14, relativeTo: .caption))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .black.opacity(0.7))
            }
            .frame(width: 60, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? Color.orange.opacity(0.3) : Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            // Today indicator
            Group {
                if isToday {
                    VStack {
                        Spacer()
                        Text("TODAY")
                            .font(.custom("Sofia Pro", size: 10, relativeTo: .caption2))
                            .fontWeight(.medium)
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.top, 4)
                    }
                }
            }
        )
    }
}

#Preview {
    LogPeriodStartView()
        .modelContainer(for: [UserProfile.self, PersonalizationData.self], inMemory: true)
}
