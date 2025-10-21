import Foundation
import Supabase
import Combine

/// Service that handles household management operations
class HouseholdService: ObservableObject {
    static let shared = HouseholdService()

    @Published var currentHousehold: Household?
    @Published var householdMembers: [Profile] = []

    private let supabase = SupabaseService.shared.client

    private init() {}

    // MARK: - Create Household

    /// Create a new household with a unique invite code
    func createHousehold(name: String, createdBy: String) async throws -> Household {
        // Generate unique 6-digit invite code
        let inviteCode = generateInviteCode()

        let household = Household(
            id: UUID().uuidString,
            name: name,
            inviteCode: inviteCode,
            createdBy: createdBy,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Insert household into database
        try await supabase
            .from("households")
            .insert(household)
            .execute()

        // Add creator as first member
        try await addMemberToHousehold(
            householdId: household.id,
            userId: createdBy,
            role: "parent"
        )

        // Update user's profile with household_id
        try await updateUserHousehold(userId: createdBy, householdId: household.id)

        await MainActor.run {
            self.currentHousehold = household
        }

        return household
    }

    // MARK: - Join Household

    /// Join an existing household using an invite code
    func joinHousehold(inviteCode: String, userId: String, role: String) async throws -> Household {
        // Find household by invite code
        let household: Household = try await supabase
            .from("households")
            .select()
            .eq("invite_code", value: inviteCode)
            .single()
            .execute()
            .value

        // Add user as member
        try await addMemberToHousehold(
            householdId: household.id,
            userId: userId,
            role: role
        )

        // Update user's profile with household_id
        try await updateUserHousehold(userId: userId, householdId: household.id)

        await MainActor.run {
            self.currentHousehold = household
        }

        return household
    }

    // MARK: - Household Members

    /// Add a member to a household
    private func addMemberToHousehold(householdId: String, userId: String, role: String) async throws {
        let member = HouseholdMember(
            householdId: householdId,
            userId: userId,
            role: role,
            joinedAt: Date()
        )

        try await supabase
            .from("household_members")
            .insert(member)
            .execute()
    }

    /// Get all members of a household
    func getHouseholdMembers(householdId: String) async throws -> [Profile] {
        let members: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("household_id", value: householdId)
            .execute()
            .value

        await MainActor.run {
            self.householdMembers = members
        }

        return members
    }

    /// Get household for a user
    func getUserHousehold(userId: String) async throws -> Household? {
        // First get user's profile to find household_id
        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        guard let householdId = profile.householdId else {
            return nil
        }

        // Get household
        let household: Household = try await supabase
            .from("households")
            .select()
            .eq("id", value: householdId)
            .single()
            .execute()
            .value

        await MainActor.run {
            self.currentHousehold = household
        }

        return household
    }

    // MARK: - Helper Methods

    /// Update user's profile with household_id
    private func updateUserHousehold(userId: String, householdId: String) async throws {
        try await supabase
            .from("profiles")
            .update(["household_id": householdId])
            .eq("id", value: userId)
            .execute()
    }

    /// Generate a unique 6-digit invite code
    private func generateInviteCode() -> String {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        return code
    }

    /// Verify if an invite code is valid
    func verifyInviteCode(_ code: String) async throws -> Bool {
        do {
            let _: Household = try await supabase
                .from("households")
                .select()
                .eq("invite_code", value: code)
                .single()
                .execute()
                .value
            return true
        } catch {
            return false
        }
    }

    // MARK: - Leave Household

    /// Remove user from household
    func leaveHousehold(userId: String) async throws {
        // Remove household_id from profile
        let updateData: [String: String?] = ["household_id": nil]
        try await supabase
            .from("profiles")
            .update(updateData)
            .eq("id", value: userId)
            .execute()

        // Remove from household_members
        try await supabase
            .from("household_members")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        await MainActor.run {
            self.currentHousehold = nil
        }
    }

    // MARK: - Child Profile Management

    /// Create a child profile (not a full auth user, just a profile entry)
    func createChildProfile(
        name: String,
        age: Int,
        householdId: String,
        createdBy: String,
        avatarUrl: String? = nil
    ) async throws -> String {
        // Generate a unique ID for this child profile
        let childId = UUID().uuidString

        print("🔵 Creating child profile:")
        print("  - Name: \(name)")
        print("  - Age: \(age)")
        print("  - Household ID: \(householdId)")
        print("  - Child ID: \(childId)")

        // Create the profile entry with encodable struct
        struct ChildProfileInsert: Encodable {
            let id: String
            let full_name: String
            let role: String
            let household_id: String
            let age: Int
            let avatar_url: String?
        }

        let profileData = ChildProfileInsert(
            id: childId,
            full_name: name,
            role: "child",
            household_id: householdId,
            age: age,
            avatar_url: avatarUrl
        )

        try await supabase
            .from("profiles")
            .insert(profileData)
            .execute()

        print("✅ Child profile inserted into profiles table")

        // Add to household_members
        try await addMemberToHousehold(
            householdId: householdId,
            userId: childId,
            role: "child"
        )

        print("✅ Child added to household_members table")

        return childId
    }

    /// Upload profile picture to Supabase Storage
    func uploadProfilePicture(userId: String, imageData: Data) async throws -> String {
        let fileName = "\(userId)/avatar.jpg"
        let bucketName = "avatars"

        // Upload to Supabase Storage
        try await supabase.storage
            .from(bucketName)
            .upload(
                path: fileName,
                file: imageData,
                options: .init(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        // Get public URL
        let publicURL = try supabase.storage
            .from(bucketName)
            .getPublicURL(path: fileName)

        return publicURL.absoluteString
    }

    /// Get child profiles for a household by invite code
    func getChildProfilesByInviteCode(_ inviteCode: String) async throws -> [Profile] {
        print("🔍 Searching for household with invite code: \(inviteCode)")

        // Get household by invite code
        let household: Household = try await supabase
            .from("households")
            .select()
            .eq("invite_code", value: inviteCode)
            .single()
            .execute()
            .value

        print("✅ Found household: \(household.name) (ID: \(household.id))")
        print("🔍 Searching for child profiles in household: \(household.id)")

        // Get all child profiles in this household
        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("household_id", value: household.id)
            .eq("role", value: "child")
            .execute()
            .value

        print("✅ Found \(profiles.count) child profile(s):")
        for profile in profiles {
            print("  - Name: \(profile.fullName ?? "Unknown"), Age: \(profile.age ?? 0), ID: \(profile.id)")
        }

        return profiles
    }

    /// Get ALL profiles (both parent and child) for a household by invite code
    func getAllProfilesByInviteCode(_ inviteCode: String) async throws -> [Profile] {
        print("🔍 Searching for household with invite code: \(inviteCode)")

        // Get household by invite code
        let household: Household = try await supabase
            .from("households")
            .select()
            .eq("invite_code", value: inviteCode)
            .single()
            .execute()
            .value

        print("✅ Found household: \(household.name) (ID: \(household.id))")
        print("🔍 Searching for ALL profiles in household: \(household.id)")

        // Get ALL profiles in this household (both parent and child)
        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("household_id", value: household.id)
            .order("role", ascending: false) // Parents first, then children
            .execute()
            .value

        print("✅ Found \(profiles.count) profile(s):")
        for profile in profiles {
            print("  - Name: \(profile.fullName ?? "Unknown"), Role: \(profile.role), ID: \(profile.id)")
        }

        return profiles
    }
}
