//
//  ThemeSettingsViewModel.swift
//  EnviveNew
//
//  ViewModel for theme settings UI
//

import SwiftUI
import Combine

// MARK: - ThemeSettingsViewModel

final class ThemeSettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedTheme: ThemeMode
    @Published var effectiveColorScheme: ColorScheme?

    // MARK: - Private Properties

    private let themeService: ThemeService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(themeService: ThemeService) {
        self.themeService = themeService
        self.selectedTheme = themeService.currentTheme
        self.effectiveColorScheme = themeService.currentColorScheme

        // Observe theme changes
        themeService.observeThemeChanges()
            .sink { [weak self] newTheme in
                self?.selectedTheme = newTheme
                self?.updateEffectiveColorScheme()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Select a new theme mode
    func selectTheme(_ mode: ThemeMode) {
        themeService.setTheme(mode)
        updateEffectiveColorScheme()
    }

    /// Get display text for current effective theme
    func effectiveThemeDescription() -> String {
        guard selectedTheme == .auto else {
            return selectedTheme.displayName
        }

        let isDark = effectiveColorScheme == .dark
        let timeBasedMode = isDark ? "Dark" : "Light"
        return "Auto (\(timeBasedMode))"
    }

    // MARK: - Private Helpers

    private func updateEffectiveColorScheme() {
        effectiveColorScheme = themeService.currentColorScheme
    }
}
