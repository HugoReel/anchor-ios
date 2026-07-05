# Future work

Seams deliberately left for after v1. Each is shaped so it can be added without
reworking the core; where a switch is wanted, it goes through `FeatureFlag`.

## Extension seams (PROMPT §11)

- **CloudKit sync.** Every entity already has a stable `UUID` and
  `createdAt`/`modifiedAt`; the SwiftData models store a Codable payload rather
  than deep relationships (ADR-004), which is the CloudKit-friendly shape. Sync
  would add a mirrored container and a merge policy, not a schema rewrite.
- **Sharing (consent-first).** A supporter view of the day/wins would be
  export-shaped: a read-only projection built from the same repositories, gated
  behind explicit per-item consent. No data leaves the device without it.
- **Widgets / Live Activity.** `ScheduleMath` already derives the current and
  next block and progress as pure functions of a `DayPlan` and an instant — a
  widget timeline provider or Live Activity can call them directly.
- **Apple Watch.** The domain layer is UI-free and `Sendable`; a watch target
  would reuse AnchorCore and a trimmed set of repositories.
- **Template sharing.** `DayTemplate` is already Codable; sharing is an
  export/import of that value.
- **AI task breakdown.** Behind a `FeatureFlag`, an on-device or opt-in service
  could suggest `GoalStep`s or `BlockStep`s; the models accept them today.
- **Sensory-break suggestions & insights.** `EnergyAdvisor` and the wins/energy
  history are the data source; new advisories would be pure rules over them,
  surfaced as offers (never auto-applied), consistent with the current design.

## Known limitations in v1

- **Notification pruning.** `NotificationCoordinator` reschedules transition
  warnings by stable id (replace-by-id), so changed blocks update in place. A
  block that is *deleted* leaves its already-scheduled warning pending until the
  next `cancelAll` (turning reminders off, or off-and-on). The fix is a
  `cancel(ids:)` on `NotificationScheduling` plus a diff against pending ids;
  left for v1.1 because the notification is gentle, snoozable and non-urgent, so
  a stale one is low-harm and the API is better grown deliberately than during
  hardening.
- **Journal history** loads a day range and renders previews lazily; very large
  histories would benefit from windowed fetching (`journalEntries(in:)` already
  supports ranges).
- **Demo data** is DEBUG-only (`FeatureFlag.seedDemoData`); Release builds start
  empty, as a real install should.
