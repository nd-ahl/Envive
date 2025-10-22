import SwiftUI

// MARK: - Manage Family View

/// Parent settings view for managing household and adding children
struct ManageFamilyView: View {
    @StateObject private var householdService = HouseholdService.shared
    @StateObject private var authService = AuthenticationService.shared
    @ObservedObject private var householdContext = HouseholdContext.shared

    @State private var children: [HouseholdChildInfo] = []
    @State private var showingAddChildSheet = false
    @State private var editingChild: HouseholdChildInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingDeleteConfirmation = false
    @State private var childToDelete: HouseholdChildInfo?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                headerSection

                // Children List
                if isLoading {
                    loadingView
                } else if children.isEmpty {
                    emptyStateView
                } else {
                    childrenListSection
                }

                // Add Child Button
                addChildButton
            }
            .padding()
        }
        .navigationTitle("Manage Family")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadChildren()
        }
        .refreshable {
            loadChildren()
        }
        .sheet(isPresented: $showingAddChildSheet) {
            AddChildProfileSheet(
                profile: editingChild?.toChildProfileData(),
                onSave: { childData in
                    Task {
                        await saveChild(childData)
                    }
                },
                onCancel: {
                    editingChild = nil
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .confirmationDialog(
            "Delete Child Profile",
            isPresented: $showingDeleteConfirmation,
            presenting: childToDelete
        ) { child in
            Button("Delete", role: .destructive) {
                Task {
                    await deleteChild(child)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { child in
            Text("Are you sure you want to remove \(child.name) from your household? This action cannot be undone.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Household")
                        .font(.title3)
                        .fontWeight(.bold)

                    if let parentProfile = authService.currentProfile {
                        Text(parentProfile.fullName ?? "Parent")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Household member count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(children.count + 1)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading children...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Children Added")
                .font(.title3)
                .fontWeight(.bold)

            Text("Add children to your household so they can create accounts and earn screen time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Children List

    private var childrenListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Children (\(children.count))")
                .font(.headline)

            ForEach(children) { child in
                ChildManagementCard(
                    child: child,
                    onEdit: {
                        editingChild = child
                        showingAddChildSheet = true
                    },
                    onDelete: {
                        childToDelete = child
                        showingDeleteConfirmation = true
                    }
                )
            }
        }
    }

    // MARK: - Add Child Button

    private var addChildButton: some View {
        Button(action: {
            editingChild = nil
            showingAddChildSheet = true
        }) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                Text("Add Child")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Data Loading

    private func loadChildren() {
        isLoading = true

        Task {
            do {
                let childProfiles = try await householdService.getMyChildren()

                await MainActor.run {
                    children = childProfiles.map { profile in
                        HouseholdChildInfo(
                            id: UUID(uuidString: profile.id) ?? UUID(),
                            name: profile.fullName ?? "Child",
                            age: profile.age,
                            profilePhotoFileName: nil // TODO: Map from avatar_url if available
                        )
                    }
                    isLoading = false

                    print("✅ Loaded \(children.count) children from household")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load children: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false

                    print("❌ Error loading children: \(error)")
                }
            }
        }
    }

    // MARK: - Save Child

    private func saveChild(_ childData: ChildProfileData) async {
        guard let currentProfile = authService.currentProfile,
              let householdId = currentProfile.householdId else {
            await MainActor.run {
                errorMessage = "No household found. Please complete onboarding first."
                showingError = true
            }
            return
        }

        await MainActor.run {
            isLoading = true
        }

        do {
            // Upload avatar if provided
            var avatarUrl: String? = nil
            if let avatarImage = childData.avatarImage,
               let imageData = avatarImage.jpegData(compressionQuality: 0.8) {
                let tempChildId = UUID().uuidString
                avatarUrl = try await householdService.uploadProfilePicture(
                    userId: tempChildId,
                    imageData: imageData
                )
                print("✅ Uploaded child avatar")
            }

            // Create child profile in Supabase
            let childId = try await householdService.createChildProfile(
                name: childData.name,
                age: childData.age,
                householdId: householdId,
                createdBy: currentProfile.id,
                avatarUrl: avatarUrl
            )

            print("✅ Child profile created: \(childData.name), age \(childData.age) (ID: \(childId))")

            // Reload children list
            await MainActor.run {
                editingChild = nil
                showingAddChildSheet = false
            }

            loadChildren()

        } catch {
            await MainActor.run {
                errorMessage = "Failed to create child profile: \(error.localizedDescription)"
                showingError = true
                isLoading = false

                print("❌ Error creating child profile: \(error)")
            }
        }
    }

    // MARK: - Delete Child

    private func deleteChild(_ child: HouseholdChildInfo) async {
        await MainActor.run {
            isLoading = true
        }

        do {
            // TODO: Implement deleteChildProfile in HouseholdService
            // For now, just show a message
            await MainActor.run {
                errorMessage = "Delete functionality is not yet implemented. Child profiles can be managed through Supabase dashboard."
                showingError = true
                isLoading = false
            }

            print("⚠️ Delete child not implemented yet: \(child.name)")

        } catch {
            await MainActor.run {
                errorMessage = "Failed to delete child: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }
}

// MARK: - Household Child Info Model

struct HouseholdChildInfo: Identifiable {
    let id: UUID
    let name: String
    let age: Int?
    let profilePhotoFileName: String?

    func toChildProfileData() -> ChildProfileData {
        ChildProfileData(
            id: id,
            name: name,
            age: age ?? 8,
            avatarImage: nil
        )
    }
}

// MARK: - Child Management Card

struct ChildManagementCard: View {
    let child: HouseholdChildInfo
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingOptions = false

    var body: some View {
        HStack(spacing: 12) {
            // Profile Photo or Initial
            if let photoFileName = child.profilePhotoFileName,
               let image = ProfilePhotoManager.shared.loadProfilePhoto(fileName: photoFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
            }

            // Child Info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)

                if let age = child.age {
                    Text("\(age) years old")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Options Button
            Button(action: {
                showingOptions = true
            }) {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .confirmationDialog("Manage \(child.name)", isPresented: $showingOptions) {
            Button("Edit Profile") {
                onEdit()
            }

            Button("Delete", role: .destructive) {
                onDelete()
            }

            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Preview

struct ManageFamilyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ManageFamilyView()
        }
    }
}
