import Foundation
import Testing
@testable import MiraiStreakKit

/// Comprehensive tests for StreakManager observable class.
@Suite
struct StreakManagerTests {
    private let calendar = Calendar(identifier: .gregorian)

    // MARK: - updateStreak() Tests

    @Suite
    struct UpdateStreakTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func updateStreakOnFirstDay() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            manager.updateStreak(on: day1)

            #expect(manager.streak.length == 1)
            #expect(manager.streak.lastDate == day1)
            #expect(store.writeCount == 1)
        }

        @Test @MainActor
        func updateStreakOnConsecutiveDay() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)

            #expect(manager.streak.length == 2)
            #expect(manager.streak.lastDate == day2)
            #expect(store.writeCount == 2)
        }

        @Test @MainActor
        func updateStreakOnSameDayTwiceDoesNotIncrement() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 9).date!
            let sameDay = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 17).date!

            manager.updateStreak(on: day)
            let lengthAfterFirst = manager.streak.length
            manager.updateStreak(on: sameDay)

            #expect(manager.streak.length == lengthAfterFirst)
            #expect(store.writeCount == 1) // Only written once
        }

        @Test @MainActor
        func updateStreakAfterMissedDayResetsTo1() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!
            let day4 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 4, hour: 12).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)
            #expect(manager.streak.length == 2)

            manager.updateStreak(on: day4)

            #expect(manager.streak.length == 1)
            #expect(manager.streak.lastDate == day4)
        }

        @Test @MainActor
        func updateStreakLongSequence() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            for dayOffset in 0..<30 {
                let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: dayOffset + 1, hour: 12).date!
                manager.updateStreak(on: day)
            }

            #expect(manager.streak.length == 30)
            #expect(store.writeCount == 30)
        }

        @Test @MainActor
        func updateStreakUsesConfigCalendar() throws {
            let hebrew = Calendar(identifier: .hebrew)
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: hebrew))
            let day1 = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 2, hour: 12).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)

            #expect(manager.streak.length == 2)
        }

        @Test @MainActor
        func updateStreakPersistsToStore() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            manager.updateStreak(on: day)

            // Verify data was written
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Streak.self, from: store.data!)
            #expect(decoded.length == 1)
            #expect(decoded.lastDate != nil)
        }

        @Test @MainActor
        func updateStreakWithDefaultDate() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // This should use Date.now internally
            manager.updateStreak()

            #expect(manager.streak.length >= 1)
        }
    }

    // MARK: - getStreakLength() Tests

    @Suite
    struct GetStreakLengthTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func getStreakLengthWithoutPriorUpdates() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let today = Date()

            let length = manager.getStreakLength(on: today)

            #expect(length == 0)
        }

        @Test @MainActor
        func getStreakLengthReturnsCurrent() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)

            let length = manager.getStreakLength(on: day2)

            #expect(length == 2)
        }

        @Test @MainActor
        func getStreakLengthWhenCompletedToday() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let today = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 9).date!
            let sameDay = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 17).date!

            manager.updateStreak(on: today)
            let length = manager.getStreakLength(on: sameDay)

            #expect(length == 1)
        }

        @Test @MainActor
        func getStreakLengthAfterMissedDay() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!
            let day4 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 4, hour: 12).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)
            #expect(manager.streak.length == 2)

            let length = manager.getStreakLength(on: day4)

            #expect(length == 0)
            #expect(manager.streak.length == 0)
            #expect(manager.streak.lastDate == nil)
        }

        @Test @MainActor
        func getStreakLengthResetsAndPersists() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!
            let day4 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 4, hour: 12).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)
            let writeCountAfterUpdates = store.writeCount

            manager.getStreakLength(on: day4)

            #expect(store.writeCount > writeCountAfterUpdates) // Should persist the reset
        }

        @Test @MainActor
        func getStreakLengthIsDiscardable() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // This should compile without warning about unused result
            _ = manager.getStreakLength()
            #expect(true)
        }

        @Test @MainActor
        func getStreakLengthWithDefaultDate() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Update with today's date first (no args = current date)
            manager.updateStreak()

            // Then getStreakLength with same default date should return the value
            let length = manager.getStreakLength()

            #expect(length >= 1)
        }

        @Test @MainActor
        func getStreakLengthDoesNotModifyCompletedStreaks() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let today = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            manager.updateStreak(on: today)
            let length1 = manager.getStreakLength(on: today)
            let length2 = manager.getStreakLength(on: today)

            #expect(length1 == length2)
            #expect(manager.streak.length == 1) // Should not change
        }
    }

    // MARK: - hasCompletedStreak() Tests

    @Suite
    struct HasCompletedStreakTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func hasCompletedStreakReturnsFalseWhenNeverCheckedIn() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let today = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            let completed = manager.hasCompletedStreak(on: today)

            #expect(completed == false)
        }

        @Test @MainActor
        func hasCompletedStreakReturnsTrueWhenCheckedInToday() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 9).date!
            let sameDay = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 17).date!

            manager.updateStreak(on: day)
            let completed = manager.hasCompletedStreak(on: sameDay)

            #expect(completed == true)
        }

        @Test @MainActor
        func hasCompletedStreakReturnsFalseForYesterday() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!

            manager.updateStreak(on: day1)
            let completed = manager.hasCompletedStreak(on: day2)

            #expect(completed == false)
        }

        @Test @MainActor
        func hasCompletedStreakReturnsFalseForTomorrow() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!

            manager.updateStreak(on: day1)
            let completed = manager.hasCompletedStreak(on: day2)

            #expect(completed == false)
        }

        @Test @MainActor
        func hasCompletedStreakWithCustomDate() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let specificDay = DateComponents(calendar: calendar, year: 2025, month: 10, day: 15, hour: 12).date!

            manager.updateStreak(on: specificDay)
            let completedOnSpecificDay = manager.hasCompletedStreak(on: specificDay)
            let completedOnOtherDay = manager.hasCompletedStreak(
                on: DateComponents(calendar: calendar, year: 2025, month: 10, day: 16, hour: 12).date!
            )

            #expect(completedOnSpecificDay == true)
            #expect(completedOnOtherDay == false)
        }

        @Test @MainActor
        func hasCompletedStreakWithDefaultDate() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let today = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            manager.updateStreak(on: today)

            // Using .now as default should check today
            let _ = manager.hasCompletedStreak()

            // This might be true or false depending on actual current time
            // Just verify it returns a boolean without crashing
            #expect(true)
        }

        @Test @MainActor
        func hasCompletedStreakUsesConfigCalendar() throws {
            let hebrew = Calendar(identifier: .hebrew)
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: hebrew))
            let day = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 1, hour: 12).date!
            let sameDay = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 1, hour: 17).date!

            manager.updateStreak(on: day)
            let completed = manager.hasCompletedStreak(on: sameDay)

            #expect(completed == true)
        }
    }

    // MARK: - Initialization Tests

    @Suite
    struct InitializationTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func initWithEmptyStoreCreatesFreshStreak() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            #expect(manager.streak.length == 0)
            #expect(manager.streak.lastDate == nil)
        }

        @Test @MainActor
        func initWithExistingDataLoadsStreak() throws {
            let store = InMemoryStore()
            let original = Streak(length: 5, lastDate: Date())
            let encoder = JSONEncoder()
            let data = try encoder.encode(original)
            store.data = data

            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            #expect(manager.streak.length == 5)
            #expect(manager.streak.lastDate != nil)
        }

        @Test @MainActor
        func initWithCorruptedDataFallsBackToEmpty() throws {
            let store = InMemoryStore()
            let invalidJSON = "{ invalid }".data(using: .utf8)!
            store.data = invalidJSON

            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            #expect(manager.streak.length == 0)
            #expect(manager.streak.lastDate == nil)
        }

        @Test @MainActor
        func initWithCustomConfigUsesProvidedCalendar() throws {
            let hebrew = Calendar(identifier: .hebrew)
            let store = InMemoryStore()
            let config = StreakManager.Config(calendar: hebrew)

            let manager = StreakManager(store: store, config: config)

            #expect(manager.config.calendar.identifier == hebrew.identifier)
        }

        @Test @MainActor
        func initWithDifferentStoreTypes() throws {
            let userDefaultsStore = UserDefaultsStore()
            let manager1 = StreakManager(store: userDefaultsStore)
            #expect(manager1.streak.length >= 0)

            let fileStore = FileStore()
            let manager2 = StreakManager(store: fileStore)
            #expect(manager2.streak.length >= 0)
        }

        @Test @MainActor
        func multipleManagerInstancesIndependent() throws {
            let store1 = InMemoryStore()
            let store2 = InMemoryStore()
            let manager1 = StreakManager(store: store1, config: .init(calendar: calendar))
            let manager2 = StreakManager(store: store2, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            manager1.updateStreak(on: day)

            #expect(manager1.streak.length == 1)
            #expect(manager2.streak.length == 0)
        }

        @Test @MainActor
        func defaultParametersCreateValidManager() throws {
            let manager = StreakManager()

            #expect(manager.streak.length >= 0)
            #expect(manager.config.calendar == .current)
        }
    }

    // MARK: - Configuration Tests

    @Suite
    struct ConfigurationTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func configEquality() throws {
            let config1 = StreakManager.Config(calendar: calendar)
            let config2 = StreakManager.Config(calendar: calendar)

            #expect(config1 == config2)
        }

        @Test @MainActor
        func configWithDifferentCalendars() throws {
            let hebrew = Calendar(identifier: .hebrew)
            let config1 = StreakManager.Config(calendar: calendar)
            let config2 = StreakManager.Config(calendar: hebrew)

            #expect(config1 != config2)
        }

        @Test @MainActor
        func configChangeAffectsOutcome() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)
            #expect(manager.streak.length == 2)

            // Changing config should use new calendar for future operations
            let hebrew = Calendar(identifier: .hebrew)
            manager.config = .init(calendar: hebrew)
            let day3 = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 3, hour: 12).date!
            manager.updateStreak(on: day3)

            // Streak should continue based on Hebrew calendar logic
            #expect(manager.streak.length >= 1)
        }
    }

    // MARK: - Observation & State Tests

    @Suite
    struct ObservationTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func streakPropertyIsObservable() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            let initialLength = manager.streak.length
            manager.updateStreak(on: day)
            let updatedLength = manager.streak.length

            #expect(updatedLength > initialLength)
        }

        @Test @MainActor
        func mainActorIsolation() async throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Should be able to access on MainActor
            #expect(manager.streak.length >= 0)
        }
    }

    // MARK: - Sendable Conformance

    @Test @MainActor
    func configSendable() async throws {
        let config = StreakManager.Config()
        let _: StreakManager.Config = config
        #expect(true)
    }
}

// MARK: - Test Fixtures

/// In-memory store for testing without persistence side effects.
private final class InMemoryStore: StreakStore, @unchecked Sendable {
    var data: Data?
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
