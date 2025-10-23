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

                    // Step-by-step instructions
                    instructionsSection
                        .padding(.horizontal, 24)

                    // Request permission button
                    instructionalAlertMock
                        .padding(.horizontal, 32)
                }

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

    // MARK: - Step-by-Step Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Follow these steps:")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 4)

            // Step 1
            instructionStep(
                number: "1",
                text: "Tap the \"Request Permission\" button below"
            )

            // Step 2
            instructionStep(
                number: "2",
                text: "A system alert will appear from iOS"
            )

            // Step 3
            instructionStep(
                number: "3",
                text: "On the alert, tap \"Continue\" (the button on the LEFT side)",
                highlight: true
            )

            // Visual helper
            alertVisualHelper
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
        .opacity(showContent ? 1.0 : 0)
    }

    private func instructionStep(number: String, text: String, highlight: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Number circle
            ZStack {
                Circle()
                    .fill(highlight ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 32, height: 32)

                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            // Text
            Text(text)
                .font(.system(size: 16, weight: highlight ? .bold : .medium))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var alertVisualHelper: some View {
        VStack(spacing: 12) {
            Text("The alert will look like this:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            // Mock alert visual
            VStack(spacing: 0) {
                // Alert title
                VStack(spacing: 8) {
                    Text("\"Envive\" Would Like to Access Screen Time")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.top, 16)

                    Text("Providing \"Envive\" access to Screen Time...")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }

                Divider()

                // Buttons with green arrow
                HStack(spacing: 0) {
                    ZStack {
                        Text("Continue")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, minHeight: 40)

                        // Green arrow pointing to Continue
                        Image(systemName: "arrow.down")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                            .offset(y: 50)
                    }

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 0.5, height: 40)

                    Text("Don't Allow")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.blue.opacity(0.5))
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 10)

            // Arrow instruction
            HStack(spacing: 6) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                Text("Tap Continue on the left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.top, 50)
        }
        .padding(.top, 12)
    }

    // MARK: - Request Permission Button

    private var instructionalAlertMock: some View {
        VStack(spacing: 16) {
            Button(action: {
                requestPermission()
            }) {
                HStack(spacing: 12) {
                    if isRequestingPermission {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                        Text("Requesting Permission...")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else if permissionGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("Permission Granted!")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                        Text("Request Permission")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    permissionGranted ? Color.green :
                    isRequestingPermission ? Color.blue.opacity(0.7) :
                    Color.blue
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
            .disabled(isRequestingPermission || permissionGranted)
        }
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
