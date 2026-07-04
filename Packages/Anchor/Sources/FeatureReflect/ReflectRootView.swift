import SwiftUI

/// Placeholder root for the Reflect tab. The check-in space arrives in phase 3.
public struct ReflectRootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Reflect")
                .font(.title2)
            Text("A quiet space to notice how things are. Coming soon.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
