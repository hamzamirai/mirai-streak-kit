import SwiftUI

/// A pre-built view that displays the current streak with a flame icon.
///
/// This view automatically updates when the streak changes, with smooth animations.
/// It displays both the current streak and the best streak ever achieved.
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
        let best = manager.getBestStreak()

        return VStack(spacing: 4) {
            // Current streak
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(length)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }

            // Best streak indicator (only show if different from current)
            if best > length {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("Best: \(best)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .animation(.smooth, value: length)
        .animation(.smooth, value: best)
    }
}
