# Build Anchor — end-to-end iOS build prompt for Claude Code

*(How to use: save this file as `PROMPT.md` in an empty git repo on a Mac with Xcode installed, open Claude Code there, and say: "Read PROMPT.md and execute it end-to-end." Or paste the whole document as your first message.)*

---

## 1. Mission

Build **Anchor**, a production-quality native iOS app that helps autistic adults bring gentle, flexible structure to their lives: a visual day timeline, long-term goals broken into small steps, an alexithymia-aware reflection space, and calm sensory-friendly design throughout.

This is not a prototype. The deliverable is a complete, compiling, tested, documented codebase held to enterprise standards, architected so future features can be added without rework.

---

## 2. Before writing any code — skills and workflow (mandatory)

Four skills are installed in this environment. You must use all of them.

1. **Skill discovery (find-skills).** Run this first. List every installed skill and read each SKILL.md in full before planning. If actual skill names differ slightly from what's described here, adapt — the intent is what matters.
2. **superpowers.** Follow its full workflow for this entire project: brainstorm → written plan → test-driven implementation → code review. Do not freestyle around it. Keep the plan file updated as you go. If it supports subagents for parallel work, use them where sensible.
3. **Frontend design skill A** and **4. Frontend design skill B.** Two separate frontend design skills are installed. Apply **both** to the design system and to **every screen** you build. Where their guidance conflicts, note the conflict, choose with a one-line rationale, and stay consistent.

Working rules:
- Conventional commits at every logical checkpoint.
- After every phase: full build + full test suite green, zero warnings, lint clean, then commit.
- If you need to deviate from this spec in a significant way, stop and ask first.
- Never mark a phase complete without verifying it compiles and tests pass.

---

## 3. Who this is for — evidence-derived design principles (non-negotiable)

These come from a research review of the autism, executive-function, and HCI literature. Treat them as product requirements, not suggestions.

1. **Predictability reduces anxiety.** Visual schedules externalise executive function. Always show what's happening now and what's next. Nothing in the UI should appear, move, or reorder unexpectedly.
2. **Adults, not children.** Much visual-schedule research was done with children; the aesthetic must never be infantilising. Calm, mature, respectful. No cartoon mascots, no childish reward imagery.
3. **Flexibility over rigidity.** Rigid clock-based time blocks are the single most common complaint about competing apps. Anchor must support untimed sequences, slack, and effortless rescheduling. Falling behind schedule must never feel like failure.
4. **Alexithymia is common.** A large share of autistic adults have difficulty identifying and naming emotions. A check-in that forces emotion labels fails them. Body-sensation and energy-based logging come first; emotion words are optional; "I'm not sure" is always a valid, guilt-free answer.
5. **Streaks can harm.** Loss-framed streaks (counters that reset to zero) cause documented distress, especially for demand-avoidant (PDA) profiles. Anchor replaces streaks with additive "gentle wins" that never zero out, can be paused, and can be hidden entirely.
6. **Energy varies day to day.** Capacity fluctuates (autistic burnout, co-occurring ADHD/anxiety/sleep issues). A daily energy check-in should let the app *suggest* lightening the day — never auto-delete or judge.
7. **Demands can feel threatening (PDA).** A Low-Demand Mode must exist: invitational language ("You could…"), timers and warnings hidden, wins hidden, the day rendered as a gentle menu of options rather than a mandate.
8. **Sensory needs vary widely.** Themes, motion controls, haptics and sound toggles are accessibility features, not cosmetics. Respect system Reduce Motion everywhere. Sound off by default.
9. **Autonomy over compliance.** The app suggests; it never nags, guilts, or coerces. All notifications are opt-in, kindly worded, easy to snooze, and trivially easy to turn off forever.
10. **Privacy is trust.** Everything stays on-device. No accounts, no servers, no analytics, no third-party tracking, no network calls in v1.

---

## 4. Platform and stack (decided — do not relitigate)

- Native **Swift** (latest stable toolchain, Swift 6 language mode, strict concurrency checking enabled), **SwiftUI only**.
- Minimum deployment target **iOS 17.0** (SwiftData requirement). Build with the latest stable Xcode.
- Persistence: **SwiftData**, hidden behind repository protocols.
- Architecture: **modular local Swift packages** + a thin app target. MVVM using the Observation framework (`@Observable`).
- Local notifications via `UNUserNotificationCenter`.
- **Zero third-party runtime dependencies.** Build tooling (SwiftLint) is fine.
- Typeface: **Lexend** (bundled, SIL Open Font License — include the licence file), mapped to Dynamic Type.

---

## 5. Architecture requirements (enterprise standards)

Target package layout (finalise in your plan, get the tree written down before scaffolding):

```
Anchor.xcodeproj            // thin app target = composition root only
Packages/
  AnchorCore                // domain models + pure business logic; no UI, no persistence imports
  AnchorPersistence         // SwiftData schema, repositories, migration plan
  AnchorDesign              // design tokens, 4 themes, Lexend, reusable components
  FeatureToday
  FeatureTimeline
  FeatureGoals
  FeatureReflect
  FeatureSettings
```

Rules:

- **Dependency direction:** features depend on Core, Design, and Persistence *interfaces*. Nothing depends on a feature. The app target wires everything together.
- **Repository pattern:** one protocol per aggregate (`DayPlanRepository`, `GoalRepository`, `ReflectionRepository`, `PreferencesRepository`, …) defined in Core, implemented in Persistence with SwiftData, plus an `InMemory` implementation for tests and SwiftUI previews.
- **Dependency injection:** initializer injection, with a lightweight `AppDependencies` container assembled in the app target. No singletons, except system wrappers (clock, notifications, haptics) which live behind protocols.
- **Clock abstraction:** inject a `Clock`/`DateProvider` protocol everywhere time is read. All scheduling logic must be testable across midnight boundaries, DST changes, and time zones.
- **Feature flags:** a simple `FeatureFlag` enum + local store. Every post-v1 feature ships dark behind a flag from day one.
- **Schema versioning:** use `VersionedSchema` + `SchemaMigrationPlan` starting at v1, and write at least one migration test, so future model changes never strand user data.
- **Errors:** typed domain errors; no force unwraps anywhere; user-facing error copy is calm and actionable.
- **Logging:** an `os.Logger` wrapper with a category per module. No `print`.
- **No God objects. No logic in Views beyond presentation.** ViewModels own state; Core owns rules.

---

## 6. Storage and data

- All user data lives on-device in the SwiftData store (included in the user's normal encrypted device/iCloud backup — document this in the README).
- Initial entities (refine field lists in your plan): `DayPlan`, `TimeBlock` (title, category, timed-or-sequenced, steps, flexible flag, rest flag), `BlockStep`, `Goal`, `GoalStep`, `IfThenPlan`, `MoodCheckIn` (body sensations, energy 1–5, optional valence/arousal, optional emotion words), `JournalEntry`, `EnergyCheckIn`, `WinEvent`, `CopingStrategy`, `UserPreferences`, `DayTemplate`.
- Stable `UUID` identifiers, `createdAt`/`modifiedAt` timestamps on every entity — chosen deliberately so CloudKit sync can be added later without a schema rewrite.
- **Export:** Settings → export all data as human-readable JSON via the share sheet. The user owns their data.
- **Delete:** full local wipe with a calm double confirmation.
- Data is text-first and tiny; still index day-scoped queries so the timeline stays instant at years of history.

---

## 7. Feature specification — v1

### 7.1 Today (dashboard)
- "Right now" hero card: current block, category colour, progress within the block, time remaining (hidden in Sequence mode and Low-Demand Mode).
- **Transition warning:** gentle heads-up before a block ends ("In about 15 minutes, gently wrap up. Next is Lunch."). Lead time configurable 5–30 minutes (default 15). Calm wording, calm colour — never red, never alarming.
- "Next up" preview, day-progress ring, today's energy check-in prompt (skippable), gentle wins summary, and a dismissible reflection nudge (no red badges, ever).

### 7.2 Day (timeline)
- **Two scheduling modes per day**, switchable without data loss:
  - **Clock mode** — timed blocks.
  - **Sequence mode** — ordered, untimed blocks; "move on when you're ready".
- Blocks: title, one of five fixed pastel categories **plus Rest** as a first-class category, optional step checklist, optional notes, flexible flag.
- **Slack tools:** a one-tap "shift the rest of my day" action when running late; suggest buffers between long blocks.
- **Rest blocks** count as wins and can never be marked "missed".
- Three visualisations: **Agenda** (vertical list), **Ribbon** (horizontal cards), **Focus** (only now + next + "N more later" — minimal cognitive load).
- Block detail sheet: steps, mark all done, reschedule, convert to rest.
- **Day templates:** save any day as a template; apply a template to any date.

### 7.3 Goals
- Goal → small checkable steps with a live progress bar. Target dates optional; no countdown pressure.
- **If–then plan builder** on any step: "If [trigger/situation/time], then I will [step]." Time-triggered plans surface on Today at the right moment.
- Progress only ever accrues. No goal streaks, no decay, no shame states.

### 7.4 Reflect
- **Alexithymia-aware check-in**, layered in this order, each layer optional:
  1. Body and energy: a simple body-sensation picker (e.g. tense shoulders, tired eyes, restless legs, settled stomach) + energy battery 1–5.
  2. Optional dimensional sliders: unpleasant ↔ pleasant, low energy ↔ high energy.
  3. Optional searchable list of granular emotion words — never required.
  - "I'm not sure" is always a first-class, guilt-free answer.
- Free journaling with autosave, no minimum length, no prompts forced on the user (offer optional gentle prompts).
- History: a calm list plus a simple patterns view (neutral counts and trends — descriptive, never judgemental).
- **Reminders:** daily / weekly / monthly / yearly toggles, user-chosen times, invitational copy ("If you feel like it, a moment to reflect is here"), snooze, quiet hours, and a one-tap permanent off.

### 7.5 Wins (the streak replacement)
- Additive counters only: "8 check-ins this month", "You showed up 4 days this week." Nothing ever resets to zero; missed days are simply not mentioned.
- Pause / holiday mode. Fully hideable in Settings. No flames, no chains, no badges with fail states.

### 7.6 Energy and Low-Demand Mode
- Daily capacity check-in (1–5 battery, optional note) on first open. When energy is low, the app *offers* to lighten the day (suggests specific blocks to defer or convert to rest) — the user always decides.
- **Low-Demand Mode**, reachable in one tap from Today and Settings: invitational language throughout, timers and transition warnings hidden, wins hidden, the timeline rendered as an unordered gentle menu. Persists until the user turns it off.

### 7.7 Coping strategy bank
- A user-curated list of personal strategies (title, note, optional category), seeded with a few editable examples.
- Reachable in **two taps or fewer from anywhere** (persistent toolbar anchor icon). Includes a "suggest one" shuffle button.

### 7.8 Settings
- Theme picker (Calm / Cool / Warm / Low-light) with live preview.
- Motion setting (Full / Reduced / None) — and always honour system Reduce Motion; the most restrictive setting wins.
- Haptics toggle (soft haptics only). Sound toggle (off by default).
- Text size follows Dynamic Type up to accessibility sizes.
- Notification management, wins visibility, Low-Demand default, data export, data delete, licences (Lexend OFL).

### 7.9 First run
- A three-question maximum, fully skippable gentle setup (theme, wake window, whether to show wins). No walls of onboarding.

---

## 8. Design system and accessibility (apply both frontend design skills here)

- **Tokens first:** build `AnchorDesign` with colour, spacing, radius, and type tokens before any feature UI. Four complete themes; five category colours + Rest stay recognisably consistent across all themes.
- **Palette:** muted pastels, low saturation. Verify **WCAG AA contrast for every text/background pair in every theme** — write a small automated check or a documented audit table in ACCESSIBILITY.md.
- **Type:** Lexend bundled and mapped to Dynamic Type text styles; body ≥ 16pt default; two weights are enough.
- **Motion:** nothing autoplays; transitions ≤ 250 ms, opacity/position only; every animation gated behind the motion setting.
- **Layout:** generous whitespace, low density, one primary action per screen, a fixed 4-tab bar (Today, Day, Goals, Reflect) with Settings via a gear — navigation never rearranges itself.
- **Copy:** literal and concrete, sentence case, no idioms, no exclamation-mark cheerleading, and guilt language is banned ("You missed…", "Don't break your streak!" must never appear).
- **VoiceOver:** every interactive element labelled; custom components get proper traits and hints; walk the three core flows (add a block, complete a step, do a check-in) with VoiceOver logic in mind.

---

## 9. Engineering quality gates

- **SwiftLint** (strict, config committed) and consistent formatting; zero warnings including concurrency warnings.
- **Tests (TDD via superpowers):**
  - Unit tests on `AnchorCore` — target ≥ 80% coverage of domain logic: scheduling math, shift-rest-of-day, sequence/clock mode conversion, wins accrual and pause, energy-based day-lightening suggestions, Low-Demand transforms, if–then trigger surfacing, notification lead-time calculation, midnight/DST edge cases.
  - Repository tests against the InMemory implementation, plus a SwiftData round-trip smoke test and one schema-migration test.
  - Keep views thin so logic is unit-testable; add a small number of XCUITests on the critical flows if the simulator is available.
- **Verification loop:** every phase ends with `xcodebuild -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 16' build test` (adjust device name to what's installed), lint clean, commit. Provide a `Makefile` or scripts folder with `build`, `test`, `lint` targets so this is one command.
- **Self review:** at the end of each phase, run the superpowers code-review workflow on your own diff and fix what it finds before moving on.
- **Documentation:** `README.md` (setup, run, screen tour), `ARCHITECTURE.md` (module diagram + dependency rules), `DECISIONS.md` (short ADRs for stack, architecture, storage, streak-replacement design), `ACCESSIBILITY.md` (audit checklist + results), `FUTURE.md` (extension points, see §11).

---

## 10. Build plan (execute in order, checkpoint each phase)

- **Phase 0 — Skills and plan.** Run the skill-discovery skill; read all four skills fully; produce the written implementation plan (superpowers workflow) including the final package tree and entity fields. Commit the plan.
- **Phase 1 — Scaffold.** Xcode project, local packages, Makefile/scripts, SwiftLint, `AnchorDesign` tokens + four themes + Lexend, tab-bar shell with placeholder screens. Build green.
- **Phase 2 — Domain and persistence.** Core models and rules, schema v1 + migration plan, repositories + InMemory doubles, Clock abstraction. Tests green.
- **Phase 3 — Features.** In order: Today → Day timeline → Goals → Reflect → Wins/Energy/Low-Demand → Coping bank → Settings → first run. TDD the logic; apply both frontend design skills to every screen; add seed demo data behind a debug flag so every screen is reviewable.
- **Phase 4 — Notifications.** Local notifications for transition warnings and reflection reminders; honest, gentle permission flow; quiet hours; full opt-out.
- **Phase 5 — Accessibility and sensory audit.** VoiceOver pass, Dynamic Type pass (including largest accessibility sizes), Reduce Motion pass, per-theme contrast audit. Fix everything found; record results in ACCESSIBILITY.md.
- **Phase 6 — Hardening and handoff.** Full review workflow across the codebase, edge cases (midnight, DST, empty states, huge journals), performance sanity, final docs, tag `v1.0.0`.

---

## 11. Future features — architecture must accommodate, but do NOT build now

Leave a documented seam (protocol, flag, or noted extension point) for each, recorded in `FUTURE.md`:

- CloudKit sync / multi-device.
- Caregiver or supporter sharing (must be designed around explicit, revocable consent).
- Home/lock-screen widgets and a Live Activity for the current block.
- Apple Watch companion.
- Routine/template library and sharing.
- AI-assisted task breakdown for goal steps.
- Schedule-density-aware sensory-break suggestions.
- Opt-in insights ("your energy tends to dip mid-afternoon" — descriptive only).

---

## 12. Hard constraints — never do these

- No loss-framed streaks, resettable counters, shame states, red alarm UI, guilt copy, or dark patterns of any kind.
- No accounts, servers, analytics, tracking, or third-party runtime SDKs.
- No autoplaying motion or sound; nothing that flashes.
- No force unwraps; no business logic inside SwiftUI views; no untested scheduling math.
- No skipping the skills workflow; no phase closed without a green build and passing tests.

---

## 13. Definition of done

- The app builds and runs on an iPhone simulator with every v1 feature functional against seed data.
- All tests pass; coverage target met on Core; lint clean; zero warnings.
- All five documentation files complete; ADRs recorded; accessibility audit documented with results.
- README contains a two-minute tour describing each screen **and** how the ten design principles in §3 are visibly expressed in it.
