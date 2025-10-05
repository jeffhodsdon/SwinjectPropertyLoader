//
//  PropertyLoaderError.swift
//  Swinject
//
//  Created by mike.owens on 12/8/15.
//  Copyright © 2015 Swinject Contributors. All rights reserved.
//

import Foundation


/// Represents errors that can be thrown when loading properties into a container
///
/// - InvalidJSONFormat:         The JSON format of the properties file is incorrect. Must be top-level dictionary
/// - InvalidPlistFormat:        The Plist format of the properties file is incorrect. Must be top-level dictionary
/// - InvalidTOMLFormat:         The TOML format of the properties file is incorrect. Must be top-level table
/// - MissingResource:           The resource is missing from the bundle or URL
/// - InvalidResourceDataFormat: The resource cannot be converted to Data
///
public enum PropertyLoaderError: Error, Sendable {
    case invalidJSONFormat(bundle: Bundle, name: String)
    case invalidPlistFormat(bundle: Bundle, name: String)
    case invalidTOMLFormat(bundle: Bundle, name: String)
    case missingResource(bundle: Bundle, name: String)
    case invalidResourceDataFormat(bundle: Bundle, name: String)

    // URL-based errors
    case invalidJSONFormatURL(url: URL)
    case invalidPlistFormatURL(url: URL)
    case invalidTOMLFormatURL(url: URL)
    case missingResourceURL(url: URL)
    case invalidResourceDataFormatURL(url: URL)
}

// MARK: - CustomStringConvertible
extension PropertyLoaderError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidJSONFormat(let bundle, let name):
            return "Invalid JSON format for bundle: \(bundle), name: \(name). Must be top-level dictionary"
        case .invalidPlistFormat(let bundle, let name):
            return "Invalid Plist format for bundle: \(bundle), name: \(name). Must be top-level dictionary"
        case .invalidTOMLFormat(let bundle, let name):
            return "Invalid TOML format for bundle: \(bundle), name: \(name). Must be top-level table"
        case .missingResource(let bundle, let name):
            return "Missing resource for bundle: \(bundle), name: \(name)"
        case .invalidResourceDataFormat(let bundle, let name):
            return "Invalid resource format for bundle: \(bundle), name: \(name)"
        case .invalidJSONFormatURL(let url):
            return "Invalid JSON format for URL: \(url). Must be top-level dictionary"
        case .invalidPlistFormatURL(let url):
            return "Invalid Plist format for URL: \(url). Must be top-level dictionary"
        case .invalidTOMLFormatURL(let url):
            return "Invalid TOML format for URL: \(url). Must be top-level table"
        case .missingResourceURL(let url):
            return "Missing resource at URL: \(url)"
        case .invalidResourceDataFormatURL(let url):
            return "Invalid resource format at URL: \(url)"
        }
    }
}
