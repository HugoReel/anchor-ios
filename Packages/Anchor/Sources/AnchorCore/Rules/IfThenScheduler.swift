import Foundation

/// Surfaces time-triggered if–then plans at the right moment on Today.
public enum IfThenScheduler {
    /// Active time-triggered plans whose trigger falls within
    /// [now, now + window] today. Situation triggers never time-surface.
    public static func surfacing(plans: [IfThenPlan], at instant: Date, calendar: Calendar, windowMinutes: Int) -> [IfThenPlan] {
        []
    }
}
