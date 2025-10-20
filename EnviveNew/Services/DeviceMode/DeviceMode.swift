import Foundation

// MARK: - Device Mode Enum

/// Represents the current device role in the parent-child system
/// This allows single-device testing while maintaining clean architecture for multi-device Firebase sync
enum DeviceMode: String, Codable, CaseIterable {
    case parent
    case child1
    case child2

    var displayName: String {
        switch self {
        case .parent:
            return "Parent"
        case .child1:
            return "Child 1"
        case .child2:
            return "Child 2"
        }
    }

    var icon: String {
        switch self {
        case .parent:
            return "person.2.fill"
        case .child1:
            return "person.fill"
        case .child2:
            return "person.fill"
        }
    }

    var description: String {
        switch self {
        case .parent:
            return "Manage tasks, approve completions, and monitor children"
        case .child1:
            return "Complete tasks and earn screen time (Sarah)"
        case .child2:
            return "Complete tasks and earn screen time (Jake)"
        }
    }

    /// Check if this mode is any child mode
    var isChildMode: Bool {
        switch self {
        case .parent:
            return false
        case .child1, .child2:
            return true
        }
    }
}

// MARK: - User Profile for Mode

/// Represents a user profile (parent or child)
/// Future: This will be synced with Firebase and support multiple children per family
struct UserProfile: Codable, Identifiable {
    let id: UUID
    let name: String
    let mode: DeviceMode
    let createdAt: Date

    /// User's age
    var age: Int?

    /// Profile photo file name (stored in Documents directory)
    var profilePhotoFileName: String?

    /// For parent mode - track which children they manage (future: from Firebase)
    var managedChildrenIds: [UUID]

    /// For child mode - track their parent (future: from Firebase)
    var parentId: UUID?

    init(id: UUID = UUID(), name: String, mode: DeviceMode, age: Int? = nil, parentId: UUID? = nil, profilePhotoFileName: String? = nil) {
        self.id = id
        self.name = name
        self.mode = mode
        self.age = age
        self.createdAt = Date()
        self.managedChildrenIds = []
        self.parentId = parentId
        self.profilePhotoFileName = profilePhotoFileName
    }
}
