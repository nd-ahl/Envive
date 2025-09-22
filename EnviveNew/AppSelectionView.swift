import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @Binding var selectedApps: FamilyActivitySelection
    @State private var isPresentingPicker = false

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
                isPresentingPicker = true
                print("🎯 isPresentingPicker set to: \(isPresentingPicker)")
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("Choose Apps and Websites")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
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
    }
}

struct AppSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        AppSelectionView(selectedApps: .constant(FamilyActivitySelection()))
    }
}