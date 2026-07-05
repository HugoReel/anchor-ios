# Architecture

Anchor is a native SwiftUI app with a strict, layered module graph. The rules
below are enforced by SwiftPM target boundaries, not convention — a dependency
that breaks a layer will not compile.

## Modules

One local package, `Packages/Anchor`, with eleven targets. The app target is a
thin composition root.

```
        ┌─────────────────────────────────────────────┐
        │  App (composition root: AnchorApp,           │
        │  AppDependencies, AppRootView, RootTabView)  │
        └───────────────┬─────────────────────────────┘
                        │ wires concrete stores + system adapters into
                        ▼
   Feature* ── FeatureToday, FeatureTimeline, FeatureGoals, FeatureReflect,
               FeatureCoping, FeatureSettings, FeatureOnboarding
                        │ depend only on
                        ▼
        ┌───────────────┴───────────────┐
        │ AnchorCore        AnchorDesign │
        └───────────────┬───────────────┘
                        ▲ implemented by (never imported downward)
        ┌───────────────┴───────────────┐
        │ AnchorPersistence  AnchorPlatform │
        └───────────────────────────────┘
```

- **AnchorCore** — pure domain: value types (`DayPlan`, `TimeBlock`, `Goal`,
  `MoodCheckIn`, …), rules (`ScheduleMath`, `ShiftEngine`, `WinsEngine`,
  `EnergyAdvisor`, `NotificationPlanner`), the repository/`NotificationScheduling`
  protocols, `DateProviding`, `Copy`, and in-memory doubles. Depends on nothing.
- **AnchorDesign** — tokens, four WCAG-audited themes, Lexend mapping, calm
  components, the `\.anchorTheme` / `\.anchorMotion` environment values.
- **AnchorPersistence** — SwiftData lives here and nowhere else: `@Model`
  classes, the versioned schema + migration plan, and `SwiftDataStore` (one
  `ModelActor` implementing every repository protocol).
- **AnchorPlatform** — system adapters behind Core protocols
  (`UserNotificationScheduler`, `SystemDateProvider`).
- **Feature\*** — one module per screen area; each owns an `@MainActor
  @Observable` view model and thin SwiftUI views. Features depend only on
  Core + Design.

## Patterns

- **Repositories.** Every aggregate has a protocol in AnchorCore, implemented
  twice: `SwiftDataStore` (live) and an in-memory actor (tests/previews).
  Features see only the protocol. See `DECISIONS.md` ADR-004/005 for the
  payload-column storage and aggregate-specific naming.
- **Dependency injection.** `AppDependencies.live()` opens the container and
  builds the store, the notification scheduler, and the `NotificationCoordinator`.
  `RootTabView`/`AppRootView` hand the protocols each view model needs into its
  initializer. No singletons; no global state.
- **The clock.** Nothing reads `Date()` directly. Every time-dependent type
  takes `DateProviding`; the app injects `SystemDateProvider`, tests inject
  `FixedDateProvider` (or a mutable double) so date logic — DST, midnight
  rollover — is deterministic.
- **View models.** `@MainActor @Observable final class`, constructed in the
  SwiftUI root view's `@MainActor init`. State is `private(set)`; views are
  presentation-only and read theme/motion from the environment.
- **Presentation, not deletion.** Low-Demand and sequence modes narrow
  `DayPresentation` (what the UI may show); they never remove data.

## Verification

Development is on Windows with no Xcode; every push is built, tested and linted
on a GitHub Actions macOS runner, which publishes a readable report to the
`ci-logs` branch (ADR-001). The simulator XCUITest is path-gated to the app
shell so domain-only pushes stay fast. `make ci` runs the identical gates on
any Mac.
