import SwiftUI
import SwiftData

struct EditPeriodDatesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    @State private var selectedDate = Date()
    @State private var showingLogPeriodStart = false
    @State private var showingLogPeriodEnd = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.08, green: 0.11, blue: 0.17)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Custom header with lighter title
                    HStack {
                        Spacer()
                        Text("Edit Period Dates")
                            .font(.sofiaProTitle3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    // Date display
                    VStack(spacing: 8) {
                        Text(selectedDate, style: .date)
                            .font(.sofiaProTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(selectedDate, format: .dateTime.weekday(.wide))
                            .font(.sofiaProSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    // Action cards
                    VStack(spacing: 16) {
                        // Log Period Start Card
                        Button(action: {
                            showingLogPeriodStart = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Log Period Start")
                                        .font(.sofiaProHeadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Mark when your period began")
                                        .font(.sofiaProSubheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.sofiaProSubheadline)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.1, green: 0.12, blue: 0.18))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Log Period End Card
                        Button(action: {
                            showingLogPeriodEnd = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: "calendar.badge.minus")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Log Period End")
                                        .font(.sofiaProHeadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Mark when your period ended")
                                        .font(.sofiaProSubheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.sofiaProSubheadline)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.1, green: 0.12, blue: 0.18))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.sofiaProTitle3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.sofiaProBody)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingLogPeriodStart) {
            LogPeriodStartView()
        }
        .sheet(isPresented: $showingLogPeriodEnd) {
            LogPeriodEndView()
        }
    }
}