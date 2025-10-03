import Foundation
import SwiftData
import CryptoKit
import Combine
import UIKit
import TelemetryDeck

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var authState: AuthenticationState = .loading
    @Published var currentUser: AuthUser?
    @Published var isAuthenticated = false
    
    var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // Backend configuration
    private let baseURL = "http://localhost:8000"
    private let session = URLSession.shared
    private var accessToken: String?
    private var refreshToken: String?
    
    private init() {
        // Private initializer for singleton
        loadStoredTokens()
    }
    
    // MARK: - Setup
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    private func checkAuthenticationStatus() {
        // Check if we have stored tokens
        guard let accessToken = accessToken else {
            authState = .unauthenticated
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        // Verify token with backend
        Task {
            do {
                let response: UserProfileResponse = try await makeRequest(
                    endpoint: "/api/user/profile",
                    method: "GET",
                    responseType: UserProfileResponse.self
                )
                
                if response.success {
                    let userData = response.data.user
                    let user = AuthUser(email: userData.email, passwordHash: "", name: userData.name)
                    user.id = UUID(uuidString: userData.id) ?? UUID()
                    user.isEmailVerified = userData.isEmailVerified
                    user.lastLoginAt = userData.lastLoginAt != nil ? ISO8601DateFormatter().date(from: userData.lastLoginAt!) : Date()
                    
                    await MainActor.run {
                        currentUser = user
                        isAuthenticated = true
                        authState = .authenticated(user)
                    }
                } else {
                    await MainActor.run {
                        clearTokens()
                        authState = .unauthenticated
                        isAuthenticated = false
                        currentUser = nil
                    }
                }
            } catch {
                await MainActor.run {
                    clearTokens()
                    authState = .unauthenticated
                    isAuthenticated = false
                    currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Token Management
    private func loadStoredTokens() {
        accessToken = UserDefaults.standard.string(forKey: "access_token")
        refreshToken = UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    private func storeTokens(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
        UserDefaults.standard.set(access, forKey: "access_token")
        UserDefaults.standard.set(refresh, forKey: "refresh_token")
    }
    
    private func clearTokens() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
    }
    
    // MARK: - Backend API Methods
    private func makeRequest<T: Codable>(endpoint: String, method: String = "GET", body: Data? = nil, responseType: T.Type) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw AuthenticationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            // Try to refresh token
            if let refreshToken = refreshToken {
                let refreshSuccess = await refreshAccessToken()
                if refreshSuccess {
                    // Retry the original request
                    request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
                    let (retryData, retryResponse) = try await session.data(for: request)
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                        throw AuthenticationError.invalidResponse
                    }
                    guard retryHttpResponse.statusCode == 200 else {
                        throw AuthenticationError.requestFailed(retryHttpResponse.statusCode)
                    }
                    return try JSONDecoder().decode(T.self, from: retryData)
                }
            }
            throw AuthenticationError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthenticationError.requestFailed(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func refreshAccessToken() async -> Bool {
        guard let refreshToken = refreshToken else { return false }
        
        do {
            let requestData = ["refreshToken": refreshToken]
            let body = try JSONSerialization.data(withJSONObject: requestData)
            
            let response: TokenRefreshResponse = try await makeRequest(
                endpoint: "/api/auth/refresh",
                method: "POST",
                body: body,
                responseType: TokenRefreshResponse.self
            )
            
            if response.success, let tokens = response.data?.tokens {
                storeTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
                return true
            }
        } catch {
            print("Token refresh failed: \(error)")
        }
        
        return false
    }
    
    // MARK: - Registration
    func register(email: String, password: String, name: String) async -> RegistrationResult {
        // Validate input
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            return .failure("All fields are required")
        }
        
        guard isValidEmail(email) else {
            return .failure("Please enter a valid email address")
        }
        
        guard password.count >= 8 else {
            return .failure("Password must be at least 8 characters long")
        }
        
        do {
            // Call backend registration API
            let requestData = [
                "email": email.lowercased(),
                "password": password,
                "name": name
            ]
            
            let body = try JSONSerialization.data(withJSONObject: requestData)
            let response: AuthResponse = try await makeRequest(
                endpoint: "/api/auth/register",
                method: "POST",
                body: body,
                responseType: AuthResponse.self
            )
            
            guard response.success, let userData = response.data?.user, let tokens = response.data?.tokens else {
                return .failure("Registration failed")
            }
            
            // Store tokens
            storeTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
            
            // Create local user object
            let newUser = AuthUser(email: userData.email, passwordHash: "", name: userData.name)
            newUser.id = UUID(uuidString: userData.id) ?? UUID()
            newUser.isEmailVerified = userData.isEmailVerified
            
            // Create local user profile
            if let context = modelContext {
                let userProfile = UserProfile(name: name, birthDate: Date())
                newUser.userProfile = userProfile
                
                context.insert(userProfile)
                try context.save()
            }
            
            // Update state
            currentUser = newUser
            isAuthenticated = true
            authState = .authenticated(newUser)
            
            TelemetryDeck.signal("User.Registered", parameters: [
                "method": "backend_api",
                "hasProfile": "true"
            ])
            
            return .success(newUser)
            
        } catch let error as AuthenticationError {
            return .failure(error.localizedDescription)
        } catch {
            return .failure("Registration failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String) async -> LoginResult {
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            return .failure("Email and password are required")
        }
        
        do {
            // Call backend login API
            let requestData = [
                "email": email.lowercased(),
                "password": password
            ]
            
            let body = try JSONSerialization.data(withJSONObject: requestData)
            let response: AuthResponse = try await makeRequest(
                endpoint: "/api/auth/login",
                method: "POST",
                body: body,
                responseType: AuthResponse.self
            )
            
            guard response.success, let userData = response.data?.user, let tokens = response.data?.tokens else {
                return .failure("Invalid email or password")
            }
            
            // Store tokens
            storeTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
            
            // Create local user object
            let user = AuthUser(email: userData.email, passwordHash: "", name: userData.name)
            user.id = UUID(uuidString: userData.id) ?? UUID()
            user.isEmailVerified = userData.isEmailVerified
            user.lastLoginAt = userData.lastLoginAt != nil ? ISO8601DateFormatter().date(from: userData.lastLoginAt!) : Date()
            
            // Update state
            currentUser = user
            isAuthenticated = true
            authState = .authenticated(user)
            
            TelemetryDeck.signal("User.LoggedIn", parameters: [
                "method": "backend_api",
                "hasProfile": "true"
            ])
            
            return .success(user)
            
        } catch let error as AuthenticationError {
            if case .requestFailed(401) = error {
                return .failure("Invalid email or password")
            }
            return .failure(error.localizedDescription)
        } catch {
            return .failure("Login failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Logout
    func logout() {
        Task {
            do {
                // Call backend logout API
                _ = try await makeRequest(
                    endpoint: "/api/auth/logout",
                    method: "POST",
                    responseType: AuthResponse.self
                )
            } catch {
                print("Backend logout failed: \(error)")
            }
            
            // Clear local tokens and state
            await MainActor.run {
                clearTokens()
                currentUser = nil
                isAuthenticated = false
                authState = .unauthenticated
                
                TelemetryDeck.signal("User.LoggedOut", parameters: [
                    "method": "manual"
                ])
            }
        }
    }
    
    // MARK: - Password Reset
    func requestPasswordReset(email: String) async -> Bool {
        do {
            let requestData = ["email": email.lowercased()]
            let body = try JSONSerialization.data(withJSONObject: requestData)
            
            let response: AuthResponse = try await makeRequest(
                endpoint: "/api/auth/forgot-password",
                method: "POST",
                body: body,
                responseType: AuthResponse.self
            )
            
            TelemetryDeck.signal("User.PasswordResetRequested", parameters: [
                "email": email
            ])
            
            return response.success
            
        } catch {
            print("Password reset request failed: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func generateSecureToken() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<32).map { _ in characters.randomElement()! })
    }
    
    private func createSession(for user: AuthUser) -> AuthSession {
        let token = generateSecureToken()
        let expiresAt = Date().addingTimeInterval(30 * 24 * 3600) // 30 days
        let deviceInfo = UIDevice.current.name
        
        return AuthSession(userId: user.id, token: token, expiresAt: expiresAt, deviceInfo: deviceInfo)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - User Profile Management
    func updateUserProfile(name: String? = nil, email: String? = nil) async -> Bool {
        guard let context = modelContext, let user = currentUser else {
            return false
        }
        
        do {
            if let newName = name {
                user.name = newName
                user.userProfile?.name = newName
            }
            
            if let newEmail = email, isValidEmail(newEmail) {
                // Check if email is already taken
                let lowercasedNewEmail = newEmail.lowercased()
                let emailCheckRequest = FetchDescriptor<AuthUser>(
                    predicate: #Predicate<AuthUser> { existingUser in
                        existingUser.email == lowercasedNewEmail
                    }
                )
                
                let existingUsers = try context.fetch(emailCheckRequest)
                // Filter out the current user to check if email is taken by someone else
                let otherUsers = existingUsers.filter { $0.id != user.id }
                if !otherUsers.isEmpty {
                    return false // Email already taken by another user
                }
                
                user.email = lowercasedNewEmail
                user.isEmailVerified = false // Require re-verification
            }
            
            try context.save()
            return true
            
        } catch {
            return false
        }
    }
}
