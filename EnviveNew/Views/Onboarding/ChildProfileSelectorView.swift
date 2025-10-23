import SwiftUI

// MARK: - Child Profile Selector View

/// Screen where child selects which profile is theirs from household
struct ChildProfileSelectorView: View {
    let inviteCode: String
    let onProfileSelected: (Profile) -> Void
    let onBack: () -> Void

    @StateObject private var householdService = HouseholdService.shared
    @State private var allProfiles: [Profile] = []
    @State private var selectedProfile: Profile?
    @State private var isLoading = true
    @State private var showContent = false
    @State private var errorMessage: String?

    private var childProfiles: [Profile] {
        allProfiles.filter { $0.role == "child" }
    }

    private var parentProfiles: [Profile] {
        allProfiles.filter { $0.role == "parent" }
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading profiles...")
                    .foregroundColor(.white)
                    .tint(.white)
            } else {
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

                    Spacer()

                    // Content
                    VStack(spacing: 40) {
                        // Header
                        headerSection

                        // Profile cards
                        if childProfiles.isEmpty {
                            emptyStateSection
                        } else {
                            profileCardsSection
                        }

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // Continue button
                    continueButton
                        .padding(.horizontal, 32)
                        .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            loadChildProfiles()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Who are you?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("Select your profile from your siblings")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Profile Cards Section

    private var profileCardsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Parent profiles section (visible but disabled)
                if !parentProfiles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Parent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 4)

                        ForEach(parentProfiles) { profile in
                            ChildProfileSelectionCard(
                                profile: profile,
                                isSelected: false,
                                isDisabled: true
                            ) {
                                // Parent profiles are not selectable for children
                            }
                        }
                    }
                }

                // Child profiles section (selectable)
                if !childProfiles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(parentProfiles.isEmpty ? "Profiles" : "Siblings")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 4)

                        ForEach(childProfiles) { profile in
                            ChildProfileSelectionCard(
                                profile: profile,
                                isSelected: selectedProfile?.id == profile.id,
                                isDisabled: false
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedProfile = profile
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 400)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Empty State Section

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))

            Text("No profiles found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            Text("Ask your parent to create a profile for you")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: handleContinue) {
            HStack(spacing: 10) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
            }
            .foregroundColor(canContinue ? Color.blue.opacity(0.9) : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            .opacity(canContinue ? 1.0 : 0.5)
        }
        .disabled(!canContinue)
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Computed Properties

    private var canContinue: Bool {
        selectedProfile != nil
    }

    // MARK: - Actions

    private func loadChildProfiles() {
        Task {
            do {
                // Get ALL profiles for this household (parent and child)
                let profiles = try await householdService.getAllProfilesByInviteCode(inviteCode)

                await MainActor.run {
                    self.allProfiles = profiles
                    self.isLoading = false

                    withAnimation(.easeOut(duration: 0.5)) {
                        showContent = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to load profiles. Please try again."
                    print("❌ Failed to load profiles: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleContinue() {
        guard let profile = selectedProfile else { return }
        onProfileSelected(profile)
    }
}

// MARK: - Child Profile Selection Card

private struct ChildProfileSelectionCard: View {
    let profile: Profile
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                if let avatarUrl = profile.avatarUrl {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        avatarPlaceholder
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .opacity(isDisabled ? 0.5 : 1.0)
                } else {
                    avatarPlaceholder
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(profile.fullName ?? (profile.role == "parent" ? "Parent" : "Child"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        if profile.role == "parent" {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }

                    if let age = profile.age {
                        Text("\(age) years old")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    } else if profile.role == "parent" {
                        Text("Parent account")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Selection indicator or lock
                if isDisabled {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(isDisabled ? Color.white.opacity(0.08) : (isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.15)))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : (isDisabled ? Color.white.opacity(0.3) : Color.clear), lineWidth: 2)
            )
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.white.opacity(isDisabled ? 0.15 : 0.3))
            .frame(width: 60, height: 60)
            .overlay(
                Text((profile.fullName ?? "?").prefix(1).uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Preview

struct ChildProfileSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ChildProfileSelectorView(
            inviteCode: "123456",
            onProfileSelected: { _ in },
            onBack: {}
        )
    }
}
