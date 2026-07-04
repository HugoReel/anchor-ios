import SwiftUI
import AnchorCore
import AnchorDesign

/// The Reflect tab home: an invitation to check in, a journal, and calm
/// ways into history and patterns.
struct ReflectContentView: View {
    @Environment(\.anchorTheme) private var theme
    @Bindable var viewModel: ReflectViewModel

    @State private var showCheckIn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                checkInInvite
                JournalEditorView(viewModel: viewModel)
                links
            }
            .padding(Spacing.md)
        }
        .background(theme.background.color)
        .sheet(isPresented: $showCheckIn) {
            CheckInFlowView(viewModel: viewModel)
        }
    }

    private var checkInInvite: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How are things, in your body and energy?")
                    .anchorFont(.title)
                    .foregroundStyle(theme.textPrimary.color)
                Text("Only if you feel like it. \u{201C}I'm not sure\u{201D} is always a fine answer.")
                    .anchorFont(.body)
                    .foregroundStyle(theme.textSecondary.color)
                Button {
                    viewModel.resetDraft()
                    showCheckIn = true
                } label: {
                    Text("Start a check-in")
                        .anchorFont(.body)
                        .foregroundStyle(theme.accentText.color)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(theme.accent.color)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var links: some View {
        VStack(spacing: Spacing.sm) {
            NavigationLink {
                HistoryListView(viewModel: viewModel)
            } label: {
                rowLabel("History", systemImage: "clock")
            }
            NavigationLink {
                PatternsView(viewModel: viewModel)
            } label: {
                rowLabel("Patterns", systemImage: "chart.bar")
            }
        }
    }

    private func rowLabel(_ title: String, systemImage: String) -> some View {
        AnchorCard {
            HStack(spacing: Spacing.sm) {
                Image(systemName: systemImage)
                    .foregroundStyle(theme.accent.color)
                Text(title)
                    .anchorFont(.body)
                    .foregroundStyle(theme.textPrimary.color)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary.color)
            }
        }
    }
}
