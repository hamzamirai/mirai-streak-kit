# MiraiStreakKit

A modern, Swift 6-native streak tracking framework for iOS, macOS, and visionOS apps. Built with SwiftUI and Swift's Observation framework for seamless integration into your projects.

## Features

- ✨ **Swift 6 & Observation**: Leverages `@Observable` for reactive UI updates
- 🎯 **Next-Day Window Logic**: Streak continues when checked in from 00:00–23:59 the next calendar day
- 🏆 **Best Streak Tracking**: Automatically tracks and displays the longest streak ever achieved
- 💾 **Flexible Persistence**: UserDefaults, file-based, or shared App Group storage
- 🧪 **Fully Tested**: Comprehensive test suite with the Swift Testing framework
- 🔒 **Concurrency-Safe**: `@MainActor` isolation with strict Swift 6 concurrency checking
- 📦 **Zero Dependencies**: Pure Swift package with no external requirements

## Installation

### Swift Package Manager

Add MiraiStreakKit to your project using Xcode:

1. File → Add Package Dependencies...
2. Enter the repository URL
3. Select version and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YourUsername/MiraiStreakKit.git", from: "1.0.0")
]
```

## Quick Start

### 1. Set Up the Environment

Inject `StreakManager` at your app's entry point:

```swift
import SwiftUI
import MiraiStreakKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .setupMiraiStreak(
                    store: UserDefaultsStore(),
                    config: .init(calendar: .current)
                )
        }
    }
}
```

### 2. Use in Your Views

Access the streak manager through the environment:

```swift
import SwiftUI
import MiraiStreakKit

struct ContentView: View {
    @Environment(StreakManager.self) private var streakManager

    var body: some View {
        VStack(spacing: 20) {
            // Pre-built streak view (shows both current and best)
            StreakView()

            // Custom UI
            Text("Current Streak: \(streakManager.getStreakLength())")
                .font(.title)

            Text("Best Streak: \(streakManager.getBestStreak())")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("Check In Today") {
                streakManager.updateStreak()
            }
            .disabled(streakManager.hasCompletedStreak())

            if streakManager.hasCompletedStreak() {
                Text("✅ Completed for today!")
                    .foregroundStyle(.green)
            }
        }
        .padding()
    }
}
```

## API Reference

### StreakManager

The main observable class that manages streak state.

#### Methods

```swift
// Update the streak for a given date (defaults to today)
func updateStreak(on date: Date = .now)

// Get current streak length (resets if broken)
@discardableResult
func getStreakLength(on date: Date = .now) -> Int

// Get the best (longest) streak ever achieved
func getBestStreak() -> Int

// Check if streak completed for a given date
func hasCompletedStreak(on date: Date = .now) -> Bool
```

#### Properties

```swift
// Current streak data (observable)
public private(set) var streak: Streak

// Calendar configuration
public var config: Config
```

### Streak

The core data structure representing a streak.

```swift
public struct Streak: Codable, Sendable, Equatable {
    public var length: Int
    public var bestStreak: Int
    public var lastDate: Date?
}
```

### Persistence Options

#### UserDefaultsStore (Default)

Stores streak data in UserDefaults:

```swift
.setupMiraiStreak(
    store: UserDefaultsStore(
        defaults: .standard,
        key: "MyAppStreak"
    )
)
```

#### FileStore

Stores streak as a JSON file in the Documents directory:

```swift
.setupMiraiStreak(
    store: FileStore(filename: "streak.json")
)
```

#### AppGroupStore

For sharing between app and extensions (widgets, Watch app):

```swift
.setupMiraiStreak(
    store: AppGroupStore(
        appGroup: "group.com.yourcompany.yourapp",
        key: "SharedStreak"
    )
)
```

#### Custom Store

Implement `StreakStore` protocol for custom persistence:

```swift
public protocol StreakStore: Sendable {
    func read() -> Data?
    func write(_ data: Data) throws
}
```

## Streak Logic

### Continuation Rules

A streak **continues** when:
- You check in on consecutive calendar days
- The next check-in is within the "next-day window" (00:00–23:59 of the following day)

### Reset Rules

A streak **resets** when:
- You skip an entire calendar day
- You don't check in within the next-day window

### Same-Day Behavior

- Multiple check-ins on the same day don't increment the streak
- `updateStreak()` is idempotent for the same calendar day

## Examples

### Streak Timeline

```
Oct 1, 8:00 AM  → updateStreak()  // Streak: 1
Oct 2, 9:00 AM  → updateStreak()  // Streak: 2
Oct 2, 11:00 PM → updateStreak()  // Streak: 2 (same day)
Oct 3, 12:01 AM → updateStreak()  // Streak: 3 (next-day window)
Oct 5, 10:00 AM → updateStreak()  // Streak: 1 (missed Oct 4)
```

### Custom Calendar

Use a specific time zone or calendar:

```swift
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "America/New_York")!

.setupMiraiStreak(
    config: .init(calendar: calendar)
)
```

### WidgetKit Integration

Share streaks with widgets using App Groups:

```swift
// In your main app
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .setupMiraiStreak(
                    store: AppGroupStore(appGroup: "group.com.mycompany.myapp")
                )
        }
    }
}

// In your widget
struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StreakWidget", provider: Provider()) { entry in
            StreakWidgetView(entry: entry)
        }
    }
}

struct Provider: TimelineProvider {
    let manager = StreakManager(
        store: AppGroupStore(appGroup: "group.com.mycompany.myapp")
    )
    
    // Use manager.getStreakLength() in your timeline entries
}
```

## Testing

Run the test suite:

```bash
swift test
```

With code coverage:

```bash
swift test --enable-code-coverage
```

### Writing Tests

Example test using Swift Testing framework:

```swift
import Testing
@testable import MiraiStreakKit

@Suite
struct MyStreakTests {
    @Test
    @MainActor
    func streakContinuesOnConsecutiveDays() throws {
        let calendar = Calendar(identifier: .gregorian)
        let store = InMemoryStore()
        let manager = StreakManager(store: store, config: .init(calendar: calendar))
        
        let day1 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
        let day2 = DateComponents(calendar: calendar, year: 2025, month: 10, day: 2).date!
        
        manager.updateStreak(on: day1)
        manager.updateStreak(on: day2)
        
        #expect(manager.streak.length == 2)
    }
}
```

## Architecture

### Observation Pattern

MiraiStreakKit uses Swift's `@Observable` macro for reactive state management:

```swift
@MainActor
@Observable
public final class StreakManager {
    public private(set) var streak: Streak
    // ...
}
```

SwiftUI views automatically update when `streak` changes, no manual `@Published` or `objectWillChange` needed.

### Concurrency

- `StreakManager` is isolated to `@MainActor` for UI safety
- All persistence operations are synchronous (suitable for small data)
- Store implementations must be `Sendable`

## Requirements

- iOS 17.0+ / macOS 14.0+ / visionOS 2.0+
- Swift 6.0+
- Xcode 16.0+

## Contributing

See [AGENTS.md](AGENTS.md) for development guidelines, coding standards, and contribution workflow.

## License

MIT License - see LICENSE file for details.

## Credits

Inspired by:
- [Luke Roberts' Streak System Blog](https://blog.lukeroberts.co/posts/streak-system/)
- [LRStreakKit](https://github.com/lukerobertsapps/LRStreakKit)

Built with ❤️ by the MiraiDevs team.
