//
//  ThemeServiceTests.swift
//  EnviveNewTests
//
//  Tests for ThemeServiceImpl
//

import XCTest
import SwiftUI
import Combine
@testable import EnviveNew

final class ThemeServiceTests: XCTestCase {
    var sut: ThemeServiceImpl!
    var mockStorage: MockStorage!
    var repository: ThemeRepository!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        repository = ThemeRepository(storage: mockStorage)
        sut = ThemeServiceImpl(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_DefaultsToAutoMode() {
        // Arrange & Act
        // Service created in setUp

        // Assert
        XCTAssertEqual(sut.currentTheme, .auto)
    }

    func testInit_LoadsSavedTheme() {
        // Arrange
        mockStorage.save(ThemeMode.light, forKey: "user_theme_preference")

        // Act
        let service = ThemeServiceImpl(repository: repository)

        // Assert
        XCTAssertEqual(service.currentTheme, .light)
    }

    // MARK: - Set Theme Tests

    func testSetTheme_UpdatesCurrentTheme() {
        // Arrange
        XCTAssertEqual(sut.currentTheme, .auto)

        // Act
        sut.setTheme(.dark)

        // Assert
        XCTAssertEqual(sut.currentTheme, .dark)
    }

    func testSetTheme_PersistsToStorage() {
        // Arrange
        // Initial state

        // Act
        sut.setTheme(.light)

        // Assert
        let savedMode: ThemeMode? = mockStorage.load(forKey: "user_theme_preference")
        XCTAssertEqual(savedMode, ThemeMode.light)
    }

    func testSetTheme_PublishesChange() {
        // Arrange
        let expectation = self.expectation(description: "Theme change published")
        var receivedTheme: ThemeMode?

        let cancellable = sut.observeThemeChanges()
            .dropFirst() // Skip initial value
            .sink { theme in
                receivedTheme = theme
                expectation.fulfill()
            }

        // Act
        sut.setTheme(.dark)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedTheme, .dark)
        cancellable.cancel()
    }

    // MARK: - Color Scheme Calculation Tests

    func testCurrentColorScheme_LightMode_ReturnsLight() {
        // Arrange
        sut.setTheme(.light)

        // Act
        let colorScheme = sut.currentColorScheme

        // Assert
        XCTAssertEqual(colorScheme, .light)
    }

    func testCurrentColorScheme_DarkMode_ReturnsDark() {
        // Arrange
        sut.setTheme(.dark)

        // Act
        let colorScheme = sut.currentColorScheme

        // Assert
        XCTAssertEqual(colorScheme, .dark)
    }

    func testCurrentColorScheme_AutoMode_DependsOnTime() {
        // Arrange
        sut.setTheme(.auto)

        // Act
        let colorScheme = sut.currentColorScheme

        // Assert
        // Should return either light or dark based on current time
        // We can't predict which, but it should not be nil for auto mode
        XCTAssertNotNil(colorScheme)

        // Verify it's one of the two valid options
        XCTAssertTrue(colorScheme == .light || colorScheme == .dark)
    }

    // MARK: - Theme Mode Enum Tests

    func testThemeMode_DisplayName() {
        // Arrange & Act & Assert
        XCTAssertEqual(ThemeMode.auto.displayName, "Auto")
        XCTAssertEqual(ThemeMode.light.displayName, "Light")
        XCTAssertEqual(ThemeMode.dark.displayName, "Dark")
    }

    func testThemeMode_Icon() {
        // Arrange & Act & Assert
        XCTAssertEqual(ThemeMode.auto.icon, "circle.lefthalf.filled")
        XCTAssertEqual(ThemeMode.light.icon, "sun.max.fill")
        XCTAssertEqual(ThemeMode.dark.icon, "moon.fill")
    }

    func testThemeMode_CaseIterable() {
        // Arrange & Act
        let allCases = ThemeMode.allCases

        // Assert
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.auto))
        XCTAssertTrue(allCases.contains(.light))
        XCTAssertTrue(allCases.contains(.dark))
    }

    // MARK: - Observation Tests

    func testObserveThemeChanges_ReturnsPublisher() {
        // Arrange & Act
        let publisher = sut.observeThemeChanges()

        // Assert
        XCTAssertNotNil(publisher)
    }

    func testObserveThemeChanges_EmitsCurrentValue() {
        // Arrange
        let expectation = self.expectation(description: "Current value emitted")
        var receivedTheme: ThemeMode?

        // Act
        let cancellable = sut.observeThemeChanges()
            .sink { theme in
                receivedTheme = theme
                expectation.fulfill()
            }

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedTheme, .auto)
        cancellable.cancel()
    }
}
