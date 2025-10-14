import Foundation
import FamilyControls
import Combine

final class AppSelectionService: ObservableObject {
    @Published var familyActivitySelection = FamilyActivitySelection()

    private let repository: AppSelectionRepository

    init(repository: AppSelectionRepository) {
        self.repository = repository
        loadSelection()
    }

    func saveSelection() {
        repository.saveSelection(familyActivitySelection)
        print("Saved app selection: \(familyActivitySelection.applicationTokens.count) apps")
    }

    func loadSelection() {
        if let selection = repository.loadSelection() {
            familyActivitySelection = selection
            print("Loaded app selection: \(selection.applicationTokens.count) apps")
        } else {
            print("No saved app selection found")
        }
    }

    func clearSelection() {
        familyActivitySelection = FamilyActivitySelection()
        repository.clearSelection()
    }

    var hasSelectedApps: Bool {
        !familyActivitySelection.applicationTokens.isEmpty ||
        !familyActivitySelection.categoryTokens.isEmpty
    }

    var selectedCount: Int {
        familyActivitySelection.applicationTokens.count +
        familyActivitySelection.categoryTokens.count
    }
}
