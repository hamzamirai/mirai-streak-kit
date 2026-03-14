import SwiftUI

/// A view modifier that injects a `StreakManager` into the environment.
///
/// You typically don't use this directly; use the `.setupMiraiStreak()` modifier instead.
public struct MiraiStreakInjector: ViewModifier {
    @State private var manager: StreakManager

    /// Creates a new streak injector.
    ///
    /// - Parameters:
    ///   - store: The persistence store to use. Defaults to `UserDefaultsStore()`.
    ///   - config: The manager configuration. Defaults to `.init()`.
    public init(
        store: any StreakStore = UserDefaultsStore(),
        config: StreakManager.Config = .init()
    ) {
        _manager = State(initialValue: StreakManager(store: store, config: config))
    }

    public func body(content: Content) -> some View {
        content.environment(manager)
    }
}

public extension View {
    /// Sets up streak tracking by injecting a `StreakManager` into the environment.
    ///
    /// Apply this modifier once at your app's root to make the streak manager
    /// available to all child views via `@Environment(StreakManager.self)`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .setupMiraiStreak(
    ///                     store: UserDefaultsStore(),
    ///                     config: .init(calendar: .current)
    ///                 )
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - store: The persistence store to use. Defaults to `UserDefaultsStore()`.
    ///   - config: The manager configuration. Defaults to `.init()`.
    /// - Returns: A view with the streak manager injected into the environment.
    func setupMiraiStreak(
        store: any StreakStore = UserDefaultsStore(),
        config: StreakManager.Config = .init()
    ) -> some View {
        modifier(MiraiStreakInjector(store: store, config: config))
    }
}
