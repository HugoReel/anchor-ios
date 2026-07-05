# Anchor iOS v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Environment adaptation (binding):** development happens on Windows with no Swift toolchain; every "run the tests" step is executed by pushing to GitHub and reading the macOS CI result (run status via unauthenticated API, failure detail via the `ci-logs` branch). "Verify RED/GREEN" steps therefore batch at the granularity recorded in each task. Keep this plan updated as tasks complete.

**Goal:** Build Anchor v1 — a native SwiftUI iOS app giving autistic adults gentle, flexible day structure (timeline, goals, alexithymia-aware reflection, wins, low-demand mode) — fully specified by [PROMPT.md](../../../PROMPT.md) and [the design spec](../specs/2026-07-04-anchor-ios-design.md).

**Architecture:** One local SwiftPM package (`Packages/Anchor`) with eleven module targets enforcing dependency direction (features → Core/Design; SwiftData only inside AnchorPersistence; system adapters in AnchorPlatform); a thin XcodeGen-generated app target as composition root. Pure domain logic in AnchorCore operates on value types; repositories bridge to SwiftData models.

**Tech Stack:** Swift 6 language mode, SwiftUI only, SwiftData, Swift Testing, XcodeGen, SwiftLint, GitHub Actions macOS runners. Zero third-party runtime dependencies. Lexend bundled (OFL).

## Global Constraints

Copied from PROMPT.md — every task inherits these:

- Swift 6 language mode, strict concurrency; **zero warnings** (CI sets `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` and `-Xswiftc -warnings-as-errors`); SwiftLint `--strict` clean.
- Minimum deployment target **iOS 17.0**; SwiftUI only; SwiftData behind repository protocols; no third-party runtime SDKs.
- **No force unwraps anywhere.** No `print` — `os.Logger` wrapper, one category per module.
- No logic in Views beyond presentation; ViewModels own state (`@Observable`, `@MainActor`); Core owns rules.
- Initializer injection; `AppDependencies` assembled in app target; system wrappers behind protocols; injected `DateProviding` everywhere time is read.
- Copy rules: sentence case, literal and concrete, no idioms, no exclamation-mark cheerleading, **guilt language banned** ("You missed…" must never appear). No red/alarm UI. Nothing resets to zero. Rest can never be "missed".
- All notifications opt-in, kindly worded, snoozable, trivially disabled forever. Sound off by default. Respect system Reduce Motion; most restrictive motion setting wins; transitions ≤ 250 ms, opacity/position only.
- Everything on-device; no accounts/servers/analytics/tracking/network calls in v1.
- Conventional commits at every logical checkpoint; a phase is complete only when its CI run is fully green.
- Stable `UUID` ids + `createdAt`/`modifiedAt` on every entity; `VersionedSchema` + `SchemaMigrationPlan` from v1.

**Repo:** `C:/Users/hugor/anchor/anchor-ios` → `https://github.com/HugoReel/anchor-ios` (public). Bundle id `com.hugoreel.anchor`.

**CI observation loop (used by every verify step):**

```bash
# latest run for a sha
curl -s "https://api.github.com/repos/HugoReel/anchor-ios/actions/runs?head_sha=$SHA" \
  | grep -E '"(status|conclusion)"' | head -4
# failure/success detail written by the workflow itself
curl -s "https://raw.githubusercontent.com/HugoReel/anchor-ios/ci-logs/ci/main/latest.md"
```

---

## Phase 1 — Scaffold (CI loop, package, app shell, design tokens)

### Task 1.1: Minimal pipeline probe — prove the CI loop end-to-end

Smallest possible green: one package target, one passing test, lint, the full reporting machinery. Calibrates runner names, jq paths, and the ci-logs publishing **before** the real scaffold can fail eight ways at once.

**Files:**
- Create: `.gitignore`, `.gitattributes`, `Makefile`, `.swiftlint.yml`
- Create: `Packages/Anchor/Package.swift`
- Create: `Packages/Anchor/Sources/AnchorCore/AnchorCore.swift`
- Create: `Packages/Anchor/Tests/AnchorCoreTests/SmokeTests.swift`
- Create: `scripts/ci-report.sh`, `.github/workflows/ci.yml`

- [x] **Step 1: Repo hygiene files**

`.gitattributes` (CRLF on Windows would break shell scripts on the runner):

```
* text=auto eol=lf
*.png binary
*.ttf binary
```

`.gitignore`:

```
.build/
.swiftpm/
DerivedData/
Anchor.xcodeproj/
*.xcresult
.DS_Store
xcuserdata/
```

`.swiftlint.yml`:

```yaml
included:
  - App
  - Packages/Anchor/Sources
  - Packages/Anchor/Tests
opt_in_rules:
  - empty_count
  - closure_spacing
  - contains_over_first_not_nil
  - fatal_error_message
disabled_rules:
  - todo
line_length:
  warning: 140
  error: 200
identifier_name:
  min_length: 2
force_unwrapping:
  severity: error
```

(`force_unwrapping` is opt-in — add it to `opt_in_rules`.)

`Makefile` (single-command verification per PROMPT §9; used verbatim by CI and by any Mac):

```make
SIM_NAME ?= iPhone 16
DEST := platform=iOS Simulator,name=$(SIM_NAME)

.PHONY: project build test test-packages lint ci

project:
	xcodegen generate

lint:
	swiftlint lint --strict

test-packages:
	cd Packages/Anchor && xcodebuild test -scheme Anchor-Package \
	  -destination '$(DEST)' -enableCodeCoverage YES \
	  OTHER_SWIFT_FLAGS='$$(inherited) -warnings-as-errors' | tee ../../build/test-packages.log

build: project
	xcodebuild build -scheme Anchor -project Anchor.xcodeproj \
	  -destination '$(DEST)' CODE_SIGNING_ALLOWED=NO \
	  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES | tee build/app-build.log

test: test-packages

ci: lint test-packages build
```

- [x] **Step 2: Probe package** — `Package.swift` with only AnchorCore + tests (full manifest lands in Task 1.2):

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Anchor",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AnchorCore", targets: ["AnchorCore"])
    ],
    targets: [
        .target(name: "AnchorCore"),
        .testTarget(name: "AnchorCoreTests", dependencies: ["AnchorCore"])
    ],
    swiftLanguageModes: [.v6]
)
```

`Sources/AnchorCore/AnchorCore.swift`:

```swift
/// Namespace marker for the AnchorCore module.
public enum AnchorCore {
    public static let moduleName = "AnchorCore"
}
```

`Tests/AnchorCoreTests/SmokeTests.swift`:

```swift
import Testing
@testable import AnchorCore

@Test func moduleLoads() {
    #expect(AnchorCore.moduleName == "AnchorCore")
}
```

- [x] **Step 3: CI workflow + report script** — `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
  workflow_dispatch:
permissions:
  contents: write
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
jobs:
  ci:
    runs-on: macos-15
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - name: Tool versions
        run: |
          sw_vers
          xcodebuild -version
          swift --version
      - name: Install tools
        run: brew install xcodegen swiftlint
      - name: Resolve simulator
        id: sim
        run: |
          set -euo pipefail
          NAME=$(xcrun simctl list devices available --json \
            | jq -r '[.devices[] | .[] | select(.name | test("^iPhone")) | .name] | (map(select(. == "iPhone 16")) + .)[0]')
          echo "Using simulator: $NAME"
          echo "name=$NAME" >> "$GITHUB_OUTPUT"
      - name: Lint
        run: mkdir -p build && (swiftlint lint --strict | tee build/lint.log)
      - name: Package tests
        run: make test-packages SIM_NAME="${{ steps.sim.outputs.name }}"
      - name: App build
        if: ${{ hashFiles('project.yml') != '' }}
        run: make build SIM_NAME="${{ steps.sim.outputs.name }}"
      - name: Publish ci-logs
        if: always()
        env:
          OUTCOME: ${{ job.status }}
        run: bash scripts/ci-report.sh
      - name: Upload full logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: build-logs
          path: build/*.log
          if-no-files-found: ignore
```

`scripts/ci-report.sh` (distils logs, force-pushes to `ci-logs`):

```bash
#!/usr/bin/env bash
set -uo pipefail
BRANCH="${GITHUB_REF_NAME:-local}"
OUT=$(mktemp -d)
REPORT="$OUT/latest.md"
{
  echo "# CI report — $BRANCH @ ${GITHUB_SHA:-unknown}"
  echo "- run: ${GITHUB_RUN_ID:-?} attempt ${GITHUB_RUN_ATTEMPT:-?} — outcome: ${OUTCOME:-unknown}"
  echo "- date: $(date -u +%FT%TZ)"
  for f in build/lint.log build/test-packages.log build/app-build.log; do
    [ -f "$f" ] || continue
    echo; echo "## ${f}"
    echo '### errors/warnings'
    echo '```'
    grep -E "(error|warning):" "$f" | grep -v "warnings-as-errors" | sort -u | head -100 || true
    echo '```'
    echo '### test summary'
    echo '```'
    grep -E "(Test Suite|Test run|Executed|passed|failed|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED|✔|✘)" "$f" | tail -60 || true
    echo '```'
  done
} > "$REPORT"
cd "$OUT"
git init -q -b ci-logs
git config user.name "ci"
git config user.email "ci@users.noreply.github.com"
mkdir -p "ci/$BRANCH"
cp latest.md "ci/$BRANCH/latest.md"
git add -A
git commit -qm "ci report $BRANCH ${GITHUB_SHA:-}"
git push -qf "https://x-access-token:${GITHUB_TOKEN:-$(cat /dev/null)}@github.com/${GITHUB_REPOSITORY}.git" ci-logs
```

Note: `GITHUB_TOKEN` must be exported to the step — add `env: GITHUB_TOKEN: ${{ github.token }}` to the "Publish ci-logs" step.

- [x] **Step 4: Commit** — `chore: bootstrap package, lint, Makefile and CI pipeline probe`
- [x] **Step 5: Push once repo exists; verify GREEN** — run 28702682207 green first try (whole Phase 1 pushed at once; probe staging unnecessary). ci-logs readable unauthenticated. Found and fixed a false green: make 3.81 ignores .SHELLFLAGS so tee masked SwiftLint's exit code; pipefail now inline per recipe and the 7 masked identifier_name violations are fixed.

### Task 1.2: Full package skeleton — eleven targets

**Files:**
- Modify: `Packages/Anchor/Package.swift` (full target graph)
- Create: one `<Target>.swift` namespace marker file per new target under `Packages/Anchor/Sources/<Target>/`
- Create: `Packages/Anchor/Sources/AnchorCore/Logging/AnchorLogger.swift`
- Test: extend `SmokeTests` pattern per target with logic later; for now each feature target compiles empty.

**Interfaces (produced):** module names `AnchorCore`, `AnchorDesign`, `AnchorPersistence`, `AnchorPlatform`, `FeatureToday`, `FeatureTimeline`, `FeatureGoals`, `FeatureReflect`, `FeatureCoping`, `FeatureSettings`, `FeatureOnboarding`; dependency edges exactly as the design spec §3 table.

- [x] **Step 1:** Full `Package.swift`: products = one `.library` per target above; targets with `dependencies:` per the table; test targets `AnchorCoreTests`, `AnchorDesignTests`, `AnchorPersistenceTests` (feature VM tests join their feature targets' test targets in Phase 3: `FeatureTodayTests`, `FeatureTimelineTests`, `FeatureGoalsTests`, `FeatureReflectTests`).
- [x] **Step 2:** `AnchorLogger.swift`:

```swift
import os

public struct AnchorLogger: Sendable {
    private let logger: os.Logger
    public init(category: String) {
        self.logger = os.Logger(subsystem: "com.hugoreel.anchor", category: category)
    }
    public func debug(_ message: String) { logger.debug("\(message, privacy: .public)") }
    public func info(_ message: String) { logger.info("\(message, privacy: .public)") }
    public func error(_ message: String) { logger.error("\(message, privacy: .public)") }
}
```

- [x] **Step 3: Commit** — `feat: add full module target graph`
- [x] **Step 4:** Verify GREEN on CI — covered by run 28702682207.

### Task 1.3: Lexend fonts + app target + tab shell

**Files:**
- Create: `App/Resources/Fonts/Lexend-Regular.ttf`, `App/Resources/Fonts/Lexend-SemiBold.ttf`, `App/Resources/Fonts/OFL.txt` (download: `https://raw.githubusercontent.com/googlefonts/lexend/main/fonts/lexend/ttf/Lexend-Regular.ttf`, `…/Lexend-SemiBold.ttf`, `…/main/OFL.txt`; fallback source: `https://raw.githubusercontent.com/google/fonts/main/ofl/lexend/…`)
- Create: `project.yml`, `App/AnchorApp.swift`, `App/AppDependencies.swift`, `App/RootTabView.swift`, `App/Assets.xcassets/` (AppIcon empty + AccentColor)
- Test: app build job activates (hashFiles gate) — compile is the test.

**Interfaces (produced):** `AppDependencies` struct with `static func live() -> AppDependencies`; `RootTabView(dependencies:)`. Tab order fixed forever: Today, Day, Goals, Reflect (PROMPT §8 — navigation never rearranges).

- [x] **Step 1:** `project.yml`:

```yaml
name: Anchor
options:
  bundleIdPrefix: com.hugoreel
  deploymentTarget:
    iOS: "17.0"
packages:
  Anchor:
    path: Packages/Anchor
targets:
  Anchor:
    type: application
    platform: iOS
    sources:
      - path: App
    dependencies:
      - package: Anchor
        products:
          - AnchorCore
          - AnchorDesign
          - AnchorPersistence
          - AnchorPlatform
          - FeatureToday
          - FeatureTimeline
          - FeatureGoals
          - FeatureReflect
          - FeatureCoping
          - FeatureSettings
          - FeatureOnboarding
    settings:
      base:
        SWIFT_VERSION: "6.0"
        SWIFT_STRICT_CONCURRENCY: complete
        GENERATE_INFOPLIST_FILE: true
        INFOPLIST_KEY_UILaunchScreen_Generation: true
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: true
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 0.1.0
    info:
      path: App/Info.plist
      properties:
        CFBundleDisplayName: Anchor
        UILaunchScreen: {}
        UIAppFonts:
          - Lexend-Regular.ttf
          - Lexend-SemiBold.ttf
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
schemes:
  Anchor:
    build:
      targets:
        Anchor: all
```

- [x] **Step 2:** `AnchorApp.swift` (`@main`, injects dependencies via environment), `AppDependencies.swift` (Phase 1: empty container + logger; grows in Phase 2), `RootTabView.swift`: `TabView` with four fixed tabs (Today `anchor` SF symbol? — use `sun.max` Today, `calendar.day.timeline.left` Day, `flag` Goals, `book.closed` Reflect; final glyphs revisited in Phase 3 design pass), each tab a `NavigationStack` with placeholder screen text + gear `ToolbarItem` pushing empty `SettingsPlaceholderView`. All copy sentence case, no exclamation marks.
- [x] **Step 3: Commit** — `feat: add app target shell with fixed four-tab navigation and bundled Lexend`
- [x] **Step 4:** Verify GREEN — `BUILD SUCCEEDED` in run 28702682207.

### Task 1.4: AnchorDesign tokens, four themes, automated WCAG audit

**Files:**
- Create in `Packages/Anchor/Sources/AnchorDesign/`: `RGBAColor.swift`, `AnchorTheme.swift`, `Themes/CalmTheme.swift`, `Themes/CoolTheme.swift`, `Themes/WarmTheme.swift`, `Themes/LowLightTheme.swift`, `CategoryPalette.swift`, `Spacing.swift`, `Radius.swift`, `AnchorFont.swift`, `MotionSetting.swift`
- Test: `Packages/Anchor/Tests/AnchorDesignTests/ContrastAuditTests.swift`, `ThemeConsistencyTests.swift`

**Interfaces (produced, relied on by every screen):**

```swift
public struct RGBAColor: Sendable, Hashable {   // sRGB 0…1 components
    public let red: Double, green: Double, blue: Double, alpha: Double
    public var color: Color { get }             // SwiftUI bridge
    public func contrastRatio(with other: RGBAColor) -> Double  // WCAG 2.1
}
public enum ThemeChoice: String, CaseIterable, Codable, Sendable { case calm, cool, warm, lowLight }
public struct AnchorTheme: Sendable {
    public let choice: ThemeChoice
    public let background, surface, surfaceRaised: RGBAColor
    public let textPrimary, textSecondary: RGBAColor
    public let accent, accentText: RGBAColor
    public let gentle: RGBAColor                 // calm highlight — never red
    public static func theme(for choice: ThemeChoice) -> AnchorTheme
    public var contrastAuditPairs: [(name: String, fg: RGBAColor, bg: RGBAColor, minimum: Double)] { get }
}
public enum BlockCategoryColor { public static func color(for category: BlockCategory, in theme: AnchorTheme) -> RGBAColor }
public enum Spacing { public static let xs: CGFloat = 4; s = 8; m = 16; l = 24; xl = 40 }
public enum Radius { public static let card: CGFloat = 16; control: CGFloat = 10 }
public enum AnchorFont {
    case display, title, body, caption, mono   // display/title = Lexend-SemiBold, body/caption = Lexend-Regular
    public func font(relativeTo style: Font.TextStyle) -> Font  // Font.custom(_, size:, relativeTo:) — Dynamic Type
}
```

WCAG math (implement exactly — this is the automated audit PROMPT §8 requires):
relative luminance `L = 0.2126·R' + 0.7152·G' + 0.0722·B'` where `c' = c/12.92` if `c ≤ 0.04045` else `((c+0.055)/1.055)^2.4`; ratio `(L1+0.05)/(L2+0.05)`, lighter first.

- [x] **Step 1: Failing tests first** — `ContrastAuditTests`: for every `ThemeChoice`, every `contrastAuditPairs` entry asserts `ratio ≥ minimum` (body pairs 4.5, large-text/secondary-on-surface pairs per declaration; category chip text pairs included); known-value test: `RGBAColor(1,1,1,1).contrastRatio(with: .init(0,0,0,1)) == 21 ± 0.01`. `ThemeConsistencyTests`: category hues stay recognisable across themes — for each category, hue angle spread across the four themes ≤ 40°; Rest is distinct from the five pastels in every theme (ΔE or min hue distance assertion); no theme colour equals pure red territory (hue 345°–15° with saturation > 0.5 banned — "never red").
- [x] **Step 2:** Implement tokens + four muted-pastel themes (design skills applied: Lexend personality, low saturation, distinct-but-calm palettes; Low-light = dark theme with reduced contrast ceilings still ≥ 4.5 body). Iterate values until the audit passes **by construction locally computed** (the WCAG math runs identically in my head/spreadsheet and in CI — pick values with margin ≥ 4.8).
- [x] **Step 3: Commit** — `feat: add design tokens, four themes, Lexend mapping and automated WCAG audit` (9117c21; interface drift from plan: `contrastAuditPairs` returns `[ContrastPair]` struct not tuples; `AnchorFont.font` is a property plus `.anchorFont(_:)` view modifier; `MotionLevel` case `off` not `none` to avoid Optional-pattern clashes)
- [x] **Step 4:** Verify GREEN. Phase 1 gate met: 14 package tests green (6 core, 8 design), app builds, lint truly strict after the pipefail fix.

---

## Phase 2 — Domain and persistence (RED push, then GREEN push)

### Task 2.1: Core value model + DayDate + Clock

**Files:**
- Create in `Packages/Anchor/Sources/AnchorCore/Model/`: `DayDate.swift`, `ScheduleMode.swift`, `BlockCategory.swift`, `BlockState.swift`, `TimeBlock.swift`, `BlockStep.swift`, `DayPlan.swift`, `DayTemplate.swift`, `Goal.swift`, `GoalStep.swift`, `IfThenPlan.swift`, `MoodCheckIn.swift`, `JournalEntry.swift`, `EnergyCheckIn.swift`, `WinEvent.swift`, `CopingStrategy.swift`, `UserPreferences.swift`, `DomainError.swift`
- Create: `Sources/AnchorCore/Time/DateProviding.swift` (`protocol DateProviding: Sendable { var now: Date { get }; var calendar: Calendar { get } }` + `struct FixedDateProvider` for tests)
- Test: `Tests/AnchorCoreTests/DayDateTests.swift`

All value types: `struct`, `Sendable`, `Hashable`, `Codable`, `Identifiable` with `id: UUID`, `createdAt`/`modifiedAt: Date`. Fields exactly per design spec §5. `DayDate` = `(year, month, day)` struct, `Comparable`, with `init(date: Date, calendar: Calendar)`, `func startDate(calendar:) -> Date`, `func advanced(by days: Int, calendar:) -> DayDate`.

Named test cases: `dayDateFromDateRespectsTimeZone`, `dayDateOrdering`, `dayDateAdvanceAcrossMonthEnd`, `dayDateAdvanceAcrossDSTSpringForward` (America/New_York 2025-03-09), `startDateIsMidnightLocal`.

### Task 2.2: Scheduling engine (pure math)

**Files:** `Sources/AnchorCore/Scheduling/ScheduleMath.swift`, `ShiftEngine.swift`, `ModeConversion.swift`, `BufferAdvisor.swift`; tests `Tests/AnchorCoreTests/ScheduleMathTests.swift`, `ShiftEngineTests.swift`, `ModeConversionTests.swift`, `BufferAdvisorTests.swift`

**Interfaces (produced):**

```swift
public enum ScheduleMath {
    public static func currentBlock(in plan: DayPlan, at instant: Date, calendar: Calendar) -> TimeBlock?
    public static func nextBlock(in plan: DayPlan, at instant: Date, calendar: Calendar) -> TimeBlock?
    public static func progress(of block: TimeBlock, in plan: DayPlan, at instant: Date, calendar: Calendar) -> Double?
    public static func dayProgress(of plan: DayPlan, at instant: Date, calendar: Calendar) -> Double
    public static func transitionWarningDate(for block: TimeBlock, in plan: DayPlan, leadMinutes: Int, calendar: Calendar) -> Date?
}
public enum ShiftEngine {
    /// One-tap "shift the rest of my day": moves not-started timed blocks so the next begins at `instant`, preserving durations and relative gaps.
    public static func shiftRemainder(of plan: DayPlan, from instant: Date, calendar: Calendar) -> DayPlan
}
public enum ModeConversion {
    /// Lossless: clock→sequence keeps times dormant; sequence→clock restores or lays out from wake window.
    public static func convert(_ plan: DayPlan, to mode: ScheduleMode, wakeStartMinutes: Int?, calendar: Calendar) -> DayPlan
}
public struct BufferSuggestion: Sendable, Hashable { public let afterBlockID: UUID; public let minutes: Int }
public enum BufferAdvisor { public static func suggestions(for plan: DayPlan, calendar: Calendar) -> [BufferSuggestion] }
```

Named test cases (each is one `@Test`; DST cases pin `TimeZone(identifier: "America/New_York")` 2025-03-09 / 2025-11-02, plus midnight cases at 23:50–00:10):
`currentBlockInsideTimedBlock`, `currentBlockNilInGap`, `currentBlockSequenceModeIsFirstUnfinished`, `nextBlockSkipsDoneBlocks`, `progressHalfwayIsPointFive`, `progressNilForSequenceMode`, `dayProgressCountsDoneOverTotal`, `transitionWarningLeadRespected`, `transitionWarningNilWhenLeadExceedsBlock`, `shiftMovesOnlyNotStartedBlocks`, `shiftPreservesDurationsAndGaps`, `shiftNoOpWhenNothingRemains`, `convertToSequenceRetainsDormantTimes`, `convertRoundTripLossless`, `convertToClockFromWakeWindowLaysOutSequentially`, `bufferSuggestedBetweenLongAdjacentBlocks`, `noBufferWhenGapExists`, `springForwardDayKeepsProgressMonotonic`, `fallBackDayHandlesRepeatedHour`, `midnightBoundaryBlockBelongsToItsDay`.

### Task 2.3: Wins, energy, low-demand, if-then, notification planning (pure rules)

**Files:** `Sources/AnchorCore/Rules/WinsEngine.swift`, `EnergyAdvisor.swift`, `LowDemandPresentation.swift`, `IfThenScheduler.swift`, `NotificationPlanner.swift`, `Copy.swift`; tests mirror names (`WinsEngineTests.swift` etc.)

**Interfaces (produced):**

```swift
public struct WinsSummary: Sendable, Hashable { public let label: String; public let count: Int }  // additive only
public enum WinsEngine {
    public static func mintedWin(for event: WinEventTrigger, preferences: UserPreferences, at instant: Date) -> WinEvent?  // nil when paused
    public static func summaries(events: [WinEvent], reference: DayDate, calendar: Calendar) -> [WinsSummary]  // "N check-ins this month", "You showed up N days this week"
}
public struct LighteningSuggestion: Sendable, Hashable { public enum Action: Sendable, Hashable { case defer_, convertToRest }; public let blockID: UUID; public let action: Action; public let reason: String }
public enum EnergyAdvisor { public static func suggestions(for plan: DayPlan, energyLevel: Int) -> [LighteningSuggestion] }  // ≤3, energy ≤2 only, never touches rest blocks, never auto-applies
public struct DayPresentation: Sendable {  // what the UI may show
    public let showsTimes: Bool, showsTimers: Bool, showsTransitionWarnings: Bool, showsWins: Bool
    public let invitational: Bool          // "You could…" copy set
    public static func standard(mode: ScheduleMode, preferences: UserPreferences) -> DayPresentation
}
public enum IfThenScheduler { public static func surfacing(plans: [IfThenPlan], at instant: Date, calendar: Calendar, windowMinutes: Int) -> [IfThenPlan] }
public struct PlannedNotification: Sendable, Hashable { public let id: String; public let fireDate: Date; public let title: String; public let body: String }
public enum NotificationPlanner {
    public static func transitionWarning(for block: TimeBlock, in plan: DayPlan, preferences: UserPreferences, calendar: Calendar) -> PlannedNotification?
    public static func reflectionReminders(preferences: UserPreferences, from instant: Date, calendar: Calendar, horizonDays: Int) -> [PlannedNotification]
    public static func snoozed(_ notification: PlannedNotification, byMinutes minutes: Int) -> PlannedNotification
}
public enum Copy { /* every user-facing string constant; audited: sentence case, no idioms, no guilt, no exclamation marks */ }
```

Named test cases: `blockDoneMintsWin`, `restCompletionMintsWin`, `checkInMintsWin`, `pausedWinsMintNothing`, `summariesNeverMentionMissedDays`, `showedUpCountsDistinctDays`, `monthWindowUsesCalendar`, `lowEnergyProducesAtMostThreeSuggestions`, `suggestionsNeverTargetRestBlocks`, `energyAboveTwoProducesNone`, `deferSuggestsFlexibleBlocksFirst`, `lowDemandHidesTimersWarningsWins`, `sequenceModeHidesTimes`, `standardClockModeShowsAll`, `ifThenSurfacesWithinWindow`, `ifThenIgnoresInactive`, `ifThenSituationTriggersExcludedFromTimeSurfacing`, `transitionWarningUsesLeadMinutes`, `transitionWarningNilInSequenceMode`, `transitionWarningNilInLowDemand`, `transitionWarningSuppressedInQuietHours`, `reflectionRemindersRespectCadenceAndTime`, `reflectionRemindersShiftOutOfQuietHours`, `remindersEmptyWhenAllTogglesOff`, `snoozeAddsExactMinutes`, `copyContainsNoBannedPhrases` (scans every `Copy` constant for "missed", "streak", "!", "don't break").

### Task 2.4: Repository protocols + InMemory implementations

**Files:** `Sources/AnchorCore/Repositories/RepositoryProtocols.swift`, `InMemoryRepositories.swift`; tests `Tests/AnchorCoreTests/InMemoryRepositoryTests.swift`

**Interfaces (produced; SwiftData mirrors these in 2.5):**

```swift
public protocol DayPlanRepository: Sendable {
    func plan(for day: DayDate) async throws -> DayPlan?
    func plans(in range: ClosedRange<DayDate>) async throws -> [DayPlan]
    func upsert(_ plan: DayPlan) async throws
    func delete(id: UUID) async throws
}
public protocol TemplateRepository: Sendable { func all() async throws -> [DayTemplate]; func upsert(_ t: DayTemplate) async throws; func delete(id: UUID) async throws }
public protocol GoalRepository: Sendable { func all(includeArchived: Bool) async throws -> [Goal]; func upsert(_ g: Goal) async throws; func delete(id: UUID) async throws }
public protocol ReflectionRepository: Sendable {
    func checkIns(in range: ClosedRange<DayDate>) async throws -> [MoodCheckIn]
    func upsert(_ c: MoodCheckIn) async throws
    func journalEntries(in range: ClosedRange<DayDate>) async throws -> [JournalEntry]
    func upsert(_ e: JournalEntry) async throws
    func delete(journalID: UUID) async throws
    func delete(checkInID: UUID) async throws
}
public protocol EnergyRepository: Sendable { func checkIn(for day: DayDate) async throws -> EnergyCheckIn?; func upsert(_ e: EnergyCheckIn) async throws }
public protocol WinRepository: Sendable { func events(in range: ClosedRange<DayDate>) async throws -> [WinEvent]; func append(_ w: WinEvent) async throws }  // append-only by design
public protocol CopingRepository: Sendable { func all() async throws -> [CopingStrategy]; func upsert(_ s: CopingStrategy) async throws; func delete(id: UUID) async throws }
public protocol PreferencesRepository: Sendable { func load() async throws -> UserPreferences; func save(_ p: UserPreferences) async throws }
public struct DataExporter { public init(/* all repositories */); public func exportJSON() async throws -> Data }  // human-readable, pretty-printed, stable key order
public protocol DataWiping: Sendable { func wipeAll() async throws }
```

InMemory implementations: `actor` wrapping dictionaries. Named tests: per-repo `upsertThenFetchRoundTrips`, `dayPlanUniquePerDay` (second upsert same day replaces), `winsAppendOnlyHasNoDelete` (API-shape test), `preferencesLoadReturnsDefaultsFirstRun`, `exporterProducesHumanReadableJSON` (round-trip decode + contains ISO dates).

### Task 2.5: SwiftData schema v1, migration plan, live repositories

**Files:** `Sources/AnchorPersistence/SchemaV1.swift` (all `@Model` classes suffixed `Model`), `AnchorMigrationPlan.swift`, `ModelContainerFactory.swift`, `Mapping.swift` (Model ↔ Core value type, both directions), `SwiftDataRepositories.swift` (one `ModelActor` implementing all protocols), `Sources/AnchorPersistence/AnchorPersistence.swift`; tests `Tests/AnchorPersistenceTests/RoundTripTests.swift`, `MigrationTests.swift`, `LiveRepositoryTests.swift` (same suite as InMemory via shared assertions, against in-memory `ModelConfiguration(isStoredInMemoryOnly: true)`)

`#Index<DayPlanModel>([\.date])` and index on check-in/journal/win dates. `VersionedSchema` named `AnchorSchemaV1`; `AnchorMigrationPlan: SchemaMigrationPlan` with `schemas = [AnchorSchemaV1.self]`, empty stages, plus `MigrationTests.migrationPlanOpensV1Store` (create store, close, reopen through the plan) so the harness exists before v2 ever does.

### Task 2.6: RED push, then implementation, then GREEN push

- [x] **Step 1:** Commit tests + neutral stubs. `test: add phase-2 domain test suite (red)` (5fd9061).
- [x] **Step 2:** Push; **verified RED** — run 28703618370: compile succeeded, 65 assertion failures across the domain suite, 8 design tests still green, no crashes.
- [x] **Step 3:** Implemented all engines + repositories + SwiftData persistence to pass; `feat: implement domain engines and persistence (green)` (8af3628). Blind-compile iterations: lint pipefail masking, lint style, repository method-name collisions (deletePlan/allTemplates/…), orphaned doc comments — each surfaced by ci-logs and fixed forward.
- [x] **Step 4:** **Verified GREEN** — run 28710530091: lint clean, 106 tests pass (85 Core + 8 Design + 13 Persistence incl. SwiftData round-trip and migration), `BUILD SUCCEEDED`. **AnchorCore coverage 83.28%** (run 534eafae), now enforced as a CI gate. `AppDependencies.live()` opens the real container with in-memory fallback.

---

## Phase 3 — Features (order fixed by PROMPT §10; both design skills on every screen)

Common pattern for every feature task: ViewModel = `@MainActor @Observable final class` taking repositories + `DateProviding` via init; views consume theme via `@Environment(\.anchorTheme)`; **write VM tests first in the same push discipline as Phase 2 step-batching (tests authored before implementation, single push per feature, mutation-check during review)**; every screen gets a design-review checklist run (impeccable general rules + frontend-design distinctiveness + PROMPT §8) recorded in the commit body.

- **Task 3.0 — design system docs:** design-skill principles are applied directly in `AnchorDesign` (tokens, four WCAG-audited themes, calm components) and recorded in DECISIONS ADR-004/007. The impeccable-specific `PRODUCT.md`/`DESIGN.md` scaffolding is deferred to Phase 6 docs — the browser-oriented impeccable `init` flow does not fit a blind SwiftUI build; its general rules (contrast, no side-stripe, no alarm colour, gentle motion) are the per-screen checklist.
- [x] **Task 3.1 — Today:** DONE, green (run f6d1857). `TodayViewModel` (@MainActor @Observable) + `TodayContentView` + shared components `AnchorCard`, `AnchorSectionLabel`, `CategoryChip`, `DayProgressRing`, `EnergyBattery`. 9 VM tests: hero+progress, sequence/low-demand hide timers, energy prompt shown/hidden, wins hidden when disabled, nudge shown then dismiss-persists-for-day, nudge hidden in low-demand. Wired into the app's Today tab.
- [x] **Task 3.2 — Day timeline:** DONE + green (run 2f57345). `DayViewModel` (16 tests): toggle done/step (mint win, never remove on undo), lossless mode switch, shift-my-day, convert-to-rest, block add/edit/delete, mark-all-steps, templates apply/save, buffer apply. Three visualisations (Agenda, Ribbon, Focus) behind a segmented picker; block detail + editor sheets; templates sheet; buffer row. New tested Core rule `BufferAdvisor.applying`.
- [x] **Task 3.3 — Goals:** DONE + green (run 2f57345). `GoalsViewModel` (9 tests): progress only accrues (win never removed on uncheck), archive hides without deleting, if-then plans, target date renders as calm "Aiming for <date>" (no countdown). Views: list with fill-only progress, detail sheet with steps + if-then builder, goal editor.
- **Task 3.3 — Goals:** `FeatureGoals` — `GoalsViewModel`, `GoalListView`, `GoalDetailView`, `StepRow`, `IfThenBuilderSheet` ("If [trigger] then I will [step]"). VM tests: `progressAccruesOnlyUpward` (unchecking a step never lowers the *lifetime* wins, list progress recomputes but no shame state), `targetDateNeverProducesCountdownString`, `ifThenTimeTriggerSurfacesOnToday` (integration with `IfThenScheduler`).
- [x] **Task 3.4 — Reflect:** DONE + green (run f24f645). `ReflectViewModel` (10 tests): layered check-in savable with body sensations only or "not sure" alone, emotion words never required, journal debounce autosave, neutral-language patterns audit, history grouped by day. Views: `CheckInFlowView`, `JournalEditorView`, `HistoryListView`, `PatternsView`.
- **Task 3.4 — Reflect:** `FeatureReflect` — layered `CheckInFlowView` (body sensations picker → energy battery → optional sliders → optional emotion search, every layer skippable, "I'm not sure" first-class), `JournalEditorView` (autosave via debounce on VM), `HistoryListView`, `PatternsView` (neutral descriptive counts only). VM tests: `checkInSavableWithOnlyBodySensations`, `checkInSavableAsNotSureAlone`, `emotionWordsNeverRequired`, `journalAutosavesAfterDebounce`, `patternsUseNeutralLanguage` (string audit), `historyGroupsByDay`.
- [x] **Task 3.5 — Wins + Energy + Low-Demand surfaces:** DONE + green (run 43c669c). `TodayViewModel` +4 tests: energy prompt once per day (new `energyPromptDismissedDayKey`), low energy → `EnergyAdvisor` lightening offers applied only on explicit tap (convert-to-rest keeps block, postpone moves to next day), low-demand toggle persists (Today toolbar moon), wins keep counts + calm paused note instead of zero. Copy strings audited.
- **Task 3.5 — Wins + Energy + Low-Demand surfaces:** wins strip on Today (additive counters, pause + hide honored), energy check-in sheet on first open per day (skippable; low answer → lightening suggestions sheet where user applies each individually), Low-Demand toggle reachable from Today toolbar + Settings (one tap, persists). VM tests: `firstOpenPromptsOncePerDay`, `applySuggestionRequiresExplicitUserAction`, `lowDemandPersistsAcrossLaunches`, `winsNeverRenderZeroAfterHavingCounts` (pause shows pause copy, not zero).
- [x] **Task 3.6 — Coping bank:** DONE + green (run f24f645). `CopingViewModel` (7 tests): shuffle returns a strategy, seed inserted exactly once behind `seedDataInserted`, reachable in two taps from every tab. Views: `CopingListView`, `CopingEditorSheet`. Seed examples in `CopingSeeds`.
- **Task 3.6 — Coping bank:** `FeatureCoping` — `CopingListView`, `CopingEditorSheet`, `SuggestOneButton` (shuffle), persistent anchor toolbar icon added to all four tab roots (≤2 taps from anywhere), seed examples flagged `isSeedExample` inserted once behind `seedDataInserted`. VM tests: `shuffleReturnsSomeStrategy`, `seedInsertedExactlyOnce`, `reachableInTwoTapsFromEveryTab` (navigation-graph unit test on route enum).
- [x] **Task 3.7 — Settings + export/delete:** DONE + green (run 0d61664). `SettingsViewModel` (4 tests: soundDefaultsOff, settingsPersistAcrossReload, exportProducesDecodableJSON, deleteRequiresTwoConfirmations) reads/writes prefs, builds `DataExporter` JSON, models arm-then-confirm delete. `SettingsRootView` Form (theme/motion pickers, feedback/wins/low-demand toggles, share-sheet export, double-confirm delete), `LicencesView` (Lexend OFL). New `AppChromeModel` re-themes the whole app live on theme change. Added `FeatureSettingsTests` target. `mostRestrictiveMotionWins` already covered in MotionSettingTests.
- **Task 3.7 — Settings + export/delete:** `FeatureSettings` — theme picker with live preview, motion setting (most restrictive of user choice vs system Reduce Motion wins — helper in AnchorDesign `MotionSetting.effective(user:system:)` with tests), haptics/sound toggles, wins visibility + pause, Low-Demand default, notification management (Phase 4 wires), Dynamic Type note, export (share sheet with `DataExporter` JSON), delete-all with calm double confirmation, licences screen (Lexend OFL text). VM tests: `mostRestrictiveMotionWins`, `exportProducesDecodableJSON`, `deleteRequiresTwoConfirmations`, `soundDefaultsOff`.
- [x] **Task 3.8 — First run:** DONE + green (run 2a7e642). `OnboardingViewModel` (3 tests: skipCompletesOnboardingWithDefaults, answersPersistToPreferences, neverShownAgainOnceComplete). Paged `OnboardingRootView` (theme/wake/show-wins, persistent Skip). New `AppRootView` gates on `onboardingComplete`; completion propagates via `onChange(of: viewModel.isComplete)` — not a Sendable Task callback (that failed the app build first try). Added `FeatureOnboardingTests` target.
- **Task 3.8 — First run:** `FeatureOnboarding` — three questions max (theme, wake window, show wins), fully skippable, writes `onboardingComplete`. VM tests: `skipCompletesOnboardingWithDefaults`, `answersPersistToPreferences`, `neverShownAgainOnceComplete`.
- [x] **Task 3.9 — Seed demo data behind debug flag:** DONE + green (run fc4ac5e). New `FeatureFlag.seedDemoData` (DEBUG only) + `DemoSeeder` populate a mixed today plan (with rest), two goals with if-then, a week of energy/check-ins/journals/wins, and coping examples — once, guarded by `seedDataInserted`. `AppRootView` runs it at launch before gating. Test `seedDataOnlyBehindFlag` (no-op disabled, seeds enabled, idempotent).
- **Task 3.9 — Seed demo data behind debug flag** (`FeatureFlag.seedDemoData`, DEBUG builds only): populated day (mixed categories + rest), two goals with if-then, week of check-ins/journals/wins/energy, coping examples — makes every screen reviewable. Test: `seedDataOnlyBehindFlag`.

**Phase 3 complete and green (run fc4ac5e): 171 tests pass, app builds, lint strict clean. All feature surfaces built. Next: Phase 4 — notifications.**

Phase gate: CI green; final-phase review checklist appended to DECISIONS.md; screenshots deferred (no simulator UI capture in v1 loop — XCUITest smoke covers launch).

## Phase 4 — Notifications

- [x] **Task 4.1 — DONE + green (run 3b0e9fac):** `NotificationScheduling` protocol placed in **AnchorCore** (not AnchorPlatform as the sketch said — features depend on Core/Design only, and the AnchorPlatform header confirms protocols live in Core) + public `RecordingNotificationScheduler` double (3 tests). `UserNotificationScheduler` UN adapter in AnchorPlatform, sound off, replace-by-id. Does not store `UNUserNotificationCenter` (not Sendable) — reads `.current()` per call.
- [x] **Task 4.2 — DONE + green (run 3ecd60b):** new `notificationsEnabled` pref + `NotificationCoordinator` (AnchorCore; 4 tests: schedulingOnlyAfterAuthorization, permanentOffCancelsEverything, planChangeReschedulesWarnings, noSchedulingWhileLowDemand). Wired: `AppDependencies.notifications`, Settings Reminders toggle + pre-permission explainer sheet, Today refreshes transition warnings on every load. Coordinator injected as an **optional** dependency so existing VM tests are untouched.
- **Task 4.1:** `AnchorPlatform/NotificationScheduling.swift` (`protocol NotificationScheduling: Sendable { func requestAuthorization() async throws -> Bool; func schedule(_ n: [PlannedNotification]) async throws; func cancelAll() async; func pending() async -> [String] }`) + `UNUserNotificationCenter` adapter + `RecordingNotificationScheduler` test double in AnchorCore tests support.
- **Task 4.2:** wiring — Today VM schedules transition warnings from `NotificationPlanner` output on plan changes; Reflect reminders from Settings; gentle pre-permission explainer sheet (system prompt only after explicit "Turn on reminders"); quiet hours; permanent-off cancels + persists. Tests: `schedulingOnlyAfterAuthorization`, `permanentOffCancelsEverything`, `planChangeReschedulesWarnings`, `noSchedulingWhileLowDemand`.
- [x] **Task 4.3 — DONE + green (run c7a02ac):** `AnchorUITests/LaunchFlowTests` (XcodeGen `bundle.ui-testing` target, scheme test action) launches the app, skips onboarding, asserts the four tabs, opens the coping bank — passed on the macOS-runner simulator in ~54s. `make uitest` runs in a new CI step after the app build; ci-report scans `app-uitest.log`.
- **Task 4.3:** XCUITest smoke (`AnchorUITests/LaunchFlowTests.swift`): app launches, four tabs present, can open coping bank in two taps. Runs in app-build job via test plan. Phase gate: CI green.

**Phase 4 complete and green (run c7a02ac). Next: Phase 5 — accessibility and sensory audit.**

## Phase 5 — Accessibility and sensory audit

- **Task 5.1:** VoiceOver pass — every interactive element gets label/trait/hint audit; custom components (`DayProgressRing`, battery picker, category chips) get `accessibilityElement(children: .combine)` + values; walk the three core flows (add block, complete step, check-in) as VM-level route assertions + manual checklist in ACCESSIBILITY.md.
- **Task 5.2:** Dynamic Type pass — all layouts at `.accessibility5`: line-limit removals, `ViewThatFits`/scroll fallbacks; snapshot-free assertion: no fixed-height text containers (lint rule custom regex `\.frame\(height:` on rows flagged for review, documented exceptions).
- **Task 5.3:** Motion pass — every `withAnimation`/`.animation` routed through `MotionSetting.effective` gate helper (`Animation?` nil when off); test `noAnimationWhenMotionNone`; audit table in ACCESSIBILITY.md.
- **Task 5.4:** Contrast — Task 1.4 automated audit re-verified per final palettes; results table (theme × pair × ratio) generated by a small test that prints the table into the CI log, pasted into ACCESSIBILITY.md. Phase gate: CI green + ACCESSIBILITY.md complete with results, not intentions.

## Phase 6 — Hardening and handoff

- **Task 6.1:** Edge cases — empty states for every screen (calm, invitational); huge journal (10k words) scroll/perf sanity via unit-level pagination in `HistoryListView` (fetch by range); midnight rollover while app foregrounded (Today refreshes via `DateProviding` tick — timer on VM, test with `FixedDateProvider` advancing past midnight); DST re-verified.
- **Task 6.2:** Final whole-branch code review — superpowers requesting-code-review workflow (subagent, most capable model), findings fixed, re-reviewed.
- **Task 6.3:** Docs complete — README.md (setup incl. `make project` on a Mac, screen tour mapping each screen to the ten §3 principles), ARCHITECTURE.md (module diagram + dependency rules + repository/DI/clock patterns), DECISIONS.md (ADRs: stack, CI-verification, XcodeGen, single-package layout, streak replacement, TDD adaptation, design-skill conflicts), ACCESSIBILITY.md (results), FUTURE.md (§11 seams: CloudKit-ready ids/timestamps, sharing consent model sketch, widgets/Live Activity extension point, watch, template sharing, AI breakdown flag, sensory-break suggestions, insights — each with its `FeatureFlag` case).
- **Task 6.4:** Tag `v1.0.0` after final green run.

---

## Self-review notes (run 2026-07-04)

- **Spec coverage:** every PROMPT §7 feature has a task (7.1→3.1, 7.2→3.2, 7.3→3.3, 7.4→3.4, 7.5/7.6→3.5, 7.7→3.6, 7.8→3.7, 7.9→3.8); §6 export/delete → 2.4/3.7; §5 architecture → 1.2/2.4/2.5; §8 → 1.4/3.x/5.x; §9 gates → CI design; §10 phases mapped 1:1; §11 → 6.3 FUTURE.md.
- **Type consistency:** `DayDate`, `DateProviding`, repository signatures, `PlannedNotification`, `DayPresentation` are defined once (2.1–2.4) and referenced by exact name in Phases 3–4.
- **Placeholder scan:** later-phase tasks intentionally carry named interfaces + named test cases rather than verbatim view code; per the header adaptation this plan is the living document and each phase's push fills its checkboxes. No TBD/TODO markers exist.
