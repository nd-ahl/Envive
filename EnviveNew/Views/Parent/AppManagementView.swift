import SwiftUI
import FamilyControls
import ManagedSettings

// MARK: - App Management View

/// Dedicated view for managing blocked apps and websites
struct AppManagementView: View {
    @ObservedObject var appSelectionStore: AppSelectionStore
    @StateObject private var settingsManager = SettingsManager()

    @State private var isPresentingPicker = false
    @State private var tempSelection: FamilyActivitySelection
    @State private var showingSaveConfirmation = false
    @State private var showingClearConfirmation = false

    @Environment(\.dismiss) private var dismiss

    init(appSelectionStore: AppSelectionStore) {
        self.appSelectionStore = appSelectionStore
        _tempSelection = State(initialValue: appSelectionStore.familyActivitySelection)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection

                    // Current Selection Display
                    currentSelectionSection

                    // Action Buttons
                    actionButtonsSection

                    // Information Section
                    informationSection
                }
                .padding()
            }
            .navigationTitle("App Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        tempSelection = appSelectionStore.familyActivitySelection
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
            .sheet(isPresented: $isPresentingPicker) {
                NavigationView {
                    FamilyActivityPickerView(selection: $tempSelection)
                        .navigationTitle("Select Apps to Block")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    isPresentingPicker = false
                                }
                            }
                        }
                }
            }
            .alert("Changes Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Blocked apps have been updated successfully.")
            }
            .alert("Clear All Restrictions?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    clearAllRestrictions()
                }
            } message: {
                Text("This will remove all app and website restrictions. Children will have unrestricted access until you configure new restrictions.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Blocked Apps & Websites")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text("Select apps and websites that will be blocked when screen time sessions are not active")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Current Selection Section

    private var currentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Restrictions")
                .font(.headline)

            if tempSelection.applicationTokens.isEmpty && tempSelection.categoryTokens.isEmpty && tempSelection.webDomainTokens.isEmpty {
                emptyStateView
            } else {
                restrictionsSummaryView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Restrictions Set")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Tap 'Choose Apps to Block' to get started")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var restrictionsSummaryView: some View {
        VStack(spacing: 16) {
            if !tempSelection.applicationTokens.isEmpty {
                RestrictionRow(
                    icon: "app.fill",
                    title: "Apps",
                    count: tempSelection.applicationTokens.count,
                    color: .blue
                )
            }

            if !tempSelection.categoryTokens.isEmpty {
                RestrictionRow(
                    icon: "square.grid.3x3.fill",
                    title: "Categories",
                    count: tempSelection.categoryTokens.count,
                    color: .purple
                )
            }

            if !tempSelection.webDomainTokens.isEmpty {
                RestrictionRow(
                    icon: "globe",
                    title: "Websites",
                    count: tempSelection.webDomainTokens.count,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                isPresentingPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Choose Apps to Block")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            if appSelectionStore.hasSelectedApps {
                Button(action: {
                    showingClearConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Clear All Restrictions")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Information Section

    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.headline)

            InfoRow(
                icon: "lock.shield.fill",
                title: "Always Blocked",
                description: "Selected apps remain blocked until children earn screen time"
            )

            InfoRow(
                icon: "timer",
                title: "Session Access",
                description: "During active screen time sessions, children can access blocked apps"
            )

            InfoRow(
                icon: "person.2.fill",
                title: "Applies to All Children",
                description: "These restrictions apply to all children on this device"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Computed Properties

    private var hasChanges: Bool {
        tempSelection.applicationTokens != appSelectionStore.familyActivitySelection.applicationTokens ||
        tempSelection.categoryTokens != appSelectionStore.familyActivitySelection.categoryTokens ||
        tempSelection.webDomainTokens != appSelectionStore.familyActivitySelection.webDomainTokens
    }

    // MARK: - Actions

    private func saveChanges() {
        appSelectionStore.familyActivitySelection = tempSelection
        appSelectionStore.saveSelection()
        settingsManager.blockApps(tempSelection)
        showingSaveConfirmation = true
    }

    private func clearAllRestrictions() {
        tempSelection = FamilyActivitySelection()
        appSelectionStore.clearSelection()
        settingsManager.unblockApps()
    }
}

// MARK: - FamilyActivityPicker View

struct FamilyActivityPickerView: View {
    @Binding var selection: FamilyActivitySelection

    var body: some View {
        FamilyActivityPicker(selection: $selection)
    }
}

// MARK: - Supporting Components

struct RestrictionRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

struct AppManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AppManagementView(appSelectionStore: AppSelectionStore())
    }
}
