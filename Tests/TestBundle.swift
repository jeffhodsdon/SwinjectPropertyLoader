//
//  TestBundle.swift
//  SwinjectPropertyLoader
//
//  Created for SPM and Xcode compatibility
//

import Foundation

extension Bundle {
    static var test: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: TestBundleMarker.self)
        #endif
    }
}

private class TestBundleMarker {}
