import SwiftUI

/// A pre-built view that displays the current streak with a flame icon.
///
/// This view automatically updates when the streak changes, with smooth animations.
///
/// ## Example
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         VStack {
///             StreakView()
///             // Your other content
///         }
///     }
/// }
/// ```
///
/// - Important: Requires a `StreakManager` in the environment. Use `.setupMiraiStreak()` on a parent view.
public struct StreakView: View {
    @Environment(StreakManager.self) private var manager

    public init() {}

    public var body: some View {
        let length = manager.getStreakLength()

        return HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(length)")
                .font(.system(.title2, design: .rounded).weight(.bold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .animation(.smooth, value: length)
    }
}
