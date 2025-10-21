import Foundation

// MARK: - Test Data Cleanup Service

/// Service to clean up legacy test data for beta launch
/// Removes old test profiles and resets the app to a clean state
class TestDataCleanupService {
    static let shared = TestDataCleanupService()

    private let userDefaults = UserDefaults.standard

    // Keys to clean up
    private let legacyKeys = [
        "device_mode",
        "user_profile",
        "test_child_1_id",
        "test_child_2_id",
        "profile_mode_parent",
        "profile_mode_child1",
        "profile_mode_child2",
        "parentName",
        "hasCompletedOnboarding"
    ]

    private init() {}

    // MARK: - Public Methods

    /// Clean all legacy test data from UserDefaults
    /// This should be called on first launch after beta deployment
    func cleanLegacyTestData() {
        print("🧹 Starting legacy test data cleanup...")

        var cleanedCount = 0

        // Remove specific legacy keys
        for key in legacyKeys {
            if userDefaults.object(forKey: key) != nil {
                userDefaults.removeObject(forKey: key)
                cleanedCount += 1
                print("   ✓ Removed: \(key)")
            }
        }

        // Remove all profile storage keys (profile_UUID format)
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix("profile_") {
                userDefaults.removeObject(forKey: key)
                cleanedCount += 1
                print("   ✓ Removed: \(key)")
            }
        }

        // Remove mode switcher button position (force re-center)
        userDefaults.removeObject(forKey: "modeSwitcherButtonX")
        userDefaults.removeObject(forKey: "modeSwitcherButtonY")

        userDefaults.synchronize()

        print("🧹 Cleanup complete! Removed \(cleanedCount) legacy keys")
        print("✨ App is now in clean state for beta users")
    }

    /// Check if cleanup has been performed
    func hasPerformedBetaCleanup() -> Bool {
        return userDefaults.bool(forKey: "beta_cleanup_completed_v1")
    }

    /// Mark cleanup as completed
    func markCleanupCompleted() {
        userDefaults.set(true, forKey: "beta_cleanup_completed_v1")
        userDefaults.synchronize()
    }

    /// Perform cleanup only if not already done
    func performCleanupIfNeeded() {
        if !hasPerformedBetaCleanup() {
            cleanLegacyTestData()
            markCleanupCompleted()
        } else {
            print("✓ Beta cleanup already performed, skipping...")
        }
    }

    /// Force cleanup (for testing/debugging)
    func forceCleanup() {
        cleanLegacyTestData()
        markCleanupCompleted()
    }

    /// Reset everything including cleanup flag (for development)
    func resetEverything() {
        print("⚠️  RESET EVERYTHING - Development only!")

        // Remove cleanup flag
        userDefaults.removeObject(forKey: "beta_cleanup_completed_v1")

        // Clean all data
        cleanLegacyTestData()

        // Clear onboarding state
        userDefaults.removeObject(forKey: "hasCompletedOnboarding")
        userDefaults.removeObject(forKey: "onboardingCompleted")

        // Clear household data
        userDefaults.removeObject(forKey: "householdCode")
        userDefaults.removeObject(forKey: "currentHouseholdId")

        // Clear authentication service data
        userDefaults.removeObject(forKey: "currentUserId")
        userDefaults.removeObject(forKey: "userEmail")

        userDefaults.synchronize()

        print("✓ Complete reset performed")
    }

    // MARK: - Diagnostic Methods

    /// Print all UserDefaults keys for debugging
    func printAllStoredKeys() {
        print("\n📋 All UserDefaults Keys:")
        print(String(repeating: "=", count: 50))

        let allKeys = userDefaults.dictionaryRepresentation().keys.sorted()
        for key in allKeys {
            if let value = userDefaults.object(forKey: key) {
                print("  \(key): \(type(of: value))")
            }
        }

        print(String(repeating: "=", count: 50))
        print("Total keys: \(allKeys.count)\n")
    }

    /// Check for any remaining test data
    func hasRemainingTestData() -> Bool {
        let allKeys = userDefaults.dictionaryRepresentation().keys

        for key in allKeys {
            if legacyKeys.contains(key) {
                return true
            }
            if key.hasPrefix("profile_") && key.contains("mode") {
                return true
            }
        }

        return false
    }
}
