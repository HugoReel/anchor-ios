import SwiftUI

/// Placeholder root for Settings. The full settings surface arrives in phase 3.
public struct SettingsRootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Settings")
                .font(.title2)
            Text("Themes, motion, sound and your data. Coming soon.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
