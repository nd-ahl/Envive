import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @Binding var selectedApps: FamilyActivitySelection
    @State private var isPresentingPicker = false
    @State private var showingPermissionAlert = false
    @State private var isRequestingPermission = false

    private let authorizationCenter = AuthorizationCenter.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Activities")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            Text("Most used apps, categories, and websites")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                print("🎯 'Choose Apps and Websites' button tapped")
                checkPermissionAndShowPicker()
            }) {
                HStack {
                    if isRequestingPermission {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Requesting Permission...")
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Choose Apps and Websites")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .disabled(isRequestingPermission)
            .familyActivityPicker(
                isPresented: $isPresentingPicker,
                selection: $selectedApps
            )
            .onChange(of: isPresentingPicker) { newValue in
                print("🎯 FamilyActivityPicker presentation state changed to: \(newValue)")
            }
            .onChange(of: selectedApps) { newSelection in
                print("🎯 App selection changed - Apps: \(newSelection.applicationTokens.count), Categories: \(newSelection.categoryTokens.count), Websites: \(newSelection.webDomainTokens.count)")
            }

            if !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Items")
                        .font(.headline)

                    HStack {
                        if !selectedApps.applicationTokens.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Apps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(selectedApps.applicationTokens.count)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }

                        if !selectedApps.categoryTokens.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Categories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(selectedApps.categoryTokens.count)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }

                        if !selectedApps.webDomainTokens.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Websites")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(selectedApps.webDomainTokens.count)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top)
            }

            Spacer()
        }
        .padding(.horizontal)
        .alert("Screen Time Permission Required", isPresented: $showingPermissionAlert) {
            Button("Grant Permission", role: .none) {
                requestScreenTimePermission()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Envive needs Screen Time access to manage blocked apps. Tap 'Grant Permission' to enable this feature.")
        }
    }

    // MARK: - Permission Checking

    private func checkPermissionAndShowPicker() {
        let status = authorizationCenter.authorizationStatus

        switch status {
        case .approved:
            // Permission granted, show picker
            isPresentingPicker = true
            print("🎯 isPresentingPicker set to: \(isPresentingPicker)")
            print("✅ Screen Time permission approved - showing app picker")
        case .notDetermined, .denied:
            // Permission not granted, show alert
            showingPermissionAlert = true
            print("❌ Screen Time permission not granted - status: \(status)")
        @unknown default:
            showingPermissionAlert = true
            print("⚠️ Unknown Screen Time permission status")
        }
    }

    private func requestScreenTimePermission() {
        isRequestingPermission = true

        Task {
            do {
                try await authorizationCenter.requestAuthorization(for: .individual)

                await MainActor.run {
                    isRequestingPermission = false

                    // Check status again and show picker if approved
                    if authorizationCenter.authorizationStatus == .approved {
                        isPresentingPicker = true
                        print("✅ Screen Time permission granted - showing app picker")
                    } else {
                        print("❌ Screen Time permission denied after request")
                    }
                }
            } catch {
                await MainActor.run {
                    isRequestingPermission = false
                    print("❌ Screen Time permission request failed: \(error)")
                }
            }
        }
    }
}

struct AppSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        AppSelectionView(selectedApps: .constant(FamilyActivitySelection()))
    }
}