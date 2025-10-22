import SwiftUI

// MARK: - Mode Switcher View

/// A view that allows switching between Parent and Child modes
/// For single-device testing during development
/// NOW WITH SUPABASE: Fetches children from Supabase database
struct ModeSwitcherView: View {
    @ObservedObject var deviceModeManager: LocalDeviceModeManager
    @ObservedObject var householdService = HouseholdService.shared
    @ObservedObject var authService = AuthenticationService.shared
    @ObservedObject var householdContext = HouseholdContext.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMode: DeviceMode
    @State private var parentName: String = ""
    @State private var selectedChildId: String? = nil
    @State private var showingConfirmation = false
    @State private var availableChildren: [Profile] = [] // Supabase Profile, not UserProfile
    @State private var isLoadingChildren = false
    @State private var savedParentName: String = "" // Store parent name when switching to child

    init(deviceModeManager: LocalDeviceModeManager) {
        self.deviceModeManager = deviceModeManager
        _selectedMode = State(initialValue: deviceModeManager.currentMode)

        // Load parent name from actual authenticated profile (best source)
        let authName = AuthenticationService.shared.currentProfile?.fullName ?? ""

        // Fallback to device manager or onboarding
        let parentProfile = deviceModeManager.getProfile(byMode: .parent)
        let savedName = parentProfile?.name ?? ""
        let onboardingName = OnboardingManager.shared.parentName ?? ""

        // Priority: AuthenticationService > DeviceManager > OnboardingManager
        let finalName = !authName.isEmpty ? authName : (!savedName.isEmpty ? savedName : onboardingName)

        _parentName = State(initialValue: finalName)
        _savedParentName = State(initialValue: finalName)

        print("🎯 ModeSwitcher initialized with parent name: '\(finalName)' (from auth: '\(authName)', saved: '\(savedName)', onboarding: '\(onboardingName)')")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Household Info
                    if deviceModeManager.isParentMode() {
                        householdInfoSection
                    }

                    // Mode Selection
                    modeSelectionSection

                    // Child or Parent Selection
                    if selectedMode == .parent {
                        parentInputSection
                    } else {
                        childSelectionSection
                    }

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
            .onAppear {
                loadAvailableChildren()

                // Use actual parent name from AuthenticationService first
                let actualParentName = authService.currentProfile?.fullName ?? ""

                if !actualParentName.isEmpty {
                    // Use the real parent name from auth
                    savedParentName = actualParentName
                    if parentName.isEmpty || deviceModeManager.isChildMode() {
                        parentName = actualParentName
                    }
                } else if let savedName = UserDefaults.standard.string(forKey: "savedParentName"),
                          !savedName.isEmpty {
                    // Fallback to UserDefaults
                    savedParentName = savedName
                    if deviceModeManager.isChildMode() && selectedMode == .parent {
                        parentName = savedName
                    } else if parentName.isEmpty {
                        parentName = savedName
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

    // MARK: - Household Info Section

    private var householdInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.blue)
                Text("Current Household")
                    .font(.headline)
            }

            if isLoadingChildren {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading children...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } else if availableChildren.isEmpty {
                Text("No children in household yet. Create child profiles during onboarding to see them here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                Text("\(availableChildren.count) child(ren) in household:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(availableChildren) { child in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.green)
                        Text(child.fullName ?? "Unknown")
                            .font(.subheadline)
                        if let age = child.age {
                            Text("(age \(age))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Mode Selection

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Mode")
                .font(.headline)

            // Parent mode button
            Button(action: {
                selectedMode = .parent
                selectedChildId = nil

                // Restore saved parent name when selecting parent mode
                if parentName.isEmpty && !savedParentName.isEmpty {
                    parentName = savedParentName
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(selectedMode == .parent ? Color.blue : Color(.systemGray5))
                            .frame(width: 50, height: 50)

                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundColor(selectedMode == .parent ? .white : .primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Parent")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Manage tasks, approve completions, and monitor children")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if selectedMode == .parent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(selectedMode == .parent ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedMode == .parent ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)

            // Child mode button
            Button(action: {
                selectedMode = .child1
                if !availableChildren.isEmpty && selectedChildId == nil {
                    selectedChildId = availableChildren[0].id
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(selectedMode == .child1 ? Color.blue : Color(.systemGray5))
                            .frame(width: 50, height: 50)

                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundColor(selectedMode == .child1 ? .white : .primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Child")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Complete tasks and earn screen time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if selectedMode == .child1 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(selectedMode == .child1 ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedMode == .child1 ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Parent Input Section

    private var parentInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parent Name")
                .font(.headline)

            TextField("e.g., Mom, Dad, John", text: $parentName)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.words)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Child Selection Section

    private var childSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Child")
                .font(.headline)

            if isLoadingChildren {
                HStack {
                    ProgressView()
                    Text("Loading children...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if availableChildren.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No children available")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Add children during onboarding to switch to child mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(availableChildren) { child in
                    Button(action: {
                        selectedChildId = child.id
                    }) {
                        HStack {
                            Image(systemName: selectedChildId == child.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(selectedChildId == child.id ? .blue : .gray)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(child.fullName ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                if let age = child.age {
                                    Text("Age \(age)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(selectedChildId == child.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
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
        if selectedMode == .parent {
            return !parentName.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            // For child mode, must have a child selected
            return selectedChildId != nil
        }
    }

    // MARK: - Actions

    private func handleModeSwitch() {
        if selectedMode == .parent {
            // Use actual parent name from AuthenticationService if available
            let actualParentName = authService.currentProfile?.fullName ?? ""
            let trimmedName = !actualParentName.isEmpty ? actualParentName : parentName.trimmingCharacters(in: .whitespaces)

            // Get existing parent profile to preserve photo
            let existingParentProfile = deviceModeManager.getProfile(byMode: .parent)
            let parentId = authService.currentProfile.flatMap { UUID(uuidString: $0.id) } ?? UUID()

            let parentProfile = UserProfile(
                id: parentId,
                name: trimmedName,
                mode: .parent,
                age: nil,
                parentId: nil,
                profilePhotoFileName: existingParentProfile?.profilePhotoFileName
            )

            deviceModeManager.switchMode(to: .parent, profile: parentProfile)

            // Clear current child ID from HouseholdContext
            householdContext.clearCurrentChild()

            // Save parent name for future switches
            savedParentName = trimmedName
            UserDefaults.standard.set(trimmedName, forKey: "savedParentName")

            // Update UserDefaults for ProfileView
            UserDefaults.standard.set(trimmedName, forKey: "userName")

            print("🔄 Switched to Parent mode: \(trimmedName), Photo: \(existingParentProfile?.profilePhotoFileName ?? "none")")
        } else if let childId = selectedChildId,
                  let child = availableChildren.first(where: { $0.id == childId }) {
            // Before switching to child, save current parent name
            let actualParentName = authService.currentProfile?.fullName ?? ""
            if !actualParentName.isEmpty {
                savedParentName = actualParentName
                UserDefaults.standard.set(actualParentName, forKey: "savedParentName")
            } else if !savedParentName.isEmpty {
                UserDefaults.standard.set(savedParentName, forKey: "savedParentName")
            } else if !parentName.trimmingCharacters(in: .whitespaces).isEmpty {
                savedParentName = parentName.trimmingCharacters(in: .whitespaces)
                UserDefaults.standard.set(savedParentName, forKey: "savedParentName")
            }

            // Switch to child mode
            let childName = child.fullName ?? "Child"
            let childAge = child.age ?? 0
            let childUUID = UUID(uuidString: child.id) ?? UUID()

            // Get existing child profile to preserve photo
            let existingChildProfile = deviceModeManager.getProfile(byId: childUUID)

            let childProfile = UserProfile(
                id: childUUID,
                name: childName,
                mode: .child1,
                age: childAge,
                parentId: authService.currentProfile.flatMap { UUID(uuidString: $0.id) },
                profilePhotoFileName: existingChildProfile?.profilePhotoFileName
            )

            deviceModeManager.switchMode(to: .child1, profile: childProfile)

            // Set current child ID in HouseholdContext for task filtering
            householdContext.setCurrentChild(childUUID)

            // Update UserDefaults for ProfileView to show child's name and age
            UserDefaults.standard.set(childName, forKey: "userName")
            UserDefaults.standard.set(childAge, forKey: "userAge")

            print("🔄 Switched to Child mode: \(childName), Age: \(childAge), ID: \(childUUID), Photo: \(existingChildProfile?.profilePhotoFileName ?? "none")")
        }

        // Reload household children to ensure task filtering works correctly
        householdContext.reloadHouseholdChildren()

        // Post notification to update UI
        NotificationCenter.default.post(name: NSNotification.Name("DeviceModeChanged"), object: nil)

        // Show confirmation
        showingConfirmation = true
    }

    private func loadAvailableChildren() {
        isLoadingChildren = true

        Task {
            do {
                // Fetch children from Supabase
                let children = try await householdService.getMyChildren()

                await MainActor.run {
                    availableChildren = children
                    isLoadingChildren = false
                }

                print("👶 Loaded \(children.count) children from Supabase")
            } catch {
                print("❌ Error loading children: \(error.localizedDescription)")
                await MainActor.run {
                    availableChildren = []
                    isLoadingChildren = false
                }
            }
        }
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

    /// Display name showing actual profile name if available
    private var currentDisplayName: String {
        deviceModeManager.currentProfile?.name ?? deviceModeManager.currentMode.displayName
    }

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
                Text(currentDisplayName)
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
