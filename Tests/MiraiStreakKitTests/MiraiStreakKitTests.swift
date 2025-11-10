import Foundation
import Testing
@testable import MiraiStreakKit

@Suite
struct StreakLogicTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func sameDayCheckInReturnsAlreadyCompleted() throws {
        let last = DateComponents(calendar: calendar, year: 2025, month: 10, day: 18, hour: 9).date!
        let now = DateComponents(calendar: calendar, year: 2025, month: 10, day: 18, hour: 13).date!
        let streak = Streak(length: 3, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: calendar) == .alreadyCompletedToday)
    }

    @Test
    func nextDayWithinWindowContinues() throws {
        let last = DateComponents(calendar: calendar, year: 2025, month: 10, day: 18, hour: 23, minute: 59).date!
        let now = DateComponents(calendar: calendar, year: 2025, month: 10, day: 19, hour: 0, minute: 1).date!
        let streak = Streak(length: 3, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: calendar) == .streakContinues)
    }

    @Test
    func missingFullDayBreaksStreak() throws {
        let last = DateComponents(calendar: calendar, year: 2025, month: 10, day: 10, hour: 12).date!
        let now = DateComponents(calendar: calendar, year: 2025, month: 10, day: 12, hour: 12).date!
        let streak = Streak(length: 8, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: calendar) == .streakBroken)
    }

    @Test
    @MainActor
    func managerUpdatesLengthAndPersists() throws {
        let last = DateComponents(calendar: calendar, year: 2025, month: 10, day: 18, hour: 9).date!
        let now = DateComponents(calendar: calendar, year: 2025, month: 10, day: 19, hour: 12).date!
        let store = InMemoryStore()
        let manager = StreakManager(store: store, config: .init(calendar: calendar))

        manager.updateStreak(on: last)
        #expect(manager.streak.length == 1)

        manager.updateStreak(on: now)
        #expect(manager.streak.length == 2)
        #expect(manager.streak.lastDate == now)

        #expect(store.writeCount == 2)
    }

    @Test
    @MainActor
    func managerResetsLengthAfterMissedDay() throws {
        let dayOne = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 8).date!
        let dayTwo = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 8).date!
        let dayFour = DateComponents(calendar: calendar, year: 2025, month: 10, day: 4, hour: 9).date!
        let store = InMemoryStore()
        let manager = StreakManager(store: store, config: .init(calendar: calendar))

        manager.updateStreak(on: dayOne)
        manager.updateStreak(on: dayTwo)

        #expect(manager.streak.length == 2)

        let length = manager.getStreakLength(on: dayFour)
        #expect(length == 0)
        #expect(manager.streak.length == 0)
        #expect(manager.streak.lastDate == nil)
    }
}

private final class InMemoryStore: StreakStore, @unchecked Sendable {
    private(set) var data: Data?
    private(set) var readCount = 0
    private(set) var writeCount = 0

    func read() -> Data? {
        readCount += 1
        return data
    }

    func write(_ data: Data) throws {
        writeCount += 1
        self.data = data
    }
}
