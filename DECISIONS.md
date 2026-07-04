# Architecture decision records

Short ADRs for the choices a future maintainer would otherwise have to
reverse-engineer. Newest decisions are appended; none are deleted — a
superseded decision gets a note, not a removal.

## ADR-001 — Verification runs on GitHub macOS CI, not locally

**Context.** Development happens on Windows, which has no Xcode, Swift
toolchain or iOS simulator. The app is iOS-only.

**Decision.** All code is written locally; every build, test and lint gate
runs on GitHub Actions `macos-15` runners in the public repo
`HugoReel/anchor-ios`. The workflow distils each run into a small report and
force-pushes it to an orphan `ci-logs` branch, so failures are readable
without authentication (Actions log downloads require a token; a public
branch does not). A phase is complete only on a fully green run.

**Consequences.** Slower feedback than a local compiler; first pushes of new
code routinely surface compile errors that a local build would have caught.
The `ci-logs` report plus artifact logs make each failure diagnosable. Public
repo keeps macOS minutes free.

## ADR-002 — XcodeGen generates the project; it is never committed

**Context.** An `.xcodeproj` cannot be authored without Xcode, and its
`project.pbxproj` is merge-hostile and unvalidatable blind.

**Decision.** `project.yml` is the source of truth; `make project` runs
`xcodegen generate` on any Mac or in CI. The generated `Anchor.xcodeproj`
is git-ignored. XcodeGen is build tooling, which the spec permits.

**Consequences.** Contributors need `brew install xcodegen`. The project
definition stays small and diffable.

## ADR-003 — One local package, eleven targets

**Context.** The spec sketches eight separate packages under `Packages/`.

**Decision.** A single package `Packages/Anchor` with one target per module
(`AnchorCore`, `AnchorDesign`, `AnchorPersistence`, `AnchorPlatform`, seven
`Feature*`). SwiftPM enforces the dependency direction per target exactly as
strictly as separate packages would, and one generated `Anchor-Package`
scheme tests everything in a single `xcodebuild` invocation.

**Consequences.** `AnchorPlatform` and `FeatureCoping`/`FeatureOnboarding`
were added beyond the spec's list so the app target stays a pure composition
root and system imports (`UserNotifications`, `UIKit`) live behind protocols.

## ADR-004 — SwiftData stores queryable columns plus a Codable payload

**Context.** Aggregates have nested value collections (a day's blocks, a
block's steps, a goal's steps and if–then plans). Modelling every nested type
as a `@Relationship` multiplies the SwiftData surface that must compile
correctly blind, and CloudKit later forbids cascade deletes and required
relationships.

**Decision.** Each aggregate is a top-level `@Model` carrying only the
columns queried or sorted on (`id`, `dayKey`, `timestamp`, `createdAt`,
`orderIndex`) plus a `payload: Data` holding the Codable Core value type as
its source of truth. Nested collections live inside the payload. Mapping is a
single encode/decode.

**Consequences.** No querying inside nested collections — not needed; the app
filters only on day and id. The blob shape is CloudKit-friendly for the sync
seam. `#Index` (iOS 18) is not used; `dayKey` is an integer column giving
range queries without it, keeping the iOS 17 floor.

## ADR-005 — Repository methods are aggregate-specific

**Context.** One type (the SwiftData store) conforms to every repository
protocol. Bare `all()` and `delete(id:)` names collided across protocols —
identical signatures the compiler rejects.

**Decision.** Names carry the aggregate: `allTemplates()`, `allCoping()`,
`deleteGoal(id:)`, and so on, uniform with the existing `allPlans()` /
`allEvents()`. Overloads that differ by parameter type (`upsert(_:)`) keep
one name.

**Consequences.** Slightly less uniform protocols, but explicit at call sites
and collision-free for the shared store.

## ADR-006 — TDD is preserved across the CI boundary

**Context.** The TDD skill requires watching tests fail before implementing,
but a literal red run per micro-step would cost dozens of CI round-trips.

**Decision.** Domain logic (Phase 2) gets a literal red run: the full test
suite plus neutral compiling stubs is pushed and confirmed red with assertion
failures (65 of them, verified), then implementations are pushed and confirmed
green. Later phases author tests before implementation locally but batch one
push per unit; trivially-passing tests get a mutation check at review.

**Consequences.** The red/green evidence is real and recorded by run id
(red: run 28703618370; green: run 28710530091).

## ADR-007 — Falling behind is never failure: no "missed" state exists

**Context.** Rigid time blocks and loss-framed streaks are the most-cited
harms in competing apps, especially for demand-avoidant profiles.

**Decision.** The domain model has no "missed" state — `BlockState` is only
`notStarted` or `done`. Wins are append-only and never reset, decay or
mention absent days. Rest is a first-class category that always counts as a
win. Low-Demand Mode and sequence mode narrow what the UI shows
(`DayPresentation`) rather than deleting data.

**Consequences.** Guilt states are unrepresentable, not merely unstyled. Copy
is audited by test (`CopyTests`) for banned phrases.
