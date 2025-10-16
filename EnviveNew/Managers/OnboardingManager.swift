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

    private let onboardingKey = "hasCompletedOnboarding"
    private let welcomeKey = "hasCompletedWelcome"
    private let questionsKey = "hasCompletedQuestions"
    private let ageSelectionKey = "hasCompletedAgeSelection"
    private let permissionsKey = "hasCompletedPermissions"

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.hasCompletedWelcome = UserDefaults.standard.bool(forKey: welcomeKey)
        self.hasCompletedQuestions = UserDefaults.standard.bool(forKey: questionsKey)
        self.hasCompletedAgeSelection = UserDefaults.standard.bool(forKey: ageSelectionKey)
        self.hasCompletedPermissions = UserDefaults.standard.bool(forKey: permissionsKey)
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

    /// Mark entire onboarding flow as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
        hasCompletedWelcome = true
        hasCompletedQuestions = true
        hasCompletedAgeSelection = true
        hasCompletedPermissions = true
        print("✅ Onboarding flow completed")
    }

    /// Reset onboarding (for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasCompletedWelcome = false
        hasCompletedQuestions = false
        hasCompletedAgeSelection = false
        hasCompletedPermissions = false
        UserDefaults.standard.removeObject(forKey: "userAge")
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

    /// Check if user should see age selection
    var shouldShowAgeSelection: Bool {
        return hasCompletedQuestions && !hasCompletedAgeSelection
    }

    /// Check if user should see permissions screen
    var shouldShowPermissions: Bool {
        return hasCompletedAgeSelection && !hasCompletedPermissions
    }

    /// Get saved user age
    var userAge: Int? {
        let age = UserDefaults.standard.integer(forKey: "userAge")
        return age > 0 ? age : nil
    }
}
