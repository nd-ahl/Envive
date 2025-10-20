import SwiftUI

// MARK: - Mode Switcher View

/// A view that allows switching between Parent and Child modes
/// For single-device testing during development
struct ModeSwitcherView: View {
    @ObservedObject var deviceModeManager: LocalDeviceModeManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMode: DeviceMode
    @State private var parentName: String = ""
    @State private var childName: String = ""
    @State private var showingConfirmation = false

    init(deviceModeManager: LocalDeviceModeManager) {
        self.deviceModeManager = deviceModeManager
        _selectedMode = State(initialValue: deviceModeManager.currentMode)

        // Load existing profile names if available
        if let profile = deviceModeManager.currentProfile {
            _parentName = State(initialValue: profile.mode == .parent ? profile.name : "Parent")
            _childName = State(initialValue: profile.mode == .child ? profile.name : "Child")
        } else {
            _parentName = State(initialValue: "Parent")
            _childName = State(initialValue: "Child")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Mode Selection
                    modeSelectionSection

                    // Name Input
                    nameInputSection

                    // Info Card
                    infoCard

                    // Switch Button
                    switchButton
                }
                .padding()
            }
            .navigationTitle("Device Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Mode Switched!", isPresented: $showingConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Now in \(selectedMode.displayName) mode")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.2.swap")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("Testing Mode Switcher")
                .font(.title2)
                .fontWeight(.bold)

            Text("Switch between Parent and Child roles for single-device testing")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Mode Selection

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Mode")
                .font(.headline)

            ForEach(DeviceMode.allCases, id: \.self) { mode in
                ModeSelectionCard(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    onSelect: {
                        selectedMode = mode
                    }
                )
            }
        }
    }

    // MARK: - Name Input Section

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter Name")
                .font(.headline)

            if selectedMode == .parent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Parent Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("e.g., Mom, Dad, John", text: $parentName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Child Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("e.g., Sarah, Alex", text: $childName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Development Feature")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("This mode switcher is for testing the parent-child workflow on a single device. In production, each device will have its own role synced via Firebase.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Switch Button

    private var switchButton: some View {
        Button(action: handleModeSwitch) {
            HStack {
                Image(systemName: selectedMode.icon)
                    .font(.title3)

                Text("Switch to \(selectedMode.displayName) Mode")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSwitch ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canSwitch)
    }

    // MARK: - Computed Properties

    private var canSwitch: Bool {
        let name = selectedMode == .parent ? parentName : childName
        return !name.trimmingCharacters(in: .whitespaces).isEmpty &&
               (selectedMode != deviceModeManager.currentMode ||
                name != deviceModeManager.currentProfile?.name)
    }

    // MARK: - Actions

    private func handleModeSwitch() {
        let name = selectedMode == .parent ? parentName : childName

        // Create new profile
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            mode: selectedMode
        )

        // Switch mode
        deviceModeManager.switchMode(to: selectedMode, profile: profile)

        // Show confirmation
        showingConfirmation = true
    }
}

// MARK: - Mode Selection Card

struct ModeSelectionCard: View {
    let mode: DeviceMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                        .frame(width: 50, height: 50)

                    Image(systemName: mode.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .primary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Switcher Button (Floating)

/// A floating button that can be added to any view to access the mode switcher
struct ModeSwitcherButton: View {
    @ObservedObject var deviceModeManager: LocalDeviceModeManager
    @ObservedObject private var deviceModeService = DeviceModeService.shared
    @State private var showingModeSwitcher = false
    @State private var showingLockedAlert = false

    // Position state - persisted between launches
    @AppStorage("modeSwitcherButtonX") private var buttonX: Double = 20
    @AppStorage("modeSwitcherButtonY") private var buttonY: Double = 100

    // Drag state
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        Button(action: {
            if !isDragging {
                if deviceModeService.isRoleLocked {
                    showingLockedAlert = true
                } else {
                    showingModeSwitcher = true
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: deviceModeManager.currentMode.icon)
                    .font(.caption)
                Text(deviceModeManager.currentMode.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                Image(systemName: deviceModeService.isRoleLocked ? "lock.fill" : "arrow.triangle.2.circlepath")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isDragging ? Color.blue.opacity(0.8) : (deviceModeService.isRoleLocked ? Color.gray : Color.blue))
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .position(x: buttonX + dragOffset.width, y: buttonY + dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    // Update final position
                    buttonX += value.translation.width
                    buttonY += value.translation.height

                    // Clamp to screen bounds (with some padding)
                    buttonX = max(60, min(buttonX, UIScreen.main.bounds.width - 60))
                    buttonY = max(60, min(buttonY, UIScreen.main.bounds.height - 100))

                    // Reset drag offset
                    dragOffset = .zero

                    // Small delay before allowing tap
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isDragging = false
                    }
                }
        )
        .sheet(isPresented: $showingModeSwitcher) {
            ModeSwitcherView(deviceModeManager: deviceModeManager)
        }
        .alert("Device Role Locked", isPresented: $showingLockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device's role has been locked to \(deviceModeService.deviceMode.displayName) mode. To change roles, reset onboarding from Settings.")
        }
    }
}

// MARK: - Preview

struct ModeSwitcherView_Previews: PreviewProvider {
    static var previews: some View {
        ModeSwitcherView(
            deviceModeManager: DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
        )
    }
}
