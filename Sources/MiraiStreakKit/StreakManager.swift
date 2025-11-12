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

        /// The milestone interval for earning freeze tokens.
        ///
        /// Users earn one freeze token each time they reach a multiple of this value.
        /// For example, with `tokenMilestone = 7`, users earn tokens at 7, 14, 21 days, etc.
        public var tokenMilestone: Int

        /// Optional timezone pinning for streak calculations.
        ///
        /// When set, all date comparisons use this timezone regardless of device timezone.
        /// Useful for travelers or apps targeting users in specific regions.
        ///
        /// If `nil`, uses the calendar's default timezone.
        public var pinnedTimeZone: TimeZone?

        /// Creates a new configuration.
        ///
        /// - Parameters:
        ///   - calendar: The calendar to use. Defaults to the current calendar.
        ///   - tokenMilestone: The streak length interval for earning tokens. Defaults to 7 days.
        ///   - pinnedTimeZone: Optional timezone to pin streak calculations to. Defaults to nil.
        public init(
            calendar: Calendar = .current,
            tokenMilestone: Int = 7,
            pinnedTimeZone: TimeZone? = nil
        ) {
            var mutableCalendar = calendar
            if let pinnedTimeZone {
                mutableCalendar.timeZone = pinnedTimeZone
            }
            self.calendar = mutableCalendar
            self.tokenMilestone = tokenMilestone
            self.pinnedTimeZone = pinnedTimeZone
        }
    }

    /// The current streak data (observable).
    ///
    /// SwiftUI views that read this property will automatically update when it changes.
    public private(set) var streak: Streak

    /// The manager's configuration.
    public var config: Config

    /// Optional analytics delegate for tracking streak events.
    ///
    /// Set this to receive notifications about important streak events
    /// such as updates, milestones, breaks, and freeze token usage.
    public weak var analyticsDelegate: (any StreakAnalyticsDelegate)?

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
    /// - Automatically updates best streak if current exceeds it
    /// - Awards freeze tokens at milestone intervals
    /// - Fires analytics events for tracking
    ///
    /// Changes are automatically persisted to the store.
    ///
    /// - Parameter date: The date to update for. Defaults to the current date.
    public func updateStreak(on date: Date = .now) {
        let previousLength = streak.length
        let previousBest = streak.bestStreak
        var streakWasBroken = false

        switch streak.determineOutcome(on: date, calendar: config.calendar) {
        case .alreadyCompletedToday:
            return
        case .streakContinues:
            streak.lastDate = date
            streak.length += 1
        case .streakBroken:
            streakWasBroken = true
            streak.lastDate = date
            streak.length = 1
        }

        let isNewStreak = streak.length == 1

        // Fire streak broken event
        if streakWasBroken && previousLength > 0 {
            analyticsDelegate?.streakEventOccurred(
                .streakBroken(previousLength: previousLength, bestStreak: previousBest),
                manager: self
            )
        }

        // Update best streak if current streak exceeds it
        if streak.length > streak.bestStreak {
            streak.bestStreak = streak.length

            // Fire new best streak event
            if streak.length > previousBest {
                analyticsDelegate?.streakEventOccurred(
                    .newBestStreakAchieved(newBest: streak.length, previousBest: previousBest),
                    manager: self
                )
            }
        }

        // Award freeze token at milestones
        var earnedToken = false
        if config.tokenMilestone > 0 &&
           streak.length % config.tokenMilestone == 0 &&
           streak.length > previousLength {
            streak.freezeTokens += 1
            earnedToken = true
        }

        // Fire milestone event if at milestone
        if config.tokenMilestone > 0 &&
           streak.length % config.tokenMilestone == 0 &&
           streak.length > 0 {
            analyticsDelegate?.streakEventOccurred(
                .milestoneReached(length: streak.length, earnedToken: earnedToken),
                manager: self
            )
        }

        // Fire streak updated event
        analyticsDelegate?.streakEventOccurred(
            .streakUpdated(length: streak.length, isNewStreak: isNewStreak),
            manager: self
        )

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

    /// Gets the best (longest) streak ever achieved.
    ///
    /// - Returns: The best streak length.
    public func getBestStreak() -> Int {
        return streak.bestStreak
    }

    /// Uses a freeze token to protect the streak from breaking.
    ///
    /// This method should be called when a user wants to use a freeze token
    /// to prevent their streak from resetting after missing a day.
    ///
    /// A freeze can only be used if:
    /// - The user has available freeze tokens
    /// - The streak is currently broken (missed days exist)
    /// - A freeze hasn't already been used for this gap
    ///
    /// - Parameter date: The date to apply the freeze for. Defaults to the current date.
    /// - Returns: `true` if the freeze was successfully applied, `false` otherwise.
    @discardableResult
    public func useFreeze(on date: Date = .now) -> Bool {
        // Check if user has tokens
        guard streak.freezeTokens > 0 else {
            return false
        }

        // Check if streak is broken
        guard streak.determineOutcome(on: date, calendar: config.calendar) == .streakBroken else {
            return false
        }

        // Check if freeze already used for this gap
        if let lastFreezeDate = streak.lastFreezeDate,
           let lastDate = streak.lastDate,
           config.calendar.isDate(lastFreezeDate, inSameDayAs: lastDate) {
            return false
        }

        // Use the freeze token
        streak.freezeTokens -= 1
        streak.lastFreezeDate = date
        streak.lastDate = date
        // Don't increment length - just maintain it

        // Fire freeze token used event
        analyticsDelegate?.streakEventOccurred(
            .freezeTokenUsed(tokensRemaining: streak.freezeTokens),
            manager: self
        )

        save()
        return true
    }

    /// Checks if a freeze token can be used for the current streak state.
    ///
    /// - Parameter date: The date to check for. Defaults to the current date.
    /// - Returns: `true` if a freeze token can be used, `false` otherwise.
    public func canUseFreeze(on date: Date = .now) -> Bool {
        guard streak.freezeTokens > 0 else {
            return false
        }

        guard streak.determineOutcome(on: date, calendar: config.calendar) == .streakBroken else {
            return false
        }

        if let lastFreezeDate = streak.lastFreezeDate,
           let lastDate = streak.lastDate,
           config.calendar.isDate(lastFreezeDate, inSameDayAs: lastDate) {
            return false
        }

        return true
    }

    /// Gets the number of available freeze tokens.
    ///
    /// - Returns: The number of freeze tokens.
    public func getFreezeTokens() -> Int {
        return streak.freezeTokens
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
