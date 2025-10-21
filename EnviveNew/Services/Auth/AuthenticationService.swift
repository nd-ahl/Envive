import Foundation
import Supabase
import AuthenticationServices
import Combine

/// Service that handles all authentication operations
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    @Published var isAuthenticated = false
    @Published var currentProfile: Profile?

    private let supabase = SupabaseService.shared.client

    private init() {
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Check Authentication Status

    /// Check if user is currently authenticated
    func checkAuthStatus() async {
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

        // Create auth user with metadata for the database trigger
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: [
                "full_name": .string(fullName),
                "role": .string(role == .parent ? "parent" : "child")
            ]
        )

        let user = response.user

        await MainActor.run {
            self.isAuthenticated = true
        }

        // The profile was auto-created by the database trigger
        // Wait a moment for the trigger to complete, then load the profile
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second

        return try await loadProfile(userId: user.id.uuidString)
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> Profile {
        // DO NOT clear data here automatically
        // Caller should clear if needed (e.g., ExistingUserSignInView)

        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )

        await MainActor.run {
            self.isAuthenticated = true
        }

        // Load profile
        return try await loadProfile(userId: session.user.id.uuidString)
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

        // Prepare user metadata for the database trigger
        let fullName = [
            appleIDCredential.fullName?.givenName,
            appleIDCredential.fullName?.familyName
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        // Sign in with Supabase using Apple token
        // The database trigger will automatically create the profile
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        await MainActor.run {
            self.isAuthenticated = true
        }

        // The profile was auto-created by the database trigger
        // Wait a moment for the trigger to complete, then load the profile
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second

        return try await loadProfile(userId: session.user.id.uuidString)
    }

    // MARK: - Profile Management

    /// Load user profile from database
    @discardableResult
    private func loadProfile(userId: String) async throws -> Profile {
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
            return "User profile not found."
        }
    }
}
