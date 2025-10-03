import SwiftUI
import TelemetryDeck

struct UserProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingEditProfile = false
    @State private var showingChangePassword = false
    @State private var showingDeleteAccount = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    HStack(spacing: 16) {
                        // Profile Picture
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(authManager.currentUser?.name.prefix(1).uppercased() ?? "?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.name ?? "Unknown User")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(authManager.currentUser?.email ?? "No email")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            if let lastLogin = authManager.currentUser?.lastLoginAt {
                                Text("Last login: \(lastLogin, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Account Information")
                }
                
                // Account Management Section
                Section {
                    NavigationLink(destination: UserEditProfileView()) {
                        Label("Edit Profile", systemImage: "person.circle")
                    }
                    
                    Button(action: {
                        showingChangePassword = true
                    }) {
                        Label("Change Password", systemImage: "key")
                    }
                    
                    NavigationLink(destination: AccountSettingsView()) {
                        Label("Account Settings", systemImage: "gearshape")
                    }
                } header: {
                    Text("Account Management")
                }
                
                // Data & Privacy Section
                Section {
                    NavigationLink(destination: DataExportView()) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy Settings", systemImage: "hand.raised")
                    }
                } header: {
                    Text("Data & Privacy")
                }
                
                // Support Section
                Section {
                    NavigationLink(destination: HelpSupportView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: ContactUsView()) {
                        Label("Contact Us", systemImage: "envelope")
                    }
                } header: {
                    Text("Support")
                }
                
                // Danger Zone
                Section {
                    Button(action: {
                        showingDeleteAccount = true
                    }) {
                        Label("Delete Account", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Deleting your account will permanently remove all your data and cannot be undone.")
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authManager.logout()
                    }
                    .foregroundColor(.purple)
                }
            }
        }
        .alert("Change Password", isPresented: $showingChangePassword) {
            // This would show a change password form
            Button("OK") { }
        } message: {
            Text("Password change functionality will be implemented in the next update.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // This would implement account deletion
                print("Account deletion requested")
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "UserProfile",
                "pageType": "profile_management"
            ])
        }
    }
}

// MARK: - Edit Profile View
struct UserEditProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var email: String
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    init() {
        _name = State(initialValue: AuthenticationManager.shared.currentUser?.name ?? "")
        _email = State(initialValue: AuthenticationManager.shared.currentUser?.email ?? "")
    }
    
    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            
            if !successMessage.isEmpty {
                Section {
                    Text(successMessage)
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(name.isEmpty || email.isEmpty || isLoading)
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            let success = await authManager.updateUserProfile(name: name, email: email)
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    successMessage = "Profile updated successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else {
                    errorMessage = "Failed to update profile. Please try again."
                }
            }
        }
    }
}

// MARK: - Placeholder Views
struct AccountSettingsView: View {
    var body: some View {
        Text("Account Settings")
            .navigationTitle("Account Settings")
    }
}

struct DataExportView: View {
    var body: some View {
        Text("Data Export")
            .navigationTitle("Export Data")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy Settings")
    }
}

struct HelpSupportView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Help & Support")
    }
}

struct ContactUsView: View {
    var body: some View {
        Text("Contact Us")
            .navigationTitle("Contact Us")
    }
}

#Preview {
    UserProfileView()
}
