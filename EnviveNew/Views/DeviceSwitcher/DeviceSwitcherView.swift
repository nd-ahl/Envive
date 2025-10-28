import SwiftUI

// MARK: - Device Switcher View

/// A floating button UI for switching between parent and child modes during testing
/// This allows developers and testers to quickly switch perspectives without signing out
struct DeviceSwitcherView: View {
    @StateObject private var deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var householdService = HouseholdService.shared

    @State private var isExpanded = false
    @State private var showingChildSelector = false
    @State private var availableChildren: [Profile] = []
    @State private var isLoading = false

    // Testing mode flag - disabled by default, enable via settings if needed
    @AppStorage("enableDeviceSwitcher") private var enableDeviceSwitcher = false

    var body: some View {
        ZStack {
            if enableDeviceSwitcher {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        switcherButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 100)
                    }
                }
                .zIndex(999) // Ensure it's always on top
            }
        }
        .sheet(isPresented: $showingChildSelector) {
            ChildProfileSelectorSheet(
                children: availableChildren,
                onSelect: { child in
                    switchToChildMode(child)
                }
            )
        }
    }

    // MARK: - Switcher Button

    private var switcherButton: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedMenu
                    .transition(.scale.combined(with: .opacity))
            }

            // Main toggle button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.purple.gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: isExpanded ? "xmark" : "arrow.triangle.2.circlepath")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
            }
        }
    }

    // MARK: - Expanded Menu

    private var expandedMenu: some View {
        VStack(spacing: 12) {
            // Current mode indicator
            HStack {
                Image(systemName: deviceModeManager.isParentMode() ? "person.2.fill" : "person.fill")
                    .font(.caption)
                Text("Mode: \(deviceModeManager.currentMode.displayName)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Switch to Parent button
            if deviceModeManager.isChildMode() {
                switchButton(
                    icon: "person.2.fill",
                    title: "Parent",
                    color: .blue,
                    action: switchToParentMode
                )
            }

            // Switch to Child button(s)
            if deviceModeManager.isParentMode() {
                switchButton(
                    icon: "person.fill",
                    title: "Child",
                    color: .green,
                    action: loadChildrenAndShowSelector
                )
            }
        }
        .padding(.bottom, 12)
    }

    private func switchButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color.gradient)
            .cornerRadius(20)
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Switch Actions

    private func switchToParentMode() {
        withAnimation {
            isExpanded = false
        }

        guard let currentProfile = authService.currentProfile else {
            print("❌ No current profile - cannot switch")
            return
        }

        // Create a UserProfile from the Supabase Profile
        let parentProfile = UserProfile(
            id: UUID(uuidString: currentProfile.id) ?? UUID(),
            name: currentProfile.fullName ?? "Parent",
            mode: .parent,
            age: nil,
            parentId: nil,
            profilePhotoFileName: nil
        )

        deviceModeManager.switchMode(to: .parent, profile: parentProfile)

        print("🔄 Switched to Parent mode")

        // Post notification to update UI
        NotificationCenter.default.post(name: NSNotification.Name("DeviceModeChanged"), object: nil)
    }

    private func loadChildrenAndShowSelector() {
        isLoading = true

        Task {
            do {
                // Fetch children from Supabase
                let children = try await householdService.getMyChildren()

                await MainActor.run {
                    availableChildren = children
                    isLoading = false

                    if children.isEmpty {
                        print("⚠️ No children found - cannot switch to child mode")
                        withAnimation {
                            isExpanded = false
                        }
                    } else if children.count == 1 {
                        // Only one child - switch directly
                        switchToChildMode(children[0])
                    } else {
                        // Multiple children - show selector
                        showingChildSelector = true
                    }
                }
            } catch {
                print("❌ Error loading children: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        isExpanded = false
                    }
                }
            }
        }
    }

    private func switchToChildMode(_ child: Profile) {
        withAnimation {
            isExpanded = false
            showingChildSelector = false
        }

        // Create a UserProfile from the Supabase Profile
        let childProfile = UserProfile(
            id: UUID(uuidString: child.id) ?? UUID(),
            name: child.fullName ?? "Child",
            mode: .child1, // Use child1 for simplicity
            age: child.age,
            parentId: authService.currentProfile.flatMap { UUID(uuidString: $0.id) },
            profilePhotoFileName: nil
        )

        deviceModeManager.switchMode(to: .child1, profile: childProfile)

        print("🔄 Switched to Child mode: \(child.fullName ?? "Unknown")")

        // Post notification to update UI
        NotificationCenter.default.post(name: NSNotification.Name("DeviceModeChanged"), object: nil)
    }
}

// MARK: - Child Profile Selector Sheet

struct ChildProfileSelectorSheet: View {
    let children: [Profile]
    let onSelect: (Profile) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.crop.square.stack")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)

                        Text("Select Child Profile")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Switch to a child's perspective")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Children list
                    ForEach(children) { child in
                        Button(action: {
                            onSelect(child)
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                // Avatar
                                if let avatarUrl = child.avatarUrl {
                                    AsyncImage(url: URL(string: avatarUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.purple.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Text(child.fullName?.prefix(1) ?? "?")
                                                .font(.title2)
                                                .foregroundColor(.purple)
                                        }
                                }

                                // Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(child.fullName ?? "Unknown")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    if let age = child.age {
                                        Text("Age \(age)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct DeviceSwitcherView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()

            DeviceSwitcherView()
        }
    }
}
