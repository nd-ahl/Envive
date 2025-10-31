import Foundation
import Combine
import LocalAuthentication

// MARK: - Biometric Authentication Service

/// Service for handling Face ID and Touch ID authentication
/// Used by parents to bypass/change screen time restriction passwords
final class BiometricAuthenticationService: ObservableObject {
    static let shared = BiometricAuthenticationService()

    @Published var isBiometricsAvailable: Bool = false
    @Published var biometricType: BiometricType = .none
    @Published var isAuthenticating: Bool = false  // Track when biometric auth is in progress

    var authCompletionTime: Date?  // Track when auth completed for grace period (internal for debugging)
    private let context = LAContext()
    private let gracePeriod: TimeInterval = 3.0  // 3 second grace period after auth completes (covers view transitions and rebuilds)

    // MARK: - Biometric Type

    enum BiometricType {
        case none
        case touchID
        case faceID

        var displayName: String {
            switch self {
            case .none: return "Biometrics"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            }
        }

        var icon: String {
            switch self {
            case .none: return "lock.fill"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        checkBiometricAvailability()
    }

    // MARK: - Public Methods

    /// Check if we're currently authenticating or within grace period after auth
    var shouldPreventSplashScreen: Bool {
        if isAuthenticating {
            return true
        }

        // Check if we're within grace period after authentication completed
        if let completionTime = authCompletionTime {
            let elapsed = Date().timeIntervalSince(completionTime)
            return elapsed < gracePeriod
        }

        return false
    }

    /// Clear the grace period - call when user explicitly navigates away from auth flows
    func clearGracePeriod() {
        authCompletionTime = nil
        print("🧹 Grace period cleared manually")
    }

    /// Check if biometric authentication is available on this device
    func checkBiometricAvailability() {
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricsAvailable = true

            // Determine biometric type
            switch context.biometryType {
            case .none:
                biometricType = .none
            case .touchID:
                biometricType = .touchID
            case .faceID:
                biometricType = .faceID
            @unknown default:
                biometricType = .none
            }

            print("✅ Biometric authentication available: \(biometricType.displayName)")
        } else {
            isBiometricsAvailable = false
            biometricType = .none
            print("❌ Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    /// Authenticate the parent using biometrics (Face ID or Touch ID)
    /// - Parameter reason: The reason shown to the user for authentication
    /// - Returns: True if authentication successful, false otherwise
    func authenticateParent(reason: String = "Authenticate to manage app restrictions") async -> Result<Bool, BiometricError> {
        // Check availability first
        checkBiometricAvailability()

        guard isBiometricsAvailable else {
            return .failure(.notAvailable)
        }

        // Set flag to prevent splash screen during auth
        await MainActor.run {
            isAuthenticating = true
        }

        // Create a fresh context for each authentication attempt
        let authContext = LAContext()
        authContext.localizedCancelTitle = "Use Password"

        var error: NSError?

        // Check if biometric authentication can be evaluated
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("❌ Cannot evaluate biometric policy: \(error?.localizedDescription ?? "Unknown")")
            await MainActor.run {
                isAuthenticating = false
                authCompletionTime = Date()  // Record completion time for policy evaluation failures
            }
            return .failure(.notAvailable)
        }

        do {
            print("🔐 Requesting biometric authentication...")
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            await MainActor.run {
                isAuthenticating = false
                authCompletionTime = Date()  // Record completion time for grace period
                print("⏰ Auth completed at \(authCompletionTime!) - grace period active for \(gracePeriod)s")
            }

            if success {
                print("✅ Biometric authentication successful")
                return .success(true)
            } else {
                print("❌ Biometric authentication failed")
                return .failure(.authenticationFailed)
            }
        } catch let error as LAError {
            print("❌ Biometric authentication error: \(error.localizedDescription)")

            await MainActor.run {
                isAuthenticating = false
                authCompletionTime = Date()  // Record completion time even for errors
            }

            switch error.code {
            case .authenticationFailed:
                return .failure(.authenticationFailed)
            case .userCancel:
                return .failure(.userCancelled)
            case .userFallback:
                return .failure(.userFallback)
            case .biometryNotAvailable:
                return .failure(.notAvailable)
            case .biometryNotEnrolled:
                return .failure(.notEnrolled)
            case .biometryLockout:
                return .failure(.lockout)
            default:
                return .failure(.other(error.localizedDescription))
            }
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            await MainActor.run {
                isAuthenticating = false
                authCompletionTime = Date()  // Record completion time for unexpected errors
            }
            return .failure(.other(error.localizedDescription))
        }
    }

    /// Authenticate with device passcode as fallback
    func authenticateWithPasscode(reason: String = "Authenticate to manage app restrictions") async -> Result<Bool, BiometricError> {
        let authContext = LAContext()
        authContext.localizedCancelTitle = "Cancel"

        do {
            print("🔐 Requesting passcode authentication...")
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthentication, // This allows passcode as well
                localizedReason: reason
            )

            if success {
                print("✅ Passcode authentication successful")
                return .success(true)
            } else {
                print("❌ Passcode authentication failed")
                return .failure(.authenticationFailed)
            }
        } catch let error as LAError {
            print("❌ Passcode authentication error: \(error.localizedDescription)")

            switch error.code {
            case .userCancel:
                return .failure(.userCancelled)
            default:
                return .failure(.other(error.localizedDescription))
            }
        } catch {
            return .failure(.other(error.localizedDescription))
        }
    }
}

// MARK: - Biometric Error

enum BiometricError: Error, LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case userFallback
    case lockout
    case other(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
        case .authenticationFailed:
            return "Authentication failed. Please try again"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User requested password fallback"
        case .lockout:
            return "Biometric authentication is locked due to too many failed attempts. Please try again later"
        case .other(let message):
            return message
        }
    }
}
