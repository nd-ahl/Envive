import Foundation

final class UserDefaultsStorage: StorageService {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? encoder.encode(value) {
            userDefaults.set(data, forKey: key)
        }
    }

    func load<T: Codable>(forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func saveInt(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func loadInt(forKey key: String, defaultValue: Int = 0) -> Int {
        let value = userDefaults.integer(forKey: key)
        return value == 0 && !userDefaults.objectExists(forKey: key) ? defaultValue : value
    }

    func saveBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func loadBool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: key)
    }

    func saveDate(_ value: Date, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func loadDate(forKey key: String) -> Date? {
        userDefaults.object(forKey: key) as? Date
    }

    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}

private extension UserDefaults {
    func objectExists(forKey key: String) -> Bool {
        object(forKey: key) != nil
    }
}
