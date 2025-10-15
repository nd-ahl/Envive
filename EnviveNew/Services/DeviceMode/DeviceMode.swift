import Foundation

// MARK: - Device Mode Enum

/// Represents the current device role in the parent-child system
/// This allows single-device testing while maintaining clean architecture for multi-device Firebase sync
enum DeviceMode: String, Codable, CaseIterable {
    case parent
    case child

    var displayName: String {
        switch self {
        case .parent:
            return "Parent"
        case .child:
            return "Child"
        }
    }

    var icon: String {
        switch self {
        case .parent:
            return "person.2.fill"
        case .child:
            return "person.fill"
        }
    }

    var description: String {
        switch self {
        case .parent:
            return "Manage tasks, approve completions, and monitor children"
        case .child:
            return "Complete tasks and earn screen time"
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

    /// For parent mode - track which children they manage (future: from Firebase)
    var managedChildrenIds: [UUID]

    /// For child mode - track their parent (future: from Firebase)
    var parentId: UUID?

    init(id: UUID = UUID(), name: String, mode: DeviceMode, parentId: UUID? = nil) {
        self.id = id
        self.name = name
        self.mode = mode
        self.createdAt = Date()
        self.managedChildrenIds = []
        self.parentId = parentId
    }
}
