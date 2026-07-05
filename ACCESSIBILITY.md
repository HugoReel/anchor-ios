# Accessibility

Results, not intentions. Each section is filled as its Phase 5 task lands.

## Motion (Task 5.3 — done)

Every animation in the app is gated by `AnchorMotion.effective(user:systemReduceMotion:)`,
which returns the **most restrictive** of the user's motion choice and the system
Reduce Motion setting (`.off` wins over `.reduced` wins over `.full`). The
resulting level is passed to `AnchorMotion.animation(for:)`, which returns `nil`
for `.off` — so `withAnimation(nil)` runs the change with no animation at all.

The effective level is provided through the `\.anchorMotion` environment value:

- `RootTabView` sets it from the stored motion preference (`AppChromeModel.userMotion`)
  combined with `@Environment(\.accessibilityReduceMotion)`.
- `AppRootView` sets it for the first-run flow from the system setting alone
  (no user preference exists yet during onboarding).

All transitions are opacity/position only and stay at or under 250 ms
(`.full` = 200 ms, `.reduced` = 120 ms).

| Animation site | File | Gated through |
| --- | --- | --- |
| Onboarding page advance | `FeatureOnboarding/OnboardingRootView.swift` | `AnchorMotion.animation(for: motion)` |
| Reflect: reveal emotion list | `FeatureReflect/CheckInFlowView.swift` (`withAnimationIfAllowed`) | `AnchorMotion.animation(for: motion)` |

Verified by `AnchorDesignTests`: `mostRestrictiveMotionWins`, `animationIsNilWhenMotionOff`.

## VoiceOver (Task 5.1 — pending)

## Dynamic Type (Task 5.2 — pending)

## Contrast (Task 5.4 — pending)

The automated WCAG audit already runs in `AnchorDesignTests/ContrastAuditTests`
for all four themes; Task 5.4 re-verifies against the final palettes and pastes
the theme × pair × ratio table here.
