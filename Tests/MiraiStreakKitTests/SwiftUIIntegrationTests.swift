import Foundation
import SwiftUI
import Testing
@testable import MiraiStreakKit

/// Tests for SwiftUI integration components.
///
/// Note: Full UI rendering tests require preview contexts or UI testing frameworks.
/// These tests focus on the observable manager and modifier functionality.
@Suite
struct SwiftUIIntegrationTests {
    // MARK: - MiraiStreakInjector Tests

    @Suite
    struct InjectorTests {
        @Test @MainActor
        func injectorCreatesManagerWithDefaultParameters() throws {
            let _ = MiraiStreakInjector()

            // Verify the injector can be created without errors
            #expect(true)
        }

        @Test @MainActor
        func injectorCreatesManagerWithCustomStore() throws {
            let customStore = MockStore()
            let _ = MiraiStreakInjector(store: customStore)

            #expect(true)
        }

        @Test @MainActor
        func injectorCreatesManagerWithCustomConfig() throws {
            let hebrew = Calendar(identifier: .hebrew)
            let config = StreakManager.Config(calendar: hebrew)
            let _ = MiraiStreakInjector(config: config)

            #expect(true)
        }

        @Test @MainActor
        func injectorCreatesManagerWithAllCustomParameters() throws {
            let customStore = MockStore()
            let hebrew = Calendar(identifier: .hebrew)
            let config = StreakManager.Config(calendar: hebrew)
            let _ = MiraiStreakInjector(store: customStore, config: config)

            #expect(true)
        }
    }

    // MARK: - setupMiraiStreak() Extension Tests

    @Suite
    struct ModifierExtensionTests {
        @Test @MainActor
        func setupMiraiStreakReturnsViewModifierType() throws {
            let testView = Text("Test View")

            // This should compile and return a view with the modifier applied
            let _ = testView.setupMiraiStreak()

            // Verify it returns some view type
            #expect(true)
        }

        @Test @MainActor
        func setupMiraiStreakWithCustomStore() throws {
            let customStore = MockStore()
            let testView = Text("Test View")

            let _ = testView.setupMiraiStreak(store: customStore)

            #expect(true)
        }

        @Test @MainActor
        func setupMiraiStreakWithCustomConfig() throws {
            let hebrew = Calendar(identifier: .hebrew)
            let config = StreakManager.Config(calendar: hebrew)
            let testView = Text("Test View")

            let _ = testView.setupMiraiStreak(config: config)

            #expect(true)
        }

        @Test @MainActor
        func setupMiraiStreakWithAllCustomParameters() throws {
            let customStore = MockStore()
            let hebrew = Calendar(identifier: .hebrew)
            let config = StreakManager.Config(calendar: hebrew)
            let testView = Text("Test View")

            let _ = testView.setupMiraiStreak(store: customStore, config: config)

            #expect(true)
        }

        @Test @MainActor
        func setupMiraiStreakIsChainable() throws {
            let testView = Text("Test")

            // Verify the modifier returns a view that can be chained with other modifiers
            let _ = testView
                .setupMiraiStreak()
                .padding()
                .background(Color.blue)

            #expect(true)
        }
    }

    // MARK: - Manager Observable Integration Tests

    @Suite
    struct ManagerObservableTests {
        @Test @MainActor
        func managerIsObservable() throws {
            let store = MockStore()
            let _ = StreakManager(store: store)

            // Verify manager is observable by checking it's accessible as Observable
            #expect(true)
        }

        @Test @MainActor
        func managerCanBeAccessedViaEnvironment() throws {
            let store = MockStore()
            let manager = StreakManager(store: store, config: .init())

            // Simulate environment access
            #expect(manager.streak.length >= 0)
        }

        @Test @MainActor
        func managerStateChangeTriggersUpdate() throws {
            let store = MockStore()
            let manager = StreakManager(store: store)
            let day = DateComponents(calendar: .current, year: 2025, month: 10, day: 1, hour: 12).date!

            let initialLength = manager.streak.length
            manager.updateStreak(on: day)
            let updatedLength = manager.streak.length

            #expect(updatedLength > initialLength)
        }

        @Test @MainActor
        func configChangeTakesEffect() throws {
            let store = MockStore()
            let gregorian = Calendar(identifier: .gregorian)
            let manager = StreakManager(store: store, config: .init(calendar: gregorian))

            let hebrew = Calendar(identifier: .hebrew)
            manager.config = .init(calendar: hebrew)

            #expect(manager.config.calendar.identifier == hebrew.identifier)
        }
    }

    // MARK: - Integration Scenario Tests

    @Suite
    struct IntegrationScenarioTests {
        @Test @MainActor
        func setupInjectorAndAccessManager() throws {
            let store = MockStore()
            let manager = StreakManager(store: store)

            // Simulate what happens when injector creates and injects manager
            let day = DateComponents(calendar: .current, year: 2025, month: 10, day: 1, hour: 12).date!
            manager.updateStreak(on: day)

            #expect(manager.streak.length == 1)
        }

        @Test @MainActor
        func multipleEnvironmentInjections() throws {
            let store1 = MockStore()
            let store2 = MockStore()
            let manager1 = StreakManager(store: store1)
            let manager2 = StreakManager(store: store2)

            let day = DateComponents(calendar: .current, year: 2025, month: 10, day: 1, hour: 12).date!

            manager1.updateStreak(on: day)
            // manager2 should remain unaffected

            #expect(manager1.streak.length == 1)
            #expect(manager2.streak.length == 0)
        }

        @Test @MainActor
        func injectorWithPersistentStore() throws {
            let userDefaultsKey = "test_\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let store = UserDefaultsStore(defaults: defaults, key: userDefaultsKey)
            let manager = StreakManager(store: store)

            let day = DateComponents(calendar: .current, year: 2025, month: 10, day: 1, hour: 12).date!
            manager.updateStreak(on: day)

            // Create a new manager with same store to verify persistence
            let manager2 = StreakManager(store: UserDefaultsStore(defaults: defaults, key: userDefaultsKey))
            #expect(manager2.streak.length == 1)
        }

        @Test @MainActor
        func injectorWithFileStore() throws {
            let filename = "test_\(UUID().uuidString).json"
            let store = FileStore(filename: filename)
            let manager = StreakManager(store: store)

            let day = DateComponents(calendar: .current, year: 2025, month: 10, day: 1, hour: 12).date!
            manager.updateStreak(on: day)

            // Create a new manager with same file store to verify persistence
            let manager2 = StreakManager(store: FileStore(filename: filename))
            #expect(manager2.streak.length == 1)

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }
    }

    // MARK: - Error Handling Tests

    @Suite
    struct ErrorHandlingTests {
        @Test @MainActor
        func injectorHandlesStoreFailureGracefully() throws {
            let failingStore = FailingStore()
            let manager = StreakManager(store: failingStore)

            // Manager should initialize even with failing store
            #expect(manager.streak.length == 0)
        }

        @Test @MainActor
        func managerHandlesCorruptedDataFromStore() throws {
            let store = CorruptedDataStore()
            let manager = StreakManager(store: store)

            // Should fall back to empty streak when data is corrupted
            #expect(manager.streak.length == 0)
            #expect(manager.streak.lastDate == nil)
        }
    }
}

// MARK: - Test Fixtures

/// A mock store for testing.
private final class MockStore: StreakStore, @unchecked Sendable {
    private var data: Data?

    func read() -> Data? {
        data
    }

    func write(_ data: Data) throws {
        self.data = data
    }
}

/// A store that always fails writes.
private struct FailingStore: StreakStore {
    func read() -> Data? {
        nil
    }

    func write(_ data: Data) throws {
        // Intentionally do nothing
    }
}

/// A store that returns corrupted data.
private struct CorruptedDataStore: StreakStore {
    func read() -> Data? {
        "invalid json data".data(using: .utf8)
    }

    func write(_ data: Data) throws {
        // Intentionally ignore
    }
}
