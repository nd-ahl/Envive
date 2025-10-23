import SwiftUI
import PhotosUI

// MARK: - Add Profiles View

/// Onboarding screen for adding child profiles to the household
struct AddProfilesView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onBack: () -> Void

    @StateObject private var householdService = HouseholdService.shared
    @StateObject private var authService = AuthenticationService.shared
    @State private var childProfiles: [ChildProfileData] = []
    @State private var existingChildIds: Set<String> = [] // Track which profiles already exist in DB
    @State private var showingAddProfileSheet = false
    @State private var editingProfile: ChildProfileData?
    @State private var showContent = false
    @State private var isLoadingExistingChildren = false

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    Spacer()
                }

                // Header
                headerSection
                    .padding(.top, 20)

                Spacer()

                // Profiles list or empty state
                if childProfiles.isEmpty {
                    emptyStateSection
                } else {
                    profilesListSection
                }

                Spacer()

                // Add Profile Button
                addProfileButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)

                // Action buttons
                actionButtons
                    .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showingAddProfileSheet) {
            AddChildProfileSheet(
                profile: editingProfile,
                onSave: { profile in
                    if let index = childProfiles.firstIndex(where: { $0.id == profile.id }) {
                        childProfiles[index] = profile
                    } else {
                        childProfiles.append(profile)
                    }
                    editingProfile = nil
                },
                onCancel: {
                    editingProfile = nil
                }
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            loadExistingChildren()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Add Your Family")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Create profiles for everyone who will be doing tasks")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Empty State Section

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))

            Text("No profiles yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            Text("Tap the button below to add a child profile")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Profiles List Section

    private var profilesListSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(childProfiles) { profile in
                    ChildProfileCard(profile: profile) {
                        // Only allow editing new profiles, not existing ones
                        if profile.databaseId == nil {
                            editingProfile = profile
                            showingAddProfileSheet = true
                        }
                    } onDelete: {
                        // Only allow deleting new profiles, not existing ones
                        if profile.databaseId == nil,
                           let index = childProfiles.firstIndex(where: { $0.id == profile.id }) {
                            withAnimation {
                                childProfiles.remove(at: index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxHeight: 300)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Add Profile Button

    private var addProfileButton: some View {
        Button(action: {
            editingProfile = nil
            showingAddProfileSheet = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add Profile")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(Color.purple.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Skip button
            Button(action: onSkip) {
                Text("Skip for Now")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .underline()
            }

            Spacer()

            // Continue button
            Button(action: handleContinue) {
                HStack(spacing: 10) {
                    Text(childProfiles.isEmpty ? "Continue" : "Save & Continue")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color.blue.opacity(0.9))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 32)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Actions

    private func loadExistingChildren() {
        isLoadingExistingChildren = true
        Task {
            do {
                let existingChildren = try await householdService.getMyChildren()

                await MainActor.run {
                    // Convert Profile objects to ChildProfileData
                    let existingProfileData = existingChildren.map { profile in
                        ChildProfileData(
                            name: profile.fullName ?? "Unknown",
                            age: profile.age ?? 0,
                            avatarImage: nil, // We'll load this from URL if needed
                            databaseId: profile.id, // Mark as existing
                            avatarUrl: profile.avatarUrl
                        )
                    }

                    // Add existing profiles to the list
                    childProfiles = existingProfileData
                    existingChildIds = Set(existingChildren.map { $0.id })

                    print("✅ Loaded \(existingChildren.count) existing child profile(s)")
                    isLoadingExistingChildren = false
                }
            } catch {
                await MainActor.run {
                    print("⚠️ Could not load existing children: \(error.localizedDescription)")
                    // This is OK - might be first time setup with no children yet
                    isLoadingExistingChildren = false
                }
            }
        }
    }

    private func handleContinue() {
        // Save only NEW child profiles to the database (skip existing ones)
        Task {
            guard let currentProfile = authService.currentProfile else {
                print("❌ No current profile found")
                return
            }

            guard let householdId = currentProfile.householdId else {
                print("❌ No household found for user \(currentProfile.id)")
                print("❌ Profile: \(currentProfile)")
                return
            }

            // Filter out profiles that already exist in the database
            let newProfiles = childProfiles.filter { $0.databaseId == nil }

            print("✅ Creating \(newProfiles.count) NEW child profile(s) in household: \(householdId)")
            print("ℹ️  Skipping \(childProfiles.count - newProfiles.count) existing profile(s)")

            for childData in newProfiles {
                do {
                    try await createChildProfile(childData, in: householdId, createdBy: currentProfile.id)
                } catch {
                    print("❌ Failed to create profile for \(childData.name): \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                onContinue()
            }
        }
    }

    private func createChildProfile(_ childData: ChildProfileData, in householdId: String, createdBy: String) async throws {
        var avatarUrl: String? = nil

        // Upload avatar if provided
        if let avatarImage = childData.avatarImage,
           let imageData = avatarImage.jpegData(compressionQuality: 0.8) {
            do {
                let tempChildId = UUID().uuidString
                avatarUrl = try await householdService.uploadProfilePicture(
                    userId: tempChildId,
                    imageData: imageData
                )
            } catch {
                print("⚠️ Failed to upload avatar: \(error.localizedDescription)")
                // Continue without avatar
            }
        }

        // Create child profile
        let childId = try await householdService.createChildProfile(
            name: childData.name,
            age: childData.age,
            householdId: householdId,
            createdBy: createdBy,
            avatarUrl: avatarUrl
        )

        print("✅ Child profile created: \(childData.name), age \(childData.age) (ID: \(childId))")
    }
}

// MARK: - Child Profile Card

private struct ChildProfileCard: View {
    let profile: ChildProfileData
    let onEdit: () -> Void
    let onDelete: () -> Void

    var isExisting: Bool {
        profile.databaseId != nil
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let avatarImage = profile.avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(profile.name.prefix(1).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )
                }

                // Show checkmark badge for existing profiles
                if isExisting {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    if isExisting {
                        Text("(Existing)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text("\(profile.age) years old")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // Actions - disable delete for existing profiles
            HStack(spacing: 12) {
                if !isExisting {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
        .padding(16)
        .background(isExisting ? Color.green.opacity(0.15) : Color.white.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isExisting ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Child Profile Data

struct ChildProfileData: Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var avatarImage: UIImage?
    var databaseId: String? // If set, this profile already exists in the database
    var avatarUrl: String? // URL of existing avatar

    init(id: UUID = UUID(), name: String = "", age: Int = 10, avatarImage: UIImage? = nil, databaseId: String? = nil, avatarUrl: String? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarImage = avatarImage
        self.databaseId = databaseId
        self.avatarUrl = avatarUrl
    }
}

// MARK: - Preview

struct AddProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        AddProfilesView(
            onContinue: {},
            onSkip: {},
            onBack: {}
        )
    }
}
