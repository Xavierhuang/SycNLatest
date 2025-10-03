import SwiftUI
import TelemetryDeck

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingRegistration = false
    
    let onAuthenticationComplete: () -> Void
    let onSkipAuthentication: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showingRegistration {
                RegistrationView(
                    onSuccess: {
                        onAuthenticationComplete()
                    },
                    onBackToLogin: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingRegistration = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                LoginView(
                    onSuccess: {
                        onAuthenticationComplete()
                    },
                    onSkipAuth: {
                        onSkipAuthentication()
                    },
                    onShowRegistration: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingRegistration = true
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            TelemetryDeck.signal("Page.Viewed", parameters: [
                "pageName": "Authentication",
                "pageType": "auth_flow"
            ])
        }
    }
}

// MARK: - Authentication Wrapper
struct AuthenticationWrapper<Content: View>: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var hasSkippedAuth = false
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                LoadingView()
            case .authenticated:
                content
            case .unauthenticated:
                if hasSkippedAuth {
                    content
                } else {
                    AuthenticationView(
                        onAuthenticationComplete: {
                            // Authentication completed, user is now logged in
                        },
                        onSkipAuthentication: {
                            hasSkippedAuth = true
                        }
                    )
                }
            case .error(let message):
                ErrorView(message: message) {
                    // Retry authentication check
                    authManager.configure(with: modelContext)
                }
            }
        }
        .onAppear {
            if authManager.modelContext == nil {
                authManager.configure(with: modelContext)
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Something went wrong")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button("Try Again") {
                    onRetry()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.purple)
                .cornerRadius(12)
            }
        }
    }
}

#Preview("Login") {
    AuthenticationView(
        onAuthenticationComplete: {
            print("Authentication completed")
        },
        onSkipAuthentication: {
            print("Skip authentication")
        }
    )
}

#Preview("Loading") {
    LoadingView()
}

#Preview("Error") {
    ErrorView(message: "Failed to connect to the server") {
        print("Retry tapped")
    }
}
