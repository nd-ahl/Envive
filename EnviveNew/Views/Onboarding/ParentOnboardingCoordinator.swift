import SwiftUI

// MARK: - Parent Onboarding Coordinator

/// Manages the parent onboarding flow: enter code → authenticate → select profile
/// SECURITY: Requires email/password authentication before accessing parent roles
struct ParentOnboardingCoordinator: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var currentStep: ParentOnboardingStep = .enterCode
    @State private var inviteCode: String = ""
    @State private var authenticatedProfile: Profile?

    var body: some View {
        Group {
            switch currentStep {
            case .enterCode:
                ChildInviteCodeEntryView(
                    onCodeEntered: { code in
                        inviteCode = code
                        withAnimation {
                            currentStep = .authenticate
                        }
                    },
                    onBack: onBack
                )

            case .authenticate:
                ParentAuthenticationView(
                    inviteCode: inviteCode,
                    onAuthenticated: { profile in
                        authenticatedProfile = profile
                        withAnimation {
                            currentStep = .selectProfile
                        }
                    },
                    onBack: {
                        withAnimation {
                            currentStep = .enterCode
                        }
                    }
                )

            case .selectProfile:
                ParentProfileSelectorView(
                    inviteCode: inviteCode,
                    onProfileSelected: { profile in
                        // Link this device to the selected profile
                        linkDeviceToProfile(profile)
                    },
                    onBack: {
                        withAnimation {
                            currentStep = .authenticate
                        }
                    }
                )
            }
        }
    }

    private func linkDeviceToProfile(_ profile: Profile) {
        // IMPORTANT: Use the AUTHENTICATED user's role, not the selected profile's role
        // The authenticated user determines the device mode
        guard let authenticatedProfile = authenticatedProfile else {
            print("❌ Error: No authenticated profile found")
            return
        }

        // The authenticated user's role determines device mode
        let authenticatedRole: UserRole = authenticatedProfile.role == "parent" ? .parent : .child

        // SECURITY: If authenticated as parent, only allow selecting parent profiles
        // This prevents a parent from accidentally logging into a child's profile
        if authenticatedRole == .parent && profile.role != "parent" {
            print("❌ Error: Parent authenticated users can only select parent profiles")
            print("  - Authenticated as: \(authenticatedProfile.fullName ?? "Unknown") (parent)")
            print("  - Attempted to select: \(profile.fullName ?? "Unknown") (\(profile.role))")
            return
        }

        // Save the selected profile information
        UserDefaults.standard.set(profile.id, forKey: "linkedProfileId")
        UserDefaults.standard.set(profile.fullName, forKey: "userName")
        if let age = profile.age {
            UserDefaults.standard.set(age, forKey: "userAge")
        }

        // Save household info
        if let householdId = profile.householdId {
            UserDefaults.standard.set(householdId, forKey: "householdId")
            UserDefaults.standard.set(inviteCode, forKey: "householdCode")
            UserDefaults.standard.set(true, forKey: "isInHousehold")
        }

        // Set device mode based on AUTHENTICATED role, not selected profile
        let deviceMode = DeviceModeService.deviceModeFromUserRole(authenticatedRole)
        DeviceModeService.shared.setDeviceMode(deviceMode)

        // Save AUTHENTICATED user role for onboarding flow
        UserDefaults.standard.set(authenticatedRole == .parent ? "parent" : "child", forKey: "userRole")

        // Mark certain steps as complete since they're joining existing household
        OnboardingManager.shared.hasCompletedNameEntry = true
        OnboardingManager.shared.hasCompletedFamilySetup = true

        print("✅ Device linked to profile: \(profile.fullName ?? "Unknown")")
        print("  - Authenticated as: \(authenticatedProfile.fullName ?? "Unknown") (\(authenticatedProfile.role))")
        print("  - Selected profile: \(profile.fullName ?? "Unknown") (\(profile.role))")
        print("  - Profile ID: \(profile.id)")
        print("  - Household ID: \(profile.householdId ?? "nil")")
        print("  - Device mode set to: \(deviceMode.displayName)")
        print("  - Moving to next onboarding step")

        onComplete()
    }
}

// MARK: - Parent Onboarding Step Enum

private enum ParentOnboardingStep {
    case enterCode
    case authenticate
    case selectProfile
}

// MARK: - Preview

struct ParentOnboardingCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        ParentOnboardingCoordinator(
            onComplete: {},
            onBack: {}
        )
    }
}
