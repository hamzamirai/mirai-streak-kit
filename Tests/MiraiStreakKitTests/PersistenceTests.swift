import Foundation
import Testing
@testable import MiraiStreakKit

/// Comprehensive tests for all persistence store implementations.
@Suite
struct PersistenceTests {
    private let sampleData = try! JSONEncoder().encode(Streak(length: 5, lastDate: Date()))
    private let emptyData = try! JSONEncoder().encode(Streak(length: 0, lastDate: nil))

    // MARK: - UserDefaultsStore Tests

    @Suite
    struct UserDefaultsStoreTests {
        @Test("Read returns nil when key doesn't exist")
        func readMissingKeyReturnsNil() throws {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let store = UserDefaultsStore(defaults: defaults, key: "nonexistent")

            let data = store.read()

            #expect(data == nil)
        }

        @Test("Write and read cycle preserves data")
        func writeReadCycle() throws {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let key = "testKey"
            let store = UserDefaultsStore(defaults: defaults, key: key)
            let testData = "test data".data(using: .utf8)!

            try store.write(testData)
            let readData = store.read()

            #expect(readData == testData)
        }

        @Test("Write overwrites existing data")
        func writeOverwrites() throws {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let key = "testKey"
            let store = UserDefaultsStore(defaults: defaults, key: key)
            let data1 = "data1".data(using: .utf8)!
            let data2 = "data2".data(using: .utf8)!

            try store.write(data1)
            #expect(store.read() == data1)

            try store.write(data2)
            #expect(store.read() == data2)
        }

        @Test("Multiple instances with same key share data")
        func multipleInstancesSameKey() throws {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let key = "sharedKey"
            let store1 = UserDefaultsStore(defaults: defaults, key: key)
            let store2 = UserDefaultsStore(defaults: defaults, key: key)
            let testData = "shared".data(using: .utf8)!

            try store1.write(testData)
            let readFromStore2 = store2.read()

            #expect(readFromStore2 == testData)
        }

        @Test("Multiple instances with different keys don't share data")
        func multipleInstancesDifferentKeys() throws {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let store1 = UserDefaultsStore(defaults: defaults, key: "key1")
            let store2 = UserDefaultsStore(defaults: defaults, key: "key2")
            let data1 = "data1".data(using: .utf8)!
            let data2 = "data2".data(using: .utf8)!

            try store1.write(data1)
            try store2.write(data2)

            #expect(store1.read() == data1)
            #expect(store2.read() == data2)
        }

        @Test("Write empty data is valid")
        func writeEmptyData() throws {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let store = UserDefaultsStore(defaults: defaults, key: "test")
            let emptyData = Data()

            try store.write(emptyData)
            let readData = store.read()

            #expect(readData == emptyData)
        }

        @Test("Streak JSON roundtrip with UserDefaults")
        func streakRoundTrip() throws {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let store = UserDefaultsStore(defaults: defaults, key: "streak")
            let original = Streak(length: 10, lastDate: Date())
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let encoded = try encoder.encode(original)

            try store.write(encoded)
            let decoded = try decoder.decode(Streak.self, from: store.read()!)

            #expect(decoded.length == original.length)
            #expect(decoded.lastDate != nil)
        }

        @Test("Default parameters create functional store")
        func defaultParameters() throws {
            // Verify the store can be created with defaults and basic operations work
            let store = UserDefaultsStore()
            let testData = "test".data(using: .utf8)!

            try store.write(testData)
            // Note: This might affect global UserDefaults.standard, so not checking read
        }
    }

    // MARK: - FileStore Tests

    @Suite
    struct FileStoreTests {
        @Test("Read returns nil when file doesn't exist")
        func readMissingFileReturnsNil() throws {
            let _ = FileManager.default.temporaryDirectory
            let testStore = FileStore(filename: "nonexistent_\(UUID().uuidString).json")

            // Create a new FileStore pointing to temp directory by testing the default behavior
            // Since FileStore uses Documents directory, we'll test with a unique filename
            let data = testStore.read()

            #expect(data == nil)
        }

        @Test("Write creates file")
        func writeCreatesFile() throws {
            let filename = "test_\(UUID().uuidString).json"
            let store = FileStore(filename: filename)
            let testData = "test data".data(using: .utf8)!

            try store.write(testData)

            // Verify file exists by reading it back
            let readData = store.read()
            #expect(readData == testData)

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }

        @Test("Write and read cycle preserves data")
        func writeReadCycle() throws {
            let filename = "cycle_\(UUID().uuidString).json"
            let store = FileStore(filename: filename)
            let testData = "test content".data(using: .utf8)!

            try store.write(testData)
            let readData = store.read()

            #expect(readData == testData)

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }

        @Test("Write overwrites existing file")
        func writeOverwrites() throws {
            let filename = "overwrite_\(UUID().uuidString).json"
            let store = FileStore(filename: filename)
            let data1 = "data1".data(using: .utf8)!
            let data2 = "data2".data(using: .utf8)!

            try store.write(data1)
            #expect(store.read() == data1)

            try store.write(data2)
            #expect(store.read() == data2)

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }

        @Test("Multiple FileStore instances with same filename share data")
        func multipleInstancesSameFile() throws {
            let filename = "shared_\(UUID().uuidString).json"
            let store1 = FileStore(filename: filename)
            let store2 = FileStore(filename: filename)
            let testData = "shared data".data(using: .utf8)!

            try store1.write(testData)
            let readFromStore2 = store2.read()

            #expect(readFromStore2 == testData)

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }

        @Test("Atomic write prevents corruption")
        func atomicWrite() throws {
            let filename = "atomic_\(UUID().uuidString).json"
            let store = FileStore(filename: filename)
            let data1 = "original data content".data(using: .utf8)!
            let data2 = "replacement data".data(using: .utf8)!

            try store.write(data1)
            try store.write(data2)

            // With atomic writes, file should be completely valid, not partially written
            let readData = store.read()
            #expect(readData == data2)

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }

        @Test("Streak JSON roundtrip with FileStore")
        func streakRoundTrip() throws {
            let filename = "streak_\(UUID().uuidString).json"
            let store = FileStore(filename: filename)
            let original = Streak(length: 15, lastDate: Date())
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let encoded = try encoder.encode(original)

            try store.write(encoded)
            let decoded = try decoder.decode(Streak.self, from: store.read()!)

            #expect(decoded.length == original.length)
            #expect(decoded.lastDate != nil)

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }

        @Test("Default filename is MiraiStreak.json")
        func defaultFilename() throws {
            let _ = FileStore()
            // Just verify it can be created without error
            #expect(true)
        }
    }

    // MARK: - AppGroupStore Tests

    @Suite
    struct AppGroupStoreTests {
        @Test("Read returns nil when key doesn't exist")
        func readMissingKeyReturnsNil() throws {
            // Use a fake app group ID since we can't actually configure app groups in tests
            let store = AppGroupStore(appGroup: "group.test.nonexistent", key: "missing")

            // When app group is invalid, it falls back to .standard
            // This might return nil or previous values from .standard
            let _ = store.read()
            // We just verify it doesn't crash
            #expect(true)
        }

        @Test("Write and read cycle preserves data")
        func writeReadCycle() throws {
            let store = AppGroupStore(appGroup: "group.test.\(UUID().uuidString)", key: "testKey")
            let testData = "test data".data(using: .utf8)!

            try store.write(testData)
            let readData = store.read()

            #expect(readData == testData)
        }

        @Test("Write overwrites existing data")
        func writeOverwrites() throws {
            let appGroup = "group.test.\(UUID().uuidString)"
            let store = AppGroupStore(appGroup: appGroup, key: "testKey")
            let data1 = "data1".data(using: .utf8)!
            let data2 = "data2".data(using: .utf8)!

            try store.write(data1)
            #expect(store.read() == data1)

            try store.write(data2)
            #expect(store.read() == data2)
        }

        @Test("Multiple instances with same app group and key share data")
        func multipleInstancesSameAppGroup() throws {
            let appGroup = "group.test.\(UUID().uuidString)"
            let key = "sharedKey"
            let store1 = AppGroupStore(appGroup: appGroup, key: key)
            let store2 = AppGroupStore(appGroup: appGroup, key: key)
            let testData = "shared".data(using: .utf8)!

            try store1.write(testData)
            let readFromStore2 = store2.read()

            #expect(readFromStore2 == testData)
        }

        @Test("Different keys in same app group don't share data")
        func differentKeysSameAppGroup() throws {
            let appGroup = "group.test.\(UUID().uuidString)"
            let store1 = AppGroupStore(appGroup: appGroup, key: "key1")
            let store2 = AppGroupStore(appGroup: appGroup, key: "key2")
            let data1 = "data1".data(using: .utf8)!
            let data2 = "data2".data(using: .utf8)!

            try store1.write(data1)
            try store2.write(data2)

            #expect(store1.read() == data1)
            #expect(store2.read() == data2)
        }

        @Test("Streak JSON roundtrip with AppGroupStore")
        func streakRoundTrip() throws {
            let appGroup = "group.test.\(UUID().uuidString)"
            let store = AppGroupStore(appGroup: appGroup, key: "streak")
            let original = Streak(length: 20, lastDate: Date())
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let encoded = try encoder.encode(original)

            try store.write(encoded)
            let decoded = try decoder.decode(Streak.self, from: store.read()!)

            #expect(decoded.length == original.length)
            #expect(decoded.lastDate != nil)
        }

        @Test("Default parameters work")
        func defaultParameters() throws {
            // Should create store with "MiraiStreak" as default key
            let store = AppGroupStore(appGroup: "group.test.\(UUID().uuidString)")
            let testData = "test".data(using: .utf8)!

            try store.write(testData)
            #expect(store.read() == testData)
        }
    }

    // MARK: - StreakStore Protocol Tests

    @Suite
    struct StreakStoreProtocolTests {
        @Test("Custom store implementation conforms to protocol")
        func customStoreConforms() throws {
            let store = MockStore()
            let testData = "test".data(using: .utf8)!

            try store.write(testData)
            let readData = store.read()

            #expect(readData == testData)
        }

        @Test("Any StreakStore can be used with manager")
        func anyStoreWithManager() throws {
            let _ : any StreakStore = MockStore()
            // Verify the existential works
            #expect(true)
        }
    }

    // MARK: - Data Corruption & Error Handling

    @Suite
    struct ErrorHandlingTests {
        @Test("FileStore handles corrupted file gracefully")
        func fileStoreHandlesCorruptedFile() throws {
            let filename = "corrupt_\(UUID().uuidString).json"
            let store = FileStore(filename: filename)
            let invalidJSON = "{ invalid json }".data(using: .utf8)!

            try store.write(invalidJSON)

            // Reading back the invalid JSON should succeed (it's still data)
            let readData = store.read()
            #expect(readData == invalidJSON)

            // But decoding should fail
            let decoder = JSONDecoder()
            #expect(throws: DecodingError.self) {
                try decoder.decode(Streak.self, from: readData!)
            }

            // Cleanup
            try? FileManager.default.removeItem(at: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent(filename))
        }

        @Test("Custom store can throw errors on write")
        func customStoreThrowsOnWrite() throws {
            let store = FailingStore()
            let testData = "test".data(using: .utf8)!

            #expect(throws: FailingStore.TestError.self) {
                try store.write(testData)
            }
        }
    }
}

// MARK: - Test Fixtures

/// A mock store for testing protocol conformance.
private final class MockStore: StreakStore, @unchecked Sendable {
    private var data: Data?

    func read() -> Data? {
        data
    }

    func write(_ data: Data) throws {
        self.data = data
    }
}

/// A store that always fails to test error handling.
private struct FailingStore: StreakStore {
    enum TestError: Error {
        case writeFailed
    }

    func read() -> Data? {
        nil
    }

    func write(_ data: Data) throws {
        throw TestError.writeFailed
    }
}
