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
    @StateObject private var authService = AuthenticationService.shared
    @State private var isCreatingHousehold = false
    @State private var showingSignIn = false

    var body: some Scene {
        WindowGroup {
            Group {
                if showingSignIn {
                    // Existing user sign-in flow (skip onboarding)
                    ExistingUserSignInView(
                        onComplete: {
                            // User signed in successfully - skip onboarding
                            onboardingManager.completeOnboarding()
                            showingSignIn = false
                        },
                        onBack: {
                            showingSignIn = false
                        }
                    )
                } else if onboardingManager.shouldShowWelcome {
                    WelcomeView(
                        onGetStarted: {
                            onboardingManager.completeWelcome()
                        },
                        onSignIn: {
                            // Show sign-in screen for existing users
                            showingSignIn = true
                        }
                    )
                } else if onboardingManager.shouldShowQuestions {
                    OnboardingQuestionView(
                        onComplete: {
                            onboardingManager.completeQuestions()
                        },
                        onBack: {
                            onboardingManager.hasCompletedWelcome = false
                        }
                    )
                } else if onboardingManager.shouldShowRoleConfirmation {
                    // Get user role from saved responses
                    let roleString = UserDefaults.standard.string(forKey: "userRole") ?? "parent"
                    let userRole = roleString == "child" ? UserRole.child : UserRole.parent

                    RoleConfirmationView(
                        userRole: userRole,
                        onConfirm: {
                            onboardingManager.completeRoleConfirmation(role: userRole)
                        },
                        onGoBack: {
                            // Allow user to go back to questions to change their role
                            onboardingManager.hasCompletedQuestions = false
                        }
                    )
                } else if onboardingManager.shouldShowHouseholdSelection {
                    // Get user role from saved responses
                    let roleString = UserDefaults.standard.string(forKey: "userRole") ?? "parent"
                    let userRole = roleString == "child" ? UserRole.child : UserRole.parent

                    HouseholdSelectionView(
                        userRole: userRole,
                        onCreateHousehold: {
                            isCreatingHousehold = true
                            onboardingManager.completeHouseholdSelection()
                        },
                        onJoinHousehold: {
                            isCreatingHousehold = false
                            onboardingManager.completeHouseholdSelection()
                        },
                        onBack: {
                            onboardingManager.hasCompletedRoleConfirmation = false
                        }
                    )
                } else if onboardingManager.shouldShowSignIn {
                    if isCreatingHousehold {
                        // Show sign in/sign up for creating household
                        SignInView(
                            isCreatingHousehold: true,
                            onComplete: {
                                onboardingManager.completeSignIn()
                            },
                            onBack: {
                                onboardingManager.hasCompletedHouseholdSelection = false
                            }
                        )
                    } else {
                        // Show join household flow for children
                        ChildOnboardingCoordinator(
                            onComplete: {
                                onboardingManager.completeSignIn()
                            },
                            onBack: {
                                onboardingManager.hasCompletedHouseholdSelection = false
                            }
                        )
                    }
                } else if onboardingManager.shouldShowNameEntry {
                    // NEW: Parent name entry
                    ParentNameEntryView(
                        onComplete: { name in
                            onboardingManager.completeNameEntry(name: name)
                        },
                        onBack: {
                            onboardingManager.hasCompletedSignIn = false
                        }
                    )
                } else if onboardingManager.shouldShowFamilySetup {
                    // NEW: Family setup flow (add profiles + link devices)
                    OnboardingCoordinator(
                        onComplete: {
                            onboardingManager.completeFamilySetup()
                        },
                        onBack: {
                            onboardingManager.hasCompletedNameEntry = false
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
                        }
                    )
                } else if onboardingManager.shouldShowBenefits {
                    // Get user role from saved responses
                    let roleString = UserDefaults.standard.string(forKey: "userRole") ?? "parent"
                    let userRole = roleString == "child" ? UserRole.child : UserRole.parent

                    BenefitsView(
                        userRole: userRole,
                        onComplete: {
                            onboardingManager.completeBenefits()
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
