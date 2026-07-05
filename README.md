# Anchor (iOS)

Gentle, flexible day structure for autistic adults: a visual day timeline,
goals broken into small steps, an alexithymia-aware reflection space, and
calm, sensory-friendly design throughout. Everything stays on the device —
no accounts, no servers, no analytics, no tracking.

**Status: v1.0.0 — feature-complete.** Built to [PROMPT.md](PROMPT.md).
Companion docs: [ARCHITECTURE.md](ARCHITECTURE.md) (module graph and patterns),
[DECISIONS.md](DECISIONS.md) (ADRs), [ACCESSIBILITY.md](ACCESSIBILITY.md)
(VoiceOver, Dynamic Type, motion, contrast results), [FUTURE.md](FUTURE.md)
(extension seams and known limitations).

## Screen tour

Four fixed tabs, plus Settings behind the gear and the coping bank one tap from
anywhere — each maps to the design principles in PROMPT §3:

- **Today** — the "right now" card, next-up, gentle wins, and an energy check-in
  that can offer (never impose) a lighter day. *Reduce uncertainty; additive
  encouragement; capacity-aware.*
- **Day** — the timeline in three views (agenda, ribbon, focus), duration-based
  blocks that reflow rather than break, one-tap "shift my day", rest as a
  first-class block. *Flexible structure; falling behind is never failure.*
- **Goals** — steps that only accrue, if–then plans, calm target dates with no
  countdown. *Small wins; no loss framing.*
- **Reflect** — a layered check-in (body → energy → optional sliders → optional
  emotion words), where "I'm not sure" is a complete answer. *Alexithymia-aware;
  everything optional.*
- **Settings / Coping / Low-Demand** — user-controlled theme, motion, reminders
  (opt-in, quiet), export/delete, and a mode that hides times and timers.
  *Sensory control; nothing punitive; on-device only.*

## Stack

Swift 6 (strict concurrency), SwiftUI only, SwiftData behind repository
protocols, iOS 17+, zero third-party runtime dependencies. Typeface: Lexend
(bundled, SIL Open Font License — see `App/Resources/Fonts/OFL.txt`).

## Building

On a Mac with Xcode 16+:

```bash
brew install xcodegen swiftlint
make project      # generates Anchor.xcodeproj from project.yml
make ci           # lint + package tests + app build (same commands CI runs)
```

The Xcode project is generated, never committed. Package logic tests can
also run without the project: `make test-packages`.

## How this repo is verified

Development happens on a machine without Xcode; every push is compiled and
tested by GitHub Actions on a macOS runner (see `.github/workflows/ci.yml`).
The workflow publishes a distilled failure/success report to the `ci-logs`
branch, readable without authentication. A phase of work only completes on
a fully green run: build, tests, SwiftLint strict, zero warnings.
