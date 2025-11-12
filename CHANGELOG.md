# Changelog

All notable changes to MiraiStreakKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Best Streak Tracking**: Automatically tracks and persists the longest streak ever achieved
  - Added `bestStreak` property to `Streak` struct
  - Added `getBestStreak()` method to `StreakManager`
  - Updated `StreakView` to display both current and best streaks
  - Backward compatible with existing data (defaults to 0)
  - Includes 9 comprehensive tests for best streak functionality

- **Freeze/Make-up Day Tokens**: Protect streaks with earned tokens at milestone intervals
  - Added `freezeTokens` and `lastFreezeDate` properties to `Streak` struct
  - Added `tokenMilestone` configuration (default: 7 days)
  - Automatic token earning at milestone streaks
  - Added `useFreeze()` method to protect streak from breaking
  - Added `canUseFreeze()` method to check token availability
  - Added `getFreezeTokens()` method to access token count
  - Tokens persist across sessions and survive streak resets
  - Prevents multiple token usage for same missed day
  - Includes 11 comprehensive tests for freeze token functionality

- **TimeZone Pinning**: Lock streak calculations to specific timezone for travelers
  - Added `pinnedTimeZone` optional property to `Config`
  - Automatically applies pinned timezone to calendar
  - All date comparisons use pinned timezone when set
  - Useful for travelers and global apps with regional focus
  - Config initialization automatically configures calendar timezone
  - Includes 7 comprehensive tests covering timezone scenarios

- **Analytics Integration Hooks**: Track streak events with delegate pattern
  - Added `StreakEvent` enum with 5 event types
  - Added `StreakAnalyticsDelegate` protocol for event notifications
  - Added `analyticsDelegate` weak property to `StreakManager`
  - Events: streakUpdated, milestoneReached, streakBroken, freezeTokenUsed, newBestStreakAchieved
  - Weak delegate prevents retain cycles
  - Events fired at appropriate points in streak lifecycle
  - Includes 10 comprehensive tests for analytics integration

### Fixes
- **Swift Version Requirement**: Further downgraded to Swift 6.0.0 for maximum GitHub Actions runner compatibility
  - Xcode 16.0 on macOS-latest includes Swift 6.0.0
  - All tests pass with Swift 6.0.0

### Planned Features
- TimeZone pinning for cross-timezone applications
- Freeze/Make-up day tokens for streak protection
- Analytics integration hooks
- CloudKit persistence option
- Firestore persistence option
- Reminders system for streak notifications
- Performance optimizations for large datasets

---

## [1.0.1] - 2025-11-11

### Fixes
- **Swift Version Requirement**: Downgraded `swift-tools-version` from 6.2 to 6.1 for improved GitHub Actions CI/CD compatibility
  - Ensures compatibility with broader range of CI/CD environments
  - All 142 tests pass with Swift 6.1
  - No feature changes or breaking changes

---

## [1.0.0] - 2025-11-11

### Initial Release

#### Core Features
- **Streak Tracking**: `Streak` struct with outcome determination for consecutive day tracking
  - Supports same-day multiple check-ins detection
  - Next-day window logic for streak continuation
  - Automatic streak reset on missed days
  - Configurable calendar systems (Gregorian, Hebrew, Islamic, etc.)

- **Observable Manager**: `@Observable` `StreakManager` class for reactive state management
  - `@MainActor` isolated for thread-safe SwiftUI integration
  - Configurable with custom calendars and stores
  - Automatic persistence on state changes
  - Methods: `updateStreak()`, `getStreakLength()`, `hasCompletedStreak()`

- **Flexible Persistence Layer**: Custom `StreakStore` protocol with built-in implementations
  - `UserDefaultsStore` for simple in-app storage
  - `FileStore` for JSON file-based persistence in Documents directory
  - `AppGroupStore` for sharing data between apps and extensions
  - Atomic writes to prevent corruption

- **SwiftUI Integration**
  - `MiraiStreakInjector` view modifier for environment setup
  - `.setupMiraiStreak()` convenience extension
  - `StreakView` component for displaying streak with flame icon
  - Full `@Environment` support for accessing manager in views

#### Test Coverage
- **174+ Comprehensive Tests** across 5 dedicated test files:
  - `StreakCoreTests.swift` (33 tests): Edge cases, calendars, boundaries, Codable conformance
  - `PersistenceTests.swift` (27 tests): All store implementations, error handling
  - `StreakManagerTests.swift` (58 tests): Manager methods, initialization, configuration
  - `SwiftUIIntegrationTests.swift` (23 tests): Environment injection, modifiers
  - `IntegrationTests.swift` (27 tests): End-to-end flows, real-world scenarios

- **Edge Cases Covered**
  - Calendar variations (Gregorian, Hebrew, Islamic)
  - Leap year transitions (Feb 28/29 → Mar 1)
  - Month/year boundaries (Dec 31 → Jan 1)
  - Midnight boundaries (23:59 → 00:01)
  - Corrupted data recovery
  - Concurrent access patterns

#### Quality Metrics
- ✅ Zero compiler warnings
- ✅ 100% test pass rate (174 tests)
- ✅ Full `Sendable` conformance for concurrency safety
- ✅ Complete API documentation with examples
- ✅ No external dependencies

#### Platform Support
- iOS 17.0+
- macOS 14.0+
- visionOS 2.0+

#### Documentation
- Comprehensive README with quick start guide
- API reference for all public types and methods
- Architecture overview and design patterns
- Usage examples and integration guide
- Contributing guidelines and code style
- Full test coverage documentation

### Known Limitations
- Requires iOS 17+/macOS 14+ (uses `@Observable` macro)
- File storage uses app Documents directory (not iCloud)
- No built-in analytics integration (can add custom hooks)

### Future Roadmap
- [v1.1.0] Best streak tracking and freeze days
- [v1.2.0] TimeZone pinning for global apps
- [v2.0.0] CloudKit sync support
- [v2.1.0] WidgetKit integration examples

---

[Unreleased]: https://github.com/yourusername/MiraiStreakKit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/MiraiStreakKit/releases/tag/v1.0.0
