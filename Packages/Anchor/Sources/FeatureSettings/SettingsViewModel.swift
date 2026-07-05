import Foundation
import Observation
import AnchorCore
import AnchorDesign

/// Owns the settings surface. Reads and writes the single preferences record,
/// builds the export document, and models the two-step delete. Holds no view
/// code and reads the clock only through `DateProviding`.
@MainActor
@Observable
public final class SettingsViewModel {
    public private(set) var theme: ThemeChoice = .calm
    public private(set) var motion: MotionLevel = .full
    public private(set) var hapticsEnabled: Bool = true
    public private(set) var soundEnabled: Bool = false
    public private(set) var showWins: Bool = true
    public private(set) var winsPaused: Bool = false
    public private(set) var lowDemandMode: Bool = false
    /// First explicit confirmation arms the delete; the second carries it out.
    public private(set) var deleteArmed: Bool = false
    public private(set) var didDeleteEverything: Bool = false
    public private(set) var loadFailed: Bool = false

    /// Called after any preference change persists, so the app chrome can
    /// re-read the theme and update live.
    public var onPreferencesChanged: (@MainActor () -> Void)?

    private let preferences: any PreferencesRepository
    private let exporter: DataExporter
    private let wiper: any DataWiping
    private let dateProvider: any DateProviding

    public init(
        preferences: any PreferencesRepository,
        exporter: DataExporter,
        wiper: any DataWiping,
        dateProvider: any DateProviding
    ) {
        self.preferences = preferences
        self.exporter = exporter
        self.wiper = wiper
        self.dateProvider = dateProvider
    }

    public func load() async {
        do {
            let prefs = try await preferences.load()
            theme = ThemeChoice(rawValue: prefs.themeRawValue) ?? .calm
            motion = MotionLevel(rawValue: prefs.motionRawValue) ?? .full
            hapticsEnabled = prefs.hapticsEnabled
            soundEnabled = prefs.soundEnabled
            showWins = prefs.showWins
            winsPaused = prefs.winsPaused
            lowDemandMode = prefs.lowDemandMode
        } catch {
            loadFailed = true
        }
    }

    public func update(theme newValue: ThemeChoice) async { theme = newValue; await persist() }
    public func update(motion newValue: MotionLevel) async { motion = newValue; await persist() }
    public func setHaptics(_ enabled: Bool) async { hapticsEnabled = enabled; await persist() }
    public func setSound(_ enabled: Bool) async { soundEnabled = enabled; await persist() }
    public func setShowWins(_ enabled: Bool) async { showWins = enabled; await persist() }
    public func setWinsPaused(_ paused: Bool) async { winsPaused = paused; await persist() }
    public func setLowDemand(_ enabled: Bool) async { lowDemandMode = enabled; await persist() }

    private func persist() async {
        do {
            var prefs = try await preferences.load()
            prefs.themeRawValue = theme.rawValue
            prefs.motionRawValue = motion.rawValue
            prefs.hapticsEnabled = hapticsEnabled
            prefs.soundEnabled = soundEnabled
            prefs.showWins = showWins
            prefs.winsPaused = winsPaused
            prefs.lowDemandMode = lowDemandMode
            prefs.modifiedAt = dateProvider.now
            try await preferences.save(prefs)
            onPreferencesChanged?()
        } catch {
            loadFailed = true
        }
    }

    /// The whole export document as pretty-printed JSON, or nil on failure.
    public func exportData() async -> Data? {
        do {
            return try await exporter.exportJSON(now: dateProvider.now)
        } catch {
            loadFailed = true
            return nil
        }
    }

    // MARK: - Two-step delete

    public func armDelete() { deleteArmed = true }
    public func cancelDelete() { deleteArmed = false }

    /// Wipes everything, but only once the delete has been armed by a first
    /// explicit confirmation. A lone call does nothing.
    public func confirmDelete() async {
        guard deleteArmed else { return }
        do {
            try await wiper.wipeAll()
            didDeleteEverything = true
            deleteArmed = false
            await load()
            onPreferencesChanged?()
        } catch {
            loadFailed = true
        }
    }
}
