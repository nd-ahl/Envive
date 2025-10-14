import XCTest
@testable import EnviveNew

final class StorageServiceTests: XCTestCase {
    var mockStorage: MockStorage!

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
    }

    override func tearDown() {
        mockStorage.clear()
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Int Tests

    func testSaveAndLoadInt() {
        mockStorage.saveInt(42, forKey: "testInt")
        let loaded = mockStorage.loadInt(forKey: "testInt")
        XCTAssertEqual(loaded, 42)
    }

    func testLoadIntWithDefaultValue() {
        let loaded = mockStorage.loadInt(forKey: "nonexistent", defaultValue: 100)
        XCTAssertEqual(loaded, 100)
    }

    // MARK: - Bool Tests

    func testSaveAndLoadBool() {
        mockStorage.saveBool(true, forKey: "testBool")
        let loaded = mockStorage.loadBool(forKey: "testBool")
        XCTAssertTrue(loaded)
    }

    func testLoadBoolDefaultValue() {
        let loaded = mockStorage.loadBool(forKey: "nonexistent")
        XCTAssertFalse(loaded)
    }

    // MARK: - Date Tests

    func testSaveAndLoadDate() {
        let testDate = Date()
        mockStorage.saveDate(testDate, forKey: "testDate")
        let loaded = mockStorage.loadDate(forKey: "testDate")
        XCTAssertEqual(loaded, testDate)
    }

    func testLoadDateNonexistent() {
        let loaded = mockStorage.loadDate(forKey: "nonexistent")
        XCTAssertNil(loaded)
    }

    // MARK: - Codable Tests

    struct TestModel: Codable, Equatable {
        let name: String
        let value: Int
    }

    func testSaveAndLoadCodable() {
        let model = TestModel(name: "Test", value: 123)
        mockStorage.save(model, forKey: "testModel")
        let loaded: TestModel? = mockStorage.load(forKey: "testModel")
        XCTAssertEqual(loaded, model)
    }

    func testLoadCodableNonexistent() {
        let loaded: TestModel? = mockStorage.load(forKey: "nonexistent")
        XCTAssertNil(loaded)
    }

    // MARK: - Remove Tests

    func testRemove() {
        mockStorage.saveInt(42, forKey: "testKey")
        XCTAssertEqual(mockStorage.loadInt(forKey: "testKey", defaultValue: 0), 42)

        mockStorage.remove(forKey: "testKey")
        XCTAssertEqual(mockStorage.loadInt(forKey: "testKey", defaultValue: 0), 0)
    }

    // MARK: - Clear Tests

    func testClear() {
        mockStorage.saveInt(1, forKey: "key1")
        mockStorage.saveInt(2, forKey: "key2")
        mockStorage.saveBool(true, forKey: "key3")

        mockStorage.clear()

        XCTAssertEqual(mockStorage.loadInt(forKey: "key1", defaultValue: 0), 0)
        XCTAssertEqual(mockStorage.loadInt(forKey: "key2", defaultValue: 0), 0)
        XCTAssertFalse(mockStorage.loadBool(forKey: "key3"))
    }
}
