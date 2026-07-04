import SwiftUI
import AnchorCore
import AnchorDesign

/// Wrapper for sheet presentation of a block by id, resolved live from the
/// view model so the sheet always shows current data.
private struct BlockSelection: Identifiable {
    let id: UUID
}

/// The Day tab: one of three visualisations over the same plan, plus the
/// calm slack tools (shift, buffers) and block editing.
struct DayContentView: View {
    @Environment(\.anchorTheme) private var theme
    @Bindable var viewModel: DayViewModel

    @State private var detailSelection: BlockSelection?
    @State private var editorBlock: TimeBlock?
    @State private var showTemplates = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                controls
                bufferRow
                visualisation
            }
            .padding(Spacing.md)
        }
        .background(theme.background.color)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("Add a block") { editorBlock = viewModel.newBlockTemplate }
                    Button("Templates") { showTemplates = true }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add a block or use a template")
            }
        }
        .sheet(item: $detailSelection) { selection in
            detailSheet(for: selection.id)
        }
        .sheet(item: $editorBlock) { block in
            BlockEditorSheet(
                block: block,
                defaultStart: viewModel.defaultStartTime,
                onSave: { edited in Task { await viewModel.upsertBlock(edited) } }
            )
        }
        .sheet(isPresented: $showTemplates) {
            TemplatesSheet(
                templates: viewModel.templates,
                onApply: { template in Task { await viewModel.applyTemplate(template) } },
                onSaveCurrent: { name in Task { await viewModel.saveAsTemplate(named: name) } }
            )
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("View", selection: $viewModel.visualization) {
                ForEach(DayVisualization.allCases, id: \.self) { choice in
                    Text(choice.displayName).tag(choice)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: Spacing.sm) {
                Button {
                    Task { await viewModel.switchMode() }
                } label: {
                    Label(
                        viewModel.plan.mode == .clock ? "Switch to sequence" : "Switch to clock",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                    .anchorFont(.caption)
                }
                .tint(theme.accent.color)

                if viewModel.presentation.showsTimes {
                    Spacer(minLength: 0)
                    Button {
                        Task { await viewModel.shiftDay() }
                    } label: {
                        Label("Shift my day", systemImage: "clock.arrow.circlepath")
                            .anchorFont(.caption)
                    }
                    .tint(theme.accent.color)
                }
            }
        }
    }

    @ViewBuilder
    private var bufferRow: some View {
        if viewModel.presentation.showsTimes, let suggestion = viewModel.bufferSuggestions.first {
            let title = viewModel.plan.block(withID: suggestion.afterBlockID)?.title ?? "this block"
            AnchorCard {
                HStack(spacing: Spacing.sm) {
                    Text("A \(suggestion.minutes)-minute pause after \(title) could help.")
                        .anchorFont(.caption)
                        .foregroundStyle(theme.textSecondary.color)
                    Spacer(minLength: 0)
                    Button("Add it") {
                        Task { await viewModel.applyBuffer(suggestion) }
                    }
                    .anchorFont(.caption)
                    .tint(theme.accent.color)
                }
            }
        }
    }

    // MARK: - Visualisations

    @ViewBuilder
    private var visualisation: some View {
        if viewModel.blocks.isEmpty {
            emptyState
        } else {
            switch viewModel.visualization {
            case .agenda:
                AgendaListView(viewModel: viewModel, onOpen: { detailSelection = BlockSelection(id: $0) })
            case .ribbon:
                RibbonView(viewModel: viewModel, onOpen: { detailSelection = BlockSelection(id: $0) })
            case .focus:
                FocusView(viewModel: viewModel, onOpen: { detailSelection = BlockSelection(id: $0) })
            }
        }
    }

    private var emptyState: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Nothing planned yet.")
                    .anchorFont(.title)
                    .foregroundStyle(theme.textPrimary.color)
                Text("Add a block whenever you're ready. There's no rush.")
                    .anchorFont(.body)
                    .foregroundStyle(theme.textSecondary.color)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private func detailSheet(for id: UUID) -> some View {
        if let block = viewModel.plan.block(withID: id) {
            BlockDetailSheet(
                block: block,
                showsTimes: viewModel.presentation.showsTimes,
                onToggleStep: { stepID in Task { await viewModel.toggleStep(blockID: id, stepID: stepID) } },
                onMarkAllSteps: { Task { await viewModel.markAllStepsDone(blockID: id) } },
                onConvertToRest: { Task { await viewModel.convertToRest(blockID: id) } },
                onEdit: {
                    detailSelection = nil
                    editorBlock = block
                },
                onDelete: {
                    detailSelection = nil
                    Task { await viewModel.deleteBlock(id: id) }
                }
            )
        }
    }
}

/// Agenda visualisation: a calm vertical list.
struct AgendaListView: View {
    let viewModel: DayViewModel
    let onOpen: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(viewModel.blocks) { block in
                AgendaRow(
                    block: block,
                    showsTimes: viewModel.presentation.showsTimes,
                    onToggle: { Task { await viewModel.toggleDone(blockID: block.id) } },
                    onOpen: { onOpen(block.id) }
                )
            }
        }
    }
}

/// One block in the agenda. Tapping the circle marks it done; tapping the
/// row opens detail. Rest and done blocks are never shown as failing.
struct AgendaRow: View {
    @Environment(\.anchorTheme) private var theme
    let block: TimeBlock
    let showsTimes: Bool
    let onToggle: () -> Void
    let onOpen: () -> Void

    var body: some View {
        AnchorCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                Button(action: onToggle) {
                    Image(systemName: block.state == .done ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(block.state == .done ? theme.accent.color : theme.textSecondary.color)
                }
                .accessibilityLabel(block.state == .done ? "Done" : "Mark done")

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        CategoryChip(block.category)
                        if showsTimes, let start = block.startTime {
                            Text(BlockTimeText.short(start))
                                .anchorFont(.caption)
                                .foregroundStyle(theme.textSecondary.color)
                        }
                    }
                    Text(block.title)
                        .anchorFont(.body)
                        .foregroundStyle(theme.textPrimary.color)
                        .strikethrough(block.state == .done, color: theme.textSecondary.color)
                    if !block.steps.isEmpty {
                        Text(BlockTimeText.stepsSummary(block.steps))
                            .anchorFont(.caption)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onOpen)
            }
        }
    }
}

/// Shared formatting helpers for block rows.
enum BlockTimeText {
    static func short(_ date: Date) -> String {
        formatter.string(from: date)
    }

    static func stepsSummary(_ steps: [BlockStep]) -> String {
        let done = steps.filter(\.isDone).count
        return "\(done) of \(steps.count) steps"
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
