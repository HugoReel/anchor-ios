import SwiftUI

/// Placeholder root for the Today tab. The real dashboard arrives in phase 3.
public struct TodayRootView: View {
    public init() {}

    public var body: some View {
        PlaceholderScreen(
            symbol: "sun.max",
            title: "Today",
            message: "Your day, at a gentle pace. This screen arrives in a later phase."
        )
    }
}

/// Shared placeholder used by every tab until its feature lands.
struct PlaceholderScreen: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
