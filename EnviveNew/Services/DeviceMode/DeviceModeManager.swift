import Foundation
import Combine

// MARK: - Device Mode Manager Protocol

/// Manages the current device mode and user profile
/// Architecture: This protocol allows swapping between local (UserDefaults) and remote (Firebase) implementations
protocol DeviceModeManager: AnyObject {
    /// Current active mode
    var currentMode: DeviceMode { get }

    /// Current user profile
    var currentProfile: UserProfile? { get }

    /// Observable mode changes
    var modePublisher: AnyPublisher<DeviceMode, Never> { get }

    /// Observable profile changes
    var profilePublisher: AnyPublisher<UserProfile?, Never> { get }

    /// Switch to a different mode
    func switchMode(to mode: DeviceMode, profile: UserProfile)

    /// Get current profile
    func getCurrentProfile() -> UserProfile?

    /// Check if user is in parent mode
    func isParentMode() -> Bool

    /// Check if user is in child mode
    func isChildMode() -> Bool

    /// Get the test child ID for single-device testing
    /// This returns a consistent ID so tasks assigned by parent show up for child
    func getTestChildId() -> UUID
}

// MARK: - Device Mode Manager Implementation (Local Storage)

/// Local storage implementation for single-device testing
/// Future: Will be replaced/supplemented with FirebaseDeviceModeManager for multi-device sync
class LocalDeviceModeManager: DeviceModeManager, ObservableObject {
    private let storage: StorageService
    private let modeKey = "device_mode"
    private let profileKey = "user_profile"
    private let testChildIdKey = "test_child_id"

    @Published private(set) var currentMode: DeviceMode
    @Published private(set) var currentProfile: UserProfile?

    // Consistent test child ID for single-device testing
    private var testChildId: UUID

    var modePublisher: AnyPublisher<DeviceMode, Never> {
        $currentMode.eraseToAnyPublisher()
    }

    var profilePublisher: AnyPublisher<UserProfile?, Never> {
        $currentProfile.eraseToAnyPublisher()
    }

    init(storage: StorageService) {
        self.storage = storage

        // Load or create consistent test child ID for single-device testing
        if let savedIdString: String = storage.load(forKey: testChildIdKey),
           let savedId = UUID(uuidString: savedIdString) {
            self.testChildId = savedId
        } else {
            self.testChildId = UUID()
            storage.save(self.testChildId.uuidString, forKey: testChildIdKey)
            print("🆔 Created test child ID: \(self.testChildId)")
        }

        // Load current mode from storage, default to parent
        if let savedModeString: String = storage.load(forKey: modeKey),
           let savedMode = DeviceMode(rawValue: savedModeString) {
            self.currentMode = savedMode
        } else {
            self.currentMode = .parent
        }

        // Load current profile from storage
        self.currentProfile = storage.load(forKey: profileKey)

        // Create default profile if none exists
        if self.currentProfile == nil {
            let defaultProfile = UserProfile(
                name: currentMode == .parent ? "Parent" : "Child",
                mode: currentMode
            )
            self.currentProfile = defaultProfile
            storage.save(defaultProfile, forKey: profileKey)
        }
    }

    func switchMode(to mode: DeviceMode, profile: UserProfile) {
        currentMode = mode
        currentProfile = profile

        // Persist to storage
        storage.save(mode.rawValue, forKey: modeKey)
        storage.save(profile, forKey: profileKey)

        print("🔄 Switched to \(mode.displayName) mode: \(profile.name)")
    }

    func getCurrentProfile() -> UserProfile? {
        return currentProfile
    }

    func isParentMode() -> Bool {
        return currentMode == .parent
    }

    func isChildMode() -> Bool {
        return currentMode == .child
    }

    func getTestChildId() -> UUID {
        return testChildId
    }
}

// MARK: - Firebase Device Mode Manager (Future Implementation)

/*
 Future implementation for multi-device sync:

 class FirebaseDeviceModeManager: DeviceModeManager {
     private let db = Firestore.firestore()
     private let auth = Auth.auth()

     func switchMode(to mode: DeviceMode, profile: UserProfile) {
         // Update Firebase user document
         db.collection("users").document(profile.id.uuidString)
             .updateData(["currentMode": mode.rawValue])

         // Update local state
         currentMode = mode
         currentProfile = profile
     }

     // Add real-time listener for profile changes
     func listenForProfileChanges() {
         db.collection("users").document(currentProfile.id.uuidString)
             .addSnapshotListener { snapshot, error in
                 // Sync profile changes across devices
             }
     }
 }
 */
