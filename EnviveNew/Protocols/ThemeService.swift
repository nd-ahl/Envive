//
//  ThemeService.swift
//  EnviveNew
//
//  Protocol for managing app theme and color scheme
//

import SwiftUI
import Combine

// MARK: - ThemeMode

/// Represents the user's theme preference
enum ThemeMode: String, Codable, CaseIterable {
    case auto
    case light
    case dark

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .auto: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - ThemeService Protocol

/// Service for managing app theme preferences
protocol ThemeService {
    /// Current theme mode (auto, light, or dark)
    var currentTheme: ThemeMode { get }

    /// Current color scheme based on theme mode and time of day
    var currentColorScheme: ColorScheme? { get }

    /// Set the theme mode
    func setTheme(_ mode: ThemeMode)

    /// Observe theme changes
    func observeThemeChanges() -> AnyPublisher<ThemeMode, Never>
}
