//
//  SimplifiedChildJoinView.swift
//  EnviveNew
//
//  Simple child join flow with invite code and permissions
//

import SwiftUI
import FamilyControls

struct SimplifiedChildJoinView: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var inviteCode = ""
    @State private var selectedProfile: Profile?
    @State private var step: ChildJoinStep = .enterCode
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var permissionGranted = false

    enum ChildJoinStep {
        case enterCode
        case selectProfile
        case permissions
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                switch step {
                case .enterCode:
                    enterCodeView
                case .selectProfile:
                    selectProfileView
                case .permissions:
                    permissionsView
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Enter Code View

    private var enterCodeView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("Join Your Family")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text("Enter the code your parent gave you")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            // Code input
            VStack(spacing: 16) {
                TextField("", text: $inviteCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textCase(.uppercase)
                    .autocapitalization(.allCharacters)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .onChange(of: inviteCode) { newValue in
                        // Format as we type
                        inviteCode = newValue.uppercased()
                    }

                Text("Example: ABC123")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 40)

            Spacer()

            // Buttons
            VStack(spacing: 14) {
                Button(action: handleCodeSubmit) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(inviteCode.count >= 6 ? Color.blue.opacity(0.9) : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(14)
                }
                .disabled(inviteCode.count < 6 || isLoading)

                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Select Profile View

    private var selectProfileView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text("Which one are you?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text("Select your profile")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            // Profile selection (placeholder - will be populated from household)
            VStack(spacing: 12) {
                profileButton(name: "Loading...", age: 0)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: {
                step = .enterCode
            }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("Back")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            }
            .padding(.bottom, 50)
        }
    }

    private func profileButton(name: String, age: Int) -> some View {
        Button(action: {
            // Handle profile selection
            step = .permissions
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Age \(age)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // MARK: - Permissions View

    private var permissionsView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "hourglass")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("One Last Thing")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text("Envive needs permission to manage screen time on this device")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Permission explanation
            VStack(spacing: 12) {
                permissionPoint(
                    icon: "checkmark.shield.fill",
                    text: "Your parents can set screen time limits"
                )

                permissionPoint(
                    icon: "gamecontroller.fill",
                    text: "Earn extra time by completing tasks"
                )

                permissionPoint(
                    icon: "lock.fill",
                    text: "All data stays secure on your device"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Grant permission button
            VStack(spacing: 14) {
                Button(action: handlePermissionRequest) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else if permissionGranted {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Permission Granted")
                        } else {
                            Text("Grant Permission")
                        }
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.blue.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(14)
                }
                .disabled(isLoading || permissionGranted)

                if permissionGranted {
                    Button(action: onComplete) {
                        Text("Continue to App")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }

    private func permissionPoint(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 40)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
    }

    // MARK: - Actions

    private func handleCodeSubmit() {
        isLoading = true

        // TODO: Verify code and fetch household
        // For now, just move to next step
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            step = .permissions  // Skip profile selection for now
        }
    }

    private func handlePermissionRequest() {
        isLoading = true

        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)

                await MainActor.run {
                    isLoading = false
                    permissionGranted = true
                    print("✅ Screen Time permission granted")

                    // Auto-continue after brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onComplete()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    permissionGranted = false
                    errorMessage = "Permission denied. You can grant it later from Settings."
                    showError = true

                    // Still allow continuing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        onComplete()
                    }
                }
            }
        }
    }
}
