//
//  ThemeRepository.swift
//  EnviveNew
//
//  Repository for persisting theme preferences
//

import Foundation

// MARK: - ThemeRepository

/// Handles persistence of theme preferences
final class ThemeRepository {
    // MARK: - Properties

    private let storage: StorageService
    private let storageKey = "user_theme_preference"

    // MARK: - Initializer

    init(storage: StorageService) {
        self.storage = storage
    }

    // MARK: - Public Methods

    /// Save the user's theme preference
    func saveThemeMode(_ mode: ThemeMode) {
        storage.save(mode, forKey: storageKey)
    }

    /// Load the user's theme preference (defaults to .auto)
    func loadThemeMode() -> ThemeMode {
        guard let mode: ThemeMode = storage.load(forKey: storageKey) else {
            return .auto  // Default to auto mode
        }
        return mode
    }
}
