//
//  URLPropertyLoaderTests.swift
//  SwinjectPropertyLoader
//
//  Tests for URL-based property loading
//

import XCTest
import Swinject
import SwinjectPropertyLoader

class URLPropertyLoaderTests: XCTestCase {

    // MARK: - JSON URL Tests

    func testJsonPropertyLoaderCanLoadFromURL() throws {
        // Get the test resource URL
        let bundle = Bundle.test
        guard let url = bundle.url(forResource: "first", withExtension: "json") else {
            XCTFail("Could not find first.json in test bundle")
            return
        }

        let loader = JsonPropertyLoader(url: url)
        let properties = try loader.load()

        XCTAssertEqual(properties["test.string"] as? String, "first")
        XCTAssertEqual(properties["test.int"] as? Int, 100)
        XCTAssertEqual(properties["test.double"] as? Double, 30.50)
    }

    func testJsonPropertyLoaderThrowsErrorForMissingURL() {
        let tempDir = FileManager.default.temporaryDirectory
        let missingURL = tempDir.appendingPathComponent("nonexistent.json")

        let loader = JsonPropertyLoader(url: missingURL)
        XCTAssertThrowsError(try loader.load()) { error in
            guard case PropertyLoaderError.missingResourceURL(let url) = error else {
                XCTFail("Expected missingResourceURL error, got \(error)")
                return
            }
            XCTAssertEqual(url, missingURL)
        }
    }

    func testJsonPropertyLoaderThrowsErrorForInvalidFormatURL() {
        let bundle = Bundle.test
        guard let url = bundle.url(forResource: "invalid", withExtension: "json") else {
            XCTFail("Could not find invalid.json in test bundle")
            return
        }

        let loader = JsonPropertyLoader(url: url)
        XCTAssertThrowsError(try loader.load()) { error in
            XCTAssert(error is PropertyLoaderError)
            if case PropertyLoaderError.invalidJSONFormatURL(let errorURL) = error {
                XCTAssertEqual(errorURL, url)
            } else {
                XCTFail("Expected invalidJSONFormatURL error")
            }
        }
    }

    // MARK: - Plist URL Tests

    func testPlistPropertyLoaderCanLoadFromURL() throws {
        let bundle = Bundle.test
        guard let url = bundle.url(forResource: "first", withExtension: "plist") else {
            XCTFail("Could not find first.plist in test bundle")
            return
        }

        let loader = PlistPropertyLoader(url: url)
        let properties = try loader.load()

        XCTAssertEqual(properties["test.string"] as? String, "first")
        XCTAssertEqual(properties["test.int"] as? Int, 100)
    }

    func testPlistPropertyLoaderThrowsErrorForMissingURL() {
        let tempDir = FileManager.default.temporaryDirectory
        let missingURL = tempDir.appendingPathComponent("nonexistent.plist")

        let loader = PlistPropertyLoader(url: missingURL)
        XCTAssertThrowsError(try loader.load()) { error in
            guard case PropertyLoaderError.missingResourceURL(let url) = error else {
                XCTFail("Expected missingResourceURL error, got \(error)")
                return
            }
            XCTAssertEqual(url, missingURL)
        }
    }

    // MARK: - Integration Tests

    func testCanUseURLBasedLoaderWithContainer() throws {
        let bundle = Bundle.test
        guard let url = bundle.url(forResource: "first", withExtension: "json") else {
            XCTFail("Could not find first.json in test bundle")
            return
        }

        let container = Container()
        let loader = JsonPropertyLoader(url: url)
        try container.applyPropertyLoader(loader)

        let value: String? = container.property("test.string")
        XCTAssertEqual(value, "first")
    }
}
