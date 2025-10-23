import Foundation
import Combine
import Security

// MARK: - Parent Password Manager

/// Manages password protection for parent-only features
class ParentPasswordManager: ObservableObject {
    static let shared = ParentPasswordManager()

    @Published var isUnlocked: Bool = false

    private let keychainService = "com.neal.envivenew.parent"
    private let passwordKey = "parentPassword"
    private let sessionTimeout: TimeInterval = 300 // 5 minutes

    private var unlockTime: Date?

    private init() {
        checkSessionExpiration()
    }

    // MARK: - Password Management

    /// Check if a parent password is set
    var isPasswordSet: Bool {
        return getStoredPassword() != nil
    }

    /// Set or update the parent password
    func setPassword(_ password: String) throws {
        guard !password.isEmpty else {
            throw PasswordError.emptyPassword
        }

        guard password.count >= 4 else {
            throw PasswordError.passwordTooShort
        }

        // Store password securely in keychain
        try saveToKeychain(password)
        print("✅ Parent password set successfully")
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
}

// MARK: - Password Error

enum PasswordError: LocalizedError {
    case emptyPassword
    case passwordTooShort
    case encodingFailed
    case keychainSaveFailed

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
        }
    }
}
