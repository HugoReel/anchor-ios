import SwiftUI

/// Placeholder root for the Goals tab. Goal tracking arrives in phase 3.
public struct GoalsRootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Goals")
                .font(.title2)
            Text("Small steps towards what matters. Coming soon.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
