import Foundation
import Combine
import Supabase

// MARK: - Onboarding Manager

/// Manages onboarding state and user introduction flow
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
        }
    }

    @Published var hasCompletedWelcome: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedWelcome, forKey: welcomeKey)
        }
    }

    @Published var hasCompletedQuestions: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedQuestions, forKey: questionsKey)
        }
    }

    @Published var hasCompletedAgeSelection: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedAgeSelection, forKey: ageSelectionKey)
        }
    }

    @Published var hasCompletedPermissions: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedPermissions, forKey: permissionsKey)
        }
    }

    @Published var hasCompletedRoleConfirmation: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedRoleConfirmation, forKey: roleConfirmationKey)
        }
    }

    @Published var hasCompletedBenefits: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedBenefits, forKey: benefitsKey)
        }
    }

    @Published var hasCompletedHouseholdSelection: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedHouseholdSelection, forKey: householdSelectionKey)
        }
    }

    @Published var hasCompletedSignIn: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedSignIn, forKey: signInKey)
        }
    }

    @Published var hasCompletedNameEntry: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedNameEntry, forKey: nameEntryKey)
        }
    }

    @Published var hasCompletedFamilySetup: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedFamilySetup, forKey: familySetupKey)
        }
    }

    private let onboardingKey = "hasCompletedOnboarding"
    private let welcomeKey = "hasCompletedWelcome"
    private let questionsKey = "hasCompletedQuestions"
    private let roleConfirmationKey = "hasCompletedRoleConfirmation"
    private let householdSelectionKey = "hasCompletedHouseholdSelection"
    private let signInKey = "hasCompletedSignIn"
    private let nameEntryKey = "hasCompletedNameEntry"
    private let familySetupKey = "hasCompletedFamilySetup"
    private let ageSelectionKey = "hasCompletedAgeSelection"
    private let permissionsKey = "hasCompletedPermissions"
    private let benefitsKey = "hasCompletedBenefits"

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.hasCompletedWelcome = UserDefaults.standard.bool(forKey: welcomeKey)
        self.hasCompletedQuestions = UserDefaults.standard.bool(forKey: questionsKey)
        self.hasCompletedRoleConfirmation = UserDefaults.standard.bool(forKey: roleConfirmationKey)
        self.hasCompletedHouseholdSelection = UserDefaults.standard.bool(forKey: householdSelectionKey)
        self.hasCompletedSignIn = UserDefaults.standard.bool(forKey: signInKey)
        self.hasCompletedNameEntry = UserDefaults.standard.bool(forKey: nameEntryKey)
        self.hasCompletedFamilySetup = UserDefaults.standard.bool(forKey: familySetupKey)
        self.hasCompletedAgeSelection = UserDefaults.standard.bool(forKey: ageSelectionKey)
        self.hasCompletedPermissions = UserDefaults.standard.bool(forKey: permissionsKey)
        self.hasCompletedBenefits = UserDefaults.standard.bool(forKey: benefitsKey)
    }

    // MARK: - Public Methods

    /// Mark welcome screen as completed
    func completeWelcome() {
        hasCompletedWelcome = true
        print("✅ Welcome screen completed")
    }

    /// Mark questions as completed
    func completeQuestions() {
        hasCompletedQuestions = true
        print("✅ Onboarding questions completed")
    }

    /// Mark role confirmation as completed (role locking disabled for development)
    func completeRoleConfirmation(role: UserRole) {
        let mode = DeviceModeService.deviceModeFromUserRole(role)
        _ = DeviceModeService.shared.setDeviceMode(mode)
        // DeviceModeService.shared.lockDeviceRole() // Disabled for development - can switch freely
        hasCompletedRoleConfirmation = true
        print("✅ Role confirmation completed: \(mode.displayName) (unlocked for testing)")
    }

    /// Mark age selection as completed and save age
    func completeAgeSelection(age: Int) {
        UserDefaults.standard.set(age, forKey: "userAge")
        hasCompletedAgeSelection = true
        print("✅ Age selection completed: \(age) years old")
    }

    /// Mark permissions screen as completed
    func completePermissions() {
        hasCompletedPermissions = true
        print("✅ Permissions screen completed")
    }

    /// Mark benefits screen as completed
    func completeBenefits() {
        hasCompletedBenefits = true
        print("✅ Benefits screen completed")
    }

    /// Mark household selection as completed
    func completeHouseholdSelection() {
        hasCompletedHouseholdSelection = true
        print("✅ Household selection completed")
    }

    /// Mark sign in as completed
    func completeSignIn() {
        hasCompletedSignIn = true
        print("✅ Sign in completed")
    }

    /// Mark name entry as completed and save name
    func completeNameEntry(name: String) {
        UserDefaults.standard.set(name, forKey: "parentName")
        hasCompletedNameEntry = true
        print("✅ Name entry completed: \(name)")

        // Also update the Supabase profile
        Task {
            guard let userId = AuthenticationService.shared.currentProfile?.id else { return }

            do {
                try await SupabaseService.shared.client
                    .from("profiles")
                    .update(["full_name": name])
                    .eq("id", value: userId)
                    .execute()

                print("✅ Parent name saved to Supabase: \(name)")
            } catch {
                print("❌ Failed to save parent name to Supabase: \(error.localizedDescription)")
            }
        }
    }

    /// Mark family setup as completed (add profiles + link devices)
    func completeFamilySetup() {
        hasCompletedFamilySetup = true
        // Also mark age selection as complete since we collect age during family setup
        hasCompletedAgeSelection = true
        print("✅ Family setup completed")
    }

    /// Mark entire onboarding flow as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
        hasCompletedWelcome = true
        hasCompletedQuestions = true
        hasCompletedRoleConfirmation = true
        hasCompletedHouseholdSelection = true
        hasCompletedSignIn = true
        hasCompletedNameEntry = true
        hasCompletedFamilySetup = true
        hasCompletedAgeSelection = true
        hasCompletedPermissions = true
        hasCompletedBenefits = true
        print("✅ Onboarding flow completed")
    }

    /// Reset onboarding (for testing - requires authentication)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasCompletedWelcome = false
        hasCompletedQuestions = false
        hasCompletedRoleConfirmation = false
        hasCompletedHouseholdSelection = false
        hasCompletedSignIn = false
        hasCompletedNameEntry = false
        hasCompletedFamilySetup = false
        hasCompletedAgeSelection = false
        hasCompletedPermissions = false
        hasCompletedBenefits = false
        UserDefaults.standard.removeObject(forKey: "userAge")
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "parentName")
        UserDefaults.standard.removeObject(forKey: "householdCode")
        UserDefaults.standard.removeObject(forKey: "isInHousehold")

        // Unlock and reset device role
        DeviceModeService.shared.resetDeviceRole()

        print("🔄 Onboarding reset")
    }

    /// Check if user should see onboarding
    var shouldShowOnboarding: Bool {
        return !hasCompletedOnboarding
    }

    /// Check if user should see welcome screen
    var shouldShowWelcome: Bool {
        return !hasCompletedWelcome
    }

    /// Check if user should see questions
    var shouldShowQuestions: Bool {
        return hasCompletedWelcome && !hasCompletedQuestions
    }

    /// Check if user should see role confirmation
    var shouldShowRoleConfirmation: Bool {
        return hasCompletedQuestions && !hasCompletedRoleConfirmation
    }

    /// Check if user should see household selection
    var shouldShowHouseholdSelection: Bool {
        return hasCompletedRoleConfirmation && !hasCompletedHouseholdSelection
    }

    /// Check if user should see sign in (when creating household)
    var shouldShowSignIn: Bool {
        return hasCompletedHouseholdSelection && !hasCompletedSignIn
    }

    /// Check if user should see name entry
    var shouldShowNameEntry: Bool {
        return hasCompletedSignIn && !hasCompletedNameEntry
    }

    /// Check if user should see family setup (add profiles + link devices)
    var shouldShowFamilySetup: Bool {
        return hasCompletedNameEntry && !hasCompletedFamilySetup
    }

    /// Check if user should see age selection (SKIPPED - age collected during family setup)
    var shouldShowAgeSelection: Bool {
        return false // Age is collected during child profile creation
    }

    /// Check if user should see permissions screen
    var shouldShowPermissions: Bool {
        return hasCompletedFamilySetup && !hasCompletedPermissions
    }

    /// Check if user should see benefits screen
    var shouldShowBenefits: Bool {
        return hasCompletedPermissions && !hasCompletedBenefits
    }

    /// Get saved user age
    var userAge: Int? {
        let age = UserDefaults.standard.integer(forKey: "userAge")
        return age > 0 ? age : nil
    }

    /// Get saved parent name
    var parentName: String? {
        return UserDefaults.standard.string(forKey: "parentName")
    }
}
