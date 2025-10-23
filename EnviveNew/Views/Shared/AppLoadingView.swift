import SwiftUI

// MARK: - App Loading View

/// Brief loading screen shown every time the app launches to refresh data
/// Ensures all data is up-to-date before showing main content
struct AppLoadingView: View {
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0.0
    @State private var currentStep = "Initializing..."

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // App logo or icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(loadingProgress * 360))
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: loadingProgress)
                }

                // App name
                Text("Envive")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)

                    Text(currentStep)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            performDataRefresh()
        }
    }

    // MARK: - Data Refresh

    private func performDataRefresh() {
        Task {
            // Step 1: Request notification permissions (300ms)
            await updateStep("Setting up notifications...", progress: 0.2)
            let notificationService = NotificationServiceImpl()
            _ = await notificationService.requestPermission()
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Step 2: Sync authentication state (300ms)
            await updateStep("Checking authentication...", progress: 0.4)
            try? await AuthenticationService.shared.refreshCurrentProfile()
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Step 3: Load household data (300ms)
            await updateStep("Loading household...", progress: 0.6)
            let authService = AuthenticationService.shared
            if let profile = authService.currentProfile {
                try? await HouseholdService.shared.getUserHousehold(userId: profile.id)
            }
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Step 4: Refresh task data (300ms)
            await updateStep("Syncing tasks...", progress: 0.8)
            // Task data is loaded on-demand by views, so just ensure services are ready
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Step 5: Finalize (200ms)
            await updateStep("Almost ready...", progress: 1.0)
            try? await Task.sleep(nanoseconds: 200_000_000)

            // Complete loading (minimum 1.7 seconds total)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }

                // Call completion after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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

/// Wrapper view that shows loading screen on app launch, then transitions to content
struct AppLoadingCoordinator<Content: View>: View {
    @State private var hasCompletedInitialLoad = false
    @State private var showContent = false
    @Environment(\.scenePhase) private var scenePhase

    let content: () -> Content

    var body: some View {
        ZStack {
            if showContent {
                content()
                    .transition(.opacity)
            } else {
                AppLoadingView {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showContent = true
                        hasCompletedInitialLoad = true
                    }
                }
                .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Refresh data when app becomes active (but don't show loading screen again)
            if newPhase == .active && hasCompletedInitialLoad {
                performBackgroundRefresh()
            }
        }
    }

    // MARK: - Background Refresh

    private func performBackgroundRefresh() {
        Task {
            print("🔄 Performing background data refresh...")

            // Quick refresh without showing loading screen
            try? await AuthenticationService.shared.refreshCurrentProfile()

            let authService = AuthenticationService.shared
            if let profile = authService.currentProfile {
                try? await HouseholdService.shared.getUserHousehold(userId: profile.id)
            }

            print("✅ Background refresh complete")
        }
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
