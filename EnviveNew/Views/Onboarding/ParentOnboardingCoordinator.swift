import SwiftUI

// MARK: - Parent Onboarding Coordinator

/// Manages the parent onboarding flow: enter code → select profile (can select ANY role)
struct ParentOnboardingCoordinator: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var currentStep: ParentOnboardingStep = .enterCode
    @State private var inviteCode: String = ""

    var body: some View {
        Group {
            switch currentStep {
            case .enterCode:
                ChildInviteCodeEntryView(
                    onCodeEntered: { code in
                        inviteCode = code
                        withAnimation {
                            currentStep = .selectProfile
                        }
                    },
                    onBack: onBack
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
                            currentStep = .enterCode
                        }
                    }
                )
            }
        }
    }

    private func linkDeviceToProfile(_ profile: Profile) {
        // Determine if selected profile is parent or child
        let selectedRole: UserRole = profile.role == "parent" ? .parent : .child

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

        // Set device mode based on selected role
        let deviceMode = DeviceModeService.deviceModeFromUserRole(selectedRole)
        DeviceModeService.shared.setDeviceMode(deviceMode)

        // Save user role for onboarding flow
        UserDefaults.standard.set(selectedRole == .parent ? "parent" : "child", forKey: "userRole")

        // If parent was selected and they're joining (not creating), skip certain steps
        if selectedRole == .parent {
            // Mark certain steps as complete since they're joining existing household
            OnboardingManager.shared.hasCompletedNameEntry = true
            OnboardingManager.shared.hasCompletedFamilySetup = true

            print("✅ Device linked to parent profile: \(profile.fullName ?? "Parent")")
            print("  - Profile ID: \(profile.id)")
            print("  - Household ID: \(profile.householdId ?? "nil")")
            print("  - Device mode set to: PARENT")
        } else {
            // Parent joining as child (for troubleshooting)
            OnboardingManager.shared.hasCompletedNameEntry = true
            OnboardingManager.shared.hasCompletedFamilySetup = true

            print("✅ Device linked to child profile: \(profile.fullName ?? "Child")")
            print("  - Profile ID: \(profile.id)")
            print("  - Household ID: \(profile.householdId ?? "nil")")
            print("  - Age: \(profile.age ?? 0)")
            print("  - Device mode set to: CHILD")
        }

        print("  - Moving to next onboarding step")
        onComplete()
    }
}

// MARK: - Parent Onboarding Step Enum

private enum ParentOnboardingStep {
    case enterCode
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
