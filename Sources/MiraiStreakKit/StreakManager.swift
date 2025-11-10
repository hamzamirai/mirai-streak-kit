import Foundation
import Observation

/// The main observable class for managing streak state.
///
/// `StreakManager` is isolated to the `@MainActor` for safe SwiftUI integration.
/// It uses Swift's Observation framework, so SwiftUI views automatically update
/// when the streak changes.
///
/// ## Example
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .setupMiraiStreak()
///         }
///     }
/// }
///
/// struct ContentView: View {
///     @Environment(StreakManager.self) private var manager
///
///     var body: some View {
///         VStack {
///             Text("Streak: \(manager.getStreakLength())")
///             Button("Check In") {
///                 manager.updateStreak()
///             }
///         }
///     }
/// }
/// ```
@MainActor
@Observable
public final class StreakManager {
    /// Configuration for the streak manager.
    public struct Config: Sendable, Equatable {
        /// The calendar to use for date comparisons.
        public var calendar: Calendar

        /// Creates a new configuration.
        ///
        /// - Parameter calendar: The calendar to use. Defaults to the current calendar.
        public init(calendar: Calendar = .current) {
            self.calendar = calendar
        }
    }

    /// The current streak data (observable).
    ///
    /// SwiftUI views that read this property will automatically update when it changes.
    public private(set) var streak: Streak
    
    /// The manager's configuration.
    public var config: Config

    private let store: any StreakStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a new streak manager.
    ///
    /// - Parameters:
    ///   - store: The persistence store to use. Defaults to `UserDefaultsStore()`.
    ///   - config: The manager configuration. Defaults to `.init()`.
    public init(
        store: any StreakStore = UserDefaultsStore(),
        config: Config = .init()
    ) {
        self.store = store
        self.config = config
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.streak = Self.load(from: store, using: decoder) ?? Streak()
    }

    /// Updates the streak for a given date.
    ///
    /// This method:
    /// - Does nothing if already completed today
    /// - Increments the streak if continuing from yesterday
    /// - Resets to 1 if the streak was broken
    ///
    /// Changes are automatically persisted to the store.
    ///
    /// - Parameter date: The date to update for. Defaults to the current date.
    public func updateStreak(on date: Date = .now) {
        switch streak.determineOutcome(on: date, calendar: config.calendar) {
        case .alreadyCompletedToday:
            return
        case .streakContinues:
            streak.lastDate = date
            streak.length += 1
        case .streakBroken:
            streak.lastDate = date
            streak.length = 1
        }

        save()
    }

    /// Gets the current streak length, resetting if broken.
    ///
    /// This method checks if the streak is still valid. If it has been broken
    /// (a day was skipped), it resets the streak to 0 and persists the change.
    ///
    /// - Parameter date: The date to check against. Defaults to the current date.
    /// - Returns: The current streak length (may be 0 if broken).
    @discardableResult
    public func getStreakLength(on date: Date = .now) -> Int {
        if streak.determineOutcome(on: date, calendar: config.calendar) == .streakBroken {
            streak.length = 0
            streak.lastDate = nil
            save()
        }

        return streak.length
    }

    /// Checks if the streak has been completed on a given date.
    ///
    /// - Parameter date: The date to check. Defaults to the current date.
    /// - Returns: `true` if a check-in occurred on the given date, `false` otherwise.
    public func hasCompletedStreak(on date: Date = .now) -> Bool {
        guard let lastDate = streak.lastDate else {
            return false
        }

        return config.calendar.isDate(date, inSameDayAs: lastDate)
    }

    private func save() {
        guard let data = try? encoder.encode(streak) else { return }
        try? store.write(data)
    }

    private static func load(from store: any StreakStore, using decoder: JSONDecoder) -> Streak? {
        guard let data = store.read() else { return nil }
        return try? decoder.decode(Streak.self, from: data)
    }
}
