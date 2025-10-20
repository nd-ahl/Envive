import Foundation
import LocalAuthentication
import SwiftUI
import Combine

// MARK: - Reset Onboarding Helper

/// Shared helper for resetting onboarding with authentication
class ResetOnboardingHelper: ObservableObject {
    static let shared = ResetOnboardingHelper()

    @Published var showingResetAlert = false

    private init() {}

    /// Initiate the reset process (authentication disabled for development)
    func initiateReset() {
        // Role locking disabled for development - no authentication needed
        showingResetAlert = true
    }

    /// Authenticate the user with biometrics or passcode
    private func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Try biometric authentication first
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to reset onboarding and unlock device role"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                if let error = authError as? LAError {
                    if error.code == .userCancel || error.code == .systemCancel || error.code == .appCancel {
                        // User cancelled, just return false
                        completion(false)
                        return
                    }
                }
                completion(success)
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // Biometrics not available, but passcode is
            let reason = "Authenticate to reset onboarding and unlock device role"

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                if let error = authError as? LAError {
                    if error.code == .userCancel || error.code == .systemCancel || error.code == .appCancel {
                        // User cancelled, just return false
                        completion(false)
                        return
                    }
                }
                completion(success)
            }
        } else {
            // No authentication available - for development/testing, allow with console warning
            print("⚠️ Biometric authentication is not available on this device. Reset allowed for development.")
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }

    /// Perform the actual reset
    func performReset() {
        OnboardingManager.shared.resetOnboarding()
        // Exit the app so user can reopen and see welcome screen
        exit(0)
    }
}
