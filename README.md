# Anchor (iOS)

Gentle, flexible day structure for autistic adults: a visual day timeline,
goals broken into small steps, an alexithymia-aware reflection space, and
calm, sensory-friendly design throughout. Everything stays on the device —
no accounts, no servers, no analytics, no tracking.

**Status: in development.** Built to [PROMPT.md](PROMPT.md); design decisions
in [docs/superpowers/specs](docs/superpowers/specs) and (soon) DECISIONS.md.

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
