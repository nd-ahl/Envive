import Foundation
import Combine

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

    private let onboardingKey = "hasCompletedOnboarding"
    private let welcomeKey = "hasCompletedWelcome"
    private let questionsKey = "hasCompletedQuestions"
    private let roleConfirmationKey = "hasCompletedRoleConfirmation"
    private let ageSelectionKey = "hasCompletedAgeSelection"
    private let permissionsKey = "hasCompletedPermissions"
    private let benefitsKey = "hasCompletedBenefits"

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.hasCompletedWelcome = UserDefaults.standard.bool(forKey: welcomeKey)
        self.hasCompletedQuestions = UserDefaults.standard.bool(forKey: questionsKey)
        self.hasCompletedRoleConfirmation = UserDefaults.standard.bool(forKey: roleConfirmationKey)
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

    /// Mark entire onboarding flow as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
        hasCompletedWelcome = true
        hasCompletedQuestions = true
        hasCompletedRoleConfirmation = true
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
        hasCompletedAgeSelection = false
        hasCompletedPermissions = false
        hasCompletedBenefits = false
        UserDefaults.standard.removeObject(forKey: "userAge")
        UserDefaults.standard.removeObject(forKey: "userRole")

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

    /// Check if user should see age selection
    var shouldShowAgeSelection: Bool {
        return hasCompletedRoleConfirmation && !hasCompletedAgeSelection
    }

    /// Check if user should see permissions screen
    var shouldShowPermissions: Bool {
        return hasCompletedAgeSelection && !hasCompletedPermissions
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
}
