import Foundation

/// A data structure representing a daily streak.
///
/// A streak tracks consecutive days of completion, storing the current length
/// and the last date a check-in occurred.
///
/// ## Example
///
/// ```swift
/// var streak = Streak(length: 5, lastDate: Date())
/// let outcome = streak.determineOutcome(on: Date())
/// ```
public struct Streak: Codable, Sendable, Equatable {
    /// The current length of the streak (number of consecutive days).
    public var length: Int

    /// The last date when a check-in occurred.
    public var lastDate: Date?

    /// The best (longest) streak ever achieved.
    public var bestStreak: Int

    /// The number of available freeze tokens to protect streaks.
    public var freezeTokens: Int

    /// The last date when a freeze token was used.
    public var lastFreezeDate: Date?

    /// Creates a new streak.
    ///
    /// - Parameters:
    ///   - length: The initial streak length. Defaults to 0.
    ///   - lastDate: The last check-in date. Defaults to nil.
    ///   - bestStreak: The best streak achieved. Defaults to 0.
    ///   - freezeTokens: The number of available freeze tokens. Defaults to 0.
    ///   - lastFreezeDate: The last date a freeze was used. Defaults to nil.
    public init(
        length: Int = 0,
        lastDate: Date? = nil,
        bestStreak: Int = 0,
        freezeTokens: Int = 0,
        lastFreezeDate: Date? = nil
    ) {
        self.length = length
        self.lastDate = lastDate
        self.bestStreak = bestStreak
        self.freezeTokens = freezeTokens
        self.lastFreezeDate = lastFreezeDate
    }

    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case length
        case lastDate
        case bestStreak
        case freezeTokens
        case lastFreezeDate
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(length, forKey: .length)
        try container.encode(lastDate, forKey: .lastDate)
        try container.encode(bestStreak, forKey: .bestStreak)
        try container.encode(freezeTokens, forKey: .freezeTokens)
        try container.encode(lastFreezeDate, forKey: .lastFreezeDate)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        length = try container.decode(Int.self, forKey: .length)
        lastDate = try container.decodeIfPresent(Date.self, forKey: .lastDate)
        // New fields with backward compatibility: default to 0/nil if not present
        bestStreak = try container.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        freezeTokens = try container.decodeIfPresent(Int.self, forKey: .freezeTokens) ?? 0
        lastFreezeDate = try container.decodeIfPresent(Date.self, forKey: .lastFreezeDate)
    }

    /// Possible outcomes when checking a streak against a date.
    public enum Outcome: Sendable, Equatable {
        /// The streak was already completed on the given date.
        case alreadyCompletedToday
        
        /// The streak continues (next consecutive day or first check-in).
        case streakContinues
        
        /// The streak is broken (missed a day).
        case streakBroken
    }

    /// Determines the outcome of a check-in on a specific date.
    ///
    /// This method implements the "next-day window" logic:
    /// - Same day: Already completed
    /// - Next consecutive day: Streak continues
    /// - Skipped day(s): Streak broken
    /// - No prior date: Streak continues (first check-in)
    ///
    /// - Parameters:
    ///   - date: The date to check against. Defaults to the current date.
    ///   - calendar: The calendar to use for date comparisons. Defaults to the current calendar.
    /// - Returns: The outcome of the check-in.
    public func determineOutcome(
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Outcome {
        guard let lastDate else {
            return .streakContinues
        }

        if calendar.isDate(date, inSameDayAs: lastDate) {
            return .alreadyCompletedToday
        }

        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDate) else {
            return .streakContinues
        }

        if calendar.isDate(date, inSameDayAs: nextDay) {
            return .streakContinues
        }

        return .streakBroken
    }
}
