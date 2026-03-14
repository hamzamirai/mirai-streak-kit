import Foundation

/// A protocol for storing and retrieving streak data.
///
/// Implement this protocol to create custom persistence backends.
/// All implementations must be thread-safe (`Sendable`).
///
/// ## Example
///
/// ```swift
/// struct MyCustomStore: StreakStore {
///     func read() -> Data? {
///         // Your read implementation
///     }
///
///     func write(_ data: Data) throws {
///         // Your write implementation
///     }
/// }
/// ```
public protocol StreakStore: Sendable {
    /// Reads persisted streak data.
    ///
    /// - Returns: The stored data, or nil if no data exists.
    func read() -> Data?
    
    /// Writes streak data to persistent storage.
    ///
    /// - Parameter data: The encoded streak data to store.
    /// - Throws: An error if the write operation fails.
    func write(_ data: Data) throws
}

/// A streak store that persists data to UserDefaults.
///
/// This is the default store and works well for simple use cases.
/// Data is stored unencrypted in the app's UserDefaults.
///
/// ## Example
///
/// ```swift
/// let store = UserDefaultsStore(defaults: .standard, key: "appStreak")
/// let manager = StreakManager(store: store)
/// ```
public struct UserDefaultsStore: StreakStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    /// Creates a UserDefaults-based streak store.
    ///
    /// - Parameters:
    ///   - defaults: The UserDefaults instance to use. Defaults to `.standard`.
    ///   - key: The key under which to store streak data. Defaults to "MiraiStreak".
    public init(defaults: UserDefaults = .standard, key: String = "MiraiStreak") {
        self.defaults = defaults
        self.key = key
    }

    public func read() -> Data? {
        defaults.data(forKey: key)
    }

    public func write(_ data: Data) throws {
        defaults.set(data, forKey: key)
    }
}

/// A streak store that persists data to a JSON file in the Documents directory.
///
/// Use this store when you need file-based persistence or want to
/// inspect/export streak data easily.
///
/// ## Example
///
/// ```swift
/// let store = FileStore(filename: "myStreak.json")
/// let manager = StreakManager(store: store)
/// ```
public struct FileStore: StreakStore {
    private let url: URL

    /// Creates a file-based streak store.
    ///
    /// - Parameter filename: The name of the file to store data in. Defaults to "MiraiStreak.json".
    ///                       The file will be created in the Documents directory.
    public init(filename: String = "MiraiStreak.json") {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.url = directory.appendingPathComponent(filename)
    }

    public func read() -> Data? {
        try? Data(contentsOf: url)
    }

    public func write(_ data: Data) throws {
        try data.write(to: url, options: .atomic)
    }
}

/// A streak store that persists data to a shared App Group container.
///
/// Use this store to share streak data between your app and extensions
/// (widgets, Watch app, etc.).
///
/// ## Example
///
/// ```swift
/// let store = AppGroupStore(appGroup: "group.com.mycompany.myapp")
/// let manager = StreakManager(store: store)
/// ```
///
/// - Important: You must configure the App Group capability in your
///              app and extension targets.
public struct AppGroupStore: StreakStore, @unchecked Sendable {
    private let store: UserDefaults
    private let key: String

    /// Creates an App Group-based streak store.
    ///
    /// - Parameters:
    ///   - appGroup: The App Group identifier (e.g., "group.com.mycompany.myapp").
    ///   - key: The key under which to store streak data. Defaults to "MiraiStreak".
    public init(appGroup: String, key: String = "MiraiStreak") {
        self.store = UserDefaults(suiteName: appGroup) ?? .standard
        self.key = key
    }

    public func read() -> Data? {
        store.data(forKey: key)
    }

    public func write(_ data: Data) throws {
        store.set(data, forKey: key)
    }
}
