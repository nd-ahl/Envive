import SwiftUI
import LocalAuthentication

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
                    parentId: deviceModeManager.currentProfile?.id ?? UUID(),
                    testChild1Id: deviceModeManager.getTestChild1Id(),
                    testChild2Id: deviceModeManager.getTestChild2Id(),
                    deviceModeManager: deviceModeManager
                ),
                appSelectionStore: model.appSelectionStore,
                notificationManager: model.notificationManager
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Dashboard")
            }
            .tag(0)

            // Screen Time Manager - Direct access to app controls
            AppManagementView(appSelectionStore: model.appSelectionStore)
                .tabItem {
                    Image(systemName: "hourglass")
                    Text("Screen Time")
                }
                .tag(1)

            // Children Overview/Management
            ParentChildrenView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Children")
                }
                .tag(2)

            // Activity/Reports
            ParentActivityView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Activity")
                }
                .tag(3)

            // Settings/Profile
            ParentProfileView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
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
                .badge(recentActivityCount)

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

            // Social
            SocialView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "heart.circle.fill")
                    Text("Social")
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

    /// Recent activity count for badge
    private var recentActivityCount: Int {
        model.friendActivities.filter { activity in
            Date().timeIntervalSince(activity.timestamp) < 3600
        }.count
    }

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

    @State private var showingProfilePhotoPicker = false

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

                        HStack {
                            Text("Name")
                            Spacer()
                            Text(profile.name)
                                .foregroundColor(.secondary)
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

                Section {
                    NavigationLink(destination: Text("Family Settings")) {
                        Label("Family", systemImage: "person.2")
                    }

                    NavigationLink(destination: Text("Notifications Settings")) {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink(destination: Text("Privacy Settings")) {
                        Label("Privacy", systemImage: "lock")
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

                Section {
                    Button(action: {
                        resetHelper.initiateReset()
                    }) {
                        Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Debug & Testing")
                } footer: {
                    Text("Reset onboarding to see the welcome screen again")
                        .font(.caption)
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
        }
    }

    private func updateProfilePhoto(fileName: String) {
        deviceModeManager.updateProfilePhoto(fileName: fileName.isEmpty ? nil : fileName)
    }
}

// MARK: - Preview

struct RootNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        RootNavigationView()
    }
}
