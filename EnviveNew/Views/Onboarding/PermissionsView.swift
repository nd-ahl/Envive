import SwiftUI
import FamilyControls

// MARK: - Permissions View

/// Guides users through granting Screen Time access with instructional alert mock
struct PermissionsView: View {
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var isRequestingPermission = false
    @State private var permissionGranted = false

    private let authorizationCenter = AuthorizationCenter.shared

    var body: some View {
        ZStack {
            // Gradient background (consistent with other onboarding screens)
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Content
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Instructional alert mock with arrow
                    instructionalAlertMock
                }
                .padding(.horizontal, 32)

                Spacer()

                // Bottom security text and learn more
                bottomSecuritySection
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "hourglass")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Connect Envive to Screen Time")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("To manage screen time on this iPhone, Envive needs your permission")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Instructional Alert Mock (Non-Functional)

    private var instructionalAlertMock: some View {
        VStack(spacing: 0) {
            // Title + Body
            VStack(spacing: 12) {
                Text("\u{201C}Envive\u{201D} Would Like to Access Screen Time")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                Text("Providing \u{201C}Envive\u{201D} access to Screen Time may allow it to see your activity data, restrict content, and limit the usage of apps and websites.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(red: 0.43, green: 0.43, blue: 0.45)) // #6D6D72
                    .multilineTextAlignment(.center)
                    .lineSpacing(1) // ~1.07 line height
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }

            // Top hairline divider
            Divider()
                .background(Color(red: 0.78, green: 0.78, blue: 0.78)) // #C6C6C8

            // Buttons row (FUNCTIONAL - tapping Continue will request permission)
            HStack(spacing: 0) {
                // Continue button (left) - FUNCTIONAL with visual feedback
                Button(action: {
                    requestPermission()
                }) {
                    ZStack(alignment: .leading) {
                        HStack(spacing: 8) {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.0, green: 0.48, blue: 1.0)))
                                    .scaleEffect(0.8)
                                Text("Requesting...")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                            } else if permissionGranted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(.green)
                                Text("Granted")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.green)
                            } else {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0)) // #007AFF
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)

                        // Green arrow pointing to Continue (only show when idle)
                        if !isRequestingPermission && !permissionGranted {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.green)
                                Text("Tap to continue")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .offset(y: 60)
                        }
                    }
                }
                .disabled(isRequestingPermission || permissionGranted)

                // Vertical divider
                Rectangle()
                    .fill(Color(red: 0.78, green: 0.78, blue: 0.78)) // #C6C6C8
                    .frame(width: 1 / UIScreen.main.scale, height: 44)

                // Don't Allow button (right) - greyed out/disabled appearance
                Text("Don't Allow")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3)) // Faded to show it's not the action
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .frame(width: 270)
        .background(Color.white)
        .cornerRadius(13)
        .shadow(color: .black.opacity(0.10), radius: 30, x: 0, y: 0)
        .opacity(showContent ? 1.0 : 0)
        .scaleEffect(showContent ? 1.0 : 0.95)
    }


    // MARK: - Bottom Security Section

    private var bottomSecuritySection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                Text("Your sensitive data is protected by Apple and never leaves your device")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            Button(action: {
                // Open Apple's Screen Time privacy page
                if let url = URL(string: "https://support.apple.com/en-us/HT208982") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Learn More About Screen Time Privacy")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .underline()
            }
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Actions

    private func requestPermission() {
        isRequestingPermission = true

        Task {
            do {
                try await authorizationCenter.requestAuthorization(for: .individual)

                // Permission granted
                await MainActor.run {
                    isRequestingPermission = false
                    permissionGranted = true

                    print("✅ Screen Time authorization granted")

                    // Wait a moment to show success state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onComplete()
                    }
                }
            } catch {
                // Permission denied or error
                await MainActor.run {
                    isRequestingPermission = false
                    permissionGranted = false

                    print("❌ Screen Time authorization failed: \(error)")

                    // Still complete onboarding - user can grant later from Settings
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PermissionsView(onComplete: {})
                .previewDisplayName("Permissions - Light")

            PermissionsView(onComplete: {})
                .preferredColorScheme(.dark)
                .previewDisplayName("Permissions - Dark")
        }
    }
}
