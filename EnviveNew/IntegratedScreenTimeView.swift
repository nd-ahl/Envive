import SwiftUI
import FamilyControls

struct IntegratedScreenTimeView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var appSelectionStore = AppSelectionStore()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var rewardManager = ScreenTimeRewardManager()

    @State private var isParentMode = false
    @State private var showingAppSelection = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with mode toggle
                    headerSection

                    if screenTimeManager.isAuthorized {
                        if isParentMode {
                            parentControlsSection
                        } else {
                            childControlsSection
                        }
                    } else {
                        authorizationSection
                    }
                }
                .padding()
            }
            .navigationTitle("Screen Time")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAppSelection) {
            NavigationView {
                AppSelectionView(selectedApps: $appSelectionStore.familyActivitySelection)
                    .navigationTitle("Select Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingAppSelection = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                appSelectionStore.saveSelection()
                                showingAppSelection = false
                            }
                            .fontWeight(.semibold)
                        }
                    }
            }
        }
        .onAppear {
            screenTimeManager.updateAuthorizationStatus()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Screen Time Management")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Control and earn screen time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Mode toggle
            HStack {
                Text("Mode:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Mode", selection: $isParentMode) {
                    Text("Child").tag(false)
                    Text("Parent").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var authorizationSection: some View {
        VStack(spacing: 16) {
            switch screenTimeManager.authorizationStatus {
            case .notDetermined:
                VStack(spacing: 16) {
                    Image(systemName: "hourglass.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Enable Screen Time Controls")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Grant permission to manage screen time and app usage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Enable Screen Time") {
                        Task {
                            try? await screenTimeManager.requestAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

            case .denied:
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Screen Time Access Denied")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    Text("Please enable Screen Time access in Settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .buttonStyle(.bordered)
                }

            case .approved:
                Text("Screen Time Authorized")
                    .font(.headline)
                    .foregroundColor(.green)

            @unknown default:
                EmptyView()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var parentControlsSection: some View {
        VStack(spacing: 20) {
            // App Management Section
            VStack(alignment: .leading, spacing: 16) {
                Text("App Management")
                    .font(.title3)
                    .fontWeight(.semibold)

                if appSelectionStore.hasSelectedApps {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Selected Items")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(appSelectionStore.selectedCount) items")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Status")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(settingsManager.isBlocking ? "Blocked" : "Allowed")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(settingsManager.isBlocking ? .red : .green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        HStack(spacing: 12) {
                            Button("Block Apps") {
                                settingsManager.blockApps(appSelectionStore.familyActivitySelection)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(settingsManager.isBlocking)

                            Button("Allow Apps") {
                                settingsManager.unblockApps()
                            }
                            .buttonStyle(.bordered)
                            .disabled(!settingsManager.isBlocking)
                        }
                    }
                }

                Button("Select Apps to Manage") {
                    showingAppSelection = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

            // Quick Controls Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Controls")
                    .font(.title3)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    quickControlButton(
                        title: "Study Mode",
                        subtitle: "30 min",
                        icon: "book.fill",
                        color: .blue
                    ) {
                        if appSelectionStore.hasSelectedApps {
                            settingsManager.blockApps(appSelectionStore.familyActivitySelection)
                        }
                    }

                    quickControlButton(
                        title: "Sleep Mode",
                        subtitle: "8 hours",
                        icon: "moon.fill",
                        color: .purple
                    ) {
                        if appSelectionStore.hasSelectedApps {
                            settingsManager.blockApps(appSelectionStore.familyActivitySelection)
                        }
                    }

                    quickControlButton(
                        title: "Family Time",
                        subtitle: "2 hours",
                        icon: "person.2.fill",
                        color: .green
                    ) {
                        if appSelectionStore.hasSelectedApps {
                            settingsManager.blockApps(appSelectionStore.familyActivitySelection)
                        }
                    }

                    quickControlButton(
                        title: "Stop All",
                        subtitle: "Remove",
                        icon: "stop.fill",
                        color: .red
                    ) {
                        settingsManager.unblockApps()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private var childControlsSection: some View {
        VStack(spacing: 20) {
            // Screen Time Status
            screenTimeStatusCard

            // Earned Time Management
            if rewardManager.isScreenTimeActive {
                activeSessionCard
            } else {
                earnedTimeCard
            }

            // XP Redemption
            xpRedemptionCard
        }
    }

    private var screenTimeStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "hourglass")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Screen Time Status")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if rewardManager.isScreenTimeActive {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Earned Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(rewardManager.formattedEarnedTime())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                Spacer()

                if rewardManager.isScreenTimeActive {
                    VStack(alignment: .trailing) {
                        Text("Session Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(rewardManager.formattedActiveTime())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var activeSessionCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("Session Active")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("End Session") {
                    rewardManager.endScreenTimeSession()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Apps are currently unlocked. Use your time wisely!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    private var earnedTimeCard: some View {
        VStack(spacing: 16) {
            if rewardManager.hasEarnedTime {
                VStack(spacing: 12) {
                    Text("Ready to start a session?")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("You have \(rewardManager.formattedEarnedTime()) of earned screen time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button("15 min") {
                            _ = rewardManager.startScreenTimeSession(durationMinutes: 15)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!rewardManager.canStartSession || rewardManager.earnedMinutes < 15)

                        Button("30 min") {
                            _ = rewardManager.startScreenTimeSession(durationMinutes: 30)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!rewardManager.canStartSession || rewardManager.earnedMinutes < 30)

                        Button("60 min") {
                            _ = rewardManager.startScreenTimeSession(durationMinutes: 60)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!rewardManager.canStartSession || rewardManager.earnedMinutes < 60)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "hourglass.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text("No Screen Time Available")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Complete tasks to earn screen time!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(rewardManager.hasEarnedTime ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((rewardManager.hasEarnedTime ? Color.blue : Color.orange).opacity(0.3), lineWidth: 1)
        )
    }

    private var xpRedemptionCard: some View {
        VStack(spacing: 16) {
            Text("Redeem XP for Screen Time")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Current XP: \(model.currentUser.totalXPEarned)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("100 XP → 10 min") {
                    _ = rewardManager.redeemXPForScreenTime(xpAmount: 100)
                    // TODO: Deduct XP from user model
                }
                .buttonStyle(.bordered)
                .disabled(model.currentUser.totalXPEarned < 100)

                Button("250 XP → 25 min") {
                    _ = rewardManager.redeemXPForScreenTime(xpAmount: 250)
                    // TODO: Deduct XP from user model
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.currentUser.totalXPEarned < 250)

                Button("500 XP → 50 min") {
                    _ = rewardManager.redeemXPForScreenTime(xpAmount: 500)
                    // TODO: Deduct XP from user model
                }
                .buttonStyle(.bordered)
                .disabled(model.currentUser.totalXPEarned < 500)
            }

            Text("Ratio: 10 XP = 1 minute of screen time")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func quickControlButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(!appSelectionStore.hasSelectedApps && title != "Stop All")
    }
}

struct IntegratedScreenTimeView_Previews: PreviewProvider {
    static var previews: some View {
        IntegratedScreenTimeView()
            .environmentObject(EnhancedScreenTimeModel())
    }
}