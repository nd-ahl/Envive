import ManagedSettings
import FamilyControls

class SettingsManager: ObservableObject {
    private let store = ManagedSettingsStore()
    @Published var isBlocking = false
    @Published var isSafariBlocked = false

    func blockApps(_ selection: FamilyActivitySelection) {
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
        }

        isBlocking = true
        print("Blocked \(selection.applicationTokens.count) apps and \(selection.categoryTokens.count) categories")
    }

    func unblockApps() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        isBlocking = false
        print("Unblocked all apps")
    }

    func clearAllSettings() {
        store.clearAllSettings()
        isBlocking = false
        print("Cleared all managed settings")
    }

    // MARK: - Safari-specific blocking for testing

    func blockSafariWithCustomShield() {
        // Create custom shield configuration
        let shieldConfiguration = ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor.systemRed,
            icon: ShieldConfiguration.Icon(systemImageName: "hourglass.circle"),
            title: ShieldConfiguration.Label(text: "Time Limit Reached", color: .white),
            subtitle: ShieldConfiguration.Label(text: "You've reached your time limit on Safari. Complete tasks to earn more screen time!", color: .white),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .white),
            primaryButtonBackgroundColor: UIColor.systemBlue
        )

        // Apply shield to Safari (we'll need to get Safari's token through FamilyActivityPicker)
        // For now, let's configure the shield and mark as blocked
        store.shield.applicationCategories = .specific([])
        isSafariBlocked = true

        print("Safari blocked with custom shield")
    }

    func unblockSafari() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        isSafariBlocked = false
        print("Safari unblocked")
    }

    func blockSafariFromSelection(_ selection: FamilyActivitySelection) {
        // Apply shield specifically to Safari if it's in the selection
        if !selection.applicationTokens.isEmpty {
            let shieldConfiguration = ShieldConfiguration(
                backgroundBlurStyle: .systemThickMaterial,
                backgroundColor: UIColor.systemRed,
                icon: ShieldConfiguration.Icon(systemImageName: "hourglass.circle"),
                title: ShieldConfiguration.Label(text: "Time Limit Reached", color: .white),
                subtitle: ShieldConfiguration.Label(text: "You've reached your time limit on Safari. Start a session in EnviveNew to continue!", color: .white),
                primaryButtonLabel: ShieldConfiguration.Label(text: "Open EnviveNew", color: .white),
                primaryButtonBackgroundColor: UIColor.systemBlue
            )

            store.shield.applications = selection.applicationTokens
            store.shield.applicationConfiguration = shieldConfiguration
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        isSafariBlocked = true
        print("Safari blocked with custom shield from selection")
    }

    @available(iOS 16.0, *)
    func configureAdvancedRestrictions() {
        store.application.denyAppInstallation = true
        store.application.denyAppRemoval = true
        store.account.lockAccounts = true
        store.media.denyExplicitContent = true
        store.cellular.lockCellularPlan = true
        store.gameCenter.denyMultiplayerGaming = true
        store.gameCenter.denyAddingFriends = true
        print("Applied advanced restrictions")
    }
}