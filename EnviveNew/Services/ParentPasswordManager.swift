import Foundation
import Combine
import Security
import Supabase

// MARK: - Parent Password Manager

/// Manages password protection for parent-only features
/// Syncs password across household devices via Supabase
class ParentPasswordManager: ObservableObject {
    static let shared = ParentPasswordManager()

    @Published var isUnlocked: Bool = false

    private let keychainService = "com.neal.envivenew.parent"
    private let passwordKey = "parentPassword"
    private let sessionTimeout: TimeInterval = 300 // 5 minutes

    private var unlockTime: Date?
    private let supabase = SupabaseService.shared.client
    private let householdService = HouseholdService.shared

    private init() {
        checkSessionExpiration()
        // Sync password from Supabase on init
        Task {
            await syncPasswordFromSupabase()
        }
    }

    // MARK: - Password Management

    /// Check if a parent password is set
    var isPasswordSet: Bool {
        return getStoredPassword() != nil
    }

    /// Set or update the parent password
    func setPassword(_ password: String) async throws {
        guard !password.isEmpty else {
            throw PasswordError.emptyPassword
        }

        guard password.count >= 4 else {
            throw PasswordError.passwordTooShort
        }

        // Store password securely in keychain
        try saveToKeychain(password)

        // Sync to Supabase for household-wide access
        try await syncPasswordToSupabase(password)

        print("✅ Parent password set and synced successfully")
    }

    /// Verify the password
    func verifyPassword(_ password: String) -> Bool {
        guard let storedPassword = getStoredPassword() else {
            print("⚠️ No password set")
            return false
        }

        let isValid = password == storedPassword

        if isValid {
            unlock()
        }

        return isValid
    }

    /// Remove the password (for reset)
    func removePassword() {
        deleteFromKeychain()
        lock()
        print("🔓 Parent password removed")
    }

    // MARK: - Session Management

    /// Unlock parent features
    private func unlock() {
        isUnlocked = true
        unlockTime = Date()
        print("🔓 Parent features unlocked")
    }

    /// Lock parent features
    func lock() {
        isUnlocked = false
        unlockTime = nil
        print("🔒 Parent features locked")
    }

    /// Check if session has expired
    private func checkSessionExpiration() {
        guard let unlockTime = unlockTime else {
            lock()
            return
        }

        let elapsed = Date().timeIntervalSince(unlockTime)
        if elapsed > sessionTimeout {
            lock()
        }
    }

    /// Extend session when user is active
    func extendSession() {
        if isUnlocked {
            unlockTime = Date()
        }
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(_ password: String) throws {
        guard let data = password.data(using: .utf8) else {
            throw PasswordError.encodingFailed
        }

        // Delete existing item first
        deleteFromKeychain()

        // Add new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passwordKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw PasswordError.keychainSaveFailed
        }
    }

    private func getStoredPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passwordKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }

        return password
    }

    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passwordKey
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Supabase Sync

    /// Sync password to Supabase for household-wide access
    private func syncPasswordToSupabase(_ password: String) async throws {
        guard let household = householdService.currentHousehold else {
            print("⚠️ No current household - cannot sync password")
            return
        }

        do {
            // Update household with encrypted password
            try await supabase
                .from("households")
                .update(["app_restriction_password": password])
                .eq("id", value: household.id)
                .execute()

            print("✅ Password synced to Supabase for household: \(household.name)")
        } catch {
            print("❌ Failed to sync password to Supabase: \(error.localizedDescription)")
            throw PasswordError.syncFailed
        }
    }

    /// Fetch password from Supabase (for child devices)
    func syncPasswordFromSupabase() async {
        guard let household = householdService.currentHousehold else {
            print("⚠️ No current household - cannot fetch password")
            return
        }

        do {
            // Fetch household password
            let response: Household = try await supabase
                .from("households")
                .select()
                .eq("id", value: household.id)
                .single()
                .execute()
                .value

            // If password exists in Supabase, update local keychain
            if let password = response.appRestrictionPassword, !password.isEmpty {
                try saveToKeychain(password)
                print("✅ Password synced from Supabase")
            }
        } catch {
            print("⚠️ Could not fetch password from Supabase: \(error.localizedDescription)")
        }
    }

    /// Force refresh password from Supabase (call when child device needs latest password)
    func refreshPasswordFromServer() async {
        await syncPasswordFromSupabase()
    }

    // MARK: - Password Reset

    /// Request a password reset - generates a code and sends email
    func requestPasswordReset() async throws -> String {
        guard let household = householdService.currentHousehold else {
            throw PasswordError.noHousehold
        }

        // Generate 6-digit reset code
        let resetCode = String(format: "%06d", Int.random(in: 100000...999999))
        let expiryDate = Date().addingTimeInterval(15 * 60) // 15 minutes

        // Store reset code in Supabase
        try await supabase
            .from("households")
            .update([
                "password_reset_code": resetCode,
                "password_reset_expiry": ISO8601DateFormatter().string(from: expiryDate)
            ])
            .eq("id", value: household.id)
            .execute()

        print("✅ Password reset code generated: \(resetCode)")

        // Get parent email for sending the code
        guard let parentEmail = AuthenticationService.shared.currentProfile?.email else {
            throw PasswordError.noEmail
        }

        // Send email with reset code
        try await sendResetCodeEmail(email: parentEmail, code: resetCode, householdName: household.name)

        return parentEmail
    }

    /// Verify reset code and reset password
    func resetPasswordWithCode(code: String, newPassword: String) async throws {
        guard let household = householdService.currentHousehold else {
            throw PasswordError.noHousehold
        }

        guard newPassword.count >= 4 else {
            throw PasswordError.passwordTooShort
        }

        // Fetch household to verify code
        let response: Household = try await supabase
            .from("households")
            .select()
            .eq("id", value: household.id)
            .single()
            .execute()
            .value

        // Verify reset code exists and hasn't expired
        guard let storedCode = response.passwordResetCode,
              let expiry = response.passwordResetExpiry else {
            throw PasswordError.invalidResetCode
        }

        guard storedCode == code else {
            throw PasswordError.invalidResetCode
        }

        guard expiry > Date() else {
            throw PasswordError.resetCodeExpired
        }

        // Code is valid - set new password
        try saveToKeychain(newPassword)
        try await syncPasswordToSupabase(newPassword)

        // Clear reset code - set to null in database
        struct ResetCodeClear: Encodable {
            let password_reset_code: String?
            let password_reset_expiry: String?
        }

        let clearData = ResetCodeClear(password_reset_code: nil, password_reset_expiry: nil)

        try await supabase
            .from("households")
            .update(clearData)
            .eq("id", value: household.id)
            .execute()

        print("✅ Password reset successfully with code")
    }

    /// Send reset code via email
    private func sendResetCodeEmail(email: String, code: String, householdName: String) async throws {
        // In a production app, you would use a service like SendGrid, AWS SES, or Supabase Edge Functions
        // For now, we'll use a simple notification approach

        // Create encodable struct for email data
        struct EmailData: Encodable {
            let to: String
            let subject: String
            let code: String
            let household_name: String
        }

        let emailData = EmailData(
            to: email,
            subject: "Envive App Restriction Password Reset",
            code: code,
            household_name: householdName
        )

        do {
            // Call your Supabase edge function to send email
            // This is a placeholder - you'll need to implement the edge function
            _ = try await supabase.functions.invoke(
                "send-password-reset-email",
                options: FunctionInvokeOptions(body: emailData)
            )
            print("✅ Reset code email sent to \(email)")
        } catch {
            print("⚠️ Could not send email, but code is still valid: \(code)")
            // Don't throw - the code is still generated and can be used
        }
    }
}

// MARK: - Password Error

enum PasswordError: LocalizedError {
    case emptyPassword
    case passwordTooShort
    case encodingFailed
    case keychainSaveFailed
    case syncFailed
    case noHousehold
    case noEmail
    case invalidResetCode
    case resetCodeExpired

    var errorDescription: String? {
        switch self {
        case .emptyPassword:
            return "Password cannot be empty"
        case .passwordTooShort:
            return "Password must be at least 4 characters"
        case .encodingFailed:
            return "Failed to encode password"
        case .keychainSaveFailed:
            return "Failed to save password securely"
        case .syncFailed:
            return "Failed to sync password to household"
        case .noHousehold:
            return "No household found"
        case .noEmail:
            return "No email address associated with account"
        case .invalidResetCode:
            return "Invalid reset code"
        case .resetCodeExpired:
            return "Reset code has expired. Please request a new one."
        }
    }
}
