import SwiftUI

// MARK: - Child Profile Selector View

/// Screen where child selects which profile is theirs from household
struct ChildProfileSelectorView: View {
    let inviteCode: String
    let onProfileSelected: (Profile) -> Void
    let onBack: () -> Void

    @StateObject private var householdService = HouseholdService.shared
    @State private var childProfiles: [Profile] = []
    @State private var selectedProfile: Profile?
    @State private var isLoading = true
    @State private var showContent = false
    @State private var errorMessage: String?

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
            Text("👶")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Who are you?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("Select your profile from the list")
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
            VStack(spacing: 12) {
                ForEach(childProfiles) { profile in
                    ChildProfileSelectionCard(
                        profile: profile,
                        isSelected: selectedProfile?.id == profile.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedProfile = profile
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
                // Get all child profiles for this household
                let profiles = try await householdService.getChildProfilesByInviteCode(inviteCode)

                await MainActor.run {
                    self.childProfiles = profiles
                    self.isLoading = false

                    withAnimation(.easeOut(duration: 0.5)) {
                        showContent = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to load profiles. Please try again."
                    print("❌ Failed to load child profiles: \(error.localizedDescription)")
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
                } else {
                    avatarPlaceholder
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.fullName ?? "Child")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    if let age = profile.age {
                        Text("\(age) years old")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.white.opacity(0.3))
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
