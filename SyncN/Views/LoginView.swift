import SwiftUI
import TelemetryDeck

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingForgotPassword = false
    
    let onSuccess: () -> Void
    let onSkipAuth: (() -> Void)?
    let onShowRegistration: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in to continue your SyncN journey")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                if showingPassword {
                                    TextField("Enter your password", text: $password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                }
                                
                                Button(action: {
                                    showingPassword.toggle()
                                }) {
                                    Image(systemName: showingPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showingForgotPassword = true
                            }
                            .font(.body)
                            .foregroundColor(.purple)
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Login Button
                        Button(action: login) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(email.isEmpty || password.isEmpty ? Color.gray : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                    }
                    .padding(.horizontal, 24)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                        
                        Text("or")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    .padding(.horizontal, 24)
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("Sign Up") {
                            // Show registration view
                            if let showRegistration = onShowRegistration {
                                showRegistration()
                            } else {
                                // Fallback for standalone use
                                onSuccess()
                            }
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    }
                    
                    // Continue without account option
                    if let skipAuth = onSkipAuth {
                        Button(action: skipAuth) {
                            Text("Continue without account")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .underline()
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "Login",
                "pageType": "auth"
            ])
        }
        .alert("Reset Password", isPresented: $showingForgotPassword) {
            TextField("Email", text: $email)
            Button("Send Reset Link") {
                Task {
                    await resetPassword()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your email address to receive a password reset link.")
        }
    }
    
    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            let result = await authManager.login(email: email, password: password)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    errorMessage = error
                }
            }
        }
    }
    
    private func resetPassword() async {
        let success = await authManager.requestPasswordReset(email: email)
        
        await MainActor.run {
            if success {
                errorMessage = "Password reset link sent to your email"
            } else {
                errorMessage = "Failed to send reset link. Please try again."
            }
        }
    }
}

#Preview {
    LoginView(
        onSuccess: {
            print("Login successful")
        },
        onSkipAuth: {
            print("Skip authentication")
        },
        onShowRegistration: {
            print("Show registration")
        }
    )
}
