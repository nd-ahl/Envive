import SwiftUI
import LocalAuthentication
import Supabase

// MARK: - Root Navigation View

/// Main navigation coordinator that routes to Parent or Child views based on device mode
/// This is the central routing point that respects the DeviceModeManager state
struct RootNavigationView: View {
    @ObservedObject private var deviceModeManager: LocalDeviceModeManager
    @ObservedObject private var deviceModeService = DeviceModeService.shared
    @StateObject private var model = EnhancedScreenTimeModel()
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Get the device mode manager from dependency container
        let manager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
        self.deviceModeManager = manager
    }

    var body: some View {
        ZStack {
            // Main content based on mode
            // When role is locked, use DeviceModeService as source of truth
            // Otherwise use LocalDeviceModeManager for testing flexibility
            Group {
                if currentEffectiveMode == .parent {
                    parentView
                } else {
                    childView
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: currentEffectiveMode)
            .onAppear(perform: handleAppAppear)
            .onChange(of: scenePhase, handleScenePhaseChange)
            .badgeNotifications()

            // Floating mode switcher button (for testing) - draggable
            ModeSwitcherButton(deviceModeManager: deviceModeManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    // MARK: - Computed Properties

    /// The effective device mode - uses DeviceModeService when locked, LocalDeviceModeManager otherwise
    private var currentEffectiveMode: DeviceMode {
        if deviceModeService.isRoleLocked {
            return deviceModeService.deviceMode
        } else {
            return deviceModeManager.currentMode
        }
    }

    /// The current child ID based on which child mode is active
    private var currentChildId: UUID {
        // Use actual child ID from current profile, not test IDs
        // This ensures tasks are saved and retrieved with the correct child UUID
        if let profileId = deviceModeManager.currentProfile?.id {
            return profileId
        }

        // Fallback to test child IDs only if profile not available
        switch currentEffectiveMode {
        case .parent:
            return deviceModeManager.getTestChild1Id()  // Shouldn't happen, but default to child 1
        case .child1:
            return deviceModeManager.getTestChild1Id()
        case .child2:
            return deviceModeManager.getTestChild2Id()
        }
    }

    // MARK: - Parent View

    private var parentView: some View {
        TabView(selection: $selectedTab) {
            // Parent Dashboard
            ParentDashboardView(
                viewModel: ParentDashboardViewModel(
                    taskService: DependencyContainer.shared.taskService,
                    credibilityService: DependencyContainer.shared.credibilityService,
                    xpService: DependencyContainer.shared.xpService,
                    parentId: deviceModeManager.currentProfile?.id ?? UUID()
                ),
                appSelectionStore: model.appSelectionStore,
                notificationManager: model.notificationManager,
                selectedTab: $selectedTab
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Dashboard")
            }
            .tag(0)

            // Children Overview/Management
            ParentChildrenManagementView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Children")
                }
                .tag(1)

            // Settings/Profile
            ParentProfileView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
    }

    // MARK: - Child View

    private var childView: some View {
        TabView(selection: $selectedTab) {
            // Home - Screen time management
            EnhancedHomeView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            // Tasks - New task dashboard
            ChildDashboardView(
                viewModel: ChildDashboardViewModel(
                    taskService: DependencyContainer.shared.taskService,
                    xpService: DependencyContainer.shared.xpService,
                    credibilityService: DependencyContainer.shared.credibilityService,
                    childId: currentChildId
                )
            )
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Tasks")
            }
            .tag(1)

            // Social - TEMPORARILY REMOVED
            // SocialView()
            //     .environmentObject(model)
            //     .tabItem {
            //         Image(systemName: "heart.circle.fill")
            //         Text("Social")
            //     }
            //     .tag(2)

            // App Management (Password Protected)
            ChildAppManagementView(appSelectionStore: model.appSelectionStore)
                .tabItem {
                    Image(systemName: "lock.shield.fill")
                    Text("App Limits")
                }
                .tag(2)

            // Profile
            ProfileView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(3)
        }
    }

    // Recent activity count - REMOVED with social features
    // private var recentActivityCount: Int {
    //     model.friendActivities.filter { activity in
    //         Date().timeIntervalSince(activity.timestamp) < 3600
    //     }.count
    // }

    // MARK: - Handlers

    private func handleAppAppear() {
        model.notificationManager.requestPermission()
        model.notificationManager.clearBadge()
    }

    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("App became active - ensuring restrictions are applied")
            model.ensureAppsAreBlocked()
            model.checkForPendingWidgetSession()
            model.checkForEndSessionRequest()
        case .inactive:
            print("App became inactive")
        case .background:
            print("App moved to background")
        @unknown default:
            break
        }
    }
}

// MARK: - Parent Children View

struct ParentChildrenView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Children Management")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("View and manage your children's profiles, credibility scores, and task history")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // TODO: List of children with details
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Children")
        }
    }
}

// MARK: - Parent Activity View

struct ParentActivityView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Activity & Reports")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("View task history, screen time usage, and family activity reports")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // TODO: Activity charts and reports
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Activity")
        }
    }
}

// MARK: - Parent Profile View

struct ParentProfileView: View {
    @ObservedObject private var deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
    @ObservedObject private var deviceModeService = DeviceModeService.shared
    @ObservedObject private var resetHelper = ResetOnboardingHelper.shared
    @ObservedObject private var profilePhotoManager = ProfilePhotoManager.shared
    @ObservedObject private var householdService = HouseholdService.shared
    @ObservedObject private var authService = AuthenticationService.shared
    @StateObject private var themeViewModel = DependencyContainer.shared
        .viewModelFactory.makeThemeSettingsViewModel()

    private let supabase = SupabaseService.shared.client

    @State private var showingProfilePhotoPicker = false
    @State private var showCopiedMessage = false
    @State private var showingNameEditor = false
    @State private var editedName = ""
    @State private var showingResetTestDataConfirmation = false
    @AppStorage("enableDeviceSwitcher") private var enableDeviceSwitcher = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    if let profile = deviceModeManager.currentProfile {
                        // Profile Photo
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                // Profile photo display
                                if let photoFileName = profile.profilePhotoFileName,
                                   let image = profilePhotoManager.loadProfilePhoto(fileName: photoFileName) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.blue, lineWidth: 3)
                                        )
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Text(String(profile.name.prefix(2)).uppercased())
                                                .font(.system(size: 40, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                }

                                Button(action: {
                                    showingProfilePhotoPicker = true
                                }) {
                                    Text(profile.profilePhotoFileName == nil ? "Add Photo" : "Change Photo")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 8)
                            Spacer()
                        }

                        // Parent name (editable)
                        Button(action: {
                            editedName = OnboardingManager.shared.parentName ?? ""
                            showingNameEditor = true
                        }) {
                            HStack {
                                Text("Name")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(OnboardingManager.shared.parentName ?? "Add name")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("Role")
                            Spacer()
                            Text(profile.mode.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Profile")
                }

                // Family section - different for parents and children
                if let household = householdService.currentHousehold,
                   let profile = deviceModeManager.currentProfile {

                    if profile.mode == .parent {
                        // PARENT VIEW: Show invite code
                        Section {
                            // Family Name
                            HStack {
                                Text("Family Name")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(household.name)
                                    .foregroundColor(.secondary)
                            }

                            // Invite Code
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Household Invite Code")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(household.inviteCode)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .tracking(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)

                                HStack(spacing: 12) {
                                    Button(action: {
                                        copyInviteCode(household.inviteCode)
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.on.doc")
                                            Text("Copy Code")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    }

                                    Button(action: {
                                        shareInviteCode(household.inviteCode, householdName: household.name)
                                    }) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Share Code")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 8)

                            if showCopiedMessage {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Code copied to clipboard!")
                                        .font(.subheadline)
                                }
                            }
                        } header: {
                            Text("Family")
                        } footer: {
                            Text("Share this code with family members to add them to your household")
                        }
                    } else {
                        // CHILD VIEW: Show family members
                        Section {
                            // Family Name
                            HStack {
                                Text("Family Name")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(household.name)
                                    .foregroundColor(.secondary)
                            }

                            // Family Members
                            ForEach(householdService.householdMembers, id: \.id) { member in
                                HStack(spacing: 12) {
                                    Image(systemName: member.role == "parent" ? "person.fill" : "person")
                                        .foregroundColor(member.role == "parent" ? .blue : .secondary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.fullName ?? "Family Member")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)

                                        Text(member.role.capitalized)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if member.age != nil {
                                        Text("Age \(member.age!)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Family")
                        }
                    }
                }

                Section {
                    // Appearance Mode Picker
                    HStack {
                        Image(systemName: "paintbrush.fill")
                        Text("Appearance")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { themeViewModel.selectedTheme },
                            set: { themeViewModel.selectTheme($0) }
                        )) {
                            ForEach(ThemeMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    NavigationLink(destination: ManageFamilyView()) {
                        Label("Manage Family", systemImage: "person.2")
                    }

                    NavigationLink(destination: ChangePasswordView()) {
                        Label("App Restriction Password", systemImage: "lock.shield")
                    }

                    NavigationLink(destination: Text("Notifications Settings")) {
                        Label("Notifications", systemImage: "bell")
                    }

                    Button(action: {
                        if let url = URL(string: "https://nd-ahl.github.io/Envive/privacy-policy") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        if let url = URL(string: "https://nd-ahl.github.io/Envive/terms-of-service") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Settings")
                }

                Section {
                    NavigationLink(destination: Text("Help & Support")) {
                        Label("Help", systemImage: "questionmark.circle")
                    }

                    NavigationLink(destination: Text("About")) {
                        Label("About", systemImage: "info.circle")
                    }
                } header: {
                    Text("Info")
                }

                // Developer/Testing tools - moved to bottom for discretion
                Section {
                    Toggle(isOn: $enableDeviceSwitcher) {
                        HStack {
                            Text("Device Switcher")
                                .font(.caption)
                            Spacer()
                        }
                        .foregroundColor(.secondary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))

                    Button(action: {
                        resetHelper.initiateReset()
                    }) {
                        HStack {
                            Text("Reset Onboarding")
                                .font(.caption)
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }

                    Button(action: {
                        // Force cleanup of test data
                        TestDataCleanupService.shared.forceCleanup()

                        // Show alert that cleanup is complete
                        let alert = UIAlertController(
                            title: "Test Data Cleaned",
                            message: "All legacy test data has been removed. The app will close.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            // Close the app
                            exit(0)
                        })

                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.windows.first?.rootViewController {
                            rootVC.present(alert, animated: true)
                        }
                    }) {
                        HStack {
                            Text("Clean Test Data")
                                .font(.caption)
                            Spacer()
                            Image(systemName: "trash")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }

                    Button(action: {
                        // Show all stored keys for debugging
                        TestDataCleanupService.shared.printAllStoredKeys()
                    }) {
                        HStack {
                            Text("Print Debug Keys")
                                .font(.caption)
                            Spacer()
                            Image(systemName: "terminal")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }

                    Button(action: {
                        // Fix profile household IDs
                        Task {
                            do {
                                try await HouseholdService.shared.fixProfileHouseholdIds()
                                print("✅ Profile household IDs fixed successfully")
                            } catch {
                                print("❌ Failed to fix profile household IDs: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            Text("Fix Profile IDs")
                                .font(.caption)
                            Spacer()
                            Image(systemName: "wrench")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }

                    Button(action: {
                        showingResetTestDataConfirmation = true
                    }) {
                        HStack {
                            Text("Reset All Test Data")
                                .font(.caption)
                            Spacer()
                            Image(systemName: "trash.circle")
                                .font(.caption2)
                        }
                        .foregroundColor(.red)
                    }
                } footer: {
                    Text("Developer tools")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Onboarding?", isPresented: $resetHelper.showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetHelper.performReset()
                }
            } message: {
                Text("This will reset the app and show the welcome screen again. The app will close.")
            }
            .sheet(isPresented: $showingProfilePhotoPicker) {
                if let profile = deviceModeManager.currentProfile {
                    ProfilePhotoPicker(
                        userId: profile.id,
                        currentPhotoFileName: profile.profilePhotoFileName,
                        onPhotoSelected: { fileName in
                            updateProfilePhoto(fileName: fileName)
                        }
                    )
                }
            }
            .alert("Edit Name", isPresented: $showingNameEditor) {
                TextField("Your name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    saveParentName(editedName)
                }
            } message: {
                Text("Enter your name")
            }
            .alert("Reset All Test Data", isPresented: $showingResetTestDataConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllTestData()
                }
            } message: {
                Text("This will delete all tasks, reset all children's XP to 0, and set credibility to 100. This action cannot be undone.")
            }
        }
        .navigationViewStyle(.stack)
    }

    private func updateProfilePhoto(fileName: String) {
        deviceModeManager.updateProfilePhoto(fileName: fileName.isEmpty ? nil : fileName)
    }

    private func copyInviteCode(_ code: String) {
        UIPasteboard.general.string = code

        withAnimation {
            showCopiedMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }

    private func shareInviteCode(_ code: String, householdName: String) {
        let message = """
        Join my household on Envive!

        Household: \(householdName)
        Invite Code: \(code)

        Download Envive and enter this code to join.
        """

        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func saveParentName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Save to UserDefaults
        UserDefaults.standard.set(trimmedName, forKey: "parentName")

        // Update in Supabase profile
        Task {
            guard let userId = authService.currentProfile?.id else { return }

            do {
                try await supabase
                    .from("profiles")
                    .update(["full_name": trimmedName])
                    .eq("id", value: userId)
                    .execute()

                print("✅ Parent name updated: \(trimmedName)")
            } catch {
                print("❌ Failed to update parent name: \(error.localizedDescription)")
            }
        }
    }

    private func resetAllTestData() {
        print("🗑️ Resetting all child data...")

        let taskService = DependencyContainer.shared.taskService
        let credibilityService = DependencyContainer.shared.credibilityService
        let xpService = DependencyContainer.shared.xpService

        // Load children from household
        Task {
            do {
                let children = try await householdService.getMyChildren()
                let childIds = children.compactMap { UUID(uuidString: $0.id) }

                // Reset data for each child
                for childId in childIds {
                    // Reset XP balance
                    xpService.resetBalance(userId: childId)
                    xpService.deleteAllTransactions(userId: childId)

                    // Reset credibility
                    credibilityService.resetCredibility(childId: childId)

                    // Clear ScreenTimeRewardManager storage
                    UserDefaults.standard.removeObject(forKey: "earnedScreenTimeMinutes_\(childId.uuidString)")
                    UserDefaults.standard.removeObject(forKey: "currentStreak_\(childId.uuidString)")
                    UserDefaults.standard.removeObject(forKey: "lastTaskCompletionDate_\(childId.uuidString)")
                }

                // Delete all task assignments
                taskService.deleteAllAssignments()

                print("✅ Reset complete - all tasks deleted, XP set to 0, credibility set to 100")
            } catch {
                print("❌ Error loading children for reset: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview

struct RootNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        RootNavigationView()
    }
}
