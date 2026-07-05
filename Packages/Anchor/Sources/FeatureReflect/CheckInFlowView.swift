import SwiftUI
import AnchorCore
import AnchorDesign

/// The layered, alexithymia-aware check-in. Body and energy first; optional
/// dimensional sliders; an optional searchable emotion list. Every layer can
/// be skipped, and "I'm not sure" saves on its own.
struct CheckInFlowView: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.anchorMotion) private var motion
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ReflectViewModel

    @State private var showEmotions = false
    @State private var emotionSearch = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    bodyLayer
                    energyLayer
                    dimensionalLayer
                    emotionLayer
                    unsureLayer
                }
                .padding(Spacing.md)
            }
            .background(theme.background.color)
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await viewModel.saveCheckIn() }
                        dismiss()
                    }
                    .disabled(!viewModel.canSaveCheckIn)
                }
            }
        }
    }

    // Layer 1: body sensations.
    private var bodyLayer: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel("In your body")
                FlowChips(
                    options: BodySensationCatalog.suggestions,
                    isSelected: { viewModel.bodySensations.contains($0) },
                    toggle: { sensation in
                        if viewModel.bodySensations.contains(sensation) {
                            viewModel.bodySensations.remove(sensation)
                        } else {
                            viewModel.bodySensations.insert(sensation)
                        }
                    }
                )
            }
        }
    }

    // Layer 1b: energy battery.
    private var energyLayer: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel("Energy")
                HStack(spacing: Spacing.sm) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            viewModel.energy = (viewModel.energy == level) ? nil : level
                        } label: {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill((viewModel.energy ?? 0) >= level ? theme.accent.color : theme.gentle.color)
                                .frame(width: 40, height: 28)
                        }
                        .accessibilityLabel("Energy \(level) of 5")
                    }
                }
            }
        }
    }

    // Layer 2: optional dimensional sliders.
    private var dimensionalLayer: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel("If it helps (optional)")
                sliderRow(
                    "unpleasant",
                    "pleasant",
                    value: Binding(get: { viewModel.valence ?? 0 }, set: { viewModel.valence = $0 })
                )
                sliderRow(
                    "low energy",
                    "high energy",
                    value: Binding(get: { viewModel.arousal ?? 0 }, set: { viewModel.arousal = $0 })
                )
            }
        }
    }

    private func sliderRow(_ low: String, _ high: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Slider(value: value, in: -1...1)
                .tint(theme.accent.color)
            HStack {
                Text(low).anchorFont(.caption).foregroundStyle(theme.textSecondary.color)
                Spacer(minLength: 0)
                Text(high).anchorFont(.caption).foregroundStyle(theme.textSecondary.color)
            }
        }
    }

    // Layer 3: optional emotion words.
    private var emotionLayer: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Button {
                    withAnimationIfAllowed { showEmotions.toggle() }
                } label: {
                    HStack {
                        AnchorSectionLabel("Words for it (optional)")
                        Spacer(minLength: 0)
                        Image(systemName: showEmotions ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                }
                if showEmotions {
                    TextField("Search words", text: $emotionSearch)
                        .textFieldStyle(.roundedBorder)
                    FlowChips(
                        options: filteredEmotions,
                        isSelected: { viewModel.emotionWords.contains($0) },
                        toggle: { word in
                            if viewModel.emotionWords.contains(word) {
                                viewModel.emotionWords.remove(word)
                            } else {
                                viewModel.emotionWords.insert(word)
                            }
                        }
                    )
                }
            }
        }
    }

    private var filteredEmotions: [String] {
        let query = emotionSearch.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return EmotionCatalog.words }
        return EmotionCatalog.words.filter { $0.contains(query) }
    }

    // Layer 0: I'm not sure — always valid.
    private var unsureLayer: some View {
        AnchorCard {
            Toggle(isOn: $viewModel.isUnsure) {
                Text("I'm not sure — and that's okay")
                    .anchorFont(.body)
                    .foregroundStyle(theme.textPrimary.color)
            }
            .tint(theme.accent.color)
        }
    }

    private func withAnimationIfAllowed(_ body: () -> Void) {
        withAnimation(AnchorMotion.animation(for: motion), body)
    }
}

/// A simple wrapping row of selectable chips.
struct FlowChips: View {
    @Environment(\.anchorTheme) private var theme
    let options: [String]
    let isSelected: (String) -> Bool
    let toggle: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: Spacing.sm)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.sm) {
            ForEach(options, id: \.self) { option in
                Button {
                    toggle(option)
                } label: {
                    Text(option)
                        .anchorFont(.caption)
                        .foregroundStyle(isSelected(option) ? theme.accentText.color : theme.textPrimary.color)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .frame(maxWidth: .infinity)
                        .background(isSelected(option) ? theme.accent.color : theme.gentle.color)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
