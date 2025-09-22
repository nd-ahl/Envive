import Foundation
import FamilyControls
import Combine

class AppSelectionStore: ObservableObject {
    @Published var familyActivitySelection = FamilyActivitySelection()

    private let userDefaults = UserDefaults(suiteName: "group.com.neal.envivenew.screentime")
    private let selectionKey = "familyActivitySelection"

    init() {
        loadSelection()
    }

    func saveSelection() {
        if let encoded = try? JSONEncoder().encode(familyActivitySelection) {
            userDefaults?.set(encoded, forKey: selectionKey)
            print("Saved app selection: \(familyActivitySelection.applicationTokens.count) apps")
        }
    }

    func loadSelection() {
        guard let data = userDefaults?.data(forKey: selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("No saved app selection found")
            return
        }
        familyActivitySelection = selection
        print("Loaded app selection: \(familyActivitySelection.applicationTokens.count) apps")
    }

    func clearSelection() {
        familyActivitySelection = FamilyActivitySelection()
        userDefaults?.removeObject(forKey: selectionKey)
    }

    var hasSelectedApps: Bool {
        !familyActivitySelection.applicationTokens.isEmpty ||
        !familyActivitySelection.categoryTokens.isEmpty
    }

    var selectedCount: Int {
        familyActivitySelection.applicationTokens.count + familyActivitySelection.categoryTokens.count
    }
}