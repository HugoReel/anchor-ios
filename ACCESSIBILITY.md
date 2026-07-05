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

## VoiceOver (Task 5.1 — done, code level)

VoiceOver support is built into the components and screens:

- **Custom components collapse to one meaningful element.** `DayProgressRing`,
  `EnergyBattery` and `CategoryChip` use `accessibilityElement(children: .ignore)`
  with an explicit label and value (e.g. Energy → "Energy", value "3 of 5";
  progress ring → "Day progress", value "40%"; chip → "Focus block"), so a
  swipe lands on a single spoken element rather than raw shapes.
- **Every icon-only control has a label.** The toolbar anchors ("Coping bank",
  "Settings"), the low-demand toggle ("Turn on/off low-demand mode"), the add
  buttons ("Add a block or use a template", "Add a goal", "Add a strategy"),
  the nudge dismiss ("Dismiss for today") and the energy segments ("Energy N of
  5") all carry `accessibilityLabel`.
- **State is spoken, not just shown.** Done toggles read "Done" / "Mark done"
  rather than a bare glyph; completed titles also use `strikethrough`.

A full spoken-walkthrough of the three core flows (add block, complete step,
check-in) on a device with VoiceOver active is the remaining manual step; it
cannot run in the Windows/CI build environment used here.

## Dynamic Type (Task 5.2 — done)

- All text uses `AnchorFont` → `Font.custom(_, size:, relativeTo:)`, so it
  scales with the user's text size, including the accessibility sizes.
- Layouts are `ScrollView` + `VStack`/`HStack`, which reflow rather than clip.
  No text sits in a height-only frame; the only fixed-size frames are graphical
  (progress ring, battery segments, energy tap targets) which are not text.
- Line limits appear only on a journal preview (`HistoryListView`, 4 lines), a
  compact ribbon label (2 lines), and growing text editors (`1...4`, `2...5`
  ranges) — none constrain height.
- A custom SwiftLint rule (`height_only_frame`) now flags any future
  `.frame(height:)` so a fixed-height text row can't regress unnoticed.

## Contrast (Task 5.4 — done)

WCAG 2.1 ratios for the semantic text/background pairs, computed with the same
math as `RGBAColor.contrastRatio` (relative luminance, `(L1+0.05)/(L2+0.05)`).
Body text requires ≥ 4.5; the accent-as-UI-component pair requires ≥ 3.0. All
four themes pass every pair, and the six per-theme category-chip pairs
(`textPrimary` on each chip background) are asserted ≥ 4.5 by
`AnchorDesignTests/ContrastAuditTests`, which is a CI gate.

### Calm

| Pair | Ratio | Min |
| --- | --- | --- |
| textPrimary on background | 12.01 | 4.5 |
| textPrimary on surface | 12.72 | 4.5 |
| textPrimary on surfaceRaised | 13.20 | 4.5 |
| textSecondary on background | 6.17 | 4.5 |
| textSecondary on surface | 6.54 | 4.5 |
| accentText on accent | 5.67 | 4.5 |
| textPrimary on gentle | 11.00 | 4.5 |
| accent on background (component) | 5.55 | 3.0 |

### Cool

| Pair | Ratio | Min |
| --- | --- | --- |
| textPrimary on background | 12.41 | 4.5 |
| textPrimary on surface | 13.21 | 4.5 |
| textPrimary on surfaceRaised | 13.82 | 4.5 |
| textSecondary on background | 6.40 | 4.5 |
| textSecondary on surface | 6.81 | 4.5 |
| accentText on accent | 6.11 | 4.5 |
| textPrimary on gentle | 11.36 | 4.5 |
| accent on background (component) | 5.92 | 3.0 |

### Warm

| Pair | Ratio | Min |
| --- | --- | --- |
| textPrimary on background | 11.55 | 4.5 |
| textPrimary on surface | 12.34 | 4.5 |
| textPrimary on surfaceRaised | 13.14 | 4.5 |
| textSecondary on background | 6.09 | 4.5 |
| textSecondary on surface | 6.51 | 4.5 |
| accentText on accent | 5.17 | 4.5 |
| textPrimary on gentle | 10.57 | 4.5 |
| accent on background (component) | 4.95 | 3.0 |

### Low-light

| Pair | Ratio | Min |
| --- | --- | --- |
| textPrimary on background | 12.73 | 4.5 |
| textPrimary on surface | 11.33 | 4.5 |
| textPrimary on surfaceRaised | 9.75 | 4.5 |
| textSecondary on background | 6.91 | 4.5 |
| textSecondary on surface | 6.15 | 4.5 |
| accentText on accent | 6.53 | 4.5 |
| textPrimary on gentle | 9.09 | 4.5 |
| accent on background (component) | 6.77 | 3.0 |
