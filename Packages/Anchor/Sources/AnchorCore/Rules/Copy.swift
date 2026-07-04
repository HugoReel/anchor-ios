/// Every reusable user-facing string. Copy rules are product requirements:
/// sentence case, literal and concrete, no idioms, no exclamation marks,
/// and guilt language is banned — enforced by `CopyTests`.
public enum Copy {
    public static let transitionTitle = "Gently wrap up soon"

    public static func transitionBody(leadMinutes: Int, nextTitle: String?) -> String {
        if let nextTitle {
            return "In about \(leadMinutes) minutes, gently wrap up. Next is \(nextTitle)."
        }
        return "In about \(leadMinutes) minutes, gently wrap up."
    }

    public static let reflectionTitle = "A moment for you"
    public static let reflectionBody = "If you feel like it, a moment to reflect is here."

    public static func winsCheckIns(count: Int) -> String {
        count == 1 ? "1 check-in this month" : "\(count) check-ins this month"
    }

    public static func winsShowedUp(days: Int) -> String {
        days == 1 ? "You showed up 1 day this week" : "You showed up \(days) days this week"
    }

    public static func winsBlocksDone(count: Int) -> String {
        count == 1 ? "1 block done this week" : "\(count) blocks done this week"
    }

    public static func winsRest(count: Int) -> String {
        count == 1 ? "1 rest this week" : "\(count) rests this week"
    }

    public static func postponeSuggestion(title: String) -> String {
        "You could move \u{201C}\(title)\u{201D} to another day"
    }

    public static func convertToRestSuggestion(title: String) -> String {
        "You could turn \u{201C}\(title)\u{201D} into rest"
    }

    /// Representative samples for the banned-phrase audit, including
    /// parameterised strings rendered with sample values.
    public static var auditableSamples: [String] {
        [
            transitionTitle,
            transitionBody(leadMinutes: 15, nextTitle: "Lunch"),
            transitionBody(leadMinutes: 20, nextTitle: nil),
            reflectionTitle,
            reflectionBody,
            winsCheckIns(count: 1),
            winsCheckIns(count: 8),
            winsShowedUp(days: 1),
            winsShowedUp(days: 4),
            winsBlocksDone(count: 1),
            winsBlocksDone(count: 5),
            winsRest(count: 1),
            winsRest(count: 3),
            postponeSuggestion(title: "Laundry"),
            convertToRestSuggestion(title: "Deep work")
        ]
    }
}
