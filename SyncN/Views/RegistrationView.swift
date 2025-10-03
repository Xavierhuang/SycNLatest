import SwiftUI
import TelemetryDeck

struct RegistrationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPassword = false
    @State private var showingConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var agreedToTerms = false
    
    let onSuccess: () -> Void
    let onBackToLogin: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Join SyncN and start your personalized wellness journey")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Registration Form
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField("Enter your full name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
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
                                    TextField("Create a password", text: $password)
                                } else {
                                    SecureField("Create a password", text: $password)
                                }
                                
                                Button(action: {
                                    showingPassword.toggle()
                                }) {
                                    Image(systemName: showingPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            // Password requirements
                            if !password.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    PasswordRequirement(
                                        text: "At least 8 characters",
                                        isValid: password.count >= 8
                                    )
                                    PasswordRequirement(
                                        text: "Contains a number",
                                        isValid: password.rangeOfCharacter(from: .decimalDigits) != nil
                                    )
                                    PasswordRequirement(
                                        text: "Contains uppercase letter",
                                        isValid: password.rangeOfCharacter(from: .uppercaseLetters) != nil
                                    )
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                if showingConfirmPassword {
                                    TextField("Confirm your password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm your password", text: $confirmPassword)
                                }
                                
                                Button(action: {
                                    showingConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showingConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            // Password match indicator
                            if !confirmPassword.isEmpty {
                                HStack {
                                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(passwordsMatch ? .green : .red)
                                        .font(.caption)
                                    
                                    Text(passwordsMatch ? "Passwords match" : "Passwords don't match")
                                        .font(.caption)
                                        .foregroundColor(passwordsMatch ? .green : .red)
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        // Terms Agreement
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: {
                                agreedToTerms.toggle()
                            }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreedToTerms ? .purple : .secondary)
                                    .font(.title3)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Button("Terms of Service") {
                                        // Open terms of service
                                    }
                                    .font(.body)
                                    .foregroundColor(.purple)
                                    
                                    Text("and")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    Button("Privacy Policy") {
                                        // Open privacy policy
                                    }
                                    .font(.body)
                                    .foregroundColor(.purple)
                                }
                            }
                        }
                        
                        // Error/Success Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        if !successMessage.isEmpty {
                            Text(successMessage)
                                .font(.body)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Register Button
                        Button(action: register) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color.purple : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.horizontal, 24)
                    
                    // Login Link
                    HStack {
                        Text("Already have an account?")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("Sign In") {
                            onBackToLogin()
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        onBackToLogin()
                    }
                }
            }
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "Registration",
                "pageType": "auth"
            ])
        }
    }
    
    private var passwordsMatch: Bool {
        return !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty &&
               !email.isEmpty &&
               isValidEmail(email) &&
               password.count >= 8 &&
               passwordsMatch &&
               agreedToTerms
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func register() {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            let result = await authManager.register(email: email, password: password, name: name)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success:
                    successMessage = "Account created successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onSuccess()
                    }
                case .failure(let error):
                    errorMessage = error
                }
            }
        }
    }
}

struct PasswordRequirement: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .green : .secondary)
        }
    }
}

#Preview {
    RegistrationView(
        onSuccess: { print("Registration successful") },
        onBackToLogin: { print("Back to login") }
    )
}
