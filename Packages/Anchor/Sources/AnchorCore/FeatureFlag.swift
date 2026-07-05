/// Compile-time feature switches. The only v1 flag seeds demo data so every
/// screen is reviewable; it is on in DEBUG builds and never in release. Later
/// phases (§11) add their own cases here.
public enum FeatureFlag {
    public static var seedDemoData: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
