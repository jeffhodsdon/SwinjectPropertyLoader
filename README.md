SwinjectPropertyLoader
========

[![Build Status](https://travis-ci.org/Swinject/SwinjectPropertyLoader.svg?branch=master)](https://travis-ci.org/Swinject/SwinjectPropertyLoader)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Version](https://img.shields.io/cocoapods/v/SwinjectPropertyLoader.svg?style=flat)](http://cocoapods.org/pods/SwinjectPropertyLoader)
[![License](https://img.shields.io/cocoapods/l/SwinjectPropertyLoader.svg?style=flat)](http://cocoapods.org/pods/SwinjectPropertyLoader)
[![Platform](https://img.shields.io/cocoapods/p/SwinjectPropertyLoader.svg?style=flat)](http://cocoapods.org/pods/SwinjectPropertyLoader)
[![Swift Version](https://img.shields.io/badge/Swift-6.0-F16D39.svg?style=flat)](https://developer.apple.com/swift)


SwinjectPropertyLoader is an extension of Swinject to load property values from resources that are bundled with your application or framework.

## Requirements

- iOS 15.0+ / macOS 12.0+ / watchOS 8.0+ / tvOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

To install SwinjectPropertyLoader using Swift Package Manager, add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Swinject/SwinjectPropertyLoader.git", from: "2.0.0")
]
```

Or add it through Xcode:
1. File > Add Package Dependencies...
2. Enter package URL: `https://github.com/Swinject/SwinjectPropertyLoader.git`
3. Select version 2.0.0 or later

### Carthage

To install SwinjectPropertyLoader with Carthage, add the following line to your `Cartfile`:

```
github "Swinject/Swinject" ~> 2.9.1
github "Swinject/SwinjectPropertyLoader" ~> 2.0.0
```

Then run `carthage update --no-use-binaries` command or just `carthage update`. For details of the installation and usage of Carthage, visit [its project page](https://github.com/Carthage/Carthage).


### CocoaPods

To install SwinjectPropertyLoader with CocoaPods, add the following lines to your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '15.0' # or platform :osx, '12.0' for macOS
use_frameworks!

pod 'Swinject', '~> 2.9.1'
pod 'SwinjectPropertyLoader', '~> 2.0.0'
```

Then run `pod install` command. For details of the installation and usage of CocoaPods, visit [its official website](https://cocoapods.org).

## Properties

Properties are values that can be loaded from resources that are bundled with your application/framework.
Properties can then be used when assembling definitions in your container.

There are 4 types of supported property loaders:

 - JSON (`JsonPropertyLoader`) - Load from JSON files
 - Plist (`PlistPropertyLoader`) - Load from Plist files
 - TOML (`TomlPropertyLoader`) - Load from TOML files with dot notation
 - Struct (`StructPropertyLoader`) - Load from Swift struct/class instances using reflection

Each loader supports different value types:
- **JSON**: `Bool`, `Int`, `Double`, `String`, `Array`, `Dictionary` (with comment support)
- **Plist**: All JSON types plus `NSDate` and `NSData`
- **TOML**: All TOML types (integers, floats, booleans, strings, dates, arrays, tables) - nested tables are auto-flattened to dot notation
- **Struct**: All Swift types via reflection - nested structs/classes are auto-flattened to dot notation

JSON and TOML property files support comments which allow you to provide more context to
your properties besides your property key names.

**JSON comments:**
```js
{
    // Comment type 1
    "foo": "bar",

    /* Comment type 2 */
    "baz": 100,

    /**
     Comment type 3
     */
    "boo": 30.50
}
```

**TOML comments and nested tables:**
```toml
# TOML natively supports comments
foo = "bar"
baz = 100

# Nested tables are automatically flattened to dot notation
[api]
base_url = "https://api.example.com"
timeout = 30

[packages.unlimited]
cost = 99.99
features = ["feature1", "feature2"]
```

TOML nested tables are automatically flattened, so `[api]` with `base_url = "..."` becomes
accessible as `r.property("api.base_url")` in your container.

Loading properties into the container is as simple as:

```swift
let container = Container()

// Load from bundle (traditional approach)
let jsonLoader = JsonPropertyLoader(bundle: .main, name: "properties")
try container.applyPropertyLoader(jsonLoader)

// Or load from a URL (decoupled from bundle)
let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let configURL = documentsURL.appendingPathComponent("config.json")
let urlLoader = JsonPropertyLoader(url: configURL)
try container.applyPropertyLoader(urlLoader)

// Load TOML with automatic dot notation for nested tables
let tomlLoader = TomlPropertyLoader(bundle: .main, name: "config")
try container.applyPropertyLoader(tomlLoader)

// TOML from URL
let tomlURL = documentsURL.appendingPathComponent("config.toml")
let tomlURLLoader = TomlPropertyLoader(url: tomlURL)
try container.applyPropertyLoader(tomlURLLoader)

// Load from Swift struct/class using reflection (no file needed!)
struct AppConfig: Sendable {
    let apiKey = "secret123"
    let timeout = 30
}
let config = AppConfig()
let structLoader = StructPropertyLoader(config)
try container.applyPropertyLoader(structLoader)
```

The URL-based loading allows you to load properties from anywhere in the file system, making it useful for:
- Downloaded configuration files
- User-specific settings stored in Documents
- Temporary configuration files
- Files in Application Support directory

Now you can inject properties into definitions registered into the container.

Consider the following definition:

```swift
class Person {
    var name: String!
    var count: Int?
    var team: String = ""
}
```

And let's say our `properties.json` file contains:

```json
{
    "name": "Mike",
    "count": 100,
    "team": "Giants"
}
```

Then we can register this Service type with properties like so:

```swift
container.register(Person.self) { r in
    let person = Person()
    person.name = r.property("name")
    person.count = r.property("count")
    person.team = r.property("team")!
}
```

This will resolve the person as:

```swift
let person = container.resolve(Person.self)!
person.name // "Mike"
person.count // 100
person.team // "Giants"
```

Properties are available on a per-container basis. Multiple property loaders can be
applied to a single container. Properties are merged in the order in which they
are applied to a container. For example, let's say you have 2 property files:

```json
{
    "message": "hello from A",
    "count": 10
}
```

And:

```json
{
    "message": "hello from B",
    "timeout": 4
}
```

If we apply property file A, then property file B to the container, the resulting
property key-value pairs would be:

```swift
message = "hello from B"
count = 10
timeout = 4
```

As you can see the `message` property was overridden. This only works for first-level
properties which means `Dictionary` and `Array` are not merged. For example:

```json
{
    "items": [
        "hello from A"
    ]
}
```
And:

```json
{
     "items": [
        "hello from B"
     ]
}
```

The resulting value for `items` would be: `[ "hello from B" ]`

### TOML Dot Notation Example

TOML's nested table structure is particularly useful for organizing hierarchical configuration:

```toml
# config.toml
[api]
base_url = "https://api.example.com"
timeout = 30
api_key = "secret123"

[database]
host = "localhost"
port = 5432
name = "myapp"

[packages.unlimited]
cost = 99.99
features = ["feature1", "feature2", "feature3"]

[packages.basic]
cost = 9.99
features = ["feature1"]
```

This automatically becomes accessible via dot notation:

```swift
container.register(APIClient.self) { r in
    let client = APIClient()
    client.baseURL = r.property("api.base_url")      // "https://api.example.com"
    client.timeout = r.property("api.timeout")        // 30
    client.apiKey = r.property("api.api_key")        // "secret123"
    return client
}

container.register(Database.self) { r in
    let db = Database()
    db.host = r.property("database.host")!           // "localhost"
    db.port = r.property("database.port")!           // 5432
    db.name = r.property("database.name")!           // "myapp"
    return db
}

container.register(PricingService.self) { r in
    let service = PricingService()
    service.unlimitedCost = r.property("packages.unlimited.cost")!  // 99.99
    return service
}
```

### Struct Reflection Example

For type-safe, programmatic configuration without external files, use `StructPropertyLoader`:

```swift
// Define a configuration struct
struct AppConfig: Sendable {
    struct API: Sendable {
        let baseURL = "https://api.example.com"
        let timeout = 30
        let apiKey = "secret123"
    }

    let api = API()
    let appName = "MyApp"
    let debugMode = false
}

// Load properties from struct instance
let config = AppConfig()
let loader = StructPropertyLoader(config)
try container.applyPropertyLoader(loader)

// Access with dot notation (nested structs are auto-flattened)
container.register(APIClient.self) { r in
    let client = APIClient()
    client.baseURL = r.property("api.baseURL")!     // "https://api.example.com"
    client.timeout = r.property("api.timeout")!     // 30
    client.apiKey = r.property("api.apiKey")!       // "secret123"
    return client
}

let appName: String? = container.property("appName")         // "MyApp"
let debugMode: Bool? = container.property("debugMode")       // false
```

**Benefits of StructPropertyLoader:**
- **Type-safe**: Compile-time checking of property types
- **No files**: Pure Swift configuration, no external resources
- **Dot notation**: Nested structs automatically flatten (like TOML)
- **Testing**: Perfect for default configs and test fixtures
- **Optionals**: Nil optionals are automatically skipped

### Type-Safe Property Keys

For better autocomplete, compile-time safety, and refactoring support, use `PropertyKey` instead of strings:

```swift
// Define your keys (anywhere in any module)
extension PropertyKey {
    // Recommended: Explicit constructor (self-documenting)
    static let apiBaseURL = PropertyKey("api.baseURL")
    static let apiTimeout = PropertyKey("api.timeout")
    static let apiKey = PropertyKey("api.key")

    // Alternative: String literal with type annotation (also valid)
    static let debugMode: PropertyKey = "debug.enabled"
}

// Type-safe access with autocomplete
container.register(APIClient.self) { r in
    let client = APIClient()

    // Type-safe property access
    client.baseURL = r.property(.apiBaseURL)
    client.timeout = r.property(.apiTimeout) ?? 30  // Use ?? for defaults

    return client
}
```

**Benefits:**
- ✅ **Autocomplete**: All defined keys appear in Xcode autocomplete
- ✅ **Type-safe**: Compiler catches typos and missing keys
- ✅ **Refactoring**: Rename works correctly across your codebase
- ✅ **Extensible**: Define keys in any module via extensions
- ✅ **Backward compatible**: String-based API still works


## Contributors

SwinjectPropertyLoader has been originally written by [Mike Owens](https://github.com/mowens).

## License

MIT license. See the [LICENSE file](LICENSE.txt) for details.
