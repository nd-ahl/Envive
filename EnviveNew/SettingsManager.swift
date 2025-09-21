import ManagedSettings
import FamilyControls

class SettingsManager: ObservableObject {
    private let store = ManagedSettingsStore()
    @Published var isBlocking = false

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