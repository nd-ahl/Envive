import Foundation
import FamilyControls

protocol AppSelectionRepository {
    func saveSelection(_ selection: FamilyActivitySelection)
    func loadSelection() -> FamilyActivitySelection?
    func clearSelection()
}

final class AppSelectionRepositoryImpl: AppSelectionRepository {
    private let storage: StorageService
    private let selectionKey = "familyActivitySelection"

    init(storage: StorageService) {
        self.storage = storage
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        storage.save(selection, forKey: selectionKey)
    }

    func loadSelection() -> FamilyActivitySelection? {
        storage.load(forKey: selectionKey)
    }

    func clearSelection() {
        storage.remove(forKey: selectionKey)
    }
}
