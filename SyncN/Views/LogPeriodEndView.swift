import SwiftUI
import SwiftData

struct LogPeriodEndView: View {
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
                Text("When did your period end?")
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
                
                // Log period end button
                Button(action: {
                    logPeriodEnd()
                }) {
                    Text("Log period end")
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
    }
    
    private func logPeriodEnd() {
        guard let userProfile = userProfile else { return }
        
        // Calculate the period start date based on the end date and average period length
        let calendar = Calendar.current
        let periodStartDate = calendar.date(byAdding: .day, value: -(userProfile.averagePeriodLength ?? 0), to: selectedDate) ?? selectedDate
        
        // Update the user's last period start date
        userProfile.lastPeriodStart = periodStartDate
        
        do {
            try modelContext.save()
            print("✅ Period end logged for: \(selectedDate), period start calculated as: \(periodStartDate)")
            print("🔍 This means \(selectedDate) will be cycle day \((userProfile.averagePeriodLength ?? 5) + 1) (follicular phase)")
            dismiss()
        } catch {
            print("❌ Error logging period end: \(error)")
        }
    }
}


#Preview {
    LogPeriodEndView()
        .modelContainer(for: [UserProfile.self, PersonalizationData.self], inMemory: true)
}
