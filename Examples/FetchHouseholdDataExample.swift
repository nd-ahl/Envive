import Foundation
import SwiftUI
import Supabase

// MARK: - Example: Fetch Household Data After Sign In
// This example shows how to fetch household and children data after a parent signs in

// ============================================
// EXAMPLE 1: Basic Sign In and Fetch Flow
// ============================================

class ParentDashboardViewModel: ObservableObject {
    @Published var currentProfile: Profile?
    @Published var household: Household?
    @Published var children: [Profile] = []
    @Published var allMembers: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthenticationService.shared
    private let householdService = HouseholdService.shared

    /// Complete sign-in flow that fetches all household data
    func signInAndFetchHouseholdData(email: String, password: String) async {
        await MainActor.run { isLoading = true }

        do {
            // Step 1: Sign in the user
            let profile = try await authService.signIn(email: email, password: password)

            await MainActor.run {
                self.currentProfile = profile
            }

            print("✅ Signed in as: \(profile.fullName ?? profile.email ?? "User")")
            print("   Role: \(profile.role)")
            print("   Household ID: \(profile.householdId ?? "None")")

            // Step 2: Check if user is in a household
            guard let householdId = profile.householdId else {
                print("⚠️ User not in a household yet")
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }

            // Step 3: Fetch household details
            let household = try await householdService.getUserHousehold(userId: profile.id)

            await MainActor.run {
                self.household = household
            }

            print("✅ Loaded household: \(household?.name ?? "Unknown")")
            print("   Invite Code: \(household?.inviteCode ?? "N/A")")

            // Step 4: Fetch all household members
            let members = try await householdService.getHouseholdMembers(householdId: householdId)

            // Step 5: Filter children from members
            let children = members.filter { $0.role == "child" }

            await MainActor.run {
                self.allMembers = members
                self.children = children
                self.isLoading = false
            }

            print("✅ Loaded \(members.count) household members")
            print("   Parents: \(members.filter { $0.role == "parent" }.count)")
            print("   Children: \(children.count)")

            // Print children details
            for (index, child) in children.enumerated() {
                print("   Child \(index + 1): \(child.fullName ?? "Unknown"), Age: \(child.age ?? 0)")
            }

        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Error during sign-in: \(error.localizedDescription)")
        }
    }

    /// Check if current user is a parent
    var isParent: Bool {
        currentProfile?.role == "parent"
    }

    /// Get children available for task assignment
    var childrenForTaskAssignment: [Profile] {
        // Only parents can assign tasks to children
        guard isParent else { return [] }
        return children
    }
}


// ============================================
// EXAMPLE 2: Using in a SwiftUI View
// ============================================

struct ParentDashboardView: View {
    @StateObject private var viewModel = ParentDashboardViewModel()
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.currentProfile == nil {
                    // Sign In Form
                    signInForm
                } else {
                    // Dashboard showing household data
                    householdDashboard
                }
            }
            .navigationTitle("Parent Dashboard")
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                }
            }
        }
    }

    private var signInForm: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button("Sign In") {
                Task {
                    await viewModel.signInAndFetchHouseholdData(
                        email: email,
                        password: password
                    )
                }
            }
            .buttonStyle(.borderedProminent)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

    private var householdDashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // User Info
                userInfoSection

                // Household Info
                householdInfoSection

                // Children List
                childrenSection

                // Task Assignment Example
                if viewModel.isParent {
                    taskAssignmentSection
                }
            }
            .padding()
        }
    }

    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signed in as")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(viewModel.currentProfile?.fullName ?? "User")
                .font(.title2)
                .bold()

            Text(viewModel.currentProfile?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Label(viewModel.currentProfile?.role.capitalized ?? "", systemImage: "person.circle")
                .font(.caption)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private var householdInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Household")
                .font(.headline)

            if let household = viewModel.household {
                VStack(alignment: .leading, spacing: 4) {
                    Text(household.name)
                        .font(.title3)
                        .bold()

                    HStack {
                        Text("Invite Code:")
                        Text(household.inviteCode)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .font(.caption)

                    Text("\(viewModel.allMembers.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Not in a household")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Children (\(viewModel.children.count))")
                .font(.headline)

            if viewModel.children.isEmpty {
                Text("No children in this household yet")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(viewModel.children) { child in
                    ChildRow(child: child)
                }
            }
        }
    }

    private var taskAssignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assign Task")
                .font(.headline)

            Text("Select a child to assign a task:")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(viewModel.childrenForTaskAssignment) { child in
                Button {
                    // Navigate to task creation for this child
                    print("Assign task to: \(child.fullName ?? "Child")")
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text(child.fullName ?? "Unknown")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct ChildRow: View {
    let child: Profile

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarUrl = child.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(child.fullName?.prefix(1) ?? "?")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
            }

            // Child Info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.fullName ?? "Unknown")
                    .font(.headline)

                if let age = child.age {
                    Text("Age \(age)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}


// ============================================
// EXAMPLE 3: Fetch Only Children (Optimized)
// ============================================

extension HouseholdService {
    /// Fetch only children in the household (more efficient than fetching all members)
    func getChildrenInHousehold(householdId: String) async throws -> [Profile] {
        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("household_id", value: householdId)
            .eq("role", value: "child")
            .order("full_name", ascending: true)
            .execute()
            .value

        return profiles
    }

    /// Get children for the current logged-in parent
    func getMyChildren() async throws -> [Profile] {
        // Get current user's profile
        guard let currentUserId = await SupabaseService.shared.currentUserId else {
            throw NSError(domain: "HouseholdService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No authenticated user"
            ])
        }

        // Get user's household
        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: currentUserId)
            .single()
            .execute()
            .value

        guard let householdId = profile.householdId else {
            return [] // Not in a household
        }

        // Verify user is a parent
        guard profile.role == "parent" else {
            throw NSError(domain: "HouseholdService", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Only parents can view children"
            ])
        }

        // Fetch children
        return try await getChildrenInHousehold(householdId: householdId)
    }
}


// ============================================
// EXAMPLE 4: Task Assignment with Household Context
// ============================================

struct TaskCreationViewModel: ObservableObject {
    @Published var availableChildren: [Profile] = []
    @Published var selectedChild: Profile?
    @Published var isLoading = false

    private let householdService = HouseholdService.shared

    /// Load children when parent creates a task
    func loadAvailableChildren() async {
        await MainActor.run { isLoading = true }

        do {
            // Fetch only the current parent's children
            let children = try await householdService.getMyChildren()

            await MainActor.run {
                self.availableChildren = children
                self.isLoading = false
            }

            print("✅ Loaded \(children.count) children for task assignment")

        } catch {
            print("❌ Error loading children: \(error.localizedDescription)")
            await MainActor.run {
                self.availableChildren = []
                self.isLoading = false
            }
        }
    }

    /// Create a task for the selected child
    func createTask(title: String, description: String, xpReward: Int) async throws {
        guard let child = selectedChild else {
            throw NSError(domain: "TaskCreation", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No child selected"
            ])
        }

        // Verify child is in current household (security check)
        guard HouseholdContext.shared.isChildInHousehold(UUID(uuidString: child.id)!) else {
            throw NSError(domain: "TaskCreation", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Child is not in your household"
            ])
        }

        // Create task logic here...
        print("✅ Creating task for child: \(child.fullName ?? "Unknown")")
        print("   Title: \(title)")
        print("   XP Reward: \(xpReward)")
    }
}


// ============================================
// EXAMPLE 5: Complete Sign-In to Task Assignment Flow
// ============================================

class AppCoordinator: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentProfile: Profile?
    @Published var household: Household?
    @Published var children: [Profile] = []

    private let authService = AuthenticationService.shared
    private let householdService = HouseholdService.shared

    /// Called when app launches or user signs in
    func handleAuthentication() async {
        do {
            // Check if already authenticated
            await authService.checkAuthStatus()

            guard authService.isAuthenticated,
                  let profile = authService.currentProfile else {
                await MainActor.run {
                    self.isAuthenticated = false
                }
                return
            }

            // Load household data
            await loadHouseholdData(for: profile)

            await MainActor.run {
                self.isAuthenticated = true
                self.currentProfile = profile
            }

        } catch {
            print("❌ Authentication error: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthenticated = false
            }
        }
    }

    /// Load all household-related data
    private func loadHouseholdData(for profile: Profile) async {
        guard let householdId = profile.householdId else {
            print("⚠️ User not in a household")
            return
        }

        do {
            // Fetch household
            if let household = try await householdService.getUserHousehold(userId: profile.id) {
                await MainActor.run {
                    self.household = household
                }
            }

            // Fetch children (if parent)
            if profile.role == "parent" {
                let children = try await householdService.getChildrenInHousehold(householdId: householdId)
                await MainActor.run {
                    self.children = children
                }

                print("✅ Loaded \(children.count) children for parent")
            }

        } catch {
            print("❌ Error loading household data: \(error.localizedDescription)")
        }
    }

    /// Sign in and load all data
    func signIn(email: String, password: String) async throws {
        let profile = try await authService.signIn(email: email, password: password)
        await loadHouseholdData(for: profile)

        await MainActor.run {
            self.isAuthenticated = true
            self.currentProfile = profile
        }
    }
}


// ============================================
// EXAMPLE 6: Using HouseholdContext for Data Isolation
// ============================================

class SecureTaskService {
    private let supabase = SupabaseService.shared.client

    /// Fetch tasks for children in current household ONLY
    func getTasksForMyHousehold() async throws -> [Task] {
        // Get current household context
        guard let householdId = HouseholdContext.shared.currentHouseholdId else {
            throw NSError(domain: "TaskService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No household context"
            ])
        }

        // Get child IDs in current household
        let childIds = HouseholdContext.shared.householdChildIds

        guard !childIds.isEmpty else {
            return [] // No children in household
        }

        // Fetch tasks only for children in this household
        // This ensures parents only see tasks for their own children
        let childIdStrings = childIds.map { $0.uuidString }

        // Note: Supabase query - only returns tasks for children in current household
        // RLS policies on the database also enforce this at the database level
        print("🔒 Fetching tasks for household: \(householdId)")
        print("   Children: \(childIdStrings)")

        // Your actual task fetching logic here...
        // The key is that you filter by child IDs from HouseholdContext

        return []
    }
}

// ============================================
// USAGE SUMMARY
// ============================================

/*

 STEP 1: User Signs In
 ----------------------
 let profile = try await AuthenticationService.shared.signIn(email: email, password: password)

 // At this point:
 // - User is authenticated
 // - Profile is loaded with household_id
 // - HouseholdContext is set automatically


 STEP 2: Fetch Household
 ------------------------
 let household = try await HouseholdService.shared.getUserHousehold(userId: profile.id)

 // Returns the household the user belongs to
 // Contains: id, name, invite_code, created_by


 STEP 3: Fetch Children
 ----------------------
 // Option A: Fetch all members, then filter
 let members = try await HouseholdService.shared.getHouseholdMembers(householdId: household.id)
 let children = members.filter { $0.role == "child" }

 // Option B: Fetch only children (more efficient)
 let children = try await HouseholdService.shared.getChildrenInHousehold(householdId: household.id)

 // Option C: Get current parent's children (simplest)
 let children = try await HouseholdService.shared.getMyChildren()


 STEP 4: Assign Tasks to Children
 ---------------------------------
 for child in children {
     // Create task assigned to child.id
     // Parent can only assign to children in their household
     // HouseholdContext.shared.isChildInHousehold(childId) verifies this
 }


 SECURITY NOTES
 --------------
 ✅ RLS policies ensure parents only see their household's children
 ✅ HouseholdContext provides additional client-side validation
 ✅ All queries are scoped to current household
 ✅ Cross-household data access is prevented at database level

 */
