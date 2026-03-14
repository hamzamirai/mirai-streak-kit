# Example Usage

This document provides comprehensive examples for integrating MiraiStreakKit into your projects.

## Table of Contents

- [Basic SwiftUI App](#basic-swiftui-app)
- [Custom Persistence](#custom-persistence)
- [WidgetKit Integration](#widgetkit-integration)
- [Multi-Platform Support](#multi-platform-support)
- [Advanced Patterns](#advanced-patterns)

## Basic SwiftUI App

### Minimal Setup

```swift
import SwiftUI
import MiraiStreakKit

@main
struct StreakApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .setupMiraiStreak()  // Uses defaults
        }
    }
}

struct ContentView: View {
    @Environment(StreakManager.self) private var streakManager
    
    var body: some View {
        VStack(spacing: 20) {
            StreakView()
            
            Button("Complete Today's Goal") {
                streakManager.updateStreak()
            }
            .buttonStyle(.borderedProminent)
            .disabled(streakManager.hasCompletedStreak())
        }
        .padding()
    }
}
```

### Custom UI with Animations

```swift
struct CustomStreakView: View {
    @Environment(StreakManager.self) private var streakManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated flame icon
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)
                .symbolEffect(.bounce, value: streakManager.streak.length)
            
            // Streak counter with animation
            Text("\(streakManager.getStreakLength())")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            
            Text("day streak")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            // Status indicator
            if streakManager.hasCompletedStreak() {
                Label("Completed Today", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: streakManager.streak.length)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: streakManager.hasCompletedStreak())
    }
}
```

### Check-In Button Component

```swift
struct CheckInButton: View {
    @Environment(StreakManager.self) private var streakManager
    
    @State private var showConfetti = false
    
    var body: some View {
        Button {
            withAnimation {
                streakManager.updateStreak()
                if streakManager.streak.length > 0 {
                    showConfetti = true
                }
            }
        } label: {
            Label(
                streakManager.hasCompletedStreak() ? "Done for Today" : "Check In",
                systemImage: streakManager.hasCompletedStreak() ? "checkmark.circle.fill" : "circle"
            )
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(streakManager.hasCompletedStreak())
        .confettiCannon(counter: $showConfetti)  // Requires ConfettiSwiftUI package
    }
}
```

## Custom Persistence

### CloudKit Sync Example

```swift
import Foundation
import CloudKit
import MiraiStreakKit

@MainActor
final class CloudKitStreakStore: StreakStore {
    private let container: CKContainer
    private let recordType = "Streak"
    private let recordID = CKRecord.ID(recordName: "userStreak")
    
    init(containerIdentifier: String) {
        self.container = CKContainer(identifier: containerIdentifier)
    }
    
    func read() -> Data? {
        // Synchronous read from local cache
        // Use CloudKit's cached data or implement proper async patterns
        return UserDefaults.standard.data(forKey: "cachedStreak")
    }
    
    func write(_ data: Data) throws {
        // Save locally
        UserDefaults.standard.set(data, forKey: "cachedStreak")
        
        // Background sync to CloudKit
        Task {
            await syncToCloud(data)
        }
    }
    
    private func syncToCloud(_ data: Data) async {
        do {
            let database = container.privateCloudDatabase
            let record = CKRecord(recordType: recordType, recordID: recordID)
            record["streakData"] = data
            try await database.save(record)
        } catch {
            print("CloudKit sync failed: \(error)")
        }
    }
}

// Usage
@main
struct CloudSyncApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .setupMiraiStreak(
                    store: CloudKitStreakStore(containerIdentifier: "iCloud.com.yourcompany.app")
                )
        }
    }
}
```

### Encrypted File Storage

```swift
import Foundation
import CryptoKit
import MiraiStreakKit

struct EncryptedFileStore: StreakStore {
    private let url: URL
    private let key: SymmetricKey
    
    init(filename: String = "streak_encrypted.bin", key: SymmetricKey) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.url = directory.appendingPathComponent(filename)
        self.key = key
    }
    
    func read() -> Data? {
        guard let encryptedData = try? Data(contentsOf: url) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            return nil
        }
    }
    
    func write(_ data: Data) throws {
        let sealedBox = try AES.GCM.seal(data, using: key)
        try sealedBox.combined?.write(to: url, options: .atomic)
    }
}

// Generate and store key securely (Keychain in production)
let encryptionKey = SymmetricKey(size: .bits256)

// Usage
.setupMiraiStreak(
    store: EncryptedFileStore(key: encryptionKey)
)
```

### Firestore Sync Example

```swift
import Foundation
import FirebaseFirestore
import MiraiStreakKit

@MainActor
final class FirestoreStreakStore: StreakStore {
    private let db: Firestore
    private let userId: String
    private let collectionPath: String

    init(userId: String, collectionPath: String = "streaks") {
        self.db = Firestore.firestore()
        self.userId = userId
        self.collectionPath = collectionPath
    }

    func read() -> Data? {
        // Synchronous read from local cache
        return UserDefaults.standard.data(forKey: "cachedStreak_\(userId)")
    }

    func write(_ data: Data) throws {
        // Save locally for immediate use
        UserDefaults.standard.set(data, forKey: "cachedStreak_\(userId)")

        // Background sync to Firestore
        Task {
            await syncToFirestore(data)
        }
    }

    private func syncToFirestore(_ data: Data) async {
        do {
            let docRef = db.collection(collectionPath).document(userId)

            // Decode streak data
            let decoder = JSONDecoder()
            let streak = try decoder.decode(Streak.self, from: data)

            // Convert to Firestore-compatible format
            let streakData: [String: Any] = [
                "length": streak.length,
                "bestStreak": streak.bestStreak,
                "freezeTokens": streak.freezeTokens,
                "lastDate": streak.lastDate?.timeIntervalSince1970 ?? NSNull(),
                "lastFreezeDate": streak.lastFreezeDate?.timeIntervalSince1970 ?? NSNull(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await docRef.setData(streakData, merge: true)
        } catch {
            print("Firestore sync failed: \(error)")
        }
    }

    // Optional: Fetch from Firestore on app launch
    func fetchFromFirestore() async throws -> Data? {
        let docRef = db.collection(collectionPath).document(userId)
        let document = try await docRef.getDocument()

        guard let data = document.data() else { return nil }

        // Convert from Firestore format back to Streak
        let lastDate: Date? = if let timestamp = data["lastDate"] as? Double {
            Date(timeIntervalSince1970: timestamp)
        } else {
            nil
        }

        let lastFreezeDate: Date? = if let timestamp = data["lastFreezeDate"] as? Double {
            Date(timeIntervalSince1970: timestamp)
        } else {
            nil
        }

        let streak = Streak(
            length: data["length"] as? Int ?? 0,
            bestStreak: data["bestStreak"] as? Int ?? 0,
            freezeTokens: data["freezeTokens"] as? Int ?? 0,
            lastDate: lastDate,
            lastFreezeDate: lastFreezeDate
        )

        let encoder = JSONEncoder()
        return try encoder.encode(streak)
    }
}

// Usage
@main
struct FirebaseSyncApp: App {
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .setupMiraiStreak(
                    store: FirestoreStreakStore(userId: Auth.auth().currentUser?.uid ?? "anonymous")
                )
        }
    }
}

// Optional: Fetch from Firestore on app launch
Task {
    let store = FirestoreStreakStore(userId: "user123")
    if let cloudData = try? await store.fetchFromFirestore() {
        // Cloud data available, will be used by StreakManager
    }
}
```

### Real-time Firestore Sync with Listeners

```swift
import Foundation
import FirebaseFirestore
import MiraiStreakKit

@MainActor
final class RealtimeFirestoreStore: StreakStore {
    private let db: Firestore
    private let userId: String
    private var listener: ListenerRegistration?

    // Callback for when cloud data changes
    var onCloudUpdate: ((Data) -> Void)?

    init(userId: String) {
        self.db = Firestore.firestore()
        self.userId = userId
        startListening()
    }

    deinit {
        listener?.remove()
    }

    func read() -> Data? {
        UserDefaults.standard.data(forKey: "cachedStreak_\(userId)")
    }

    func write(_ data: Data) throws {
        UserDefaults.standard.set(data, forKey: "cachedStreak_\(userId)")

        Task {
            await uploadToFirestore(data)
        }
    }

    private func startListening() {
        let docRef = db.collection("streaks").document(userId)

        listener = docRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  error == nil else { return }

            Task { @MainActor in
                await self.handleCloudUpdate(data)
            }
        }
    }

    private func handleCloudUpdate(_ data: [String: Any]) async {
        // Convert Firestore data to Streak
        let lastDate: Date? = if let timestamp = data["lastDate"] as? Double {
            Date(timeIntervalSince1970: timestamp)
        } else {
            nil
        }

        let lastFreezeDate: Date? = if let timestamp = data["lastFreezeDate"] as? Double {
            Date(timeIntervalSince1970: timestamp)
        } else {
            nil
        }

        let streak = Streak(
            length: data["length"] as? Int ?? 0,
            bestStreak: data["bestStreak"] as? Int ?? 0,
            freezeTokens: data["freezeTokens"] as? Int ?? 0,
            lastDate: lastDate,
            lastFreezeDate: lastFreezeDate
        )

        if let encoded = try? JSONEncoder().encode(streak) {
            UserDefaults.standard.set(encoded, forKey: "cachedStreak_\(userId)")
            onCloudUpdate?(encoded)
        }
    }

    private func uploadToFirestore(_ data: Data) async {
        do {
            let decoder = JSONDecoder()
            let streak = try decoder.decode(Streak.self, from: data)

            let streakData: [String: Any] = [
                "length": streak.length,
                "bestStreak": streak.bestStreak,
                "freezeTokens": streak.freezeTokens,
                "lastDate": streak.lastDate?.timeIntervalSince1970 ?? NSNull(),
                "lastFreezeDate": streak.lastFreezeDate?.timeIntervalSince1970 ?? NSNull(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await db.collection("streaks").document(userId).setData(streakData, merge: true)
        } catch {
            print("Upload failed: \(error)")
        }
    }
}
```

## WidgetKit Integration

### Shared Streak Widget

**Main App:**

```swift
import SwiftUI
import MiraiStreakKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .setupMiraiStreak(
                    store: AppGroupStore(appGroup: "group.com.yourcompany.streakapp")
                )
        }
    }
}
```

**Widget Extension:**

```swift
import WidgetKit
import SwiftUI
import MiraiStreakKit

struct StreakWidget: Widget {
    let kind = "StreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Streak Counter")
        .description("Track your daily streak")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streakLength: Int
    let isCompletedToday: Bool
}

@MainActor
struct StreakProvider: TimelineProvider {
    private let manager: StreakManager
    
    init() {
        self.manager = StreakManager(
            store: AppGroupStore(appGroup: "group.com.yourcompany.streakapp")
        )
    }
    
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streakLength: 7, isCompletedToday: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let entry = makeEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func makeEntry() -> StreakEntry {
        StreakEntry(
            date: Date(),
            streakLength: manager.getStreakLength(),
            isCompletedToday: manager.hasCompletedStreak()
        )
    }
}

struct StreakWidgetEntryView: View {
    let entry: StreakEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange.gradient)
                Text("\(entry.streakLength)")
                    .font(.system(.title, design: .rounded).bold())
            }
            
            if entry.isCompletedToday {
                Text("✓ Done Today")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Don't break it!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

## Multi-Platform Support

### Universal App (iOS, macOS, visionOS)

```swift
import SwiftUI
import MiraiStreakKit

@main
struct UniversalStreakApp: App {
    var body: some Scene {
        WindowGroup {
            AdaptiveContentView()
                .setupMiraiStreak()
        }
        #if os(macOS)
        .defaultSize(width: 400, height: 600)
        #endif
    }
}

struct AdaptiveContentView: View {
    @Environment(StreakManager.self) private var streakManager
    
    var body: some View {
        #if os(iOS)
        iOSView()
        #elseif os(macOS)
        macOSView()
        #elseif os(visionOS)
        visionOSView()
        #endif
    }
    
    #if os(iOS)
    @ViewBuilder
    private func iOSView() -> some View {
        NavigationStack {
            StreakDashboard()
                .navigationTitle("My Streak")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        CheckInButton()
                    }
                }
        }
    }
    #endif
    
    #if os(macOS)
    @ViewBuilder
    private func macOSView() -> some View {
        NavigationSplitView {
            List {
                Label("Overview", systemImage: "chart.line.uptrend.xyaxis")
                Label("History", systemImage: "calendar")
                Label("Settings", systemImage: "gear")
            }
        } detail: {
            StreakDashboard()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    #endif
    
    #if os(visionOS)
    @ViewBuilder
    private func visionOSView() -> some View {
        NavigationStack {
            StreakDashboard()
                .ornament(attachmentAnchor: .scene(.top)) {
                    StreakView()
                        .padding()
                        .glassBackgroundEffect()
                }
        }
    }
    #endif
}
```

## Advanced Patterns

### Best Streak Tracking

```swift
@MainActor
@Observable
final class ExtendedStreakManager {
    private let baseManager: StreakManager
    
    var currentStreak: Int { baseManager.getStreakLength() }
    private(set) var bestStreak: Int
    
    init(store: any StreakStore = UserDefaultsStore()) {
        self.baseManager = StreakManager(store: store)
        self.bestStreak = UserDefaults.standard.integer(forKey: "bestStreak")
    }
    
    func updateStreak() {
        baseManager.updateStreak()
        let current = baseManager.getStreakLength()
        
        if current > bestStreak {
            bestStreak = current
            UserDefaults.standard.set(bestStreak, forKey: "bestStreak")
        }
    }
    
    var hasCompletedToday: Bool {
        baseManager.hasCompletedStreak()
    }
}

// Usage
struct StatsView: View {
    @Environment(ExtendedStreakManager.self) private var manager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatRow(title: "Current Streak", value: "\(manager.currentStreak)")
            StatRow(title: "Best Streak", value: "\(manager.bestStreak)")
        }
    }
}
```

### Streak Reminders

```swift
import UserNotifications

@MainActor
class StreakNotificationManager: ObservableObject {
    private let streakManager: StreakManager
    
    init(streakManager: StreakManager) {
        self.streakManager = streakManager
    }
    
    func scheduleReminderIfNeeded() async {
        guard !streakManager.hasCompletedStreak() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak!"
        content.body = "You're on a \(streakManager.getStreakLength())-day streak. Check in today!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20  // 8 PM
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
    }
}
```

### Analytics Integration

```swift
protocol AnalyticsService {
    func track(_ event: String, properties: [String: Any])
}

@MainActor
@Observable
final class AnalyticsStreakManager {
    private let baseManager: StreakManager
    private let analytics: AnalyticsService
    
    init(store: any StreakStore, analytics: AnalyticsService) {
        self.baseManager = StreakManager(store: store)
        self.analytics = analytics
    }
    
    func updateStreak() {
        let wasCompleted = baseManager.hasCompletedStreak()
        let lengthBefore = baseManager.getStreakLength()
        
        baseManager.updateStreak()
        
        if !wasCompleted {
            let lengthAfter = baseManager.getStreakLength()
            let milestone = lengthAfter % 7 == 0  // Weekly milestones
            
            analytics.track("streak_updated", properties: [
                "streak_length": lengthAfter,
                "is_milestone": milestone,
                "broke_streak": lengthAfter < lengthBefore
            ])
        }
    }
    
    var streak: Streak { baseManager.streak }
    var hasCompletedToday: Bool { baseManager.hasCompletedStreak() }
}
```

## Testing Examples

### Mock Store for Testing

```swift
import Testing
@testable import MiraiStreakKit

final class MockStreakStore: StreakStore, @unchecked Sendable {
    var shouldFail = false
    private(set) var data: Data?
    private(set) var writeCallCount = 0
    
    func read() -> Data? {
        shouldFail ? nil : data
    }
    
    func write(_ data: Data) throws {
        writeCallCount += 1
        if shouldFail {
            throw MockError.writeFailed
        }
        self.data = data
    }
    
    enum MockError: Error {
        case writeFailed
    }
}

@Suite
struct StreakPersistenceTests {
    @Test
    @MainActor
    func dataIsPersisted() throws {
        let store = MockStreakStore()
        let manager = StreakManager(store: store)
        
        manager.updateStreak()
        
        #expect(store.data != nil)
        #expect(store.writeCallCount == 1)
    }
}
```

---

For more examples and patterns, check the [main README](../README.md) and [AGENTS.md](../AGENTS.md).
