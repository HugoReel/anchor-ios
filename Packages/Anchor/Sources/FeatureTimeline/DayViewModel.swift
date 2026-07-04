import Foundation
import Observation
import AnchorCore

/// The three ways to look at a day. A view choice, never a data change.
public enum DayVisualization: String, CaseIterable, Sendable {
    case agenda
    case ribbon
    case focus

    public var displayName: String {
        switch self {
        case .agenda: "Agenda"
        case .ribbon: "Ribbon"
        case .focus: "Focus"
        }
    }
}

/// What Focus view shows: only now, next, and how many blocks wait later.
public struct FocusSummary: Sendable, Hashable {
    public let current: TimeBlock?
    public let next: TimeBlock?
    public let laterCount: Int
}

/// Drives the Day timeline. Orchestrates the tested Core engines
/// (`ModeConversion`, `ShiftEngine`, `WinsEngine`, `BufferAdvisor`) over one
/// day's plan and persists every change. Holds no view code.
@MainActor
@Observable
public final class DayViewModel {
    public private(set) var plan: DayPlan
    public private(set) var presentation: DayPresentation
    public private(set) var bufferSuggestions: [BufferSuggestion] = []
    public private(set) var templates: [DayTemplate] = []
    public private(set) var loadFailed = false
    public var visualization: DayVisualization = .agenda

    private let day: DayDate
    private var preferencesValue = UserPreferences()
    private let dayPlans: any DayPlanRepository
    private let templateRepository: any TemplateRepository
    private let wins: any WinRepository
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding

    public init(
        day: DayDate,
        dayPlans: any DayPlanRepository,
        templates: any TemplateRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        self.day = day
        self.dayPlans = dayPlans
        self.templateRepository = templates
        self.wins = wins
        self.preferences = preferences
        self.dateProvider = dateProvider
        self.plan = DayPlan(date: day)
        self.presentation = .standard(mode: .clock, preferences: UserPreferences())
    }

    /// Blocks in presentation order for the current mode.
    public var blocks: [TimeBlock] {
        plan.sortedBlocks
    }

    /// Now + next + how many more, for the Focus visualisation. The count is
    /// descriptive ("3 more later"), never a demand.
    public var focusSummary: FocusSummary {
        let now = dateProvider.now
        let calendar = dateProvider.calendar
        let current = ScheduleMath.currentBlock(in: plan, at: now, calendar: calendar)
        let next = ScheduleMath.nextBlock(in: plan, at: now, calendar: calendar)
        let shown = Set([current?.id, next?.id].compactMap { $0 })
        let later = plan.blocks.filter { $0.state == .notStarted && !shown.contains($0.id) }.count
        return FocusSummary(current: current, next: next, laterCount: later)
    }

    /// A fresh block ready for the editor, ordered after everything else.
    public var newBlockTemplate: TimeBlock {
        let now = dateProvider.now
        return TimeBlock(
            title: "",
            category: .focus,
            orderIndex: (plan.blocks.map(\.orderIndex).max() ?? -1) + 1,
            createdAt: now,
            modifiedAt: now
        )
    }

    /// Suggested start when the editor turns on "give it a time": 09:00 on
    /// this plan's day.
    public var defaultStartTime: Date {
        day.startDate(calendar: dateProvider.calendar).addingTimeInterval(9 * 3600)
    }

    public func load() async {
        loadFailed = false
        do {
            preferencesValue = try await preferences.load()
            plan = try await dayPlans.plan(for: day) ?? DayPlan(date: day)
            templates = try await templateRepository.allTemplates()
            refreshDerived()
        } catch {
            loadFailed = true
        }
    }

    // MARK: - Blocks

    /// Adds a new block or replaces the block sharing its id.
    public func upsertBlock(_ block: TimeBlock) async {
        var updated = block
        updated.modifiedAt = dateProvider.now
        if let index = plan.blocks.firstIndex(where: { $0.id == block.id }) {
            plan.blocks[index] = updated
        } else {
            plan.blocks.append(updated)
        }
        await persist()
    }

    public func deleteBlock(id: UUID) async {
        plan.blocks.removeAll { $0.id == id }
        await persist()
    }

    public func toggleDone(blockID: UUID) async {
        guard let index = plan.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let now = dateProvider.now
        var block = plan.blocks[index]

        if block.state == .notStarted {
            block.state = .done
            block.completedAt = now
            block.modifiedAt = now
            plan.blocks[index] = block
            if let win = WinsEngine.mintedWin(for: .blockDone(block), preferences: preferencesValue, at: now) {
                try? await wins.append(win)
            }
        } else {
            // Un-completing never removes an earned win — wins only accrue.
            block.state = .notStarted
            block.completedAt = nil
            block.modifiedAt = now
            plan.blocks[index] = block
        }
        await persist()
    }

    public func toggleStep(blockID: UUID, stepID: UUID) async {
        guard let blockIndex = plan.blocks.firstIndex(where: { $0.id == blockID }),
              let stepIndex = plan.blocks[blockIndex].steps.firstIndex(where: { $0.id == stepID }) else { return }
        let now = dateProvider.now
        var step = plan.blocks[blockIndex].steps[stepIndex]
        step.isDone.toggle()
        step.modifiedAt = now
        plan.blocks[blockIndex].steps[stepIndex] = step
        plan.blocks[blockIndex].modifiedAt = now
        if step.isDone, let win = WinsEngine.mintedWin(for: .stepDone(step), preferences: preferencesValue, at: now) {
            try? await wins.append(win)
        }
        await persist()
    }

    public func markAllStepsDone(blockID: UUID) async {
        guard let blockIndex = plan.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let now = dateProvider.now
        plan.blocks[blockIndex].steps = plan.blocks[blockIndex].steps.map { step in
            var done = step
            done.isDone = true
            done.modifiedAt = now
            return done
        }
        plan.blocks[blockIndex].modifiedAt = now
        await persist()
    }

    public func convertToRest(blockID: UUID) async {
        guard let index = plan.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        var block = plan.blocks[index]
        block.category = .rest
        block.modifiedAt = dateProvider.now
        plan.blocks[index] = block
        await persist()
    }

    // MARK: - Whole-day actions

    public func switchMode() async {
        let target: ScheduleMode = plan.mode == .clock ? .sequence : .clock
        plan = ModeConversion.convert(
            plan,
            to: target,
            wakeStartMinutes: preferencesValue.wakeStartMinutes,
            calendar: dateProvider.calendar
        )
        await persist()
    }

    public func shiftDay() async {
        plan = ShiftEngine.shiftRemainder(of: plan, from: dateProvider.now, calendar: dateProvider.calendar)
        await persist()
    }

    public func applyBuffer(_ suggestion: BufferSuggestion) async {
        plan = BufferAdvisor.applying(suggestion, to: plan, at: dateProvider.now)
        await persist()
    }

    // MARK: - Templates

    /// Appends the template's blocks to this day. Existing blocks are never
    /// removed by applying a template.
    public func applyTemplate(_ template: DayTemplate) async {
        let calendar = dateProvider.calendar
        let dayStart = day.startDate(calendar: calendar)
        let baseOrder = (plan.blocks.map(\.orderIndex).max() ?? -1) + 1
        let now = dateProvider.now

        let newBlocks = template.blocks
            .sorted { $0.orderIndex < $1.orderIndex }
            .enumerated()
            .map { offset, templateBlock in
                TimeBlock(
                    title: templateBlock.title,
                    category: templateBlock.category,
                    startTime: templateBlock.startMinutes.map { dayStart.addingTimeInterval(Double($0) * 60) },
                    durationMinutes: templateBlock.durationMinutes,
                    orderIndex: baseOrder + offset,
                    isFlexible: templateBlock.isFlexible,
                    steps: templateBlock.stepTitles.enumerated().map { index, title in
                        BlockStep(title: title, orderIndex: index, createdAt: now, modifiedAt: now)
                    },
                    createdAt: now,
                    modifiedAt: now
                )
            }
        plan.blocks.append(contentsOf: newBlocks)
        if plan.blocks.count == newBlocks.count {
            plan.mode = template.mode
        }
        await persist()
    }

    /// Captures the current day as a reusable template.
    public func saveAsTemplate(named name: String) async {
        let calendar = dateProvider.calendar
        let now = dateProvider.now
        let templateBlocks = plan.sortedBlocks.enumerated().map { offset, block -> TemplateBlock in
            let startMinutes: Int? = block.startTime.map { start in
                let components = calendar.dateComponents([.hour, .minute], from: start)
                return (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
            return TemplateBlock(
                title: block.title,
                category: block.category,
                startMinutes: startMinutes,
                durationMinutes: block.durationMinutes,
                orderIndex: offset,
                isFlexible: block.isFlexible,
                stepTitles: block.steps.sorted { $0.orderIndex < $1.orderIndex }.map(\.title)
            )
        }
        let template = DayTemplate(name: name, mode: plan.mode, blocks: templateBlocks, createdAt: now, modifiedAt: now)
        do {
            try await templateRepository.upsert(template)
            templates = try await templateRepository.allTemplates()
        } catch {
            loadFailed = true
        }
    }

    // MARK: - Persistence

    private func persist() async {
        plan.modifiedAt = dateProvider.now
        do {
            try await dayPlans.upsert(plan)
            refreshDerived()
        } catch {
            loadFailed = true
        }
    }

    private func refreshDerived() {
        presentation = .standard(mode: plan.mode, preferences: preferencesValue)
        bufferSuggestions = BufferAdvisor.suggestions(for: plan, calendar: dateProvider.calendar)
    }
}
