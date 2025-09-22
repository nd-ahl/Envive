import SwiftUI
import FamilyControls

struct ParentControlView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @ObservedObject var appSelectionStore: AppSelectionStore
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var scheduler = ActivityScheduler()

    @State private var showingAppSelection = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                authorizationSection

                if screenTimeManager.isAuthorized {
                    ScrollView {
                        VStack(spacing: 20) {
                            appManagementSection
                            quickControlsSection
                            statusSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Screen Time Control")
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
    }

    private var authorizationSection: some View {
        Group {
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
                            do {
                                print("🔘 Button pressed - requesting authorization...")
                                try await screenTimeManager.requestAuthorization()
                                print("✅ Authorization request completed successfully")
                            } catch {
                                print("❌ Authorization request failed: \(error)")
                                print("❌ Error description: \(error.localizedDescription)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()

            case .denied:
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Screen Time Access Denied")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    Text("Please enable Screen Time access in Settings to use parental controls")
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
                .padding()

            case .approved:
                EmptyView()

            @unknown default:
                EmptyView()
            }
        }
    }

    private var appManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("App Management")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

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

            Button("Limit App or Website") {
                print("🎯 'Limit App or Website' button tapped")
                showingAppSelection = true
                print("🎯 showingAppSelection set to: \(showingAppSelection)")
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var quickControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Controls")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickControlButton(
                    title: "Study Mode",
                    subtitle: "30 minutes",
                    icon: "book.fill",
                    color: .blue
                ) {
                    if appSelectionStore.hasSelectedApps {
                        settingsManager.blockApps(appSelectionStore.familyActivitySelection)
                        scheduler.startTimerBasedRestrictions(durationMinutes: 30)
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
                        scheduler.startTimerBasedRestrictions(durationMinutes: 480)
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
                        scheduler.startTimerBasedRestrictions(durationMinutes: 120)
                    }
                }

                quickControlButton(
                    title: "Stop All",
                    subtitle: "Remove limits",
                    icon: "stop.fill",
                    color: .red
                ) {
                    scheduler.stopAllMonitoring()
                    settingsManager.unblockApps()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Status")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                statusRow(
                    title: "Monitoring",
                    value: scheduler.isMonitoring ? "Active" : "Inactive",
                    color: scheduler.isMonitoring ? .green : .gray
                )

                statusRow(
                    title: "Apps Blocked",
                    value: settingsManager.isBlocking ? "Yes" : "No",
                    color: settingsManager.isBlocking ? .red : .green
                )

                if appSelectionStore.hasSelectedApps {
                    statusRow(
                        title: "Managed Items",
                        value: "\(appSelectionStore.selectedCount)",
                        color: .blue
                    )
                }
            }
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

    private func statusRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct ParentControlView_Previews: PreviewProvider {
    static var previews: some View {
        ParentControlView(appSelectionStore: AppSelectionStore())
    }
}