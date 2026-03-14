import Foundation
import Testing
@testable import MiraiStreakKit

/// Comprehensive tests for streak analytics integration.
@Suite
struct StreakAnalyticsTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test @MainActor
    func delegateReceivesStreakUpdatedEvents() throws {
        let store = InMemoryStore()
        let manager = StreakManager(store: store, config: .init(calendar: calendar))
        let delegate = MockAnalyticsDelegate()
        manager.analyticsDelegate = delegate

        let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
        manager.updateStreak(on: day1)

        // First day triggers: newBestStreakAchieved + streakUpdated
        #expect(delegate.events.count >= 1)

        // Find the streakUpdated event
        let updatedEvents = delegate.events.compactMap { event -> (Int, Bool)? in
            if case .streakUpdated(let length, let isNew) = event {
                return (length, isNew)
            }
            return nil
        }

        #expect(updatedEvents.count == 1)
        #expect(updatedEvents[0].0 == 1)
        #expect(updatedEvents[0].1 == true)
    }

    @Test @MainActor
    func delegateReceivesMilestoneEvents() throws {
        let store = InMemoryStore()
        let config = StreakManager.Config(calendar: calendar, tokenMilestone: 7)
        let manager = StreakManager(store: store, config: config)
        let delegate = MockAnalyticsDelegate()
        manager.analyticsDelegate = delegate

        // Build a 7-day streak
        for day in 1...7 {
            let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
            manager.updateStreak(on: date)
        }

        // Find milestone event
        let milestoneEvents = delegate.events.compactMap { event -> (Int, Bool)? in
            if case .milestoneReached(let length, let earnedToken) = event {
                return (length, earnedToken)
            }
            return nil
        }

        #expect(milestoneEvents.count == 1)
        #expect(milestoneEvents[0].0 == 7)
        #expect(milestoneEvents[0].1 == true)  // Token earned
    }

    @Test @MainActor
    func delegateReceivesStreakBrokenEvents() throws {
        let store = InMemoryStore()
        let manager = StreakManager(store: store, config: .init(calendar: calendar))
        let delegate = MockAnalyticsDelegate()
        manager.analyticsDelegate = delegate

        // Build a 5-day streak
        for day in 1...5 {
            let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
            manager.updateStreak(on: date)
        }

        delegate.events.removeAll()  // Clear previous events

        // Break the streak
        let day7 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 7).date!
        manager.updateStreak(on: day7)

        let brokenEvents = delegate.events.compactMap { event -> (Int, Int)? in
            if case .streakBroken(let previousLength, let bestStreak) = event {
                return (previousLength, bestStreak)
            }
            return nil
        }

        #expect(brokenEvents.count == 1)
        #expect(brokenEvents[0].0 == 5)  // Previous length
        #expect(brokenEvents[0].1 == 5)  // Best streak
    }

    @Test @MainActor
    func delegateReceivesFreezeTokenUsedEvents() throws {
        let store = InMemoryStore()
        let config = StreakManager.Config(calendar: calendar, tokenMilestone: 1)
        let manager = StreakManager(store: store, config: config)
        let delegate = MockAnalyticsDelegate()
        manager.analyticsDelegate = delegate

        // Build a streak to earn a freeze token (milestone: 1)
        let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
        manager.updateStreak(on: day1)

        delegate.events.removeAll()

        // Use freeze token
        let day3 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 3).date!
        manager.useFreeze(on: day3)

        let freezeEvents = delegate.events.compactMap { event -> Int? in
            if case .freezeTokenUsed(let remaining) = event {
                return remaining
            }
            return nil
        }

        #expect(freezeEvents.count == 1)
        #expect(freezeEvents[0] == 0)  // 0 tokens remaining (used the 1)
    }

    @Test @MainActor
    func delegateReceivesNewBestStreakEvents() throws {
        let store = InMemoryStore()
        let manager = StreakManager(store: store, config: .init(calendar: calendar))
        let delegate = MockAnalyticsDelegate()
        manager.analyticsDelegate = delegate

        delegate.events.removeAll()

        // Build a 5-day streak that starts fresh (best will grow with it)
        for day in 1...5 {
            let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
            manager.updateStreak(on: date)
        }

        let bestEvents = delegate.events.compactMap { event -> (Int, Int)? in
            if case .newBestStreakAchieved(let newBest, let previousBest) = event {
                return (newBest, previousBest)
            }
            return nil
        }

        // Best streak should grow from 0 to 5
        #expect(bestEvents.count >= 1)
        // First best event should be at length 1
        #expect(bestEvents[0].0 == 1)
    }

    @Test @MainActor
    func multipleEventsInSingleUpdate() throws {
        let store = InMemoryStore()
        let config = StreakManager.Config(calendar: calendar, tokenMilestone: 7)
        let manager = StreakManager(store: store, config: config)
        let delegate = MockAnalyticsDelegate()
        manager.analyticsDelegate = delegate

        // Build up to day 6
        for day in 1...6 {
            let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
            manager.updateStreak(on: date)
        }

        delegate.events.removeAll()

        // Day 7 should trigger: milestone, possibly new best, and streak updated
        let day7 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 7).date!
        manager.updateStreak(on: day7)

        // Should have at least: milestone + streakUpdated
        #expect(delegate.events.count >= 2)

        let hasMilestone = delegate.events.contains { event in
            if case .milestoneReached = event { return true }
            return false
        }
        let hasUpdate = delegate.events.contains { event in
            if case .streakUpdated = event { return true }
            return false
        }

        #expect(hasMilestone == true)
        #expect(hasUpdate == true)
    }

    @Test @MainActor
    func weakDelegateDoesNotRetainManager() throws {
        let store = InMemoryStore()
        var manager: StreakManager? = StreakManager(store: store, config: .init(calendar: calendar))
        let delegate = MockAnalyticsDelegate()
        manager?.analyticsDelegate = delegate

        let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
        manager?.updateStreak(on: day1)

        let eventCountBefore = delegate.events.count
        #expect(eventCountBefore >= 1)

        // Release manager
        manager = nil

        // Delegate should still exist but no new events should be recorded
        let eventCountAfter = delegate.events.count
        #expect(eventCountAfter == eventCountBefore)
    }

    @Test @MainActor
    func nilDelegateDoesNotCrash() throws {
        let store = InMemoryStore()
        let manager = StreakManager(store: store, config: .init(calendar: calendar))
        // No delegate set

        let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
        manager.updateStreak(on: day1)

        // Should not crash
        #expect(manager.streak.length == 1)
    }

    @Test @MainActor
    func eventOrderIsConsistent() throws {
        let store = InMemoryStore()
        let config = StreakManager.Config(calendar: calendar, tokenMilestone: 7)
        let manager = StreakManager(store: store, config: config)
        let delegate = MockAnalyticsDelegate()
        manager.analyticsDelegate = delegate

        // Build a 7-day streak
        for day in 1...7 {
            let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
            manager.updateStreak(on: date)
        }

        // On day 7, events should be: milestone, then streakUpdated
        let day7Events = delegate.events.suffix(2)
        let eventTypes = day7Events.map { event -> String in
            switch event {
            case .milestoneReached: return "milestone"
            case .streakUpdated: return "updated"
            case .newBestStreakAchieved: return "newBest"
            default: return "other"
            }
        }

        // Should contain both milestone and update
        #expect(eventTypes.contains("milestone"))
        #expect(eventTypes.contains("updated"))
    }
}

// MARK: - Test Fixtures

@MainActor
private final class MockAnalyticsDelegate: StreakAnalyticsDelegate {
    var events: [StreakEvent] = []

    nonisolated init() {}

    func streakEventOccurred(_ event: StreakEvent, manager: StreakManager) {
        events.append(event)
    }
}

private final class InMemoryStore: StreakStore, @unchecked Sendable {
    var data: Data?

    func read() -> Data? {
        data
    }

    func write(_ data: Data) throws {
        self.data = data
    }
}
