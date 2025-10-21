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
                    }
                )
            }
        }
    }

    private func linkDeviceToProfile(_ profile: Profile) {
        // Save the selected profile information
        UserDefaults.standard.set(profile.id, forKey: "linkedChildProfileId")
        UserDefaults.standard.set(profile.fullName, forKey: "childName")
        if let age = profile.age {
            UserDefaults.standard.set(age, forKey: "childAge")
        }

        // Save household info
        if let householdId = profile.householdId {
            UserDefaults.standard.set(householdId, forKey: "householdId")
            UserDefaults.standard.set(inviteCode, forKey: "householdCode")
            UserDefaults.standard.set(true, forKey: "isInHousehold")
        }

        print("✅ Device linked to child profile: \(profile.fullName ?? "Child")")
        print("Profile ID: \(profile.id)")

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
