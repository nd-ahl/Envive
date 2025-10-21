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
    @State private var showingAddProfileSheet = false
    @State private var editingProfile: ChildProfileData?
    @State private var showContent = false

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
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Text("👨‍👩‍👧‍👦")
                .font(.system(size: 70))
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
                        editingProfile = profile
                        showingAddProfileSheet = true
                    } onDelete: {
                        if let index = childProfiles.firstIndex(where: { $0.id == profile.id }) {
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

    private func handleContinue() {
        // Save all child profiles to the database
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

            print("✅ Creating \(childProfiles.count) child profile(s) in household: \(householdId)")

            for childData in childProfiles {
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

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
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

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(profile.age) years old")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
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
        .padding(16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Child Profile Data

struct ChildProfileData: Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var avatarImage: UIImage?

    init(id: UUID = UUID(), name: String = "", age: Int = 10, avatarImage: UIImage? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarImage = avatarImage
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
