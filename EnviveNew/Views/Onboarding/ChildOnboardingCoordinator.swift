import SwiftUI

// MARK: - Child Onboarding Coordinator

/// Manages the child onboarding flow: enter code → select profile
struct ChildOnboardingCoordinator: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var currentStep: ChildOnboardingStep = .enterCode
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
                ChildProfileSelectorView(
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
        // Save the selected profile information
        UserDefaults.standard.set(profile.id, forKey: "linkedChildProfileId")
        UserDefaults.standard.set(profile.fullName, forKey: "childName")
        UserDefaults.standard.set(profile.fullName, forKey: "userName") // Also save as userName for settings
        if let age = profile.age {
            UserDefaults.standard.set(age, forKey: "childAge")
            UserDefaults.standard.set(age, forKey: "userAge") // Also save as userAge
        }

        // Save household info
        if let householdId = profile.householdId {
            UserDefaults.standard.set(householdId, forKey: "householdId")
            UserDefaults.standard.set(inviteCode, forKey: "householdCode")
            UserDefaults.standard.set(true, forKey: "isInHousehold")
        }

        // Set device mode to CHILD (this is critical!)
        let childMode = DeviceModeService.deviceModeFromUserRole(.child)
        DeviceModeService.shared.setDeviceMode(childMode)

        // Mark parent-only steps as complete so children skip them
        OnboardingManager.shared.hasCompletedNameEntry = true
        OnboardingManager.shared.hasCompletedFamilySetup = true

        print("✅ Device linked to child profile: \(profile.fullName ?? "Child")")
        print("  - Profile ID: \(profile.id)")
        print("  - Household ID: \(profile.householdId ?? "nil")")
        print("  - Age: \(profile.age ?? 0)")
        print("  - Device mode set to: CHILD")
        print("  - Moving to next onboarding step (Permissions)")

        onComplete()
    }
}

// MARK: - Child Onboarding Step Enum

private enum ChildOnboardingStep {
    case enterCode
    case selectProfile
}

// MARK: - Preview

struct ChildOnboardingCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        ChildOnboardingCoordinator(
            onComplete: {},
            onBack: {}
        )
    }
}
