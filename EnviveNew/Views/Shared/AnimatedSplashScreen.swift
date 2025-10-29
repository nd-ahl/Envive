import SwiftUI

// MARK: - Animated Splash Screen

/// Animated splash screen shown immediately after iOS launch screen
/// Displays Envive branding with loading animation while app initializes and data loads
struct AnimatedSplashScreen: View {
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var fadeIn = false
    @State private var rotationAngle: Double = 0
    @State private var isLoadingData = true
    @State private var loadingError: String?

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Gradient background matching launch screen
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.5, blue: 0.9),   // Blue
                    Color(red: 0.5, green: 0.3, blue: 0.7)    // Purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()
                    .frame(minHeight: 80, maxHeight: 150)

                // Animated logo container
                ZStack {
                    // Outer pulsing circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                Color.white.opacity(0.3),
                                lineWidth: 2
                            )
                            .frame(width: 100 + CGFloat(index) * 30,
                                   height: 100 + CGFloat(index) * 30)
                            .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                            .opacity(pulseAnimation ? 0 : 0.6)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                                value: pulseAnimation
                            )
                    }

                    // Center logo circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)

                    // Sparkles icon with rotation
                    Image(systemName: "sparkles")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(rotationAngle))
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                }

                // App name
                Text("Envive")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .opacity(fadeIn ? 1 : 0)

                Spacer()
                    .frame(minHeight: 60, maxHeight: 120)

                // Loading indicator
                VStack(spacing: 16) {
                    // Animated dots
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                                .opacity(isAnimating ? 1 : 0.3)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }

                    Text(loadingError != nil ? "Error loading data" : "Loading your data...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(fadeIn ? 1 : 0)
                }

                Spacer()
                    .frame(minHeight: 100, maxHeight: 140)
            }
            .padding(.horizontal)
        }
        .onAppear {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🎬 AnimatedSplashScreen.onAppear() CALLED")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            startAnimations()
            startDataRefresh()
        }
        .onDisappear {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("👋 AnimatedSplashScreen.onDisappear() CALLED")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎬 AnimatedSplashScreen.init() CALLED")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - Animations

    private func startAnimations() {
        // Start all animations
        withAnimation(.easeOut(duration: 0.5)) {
            fadeIn = true
            isAnimating = true
        }

        // Continuous rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
    }

    // MARK: - Data Loading

    /// Trigger full data refresh and wait for completion
    private func startDataRefresh() {
        print("🎬🎬🎬 AnimatedSplashScreen.startDataRefresh() CALLED")
        Task {
            do {
                print("🔄🔄🔄 AnimatedSplashScreen: Starting full data refresh...")
                let startTime = Date()

                // CRITICAL FIX: Wait for AuthenticationService to finish loading profile
                // This is the race condition that causes data refresh to fail!
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("⏳ WAITING for AuthenticationService to be ready...")
                print("   - This prevents the race condition where refresh runs before profile loads")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                let authService = AuthenticationService.shared
                var waitCount = 0
                while authService.isCheckingAuth && waitCount < 50 {  // Max 5 seconds
                    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
                    waitCount += 1
                    if waitCount % 10 == 0 {
                        print("   - Still waiting for auth... (\(waitCount/10)s)")
                    }
                }

                if authService.isCheckingAuth {
                    print("⚠️⚠️⚠️ WARNING: AuthenticationService still checking after 5 seconds")
                    print("   - Proceeding anyway, but refresh may fail")
                } else {
                    print("✅ AuthenticationService is ready!")
                }

                print("📊 Authentication Status:")
                print("   - isAuthenticated: \(authService.isAuthenticated)")
                print("   - currentProfile exists: \(authService.currentProfile != nil)")
                if let profile = authService.currentProfile {
                    print("   - Profile: \(profile.fullName ?? "Unknown") (\(profile.id))")
                    print("   - Household ID: \(profile.householdId ?? "None")")
                } else {
                    print("   - ❌ NO PROFILE - THIS IS THE PROBLEM!")
                }
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                // Refresh all household and children data
                print("📞 AnimatedSplashScreen: Calling HouseholdService.refreshAllData()...")
                try await HouseholdService.shared.refreshAllData()

                let refreshDuration = Date().timeIntervalSince(startTime)
                print("✅✅✅ AnimatedSplashScreen: Data refresh completed in \(String(format: "%.2f", refreshDuration))s")

                // Ensure minimum display time of 1.5 seconds for better UX
                let remainingTime = max(0, 1.5 - refreshDuration)
                if remainingTime > 0 {
                    print("⏱️ AnimatedSplashScreen: Waiting \(String(format: "%.2f", remainingTime))s for minimum display time")
                    try await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
                }

                print("🎉 AnimatedSplashScreen: Transitioning to main app")
                await MainActor.run {
                    isLoadingData = false
                    withAnimation(.easeOut(duration: 0.5)) {
                        onComplete()
                    }
                }
            } catch {
                print("❌❌❌ AnimatedSplashScreen: Data refresh FAILED: \(error.localizedDescription)")
                print("❌ Error details: \(error)")

                await MainActor.run {
                    loadingError = error.localizedDescription
                    isLoadingData = false

                    // Still transition to main app after a brief delay
                    // (User can retry refresh from within the app)
                    print("⚠️ AnimatedSplashScreen: Transitioning to main app despite error")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            onComplete()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct AnimatedSplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedSplashScreen {
            print("Splash complete")
        }
    }
}
