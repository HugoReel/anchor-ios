import Foundation

/// The single preferences record. Defaults follow the spec: sound off,
/// wins visible, fifteen-minute transition lead, nothing opted in.
public struct UserPreferences: Sendable, Hashable, Codable, Identifiable {
    /// Fixed id so exactly one row ever exists.
    public static let singletonID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))

    public let id: UUID
    public var themeRawValue: String
    public var motionRawValue: String
    public var hapticsEnabled: Bool
    public var soundEnabled: Bool
    public var showWins: Bool
    public var winsPaused: Bool
    public var lowDemandMode: Bool
    /// Transition warning lead, 5…30 minutes.
    public var transitionLeadMinutes: Int
    public var wakeStartMinutes: Int?
    public var wakeEndMinutes: Int?
    public var remindDaily: Bool
    public var remindDailyTimeMinutes: Int?
    public var remindWeekly: Bool
    public var remindWeeklyTimeMinutes: Int?
    public var remindMonthly: Bool
    public var remindMonthlyTimeMinutes: Int?
    public var remindYearly: Bool
    public var remindYearlyTimeMinutes: Int?
    public var quietStartMinutes: Int?
    public var quietEndMinutes: Int?
    public var onboardingComplete: Bool
    public var seedDataInserted: Bool
    /// Day (`yyyymmdd`) on which the Today reflection nudge was dismissed, so
    /// it stays gone for that day and returns fresh the next. Optional so it
    /// decodes from older stored payloads.
    public var reflectionNudgeDismissedDayKey: Int?
    /// Day (`yyyymmdd`) on which the energy check-in prompt was dismissed, so
    /// it only offers once per day. Optional for backward-compatible decoding.
    public var energyPromptDismissedDayKey: Int?
    /// Whether the seed coping examples have been inserted once. Optional for
    /// backward-compatible decoding; nil means not yet seeded.
    public var copingSeeded: Bool?
    /// Whether local notifications are on. Set only after the system grants
    /// authorization; turning it off cancels everything. Optional for
    /// backward-compatible decoding; nil means never enabled.
    public var notificationsEnabled: Bool?
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UserPreferences.singletonID,
        themeRawValue: String = "calm",
        motionRawValue: String = "full",
        hapticsEnabled: Bool = true,
        soundEnabled: Bool = false,
        showWins: Bool = true,
        winsPaused: Bool = false,
        lowDemandMode: Bool = false,
        transitionLeadMinutes: Int = 15,
        wakeStartMinutes: Int? = nil,
        wakeEndMinutes: Int? = nil,
        remindDaily: Bool = false,
        remindDailyTimeMinutes: Int? = nil,
        remindWeekly: Bool = false,
        remindWeeklyTimeMinutes: Int? = nil,
        remindMonthly: Bool = false,
        remindMonthlyTimeMinutes: Int? = nil,
        remindYearly: Bool = false,
        remindYearlyTimeMinutes: Int? = nil,
        quietStartMinutes: Int? = nil,
        quietEndMinutes: Int? = nil,
        onboardingComplete: Bool = false,
        seedDataInserted: Bool = false,
        reflectionNudgeDismissedDayKey: Int? = nil,
        energyPromptDismissedDayKey: Int? = nil,
        copingSeeded: Bool? = nil,
        notificationsEnabled: Bool? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.themeRawValue = themeRawValue
        self.motionRawValue = motionRawValue
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
        self.showWins = showWins
        self.winsPaused = winsPaused
        self.lowDemandMode = lowDemandMode
        self.transitionLeadMinutes = transitionLeadMinutes
        self.wakeStartMinutes = wakeStartMinutes
        self.wakeEndMinutes = wakeEndMinutes
        self.remindDaily = remindDaily
        self.remindDailyTimeMinutes = remindDailyTimeMinutes
        self.remindWeekly = remindWeekly
        self.remindWeeklyTimeMinutes = remindWeeklyTimeMinutes
        self.remindMonthly = remindMonthly
        self.remindMonthlyTimeMinutes = remindMonthlyTimeMinutes
        self.remindYearly = remindYearly
        self.remindYearlyTimeMinutes = remindYearlyTimeMinutes
        self.quietStartMinutes = quietStartMinutes
        self.quietEndMinutes = quietEndMinutes
        self.onboardingComplete = onboardingComplete
        self.seedDataInserted = seedDataInserted
        self.reflectionNudgeDismissedDayKey = reflectionNudgeDismissedDayKey
        self.energyPromptDismissedDayKey = energyPromptDismissedDayKey
        self.copingSeeded = copingSeeded
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
