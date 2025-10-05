//
//  JsonPropertyLoader.swift
//  Swinject
//
//  Created by mike.owens on 12/6/15.
//  Copyright © 2015 Swinject Contributors. All rights reserved.
//

import Foundation


/// The JsonPropertyLoader will load properties from JSON resources
final public class JsonPropertyLoader: Sendable {

    /// the bundle where the resource exists (defaults to mainBundle)
    fileprivate let bundle: Bundle?

    /// the name of the JSON resource. For example, if your resource is "properties.json" then this value will be set to "properties"
    fileprivate let name: String?

    /// the URL where the resource exists (used instead of bundle if provided)
    fileprivate let url: URL?

    ///
    /// Will create a JSON property loader from a bundle resource
    ///
    /// - parameter bundle: the bundle where the resource exists (defaults to mainBundle)
    /// - parameter name:   the name of the JSON resource. For example, if your resource is "properties.json"
    ///                     then this value will be set to "properties"
    ///
    public init(bundle: Bundle = .main, name: String) {
        self.bundle = bundle
        self.name = name
        self.url = nil
    }

    ///
    /// Will create a JSON property loader from a URL
    ///
    /// - parameter url: the URL where the JSON resource exists
    ///
    public init(url: URL) {
        self.bundle = nil
        self.name = nil
        self.url = url
    }
    
    /// Will strip the provide string of comments. This allows JSON property files to contain comments as it
    /// is valuable to provide more context to a property then just its key-value and comments are not valid JSON
    /// so this will process the JSON string before we attempt to parse the JSON into objects
    ///
    /// Implementation influence by Typhoon:
    /// https://github.com/appsquickly/Typhoon/blob/master/Source/Configuration/ConfigPostProcessor/TyphoonConfiguration/TyphoonJsonStyleConfiguration.m#L30
    ///
    /// - Parameter str: the string to strip of comments
    ///
    /// - Returns: the json string stripper of comments
    fileprivate func stringWithoutComments(_ str: String) -> String {
        let pattern = "(([\"'])(?:\\\\\\2|.)*?\\2)|(\\/\\/[^\\n\\r]*(?:[\\n\\r]+|$)|(\\/\\*(?:(?!\\*\\/).|[\\n\\r])*\\*\\/))"
        let expression = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let matches = expression.matches(in: str, options: [], range: NSRange(location: 0, length: str.count))
        
        let ret = NSMutableString(string: str)
        for match in matches.reversed() {
            let character = String(str[str.index(str.startIndex, offsetBy: match.range.location)])
            if character != "\'" && character != "\"" {
                ret.replaceCharacters(in: match.range, with: "")
            }
        }
        return ret as String
    }
}

// MARK: - PropertyLoadable
extension JsonPropertyLoader: PropertyLoader {
    public func load() throws -> [String: Any] {
        let contents: String

        if let url = url {
            // Load from URL
            contents = try loadStringFromURL(url)
        } else if let bundle = bundle, let name = name {
            // Load from bundle
            contents = try loadStringFromBundle(bundle, withName: name, ofType: "json")
        } else {
            fatalError("JsonPropertyLoader must be initialized with either a URL or bundle+name")
        }

        let jsonWithoutComments = stringWithoutComments(contents)
        guard let data = jsonWithoutComments.data(using: .utf8) else {
            if let url = url {
                throw PropertyLoaderError.invalidJSONFormatURL(url: url)
            } else {
                throw PropertyLoaderError.invalidJSONFormat(bundle: bundle!, name: name!)
            }
        }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let props = json as? [String: Any] else {
            if let url = url {
                throw PropertyLoaderError.invalidJSONFormatURL(url: url)
            } else {
                throw PropertyLoaderError.invalidJSONFormat(bundle: bundle!, name: name!)
            }
        }
        return props
    }
}
