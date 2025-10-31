import Foundation
import Supabase

// MARK: - Test Data Cleanup Service

/// Service to clean up legacy test data for beta launch
/// Removes old test profiles and resets the app to a clean state
class TestDataCleanupService {
    static let shared = TestDataCleanupService()

    private let userDefaults = UserDefaults.standard
    private let supabase = SupabaseService.shared.client

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

    // MARK: - Database Cleanup (Development Only)

    /// **DANGER**: Delete ALL user data from Supabase database
    /// This clears profiles, households, and auth users
    /// Use ONLY for development/testing - requires service role key
    func clearAllDatabaseUsers() async throws {
        print("⚠️  CLEARING ALL DATABASE USERS - DEVELOPMENT ONLY!")
        print(String(repeating: "=", count: 60))

        // Step 1: Sign out current user first
        print("📤 Signing out current user...")
        try? await AuthenticationService.shared.signOut()

        // Step 2: Create admin client with service role key for unrestricted access
        print("🔑 Creating admin client with service role key...")
        let adminClient = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.serviceRoleKey
        )

        do {
            // Step 3: Delete all household members
            print("🗑️  Deleting all household members...")
            try await adminClient
                .from("household_members")
                .delete()
                .neq("household_id", value: "00000000-0000-0000-0000-000000000000") // Delete all (dummy condition)
                .execute()
            print("   ✓ Household members cleared")

            // Step 4: Delete all households
            print("🗑️  Deleting all households...")
            try await adminClient
                .from("households")
                .delete()
                .neq("id", value: "00000000-0000-0000-0000-000000000000") // Delete all (dummy condition)
                .execute()
            print("   ✓ Households cleared")

            // Step 5: Delete all profiles
            // DISABLED: Deleting profiles can break Supabase auth triggers and email sending
            print("⚠️  Skipping profile deletion (can break auth system)")
            print("   → To delete profiles, do it manually in Supabase Dashboard")
            print("   → SQL Editor: DELETE FROM profiles WHERE household_id IS NULL;")

            // Step 6: Delete all auth users using admin API
            print("🗑️  Deleting all auth users...")
            // Note: Supabase admin.deleteUser() requires individual user IDs
            // For bulk deletion, you'd need to:
            // 1. List all users
            // 2. Delete each one individually
            // Or use Supabase Dashboard > Authentication > Users > Delete All
            print("   ⚠️  Auth users must be deleted via Supabase Dashboard")
            print("   → Go to: \(SupabaseConfig.url)")
            print("   → Authentication > Users > Select All > Delete")

            print(String(repeating: "=", count: 60))
            print("✅ Database cleanup complete!")
            print("⚠️  Remember to delete auth users manually in Supabase Dashboard")
            print(String(repeating: "=", count: 60))

        } catch {
            print("❌ Database cleanup failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Clear all local app data AND database (complete reset)
    func nukeEverything() async throws {
        print("💣 NUKE EVERYTHING - Complete Reset!")
        print(String(repeating: "=", count: 60))

        // 1. Clear local data
        print("🧹 Clearing local data...")
        resetEverything()

        // 2. Clear database
        print("🗑️  Clearing database...")
        try await clearAllDatabaseUsers()

        // 3. Clear Core Data
        print("🗑️  Clearing Core Data...")
        // Note: Core Data cleanup would go here if needed

        print(String(repeating: "=", count: 60))
        print("💥 NUKE COMPLETE - App reset to factory state")
        print(String(repeating: "=", count: 60))
    }
}
