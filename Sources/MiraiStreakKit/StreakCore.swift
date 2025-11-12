import Foundation

/// A data structure representing a daily streak.
///
/// A streak tracks consecutive days of completion, storing the current length,
/// the best (longest) streak ever achieved, and the last date a check-in occurred.
///
/// ## Example
///
/// ```swift
/// var streak = Streak(length: 5, bestStreak: 10, lastDate: Date())
/// let outcome = streak.determineOutcome(on: Date())
/// ```
public struct Streak: Codable, Sendable, Equatable {
    /// The current length of the streak (number of consecutive days).
    public var length: Int

    /// The best (longest) streak ever achieved.
    public var bestStreak: Int

    /// The last date when a check-in occurred.
    public var lastDate: Date?

    /// Creates a new streak.
    ///
    /// - Parameters:
    ///   - length: The initial streak length. Defaults to 0.
    ///   - bestStreak: The best streak ever achieved. Defaults to 0.
    ///   - lastDate: The last check-in date. Defaults to nil.
    public init(length: Int = 0, bestStreak: Int = 0, lastDate: Date? = nil) {
        self.length = length
        self.bestStreak = bestStreak
        self.lastDate = lastDate
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
