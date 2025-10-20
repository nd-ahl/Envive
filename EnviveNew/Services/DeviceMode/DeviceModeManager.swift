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

    /// Get the test child ID for single-device testing (backward compatibility - returns child 1)
    /// This returns a consistent ID so tasks assigned by parent show up for child
    func getTestChildId() -> UUID

    /// Get the first test child ID (Sarah)
    func getTestChild1Id() -> UUID

    /// Get the second test child ID (Jake)
    func getTestChild2Id() -> UUID
}

// MARK: - Device Mode Manager Implementation (Local Storage)

/// Local storage implementation for single-device testing
/// Future: Will be replaced/supplemented with FirebaseDeviceModeManager for multi-device sync
class LocalDeviceModeManager: DeviceModeManager, ObservableObject {
    private let storage: StorageService
    private let modeKey = "device_mode"
    private let profileKey = "user_profile"
    private let testChild1IdKey = "test_child_1_id"
    private let testChild2IdKey = "test_child_2_id"

    @Published private(set) var currentMode: DeviceMode
    @Published private(set) var currentProfile: UserProfile?

    // Consistent test child IDs for single-device testing
    private var testChild1Id: UUID
    private var testChild2Id: UUID

    var modePublisher: AnyPublisher<DeviceMode, Never> {
        $currentMode.eraseToAnyPublisher()
    }

    var profilePublisher: AnyPublisher<UserProfile?, Never> {
        $currentProfile.eraseToAnyPublisher()
    }

    init(storage: StorageService) {
        self.storage = storage

        // Load or create consistent test child IDs for single-device testing
        // Test Child 1 (Sarah)
        if let savedIdString: String = storage.load(forKey: testChild1IdKey),
           let savedId = UUID(uuidString: savedIdString) {
            self.testChild1Id = savedId
        } else {
            self.testChild1Id = UUID()
            storage.save(self.testChild1Id.uuidString, forKey: testChild1IdKey)
            print("🆔 Created test child 1 ID (Sarah): \(self.testChild1Id)")
        }

        // Test Child 2 (Jake)
        if let savedIdString: String = storage.load(forKey: testChild2IdKey),
           let savedId = UUID(uuidString: savedIdString) {
            self.testChild2Id = savedId
        } else {
            self.testChild2Id = UUID()
            storage.save(self.testChild2Id.uuidString, forKey: testChild2IdKey)
            print("🆔 Created test child 2 ID (Jake): \(self.testChild2Id)")
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
            let defaultName: String
            switch currentMode {
            case .parent:
                defaultName = "Parent"
            case .child1:
                defaultName = "Sarah"
            case .child2:
                defaultName = "Jake"
            }

            let defaultProfile = UserProfile(
                name: defaultName,
                mode: currentMode
            )
            self.currentProfile = defaultProfile
            storage.save(defaultProfile, forKey: profileKey)
            // Save to profiles dictionary for cross-mode access
            saveProfileToStorage(defaultProfile)
        }
    }

    func switchMode(to mode: DeviceMode, profile: UserProfile) {
        currentMode = mode
        currentProfile = profile

        // Persist to storage
        storage.save(mode.rawValue, forKey: modeKey)
        storage.save(profile, forKey: profileKey)

        // Also save to profiles dictionary for cross-mode access
        saveProfileToStorage(profile)

        // Note: Credibility service now uses per-child parameters, no need to switch active user

        print("🔄 Switched to \(mode.displayName) mode: \(profile.name)")
    }

    func getCurrentProfile() -> UserProfile? {
        return currentProfile
    }

    func isParentMode() -> Bool {
        return currentMode == .parent
    }

    func isChildMode() -> Bool {
        return currentMode.isChildMode
    }

    func getTestChildId() -> UUID {
        return testChild1Id  // Backward compatibility - returns child 1
    }

    func getTestChild1Id() -> UUID {
        return testChild1Id
    }

    func getTestChild2Id() -> UUID {
        return testChild2Id
    }

    /// Update the current user's profile photo
    func updateProfilePhoto(fileName: String?) {
        guard var profile = currentProfile else { return }

        // Update the profile
        profile.profilePhotoFileName = fileName
        currentProfile = profile

        // Persist to storage
        storage.save(profile, forKey: profileKey)

        // Also save to profiles dictionary for cross-mode access
        saveProfileToStorage(profile)

        print("📸 Updated profile photo: \(fileName ?? "removed")")
    }

    /// Get a profile by ID (for displaying other users' profiles)
    func getProfile(byId id: UUID) -> UserProfile? {
        // Check if it's the current profile
        if let current = currentProfile, current.id == id {
            return current
        }

        // Try to load from profiles storage
        return loadProfileFromStorage(id: id)
    }

    /// Get a profile by mode (for loading existing profiles when switching modes)
    func getProfile(byMode mode: DeviceMode) -> UserProfile? {
        // First check if current profile matches the mode
        if let current = currentProfile, current.mode == mode {
            return current
        }

        // Load from mode-specific storage
        return loadProfileFromStorage(mode: mode)
    }

    // MARK: - Profile Storage (for cross-mode access)

    private func saveProfileToStorage(_ profile: UserProfile) {
        let key = "profile_\(profile.id.uuidString)"
        storage.save(profile, forKey: key)

        // Also save by mode for easy lookup when switching
        let modeKey = "profile_mode_\(profile.mode.rawValue)"
        storage.save(profile, forKey: modeKey)
    }

    private func loadProfileFromStorage(id: UUID) -> UserProfile? {
        let key = "profile_\(id.uuidString)"
        return storage.load(forKey: key)
    }

    private func loadProfileFromStorage(mode: DeviceMode) -> UserProfile? {
        let modeKey = "profile_mode_\(mode.rawValue)"
        return storage.load(forKey: modeKey)
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
