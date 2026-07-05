import AnchorCore
import AnchorDesign
import Observation

/// Holds the app-wide theme, read from the single preferences record. Reloaded
/// whenever settings change so a theme choice takes effect immediately.
@MainActor
@Observable
final class AppChromeModel {
    private(set) var theme: AnchorTheme = .calm

    private let preferences: any PreferencesRepository

    init(preferences: any PreferencesRepository) {
        self.preferences = preferences
    }

    func reload() async {
        guard let prefs = try? await preferences.load() else { return }
        let choice = ThemeChoice(rawValue: prefs.themeRawValue) ?? .calm
        theme = AnchorTheme.theme(for: choice)
    }
}
