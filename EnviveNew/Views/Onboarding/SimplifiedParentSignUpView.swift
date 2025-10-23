//
//  SimplifiedParentSignUpView.swift
//  EnviveNew
//
//  Simplified parent account creation
//

import SwiftUI
import AuthenticationServices
import Supabase
import Auth

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

    // Name prompt state
    @State private var showingNamePrompt = false
    @State private var parentName = ""
    @State private var tempProfileAfterAppleSignup: Profile? = nil

    // Email verification state
    @State private var showingEmailVerification = false
    @State private var signUpEmail = ""

    // Password setup state
    @State private var showingPasswordSetup = false
    @State private var passwordSetupEmail = ""

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
        .sheet(isPresented: $showingNamePrompt) {
            namePromptView
        }
        .fullScreenCover(isPresented: $showingEmailVerification) {
            EmailVerificationView(email: signUpEmail) {
                showingEmailVerification = false
                // Navigate to sign-in
                showingSignIn = true
            }
        }
        .fullScreenCover(isPresented: $showingPasswordSetup) {
            PasswordSetupView(userEmail: passwordSetupEmail) {
                showingPasswordSetup = false
                // Continue with onboarding
                onComplete()
            }
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

    // MARK: - Helper Functions

    /// Generate a grammatically correct family name with possessive form
    private func makeGrammaticalFamilyName(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Family"
        }

        // Check if name already ends with "Family" or similar
        let lowercased = trimmed.lowercased()
        if lowercased.hasSuffix("family") || lowercased.hasSuffix("household") {
            return trimmed
        }

        // Add possessive apostrophe
        if trimmed.hasSuffix("s") {
            return "\(trimmed)' Family"
        } else {
            return "\(trimmed)'s Family"
        }
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
                        name: makeGrammaticalFamilyName(from: familyName),
                        createdBy: profile.id
                    )
                    print("✅ Household created: \(household.name) (ID: \(household.id))")

                    // CRITICAL FIX: Wait a moment for database to update
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                    // Refresh profile to get updated household_id
                    try await authService.refreshCurrentProfile()

                    // Verify household_id was updated
                    if authService.currentProfile?.householdId == nil {
                        print("⚠️ WARNING: Profile household_id is still nil after refresh, retrying...")
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        try await authService.refreshCurrentProfile()
                    }

                    print("✅ Profile household_id: \(authService.currentProfile?.householdId ?? "nil")")
                }

                // Link device to profile so user can see their data
                linkDeviceToProfile(authService.currentProfile ?? profile)

                await MainActor.run {
                    isLoading = false

                    // CRITICAL FIX: Show email verification screen for new users
                    // User must confirm their email before they can sign in again
                    signUpEmail = email

                    // CRITICAL FIX: Sign out WITHOUT clearing onboarding data
                    // This prevents the app from jumping back to the welcome screen
                    Task {
                        try? await authService.signOutWithoutClearingOnboarding()
                    }

                    // Show email verification instructions
                    showingEmailVerification = true

                    print("📧 Account created - user must verify email: \(email)")
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
                    // Try to sign in with existing account
                    let profile = try await authService.signInWithApple(authorization: authorization)

                    // Check if this is an existing user with household already set up
                    let isExistingUser = profile.householdId != nil

                    await MainActor.run {
                        isLoading = false

                        // If existing user with household, skip family setup and complete onboarding
                        if isExistingUser {
                            print("✅ Existing user detected - skipping family setup")

                            // Link device to profile
                            linkDeviceToProfile(authService.currentProfile ?? profile)

                            OnboardingManager.shared.completeSignIn()
                            OnboardingManager.shared.completeFamilySetup()
                            OnboardingManager.shared.completeOnboarding()
                        } else {
                            // New user - show name prompt instead of using email
                            print("🆕 New Apple user - showing name prompt")
                            tempProfileAfterAppleSignup = profile
                            showingNamePrompt = true
                        }
                    }
                } catch {
                    // CRITICAL FIX: If profile not found, create account seamlessly
                    if let authError = error as? AuthError, authError == .profileNotFound {
                        print("🆕 No account found - creating new account with Apple ID")
                        await createAccountWithApple(authorization)
                    } else {
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                            showingError = true
                        }
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
        // CRITICAL FIX: Clear any stale household data from previous login
        // This prevents data leakage between households
        householdService.currentHousehold = nil
        householdService.householdMembers = []
        print("🧹 Cleared stale household data")

        // Convert Profile to UserProfile and set device mode
        // Convert String ID to UUID (profile.id is from Supabase auth)
        let profileId = UUID(uuidString: profile.id) ?? UUID()
        let parentName = profile.fullName ?? profile.email ?? "Parent"

        let userProfile = UserProfile(
            id: profileId,
            name: parentName,
            mode: .parent,
            age: profile.age,
            profilePhotoFileName: nil // avatarUrl from backend is not yet synced to local file
        )

        // Set device mode to parent
        deviceModeManager.switchMode(to: .parent, profile: userProfile)
        _ = deviceModeService.setDeviceMode(.parent)

        // CRITICAL FIX: Save parent's name to UserDefaults so it displays in UI
        UserDefaults.standard.set(parentName, forKey: "userName")
        UserDefaults.standard.set(profile.id, forKey: "userId")
        UserDefaults.standard.set("parent", forKey: "userRole")

        // CRITICAL FIX: Save parent name for mode switcher
        // This ensures children can switch back to parent mode with correct name
        UserDefaults.standard.set(parentName, forKey: "savedParentName")

        if let age = profile.age {
            UserDefaults.standard.set(age, forKey: "userAge")
        }
        print("✅ Parent signed in - device linked to profile: \(parentName)")
    }

    // MARK: - Name Prompt View

    private var namePromptView: some View {
        NavigationStack {
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

                VStack(spacing: 28) {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("What's your name?")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)

                        Text("This will be displayed in your profile and settings")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    // Name input
                    VStack(spacing: 16) {
                        TextField("Your Name", text: $parentName)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.words)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Continue Button
                    VStack(spacing: 14) {
                        Button(action: handleNameSubmit) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(parentName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .cornerRadius(14)
                        }
                        .disabled(parentName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func handleNameSubmit() {
        guard let profile = tempProfileAfterAppleSignup else {
            errorMessage = "Session error. Please try again."
            showingError = true
            showingNamePrompt = false
            return
        }

        isLoading = true

        Task {
            do {
                let trimmedName = parentName.trimmingCharacters(in: .whitespaces)

                // Update profile full_name in Supabase
                let supabase = SupabaseService.shared.client
                try await supabase
                    .from("profiles")
                    .update(["full_name": trimmedName])
                    .eq("id", value: profile.id)
                    .execute()

                // Refresh the current profile to get the updated name
                try await authService.refreshCurrentProfile()

                // Save name to UserDefaults for settings display
                UserDefaults.standard.set(trimmedName, forKey: "parentName")

                // Create household with the entered name
                let household = try await householdService.createHousehold(
                    name: makeGrammaticalFamilyName(from: trimmedName),
                    createdBy: profile.id
                )
                print("✅ Household created: \(household.name) (ID: \(household.id))")

                // CRITICAL FIX: Wait a moment for database to update
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                // Refresh profile to get updated household_id
                try await authService.refreshCurrentProfile()

                // Verify household_id was updated
                if authService.currentProfile?.householdId == nil {
                    print("⚠️ WARNING: Profile household_id is still nil after refresh, retrying...")
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    try await authService.refreshCurrentProfile()
                }

                print("✅ Profile household_id: \(authService.currentProfile?.householdId ?? "nil")")

                // Link device to profile so user can see their data
                linkDeviceToProfile(authService.currentProfile ?? profile)

                await MainActor.run {
                    isLoading = false
                    showingNamePrompt = false
                    tempProfileAfterAppleSignup = nil

                    // Continue with normal flow (will go to family setup)
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save name: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    /// Create a new account using Apple ID when no profile exists
    private func createAccountWithApple(_ authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to get Apple credentials"
                showingError = true
            }
            return
        }

        guard let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to process Apple sign in"
                showingError = true
            }
            return
        }

        do {
            // Sign in with Apple to create auth user
            let supabase = SupabaseService.shared.client
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )

            await MainActor.run {
                authService.isAuthenticated = true
            }

            let userId = session.user.id.uuidString

            // Extract name from Apple ID credential (only available on first sign-in)
            var fullName = "User"
            if let givenName = appleIDCredential.fullName?.givenName,
               let familyName = appleIDCredential.fullName?.familyName {
                fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
            } else if let givenName = appleIDCredential.fullName?.givenName {
                fullName = givenName
            }

            // Get email or use Apple's private relay email
            let email = appleIDCredential.email ?? session.user.email ?? "apple-user@icloud.com"

            // Parent role (this is the parent sign-up view)
            let roleString = "parent"

            // Create profile in database
            let newProfile = Profile(
                id: userId,
                email: email,
                fullName: fullName.isEmpty ? nil : fullName,
                role: roleString,
                householdId: nil,
                avatarUrl: nil,
                age: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            try await supabase
                .from("profiles")
                .insert(newProfile)
                .execute()

            print("✅ Created new profile with Apple ID: \(fullName)")

            // Update authService with the new profile
            await MainActor.run {
                authService.currentProfile = newProfile
            }

            // Show name prompt to allow user to customize their name
            await MainActor.run {
                isLoading = false
                tempProfileAfterAppleSignup = newProfile
                showingNamePrompt = true
            }

        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to create account: \(error.localizedDescription)"
                showingError = true
                print("❌ Failed to create Apple account: \(error)")
            }
        }
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
            .foregroundColor(.black) // Ensure text is always black on white background
            .accentColor(.blue) // Cursor color
            .introspectTextField()
    }
}

// MARK: - TextField Introspection for Placeholder Color

extension View {
    func introspectTextField() -> some View {
        self.background(
            TextFieldIntrospector()
        )
    }
}

struct TextFieldIntrospector: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false

        DispatchQueue.main.async {
            // CRITICAL FIX: Set placeholder appearance without breaking functionality
            // Only modify the appearance proxy, don't override UITextField methods
            if let textField = view.superview?.superview?.subviews.compactMap({ $0 as? UITextField }).first {
                // Set placeholder color to dark gray for visibility on white background
                if let placeholder = textField.placeholder {
                    textField.attributedPlaceholder = NSAttributedString(
                        string: placeholder,
                        attributes: [.foregroundColor: UIColor.darkGray]
                    )
                }
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
