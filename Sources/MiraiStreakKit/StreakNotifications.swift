import Foundation
#if canImport(UserNotifications)
import UserNotifications

/// A manager for scheduling streak reminder notifications.
///
/// Use this class to schedule daily reminders that encourage users to maintain their streaks.
/// Reminders are only sent if the user hasn't completed their streak for the day.
///
/// ## Example
///
/// ```swift
/// let notificationManager = StreakNotificationManager(streakManager: manager)
///
/// // Request notification permission
/// await notificationManager.requestAuthorization()
///
/// // Schedule daily reminder at 8 PM
/// await notificationManager.scheduleDailyReminder(at: DateComponents(hour: 20, minute: 0))
/// ```
@MainActor
public final class StreakNotificationManager {
    /// Configuration for the notification manager.
    public struct Config: Sendable {
        /// The notification identifier for streak reminders.
        public var identifier: String

        /// The notification title.
        public var title: String

        /// The notification body template.
        ///
        /// Use `{streak}` as a placeholder for the current streak length.
        public var bodyTemplate: String

        /// The sound to play with the notification.
        public var sound: UNNotificationSound

        /// Creates a new notification configuration.
        ///
        /// - Parameters:
        ///   - identifier: The notification identifier. Defaults to "streakReminder".
        ///   - title: The notification title. Defaults to "Don't Break Your Streak!".
        ///   - bodyTemplate: The notification body template. Defaults to "You're on a {streak}-day streak. Check in today!".
        ///   - sound: The notification sound. Defaults to `.default`.
        public init(
            identifier: String = "streakReminder",
            title: String = "Don't Break Your Streak!",
            bodyTemplate: String = "You're on a {streak}-day streak. Check in today!",
            sound: UNNotificationSound = .default
        ) {
            self.identifier = identifier
            self.title = title
            self.bodyTemplate = bodyTemplate
            self.sound = sound
        }
    }

    private let streakManager: StreakManager
    private let notificationCenter: UNUserNotificationCenter
    private let config: Config

    /// Creates a new notification manager.
    ///
    /// - Parameters:
    ///   - streakManager: The streak manager to check streak status.
    ///   - notificationCenter: The notification center to use. Defaults to `.current()`.
    ///   - config: The notification configuration. Defaults to `.init()`.
    public init(
        streakManager: StreakManager,
        notificationCenter: UNUserNotificationCenter = .current(),
        config: Config = .init()
    ) {
        self.streakManager = streakManager
        self.notificationCenter = notificationCenter
        self.config = config
    }

    /// Requests notification authorization from the user.
    ///
    /// - Returns: `true` if authorization was granted, `false` otherwise.
    @discardableResult
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Schedules a daily reminder at the specified time.
    ///
    /// The reminder will only be delivered if the user hasn't completed their streak for the day.
    ///
    /// - Parameter time: The time to deliver the reminder (hour and minute required).
    /// - Returns: `true` if the reminder was scheduled successfully, `false` otherwise.
    @discardableResult
    public func scheduleDailyReminder(at time: DateComponents) async -> Bool {
        guard time.hour != nil, time.minute != nil else {
            return false
        }

        // Remove existing reminders
        await cancelReminders()

        // Only schedule if user hasn't completed today
        guard !streakManager.hasCompletedStreak() else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = config.title

        let currentStreak = streakManager.getStreakLength()
        let body = config.bodyTemplate.replacingOccurrences(of: "{streak}", with: "\(currentStreak)")
        content.body = body
        content.sound = config.sound

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: config.identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            return false
        }
    }

    /// Cancels all scheduled streak reminders.
    public func cancelReminders() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [config.identifier])
    }

    /// Checks if reminders are currently scheduled.
    ///
    /// - Returns: `true` if reminders are scheduled, `false` otherwise.
    public func hasScheduledReminders() async -> Bool {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.contains { $0.identifier == config.identifier }
    }

    /// Reschedules the reminder after a streak check-in.
    ///
    /// Call this method after the user checks in to ensure the reminder is updated
    /// with the new streak length for the next day.
    public func rescheduleAfterCheckIn() async {
        guard let requests = try? await notificationCenter.pendingNotificationRequests().first(where: { $0.identifier == config.identifier }),
              let trigger = requests.trigger as? UNCalendarNotificationTrigger else {
            return
        }

        let time = trigger.dateComponents
        await scheduleDailyReminder(at: time)
    }
}

#endif
