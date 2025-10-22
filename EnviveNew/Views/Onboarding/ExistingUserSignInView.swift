import SwiftUI
import AuthenticationServices

// MARK: - Existing User Sign In View

/// Sign-in screen for users who already have an account
struct ExistingUserSignInView: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showContent = false
    @State private var showingForgotPassword = false

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

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    Spacer()
                }

                Spacer()

                // Header
                VStack(spacing: 20) {
                    Text("👋")
                        .font(.system(size: 70))
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .opacity(showContent ? 1.0 : 0)

                    VStack(spacing: 12) {
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1.0 : 0)

                        Text("Sign in to continue")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(showContent ? 1.0 : 0)
                    }
                }
                .padding(.bottom, 40)

                // Sign in options
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("Email")
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.leading, 16)
                            }
                            TextField("", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                        }
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .opacity(showContent ? 1.0 : 0)

                    // Password field with forgot password
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .leading) {
                            if password.isEmpty {
                                Text("Password")
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.leading, 16)
                            }
                            SecureField("", text: $password)
                                .textContentType(.password)
                                .padding()
                        }
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                        // Forgot Password button
                        Button(action: {
                            showingForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.leading, 4)
                    }
                    .opacity(showContent ? 1.0 : 0)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                    }

                    // Sign In button
                    Button(action: handleEmailSignIn) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(.blue.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1.0)
                    .scaleEffect(showContent ? 1.0 : 0.9)
                    .opacity(showContent ? 1.0 : 0)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        Text("OR")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 10)
                    .opacity(showContent ? 1.0 : 0)

                    // Apple Sign In button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: handleAppleSignIn
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 55)
                    .cornerRadius(14)
                    .opacity(showContent ? 1.0 : 0)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Actions

    private func handleEmailSignIn() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                // Clear any previous user's data (this is an existing user signing in)
                await MainActor.run {
                    authService.resetAllUserData()
                }

                let profile = try await authService.signIn(email: email, password: password)

                await MainActor.run {
                    isLoading = false

                    // Set device mode based on user role
                    if profile.role == "parent" {
                        let parentMode = DeviceModeService.deviceModeFromUserRole(.parent)
                        DeviceModeService.shared.setDeviceMode(parentMode)
                        print("✅ Parent signed in - device mode set to PARENT")
                    } else {
                        let childMode = DeviceModeService.deviceModeFromUserRole(.child)
                        DeviceModeService.shared.setDeviceMode(childMode)
                        print("✅ Child signed in - device mode set to CHILD")
                    }

                    print("✅ User signed in successfully: \(profile.fullName ?? "Unknown")")
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid email or password"
                    print("❌ Sign in failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                do {
                    // Clear any previous user's data (this is an existing user signing in)
                    await MainActor.run {
                        authService.resetAllUserData()
                    }

                    let profile = try await authService.signInWithApple(authorization: authorization)

                    await MainActor.run {
                        // Set device mode based on user role
                        if profile.role == "parent" {
                            let parentMode = DeviceModeService.deviceModeFromUserRole(.parent)
                            DeviceModeService.shared.setDeviceMode(parentMode)
                            print("✅ Parent signed in via Apple - device mode set to PARENT")
                        } else {
                            let childMode = DeviceModeService.deviceModeFromUserRole(.child)
                            DeviceModeService.shared.setDeviceMode(childMode)
                            print("✅ Child signed in via Apple - device mode set to CHILD")
                        }

                        print("✅ Apple sign in successful: \(profile.fullName ?? "Unknown")")
                        onComplete()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Apple sign in failed"
                        print("❌ Apple sign in error: \(error.localizedDescription)")
                    }
                }
            }

        case .failure(let error):
            errorMessage = "Apple sign in cancelled"
            print("❌ Apple sign in error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

struct ExistingUserSignInView_Previews: PreviewProvider {
    static var previews: some View {
        ExistingUserSignInView(
            onComplete: {},
            onBack: {}
        )
    }
}
