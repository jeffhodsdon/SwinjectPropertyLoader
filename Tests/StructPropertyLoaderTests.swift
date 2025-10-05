//
//  StructPropertyLoaderTests.swift
//  SwinjectPropertyLoader
//
//  Tests for reflection-based struct property loading
//

import XCTest
import Swinject
import SwinjectPropertyLoader

// MARK: - Test Fixtures

struct BasicConfig {
    let apiKey: String = "secret123"
    let timeout: Int = 30
    let debugMode: Bool = true
    let maxRetries: Double = 3.5
    let features: [String] = ["feature1", "feature2"]
}

struct NestedConfig {
    struct API {
        let baseURL: String = "https://api.example.com"
        let timeout: Int = 30
        let apiKey: String = "secret123"
    }

    struct Database {
        let host: String = "localhost"
        let port: Int = 5432
        let name: String = "myapp"
    }

    let api = API()
    let database = Database()
    let appName: String = "MyApp"
}

struct DeeplyNestedConfig {
    struct Packages {
        struct Unlimited {
            let cost: Double = 99.99
            let features: [String] = ["feature1", "feature2", "feature3"]
        }

        struct Basic {
            let cost: Double = 9.99
            let features: [String] = ["feature1"]
        }

        let unlimited = Unlimited()
        let basic = Basic()
    }

    let packages = Packages()
}

struct OptionalConfig {
    let requiredValue: String = "required"
    let optionalValue: String? = "optional"
    let nilValue: String? = nil
    let optionalInt: Int? = 42
}

final class ConfigClass: Sendable {
    let setting1: String = "value1"
    let setting2: Int = 100
}

// MARK: - Tests

class StructPropertyLoaderTests: XCTestCase {

    // MARK: - Basic Reflection Tests

    func testStructPropertyLoaderCanLoadBasicProperties() throws {
        let config = BasicConfig()
        let loader = StructPropertyLoader(config)
        let properties = try loader.load()

        XCTAssertEqual(properties["apiKey"] as? String, "secret123")
        XCTAssertEqual(properties["timeout"] as? Int, 30)
        XCTAssertEqual(properties["debugMode"] as? Bool, true)
        XCTAssertEqual(properties["maxRetries"] as? Double, 3.5)
        XCTAssertEqual(properties["features"] as? [String], ["feature1", "feature2"])
    }

    func testStructPropertyLoaderFlattensNestedStructs() throws {
        let config = NestedConfig()
        let loader = StructPropertyLoader(config)
        let properties = try loader.load()

        // Test top-level property
        XCTAssertEqual(properties["appName"] as? String, "MyApp")

        // Test nested API properties with dot notation
        XCTAssertEqual(properties["api.baseURL"] as? String, "https://api.example.com")
        XCTAssertEqual(properties["api.timeout"] as? Int, 30)
        XCTAssertEqual(properties["api.apiKey"] as? String, "secret123")

        // Test nested Database properties with dot notation
        XCTAssertEqual(properties["database.host"] as? String, "localhost")
        XCTAssertEqual(properties["database.port"] as? Int, 5432)
        XCTAssertEqual(properties["database.name"] as? String, "myapp")

        // Ensure no un-flattened nested structs exist
        XCTAssertNil(properties["api"] as? NestedConfig.API)
        XCTAssertNil(properties["database"] as? NestedConfig.Database)
    }

    func testStructPropertyLoaderFlattensDeeplyNestedStructs() throws {
        let config = DeeplyNestedConfig()
        let loader = StructPropertyLoader(config)
        let properties = try loader.load()

        // Test deeply nested properties (3 levels)
        XCTAssertEqual(properties["packages.unlimited.cost"] as? Double, 99.99)
        XCTAssertEqual(properties["packages.unlimited.features"] as? [String],
                      ["feature1", "feature2", "feature3"])

        XCTAssertEqual(properties["packages.basic.cost"] as? Double, 9.99)
        XCTAssertEqual(properties["packages.basic.features"] as? [String], ["feature1"])
    }

    func testStructPropertyLoaderHandlesOptionals() throws {
        let config = OptionalConfig()
        let loader = StructPropertyLoader(config)
        let properties = try loader.load()

        // Required value should be present
        XCTAssertEqual(properties["requiredValue"] as? String, "required")

        // Non-nil optional should be unwrapped and present
        XCTAssertEqual(properties["optionalValue"] as? String, "optional")
        XCTAssertEqual(properties["optionalInt"] as? Int, 42)

        // Nil optional should NOT be in the dictionary
        XCTAssertNil(properties["nilValue"])
        XCTAssertFalse(properties.keys.contains("nilValue"))
    }

    func testStructPropertyLoaderWorksWithClasses() throws {
        let config = ConfigClass()
        let loader = StructPropertyLoader(config)
        let properties = try loader.load()

        XCTAssertEqual(properties["setting1"] as? String, "value1")
        XCTAssertEqual(properties["setting2"] as? Int, 100)
    }

    // MARK: - Container Integration Tests

    func testCanUseStructLoaderWithContainer() throws {
        let config = BasicConfig()
        let container = Container()
        let loader = StructPropertyLoader(config)
        try container.applyPropertyLoader(loader)

        let apiKey: String? = container.property("apiKey")
        XCTAssertEqual(apiKey, "secret123")

        let timeout: Int? = container.property("timeout")
        XCTAssertEqual(timeout, 30)

        let debugMode: Bool? = container.property("debugMode")
        XCTAssertEqual(debugMode, true)
    }

    func testCanUseNestedStructLoaderWithContainer() throws {
        let config = NestedConfig()
        let container = Container()
        let loader = StructPropertyLoader(config)
        try container.applyPropertyLoader(loader)

        // Test dot notation access
        let baseURL: String? = container.property("api.baseURL")
        XCTAssertEqual(baseURL, "https://api.example.com")

        let dbHost: String? = container.property("database.host")
        XCTAssertEqual(dbHost, "localhost")

        let dbPort: Int? = container.property("database.port")
        XCTAssertEqual(dbPort, 5432)
    }

    func testStructPropertiesMergeWithOtherLoaders() throws {
        let bundle = Bundle.test
        let container = Container()

        // First load from struct
        let structConfig = BasicConfig()
        let structLoader = StructPropertyLoader(structConfig)
        try container.applyPropertyLoader(structLoader)

        // Then load from JSON (should override)
        let jsonLoader = JsonPropertyLoader(bundle: bundle, name: "first")
        try container.applyPropertyLoader(jsonLoader)

        // JSON values should override struct values
        let testString: String? = container.property("test.string")
        XCTAssertEqual(testString, "first")  // From JSON

        // Struct-only values should still exist
        let apiKey: String? = container.property("apiKey")
        XCTAssertEqual(apiKey, "secret123")  // From struct
    }

    func testDifferentStructInstancesCanHaveDifferentValues() throws {
        struct ConfigWithValue {
            let value: String
        }

        let config1 = ConfigWithValue(value: "first")
        let loader1 = StructPropertyLoader(config1)
        let properties1 = try loader1.load()

        let config2 = ConfigWithValue(value: "second")
        let loader2 = StructPropertyLoader(config2)
        let properties2 = try loader2.load()

        XCTAssertEqual(properties1["value"] as? String, "first")
        XCTAssertEqual(properties2["value"] as? String, "second")
    }
}
