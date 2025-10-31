import Foundation
import Supabase
import AuthenticationServices
import Combine

/// Service that handles all authentication operations
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    @Published var isAuthenticated = false
    @Published var currentProfile: Profile?
    @Published var isCheckingAuth = true

    private let supabase = SupabaseService.shared.client

    private init() {
        // CRITICAL FIX: Do NOT start auth check in init()
        // On real devices with slow networks, this blocks app initialization
        // causing the app to freeze before the splash screen can render
        print("🔐 AuthenticationService.init() - Deferring auth check")
        print("   - This prevents app freeze on slow network connections")
        print("   - Auth check will be triggered manually when splash screen loads")

        // Set to false immediately so app can render without blocking
        self.isCheckingAuth = false
    }

    /// Start auth check manually (called by AnimatedSplashScreen after UI renders)
    func startAuthCheck() async {
        print("🔐 AuthenticationService.startAuthCheck() - Starting NOW")
        await MainActor.run {
            self.isCheckingAuth = true
        }
        await checkAuthStatus()
    }

    // MARK: - Check Authentication Status

    /// Check if user is currently authenticated
    func checkAuthStatus() async {
        defer {
            Task { @MainActor [weak self] in
                self?.isCheckingAuth = false
            }
        }

        do {
            let session = try await supabase.auth.session
            await MainActor.run {
                self.isAuthenticated = true
            }
            // Load user profile
            try await loadProfile(userId: session.user.id.uuidString)
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentProfile = nil
            }
        }
    }

    // MARK: - Email Authentication

    /// Sign up with email and password
    func signUp(email: String, password: String, fullName: String, role: UserRole) async throws -> Profile {
        // DO NOT clear data here - user is mid-onboarding!
        // Only clear data on sign OUT or when existing user signs IN

        print("📧 Creating new user account: \(email)")
        print("   - Full Name: \(fullName)")
        print("   - Role: \(role == .parent ? "parent" : "child")")
        print("   - Redirect URL: envivenew://auth/callback")

        // Create auth user with metadata for the database trigger
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: [
                "full_name": .string(fullName),
                "role": .string(role == .parent ? "parent" : "child")
            ],
            redirectTo: URL(string: "envivenew://auth/callback")  // Email confirmation will redirect here
        )

        print("✅ User account created in Supabase")
        print("   - User ID: \(response.user.id)")
        print("   - Email: \(email)")
        print("   - Email confirmed: \(response.user.emailConfirmedAt != nil ? "YES" : "NO (needs confirmation)")")
        print("   - Session exists: \(response.session != nil ? "YES" : "NO")")

        // IMPORTANT: Check if email was actually sent
        if response.user.emailConfirmedAt == nil {
            print("📬 Confirmation email should be sent to: \(email)")
            print("   ⚠️ If user doesn't receive email, check:")
            print("   - Spam/junk folder")
            print("   - Supabase Dashboard → Logs → Auth Logs for errors")
            print("   - Supabase Dashboard → Authentication → Settings → SMTP configuration")
        } else {
            print("✅ Email already confirmed (no confirmation needed)")
        }

        let user = response.user

        await MainActor.run {
            self.isAuthenticated = true
        }

        let userId = user.id.uuidString
        let roleString = role == .parent ? "parent" : "child"

        // Try to load existing profile, or create one if it doesn't exist
        do {
            // Wait a moment for the database trigger to complete
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            return try await loadProfile(userId: userId)
        } catch {
            // Profile doesn't exist - create it manually
            print("⚠️ Profile not found for sign-up, creating manually...")

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

            // Insert profile into database
            try await supabase
                .from("profiles")
                .insert(newProfile)
                .execute()

            // Now load it
            return try await loadProfile(userId: userId)
        }
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> Profile {
        // DO NOT clear data here automatically
        // Caller should clear if needed (e.g., ExistingUserSignInView)

        print("🔐 Attempting sign-in for: \(email)")

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            print("✅ Auth sign-in successful")
            print("   User ID: \(session.user.id.uuidString)")
            print("   Email confirmed: \(session.user.emailConfirmedAt != nil ? "YES" : "NO")")

            await MainActor.run {
                self.isAuthenticated = true
            }

            // Load profile - MUST exist for sign-in (don't create new one)
            do {
                let profile = try await loadProfile(userId: session.user.id.uuidString)
                print("✅ Sign-in complete - profile loaded")
                return profile
            } catch {
                // Profile doesn't exist - user must create account first
                print("❌ Sign-in failed: No profile found for user \(session.user.id.uuidString)")
                print("   User must go through account creation flow first")

                // Sign out the auth user since they don't have a profile
                try? await supabase.auth.signOut()

                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentProfile = nil
                }

                throw AuthError.profileNotFound
            }
        } catch {
            print("❌ Sign-in failed: \(error.localizedDescription)")

            // Check if it's an email not confirmed error
            if error.localizedDescription.contains("Email not confirmed") ||
               error.localizedDescription.contains("email_not_confirmed") {
                print("⚠️  Email not confirmed - user must click confirmation link in email")
            }

            throw error
        }
    }

    // MARK: - Apple Sign In

    /// Sign in with Apple
    func signInWithApple(authorization: ASAuthorization) async throws -> Profile {
        // DO NOT clear data here automatically
        // Caller should clear if needed (e.g., ExistingUserSignInView)

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidAppleCredentials
        }

        guard let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidAppleToken
        }

        // Sign in with Supabase using Apple token (no need to extract name for sign-in)
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        await MainActor.run {
            self.isAuthenticated = true
        }

        let userId = session.user.id.uuidString

        // Load profile - MUST exist for sign-in (don't create new one)
        do {
            return try await loadProfile(userId: userId)
        } catch {
            // Profile doesn't exist - user must create account first
            print("❌ Apple sign-in failed: No profile found for user \(userId)")
            print("   User must go through account creation flow first")

            // Sign out the auth user since they don't have a profile
            try? await supabase.auth.signOut()

            await MainActor.run {
                self.isAuthenticated = false
                self.currentProfile = nil
            }

            throw AuthError.profileNotFound
        }
    }

    // MARK: - Profile Management

    /// Load user profile from database
    @discardableResult
    func loadProfile(userId: String) async throws -> Profile {
        let response: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        await MainActor.run {
            self.currentProfile = response
            self.isAuthenticated = true

            // Set household context for data isolation
            if let householdIdString = response.householdId,
               let householdId = UUID(uuidString: householdIdString) {

                // If user is a parent, set their ID as the parent ID for household context
                let parentId: UUID? = response.role == "parent" ? UUID(uuidString: response.id) : nil

                HouseholdContext.shared.setHouseholdContext(
                    householdId: householdId,
                    parentId: parentId
                )

                print("🏠 Household context set for \(response.role): household=\(householdId), parent=\(parentId?.uuidString ?? "none")")
            } else {
                print("⚠️ No household ID found for user - household context not set")
            }
        }

        return response
    }

    /// Refresh the current user's profile from the database
    func refreshCurrentProfile() async throws {
        guard let currentUserId = currentProfile?.id else {
            throw NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }

        _ = try await loadProfile(userId: currentUserId)
        print("✅ Profile refreshed - householdId: \(currentProfile?.householdId ?? "nil")")
    }

    /// Update user profile
    func updateProfile(_ profile: Profile) async throws {
        try await supabase
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()

        await MainActor.run {
            self.currentProfile = profile
        }
    }

    // MARK: - Password Reset

    /// Send password reset email to user
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
        print("✅ Password reset email sent to: \(email)")
    }

    // MARK: - Email Verification

    /// Resend confirmation email to user
    func resendConfirmationEmail(email: String) async throws {
        // Supabase automatically resends confirmation when user tries to sign up again with same email
        // We can use the resend endpoint
        try await supabase.auth.resend(
            email: email,
            type: .signup
        )
        print("✅ Confirmation email resent to: \(email)")
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() async throws {
        try await supabase.auth.signOut()

        await MainActor.run {
            self.isAuthenticated = false
            self.currentProfile = nil
        }

        // Clear all cached user data for a fresh start
        clearAllUserData()
    }

    /// Sign out WITHOUT clearing onboarding data
    /// Used during authentication verification when security checks fail
    func signOutWithoutClearingOnboarding() async throws {
        try await supabase.auth.signOut()

        await MainActor.run {
            self.isAuthenticated = false
            self.currentProfile = nil
        }
        // DO NOT call clearAllUserData() - preserve onboarding progress
    }

    // MARK: - Data Cleanup

    /// Public method to manually clear all user data (useful for testing or fresh starts)
    func resetAllUserData() {
        clearAllUserData()
    }

    /// Clear ALL user data from UserDefaults to ensure fresh start for new users
    /// This prevents data leakage between different user accounts
    private func clearAllUserData() {
        let defaults = UserDefaults.standard

        // Profile & Authentication Data
        defaults.removeObject(forKey: "userId")
        defaults.removeObject(forKey: "userEmail")
        defaults.removeObject(forKey: "userName")
        defaults.removeObject(forKey: "userRole")
        defaults.removeObject(forKey: "userAge")
        defaults.removeObject(forKey: "parentName")

        // Household Data
        defaults.removeObject(forKey: "householdId")
        defaults.removeObject(forKey: "householdCode")
        defaults.removeObject(forKey: "isInHousehold")

        // Child Profile Linking (for devices)
        defaults.removeObject(forKey: "linkedChildProfileId")
        defaults.removeObject(forKey: "childName")
        defaults.removeObject(forKey: "childAge")

        // Onboarding State - Reset ALL flags
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "hasCompletedWelcome")
        defaults.removeObject(forKey: "hasCompletedQuestions")
        defaults.removeObject(forKey: "hasCompletedRoleConfirmation")
        defaults.removeObject(forKey: "hasCompletedHouseholdSelection")
        defaults.removeObject(forKey: "hasCompletedSignIn")
        defaults.removeObject(forKey: "hasCompletedNameEntry")
        defaults.removeObject(forKey: "hasCompletedFamilySetup")
        defaults.removeObject(forKey: "hasCompletedAgeSelection")
        defaults.removeObject(forKey: "hasCompletedPermissions")
        defaults.removeObject(forKey: "hasCompletedBenefits")

        // Clear in-memory service state
        HouseholdService.shared.currentHousehold = nil
        HouseholdService.shared.householdMembers = []

        // Clear household context for data isolation
        HouseholdContext.shared.clearHouseholdContext()

        // Reset OnboardingManager state
        OnboardingManager.shared.resetOnboarding()

        // Reset device role
        DeviceModeService.shared.resetDeviceRole()

        print("🧹 All user data cleared - fresh start for new user")
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case signUpFailed
    case invalidAppleCredentials
    case invalidAppleToken
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .invalidAppleCredentials:
            return "Invalid Apple credentials."
        case .invalidAppleToken:
            return "Failed to get Apple ID token."
        case .profileNotFound:
            return "No account found. Please create an account first."
        }
    }
}
