//
//  PlistPropertyLoader.swift
//  Swinject
//
//  Created by mike.owens on 12/6/15.
//  Copyright © 2015 Swinject Contributors. All rights reserved.
//

import Foundation


/// The PlistPropertyLoader will load properties from plist resources
final public class PlistPropertyLoader: Sendable {

    /// the bundle where the resource exists (defaults to mainBundle)
    fileprivate let bundle: Bundle?

    /// the name of the plist resource. For example, if your resource is "properties.plist" then this value will be set to "properties"
    fileprivate let name: String?

    /// the URL where the resource exists (used instead of bundle if provided)
    fileprivate let url: URL?

    ///
    /// Will create a plist property loader from a bundle resource
    ///
    /// - parameter bundle: the bundle where the resource exists (defaults to mainBundle)
    /// - parameter name:   the name of the plist resource. For example, if your resource is "properties.plist"
    ///                     then this value will be set to "properties"
    ///
    public init(bundle: Bundle = .main, name: String) {
        self.bundle = bundle
        self.name = name
        self.url = nil
    }

    ///
    /// Will create a plist property loader from a URL
    ///
    /// - parameter url: the URL where the plist resource exists
    ///
    public init(url: URL) {
        self.bundle = nil
        self.name = nil
        self.url = url
    }
}

// MARK: - PropertyLoadable
extension PlistPropertyLoader: PropertyLoader {
    public func load() throws -> [String: Any] {
        let data: Data

        if let url = url {
            // Load from URL
            data = try loadDataFromURL(url)
        } else if let bundle = bundle, let name = name {
            // Load from bundle
            data = try loadDataFromBundle(bundle, withName: name, ofType: "plist")
        } else {
            fatalError("PlistPropertyLoader must be initialized with either a URL or bundle+name")
        }

        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let props = plist as? [String: Any] else {
            if let url = url {
                throw PropertyLoaderError.invalidPlistFormatURL(url: url)
            } else {
                throw PropertyLoaderError.invalidPlistFormat(bundle: bundle!, name: name!)
            }
        }
        return props
    }
}
