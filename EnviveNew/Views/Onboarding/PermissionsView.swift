import SwiftUI
import FamilyControls

// MARK: - Permissions View

/// Guides users through granting Screen Time access to Envive
struct PermissionsView: View {
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var isRequestingPermission = false
    @State private var permissionGranted = false
    @State private var showPermissionDialog = false

    private let authorizationCenter = AuthorizationCenter.shared

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.green.opacity(0.6),
                    Color.blue.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Content
                VStack(spacing: 40) {
                    // Header
                    headerSection

                    // Permission guide
                    permissionGuideSection

                    // Security note
                    securityNote
                }

                Spacer()

                // Continue button
                continueButton
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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
                Text("Connect to Screen Time")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("To manage screen time on this iPhone, Envive needs your permission")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Permission Guide Section

    private var permissionGuideSection: some View {
        VStack(spacing: 20) {
            // Visual guide box
            VStack(spacing: 16) {
                Text("When you tap Continue, you'll see:")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                // Mock permission dialog
                VStack(spacing: 0) {
                    // Dialog header
                    VStack(spacing: 12) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)

                        Text("\"Envive\" Would Like to Access Screen Time")
                            .font(.system(size: 15, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 24)

                    Divider()

                    // Buttons
                    HStack(spacing: 0) {
                        Text("Don't Allow")
                            .font(.system(size: 17))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)

                        Divider()
                            .frame(height: 44)

                        ZStack {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)

                            // Arrow pointing to Continue
                            Image(systemName: "arrow.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.yellow)
                                .offset(x: 80, y: 0)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.2), radius: 20)

                // Instruction
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)

                    Text("Tap \"Continue\" when the dialog appears")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.15))
            .cornerRadius(20)
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Security Note

    private var securityNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text("Your screen time data is private and secure")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            requestPermission()
        }) {
            HStack(spacing: 10) {
                if isRequestingPermission {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue.opacity(0.9)))
                    Text("Requesting Permission...")
                        .font(.system(size: 18, weight: .bold))
                } else if permissionGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text("Permission Granted!")
                        .font(.system(size: 18, weight: .bold))
                } else {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
            }
            .foregroundColor(Color.blue.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .disabled(isRequestingPermission || permissionGranted)
        .scaleEffect(showContent ? 1.0 : 0.9)
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

                    // Wait a moment to show success state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onComplete()
                    }
                }

                print("✅ Screen Time authorization granted")
            } catch {
                // Permission denied or error
                await MainActor.run {
                    isRequestingPermission = false
                    permissionGranted = false
                }

                print("❌ Screen Time authorization failed: \(error)")

                // Still complete onboarding even if permission denied
                // User can grant it later from Settings
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Preview

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView(onComplete: {})
    }
}
