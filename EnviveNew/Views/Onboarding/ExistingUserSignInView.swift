import SwiftUI
import AuthenticationServices

// MARK: - Existing User Sign In View

/// Sign-in screen for users who already have an account
struct ExistingUserSignInView: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @ObservedObject private var deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager

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
                VStack(spacing: 24) {
                    Text("👋")
                        .font(.system(size: 80))
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .opacity(showContent ? 1.0 : 0)

                    VStack(spacing: 14) {
                        Text("Welcome Back")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                            .opacity(showContent ? 1.0 : 0)

                        Text("Sign in to continue")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(2)
                            .opacity(showContent ? 1.0 : 0)
                    }
                }
                .padding(.bottom, 50)

                // Sign in options
                VStack(spacing: 24) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("Email")
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.leading, 18)
                            }
                            TextField("", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 18)
                                .font(.system(size: 16, weight: .regular))
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )
                    }
                    .opacity(showContent ? 1.0 : 0)

                    // Password field with forgot password
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .leading) {
                            if password.isEmpty {
                                Text("Password")
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.leading, 18)
                            }
                            SecureField("", text: $password)
                                .textContentType(.password)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 18)
                                .font(.system(size: 16, weight: .regular))
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )

                        // Forgot Password button
                        Button(action: {
                            showingForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.leading, 6)
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
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .tracking(0.3)
                            }
                        }
                        .foregroundColor(.blue.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
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
                // DO NOT clear onboarding data here - user is mid-onboarding flow
                // We need to preserve the welcome/role/legal flags they already completed

                let profile = try await authService.signIn(email: email, password: password)

                await MainActor.run {
                    isLoading = false

                    // Link device to profile so user can see their data
                    linkDeviceToProfile(profile)

                    print("✅ User signed in successfully: \(profile.fullName ?? "Unknown")")

                    // Existing users should skip onboarding and go straight to the app
                    if profile.householdId != nil {
                        print("✅ Existing user with household - completing onboarding")
                        OnboardingManager.shared.completeSignIn()
                        OnboardingManager.shared.completeFamilySetup()
                        OnboardingManager.shared.completeOnboarding()
                    } else {
                        // No household yet - continue through onboarding
                        onComplete()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false

                    // Check if this is a profileNotFound error
                    if let authError = error as? AuthError, authError == .profileNotFound {
                        errorMessage = "No account found. Please create an account first."
                    } else {
                        errorMessage = "Invalid email or password"
                    }

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
                    // DO NOT clear onboarding data here - user is mid-onboarding flow
                    // We need to preserve the welcome/role/legal flags they already completed

                    let profile = try await authService.signInWithApple(authorization: authorization)

                    await MainActor.run {
                        // Link device to profile so user can see their data
                        linkDeviceToProfile(profile)

                        print("✅ Apple sign in successful: \(profile.fullName ?? "Unknown")")

                        // Existing users should skip onboarding and go straight to the app
                        if profile.householdId != nil {
                            print("✅ Existing user with household - completing onboarding")
                            OnboardingManager.shared.completeSignIn()
                            OnboardingManager.shared.completeFamilySetup()
                            OnboardingManager.shared.completeOnboarding()
                        } else {
                            // No household yet - continue through onboarding
                            onComplete()
                        }
                    }
                } catch {
                    await MainActor.run {
                        // Check if this is a profileNotFound error
                        if let authError = error as? AuthError, authError == .profileNotFound {
                            errorMessage = "No account found. Please create an account first."
                        } else {
                            errorMessage = "Apple sign in failed"
                        }

                        print("❌ Apple sign in error: \(error.localizedDescription)")
                    }
                }
            }

        case .failure(let error):
            errorMessage = "Apple sign in cancelled"
            print("❌ Apple sign in error: \(error.localizedDescription)")
        }
    }

    // MARK: - Profile Linking

    private func linkDeviceToProfile(_ profile: Profile) {
        // Convert Profile to UserProfile
        // Convert String ID to UUID (profile.id is from Supabase auth)
        let profileId = UUID(uuidString: profile.id) ?? UUID()

        let userProfile = UserProfile(
            id: profileId,
            name: profile.fullName ?? profile.email ?? "User",
            mode: profile.role == "parent" ? .parent : .child1,
            age: profile.age,
            profilePhotoFileName: nil // avatarUrl from backend is not yet synced to local file
        )

        // Set device mode
        let deviceMode: DeviceMode = profile.role == "parent" ? .parent : .child1
        deviceModeManager.switchMode(to: deviceMode, profile: userProfile)
        DeviceModeService.shared.setDeviceMode(deviceMode)

        print("✅ Device linked to profile: \(userProfile.name) (\(profile.role ?? "unknown"))")
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
