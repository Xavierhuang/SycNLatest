import Foundation
import SwiftData

// MARK: - Authentication User Model
@Model
final class AuthUser {
    var id: UUID
    var email: String
    var passwordHash: String // Store hashed password, never plain text
    var name: String
    var isEmailVerified: Bool
    var createdAt: Date
    var lastLoginAt: Date?
    var userProfile: UserProfile?
    
    // Account settings
    var isAccountActive: Bool
    var hasCompletedOnboarding: Bool
    
    init(email: String, passwordHash: String, name: String) {
        self.id = UUID()
        self.email = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.passwordHash = passwordHash
        self.name = name
        self.isEmailVerified = false
        self.createdAt = Date()
        self.isAccountActive = true
        self.hasCompletedOnboarding = false
    }
}

// MARK: - Authentication Session Model
@Model
final class AuthSession {
    var id: UUID
    var userId: UUID
    var token: String
    var expiresAt: Date
    var createdAt: Date
    var deviceInfo: String?
    var isActive: Bool
    
    init(userId: UUID, token: String, expiresAt: Date, deviceInfo: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.token = token
        self.expiresAt = expiresAt
        self.createdAt = Date()
        self.deviceInfo = deviceInfo
        self.isActive = true
    }
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}

// MARK: - Password Reset Token Model
@Model
final class PasswordResetToken {
    var id: UUID
    var userId: UUID
    var token: String
    var expiresAt: Date
    var isUsed: Bool
    var createdAt: Date
    
    init(userId: UUID, token: String, expiresAt: Date) {
        self.id = UUID()
        self.userId = userId
        self.token = token
        self.expiresAt = expiresAt
        self.isUsed = false
        self.createdAt = Date()
    }
    
    var isExpired: Bool {
        return Date() > expiresAt || isUsed
    }
}

// MARK: - Authentication States
enum AuthenticationState {
    case loading
    case authenticated(AuthUser)
    case unauthenticated
    case error(String)
}

// MARK: - Registration Result
enum RegistrationResult {
    case success(AuthUser)
    case failure(String)
}

// MARK: - Login Result
enum LoginResult {
    case success(AuthUser)
    case failure(String)
}

// MARK: - Authentication Error
enum AuthenticationError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case requestFailed(Int)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .requestFailed(let code):
            return "Request failed with status code: \(code)"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - API Response Models
struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let data: AuthResponseData?
}

struct AuthResponseData: Codable {
    let user: AuthUserData
    let tokens: TokenData
}

struct AuthUserData: Codable {
    let id: String
    let email: String
    let name: String
    let isEmailVerified: Bool
    let createdAt: String?
    let lastLoginAt: String?
}

struct TokenData: Codable {
    let accessToken: String
    let refreshToken: String
}

struct TokenRefreshResponse: Codable {
    let success: Bool
    let message: String
    let data: TokenRefreshData?
}

struct TokenRefreshData: Codable {
    let tokens: TokenData
}

struct UserProfileResponse: Codable {
    let success: Bool
    let data: UserProfileData
}

struct UserProfileData: Codable {
    let user: AuthUserData
}
