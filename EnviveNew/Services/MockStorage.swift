import Foundation

final class MockStorage: StorageService {
    private var storage: [String: Any] = [:]

    func save<T: Codable>(_ value: T, forKey key: String) {
        storage[key] = value
    }

    func load<T: Codable>(forKey key: String) -> T? {
        storage[key] as? T
    }

    func saveInt(_ value: Int, forKey key: String) {
        storage[key] = value
    }

    func loadInt(forKey key: String, defaultValue: Int = 0) -> Int {
        (storage[key] as? Int) ?? defaultValue
    }

    func saveBool(_ value: Bool, forKey key: String) {
        storage[key] = value
    }

    func loadBool(forKey key: String) -> Bool {
        (storage[key] as? Bool) ?? false
    }

    func saveDate(_ value: Date, forKey key: String) {
        storage[key] = value
    }

    func loadDate(forKey key: String) -> Date? {
        storage[key] as? Date
    }

    func remove(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func clear() {
        storage.removeAll()
    }
}
