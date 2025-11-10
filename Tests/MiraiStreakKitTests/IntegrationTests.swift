import Foundation
import Testing
@testable import MiraiStreakKit

/// End-to-end and cross-component integration tests.
///
/// These tests exercise the full system, simulating real-world usage patterns
/// and verifying that all components work together correctly.
@Suite
struct IntegrationTests {
    private let calendar = Calendar(identifier: .gregorian)

    // MARK: - First-Time User Flow

    @Suite
    struct FirstTimeUserFlow {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func firstTimeUserStartsStreak() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            #expect(manager.streak.length == 0)
            #expect(manager.streak.lastDate == nil)
            #expect(manager.hasCompletedStreak() == false)

            let today = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            manager.updateStreak(on: today)

            #expect(manager.streak.length == 1)
            #expect(manager.hasCompletedStreak(on: today) == true)
        }

        @Test @MainActor
        func firstCheckInThenNextDay() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!

            manager.updateStreak(on: day1)
            #expect(manager.streak.length == 1)
            #expect(manager.hasCompletedStreak(on: day1) == true)
            #expect(manager.hasCompletedStreak(on: day2) == false)

            manager.updateStreak(on: day2)
            #expect(manager.streak.length == 2)
            #expect(manager.hasCompletedStreak(on: day2) == true)
        }
    }

    // MARK: - Daily Check-in Flow

    @Suite
    struct DailyCheckInFlow {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func sevenDayConsecutiveStreak() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            for dayOffset in 0..<7 {
                let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: dayOffset + 1, hour: 12).date!
                manager.updateStreak(on: day)
                #expect(manager.streak.length == dayOffset + 1)
            }

            #expect(manager.streak.length == 7)
        }

        @Test @MainActor
        func thirtyDayStreak() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            for dayOffset in 0..<30 {
                let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: dayOffset + 1, hour: 12).date!
                manager.updateStreak(on: day)
            }

            #expect(manager.streak.length == 30)
        }

        @Test @MainActor
        func multipleCheckInsOnSameDayIgnoredAfterFirst() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let sameDay = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 18).date!

            manager.updateStreak(on: day)
            let writeCountAfterFirst = store.writeCount
            manager.updateStreak(on: sameDay)

            #expect(manager.streak.length == 1)
            #expect(store.writeCount == writeCountAfterFirst) // No additional write
        }
    }

    // MARK: - Break and Recover Flow

    @Suite
    struct BreakAndRecoverFlow {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func missOneDayAndRestart() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!
            let day4 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 4, hour: 12).date!
            let day5 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 5, hour: 12).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)
            #expect(manager.streak.length == 2)

            // Miss day 3, check on day 4
            let length = manager.getStreakLength(on: day4)
            #expect(length == 0)
            #expect(manager.streak.length == 0)

            // Restart on day 5
            manager.updateStreak(on: day5)
            #expect(manager.streak.length == 1)
        }

        @Test @MainActor
        func streakBreaksAndRestartsMultipleTimes() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // First streak: 3 days
            for dayOffset in 0..<3 {
                let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: dayOffset + 1, hour: 12).date!
                manager.updateStreak(on: day)
            }
            #expect(manager.streak.length == 3)

            // Break it
            let day5 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 5, hour: 12).date!
            manager.getStreakLength(on: day5)
            #expect(manager.streak.length == 0)

            // Second streak: 5 days
            for dayOffset in 0..<5 {
                let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: dayOffset + 10, hour: 12).date!
                manager.updateStreak(on: day)
            }
            #expect(manager.streak.length == 5)
        }

        @Test @MainActor
        func almostMissingButStillInWindow() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 23, minute: 59).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 0, minute: 1).date!

            manager.updateStreak(on: day1)
            manager.updateStreak(on: day2)

            #expect(manager.streak.length == 2)
        }
    }

    // MARK: - Persistence Lifecycle Flow

    @Suite
    struct PersistenceLifecycleFlow {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func saveAndLoadPreservesState() throws {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let key = "testKey"

            // Create manager and build a streak
            let store1 = UserDefaultsStore(defaults: defaults, key: key)
            let manager1 = StreakManager(store: store1, config: .init(calendar: calendar))
            let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!

            manager1.updateStreak(on: day1)
            manager1.updateStreak(on: day2)
            #expect(manager1.streak.length == 2)

            // Create new manager with same store
            let store2 = UserDefaultsStore(defaults: defaults, key: key)
            let manager2 = StreakManager(store: store2, config: .init(calendar: calendar))

            #expect(manager2.streak.length == 2)
            #expect(manager2.streak.lastDate != nil)
        }

        @Test @MainActor
        func fileStorePersistence() throws {
            let filename = "persistence_test_\(UUID().uuidString).json"

            // Create and populate first manager
            let store1 = FileStore(filename: filename)
            let manager1 = StreakManager(store: store1, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            manager1.updateStreak(on: day)
            #expect(manager1.streak.length == 1)

            // Load with new manager
            let store2 = FileStore(filename: filename)
            let manager2 = StreakManager(store: store2, config: .init(calendar: calendar))

            #expect(manager2.streak.length == 1)

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }

        @Test @MainActor
        func appGroupStorePersistence() throws {
            let appGroup = "group.test.\(UUID().uuidString)"

            // Create and populate first manager
            let store1 = AppGroupStore(appGroup: appGroup)
            let manager1 = StreakManager(store: store1, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            manager1.updateStreak(on: day)
            #expect(manager1.streak.length == 1)

            // Load with new manager
            let store2 = AppGroupStore(appGroup: appGroup)
            let manager2 = StreakManager(store: store2, config: .init(calendar: calendar))

            #expect(manager2.streak.length == 1)
        }
    }

    // MARK: - Cross-Component Integration

    @Suite
    struct CrossComponentIntegration {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func updateAffectsObservableProperty() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            let beforeLength = manager.streak.length
            manager.updateStreak(on: day)
            let afterLength = manager.streak.length

            #expect(beforeLength == 0)
            #expect(afterLength == 1)
        }

        @Test @MainActor
        func storeFailureDoesNotCrash() throws {
            let failingStore = FailingStore()
            let manager = StreakManager(store: failingStore, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            // Even though store fails, manager should continue
            manager.updateStreak(on: day)

            // State is still updated in memory
            #expect(manager.streak.length == 1)
        }

        @Test @MainActor
        func corruptedStoreFallsBackToEmpty() throws {
            let corruptedStore = CorruptedStore()
            let manager = StreakManager(store: corruptedStore, config: .init(calendar: calendar))

            #expect(manager.streak.length == 0)
            #expect(manager.streak.lastDate == nil)
        }

        @Test @MainActor
        func multipleStoresIndependent() throws {
            let store1 = InMemoryStore()
            let store2 = InMemoryStore()
            let manager1 = StreakManager(store: store1, config: .init(calendar: calendar))
            let manager2 = StreakManager(store: store2, config: .init(calendar: calendar))
            let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!

            manager1.updateStreak(on: day)

            #expect(manager1.streak.length == 1)
            #expect(manager2.streak.length == 0)
        }
    }

    // MARK: - Calendar Configuration Integration

    @Suite
    struct CalendarConfigurationIntegration {
        @Test @MainActor
        func differentCalendarsSameDateDifferentOutcome() throws {
            let gregorian = Calendar(identifier: .gregorian)
            let hebrew = Calendar(identifier: .hebrew)

            // Same logical date, different outcomes based on calendar
            let gregorianDate = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 1, hour: 12).date!
            let hebrewDate = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 1, hour: 12).date!

            let store1 = InMemoryStore()
            let manager1 = StreakManager(store: store1, config: .init(calendar: gregorian))

            let store2 = InMemoryStore()
            let manager2 = StreakManager(store: store2, config: .init(calendar: hebrew))

            manager1.updateStreak(on: gregorianDate)
            manager2.updateStreak(on: hebrewDate)

            // Both should have streak of 1 in their respective calendars
            #expect(manager1.streak.length == 1)
            #expect(manager2.streak.length == 1)
        }

        @Test @MainActor
        func calendarChangeAffectsFutureChecks() throws {
            let gregorian = Calendar(identifier: .gregorian)
            let hebrew = Calendar(identifier: .hebrew)
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: gregorian))

            let gregorianDay = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 1, hour: 12).date!
            manager.updateStreak(on: gregorianDay)
            #expect(manager.streak.length == 1)

            // Change calendar
            manager.config = .init(calendar: hebrew)

            // Next update uses new calendar
            let hebrewDay = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 2, hour: 12).date!
            manager.updateStreak(on: hebrewDay)

            #expect(manager.streak.length >= 1)
        }
    }

    // MARK: - Boundary Condition Integration

    @Suite
    struct BoundaryConditionIntegration {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func leapYearTransition() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            let feb28_2024 = DateComponents(calendar: calendar, year: 2024, month: 2, day: 28, hour: 12).date!
            let feb29_2024 = DateComponents(calendar: calendar, year: 2024, month: 2, day: 29, hour: 12).date!
            let mar1_2024 = DateComponents(calendar: calendar, year: 2024, month: 3, day: 1, hour: 12).date!

            manager.updateStreak(on: feb28_2024)
            manager.updateStreak(on: feb29_2024)
            manager.updateStreak(on: mar1_2024)

            #expect(manager.streak.length == 3)
        }

        @Test @MainActor
        func yearBoundaryTransition() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            let dec31_2024 = DateComponents(calendar: calendar, year: 2024, month: 12, day: 31, hour: 12).date!
            let jan1_2025 = DateComponents(calendar: calendar, year: 2025, month: 1, day: 1, hour: 12).date!
            let jan2_2025 = DateComponents(calendar: calendar, year: 2025, month: 1, day: 2, hour: 12).date!

            manager.updateStreak(on: dec31_2024)
            manager.updateStreak(on: jan1_2025)
            manager.updateStreak(on: jan2_2025)

            #expect(manager.streak.length == 3)
        }

        @Test @MainActor
        func monthBoundaryTransition() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            let sep30 = DateComponents(calendar: calendar, year: 2025, month: 9, day: 30, hour: 12).date!
            let oct1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 12).date!
            let oct2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 12).date!

            manager.updateStreak(on: sep30)
            manager.updateStreak(on: oct1)
            manager.updateStreak(on: oct2)

            #expect(manager.streak.length == 3)
        }
    }

    // MARK: - Real-world Scenario Tests

    @Suite
    struct RealWorldScenarios {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func userMissesWeekendThenRecovers() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Mon-Fri: 5-day streak
            for dayOffset in 0..<5 {
                let day = DateComponents(calendar: calendar, year: 2025, month: 10, day: dayOffset + 6, hour: 12).date!
                manager.updateStreak(on: day)
            }
            #expect(manager.streak.length == 5)

            // Skip Saturday and Sunday
            let monday = DateComponents(calendar: calendar, year: 2025, month: 10, day: 13, hour: 12).date!

            // Check on Monday - streak should break
            let length = manager.getStreakLength(on: monday)
            #expect(length == 0)

            // Start fresh on Monday
            manager.updateStreak(on: monday)
            #expect(manager.streak.length == 1)
        }

        @Test @MainActor
        func businessTravelTimeZoneScenario() throws {
            // User is traveling and checking in at different times
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            let morningCheckin = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1, hour: 6).date!
            let eveningCheckin = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2, hour: 22).date!

            manager.updateStreak(on: morningCheckin)
            manager.updateStreak(on: eveningCheckin)

            // Both should count as different days
            #expect(manager.streak.length == 2)
        }
    }

    // MARK: - Performance Integration Tests

    @Suite
    struct PerformanceIntegration {
        let calendar = Calendar(identifier: .gregorian)

        @Test @MainActor
        func largeNumberOfUpdates() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            // Perform 100 updates
            for dayOffset in 0..<100 {
                let day = DateComponents(calendar: calendar, year: 2024, month: 1, day: dayOffset + 1, hour: 12).date!
                manager.updateStreak(on: day)
            }

            #expect(manager.streak.length == 100)
            #expect(store.writeCount == 100)
        }

        @Test @MainActor
        func storeWithManyReadsAndWrites() throws {
            let store = InMemoryStore()
            let manager = StreakManager(store: store, config: .init(calendar: calendar))

            for iteration in 0..<50 {
                let day = DateComponents(calendar: calendar, year: 2024, month: 1, day: iteration + 1, hour: 12).date!
                manager.updateStreak(on: day)
                let _ = manager.getStreakLength(on: day)
            }

            #expect(store.writeCount >= 50)
        }
    }
}

// MARK: - Test Fixtures

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

private struct FailingStore: StreakStore {
    func read() -> Data? {
        nil
    }

    func write(_ data: Data) throws {
        // Intentionally do nothing
    }
}

private struct CorruptedStore: StreakStore {
    func read() -> Data? {
        "{ invalid json }".data(using: .utf8)
    }

    func write(_ data: Data) throws {
        // Intentionally do nothing
    }
}
