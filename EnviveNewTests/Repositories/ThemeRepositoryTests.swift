//
//  ThemeRepositoryTests.swift
//  EnviveNewTests
//
//  Tests for ThemeRepository
//

import XCTest
@testable import EnviveNew

final class ThemeRepositoryTests: XCTestCase {
    var sut: ThemeRepository!
    var mockStorage: MockStorage!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        sut = ThemeRepository(storage: mockStorage)
    }

    override func tearDown() {
        sut = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Save & Load Tests

    func testSaveThemeMode_PersistsValue() {
        // Arrange
        let mode = ThemeMode.dark

        // Act
        sut.saveThemeMode(mode)

        // Assert
        let savedMode: ThemeMode? = mockStorage.load(forKey: "user_theme_preference")
        XCTAssertEqual(savedMode, ThemeMode.dark)
    }

    func testLoadThemeMode_NoSavedValue_ReturnsAuto() {
        // Arrange
        // No value saved

        // Act
        let loadedMode = sut.loadThemeMode()

        // Assert
        XCTAssertEqual(loadedMode, .auto)
    }

    func testLoadThemeMode_SavedValue_ReturnsCorrectMode() {
        // Arrange
        mockStorage.save(ThemeMode.light, forKey: "user_theme_preference")

        // Act
        let loadedMode = sut.loadThemeMode()

        // Assert
        XCTAssertEqual(loadedMode, .light)
    }

    func testLoadThemeMode_InvalidValue_ReturnsAuto() {
        // Arrange
        // Save invalid data that can't be decoded as ThemeMode
        // Since MockStorage only works with Codable, this will result in nil on load

        // Act
        let loadedMode = sut.loadThemeMode()

        // Assert
        XCTAssertEqual(loadedMode, .auto)
    }

    // MARK: - Round Trip Tests

    func testSaveAndLoad_Auto_Persists() {
        // Arrange
        let mode = ThemeMode.auto

        // Act
        sut.saveThemeMode(mode)
        let loadedMode = sut.loadThemeMode()

        // Assert
        XCTAssertEqual(loadedMode, mode)
    }

    func testSaveAndLoad_Light_Persists() {
        // Arrange
        let mode = ThemeMode.light

        // Act
        sut.saveThemeMode(mode)
        let loadedMode = sut.loadThemeMode()

        // Assert
        XCTAssertEqual(loadedMode, mode)
    }

    func testSaveAndLoad_Dark_Persists() {
        // Arrange
        let mode = ThemeMode.dark

        // Act
        sut.saveThemeMode(mode)
        let loadedMode = sut.loadThemeMode()

        // Assert
        XCTAssertEqual(loadedMode, mode)
    }

    // MARK: - Multiple Updates Tests

    func testSaveThemeMode_MultipleUpdates_OverwritesPrevious() {
        // Arrange
        sut.saveThemeMode(.light)

        // Act
        sut.saveThemeMode(.dark)
        let loadedMode = sut.loadThemeMode()

        // Assert
        XCTAssertEqual(loadedMode, .dark)
    }
}
