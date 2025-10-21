import Foundation

// MARK: - Profile Model
/// Represents a user profile in the database
/// This extends the Supabase auth.users table
struct Profile: Codable, Identifiable {
    let id: String // UUID from auth.users
    let email: String?
    let fullName: String?
    let role: String // "parent" or "child"
    let householdId: String? // UUID of the household they belong to
    let avatarUrl: String? // URL to profile picture
    let age: Int? // User's age (for children)
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case householdId = "household_id"
        case avatarUrl = "avatar_url"
        case age
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Household Model
/// Represents a household that contains multiple users
struct Household: Codable, Identifiable {
    let id: String // UUID
    let name: String
    let inviteCode: String // 6-digit code for joining
    let createdBy: String // UUID of the parent who created it
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Household Member Model
/// Represents the relationship between users and households
struct HouseholdMember: Codable {
    let householdId: String
    let userId: String
    let role: String // "parent" or "child"
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case householdId = "household_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}
