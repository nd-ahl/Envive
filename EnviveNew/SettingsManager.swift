import ManagedSettings
import FamilyControls
import Combine
import UIKit
import SwiftUI

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
        // This function is deprecated - Safari blocking requires proper app selection
        // Users must use the FamilyActivityPicker to select Safari and other apps
        print("⚠️ Safari blocking requires app selection via FamilyActivityPicker. Use 'Limit App or Website' button instead.")
        print("⚠️ Empty category blocking doesn't work - you need actual app tokens from selection.")
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
            store.shield.applications = selection.applicationTokens
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        isSafariBlocked = true
        print("Safari blocked from selection")
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