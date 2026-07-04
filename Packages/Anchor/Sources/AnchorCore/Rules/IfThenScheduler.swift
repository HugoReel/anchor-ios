import Foundation

/// Surfaces time-triggered if–then plans at the right moment on Today.
public enum IfThenScheduler {
    /// Active time-triggered plans whose trigger falls within
    /// [now, now + window] today. Situation triggers never time-surface.
    public static func surfacing(plans: [IfThenPlan], at instant: Date, calendar: Calendar, windowMinutes: Int) -> [IfThenPlan] {
        let components = calendar.dateComponents([.hour, .minute], from: instant)
        let nowMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return plans.filter { plan in
            guard plan.isActive,
                  plan.triggerKind == .time,
                  let trigger = plan.triggerMinutes else { return false }
            return trigger >= nowMinutes && trigger <= nowMinutes + windowMinutes
        }
    }
}
