//
//  PropertyKey.swift
//  Swinject
//
//  Copyright © 2025 Swinject Contributors. All rights reserved.
//

import Foundation

/// A type-safe wrapper for property keys used with Swinject PropertyLoader.
///
/// PropertyKey follows the same extensible pattern as NotificationCenter.Name,
/// allowing modules to define their own property keys in a type-safe manner.
///
/// Example:
/// ```swift
/// extension PropertyKey {
///     static let apiBaseURL = PropertyKey("api.baseURL")
///     static let apiTimeout = PropertyKey("api.timeout")
/// }
///
/// // Usage
/// let url: String? = resolver.property(.apiBaseURL)
/// let timeout: Int? = resolver.property(.apiTimeout)
/// ```
public struct PropertyKey:
    Hashable,
    Equatable,
    RawRepresentable,
    ExpressibleByStringLiteral,
    Sendable
{
    /// The raw string value of the property key
    public let rawValue: String

    /// Creates a PropertyKey with the specified string value.
    ///
    /// - Parameter rawValue: The string value for this key
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a PropertyKey with the specified string value.
    ///
    /// This is a convenience initializer that allows cleaner syntax:
    /// ```swift
    /// static let myKey = PropertyKey("my.key")
    /// ```
    ///
    /// - Parameter value: The string value for this key
    public init(_ value: String) {
        self.rawValue = value
    }

    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static func == (lhs: PropertyKey, rhs: PropertyKey) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    // MARK: - Hashable & Equatable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: CustomStringConvertible

extension PropertyKey: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

// MARK: CustomDebugStringConvertible

extension PropertyKey: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "PropertyKey(\"\(rawValue)\")"
    }
}
