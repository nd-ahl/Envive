import ManagedSettings
import FamilyControls
import Combine
import UIKit
import SwiftUI

class SettingsManager: ObservableObject {
    // PERFORMANCE FIX: Use shared store to sync with extensions
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("envive-shared"))
    @Published var isBlocking = false
    @Published var isSafariBlocked = false

    init() {
        // Check initial blocking state
        updateBlockingState()
    }

    /// Check if apps are currently being blocked
    private func updateBlockingState() {
        // Check if any shields are set in the store
        let hasShields = (store.shield.applications != nil && !store.shield.applications!.isEmpty) ||
                        (store.shield.applicationCategories != nil) ||
                        (store.shield.webDomains != nil && !store.shield.webDomains!.isEmpty)

        isBlocking = hasShields
    }

    func blockApps(_ selection: FamilyActivitySelection) {
        // PERFORMANCE FIX: Run on background thread to prevent UI freeze
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Apply shields on background thread
            if !selection.applicationTokens.isEmpty {
                self.store.shield.applications = selection.applicationTokens
            }

            if !selection.categoryTokens.isEmpty {
                self.store.shield.applicationCategories = .specific(selection.categoryTokens)
            }

            if !selection.webDomainTokens.isEmpty {
                self.store.shield.webDomains = selection.webDomainTokens
            }

            print("✅ Blocked \(selection.applicationTokens.count) apps and \(selection.categoryTokens.count) categories")

            // Update UI state on main thread
            DispatchQueue.main.async {
                self.updateBlockingState()
            }
        }
    }

    func unblockApps() {
        // PERFORMANCE FIX: Run on background thread to prevent UI freeze
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Clear shields on background thread
            self.store.shield.applications = nil
            self.store.shield.applicationCategories = nil
            self.store.shield.webDomains = nil

            print("✅ Unblocked all apps")

            // Update UI state on main thread
            DispatchQueue.main.async {
                self.updateBlockingState()
            }
        }
    }

    func clearAllSettings() {
        // PERFORMANCE WARNING: clearAllSettings() is extremely slow (9-10 seconds)
        // Only use when absolutely necessary. Prefer using unblockApps() instead.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            print("⚠️ clearAllSettings() called - this takes 9-10 seconds")
            self.store.clearAllSettings()
            print("✅ Cleared all managed settings")

            // Update UI state on main thread
            DispatchQueue.main.async {
                self.updateBlockingState()
            }
        }
    }

    /// Public method to refresh blocking state
    func refreshBlockingState() {
        updateBlockingState()
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