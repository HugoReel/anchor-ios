import SwiftUI

/// Placeholder root for the Day tab. The timeline arrives in phase 3.
public struct DayRootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.day.timeline.left")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Day")
                .font(.title2)
            Text("Your timeline lives here soon.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
