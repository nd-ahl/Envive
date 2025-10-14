//
//  ThemeServiceImpl.swift
//  EnviveNew
//
//  Service implementation for managing app theme with time-based auto mode
//

import SwiftUI
import Combine

// MARK: - ThemeServiceImpl

final class ThemeServiceImpl: ThemeService {
    // MARK: - Properties

    private let repository: ThemeRepository
    private let themeSubject = CurrentValueSubject<ThemeMode, Never>(.auto)

    // Time thresholds for auto mode (24-hour format)
    private let darkModeStartHour = 20  // 8:00 PM
    private let darkModeEndHour = 6     // 6:00 AM

    var currentTheme: ThemeMode {
        themeSubject.value
    }

    var currentColorScheme: ColorScheme? {
        calculateColorScheme(for: currentTheme)
    }

    // MARK: - Initializer

    init(repository: ThemeRepository) {
        self.repository = repository

        // Load saved theme preference
        let savedTheme = repository.loadThemeMode()
        themeSubject.send(savedTheme)
    }

    // MARK: - Public Methods

    func setTheme(_ mode: ThemeMode) {
        repository.saveThemeMode(mode)
        themeSubject.send(mode)
    }

    func observeThemeChanges() -> AnyPublisher<ThemeMode, Never> {
        themeSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Helpers

    /// Calculate color scheme based on theme mode
    private func calculateColorScheme(for mode: ThemeMode) -> ColorScheme? {
        switch mode {
        case .auto:
            return isDarkTime() ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    /// Determine if current time falls within dark mode hours
    /// Dark mode: 8:00 PM (20:00) to 6:00 AM (06:00)
    private func isDarkTime() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        // Dark time is from 8 PM to 6 AM
        // This spans midnight, so we check if hour >= 20 OR hour < 6
        return hour >= darkModeStartHour || hour < darkModeEndHour
    }
}
