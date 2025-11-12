# MiraiStreakKit

A modern, Swift 6-native streak tracking framework for iOS, macOS, and visionOS apps. Built with SwiftUI and Swift's Observation framework for seamless integration into your projects.

## Features

- ✨ **Swift 6 & Observation**: Leverages `@Observable` for reactive UI updates
- 🎯 **Next-Day Window Logic**: Streak continues when checked in from 00:00–23:59 the next calendar day
- 🏆 **Best Streak Tracking**: Automatically tracks and displays the longest streak ever achieved
- ❄️ **Freeze/Make-up Day Tokens**: Protect streaks with earned tokens at milestone intervals
- 📊 **Analytics Integration**: Built-in event tracking with delegate pattern for analytics services
- 🌍 **TimeZone Pinning**: Lock streak calculations to specific timezones for global apps
- 🔔 **Smart Reminders**: Built-in notification system to keep users engaged with their streaks
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
            // Pre-built streak view
            StreakView()
            
            // Custom UI
            Text("Current Streak: \(streakManager.getStreakLength())")
                .font(.title)
            
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

<<<<<<< HEAD
=======
### Freeze Token System

**Earning Tokens:**
- Earn 1 freeze token at each milestone (default: every 7 days)
- Configure milestone interval via `Config(tokenMilestone: 7)`
- Tokens accumulate and persist across sessions

**Using Tokens:**
- Use `useFreeze(on: date)` to protect a streak from breaking
- Prevents streak reset when you miss a day
- Can only use one token per missed day gap
- Tokens are consumed when used successfully

**Example:**
```swift
// Check token availability
if manager.canUseFreeze() {
    let success = manager.useFreeze()
    if success {
        print("Streak saved! Tokens remaining: \(manager.getFreezeTokens())")
    }
}
```

### TimeZone Pinning

**Use Cases:**
- Travelers who want streaks to follow their home timezone
- Global apps targeting users in specific regions
- Apps needing consistent day boundaries regardless of user location

**Configuration:**
```swift
// Pin to a specific timezone
let tokyo = TimeZone(identifier: "Asia/Tokyo")!
.setupMiraiStreak(
    config: .init(
        calendar: .current,
        pinnedTimeZone: tokyo
    )
)

// Or use default (no pinning)
.setupMiraiStreak()  // Uses device timezone
```

**Behavior:**
- When set, all date comparisons use the pinned timezone
- Streak day boundaries align with the pinned timezone
- User can travel across timezones without affecting streak logic

### Analytics Integration

**Tracked Events:**
- `streakUpdated` - Fired when streak is updated or started
- `milestoneReached` - Fired when reaching token milestone (7, 14, 21 days, etc.)
- `streakBroken` - Fired when streak resets due to missed days
- `freezeTokenUsed` - Fired when user uses a freeze token
- `newBestStreakAchieved` - Fired when current streak exceeds best

**Implementation:**
```swift
final class MyAnalyticsDelegate: StreakAnalyticsDelegate {
    func streakEventOccurred(_ event: StreakEvent, manager: StreakManager) {
        switch event {
        case .streakUpdated(let length, let isNew):
            Analytics.track("streak_updated", properties: [
                "length": length,
                "is_new_streak": isNew
            ])

        case .milestoneReached(let length, let earnedToken):
            Analytics.track("milestone_reached", properties: [
                "milestone": length,
                "earned_token": earnedToken
            ])

        case .streakBroken(let previousLength, let bestStreak):
            Analytics.track("streak_broken", properties: [
                "previous_length": previousLength,
                "best_streak": bestStreak
            ])

        case .freezeTokenUsed(let tokensRemaining):
            Analytics.track("freeze_used", properties: [
                "tokens_remaining": tokensRemaining
            ])

        case .newBestStreakAchieved(let newBest, let previousBest):
            Analytics.track("new_best_streak", properties: [
                "new_best": newBest,
                "previous_best": previousBest
            ])
        }
    }
}

// Set the delegate
manager.analyticsDelegate = MyAnalyticsDelegate()
```

### Smart Reminders

**Features:**
- Schedule daily reminders at custom times
- Smart logic: only reminds if user hasn't checked in today
- Customizable notification content with streak length placeholder
- Automatic reminder updates after check-ins

**Implementation:**
```swift
import MiraiStreakKit

// Create notification manager
let notificationManager = StreakNotificationManager(streakManager: manager)

// Request permission (call once at app launch or onboarding)
await notificationManager.requestAuthorization()

// Schedule daily reminder at 8 PM
let reminderTime = DateComponents(hour: 20, minute: 0)
await notificationManager.scheduleDailyReminder(at: reminderTime)

// After user checks in, reschedule for tomorrow
streakManager.updateStreak()
await notificationManager.rescheduleAfterCheckIn()

// Cancel reminders (e.g., if user disables notifications in settings)
await notificationManager.cancelReminders()

// Check if reminders are scheduled
let isScheduled = await notificationManager.hasScheduledReminders()
```

**Customization:**
```swift
let config = StreakNotificationManager.Config(
    identifier: "myAppStreak",
    title: "Keep Your Streak Alive!",
    bodyTemplate: "Don't lose your {streak}-day streak! Tap to check in.",
    sound: .default
)

let notificationManager = StreakNotificationManager(
    streakManager: manager,
    config: config
)
```

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
