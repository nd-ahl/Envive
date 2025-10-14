import SwiftUI

/// Main navigation view - clean and minimal
struct EnviveMainView: View {
    @StateObject private var model = EnhancedScreenTimeModel()
    @State private var selectedTab = 0
    @State private var showingNotificationSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            EnhancedHomeView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                .badge(recentActivityCount)

            EnhancedTasksView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Tasks")
                }
                .tag(1)

            SocialView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "heart.circle.fill")
                    Text("Social")
                }
                .tag(2)

            ParentControlView(appSelectionStore: model.appSelectionStore)
                .tabItem {
                    Image(systemName: "person.2.badge.gearshape")
                    Text("Parental Controls")
                }
                .tag(3)

            PhotoGalleryView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Photos")
                }
                .tag(4)
                .badge(photoCount)

            ProfileView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(5)

            CredibilityTestingView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Credibility")
                }
                .tag(6)
        }
        .onAppear(perform: handleAppAppear)
        .onChange(of: scenePhase, handleScenePhaseChange)
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
    }

    // MARK: - Computed Properties

    private var recentActivityCount: Int {
        model.friendActivities.filter { activity in
            Date().timeIntervalSince(activity.timestamp) < 3600
        }.count
    }

    private var photoCount: Int {
        model.cameraManager.savedPhotos.count
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
