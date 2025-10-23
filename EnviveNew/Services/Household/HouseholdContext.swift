import Foundation
import Combine

// MARK: - Household Context Service

/// Manages household context for strict data isolation
/// Ensures all data queries are scoped to the current user's household
class HouseholdContext: ObservableObject {
    static let shared = HouseholdContext()

    // Current household ID (nil if not logged in or no household)
    @Published private(set) var currentHouseholdId: UUID?

    // Current parent ID (nil if child or not logged in)
    @Published private(set) var currentParentId: UUID?

    // All children in current household
    @Published private(set) var householdChildren: [UserProfile] = []

    // Current child ID when in child mode (for task filtering)
    @Published private(set) var currentChildId: UUID?

    private let storage: StorageService
    private let householdIdKey = "current_household_id"
    private let parentIdKey = "current_parent_id"
    private let childIdKey = "current_child_id"

    private init() {
        self.storage = DependencyContainer.shared.storage

        // Load saved household context
        if let savedHouseholdIdString: String = storage.load(forKey: householdIdKey),
           let savedHouseholdId = UUID(uuidString: savedHouseholdIdString) {
            self.currentHouseholdId = savedHouseholdId
            print("📦 Loaded household context: \(savedHouseholdId)")
        }

        if let savedParentIdString: String = storage.load(forKey: parentIdKey),
           let savedParentId = UUID(uuidString: savedParentIdString) {
            self.currentParentId = savedParentId
            print("👨 Loaded parent context: \(savedParentId)")
        }
    }

    // MARK: - Context Management

    /// Set the current household context (call when user logs in or creates household)
    func setHouseholdContext(householdId: UUID, parentId: UUID?) {
        // IMPORTANT: Clear any previous household data first to prevent data leakage
        householdChildren = []
        currentChildId = nil

        currentHouseholdId = householdId
        currentParentId = parentId

        // Persist to storage
        storage.save(householdId.uuidString, forKey: householdIdKey)
        if let parentId = parentId {
            storage.save(parentId.uuidString, forKey: parentIdKey)
        } else {
            storage.remove(forKey: parentIdKey)
        }

        print("✅ Household context set: household=\(householdId), parent=\(parentId?.uuidString ?? "none")")

        // Load household children from database (will replace householdChildren array)
        loadHouseholdChildren()
    }

    /// Clear household context (call on logout or reset)
    func clearHouseholdContext() {
        currentHouseholdId = nil
        currentParentId = nil
        householdChildren = []

        storage.remove(forKey: householdIdKey)
        storage.remove(forKey: parentIdKey)

        print("🧹 Household context cleared")
    }

    /// Update children list for current household
    func setHouseholdChildren(_ children: [UserProfile]) {
        householdChildren = children
        print("👶 Updated household children: \(children.count) profiles")
    }

    /// Reload household children from Supabase (public method)
    func reloadHouseholdChildren() {
        loadHouseholdChildren()
    }

    // MARK: - Data Validation

    /// Check if a child belongs to the current household
    func isChildInHousehold(_ childId: UUID) -> Bool {
        // If we're currently in child mode and this is the current child, allow it
        if let currentChild = currentChildId, currentChild == childId {
            return true
        }

        // Otherwise check the household children list
        return householdChildren.contains { $0.id == childId }
    }

    /// Set current child ID when switching to child mode
    func setCurrentChild(_ childId: UUID) {
        currentChildId = childId
        storage.save(childId.uuidString, forKey: childIdKey)
        print("👶 Set current child ID: \(childId)")
    }

    /// Clear current child ID when switching to parent mode
    func clearCurrentChild() {
        currentChildId = nil
        storage.remove(forKey: childIdKey)
        print("🧹 Cleared current child ID")
    }

    /// Get child profile by ID (only if in current household)
    func getChildProfile(_ childId: UUID) -> UserProfile? {
        return householdChildren.first { $0.id == childId }
    }

    /// Check if current user is a parent
    func isParent() -> Bool {
        return currentParentId != nil
    }

    /// Validate that a task belongs to current household
    func validateTask(childId: UUID) -> Bool {
        guard let _ = currentHouseholdId else {
            print("⚠️ No household context - cannot validate task")
            return false
        }

        let isValid = isChildInHousehold(childId)
        if !isValid {
            print("❌ Task validation failed: child \(childId) not in household")
        }
        return isValid
    }

    // MARK: - Private Helpers

    private func loadHouseholdChildren() {
        // Load children from Supabase via HouseholdService ONLY
        // DO NOT fall back to local storage - that causes data leakage between users!
        Task {
            do {
                let householdService = HouseholdService.shared
                let childProfiles = try await householdService.getMyChildren()

                // Convert Profile to UserProfile
                let children = childProfiles.map { profile in
                    UserProfile(
                        id: UUID(uuidString: profile.id) ?? UUID(),
                        name: profile.fullName ?? "Child",
                        mode: .child1, // Mode doesn't matter for data isolation, only ID matters
                        age: profile.age,
                        parentId: currentParentId,
                        profilePhotoFileName: nil // TODO: Map from avatar_url if needed
                    )
                }

                await MainActor.run {
                    householdChildren = children
                    print("📦 Loaded \(children.count) children from Supabase for household")
                    for child in children {
                        print("  - \(child.name) (ID: \(child.id))")
                    }
                }
            } catch {
                print("❌ Failed to load household children from Supabase: \(error)")

                // DO NOT fall back to DeviceModeManager!
                // Old fallback caused data leakage - users saw other users' children
                // If database fails, show empty list (user can retry)
                await MainActor.run {
                    householdChildren = []
                    print("⚠️ Set children to empty due to database error - user can retry")
                }
            }
        }
    }
}

// MARK: - Household Filtering Extensions

extension HouseholdContext {
    /// Get all child IDs in current household
    var householdChildIds: [UUID] {
        return householdChildren.map { $0.id }
    }

    /// Filter tasks to only those belonging to current household
    func filterTasksForHousehold<T>(_ tasks: [T], getChildId: (T) -> UUID) -> [T] {
        guard let _ = currentHouseholdId else {
            print("⚠️ No household context - returning empty array")
            return []
        }

        return tasks.filter { task in
            let childId = getChildId(task)
            return isChildInHousehold(childId)
        }
    }

    /// Filter children profiles to only current household
    func filterChildrenForHousehold(_ profiles: [UserProfile]) -> [UserProfile] {
        guard let parentId = currentParentId else {
            print("⚠️ No parent context - returning empty array")
            return []
        }

        // Only return children that belong to this parent
        return profiles.filter { $0.parentId == parentId && $0.mode.isChildMode }
    }
}

// MARK: - Debug Utilities

extension HouseholdContext {
    /// Print current household context for debugging
    func printContext() {
        print("\n" + String(repeating: "=", count: 50))
        print("📊 Household Context Debug Info")
        print(String(repeating: "=", count: 50))
        print("Household ID: \(currentHouseholdId?.uuidString ?? "none")")
        print("Parent ID: \(currentParentId?.uuidString ?? "none")")
        print("Children Count: \(householdChildren.count)")

        if !householdChildren.isEmpty {
            print("\nChildren in Household:")
            for child in householdChildren {
                print("  - \(child.name) (ID: \(child.id))")
            }
        }

        print(String(repeating: "=", count: 50) + "\n")
    }

    /// Validate household data integrity
    func validateDataIntegrity() -> Bool {
        guard let householdId = currentHouseholdId else {
            print("⚠️ No household ID set")
            return false
        }

        if isParent() {
            guard let parentId = currentParentId else {
                print("⚠️ Parent mode but no parent ID")
                return false
            }

            // Check that all children have matching parent ID
            let invalidChildren = householdChildren.filter { $0.parentId != parentId }
            if !invalidChildren.isEmpty {
                print("❌ Found children with mismatched parent IDs:")
                for child in invalidChildren {
                    print("  - \(child.name): parentId=\(child.parentId?.uuidString ?? "none")")
                }
                return false
            }
        }

        print("✅ Household data integrity check passed")
        return true
    }
}
