//
//  TomlPropertyLoaderTests.swift
//  SwinjectPropertyLoader
//
//  Tests for TOML property loading with dot notation support
//

import XCTest
import Swinject
import SwinjectPropertyLoader

class TomlPropertyLoaderTests: XCTestCase {

    // MARK: - Bundle-based TOML Tests

    func testTomlPropertyLoaderCanLoadFromBundle() throws {
        let bundle = Bundle.test
        let loader = TomlPropertyLoader(bundle: bundle, name: "first")
        let properties = try loader.load()

        // Test basic values with dot notation
        XCTAssertEqual(properties["test.string"] as? String, "first")
        XCTAssertEqual(properties["test.int"] as? Int, 100)
        XCTAssertEqual(properties["test.double"] as? Double, 30.50)
        XCTAssertEqual(properties["test.bool"] as? Bool, true)

        // Test array
        let array = properties["test.array"] as? [String]
        XCTAssertEqual(array, ["item1", "item2"])

        // Test nested dict flattening
        XCTAssertEqual(properties["test.dict.key1"] as? String, "item1")
        XCTAssertEqual(properties["test.dict.key2"] as? String, "item2")
    }

    func testTomlPropertyLoaderFlattensDeeplyNestedTables() throws {
        let bundle = Bundle.test
        let loader = TomlPropertyLoader(bundle: bundle, name: "first")
        let properties = try loader.load()

        // Test API section
        XCTAssertEqual(properties["api.base_url"] as? String, "https://api.example.com")
        XCTAssertEqual(properties["api.timeout"] as? Int, 30)

        // Test deeply nested packages
        XCTAssertEqual(properties["packages.unlimited.cost"] as? Double, 99.99)
        let unlimitedFeatures = properties["packages.unlimited.features"] as? [String]
        XCTAssertEqual(unlimitedFeatures, ["feature1", "feature2", "feature3"])

        XCTAssertEqual(properties["packages.basic.cost"] as? Double, 9.99)
        let basicFeatures = properties["packages.basic.features"] as? [String]
        XCTAssertEqual(basicFeatures, ["feature1"])
    }

    func testTomlPropertyLoaderThrowsErrorForMissingResource() {
        let bundle = Bundle.test
        let loader = TomlPropertyLoader(bundle: bundle, name: "nonexistent")

        XCTAssertThrowsError(try loader.load()) { error in
            guard case PropertyLoaderError.missingResource(let errorBundle, let name) = error else {
                XCTFail("Expected missingResource error, got \(error)")
                return
            }
            XCTAssertEqual(errorBundle, bundle)
            XCTAssertEqual(name, "nonexistent")
        }
    }

    func testTomlPropertyLoaderThrowsErrorForInvalidFormat() {
        let bundle = Bundle.test
        let loader = TomlPropertyLoader(bundle: bundle, name: "invalid")

        XCTAssertThrowsError(try loader.load()) { error in
            // TOML with top-level array should cause invalid format error
            XCTAssert(error is PropertyLoaderError)
            if case PropertyLoaderError.invalidTOMLFormat(let errorBundle, let name) = error {
                XCTAssertEqual(errorBundle, bundle)
                XCTAssertEqual(name, "invalid")
            } else {
                XCTFail("Expected invalidTOMLFormat error, got \(error)")
            }
        }
    }

    // MARK: - URL-based TOML Tests

    func testTomlPropertyLoaderCanLoadFromURL() throws {
        let bundle = Bundle.test
        guard let url = bundle.url(forResource: "first", withExtension: "toml") else {
            XCTFail("Could not find first.toml in test bundle")
            return
        }

        let loader = TomlPropertyLoader(url: url)
        let properties = try loader.load()

        // Verify dot notation access works
        XCTAssertEqual(properties["test.string"] as? String, "first")
        XCTAssertEqual(properties["api.base_url"] as? String, "https://api.example.com")
        XCTAssertEqual(properties["packages.unlimited.cost"] as? Double, 99.99)
    }

    func testTomlPropertyLoaderThrowsErrorForMissingURL() {
        let tempDir = FileManager.default.temporaryDirectory
        let missingURL = tempDir.appendingPathComponent("nonexistent.toml")

        let loader = TomlPropertyLoader(url: missingURL)
        XCTAssertThrowsError(try loader.load()) { error in
            guard case PropertyLoaderError.missingResourceURL(let url) = error else {
                XCTFail("Expected missingResourceURL error, got \(error)")
                return
            }
            XCTAssertEqual(url, missingURL)
        }
    }

    func testTomlPropertyLoaderThrowsErrorForInvalidFormatURL() {
        let bundle = Bundle.test
        guard let url = bundle.url(forResource: "invalid", withExtension: "toml") else {
            XCTFail("Could not find invalid.toml in test bundle")
            return
        }

        let loader = TomlPropertyLoader(url: url)
        XCTAssertThrowsError(try loader.load()) { error in
            XCTAssert(error is PropertyLoaderError)
            if case PropertyLoaderError.invalidTOMLFormatURL(let errorURL) = error {
                XCTAssertEqual(errorURL, url)
            } else {
                XCTFail("Expected invalidTOMLFormatURL error, got \(error)")
            }
        }
    }

    // MARK: - Container Integration Tests

    func testCanUseTomlLoaderWithContainer() throws {
        let bundle = Bundle.test
        let container = Container()
        let loader = TomlPropertyLoader(bundle: bundle, name: "first")
        try container.applyPropertyLoader(loader)

        // Test dot notation property access
        let baseUrl: String? = container.property("api.base_url")
        XCTAssertEqual(baseUrl, "https://api.example.com")

        let timeout: Int? = container.property("api.timeout")
        XCTAssertEqual(timeout, 30)

        let cost: Double? = container.property("packages.unlimited.cost")
        XCTAssertEqual(cost, 99.99)
    }

    func testTomlPropertiesMergeCorrectly() throws {
        let bundle = Bundle.test
        let container = Container()

        // Load first properties
        let firstLoader = TomlPropertyLoader(bundle: bundle, name: "first")
        try container.applyPropertyLoader(firstLoader)

        // Load second properties (should override)
        let secondLoader = TomlPropertyLoader(bundle: bundle, name: "second")
        try container.applyPropertyLoader(secondLoader)

        // Test overridden values
        let testString: String? = container.property("test.string")
        XCTAssertEqual(testString, "second", "Second loader should override first")

        let apiUrl: String? = container.property("api.base_url")
        XCTAssertEqual(apiUrl, "https://override.example.com", "Second loader should override first")

        // Test values only in second
        let apiKey: String? = container.property("api.api_key")
        XCTAssertEqual(apiKey, "secret123")

        let newValue: String? = container.property("test.new_value")
        XCTAssertEqual(newValue, "added")

        // Test values only in first (should still exist)
        let timeout: Int? = container.property("api.timeout")
        XCTAssertEqual(timeout, 30)

        // Test database values from second
        let dbHost: String? = container.property("database.host")
        XCTAssertEqual(dbHost, "localhost")

        let dbPort: Int? = container.property("database.port")
        XCTAssertEqual(dbPort, 5432)
    }
}
