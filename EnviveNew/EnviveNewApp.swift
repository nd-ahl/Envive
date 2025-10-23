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

    init() {
        // Clean up legacy test data on first launch after beta deployment
        TestDataCleanupService.shared.performCleanupIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                // ===== REFINED ONBOARDING FLOW =====
                // Flow: Welcome → RoleSelection → LegalAgreement → (Parent: SignUp → FamilySetup) OR (Child: Join → Permissions)

                if onboardingManager.shouldShowWelcome {
                    // Step 1: Friendly Welcome (no terms, no role selection)
                    FriendlyWelcomeView(
                        onContinue: {
                            onboardingManager.completeWelcome()
                        }
                    )
                } else if onboardingManager.shouldShowRoleSelection {
                    // Step 2: Role Selection (clear parent vs child choice)
                    RoleSelectionView(
                        onParentSelected: {
                            onboardingManager.completeRoleSelection()
                        },
                        onChildSelected: {
                            onboardingManager.completeRoleSelection()
                        }
                    )
                } else if onboardingManager.shouldShowLegalAgreement {
                    // Step 3: Legal Agreement (shown only once, never again)
                    LegalAgreementView(
                        onAccept: {
                            onboardingManager.completeLegalAgreement()
                        }
                    )
                } else if onboardingManager.shouldShowParentSignUp {
                    // Step 4a: Parent Sign Up
                    SimplifiedParentSignUpView(
                        onComplete: {
                            onboardingManager.completeSignIn()
                        },
                        onBack: {
                            onboardingManager.hasCompletedRoleSelection = false
                        }
                    )
                } else if onboardingManager.shouldShowParentFamilySetup {
                    // Step 5a: Parent Family Setup
                    QuickFamilySetupView(
                        onComplete: {
                            onboardingManager.completeFamilySetup()
                            onboardingManager.completeOnboarding()
                        }
                    )
                } else if onboardingManager.shouldShowChildJoin {
                    // Step 4b: Child Join with code
                    SimplifiedChildJoinView(
                        onComplete: {
                            onboardingManager.completeSignIn()
                        },
                        onBack: {
                            onboardingManager.hasCompletedRoleSelection = false
                        }
                    )
                } else if onboardingManager.shouldShowChildPermissions {
                    // Step 5b: Child Permissions (with clear instructions)
                    PermissionsView(
                        onComplete: {
                            onboardingManager.completePermissions()
                            onboardingManager.completeOnboarding()
                        }
                    )
                } else if showingSignIn {
                    // Legacy: Existing user sign-in flow
                    ExistingUserSignInView(
                        onComplete: {
                            onboardingManager.completeOnboarding()
                            showingSignIn = false
                        },
                        onBack: {
                            showingSignIn = false
                        }
                    )
                } else if false && onboardingManager.shouldShowQuestions {
                    // === OLD COMPLEX FLOW DISABLED ===
                    WelcomeView(
                        onGetStarted: {
                            onboardingManager.completeWelcome()
                        },
                        onSignIn: {
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
                    // Get user role to determine which flow to show
                    let roleString = UserDefaults.standard.string(forKey: "userRole") ?? "parent"
                    let userRole = roleString == "child" ? UserRole.child : UserRole.parent

                    if isCreatingHousehold {
                        // Show sign in/sign up for creating household (parent only)
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
                        // Show join household flow based on user role
                        if userRole == .parent {
                            // Parent joining existing household
                            ParentOnboardingCoordinator(
                                onComplete: {
                                    onboardingManager.completeSignIn()
                                },
                                onBack: {
                                    onboardingManager.hasCompletedHouseholdSelection = false
                                }
                            )
                        } else {
                            // Child joining existing household
                            ChildOnboardingCoordinator(
                                onComplete: {
                                    onboardingManager.completeSignIn()
                                },
                                onBack: {
                                    onboardingManager.hasCompletedHouseholdSelection = false
                                }
                            )
                        }
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
                    // Main app - legal consent already handled in refined onboarding flow
                    // (Users accept terms in LegalAgreementView during onboarding)
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
        case "/reset-password", "/auth/callback":
            // Handle password reset callback from email link
            print("🔐 Password reset callback received")
            handlePasswordResetCallback(url)
            break
        default:
            print("Unknown URL path: \(url.path)")
        }
    }

    /// Handle password reset callback from email link
    /// URL format: envivenew://reset-password#access_token=xxx&refresh_token=yyy&type=recovery
    private func handlePasswordResetCallback(_ url: URL) {
        print("Processing password reset callback...")

        // Parse the URL fragment (everything after #)
        guard let fragment = url.fragment else {
            print("❌ No fragment found in URL")
            return
        }

        // Parse fragment parameters
        let params = parseURLFragment(fragment)

        // Check if this is a password recovery flow
        guard let type = params["type"], type == "recovery" else {
            print("❌ Not a recovery flow, ignoring")
            return
        }

        // Extract tokens
        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"] else {
            print("❌ Missing access_token or refresh_token")
            return
        }

        print("✅ Found recovery tokens, establishing session...")

        // Set the session in Supabase
        Task {
            do {
                let supabase = SupabaseService.shared.client
                try await supabase.auth.setSession(
                    accessToken: accessToken,
                    refreshToken: refreshToken
                )

                print("✅ Password reset session established")

                // Post notification to trigger password reset UI
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PasswordResetReady"),
                        object: nil,
                        userInfo: ["accessToken": accessToken]
                    )
                }
            } catch {
                print("❌ Failed to set password reset session: \(error.localizedDescription)")
            }
        }
    }

    /// Parse URL fragment into dictionary
    /// Fragment format: "access_token=xxx&refresh_token=yyy&type=recovery"
    private func parseURLFragment(_ fragment: String) -> [String: String] {
        var params: [String: String] = [:]

        let pairs = fragment.components(separatedBy: "&")
        for pair in pairs {
            let keyValue = pair.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0]
                let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                params[key] = value
            }
        }

        return params
    }

}
