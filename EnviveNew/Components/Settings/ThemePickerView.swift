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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Appearance")
                .font(.headline)
                .foregroundColor(.primary)

            // Theme picker - icon-based 3-option selector
            Picker("Theme", selection: Binding(
                get: { viewModel.selectedTheme },
                set: { viewModel.selectTheme($0) }
            )) {
                Image(systemName: "sun.max.fill").tag(ThemeMode.light)
                Image(systemName: "circle.lefthalf.filled").tag(ThemeMode.auto)
                Image(systemName: "moon.fill").tag(ThemeMode.dark)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
