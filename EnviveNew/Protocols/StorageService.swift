import Foundation

protocol StorageService {
    func save<T: Codable>(_ value: T, forKey key: String)
    func load<T: Codable>(forKey key: String) -> T?
    func saveInt(_ value: Int, forKey key: String)
    func loadInt(forKey key: String, defaultValue: Int) -> Int
    func saveBool(_ value: Bool, forKey key: String)
    func loadBool(forKey key: String) -> Bool
    func saveDate(_ value: Date, forKey key: String)
    func loadDate(forKey key: String) -> Date?
    func remove(forKey key: String)
}
