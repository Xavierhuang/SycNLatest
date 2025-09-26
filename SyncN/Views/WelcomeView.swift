import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.08, green: 0.11, blue: 0.17),
                        Color(red: 0.12, green: 0.15, blue: 0.21)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top section with purple background
                        VStack(spacing: 20) {
                            // Shield icon badge
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.894, green: 0.843, blue: 0.953))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 30)
                            
                            // Main title
                            Text("The Most Secure Women's Fitness App")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            // Subtitle
                            Text("Created by women, for women, with your privacy as our priority")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                Color(red: 0.608, green: 0.431, blue: 0.953)
                                
                                // Subtle circular patterns
                                ForEach(0..<4) { i in
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: CGFloat(50 + i * 15), height: CGFloat(50 + i * 15))
                                        .offset(x: CGFloat(i * 30 - 60), y: CGFloat(i * 20 - 40))
                                }
                            }
                        )
                        .padding(.bottom, 30)
                        
                        // Middle section with privacy features
                        VStack(spacing: 24) {
                            Text("How We Protect Your Data")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            VStack(spacing: 20) {
                                // Device-only storage
                                PrivacyFeatureRow(
                                    icon: "lock.shield",
                                    title: "Device-Only Storage",
                                    description: "Your cycle and health data stays on your device. We don't store it on our servers."
                                )
                                
                                // No account required
                                PrivacyFeatureRow(
                                    icon: "person.crop.circle.badge.xmark",
                                    title: "No Account Required",
                                    description: "We don't collect email addresses or require account creation to use the app."
                                )
                                
                                // Privacy by design
                                PrivacyFeatureRow(
                                    icon: "checkmark.circle",
                                    title: "Privacy by Design",
                                    description: "Built from the ground up with privacy as a core principle, not an afterthought."
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Continue button
                        Button(action: {
                            print("🔍 WelcomeView: Get Started button tapped")
                            UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                            print("🔍 WelcomeView: Calling onGetStarted()")
                            onGetStarted()
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.608, green: 0.431, blue: 0.953),
                                            Color(red: 0.557, green: 0.671, blue: 0.557)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(28)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .stroke(Color(red: 0.608, green: 0.431, blue: 0.953), lineWidth: 2)
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 0.608, green: 0.431, blue: 0.953))
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}
