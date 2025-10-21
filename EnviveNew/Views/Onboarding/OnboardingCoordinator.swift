import SwiftUI

// MARK: - Onboarding Coordinator

/// Manages the onboarding flow after account creation
struct OnboardingCoordinator: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var currentStep: OnboardingStep = .addProfiles

    var body: some View {
        Group {
            switch currentStep {
            case .addProfiles:
                AddProfilesView(
                    onContinue: {
                        withAnimation {
                            currentStep = .linkDevices
                        }
                    },
                    onSkip: {
                        withAnimation {
                            currentStep = .linkDevices
                        }
                    },
                    onBack: onBack
                )

            case .linkDevices:
                LinkDevicesView(
                    onComplete: {
                        // Save onboarding completion
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        onComplete()
                    },
                    onBack: {
                        withAnimation {
                            currentStep = .addProfiles
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Onboarding Step Enum

private enum OnboardingStep {
    case addProfiles
    case linkDevices
}

// MARK: - Preview

struct OnboardingCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCoordinator(onComplete: {}, onBack: {})
    }
}
