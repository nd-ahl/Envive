//
//  EnviveNewApp.swift
//  EnviveNew
//
//  Created by Paul Ahlstrom on 9/20/25.
//

import SwiftUI
import CoreData
import FamilyControls
import Supabase
import Auth

@main
struct EnviveNewApp: App {
    @State private var persistenceController: PersistenceController?
    @State private var appIsReady = false

    // CRITICAL FIX: Use @ObservedObject instead of @StateObject
    // StateObject can block app initialization while it waits for the object to fully initialize
    // ObservedObject is lighter and doesn't block
    @ObservedObject private var onboardingManager = OnboardingManager.shared
    @ObservedObject private var authService = AuthenticationService.shared

    // Theme will be initialized lazily after app renders
    @State private var themeViewModel: ThemeSettingsViewModel?

    @State private var isCreatingHousehold = false
    @State private var showingSignIn = false
    @State private var needsPasswordSetup = false
    @State private var userEmailForPassword = ""
    @State private var showSplashScreen = false

    @Environment(\.scenePhase) private var scenePhase

    init() {
        print("🚀 EnviveNewApp init() started")
        print("   - Using lightweight initialization to prevent device freeze")
        // Clean up legacy test data on first launch after beta deployment
        // TEMPORARILY DISABLED: Causing blank screen on hot reload during development
        // TestDataCleanupService.shared.performCleanupIfNeeded()
        print("✅ EnviveNewApp init() completed (lightweight)")
    }

    var body: some Scene {
        WindowGroup {
            mainContent
                .environment(\.managedObjectContext, persistenceController?.container.viewContext ?? PersistenceController(inMemory: true).container.viewContext)
                .preferredColorScheme(themeViewModel?.effectiveColorScheme ?? .none)
                .onOpenURL { url in
                    handleURLScheme(url)
                }
                .task {
                    // Initialize theme view model lazily after UI renders
                    if themeViewModel == nil {
                        print("🎨 Initializing ThemeViewModel after app rendered...")
                        themeViewModel = DependencyContainer.shared.viewModelFactory.makeThemeSettingsViewModel()
                        print("✅ ThemeViewModel initialized")
                    }

                    // Load Core Data in background without blocking UI
                    if persistenceController == nil {
                        print("🔄 Loading Core Data in background...")
                        let start = Date()
                        persistenceController = await PersistenceController.loadAsync()
                        let duration = Date().timeIntervalSince(start)
                        print("✅ Core Data loaded in \(String(format: "%.2f", duration)) seconds")
                    }

                    appIsReady = true
                }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            // EMERGENCY: Show immediate loading indicator to prove app is alive
            if !appIsReady {
                ZStack {
                    Color.blue.ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                        Text("Loading Envive...")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("If stuck here, check Xcode console")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .onAppear {
                    print("🚨 EMERGENCY LOADING VIEW APPEARED - App is rendering!")
                    print("   If you see this, SwiftUI is working. Check console for where it freezes next.")
                }
            }

            Group {
                if appIsReady {
                    // ===== REFINED ONBOARDING FLOW =====
                    // Flow: Welcome → RoleSelection → LegalAgreement → (Parent: SignUp → FamilySetup) OR (Child: Join → Permissions)
                    let _ = print("🎬 mainContent rendering - checking onboarding state")

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
                        },
                        onBack: {
                            onboardingManager.hasCompletedSignIn = false
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
                    // Main app - only shown after completing all onboarding steps
                    // ALWAYS show splash screen with data refresh on EVERY app launch
                    let _ = print("🏠🏠🏠 Main app view rendering - showSplashScreen: \(showSplashScreen)")

                    MainAppWithRefresh(
                        showSplashScreen: $showSplashScreen,
                        authService: authService,
                        onboardingManager: onboardingManager
                    )
                    }
                } // End of appIsReady check
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
            // Handle both password reset AND email confirmation callbacks
            print("🔐 Auth callback received")
            handleAuthCallback(url)
            break
        default:
            print("Unknown URL path: \(url.path)")
        }
    }

    /// Handle authentication callbacks (password reset AND email confirmation)
    /// URL format: envivenew://auth/callback#access_token=xxx&refresh_token=yyy&type=recovery|signup
    private func handleAuthCallback(_ url: URL) {
        print("Processing auth callback...")

        // Parse the URL fragment (everything after #)
        guard let fragment = url.fragment else {
            print("❌ No fragment found in URL")
            return
        }

        // Parse fragment parameters
        let params = parseURLFragment(fragment)

        // Extract tokens
        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"] else {
            print("❌ Missing access_token or refresh_token")
            return
        }

        // Check the type of callback
        let callbackType = params["type"] ?? "unknown"

        switch callbackType {
        case "recovery":
            // Password reset flow
            handlePasswordResetFlow(accessToken: accessToken, refreshToken: refreshToken)

        case "signup", "email_confirmation":
            // Email confirmation flow
            handleEmailConfirmationFlow(accessToken: accessToken, refreshToken: refreshToken)

        default:
            print("⚠️ Unknown callback type: \(callbackType), attempting to establish session anyway...")
            // Try to establish session for any auth callback
            handleEmailConfirmationFlow(accessToken: accessToken, refreshToken: refreshToken)
        }
    }

    /// Handle password reset flow
    private func handlePasswordResetFlow(accessToken: String, refreshToken: String) {
        print("🔐 Processing password reset flow...")

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

    /// Handle email confirmation flow
    private func handleEmailConfirmationFlow(accessToken: String, refreshToken: String) {
        print("📧 Processing email confirmation flow...")

        Task {
            do {
                let supabase = SupabaseService.shared.client

                // Set the session with confirmed tokens - this marks email as verified
                try await supabase.auth.setSession(
                    accessToken: accessToken,
                    refreshToken: refreshToken
                )

                print("✅ Email confirmed! Session established")

                // Verify the session is valid
                guard let session = try? await supabase.auth.session else {
                    print("❌ Failed to get session after confirmation")
                    return
                }

                print("✅ Session valid, user ID: \(session.user.id.uuidString)")
                print("✅ Email verified: \(session.user.emailConfirmedAt != nil)")

                // Load the user's profile
                do {
                    let profile = try await authService.loadProfile(userId: session.user.id.uuidString)

                    await MainActor.run {
                        authService.isAuthenticated = true
                        authService.currentProfile = profile
                        authService.isCheckingAuth = false
                    }

                    print("✅ User profile loaded: \(profile.email ?? "unknown")")
                    print("✅ User household: \(profile.householdId ?? "none")")

                    // Set household context if available
                    if let householdIdString = profile.householdId,
                       let householdId = UUID(uuidString: householdIdString) {
                        let parentId: UUID? = profile.role == "parent" ? UUID(uuidString: profile.id) : nil
                        HouseholdContext.shared.setHouseholdContext(
                            householdId: householdId,
                            parentId: parentId
                        )
                        print("✅ Household context set")
                    }

                    // Continue with onboarding flow
                    await MainActor.run {
                        // Mark sign-in as complete so they can proceed to family setup
                        onboardingManager.completeSignIn()

                        // Check if they've already completed family setup
                        if onboardingManager.hasCompletedFamilySetup {
                            print("✅ User already completed family setup - going to main app")
                            onboardingManager.completeOnboarding()
                        } else {
                            print("✅ Email confirmed - user will now proceed to family setup")
                            // User will be shown QuickFamilySetupView next
                            // This is where they can add children to their family
                        }

                        print("✅ Email confirmation complete")

                        // Show success notification to user
                        NotificationCenter.default.post(
                            name: NSNotification.Name("EmailConfirmed"),
                            object: nil,
                            userInfo: ["email": profile.email ?? ""]
                        )
                    }
                } catch {
                    print("⚠️ Profile not found after confirmation: \(error.localizedDescription)")
                    // User account exists in auth but profile not created yet
                    // This shouldn't happen with proper signup flow, but handle gracefully
                    await MainActor.run {
                        authService.isAuthenticated = true
                        // Let them continue to create profile
                        onboardingManager.completeSignIn()
                    }
                }

            } catch {
                print("❌ Failed to confirm email: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
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

// MARK: - Main App with Automatic Refresh

/// Wrapper view that ensures splash screen with data refresh shows on EVERY app launch
/// This view is destroyed and recreated on every scene phase change, guaranteeing fresh state
struct MainAppWithRefresh: View {
    @Binding var showSplashScreen: Bool
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var onboardingManager: OnboardingManager
    @Environment(\.scenePhase) private var scenePhase

    init(showSplashScreen: Binding<Bool>, authService: AuthenticationService, onboardingManager: OnboardingManager) {
        self._showSplashScreen = showSplashScreen
        self.authService = authService
        self.onboardingManager = onboardingManager
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🏗️ MainAppWithRefresh.init() CALLED")
        print("   - showSplashScreen initial value: \(showSplashScreen.wrappedValue)")
        print("   - authService.isAuthenticated: \(authService.isAuthenticated)")
        print("   - authService.currentProfile exists: \(authService.currentProfile != nil)")
        if let profile = authService.currentProfile {
            print("   - Profile: \(profile.fullName ?? "Unknown") (\(profile.id))")
            print("   - Household ID: \(profile.householdId ?? "None")")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    var body: some View {
        let _ = print("🏠 MainAppWithRefresh.body rendering - showSplashScreen: \(showSplashScreen)")

        ZStack {
            // Only show RootNavigationView after splash completes
            // This ensures .onAppear fires AFTER data refresh is complete
            if !showSplashScreen {
                RootNavigationView()
                    .transition(.opacity)
                    .onAppear {
                        print("📱 RootNavigationView appeared AFTER splash screen")
                    }
            }

            // Animated splash screen overlay - triggers data refresh on every app launch
            if showSplashScreen {
                let _ = print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                let _ = print("🎬 RENDERING AnimatedSplashScreen (showSplashScreen = true)")
                let _ = print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                AnimatedSplashScreen {
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("🔚 AnimatedSplashScreen onComplete callback FIRED")
                    print("   - About to set showSplashScreen = false")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplashScreen = false
                        print("✅ showSplashScreen set to false - main app should now be visible")
                    }
                }
                .transition(.opacity)
                .zIndex(999)
            } else {
                let _ = print("⚠️ NOT showing splash screen (showSplashScreen = false)")
            }
        }
        .onAppear {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🎯 MainAppWithRefresh.onAppear() TRIGGERED")
            print("   - Current showSplashScreen value: \(showSplashScreen)")
            print("   - authService.isAuthenticated: \(authService.isAuthenticated)")
            print("   - authService.currentProfile exists: \(authService.currentProfile != nil)")
            if let profile = authService.currentProfile {
                print("   - User: \(profile.fullName ?? "Unknown")")
                print("   - Household ID: \(profile.householdId ?? "None")")
            } else {
                print("   - ❌ NO CURRENT PROFILE - THIS MAY BE THE PROBLEM!")
            }
            print("   - onboardingManager.hasCompletedOnboarding: \(onboardingManager.hasCompletedOnboarding)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // ALWAYS show splash screen on main app launch (no conditions)
            print("✅ SETTING showSplashScreen = true (UNCONDITIONAL)")
            showSplashScreen = true
            print("   - showSplashScreen is now: \(showSplashScreen)")

            // CRITICAL: Only auto-complete if user has legitimately finished onboarding
            let shouldAutoComplete = authService.isAuthenticated &&
                                     !onboardingManager.hasCompletedOnboarding &&
                                     onboardingManager.hasCompletedFamilySetup

            if shouldAutoComplete {
                print("⚠️ User authenticated and completed family setup - auto-completing onboarding")
                DispatchQueue.main.async {
                    onboardingManager.completeOnboarding()
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔄 MainAppWithRefresh scenePhase CHANGED")
            print("   - Old phase: \(oldPhase)")
            print("   - New phase: \(newPhase)")
            print("   - Current showSplashScreen: \(showSplashScreen)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // ALWAYS refresh when app becomes active
            if newPhase == .active && oldPhase != .active {
                print("✅ App became ACTIVE (from background)")
                print("✅ SETTING showSplashScreen = true (UNCONDITIONAL)")
                showSplashScreen = true
                print("   - showSplashScreen is now: \(showSplashScreen)")
            }
        }
    }
}

