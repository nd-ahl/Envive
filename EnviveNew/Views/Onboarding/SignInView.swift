import SwiftUI
import AuthenticationServices

// MARK: - Sign In View

/// Allows users to sign in with Apple or email to create/join a household
struct SignInView: View {
    let isCreatingHousehold: Bool
    let onComplete: () -> Void
    let onBack: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var householdService = HouseholdService.shared
    @State private var showContent = false
    @State private var showEmailSignIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var householdName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Gradient background (consistent theme)
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.7)
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

                // Content
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    if !showEmailSignIn {
                        // Sign in options
                        signInOptionsSection
                    } else {
                        // Email sign in form
                        emailSignInSection
                    }

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
                }
                .padding(.horizontal, 32)

                Spacer()

                // Footer
                footerSection
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
            Text(isCreatingHousehold ? "🔑" : "🏠")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text(isCreatingHousehold ? "Create Your Account" : "Sign In to Join")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text(isCreatingHousehold ? "Set up your account to create a household" : "Sign in to join your family's household")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Sign In Options Section

    private var signInOptionsSection: some View {
        VStack(spacing: 16) {
            // Sign in with Apple
            SignInWithAppleButton(.signUp) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(12)

            // Or divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)

                Text("or")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)

            // Sign in with Email
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showEmailSignIn = true
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                    Text("Continue with Email")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(Color.blue.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .opacity(showContent ? 1.0 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Email Sign In Section

    private var emailSignInSection: some View {
        VStack(spacing: 16) {
            // Full Name field (only for sign up)
            if isCreatingHousehold {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    TextField("", text: $fullName)
                        .placeholder(when: fullName.isEmpty) {
                            Text("John Doe")
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Household Name")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    TextField("", text: $householdName)
                        .placeholder(when: householdName.isEmpty) {
                            Text("The Smith Family")
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .autocapitalization(.words)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .foregroundColor(.black)
                }
            }

            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                TextField("", text: $email)
                    .placeholder(when: email.isEmpty) {
                        Text("your@email.com")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .foregroundColor(.black)
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                SecureField("", text: $password)
                    .placeholder(when: password.isEmpty) {
                        Text(isCreatingHousehold ? "At least 6 characters" : "Enter your password")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .textContentType(.password)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .foregroundColor(.black)
            }

            // Sign in button
            Button(action: handleEmailSignIn) {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.blue.opacity(0.9)))
                    } else {
                        Text(isCreatingHousehold ? "Create Account" : "Sign In")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(canSignIn ? Color.blue.opacity(0.9) : Color.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .opacity(canSignIn ? 1.0 : 0.5)
            }
            .disabled(!canSignIn || isLoading)
            .padding(.top, 8)

            // Back to options
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showEmailSignIn = false
                    errorMessage = nil
                }
            }) {
                Text("Use a different sign-in method")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .underline()
            }
            .padding(.top, 8)
        }
        .opacity(showContent ? 1.0 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("By continuing, you agree to Envive's")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 4) {
                Button(action: {
                    // TODO: Show terms of service
                }) {
                    Text("Terms of Service")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .underline()
                }

                Text("and")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Button(action: {
                    // TODO: Show privacy policy
                }) {
                    Text("Privacy Policy")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .underline()
                }
            }
        }
        .multilineTextAlignment(.center)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Computed Properties

    private var canSignIn: Bool {
        let emailValid = !email.isEmpty && isValidEmail(email)
        let passwordValid = !password.isEmpty && password.count >= 6

        if isCreatingHousehold {
            return emailValid && passwordValid && !fullName.isEmpty && !householdName.isEmpty
        } else {
            return emailValid && passwordValid
        }
    }

    // MARK: - Actions

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil

        Task {
            switch result {
            case .success(let authorization):
                do {
                    // Sign in with Supabase using Apple credentials
                    let profile = try await authService.signInWithApple(authorization: authorization)

                    print("✅ Apple Sign In successful")
                    print("User ID: \(profile.id)")
                    print("Email: \(profile.email ?? "not provided")")

                    if isCreatingHousehold {
                        // Create household for the new user
                        let defaultHouseholdName = (profile.fullName ?? "My") + " Household"
                        let household = try await householdService.createHousehold(
                            name: defaultHouseholdName,
                            createdBy: profile.id
                        )

                        print("✅ Household created: \(household.name)")
                        print("Invite code: \(household.inviteCode)")

                        // Reload profile to get updated household_id
                        try await authService.refreshCurrentProfile()

                        // Save household info
                        UserDefaults.standard.set(household.id, forKey: "householdId")
                        UserDefaults.standard.set(household.inviteCode, forKey: "householdCode")
                        UserDefaults.standard.set(true, forKey: "isInHousehold")
                    } else {
                        // Try to load their existing household
                        if let household = try? await householdService.getUserHousehold(userId: profile.id) {
                            UserDefaults.standard.set(household.id, forKey: "householdId")
                            UserDefaults.standard.set(household.inviteCode, forKey: "householdCode")
                            UserDefaults.standard.set(true, forKey: "isInHousehold")
                        }
                    }

                    // Save to UserDefaults for backward compatibility
                    UserDefaults.standard.set(profile.id, forKey: "userId")
                    if let email = profile.email {
                        UserDefaults.standard.set(email, forKey: "userEmail")
                    }
                    if let name = profile.fullName {
                        UserDefaults.standard.set(name, forKey: "userName")
                    }

                    // Set device mode to parent (they're creating a household)
                    if isCreatingHousehold {
                        let parentMode = DeviceModeService.deviceModeFromUserRole(.parent)
                        DeviceModeService.shared.setDeviceMode(parentMode)
                        print("✅ Device mode set to PARENT")
                    }

                    await MainActor.run {
                        isLoading = false
                        onComplete()
                    }
                } catch {
                    print("❌ Apple Sign In failed: \(error.localizedDescription)")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = error.localizedDescription
                    }
                }

            case .failure(let error):
                print("❌ Apple Sign In failed: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Sign in failed. Please try again."
                }
            }
        }
    }

    private func handleEmailSignIn() {
        guard canSignIn else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let profile: Profile

                if isCreatingHousehold {
                    // Get user role from UserDefaults
                    let roleString = UserDefaults.standard.string(forKey: "userRole") ?? "parent"
                    let userRole: UserRole = roleString == "child" ? .child : .parent

                    // Sign up new user
                    profile = try await authService.signUp(
                        email: email,
                        password: password,
                        fullName: fullName,
                        role: userRole
                    )

                    print("✅ Sign up successful")

                    // Create household for the new user
                    let household = try await householdService.createHousehold(
                        name: householdName,
                        createdBy: profile.id
                    )

                    print("✅ Household created: \(household.name)")
                    print("Invite code: \(household.inviteCode)")

                    // Reload profile to get updated household_id
                    try await authService.refreshCurrentProfile()

                    // Save household info
                    UserDefaults.standard.set(household.id, forKey: "householdId")
                    UserDefaults.standard.set(household.inviteCode, forKey: "householdCode")
                    UserDefaults.standard.set(true, forKey: "isInHousehold")
                } else {
                    // Sign in existing user
                    profile = try await authService.signIn(
                        email: email,
                        password: password
                    )

                    print("✅ Sign in successful")

                    // Try to load their existing household
                    if let household = try? await householdService.getUserHousehold(userId: profile.id) {
                        UserDefaults.standard.set(household.id, forKey: "householdId")
                        UserDefaults.standard.set(household.inviteCode, forKey: "householdCode")
                        UserDefaults.standard.set(true, forKey: "isInHousehold")
                    }
                }

                print("User ID: \(profile.id)")
                print("Email: \(profile.email ?? "N/A")")

                // Save to UserDefaults for backward compatibility
                UserDefaults.standard.set(profile.id, forKey: "userId")
                if let email = profile.email {
                    UserDefaults.standard.set(email, forKey: "userEmail")
                }
                if let name = profile.fullName {
                    UserDefaults.standard.set(name, forKey: "userName")
                }

                // Set device mode to parent (they're creating a household)
                if isCreatingHousehold {
                    let parentMode = DeviceModeService.deviceModeFromUserRole(.parent)
                    DeviceModeService.shared.setDeviceMode(parentMode)
                    print("✅ Device mode set to PARENT")
                }

                await MainActor.run {
                    isLoading = false
                    onComplete()
                }
            } catch {
                print("❌ Email authentication failed: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Preview

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignInView(
                isCreatingHousehold: true,
                onComplete: {},
                onBack: {}
            )
            .previewDisplayName("Create Account")

            SignInView(
                isCreatingHousehold: false,
                onComplete: {},
                onBack: {}
            )
            .previewDisplayName("Join Household")
        }
    }
}
