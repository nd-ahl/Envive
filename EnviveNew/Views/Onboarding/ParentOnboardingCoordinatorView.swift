//
//  ParentOnboardingCoordinatorView.swift
//  EnviveNew
//
//  Coordinates the parent onboarding flow with all explanation steps
//

import SwiftUI

struct ParentOnboardingCoordinatorView: View {
    let onComplete: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var householdService = HouseholdService.shared
    @StateObject private var onboardingManager = OnboardingManager.shared

    @State private var currentStep: OnboardingStep = .welcome
    @State private var parentName: String = ""
    @State private var childrenData: [AddChildOnboardingView.ChildProfileData] = []
    @State private var householdPassword: String = ""
    @State private var inviteCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    enum OnboardingStep {
        case welcome
        case addChild
        case householdPassword
        case inviteCode
        case tasksExplanation
        case credibilityExplanation
        case screenTimeExplanation
        case finalSummary
    }

    var body: some View {
        Group {
            switch currentStep {
            case .welcome:
                ParentWelcomeOnboardingView(
                    parentName: getParentName(),
                    onContinue: {
                        currentStep = .addChild
                    },
                    onSkip: {
                        skipToEnd()
                    }
                )

            case .addChild:
                AddChildOnboardingView(
                    onComplete: { children in
                        childrenData = children
                        createChildProfiles(children)
                    },
                    onSkip: {
                        currentStep = .householdPassword
                    }
                )

            case .householdPassword:
                HouseholdPasswordOnboardingView(
                    onComplete: { password in
                        householdPassword = password
                        saveHouseholdPassword(password)
                    },
                    onSkip: {
                        fetchInviteCode()
                    }
                )

            case .inviteCode:
                InviteCodeOnboardingView(
                    inviteCode: inviteCode,
                    onContinue: {
                        currentStep = .tasksExplanation
                    },
                    onSkip: {
                        currentStep = .tasksExplanation
                    }
                )

            case .tasksExplanation:
                TasksExplanationOnboardingView(
                    onContinue: {
                        currentStep = .credibilityExplanation
                    },
                    onSkip: {
                        currentStep = .credibilityExplanation
                    }
                )

            case .credibilityExplanation:
                CredibilityExplanationOnboardingView(
                    onContinue: {
                        currentStep = .screenTimeExplanation
                    },
                    onSkip: {
                        currentStep = .screenTimeExplanation
                    }
                )

            case .screenTimeExplanation:
                ScreenTimeExplanationOnboardingView(
                    onContinue: {
                        currentStep = .finalSummary
                    },
                    onSkip: {
                        currentStep = .finalSummary
                    },
                    onSetupApps: {
                        // Navigate to app management (implement this based on your app structure)
                        // For now, just continue to final summary
                        currentStep = .finalSummary
                    }
                )

            case .finalSummary:
                FinalOnboardingSummaryView(
                    childrenAdded: childrenData.count,
                    inviteCode: inviteCode,
                    onComplete: {
                        completeOnboarding()
                    },
                    onSetupApps: {
                        // Navigate to app management
                        // For now, complete onboarding
                        completeOnboarding()
                    }
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Fetch invite code when view appears
            fetchInviteCode()
        }
    }

    // MARK: - Helper Functions

    private func getParentName() -> String {
        if let name = authService.currentProfile?.fullName, !name.isEmpty {
            return name
        } else if let name = UserDefaults.standard.string(forKey: "parentName"), !name.isEmpty {
            return name
        }
        return "there"
    }

    private func createChildProfiles(_ children: [AddChildOnboardingView.ChildProfileData]) {
        guard !children.isEmpty else {
            // No children to create, move to next step
            currentStep = .householdPassword
            return
        }

        isLoading = true

        Task {
            do {
                // Get current user's profile
                guard let currentProfile = authService.currentProfile else {
                    throw NSError(domain: "ParentOnboarding", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "No authenticated user found"
                    ])
                }

                // Get or create household
                var householdId: String
                if let existingHouseholdId = currentProfile.householdId {
                    householdId = existingHouseholdId
                } else {
                    // Create household
                    let familyName = UserDefaults.standard.string(forKey: "familyName") ?? "Family"
                    let household = try await householdService.createHousehold(
                        name: familyName,
                        createdBy: currentProfile.id
                    )
                    householdId = household.id

                    // Refresh profile
                    try await Task.sleep(nanoseconds: 500_000_000)
                    try await authService.refreshCurrentProfile()
                }

                // Create each child profile
                for child in children {
                    do {
                        _ = try await householdService.createChildProfile(
                            name: child.name,
                            age: child.age,
                            householdId: householdId,
                            createdBy: currentProfile.id,
                            avatarUrl: nil
                        )
                        print("✅ Created child profile: \(child.name)")
                    } catch {
                        print("❌ Failed to create child profile for \(child.name): \(error.localizedDescription)")
                        throw error
                    }
                }

                await MainActor.run {
                    isLoading = false
                    // Mark family setup as completed in onboarding manager
                    onboardingManager.completeFamilySetup()
                    currentStep = .householdPassword
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func saveHouseholdPassword(_ password: String) {
        Task {
            do {
                guard let currentProfile = authService.currentProfile,
                      let householdId = currentProfile.householdId else {
                    throw NSError(domain: "ParentOnboarding", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "No household found"
                    ])
                }

                // Save password to household
                try await householdService.updateHouseholdPassword(
                    householdId: householdId,
                    password: password
                )

                await MainActor.run {
                    print("✅ Household password saved")
                    fetchInviteCode()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save password: \(error.localizedDescription)"
                    showError = true
                    // Continue anyway
                    fetchInviteCode()
                }
            }
        }
    }

    private func fetchInviteCode() {
        Task {
            do {
                guard let currentProfile = authService.currentProfile,
                      let householdId = currentProfile.householdId else {
                    throw NSError(domain: "ParentOnboarding", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "No household found"
                    ])
                }

                // Fetch household to get invite code
                let household = try await householdService.getHousehold(id: householdId)

                await MainActor.run {
                    inviteCode = household.inviteCode
                    print("✅ Fetched invite code: \(inviteCode)")
                    currentStep = .inviteCode
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch invite code: \(error.localizedDescription)"
                    showError = true
                    // Use placeholder and continue
                    inviteCode = "------"
                    currentStep = .inviteCode
                }
            }
        }
    }

    private func skipToEnd() {
        // Mark all steps as completed
        onboardingManager.completeFamilySetup()
        currentStep = .finalSummary
    }

    private func completeOnboarding() {
        // Mark onboarding as completed
        onboardingManager.completeOnboarding()
        onComplete()
    }
}

// MARK: - Preview

struct ParentOnboardingCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        ParentOnboardingCoordinatorView(
            onComplete: {}
        )
    }
}
