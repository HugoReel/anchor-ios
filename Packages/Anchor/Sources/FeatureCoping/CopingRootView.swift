import SwiftUI

/// Placeholder for the coping strategy bank. Arrives in phase 3.
public struct CopingRootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lifepreserver")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Coping bank")
                .font(.title2)
            Text("Your own strategies, close at hand. Coming soon.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
