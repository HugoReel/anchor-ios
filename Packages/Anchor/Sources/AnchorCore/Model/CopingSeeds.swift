import Foundation

/// A few editable example strategies, inserted once so the bank is never
/// empty on first use. Users can change or remove any of them.
public enum CopingSeeds {
    private struct Seed {
        let title: String
        let note: String
        let category: String
    }

    public static func examples(now: Date = Date()) -> [CopingStrategy] {
        let seeds: [Seed] = [
            Seed(title: "Slow breathing", note: "In for four, out for six, a few times over.", category: "Calm the body"),
            Seed(title: "Step outside", note: "A minute of fresh air and a look at something far away.", category: "Change the scene"),
            Seed(title: "Quiet corner", note: "Somewhere dim and low-stimulation to settle.", category: "Reduce input"),
            Seed(title: "Comfort object", note: "Hold or fidget with something familiar.", category: "Ground yourself"),
            Seed(title: "Name five things", note: "Notice five things you can see, four you can hear.", category: "Come back to now")
        ]
        return seeds.enumerated().map { index, seed in
            CopingStrategy(
                title: seed.title,
                note: seed.note,
                category: seed.category,
                orderIndex: index,
                isSeedExample: true,
                createdAt: now,
                modifiedAt: now
            )
        }
    }
}
