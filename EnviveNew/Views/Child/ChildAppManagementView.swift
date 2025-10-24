import SwiftUI
import FamilyControls

// MARK: - Child App Management View

/// Password-protected app management view accessible from child's device
/// Only parents can modify app selections after entering password
struct ChildAppManagementView: View {
    @StateObject private var passwordManager = ParentPasswordManager.shared
    @ObservedObject var appSelectionStore: AppSelectionStore
    @StateObject private var settingsManager = SettingsManager()

    @State private var showingPasswordPrompt = false
    @State private var showingPasswordSetup = false
    @State private var showingAppSelection = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with lock icon
                    headerSection

                    // Current app restrictions status
                    statusSection

                    // Manage button (requires password)
                    manageButtonSection

                    // Info section
                    infoSection
                }
                .padding()
            }
            .navigationTitle("App Restrictions")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Lock when view appears to ensure security
                passwordManager.lock()
                // Refresh blocking state to show current status
                settingsManager.refreshBlockingState()
            }
            .sheet(isPresented: $showingPasswordSetup) {
                ParentPasswordSetupView {
                    // After password is set, show app selection
                    showingAppSelection = true
                }
            }
            .sheet(isPresented: $showingPasswordPrompt) {
                ParentPasswordView {
                    // After successful authentication, show app selection
                    showingAppSelection = true
                }
            }
            .sheet(isPresented: $showingAppSelection) {
                NavigationView {
                    AppSelectionView(selectedApps: $appSelectionStore.familyActivitySelection)
                        .navigationTitle("Select Apps to Manage")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    showingAppSelection = false
                                    passwordManager.lock()
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Save") {
                                    appSelectionStore.saveSelection()
                                    showingAppSelection = false
                                    passwordManager.lock()
                                }
                                .fontWeight(.semibold)
                            }
                        }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Parent-Controlled Apps")
                .font(.title2)
                .fontWeight(.bold)

            Text("These settings can only be changed by a parent")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Status")
                .font(.headline)

            VStack(spacing: 12) {
                statusRow(
                    icon: "apps.iphone",
                    title: "Managed Apps",
                    value: appSelectionStore.hasSelectedApps ?
                        "\(appSelectionStore.selectedCount) items" : "None selected",
                    color: appSelectionStore.hasSelectedApps ? .blue : .gray
                )

                Divider()

                statusRow(
                    icon: "shield.fill",
                    title: "Restriction Status",
                    value: settingsManager.isBlocking ? "Active" : "Not Active",
                    color: settingsManager.isBlocking ? .orange : .green
                )

                if appSelectionStore.hasSelectedApps {
                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)

                        Text("When active, selected apps are blocked until you earn screen time through tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Manage Button Section

    private var manageButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                // Check if password is set
                if passwordManager.isPasswordSet {
                    // Show password prompt
                    showingPasswordPrompt = true
                } else {
                    // First time setup - show password creation
                    showingPasswordSetup = true
                }
            }) {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.title3)

                    Text("Manage App Restrictions")
                        .fontWeight(.semibold)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .foregroundColor(.blue)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            Text("Parent password required to modify")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                infoRow(
                    icon: "1.circle.fill",
                    text: "Parent selects which apps to manage",
                    color: .blue
                )

                infoRow(
                    icon: "2.circle.fill",
                    text: "Apps are blocked by default",
                    color: .orange
                )

                infoRow(
                    icon: "3.circle.fill",
                    text: "Complete tasks to earn screen time",
                    color: .green
                )

                infoRow(
                    icon: "4.circle.fill",
                    text: "Use earned time to access apps",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Views

    private func statusRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }

    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

struct ChildAppManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ChildAppManagementView(appSelectionStore: AppSelectionStore())
    }
}
