import Foundation

/// A few editable example strategies, inserted once so the bank is never
/// empty on first use. Users can change or remove any of them.
public enum CopingSeeds {
    public static func examples(now: Date = Date()) -> [CopingStrategy] {
        let titles: [(String, String, String)] = [
            ("Slow breathing", "In for four, out for six, a few times over.", "Calm the body"),
            ("Step outside", "A minute of fresh air and a longer look at something far away.", "Change the scene"),
            ("Quiet corner", "Somewhere dim and low-stimulation to settle.", "Reduce input"),
            ("Comfort object", "Hold or fidget with something familiar.", "Ground yourself"),
            ("Name five things", "Notice five things you can see, four you can hear.", "Come back to now")
        ]
        return titles.enumerated().map { index, item in
            CopingStrategy(
                title: item.0,
                note: item.1,
                category: item.2,
                orderIndex: index,
                isSeedExample: true,
                createdAt: now,
                modifiedAt: now
            )
        }
    }
}
