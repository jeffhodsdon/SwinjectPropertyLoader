//
//  TomlPropertyLoader.swift
//  Swinject
//
//  Created for SwinjectPropertyLoader
//  Copyright © 2025 Swinject Contributors. All rights reserved.
//

import Foundation
import TOMLKit


/// The TomlPropertyLoader will load properties from TOML resources
/// Nested TOML tables are automatically flattened to dot-notation keys for property access
final public class TomlPropertyLoader: Sendable {

    /// the bundle where the resource exists (defaults to mainBundle)
    fileprivate let bundle: Bundle?

    /// the name of the TOML resource. For example, if your resource is "properties.toml" then this value will be set to "properties"
    fileprivate let name: String?

    /// the URL where the resource exists (used instead of bundle if provided)
    fileprivate let url: URL?

    ///
    /// Will create a TOML property loader from a bundle resource
    ///
    /// - parameter bundle: the bundle where the resource exists (defaults to mainBundle)
    /// - parameter name:   the name of the TOML resource. For example, if your resource is "properties.toml"
    ///                     then this value will be set to "properties"
    ///
    public init(bundle: Bundle = .main, name: String) {
        self.bundle = bundle
        self.name = name
        self.url = nil
    }

    ///
    /// Will create a TOML property loader from a URL
    ///
    /// - parameter url: the URL where the TOML resource exists
    ///
    public init(url: URL) {
        self.bundle = nil
        self.name = nil
        self.url = url
    }
}

// MARK: - PropertyLoader
extension TomlPropertyLoader: PropertyLoader {
    public func load() throws -> [String: Any] {
        let contents: String

        if let url = url {
            // Load from URL
            contents = try loadStringFromURL(url)
        } else if let bundle = bundle, let name = name {
            // Load from bundle
            contents = try loadStringFromBundle(bundle, withName: name, ofType: "toml")
        } else {
            fatalError("TomlPropertyLoader must be initialized with either a URL or bundle+name")
        }

        // Parse TOML
        let table: TOMLTable
        do {
            table = try TOMLTable(string: contents)
        } catch {
            // Handle TOML parsing error
            if let url = url {
                throw PropertyLoaderError.invalidTOMLFormatURL(url: url)
            } else {
                throw PropertyLoaderError.invalidTOMLFormat(bundle: bundle!, name: name!)
            }
        }

        // Convert TOML to JSON, then to [String: Any]
        let jsonString = table.convert(to: .json)
        guard let jsonData = jsonString.data(using: .utf8) else {
            if let url = url {
                throw PropertyLoaderError.invalidTOMLFormatURL(url: url)
            } else {
                throw PropertyLoaderError.invalidTOMLFormat(bundle: bundle!, name: name!)
            }
        }

        let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
        guard let nestedDict = json as? [String: Any] else {
            if let url = url {
                throw PropertyLoaderError.invalidTOMLFormatURL(url: url)
            } else {
                throw PropertyLoaderError.invalidTOMLFormat(bundle: bundle!, name: name!)
            }
        }

        // Flatten nested dictionary to dot-notation keys
        return flattenDictionary(nestedDict)
    }
}
