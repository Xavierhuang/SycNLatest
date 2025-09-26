import SwiftUI

struct NotificationMessagesView: View {
    @State private var selectedPhase: CyclePhase = .follicular
    @State private var selectedCategory: String? = nil
    
    var filteredMessages: [NotificationMessage] {
        let phaseMessages = NotificationMessagesData.messagesForPhase(selectedPhase)
        
        if let category = selectedCategory {
            return phaseMessages.filter { $0.category == category }
        }
        
        return phaseMessages
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Phase Selector
                Picker("Phase", selection: $selectedPhase) {
                    ForEach(NotificationMessagesData.allPhases(), id: \.self) { phase in
                        Text(phase.displayName).tag(phase)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button("All") {
                            selectedCategory = nil
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(20)
                        
                        ForEach(NotificationMessagesData.allCategories(), id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Messages List
                List(filteredMessages) { message in
                    NotificationMessageCard(message: message)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Notification Messages")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct NotificationMessageCard: View {
    let message: NotificationMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text(message.header)
                .font(.custom("Sofia Pro", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Body
            Text(message.body)
                .font(.custom("Sofia Pro", size: 16))
                .foregroundColor(.secondary)
                .lineLimit(nil)
            
            // Category and Phase
            HStack {
                if let category = message.category {
                    Text(category)
                        .font(.custom("Sofia Pro", size: 12))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Text(message.phase.displayName)
                    .font(.custom("Sofia Pro", size: 12))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    NotificationMessagesView()
}
