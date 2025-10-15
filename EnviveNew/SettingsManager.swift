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
        // PERFORMANCE FIX: Run asynchronously to prevent UI freeze
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            await MainActor.run {
                if !selection.applicationTokens.isEmpty {
                    self.store.shield.applications = selection.applicationTokens
                }

                if !selection.categoryTokens.isEmpty {
                    self.store.shield.applicationCategories = .specific(selection.categoryTokens)
                }

                if !selection.webDomainTokens.isEmpty {
                    self.store.shield.webDomains = selection.webDomainTokens
                }

                self.isBlocking = true
                print("Blocked \(selection.applicationTokens.count) apps and \(selection.categoryTokens.count) categories")
            }
        }
    }

    func unblockApps() {
        // PERFORMANCE FIX: Run asynchronously to prevent UI freeze
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            await MainActor.run {
                self.store.shield.applications = nil
                self.store.shield.applicationCategories = nil
                self.store.shield.webDomains = nil
                self.isBlocking = false
                print("Unblocked all apps")
            }
        }
    }

    func clearAllSettings() {
        // PERFORMANCE WARNING: clearAllSettings() is extremely slow (9-10 seconds)
        // Only use when absolutely necessary. Prefer clearing specific settings.
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            await MainActor.run {
                self.store.clearAllSettings()
                self.isBlocking = false
                print("Cleared all managed settings")
            }
        }
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