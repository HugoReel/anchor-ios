import SwiftUI

/// Placeholder for the three-question first run. Arrives in phase 3.
public struct OnboardingRootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.wave")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Welcome")
                .font(.title2)
            Text("A gentle start. Setup arrives in a later phase.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
