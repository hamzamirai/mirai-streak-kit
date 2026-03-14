import Foundation

/// Events that can be tracked for streak analytics.
public enum StreakEvent: Sendable, Equatable {
    /// A streak was updated (continued or started).
    ///
    /// - Parameters:
    ///   - length: The new streak length after the update.
    ///   - isNewStreak: Whether this started a new streak (length == 1).
    case streakUpdated(length: Int, isNewStreak: Bool)

    /// A streak milestone was reached.
    ///
    /// - Parameters:
    ///   - length: The milestone length reached.
    ///   - earnedToken: Whether a freeze token was earned at this milestone.
    case milestoneReached(length: Int, earnedToken: Bool)

    /// A streak was broken (reset to 0 or 1).
    ///
    /// - Parameters:
    ///   - previousLength: The length before the break.
    ///   - bestStreak: The best streak at time of break.
    case streakBroken(previousLength: Int, bestStreak: Int)

    /// A freeze token was used successfully.
    ///
    /// - Parameters:
    ///   - tokensRemaining: The number of tokens remaining after use.
    case freezeTokenUsed(tokensRemaining: Int)

    /// A new best streak was achieved.
    ///
    /// - Parameters:
    ///   - newBest: The new best streak length.
    ///   - previousBest: The previous best streak length.
    case newBestStreakAchieved(newBest: Int, previousBest: Int)
}

/// A protocol for receiving streak event notifications for analytics tracking.
///
/// Implement this protocol to track streak events in your analytics service.
///
/// ## Example
///
/// ```swift
/// final class MyAnalyticsDelegate: StreakAnalyticsDelegate {
///     func streakEventOccurred(_ event: StreakEvent, manager: StreakManager) {
///         switch event {
///         case .streakUpdated(let length, let isNew):
///             analytics.track("streak_updated", properties: [
///                 "length": length,
///                 "is_new": isNew
///             ])
///         case .milestoneReached(let length, let earnedToken):
///             analytics.track("milestone_reached", properties: [
///                 "length": length,
///                 "earned_token": earnedToken
///             ])
///         // Handle other events...
///         default:
///             break
///         }
///     }
/// }
///
/// // Set the delegate
/// manager.analyticsDelegate = MyAnalyticsDelegate()
/// ```
@MainActor
public protocol StreakAnalyticsDelegate: AnyObject, Sendable {
    /// Called when a streak event occurs.
    ///
    /// - Parameters:
    ///   - event: The event that occurred.
    ///   - manager: The streak manager that triggered the event.
    func streakEventOccurred(_ event: StreakEvent, manager: StreakManager)
}
