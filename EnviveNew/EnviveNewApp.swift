//
//  EnviveNewApp.swift
//  EnviveNew
//
//  Created by Paul Ahlstrom on 9/20/25.
//

import SwiftUI
import CoreData
import FamilyControls

@main
struct EnviveNewApp: App {
    let persistenceController = PersistenceController.shared

    // Theme management
    @StateObject private var themeViewModel = DependencyContainer.shared
        .viewModelFactory.makeThemeSettingsViewModel()

    // Onboarding management
    @StateObject private var onboardingManager = OnboardingManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingManager.shouldShowWelcome {
                    WelcomeView(
                        onGetStarted: {
                            onboardingManager.completeWelcome()
                        },
                        onSignIn: {
                            onboardingManager.completeWelcome()
                            // TODO: Navigate to sign in
                        }
                    )
                } else if onboardingManager.shouldShowQuestions {
                    OnboardingQuestionView(
                        onComplete: {
                            onboardingManager.completeQuestions()
                        }
                    )
                } else if onboardingManager.shouldShowAgeSelection {
                    // Get user role from saved responses
                    let roleString = UserDefaults.standard.string(forKey: "userRole") ?? "parent"
                    let userRole = roleString == "child" ? UserRole.child : UserRole.parent

                    AgeSelectionView(
                        userRole: userRole,
                        onComplete: { age in
                            onboardingManager.completeAgeSelection(age: age)
                        }
                    )
                } else if onboardingManager.shouldShowPermissions {
                    PermissionsView(
                        onComplete: {
                            onboardingManager.completePermissions()
                            onboardingManager.completeOnboarding()
                        }
                    )
                } else {
                    RootNavigationView()
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .preferredColorScheme(themeViewModel.effectiveColorScheme)
            .onOpenURL { url in
                handleURLScheme(url)
            }
        }
    }

    private func handleURLScheme(_ url: URL) {
        print("Received URL scheme: \(url)")

        // Handle different URL paths
        switch url.path {
        case "/screentime":
            // User tapped on Dynamic Island/Live Activity during screen time session
            print("Opening app from screen time Live Activity")
            // The app will automatically show the current screen time session state
            // since the ScreenTimeRewardManager is already tracking the active session
            break
        case "/spend":
            // User tapped "Spend Time" button in Focus widget
            print("Opening app from Focus widget - user wants to spend screen time")

            // Extract minutes parameter from URL query
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let minutesString = queryItems.first(where: { $0.name == "minutes" })?.value,
               let minutes = Int(minutesString) {
                print("Widget requested \(minutes) minutes of screen time")

                // Post notification with minutes to start session
                NotificationCenter.default.post(
                    name: NSNotification.Name("StartScreenTimeSession"),
                    object: nil,
                    userInfo: ["minutes": minutes]
                )
            }
            break
        default:
            print("Unknown URL path: \(url.path)")
        }
    }

}
