import SwiftUI
import AnchorCore
import AnchorDesign

/// A calm chronological list of check-ins and journal entries.
struct HistoryListView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: ReflectViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if viewModel.history.isEmpty {
                    AnchorCard {
                        Text("Nothing here yet. Whatever you record will appear, gently.")
                            .anchorFont(.body)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                } else {
                    ForEach(viewModel.history) { item in
                        historyCard(item)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(theme.background.color)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func historyCard(_ item: ReflectionItem) -> some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Self.dateFormatter.string(from: item.date))
                    .anchorFont(.caption)
                    .foregroundStyle(theme.textSecondary.color)
                switch item {
                case .checkIn(let checkIn):
                    checkInSummary(checkIn)
                case .journal(let journal):
                    Text(journal.text)
                        .anchorFont(.body)
                        .foregroundStyle(theme.textPrimary.color)
                        .lineLimit(4)
                }
            }
        }
    }

    @ViewBuilder
    private func checkInSummary(_ checkIn: MoodCheckIn) -> some View {
        if checkIn.isUnsure && checkIn.bodySensations.isEmpty && checkIn.energy == nil {
            Text("Checked in — not sure, and that's okay.")
                .anchorFont(.body)
                .foregroundStyle(theme.textPrimary.color)
        } else {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let energy = checkIn.energy {
                    Text("Energy \(energy) of 5")
                        .anchorFont(.body)
                        .foregroundStyle(theme.textPrimary.color)
                }
                if !checkIn.bodySensations.isEmpty {
                    Text(checkIn.bodySensations.joined(separator: ", "))
                        .anchorFont(.caption)
                        .foregroundStyle(theme.textSecondary.color)
                }
                if !checkIn.emotionWords.isEmpty {
                    Text(checkIn.emotionWords.joined(separator: ", "))
                        .anchorFont(.caption)
                        .foregroundStyle(theme.textSecondary.color)
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
