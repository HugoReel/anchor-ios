import Foundation
import Observation
import AnchorCore

/// Drives the Day timeline. Orchestrates the tested Core engines
/// (`ModeConversion`, `ShiftEngine`, `WinsEngine`, `BufferAdvisor`) over one
/// day's plan and persists every change. Holds no view code.
@MainActor
@Observable
public final class DayViewModel {
    public private(set) var plan: DayPlan
    public private(set) var presentation: DayPresentation
    public private(set) var bufferSuggestions: [BufferSuggestion] = []
    public private(set) var loadFailed = false

    private let day: DayDate
    private var preferencesValue = UserPreferences()
    private let dayPlans: any DayPlanRepository
    private let wins: any WinRepository
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding

    public init(
        day: DayDate,
        dayPlans: any DayPlanRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        self.day = day
        self.dayPlans = dayPlans
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

    public func load() async {
        loadFailed = false
        do {
            preferencesValue = try await preferences.load()
            plan = try await dayPlans.plan(for: day) ?? DayPlan(date: day)
            refreshDerived()
        } catch {
            loadFailed = true
        }
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

    public func convertToRest(blockID: UUID) async {
        guard let index = plan.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        var block = plan.blocks[index]
        block.category = .rest
        block.modifiedAt = dateProvider.now
        plan.blocks[index] = block
        await persist()
    }

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
