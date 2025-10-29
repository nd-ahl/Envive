import SwiftUI

// MARK: - App Loading View

/// Animated, multi-colorful loading screen shown every time the app launches
/// Triggers full data refresh to ensure parents see up-to-date children overview
struct AppLoadingView: View {
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0.0
    @State private var currentStep = "Initializing..."
    @State private var animationOffset: CGFloat = 0
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Animated multi-color gradient background
            AnimatedGradientBackground(animationOffset: $animationOffset)
                .ignoresSafeArea()

            // Floating particles
            ForEach(0..<20, id: \.self) { index in
                FloatingParticle(index: index, animationOffset: animationOffset)
            }

            VStack(spacing: 30) {
                Spacer()

                // Animated logo with multi-color glow
                ZStack {
                    // Outer glow circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        gradientColors[index % gradientColors.count].opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120 + CGFloat(index) * 20, height: 120 + CGFloat(index) * 20)
                            .scaleEffect(pulseAnimation ? 1.0 : 0.8)
                            .opacity(pulseAnimation ? 0.6 : 0.3)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: pulseAnimation
                            )
                    }

                    // Main logo circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.purple.opacity(0.5), radius: 20, x: 0, y: 0)

                    // Sparkles icon with rotation
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: rotationAngle)
                }

                // App name with gradient
                Text("Envive")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                Spacer()

                // Loading indicator with colorful progress
                VStack(spacing: 20) {
                    // Custom colorful progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 200, height: 8)

                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue, Color.purple, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 200 * loadingProgress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                    }

                    Text(currentStep)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .opacity(0.95)
                }

                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            startAnimations()
            performDataRefresh()
        }
    }

    // MARK: - Animation Control

    private func startAnimations() {
        pulseAnimation = true
        rotationAngle = 360

        // Continuous background animation
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            animationOffset = 360
        }
    }

    // Gradient colors for animations
    private let gradientColors: [Color] = [
        .blue, .purple, .pink, .orange, .cyan, .indigo
    ]

    // MARK: - Data Refresh

    private func performDataRefresh() {
        Task {
            // Step 1: Request notification permissions
            await updateStep("Setting up notifications...", progress: 0.15)
            let notificationService = NotificationServiceImpl()
            _ = await notificationService.requestPermission()

            // Step 2: Sync authentication state
            await updateStep("Checking authentication...", progress: 0.3)
            try? await AuthenticationService.shared.refreshCurrentProfile()

            // Step 3: Load household data
            await updateStep("Loading household data...", progress: 0.5)
            let authService = AuthenticationService.shared
            if let profile = authService.currentProfile {
                try? await HouseholdService.shared.getUserHousehold(userId: profile.id)
            }

            // Step 4: Refresh children data (critical for parent dashboard)
            await updateStep("Refreshing children overview...", progress: 0.7)
            let householdService = HouseholdService.shared
            if householdService.currentHousehold != nil {
                _ = try? await householdService.getMyChildren()
            }

            // Step 5: Sync task data
            await updateStep("Syncing tasks and activities...", progress: 0.85)
            // Task data will be loaded on-demand by views

            // Step 6: Finalize
            await updateStep("Almost ready...", progress: 1.0)

            // Small delay to show completion
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            // Complete loading
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.5)) {
                    isLoading = false
                }

                // Call completion after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }

    private func updateStep(_ step: String, progress: Double) async {
        await MainActor.run {
            withAnimation {
                currentStep = step
                loadingProgress = progress
            }
        }
    }
}

// MARK: - App Loading Coordinator

/// Wrapper view that shows content immediately and performs data refresh in background
struct AppLoadingCoordinator<Content: View>: View {
    @State private var hasCompletedInitialLoad = false
    @Environment(\.scenePhase) private var scenePhase

    let content: () -> Content

    var body: some View {
        content()
            .task {
                // Perform initial data refresh in background on first launch
                if !hasCompletedInitialLoad {
                    await performInitialDataRefresh()
                    hasCompletedInitialLoad = true
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Refresh data when app becomes active
                if newPhase == .active && hasCompletedInitialLoad {
                    performBackgroundRefresh()
                }
            }
    }

    // MARK: - Initial Data Refresh

    /// Perform initial data refresh in background on app launch
    private func performInitialDataRefresh() async {
        print("🔄 Performing initial data refresh in background...")

        // Request notification permissions
        let notificationService = NotificationServiceImpl()
        _ = await notificationService.requestPermission()

        // Sync authentication state
        try? await AuthenticationService.shared.refreshCurrentProfile()

        // Load household data
        let authService = AuthenticationService.shared
        if let profile = authService.currentProfile {
            try? await HouseholdService.shared.getUserHousehold(userId: profile.id)
        }

        print("✅ Initial data refresh complete")
    }

    // MARK: - Background Refresh

    private func performBackgroundRefresh() {
        Task {
            print("🔄 Performing background data refresh...")

            // Quick refresh without blocking UI
            try? await AuthenticationService.shared.refreshCurrentProfile()

            let authService = AuthenticationService.shared
            if let profile = authService.currentProfile {
                try? await HouseholdService.shared.getUserHousehold(userId: profile.id)
            }

            print("✅ Background refresh complete")
        }
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @Binding var animationOffset: CGFloat

    private let colors: [Color] = [
        Color(red: 0.4, green: 0.5, blue: 0.9),  // Blue
        Color(red: 0.5, green: 0.3, blue: 0.7),  // Purple
        Color(red: 0.9, green: 0.3, blue: 0.5),  // Pink
        Color(red: 0.3, green: 0.7, blue: 0.9),  // Cyan
        Color(red: 0.4, green: 0.4, blue: 0.8),  // Indigo
    ]

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [colors[0], colors[1], colors[2]],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated overlay gradient 1
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors[1].opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 500, height: 500)
                .offset(
                    x: cos(animationOffset * .pi / 180) * 150,
                    y: sin(animationOffset * .pi / 180) * 150
                )
                .blur(radius: 60)

            // Animated overlay gradient 2
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors[2].opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 500, height: 500)
                .offset(
                    x: cos(animationOffset * .pi / 180 + 2) * 150,
                    y: sin(animationOffset * .pi / 180 + 2) * 150
                )
                .blur(radius: 60)

            // Animated overlay gradient 3
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors[3].opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 500, height: 500)
                .offset(
                    x: cos(animationOffset * .pi / 180 + 4) * 150,
                    y: sin(animationOffset * .pi / 180 + 4) * 150
                )
                .blur(radius: 60)
        }
    }
}

// MARK: - Floating Particle

struct FloatingParticle: View {
    let index: Int
    let animationOffset: CGFloat

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.3))
            .frame(width: particleSize, height: particleSize)
            .offset(x: xOffset, y: yOffset)
            .blur(radius: 2)
    }

    private var particleSize: CGFloat {
        CGFloat.random(in: 3...8)
    }

    private var xOffset: CGFloat {
        let baseX = CGFloat(index % 5 - 2) * 100
        let animatedX = cos(animationOffset * .pi / 180 + Double(index)) * 50
        return baseX + animatedX
    }

    private var yOffset: CGFloat {
        let baseY = CGFloat(index % 4 - 2) * 150
        let animatedY = sin(animationOffset * .pi / 180 + Double(index) * 1.5) * 60
        return baseY + animatedY
    }
}

// MARK: - Preview

struct AppLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        AppLoadingView {
            print("Loading complete")
        }
    }
}
