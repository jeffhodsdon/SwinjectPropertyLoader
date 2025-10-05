//
//  PropertyKeyTests.swift
//  SwinjectPropertyLoader
//
//  Tests for type-safe PropertyKey system
//

import XCTest
import Swinject
import SwinjectPropertyLoader

// MARK: - Test Property Keys

extension PropertyKey {
    static let testString = PropertyKey("test.string")
    static let testInt = PropertyKey("test.int")
    static let testDouble = PropertyKey("test.double")
    static let testBool = PropertyKey("test.bool")
    static let testArray = PropertyKey("test.array")
    static let testMissing = PropertyKey("test.missing")

    // API keys for testing
    static let apiBaseURL = PropertyKey("api.baseURL")
    static let apiTimeout = PropertyKey("api.timeout")
    static let apiKey = PropertyKey("api.key")

    // Simulated Module 1: API keys
    static let module1Key1 = PropertyKey("module1.key1")
    static let module1Key2 = PropertyKey("module1.key2")

    // Simulated Module 2: Feature flags
    static let module2FeatureA = PropertyKey("module2.featureA")
    static let module2FeatureB = PropertyKey("module2.featureB")
}

class PropertyKeyTests: XCTestCase {

    // MARK: - PropertyKey Basics

    func testPropertyKeyCreation() {
        let key1 = PropertyKey("my.key")
        let key2 = PropertyKey(rawValue: "my.key")

        XCTAssertEqual(key1.rawValue, "my.key")
        XCTAssertEqual(key2.rawValue, "my.key")
    }

    func testPropertyKeyStringLiteral() {
        let key: PropertyKey = "string.literal"
        XCTAssertEqual(key.rawValue, "string.literal")
    }

    func testPropertyKeyEquality() {
        let key1 = PropertyKey("test.key")
        let key2 = PropertyKey("test.key")
        let key3: PropertyKey = "test.key"
        let key4 = PropertyKey("different.key")

        XCTAssertEqual(key1, key2)
        XCTAssertEqual(key1, key3)
        XCTAssertNotEqual(key1, key4)
    }

    func testPropertyKeyHashable() {
        let key1 = PropertyKey("test.key")
        let key2 = PropertyKey("test.key")
        let key3 = PropertyKey("other.key")

        var set = Set<PropertyKey>()
        set.insert(key1)
        set.insert(key2)  // Should not add duplicate
        set.insert(key3)

        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(key1))
        XCTAssertTrue(set.contains(key3))
    }

    func testPropertyKeyDescription() {
        let key = PropertyKey("my.key")
        XCTAssertEqual(key.description, "my.key")
        XCTAssertEqual(key.debugDescription, "PropertyKey(\"my.key\")")
    }

    // MARK: - Type-Safe Property Access

    func testPropertyKeyAccess() throws {
        let container = Container()
        let loader = JsonPropertyLoader(bundle: .test, name: "first")
        try container.applyPropertyLoader(loader)

        // Type-safe access with PropertyKey
        let stringValue: String? = container.property(forKey: .testString)
        let intValue: Int? = container.property(forKey: .testInt)
        let doubleValue: Double? = container.property(forKey: .testDouble)
        let boolValue: Bool? = container.property(forKey: .testBool)

        XCTAssertEqual(stringValue, "first")
        XCTAssertEqual(intValue, 100)
        XCTAssertEqual(doubleValue, 30.50)
        XCTAssertEqual(boolValue, true)
    }

    func testPropertyKeyAccessWithArrays() throws {
        let container = Container()
        let loader = JsonPropertyLoader(bundle: .test, name: "first")
        try container.applyPropertyLoader(loader)

        let arrayValue: [String]? = container.property(forKey: .testArray)
        XCTAssertEqual(arrayValue, ["item1", "item2"])
    }

    // MARK: - Backward Compatibility

    func testBackwardCompatibilityWithStringAPI() throws {
        let container = Container()
        let loader = JsonPropertyLoader(bundle: .test, name: "first")
        try container.applyPropertyLoader(loader)

        // Old string-based API still works
        let stringValue: String? = container.property("test.string")
        XCTAssertEqual(stringValue, "first")

        let intValue: Int? = container.property("test.int")
        XCTAssertEqual(intValue, 100)
    }

    func testPropertyKeyAndStringProduceSameResult() throws {
        let container = Container()
        let loader = JsonPropertyLoader(bundle: .test, name: "first")
        try container.applyPropertyLoader(loader)

        // Both approaches should return the same value
        let viaKey: String? = container.property(forKey: .testString)
        let viaString: String? = container.property("test.string")

        XCTAssertEqual(viaKey, viaString)
        XCTAssertEqual(viaKey, "first")
    }

    // MARK: - Real-World Usage Patterns

    func testAPIConfigurationPattern() throws {
        // Simulate loading API configuration
        struct Config {
            struct API {
                let baseURL = "https://api.example.com"
                let timeout = 30
                let key = "secret123"
            }
            let api = API()
        }

        let container = Container()
        let config = Config()
        let loader = StructPropertyLoader(config)
        try container.applyPropertyLoader(loader)

        // Use PropertyKey for type-safe access
        let baseURL: String? = container.property(forKey: .apiBaseURL)
        let timeout: Int? = container.property(forKey: .apiTimeout)

        XCTAssertEqual(baseURL, "https://api.example.com")
        XCTAssertEqual(timeout, 30)
    }

    func testMultipleModuleKeyDefinitions() {
        // Keys from different modules are defined at file level (see below this class)
        // This test verifies they are all accessible
        XCTAssertEqual(PropertyKey.module1Key1.rawValue, "module1.key1")
        XCTAssertEqual(PropertyKey.module2FeatureA.rawValue, "module2.featureA")
    }

    func testPropertyKeyInDictionary() {
        var dict = [PropertyKey: Any]()
        dict[.testString] = "value1"
        dict[.testInt] = 42

        XCTAssertEqual(dict[.testString] as? String, "value1")
        XCTAssertEqual(dict[.testInt] as? Int, 42)
        XCTAssertEqual(dict.count, 2)
    }
}
