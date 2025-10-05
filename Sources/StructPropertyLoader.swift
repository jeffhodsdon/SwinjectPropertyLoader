//
//  StructPropertyLoader.swift
//  Swinject
//
//  Created for SwinjectPropertyLoader
//  Copyright © 2025 Swinject Contributors. All rights reserved.
//

import Foundation


/// The StructPropertyLoader will load properties from a Swift struct or class instance using reflection
/// Nested structs/classes are automatically flattened to dot-notation keys
final public class StructPropertyLoader<T>: PropertyLoader {

    /// The instance to reflect properties from
    private let instance: T

    ///
    /// Will create a struct property loader from any Swift struct or class instance
    ///
    /// - parameter instance: the struct or class instance to extract properties from
    ///
    public init(_ instance: T) {
        self.instance = instance
    }

    ///
    /// Loads properties from the struct/class instance using Mirror reflection
    ///
    /// - returns: the key-value pair properties extracted from the instance
    ///
    public func load() throws -> [String: Any] {
        return reflectProperties(instance, prefix: "")
    }

    ///
    /// Recursively reflects on a struct/class instance and extracts properties
    /// Nested types are flattened to dot notation (e.g., "api.baseURL")
    ///
    /// - parameter instance: the instance to reflect on
    /// - parameter prefix: the current key prefix for nested properties
    ///
    /// - returns: flattened dictionary of properties
    ///
    private func reflectProperties(_ instance: Any, prefix: String) -> [String: Any] {
        let mirror = Mirror(reflecting: instance)
        var properties: [String: Any] = [:]

        for child in mirror.children {
            guard let label = child.label else { continue }

            let key = prefix.isEmpty ? label : "\(prefix).\(label)"
            let value = child.value

            // Unwrap optionals
            let unwrappedValue = unwrapOptional(value)

            // Skip nil optionals
            guard let nonNilValue = unwrappedValue else { continue }

            // Check if this is a struct/class that should be flattened
            if shouldFlatten(nonNilValue) {
                // Recursively flatten nested struct/class
                let nestedProperties = reflectProperties(nonNilValue, prefix: key)
                properties.merge(nestedProperties) { _, new in new }
            } else {
                // Store the value directly
                properties[key] = nonNilValue
            }
        }

        return properties
    }

    ///
    /// Unwraps an optional value to get the underlying value or nil
    ///
    /// - parameter value: the value to unwrap
    ///
    /// - returns: the unwrapped value or nil if the optional is nil
    ///
    private func unwrapOptional(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)

        // Check if this is an Optional type
        if mirror.displayStyle == .optional {
            // Optional has one child if it has a value, zero if nil
            if let firstChild = mirror.children.first {
                return firstChild.value
            } else {
                return nil  // Optional is nil
            }
        }

        return value  // Not an optional
    }

    ///
    /// Determines if a value should be flattened (i.e., it's a custom struct/class)
    ///
    /// - parameter value: the value to check
    ///
    /// - returns: true if the value should be recursively flattened
    ///
    private func shouldFlatten(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)

        // Flatten if it's a struct or class with properties
        if mirror.displayStyle == .struct || mirror.displayStyle == .class {
            // Don't flatten Foundation types or standard library types
            let typeName = String(describing: type(of: value))

            // Exclude common Foundation and stdlib types that we want as-is
            // Check if the type name CONTAINS (not just starts with) these keywords
            let excludedTypes = ["String", "Int", "Double", "Float", "Bool", "Date",
                                 "URL", "UUID", "Data", "Array", "Dictionary", "Set",
                                 "Optional", "__"]

            for excludedType in excludedTypes {
                // Check both prefix and if type name is exactly the excluded type
                if typeName == excludedType || typeName.hasPrefix(excludedType + "<") ||
                   typeName.hasPrefix("Swift." + excludedType) ||
                   typeName.hasPrefix("Foundation." + excludedType) {
                    return false
                }
            }

            // If it has children (properties), flatten it
            return mirror.children.count > 0
        }

        return false
    }
}
