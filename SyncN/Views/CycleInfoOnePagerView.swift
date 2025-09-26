import SwiftUI
import SwiftData

struct CycleInfoOnePagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var personalizationData: [PersonalizationData]
    
    @State private var isEditing = false
    @State private var cycleLength: Int = 28
    @State private var periodLength: Int = 5
    @State private var lastPeriodStart: Date = Date()
    @State private var cycleType: CycleType = .regular
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var personalization: PersonalizationData? {
        personalizationData.first { $0.userId == userProfile?.id }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Cycle Information")
                            .font(.custom("Sofia Pro", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Your menstrual cycle details")
                            .font(.custom("Sofia Pro", size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Current Cycle Status
                    if let profile = userProfile {
                        VStack(spacing: 16) {
                            Text("Current Cycle Status")
                                .font(.custom("Sofia Pro", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 20) {
                                CycleStatusCard(
                                    title: "Cycle Day",
                                    value: "\(currentCycleDay)",
                                    icon: "calendar.badge.clock",
                                    color: .blue
                                )
                                
                                CycleStatusCard(
                                    title: "Phase",
                                    value: currentPhase,
                                    icon: "moon.fill",
                                    color: .purple
                                )
                            }
                            
                            HStack(spacing: 20) {
                                CycleStatusCard(
                                    title: "Next Period",
                                    value: nextPeriodDate,
                                    icon: "calendar.badge.exclamationmark",
                                    color: .pink
                                )
                                
                                CycleStatusCard(
                                    title: "Cycle Type",
                                    value: profile.cycleTypeDisplayName,
                                    icon: "waveform.path.ecg",
                                    color: .green
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                    }
                    
                    // Cycle Details Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Cycle Details")
                                .font(.custom("Sofia Pro", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(isEditing ? "Save" : "Edit") {
                                if isEditing {
                                    saveCycleInfo()
                                }
                                isEditing.toggle()
                            }
                            .font(.custom("Sofia Pro", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 16) {
                            CycleDetailRow(
                                title: "Cycle Length",
                                value: "\(cycleLength) days",
                                isEditing: isEditing,
                                editContent: {
                                    Stepper("\(cycleLength) days", value: $cycleLength, in: 21...35)
                                }
                            )
                            
                            CycleDetailRow(
                                title: "Period Length",
                                value: "\(periodLength) days",
                                isEditing: isEditing,
                                editContent: {
                                    Stepper("\(periodLength) days", value: $periodLength, in: 3...10)
                                }
                            )
                            
                            CycleDetailRow(
                                title: "Last Period Start",
                                value: lastPeriodStart.formatted(.dateTime.month().day()),
                                isEditing: isEditing,
                                editContent: {
                                    DatePicker("Last Period Start", selection: $lastPeriodStart, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                }
                            )
                            
                            CycleDetailRow(
                                title: "Cycle Type",
                                value: cycleType.rawValue,
                                isEditing: isEditing,
                                editContent: {
                                    Picker("Cycle Type", selection: $cycleType) {
                                        ForEach(CycleType.allCases, id: \.self) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Cycle Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                }
            }
        }
        .onAppear {
            loadCurrentData()
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentCycleDay: Int {
        guard let profile = userProfile,
              let lastStart = profile.lastPeriodStart else { return 1 }
        
        let calendar = Calendar.current
        let daysSinceLastPeriod = calendar.dateComponents([.day], from: lastStart, to: Date()).day ?? 0
        return min(daysSinceLastPeriod + 1, profile.cycleLength ?? 28)
    }
    
    private var currentPhase: String {
        guard let profile = userProfile else { return "Unknown" }
        
        let phase = CyclePredictionService.shared.getPhaseForDate(Date(), userProfile: profile)
        return phase?.rawValue.capitalized ?? "Unknown"
    }
    
    private var nextPeriodDate: String {
        guard let profile = userProfile,
              let lastStart = profile.lastPeriodStart else { return "Unknown" }
        
        let calendar = Calendar.current
        let nextPeriod = calendar.date(byAdding: .day, value: profile.cycleLength ?? 28, to: lastStart) ?? Date()
        return nextPeriod.formatted(.dateTime.month().day())
    }
    
    // MARK: - Methods
    
    private func loadCurrentData() {
        guard let profile = userProfile else { return }
        
        cycleLength = profile.cycleLength ?? 28
        periodLength = profile.averagePeriodLength ?? 5
        lastPeriodStart = profile.lastPeriodStart ?? Date()
        cycleType = profile.cycleType ?? .regular
    }
    
    private func saveCycleInfo() {
        guard let profile = userProfile else { return }
        
        profile.cycleLength = cycleLength
        profile.averagePeriodLength = periodLength
        profile.lastPeriodStart = lastPeriodStart
        profile.cycleType = cycleType
        profile.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving cycle info: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct CycleStatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.custom("Sofia Pro", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.custom("Sofia Pro", size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CycleDetailRow<EditContent: View>: View {
    let title: String
    let value: String
    let isEditing: Bool
    @ViewBuilder let editContent: () -> EditContent
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Sofia Pro", size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            if isEditing {
                editContent()
            } else {
                Text(value)
                    .font(.custom("Sofia Pro", size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CycleInfoOnePagerView()
        .modelContainer(for: [UserProfile.self, PersonalizationData.self], inMemory: true)
}