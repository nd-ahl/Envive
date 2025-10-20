import Foundation
import Combine

// MARK: - Device Mode Service

/// Centralized service for managing and securing device role assignment
class DeviceModeService: ObservableObject {
    static let shared = DeviceModeService()

    @Published private(set) var deviceMode: DeviceMode
    @Published private(set) var isRoleLocked: Bool

    private let deviceModeKey = "deviceMode"
    private let roleLockedKey = "isRoleLocked"

    private init() {
        // Load saved device mode
        if let savedMode = UserDefaults.standard.string(forKey: deviceModeKey),
           let mode = DeviceMode(rawValue: savedMode) {
            self.deviceMode = mode
        } else {
            // Default to parent if not set (will be set during onboarding)
            self.deviceMode = .parent
        }

        // Load lock status
        self.isRoleLocked = UserDefaults.standard.bool(forKey: roleLockedKey)
    }

    // MARK: - Public Methods

    /// Set the device mode (only allowed during onboarding before lock)
    func setDeviceMode(_ mode: DeviceMode) -> Bool {
        guard !isRoleLocked else {
            print("⚠️ Cannot change device mode - role is locked")
            return false
        }

        deviceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: deviceModeKey)
        print("✅ Device mode set to: \(mode.displayName)")
        return true
    }

    /// Lock the device role (called after role confirmation in onboarding)
    func lockDeviceRole() {
        isRoleLocked = true
        UserDefaults.standard.set(true, forKey: roleLockedKey)
        print("🔒 Device role locked as: \(deviceMode.displayName)")
    }

    /// Unlock device role (requires authentication - for reset purposes)
    func unlockDeviceRole() {
        isRoleLocked = false
        UserDefaults.standard.set(false, forKey: roleLockedKey)
        print("🔓 Device role unlocked")
    }

    /// Reset device role (for testing or device reset)
    func resetDeviceRole() {
        deviceMode = .parent
        isRoleLocked = false
        UserDefaults.standard.removeObject(forKey: deviceModeKey)
        UserDefaults.standard.removeObject(forKey: roleLockedKey)
        print("🔄 Device role reset")
    }

    /// Check if current device is parent mode
    var isParentDevice: Bool {
        return deviceMode == .parent
    }

    /// Check if current device is child mode
    var isChildDevice: Bool {
        return deviceMode == .child
    }

    /// Get device mode from legacy UserRole string
    static func deviceModeFromUserRole(_ roleString: String) -> DeviceMode {
        return roleString == "child" ? .child : .parent
    }

    /// Convert UserRole enum to DeviceMode
    static func deviceModeFromUserRole(_ role: UserRole) -> DeviceMode {
        return role == .child ? .child : .parent
    }
}
