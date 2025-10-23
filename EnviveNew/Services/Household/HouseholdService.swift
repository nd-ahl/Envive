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

    /// Get household by invite code
    func getHouseholdByInviteCode(_ code: String) async throws -> Household {
        let household: Household = try await supabase
            .from("households")
            .select()
            .eq("invite_code", value: code)
            .single()
            .execute()
            .value

        return household
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

        // NOTE: We do NOT add child profiles to household_members table
        // because children don't have auth.users entries (they sign in with name/age, not email/password).
        // The household_members table has a foreign key constraint on user_id -> auth.users(id),
        // which would fail for child profiles that only exist in the profiles table.
        // Instead, the household relationship is tracked via profiles.household_id.
        print("ℹ️  Child linked to household via profiles.household_id (skipping household_members)")

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
        var profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("household_id", value: household.id)
            .order("role", ascending: false) // Parents first, then children
            .execute()
            .value

        print("✅ Found \(profiles.count) profile(s) directly:")
        for profile in profiles {
            print("  - Name: \(profile.fullName ?? "Unknown"), Role: \(profile.role), ID: \(profile.id), HouseholdID: \(profile.householdId ?? "nil")")
        }

        // FALLBACK: If no profiles found via household_id, check household_members table
        // This handles cases where profiles haven't been updated with household_id yet
        if profiles.isEmpty {
            print("⚠️ No profiles found via household_id, checking household_members table...")

            // Get member IDs from household_members
            let members: [HouseholdMember] = try await supabase
                .from("household_members")
                .select()
                .eq("household_id", value: household.id)
                .execute()
                .value

            print("📋 Found \(members.count) household member(s) in household_members table")

            // Get profiles for each member
            for member in members {
                do {
                    let profile: Profile = try await supabase
                        .from("profiles")
                        .select()
                        .eq("id", value: member.userId)
                        .single()
                        .execute()
                        .value

                    profiles.append(profile)
                    print("  ✓ Loaded profile: \(profile.fullName ?? "Unknown"), Role: \(profile.role)")

                    // FIX: Update profile with household_id if missing
                    if profile.householdId == nil || profile.householdId != household.id {
                        print("  🔧 Fixing profile household_id for: \(profile.fullName ?? "Unknown")")
                        try await updateUserHousehold(userId: profile.id, householdId: household.id)
                    }
                } catch {
                    print("  ❌ Failed to load profile for member: \(member.userId)")
                }
            }

            // Sort profiles: parents first, then children
            profiles.sort { ($0.role == "parent" && $1.role != "parent") }
        }

        print("✅ Total profiles returned: \(profiles.count)")
        return profiles
    }

    /// Fix profiles that are missing household_id by checking household_members
    func fixProfileHouseholdIds() async throws {
        print("🔧 Starting profile household_id fix...")

        // Get all household members
        let allMembers: [HouseholdMember] = try await supabase
            .from("household_members")
            .select()
            .execute()
            .value

        print("📋 Found \(allMembers.count) total household members")

        var fixedCount = 0
        for member in allMembers {
            // Get profile
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: member.userId)
                .single()
                .execute()
                .value

            // Check if household_id is missing or incorrect
            if profile.householdId == nil || profile.householdId != member.householdId {
                print("  🔧 Fixing: \(profile.fullName ?? "Unknown") - setting household_id to \(member.householdId)")
                try await updateUserHousehold(userId: profile.id, householdId: member.householdId)
                fixedCount += 1
            }
        }

        print("✅ Fixed \(fixedCount) profile(s)")
    }

    // MARK: - Fetch Children for Current User

    /// Get children for the current logged-in user's household
    /// UPDATED: Works for both parents AND children
    /// - Parents: Returns all children in their household
    /// - Children: Returns siblings (other children in the same household)
    /// This is used by ParentDashboardView and ModeSwitcherView
    func getMyChildren() async throws -> [Profile] {
        // Get current user's profile from AuthenticationService
        guard let currentProfile = AuthenticationService.shared.currentProfile else {
            throw NSError(domain: "HouseholdService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No authenticated user"
            ])
        }

        guard let householdId = currentProfile.householdId else {
            print("⚠️ Current user has no household_id - returning empty children list")
            return [] // Not in a household yet
        }

        // CRITICAL FIX: Allow both parents AND children to fetch household children
        // This enables the mode switcher to work correctly when logged in as a child
        print("🔍 Fetching children for household: \(householdId) (user role: \(currentProfile.role))")

        // Fetch all children in the household (including siblings if user is a child)
        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("household_id", value: householdId)
            .eq("role", value: "child")
            .order("full_name", ascending: true)
            .execute()
            .value

        print("✅ Found \(profiles.count) child profile(s) in household \(householdId)")
        for profile in profiles {
            print("   - \(profile.fullName ?? "Unknown"), Age: \(profile.age ?? 0), ID: \(profile.id)")
        }

        return profiles
    }

    /// Get child profiles in a household by invite code (for child login flow)
    func getChildrenByInviteCode(_ inviteCode: String) async throws -> [Profile] {
        print("🔍 Fetching household by invite code: \(inviteCode)")

        // First, find the household by invite code
        let household: Household = try await supabase
            .from("households")
            .select()
            .eq("invite_code", value: inviteCode)
            .single()
            .execute()
            .value

        print("✅ Found household: \(household.name), ID: \(household.id)")

        // Fetch all child profiles in that household
        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("household_id", value: household.id)
            .eq("role", value: "child")
            .order("full_name", ascending: true)
            .execute()
            .value

        print("✅ Found \(profiles.count) child profile(s) in household")
        for profile in profiles {
            print("   - \(profile.fullName ?? "Unknown"), Age: \(profile.age ?? 0), ID: \(profile.id)")
        }

        return profiles
    }
}
