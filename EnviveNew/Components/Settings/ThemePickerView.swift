//
//  ThemePickerView.swift
//  EnviveNew
//
//  UI component for selecting theme mode
//

import SwiftUI

// MARK: - ThemePickerView

struct ThemePickerView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: ThemeSettingsViewModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Appearance")
                .font(.headline)
                .foregroundColor(.primary)

            // Theme picker
            Picker("Theme", selection: Binding(
                get: { viewModel.selectedTheme },
                set: { viewModel.selectTheme($0) }
            )) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    HStack {
                        Image(systemName: mode.icon)
                        Text(mode.displayName)
                    }
                    .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Current effective theme display
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Current: \(viewModel.effectiveThemeDescription())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Auto mode description
            if viewModel.selectedTheme == .auto {
                Text("Auto switches to dark mode from 8:00 PM to 6:00 AM")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    let mockStorage = MockStorage()
    let repository = ThemeRepository(storage: mockStorage)
    let service = ThemeServiceImpl(repository: repository)
    let viewModel = ThemeSettingsViewModel(themeService: service)

    return ThemePickerView(viewModel: viewModel)
}
