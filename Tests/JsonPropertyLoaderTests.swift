//
//  JsonPropertyLoaderTests.swift
//  Swinject
//
//  Created by mike.owens on 12/6/15.
//  Copyright © 2015 Swinject Contributors. All rights reserved.
//

import XCTest
import Swinject
import SwinjectPropertyLoader


class JsonPropertyLoaderTests: XCTestCase {
    func testMissingResourrcesCanBeHandled() {
        let loader = JsonPropertyLoader(bundle: .test, name: "noexist")
        XCTAssertThrowsError(try loader.load()) { error in
            XCTAssert(error is PropertyLoaderError)
        }
    }

    func testInvalidResourcesCanBeHandled() {
        let loader = JsonPropertyLoader(bundle: .test, name: "invalid")
        XCTAssertThrowsError(try loader.load()) { error in
            XCTAssert(error is PropertyLoaderError)
        }
    }
}
