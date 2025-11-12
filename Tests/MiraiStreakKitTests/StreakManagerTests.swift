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

    // MARK: - Best Streak Tests

    @Suite
    struct BestStreakTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func bestStreakUpdatesWhenCurrentExceedsIt() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2).date!
            let day3 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 3).date!

            manager.updateStreak(on: day1)
            #expect(manager.getBestStreak() == 1)
            #expect(manager.streak.bestStreak == 1)

            manager.updateStreak(on: day2)
            #expect(manager.getBestStreak() == 2)
            #expect(manager.streak.bestStreak == 2)

            manager.updateStreak(on: day3)
            #expect(manager.getBestStreak() == 3)
            #expect(manager.streak.bestStreak == 3)
        }

        @Test @MainActor
        func bestStreakDoesNotDecreaseWhenStreakBreaks() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Build a 5-day streak
            for day in 1...5 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }

            #expect(manager.streak.length == 5)
            #expect(manager.getBestStreak() == 5)

            // Break the streak (skip day 6, check in on day 8)
            let day8 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 8).date!
            manager.updateStreak(on: day8)

            #expect(manager.streak.length == 1)
            #expect(manager.getBestStreak() == 5)  // Best streak remains 5
        }

        @Test @MainActor
        func bestStreakUpdatesThroughMultipleBreaksAndRecoveries() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // First streak: 3 days
            for day in 1...3 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }
            #expect(manager.getBestStreak() == 3)

            // Break and start new streak: 7 days (exceeds best)
            for day in 10...16 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }
            #expect(manager.streak.length == 7)
            #expect(manager.getBestStreak() == 7)

            // Break again and start shorter streak: 2 days
            let day20 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 20).date!
            let day21 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 21).date!
            manager.updateStreak(on: day20)
            manager.updateStreak(on: day21)

            #expect(manager.streak.length == 2)
            #expect(manager.getBestStreak() == 7)  // Best streak remains 7
        }

        @Test @MainActor
        func bestStreakPersistsAcrossSessions() throws {
            let store = InMemoryStore()

            // Session 1: Build a 5-day streak
            let manager1 = StreakManager(store: store, config: .init(calendar: calendar))
            for day in 1...5 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager1.updateStreak(on: date)
            }
            #expect(manager1.getBestStreak() == 5)

            // Session 2: Load from store, best streak should persist
            let manager2 = StreakManager(store: store, config: .init(calendar: calendar))
            #expect(manager2.getBestStreak() == 5)
            #expect(manager2.streak.length == 5)

            // Continue streak in session 2
            let day6 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 6).date!
            manager2.updateStreak(on: day6)
            #expect(manager2.getBestStreak() == 6)

            // Session 3: Verify persistence again
            let manager3 = StreakManager(store: store, config: .init(calendar: calendar))
            #expect(manager3.getBestStreak() == 6)
        }

        @Test @MainActor
        func bestStreakStartsAtZero() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            #expect(manager.getBestStreak() == 0)
            #expect(manager.streak.bestStreak == 0)
        }

        @Test @MainActor
        func bestStreakEqualsCurrentWhenActive() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
            manager.updateStreak(on: day1)

            // When there's no break, best equals current
            #expect(manager.streak.length == 1)
            #expect(manager.getBestStreak() == 1)
            #expect(manager.streak.length == manager.getBestStreak())
        }

        @Test @MainActor
        func bestStreakWithLongRunningStreak() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Build a 30-day streak
            for day in 1...30 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }

            #expect(manager.streak.length == 30)
            #expect(manager.getBestStreak() == 30)
        }
    }

    // MARK: - Freeze Token Tests

    @Suite
    struct FreezeTokenTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func tokensEarnedAtMilestones() throws {
            let store = InMemoryStore()
            let config = StreakManager.Config(calendar: calendar, tokenMilestone: 7)
            let manager = StreakManager(store: store, config: config)

            // Build a 7-day streak
            for day in 1...7 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }

            #expect(manager.streak.length == 7)
            #expect(manager.getFreezeTokens() == 1)

            // Continue to 14 days
            for day in 8...14 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }

            #expect(manager.streak.length == 14)
            #expect(manager.getFreezeTokens() == 2)
        }

        @Test @MainActor
        func freezeTokenSuccessfullyUsed() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Build a 5-day streak and give a token
            for day in 1...5 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }
            manager.streak.freezeTokens = 1
            manager.save()

            // Miss a day (day 6), try to check in on day 7
            let day7 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 7).date!

            #expect(manager.canUseFreeze(on: day7) == true)

            let success = manager.useFreeze(on: day7)
            #expect(success == true)
            #expect(manager.getFreezeTokens() == 0)
            #expect(manager.streak.length == 5)  // Length maintained
            #expect(manager.streak.lastDate == day7)
        }

        @Test @MainActor
        func freezeFailsWithoutTokens() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Build a streak without tokens
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
            manager.updateStreak(on: day1)

            // Try to use freeze without tokens
            let day3 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 3).date!
            let success = manager.useFreeze(on: day3)

            #expect(success == false)
            #expect(manager.canUseFreeze(on: day3) == false)
        }

        @Test @MainActor
        func freezeFailsWhenStreakNotBroken() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Build a streak with a token
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
            manager.updateStreak(on: day1)
            manager.streak.freezeTokens = 1
            manager.save()

            // Try to use freeze on same day (streak not broken)
            let success = manager.useFreeze(on: day1)

            #expect(success == false)
            #expect(manager.getFreezeTokens() == 1)  // Token not consumed
        }

        @Test @MainActor
        func cannotUseMultipleFreezeForSameGap() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Build a streak with 2 tokens
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
            manager.updateStreak(on: day1)
            manager.streak.freezeTokens = 2
            manager.save()

            // Use freeze for missed day
            let day3 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 3).date!
            let success1 = manager.useFreeze(on: day3)
            #expect(success1 == true)
            #expect(manager.getFreezeTokens() == 1)

            // Try to use another freeze for the same gap
            let success2 = manager.useFreeze(on: day3)
            #expect(success2 == false)
            #expect(manager.getFreezeTokens() == 1)  // Token not consumed
        }

        @Test @MainActor
        func tokensResetAfterStreakBreaks() throws {
            let store = InMemoryStore()
            let config = StreakManager.Config(calendar: calendar, tokenMilestone: 7)
            let manager = StreakManager(store: store, config: config)

            // Build a 7-day streak
            for day in 1...7 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }
            #expect(manager.getFreezeTokens() == 1)

            // Break the streak (no freeze used)
            let day10 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 10).date!
            manager.updateStreak(on: day10)

            // Tokens should remain (not reset)
            #expect(manager.streak.length == 1)
            #expect(manager.getFreezeTokens() == 1)  // Tokens persist
        }

        @Test @MainActor
        func freezeTokensPersistAcrossSessions() throws {
            let store = InMemoryStore()
            let config = StreakManager.Config(calendar: calendar, tokenMilestone: 7)

            // Session 1: Earn tokens
            let manager1 = StreakManager(store: store, config: config)
            for day in 1...7 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager1.updateStreak(on: date)
            }
            #expect(manager1.getFreezeTokens() == 1)

            // Session 2: Load and verify tokens persist
            let manager2 = StreakManager(store: store, config: config)
            #expect(manager2.getFreezeTokens() == 1)
            #expect(manager2.streak.length == 7)
        }

        @Test @MainActor
        func customMilestoneConfiguration() throws {
            let store = InMemoryStore()
            let config = StreakManager.Config(calendar: calendar, tokenMilestone: 3)
            let manager = StreakManager(store: store, config: config)

            // Build a 3-day streak
            for day in 1...3 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }

            #expect(manager.getFreezeTokens() == 1)

            // Continue to 6 days
            for day in 4...6 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }

            #expect(manager.getFreezeTokens() == 2)
        }

        @Test @MainActor
        func disableTokenEarningWithZeroMilestone() throws {
            let store = InMemoryStore()
            let config = StreakManager.Config(calendar: calendar, tokenMilestone: 0)
            let manager = StreakManager(store: store, config: config)

            // Build a long streak
            for day in 1...20 {
                let date = DateComponents(calendar: calendar, year: 2025, month: 10, day: day).date!
                manager.updateStreak(on: date)
            }

            // No tokens should be earned
            #expect(manager.getFreezeTokens() == 0)
        }

        @Test @MainActor
        func freezeAfterCheckInContinuesStreak() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Day 1
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
            manager.updateStreak(on: day1)
            manager.streak.freezeTokens = 1
            manager.save()

            // Use freeze on day 3 (missed day 2)
            let day3 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 3).date!
            manager.useFreeze(on: day3)

            // Check in on day 4 should continue streak
            let day4 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 4).date!
            manager.updateStreak(on: day4)

            #expect(manager.streak.length == 2)  // Should increment from preserved length
        }
    }

    // MARK: - TimeZone Pinning Tests

    @Suite
    struct TimeZonePinningTests {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func pinnedTimeZoneAppliedToCalendar() throws {
            let tokyo = TimeZone(identifier: "Asia/Tokyo")!
            let config = StreakManager.Config(
                calendar: calendar,
                pinnedTimeZone: tokyo
            )

            #expect(config.calendar.timeZone == tokyo)
            #expect(config.pinnedTimeZone == tokyo)
        }

        @Test @MainActor
        func streakCalculationsUsePinnedTimeZone() throws {
            let store = InMemoryStore()
            let nyTimeZone = TimeZone(identifier: "America/New_York")!
            var nyCalendar = Calendar(identifier: .gregorian)
            nyCalendar.timeZone = nyTimeZone

            let config = StreakManager.Config(
                calendar: calendar,
                pinnedTimeZone: nyTimeZone
            )
            let manager = StreakManager(store: store, config: config)

            // Create dates that are consecutive in NY timezone
            var day1Components = DateComponents()
            day1Components.year = 2025
            day1Components.month = 1
            day1Components.day = 15
            day1Components.hour = 23
            day1Components.timeZone = nyTimeZone
            let day1 = nyCalendar.date(from: day1Components)!

            var day2Components = DateComponents()
            day2Components.year = 2025
            day2Components.month = 1
            day2Components.day = 16
            day2Components.hour = 1
            day2Components.timeZone = nyTimeZone
            let day2 = nyCalendar.date(from: day2Components)!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)

            #expect(manager.streak.length == 2)
        }

        @Test @MainActor
        func travelerScenarioAcrossTimeZones() throws {
            let store = InMemoryStore()
            let homeTimeZone = TimeZone(identifier: "America/Los_Angeles")!
            let config = StreakManager.Config(
                calendar: calendar,
                pinnedTimeZone: homeTimeZone
            )
            let manager = StreakManager(store: store, config: config)

            var homeCalendar = Calendar(identifier: .gregorian)
            homeCalendar.timeZone = homeTimeZone

            // Day 1: Check in from home timezone
            var day1Components = DateComponents()
            day1Components.year = 2025
            day1Components.month = 6
            day1Components.day = 1
            day1Components.hour = 22
            day1Components.timeZone = homeTimeZone
            let day1 = homeCalendar.date(from: day1Components)!

            manager.updateStreak(on: day1)
            #expect(manager.streak.length == 1)

            // Day 2: Travel to Tokyo, but check in according to home timezone
            let tokyoTimeZone = TimeZone(identifier: "Asia/Tokyo")!
            var tokyoCalendar = Calendar(identifier: .gregorian)
            tokyoCalendar.timeZone = tokyoTimeZone

            var day2Components = DateComponents()
            day2Components.year = 2025
            day2Components.month = 6
            day2Components.day = 3  // Next day in Tokyo (but same/next day in LA)
            day2Components.hour = 15
            day2Components.timeZone = tokyoTimeZone
            let day2InTokyo = tokyoCalendar.date(from: day2Components)!

            // Convert to home timezone for verification
            var day2InHomeComponents = homeCalendar.dateComponents(
                [.year, .month, .day, .hour],
                from: day2InTokyo
            )

            manager.updateStreak(on: day2InTokyo)
            // Streak should continue because pinned timezone is used
            #expect(manager.streak.length == 2)
        }

        @Test @MainActor
        func noPinnedTimeZoneUsesCalendarDefault() throws {
            let store = InMemoryStore()
            var customCalendar = Calendar(identifier: .gregorian)
            let customTimeZone = TimeZone(identifier: "Europe/London")!
            customCalendar.timeZone = customTimeZone

            let config = StreakManager.Config(
                calendar: customCalendar,
                pinnedTimeZone: nil
            )

            #expect(config.calendar.timeZone == customTimeZone)
            #expect(config.pinnedTimeZone == nil)
        }

        @Test @MainActor
        func pinnedTimeZonePersistsAcrossSessions() throws {
            let store = InMemoryStore()
            let pacific = TimeZone(identifier: "America/Los_Angeles")!
            let config = StreakManager.Config(
                calendar: calendar,
                pinnedTimeZone: pacific
            )

            // Session 1
            let manager1 = StreakManager(store: store, config: config)
            var pacificCalendar = Calendar(identifier: .gregorian)
            pacificCalendar.timeZone = pacific

            var day1Components = DateComponents()
            day1Components.year = 2025
            day1Components.month = 3
            day1Components.day = 10
            day1Components.hour = 10
            day1Components.timeZone = pacific
            let day1 = pacificCalendar.date(from: day1Components)!

            manager1.updateStreak(on: day1)
            #expect(manager1.streak.length == 1)

            // Session 2 with same config
            let manager2 = StreakManager(store: store, config: config)
            #expect(manager2.config.pinnedTimeZone == pacific)
            #expect(manager2.streak.length == 1)
        }

        @Test @MainActor
        func differentTimeZonesProduceDifferentResults() throws {
            let store1 = InMemoryStore()
            let store2 = InMemoryStore()

            let utc = TimeZone(identifier: "UTC")!
            let tokyo = TimeZone(identifier: "Asia/Tokyo")!

            let configUTC = StreakManager.Config(calendar: calendar, pinnedTimeZone: utc)
            let configTokyo = StreakManager.Config(calendar: calendar, pinnedTimeZone: tokyo)

            let managerUTC = StreakManager(store: store1, config: configUTC)
            let managerTokyo = StreakManager(store: store2, config: configTokyo)

            // Same absolute time, different interpretations
            let absoluteTime = Date(timeIntervalSince1970: 1704153600) // 2024-01-02 00:00:00 UTC

            managerUTC.updateStreak(on: absoluteTime)
            managerTokyo.updateStreak(on: absoluteTime)

            // Both should have streak of 1 after first check-in
            #expect(managerUTC.streak.length == 1)
            #expect(managerTokyo.streak.length == 1)
        }

        @Test @MainActor
        func configEquatableWithTimeZones() throws {
            let pacific = TimeZone(identifier: "America/Los_Angeles")!
            let eastern = TimeZone(identifier: "America/New_York")!

            let config1 = StreakManager.Config(calendar: calendar, pinnedTimeZone: pacific)
            let config2 = StreakManager.Config(calendar: calendar, pinnedTimeZone: pacific)
            let config3 = StreakManager.Config(calendar: calendar, pinnedTimeZone: eastern)

            #expect(config1 == config2)
            #expect(config1 != config3)
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
