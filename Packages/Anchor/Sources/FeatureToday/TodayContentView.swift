import SwiftUI
import AnchorCore
import AnchorDesign

/// Presentation-only Today dashboard. All decisions about what to show live
/// in the view model and its `presentation`; this view just renders them.
struct TodayContentView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: TodayViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                nowCard
                if viewModel.nextBlock != nil {
                    nextUpRow
                }
                if viewModel.showEnergyPrompt {
                    energyPromptCard
                }
                if !viewModel.lighteningSuggestions.isEmpty {
                    lighteningCard
                }
                if viewModel.presentation.showsWins && (!viewModel.winsSummaries.isEmpty || viewModel.winsArePaused) {
                    winsCard
                }
                if viewModel.showReflectionNudge {
                    reflectionNudge
                }
            }
            .padding(Spacing.md)
        }
        .background(theme.background.color)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.setLowDemand(!viewModel.presentation.invitational) }
                } label: {
                    Image(systemName: viewModel.presentation.invitational ? "moon.fill" : "moon")
                }
                .accessibilityLabel(viewModel.presentation.invitational ? Copy.lowDemandTurnOff : Copy.lowDemandTurnOn)
            }
        }
    }

    // MARK: - Right now (hero)

    private var nowCard: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel("Right now")
                if let current = viewModel.currentBlock {
                    HStack(spacing: Spacing.sm) {
                        CategoryChip(current.category)
                        Spacer(minLength: 0)
                        if viewModel.presentation.showsWins {
                            DayProgressRing(progress: viewModel.dayProgress, label: dayLabel)
                        }
                    }
                    Text(current.title)
                        .anchorFont(.display)
                        .foregroundStyle(theme.textPrimary.color)
                    if viewModel.presentation.showsTimers, let progress = viewModel.blockProgress {
                        ProgressView(value: progress)
                            .tint(theme.accent.color)
                            .accessibilityLabel("Progress through this block")
                    }
                } else {
                    Text(viewModel.presentation.invitational ? "Nothing you have to do right now." : "Nothing scheduled right now.")
                        .anchorFont(.title)
                        .foregroundStyle(theme.textPrimary.color)
                    Text("A good moment for whatever you need.")
                        .anchorFont(.body)
                        .foregroundStyle(theme.textSecondary.color)
                }
            }
        }
    }

    private var dayLabel: String {
        "\(Int((viewModel.dayProgress * 100).rounded()))%"
    }

    // MARK: - Next up

    private var nextUpRow: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel(viewModel.presentation.invitational ? "You could move on to" : "Next up")
                if let next = viewModel.nextBlock {
                    HStack(spacing: Spacing.sm) {
                        CategoryChip(next.category)
                        Text(next.title)
                            .anchorFont(.body)
                            .foregroundStyle(theme.textPrimary.color)
                    }
                }
            }
        }
    }

    // MARK: - Energy prompt

    private var energyPromptCard: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(Copy.energyPromptTitle)
                    .anchorFont(.title)
                    .foregroundStyle(theme.textPrimary.color)
                Text(Copy.energyPromptBody)
                    .anchorFont(.body)
                    .foregroundStyle(theme.textSecondary.color)
                HStack(spacing: Spacing.sm) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            Task { await viewModel.submitEnergy(level: level) }
                        } label: {
                            Text("\(level)")
                                .anchorFont(.title)
                                .foregroundStyle(theme.accentText.color)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(theme.accent.color, in: RoundedRectangle(cornerRadius: Radius.control))
                        }
                        .accessibilityLabel("Energy level \(level) of 5")
                    }
                }
                .padding(.top, Spacing.xs)
                Button {
                    Task { await viewModel.dismissEnergyPrompt() }
                } label: {
                    Text(Copy.energyPromptSkip)
                        .anchorFont(.body)
                        .foregroundStyle(theme.textSecondary.color)
                }
            }
        }
    }

    // MARK: - Lightening the day

    private var lighteningCard: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel("A gentler day")
                Text(Copy.lighteningIntro)
                    .anchorFont(.body)
                    .foregroundStyle(theme.textSecondary.color)
                ForEach(viewModel.lighteningSuggestions, id: \.blockID) { suggestion in
                    Button {
                        Task { await viewModel.applySuggestion(suggestion) }
                    } label: {
                        Text(suggestion.reason)
                            .anchorFont(.body)
                            .foregroundStyle(theme.textPrimary.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.sm)
                            .background(theme.surfaceRaised.color, in: RoundedRectangle(cornerRadius: Radius.control))
                    }
                }
            }
        }
    }

    // MARK: - Wins

    private var winsCard: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel("Gentle wins")
                ForEach(viewModel.winsSummaries, id: \.kind) { summary in
                    Text(summary.label)
                        .anchorFont(.body)
                        .foregroundStyle(theme.textPrimary.color)
                }
                if viewModel.winsArePaused {
                    Text(Copy.winsPausedNote)
                        .anchorFont(.caption)
                        .foregroundStyle(theme.textSecondary.color)
                }
            }
        }
    }

    // MARK: - Reflection nudge

    private var reflectionNudge: some View {
        AnchorCard {
            HStack(alignment: .top, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("A moment to reflect is here, if you'd like.")
                        .anchorFont(.body)
                        .foregroundStyle(theme.textPrimary.color)
                }
                Spacer(minLength: 0)
                Button {
                    Task { await viewModel.dismissNudge() }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(theme.textSecondary.color)
                }
                .accessibilityLabel("Dismiss for today")
            }
        }
    }
}
