//
//  SimplifiedParentSignUpView.swift
//  EnviveNew
//
//  Simplified parent account creation
//

import SwiftUI
import AuthenticationServices

struct SimplifiedParentSignUpView: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var householdService = HouseholdService.shared
    @ObservedObject private var deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
    @ObservedObject private var deviceModeService = DeviceModeService.shared

    @State private var familyName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingSignIn = false

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

            ScrollView {
                VStack(spacing: 28) {
                    Spacer()
                        .frame(height: 40)

                    // Header
                    headerSection

                    // Sign in with Apple
                    appleSignInSection

                    // Or divider
                    dividerSection

                    // Email/Password Form
                    formSection

                    // Create Account Button
                    createAccountButton

                    // Back button
                    backButton

                    // Sign In link for existing users
                    signInLink

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            ExistingUserSignInView(
                onComplete: {
                    showingSignIn = false
                    onComplete()
                },
                onBack: {
                    showingSignIn = false
                }
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: 10) {
                Text("Create Your Family Account")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.3)
                    .multilineTextAlignment(.center)

                Text("You'll add your kids in the next step")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Apple Sign In

    private var appleSignInSection: some View {
        SignInWithAppleButton(
            .signUp,  // Use signUp label instead of signIn
            onRequest: { request in
                request.requestedScopes = [.email, .fullName]
            },
            onCompletion: { result in
                handleAppleSignIn(result)
            }
        )
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .cornerRadius(10)
    }

    // MARK: - Divider

    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)

            Text("or")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)

            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 20) {
            // Family Name
            VStack(alignment: .leading, spacing: 10) {
                Text("Family Name")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(0.2)

                TextField("The Smith Family", text: $familyName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.words)
            }

            // Email
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Email")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(0.2)

                TextField("parent@example.com", text: $email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
            }

            // Password
            VStack(alignment: .leading, spacing: 10) {
                Text("Password")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(0.2)

                SecureField("At least 6 characters", text: $password)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(.newPassword)
            }
        }
    }

    // MARK: - Create Account Button

    private var createAccountButton: some View {
        Button(action: handleCreateAccount) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else {
                    Text("Create Account")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .tracking(0.3)
                }
            }
            .foregroundColor(isFormValid ? Color.blue.opacity(0.9) : .gray.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(isFormValid ? 0.2 : 0.08), radius: 12, x: 0, y: 6)
        }
        .disabled(!isFormValid || isLoading)
        .opacity(isFormValid ? 1.0 : 0.6)
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button(action: onBack) {
            HStack {
                Image(systemName: "arrow.left")
                Text("Back")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white.opacity(0.9))
        }
    }

    // MARK: - Sign In Link

    private var signInLink: some View {
        Button(action: {
            showingSignIn = true
        }) {
            HStack(spacing: 6) {
                Text("Already have an account?")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))

                Text("Sign In")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .underline()
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !familyName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6
    }

    // MARK: - Actions

    private func handleCreateAccount() {
        isLoading = true

        Task {
            do {
                // Create account with Supabase
                let profile = try await authService.signUp(
                    email: email,
                    password: password,
                    fullName: familyName,
                    role: .parent
                )

                // Save family name
                UserDefaults.standard.set(familyName, forKey: "familyName")
                UserDefaults.standard.set(email, forKey: "parentEmail")

                // Check if this is an existing user with household already set up
                let isExistingUser = profile.householdId != nil

                // If new user, create a household for them
                if !isExistingUser {
                    print("🏠 Creating household for new user...")

                    // Wait a moment to ensure profile is fully committed to database
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                    // Verify profile exists in database before creating household
                    do {
                        _ = try await authService.refreshCurrentProfile()
                        print("✅ Profile verified in database")
                    } catch {
                        print("⚠️ Profile not yet in database, waiting...")
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 more second
                        _ = try await authService.refreshCurrentProfile()
                    }

                    let household = try await householdService.createHousehold(
                        name: familyName.isEmpty ? "\(email)'s Family" : familyName,
                        createdBy: profile.id
                    )
                    print("✅ Household created: \(household.name) (ID: \(household.id))")

                    // Refresh profile to get updated household_id
                    try await authService.refreshCurrentProfile()
                }

                // Link device to profile so user can see their data
                linkDeviceToProfile(authService.currentProfile ?? profile)

                await MainActor.run {
                    isLoading = false

                    // If existing user with household, skip family setup and complete onboarding
                    if isExistingUser {
                        print("✅ Existing user detected - skipping family setup")
                        OnboardingManager.shared.completeSignIn()
                        OnboardingManager.shared.completeFamilySetup()
                        OnboardingManager.shared.completeOnboarding()
                    } else {
                        // New user - continue with normal flow (will go to family setup)
                        onComplete()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoading = true

            Task {
                do {
                    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential"])
                    }

                    guard let idToken = appleIDCredential.identityToken,
                          let idTokenString = String(data: idToken, encoding: .utf8) else {
                        throw NSError(domain: "AppleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get token"])
                    }

                    // Sign in with Apple through Supabase
                    let profile = try await authService.signInWithApple(authorization: authorization)

                    // Extract name if available
                    var householdName = "\(profile.email ?? "User")'s Family"
                    if let fullName = appleIDCredential.fullName {
                        let name = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")

                        if !name.isEmpty {
                            householdName = "\(name) Family"
                            UserDefaults.standard.set(householdName, forKey: "familyName")
                        }
                    }

                    // Check if this is an existing user with household already set up
                    let isExistingUser = profile.householdId != nil

                    // If new user, create a household for them
                    if !isExistingUser {
                        print("🏠 Creating household for new Apple sign-in user...")

                        // Wait a moment to ensure profile is fully committed to database
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                        // Verify profile exists in database before creating household
                        do {
                            _ = try await authService.refreshCurrentProfile()
                            print("✅ Profile verified in database")
                        } catch {
                            print("⚠️ Profile not yet in database, waiting...")
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 more second
                            _ = try await authService.refreshCurrentProfile()
                        }

                        let household = try await householdService.createHousehold(
                            name: householdName,
                            createdBy: profile.id
                        )
                        print("✅ Household created: \(household.name) (ID: \(household.id))")

                        // Refresh profile to get updated household_id
                        try await authService.refreshCurrentProfile()
                    }

                    // Link device to profile so user can see their data
                    linkDeviceToProfile(authService.currentProfile ?? profile)

                    await MainActor.run {
                        isLoading = false

                        // If existing user with household, skip family setup and complete onboarding
                        if isExistingUser {
                            print("✅ Existing user detected - skipping family setup")
                            OnboardingManager.shared.completeSignIn()
                            OnboardingManager.shared.completeFamilySetup()
                            OnboardingManager.shared.completeOnboarding()
                        } else {
                            // New user - continue with normal flow (will go to family setup)
                            onComplete()
                        }
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }

        case .failure(let error):
            errorMessage = "Sign in cancelled: \(error.localizedDescription)"
            showingError = true
        }
    }

    // MARK: - Profile Linking

    private func linkDeviceToProfile(_ profile: Profile) {
        // Convert Profile to UserProfile and set device mode
        // Convert String ID to UUID (profile.id is from Supabase auth)
        let profileId = UUID(uuidString: profile.id) ?? UUID()

        let userProfile = UserProfile(
            id: profileId,
            name: profile.fullName ?? profile.email ?? "Parent",
            mode: .parent,
            age: profile.age,
            profilePhotoFileName: nil // avatarUrl from backend is not yet synced to local file
        )

        // Set device mode to parent
        deviceModeManager.switchMode(to: .parent, profile: userProfile)
        deviceModeService.setDeviceMode(.parent)

        print("✅ Parent signed in - device linked to profile: \(userProfile.name)")
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .font(.system(size: 16, weight: .regular))
    }
}
